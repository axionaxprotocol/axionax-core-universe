#!/bin/bash

# =============================================================================
# axionax Protocol - Complete Service Deployment Script
# =============================================================================
# This script deploys all axionax services in the correct order
# Usage: ./deploy-all-services.sh [--check-only | --minimal | --full]
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="${DEPLOY_DIR}/deployment.log"

# Deployment modes
MODE="${1:---full}"

# =============================================================================
# Helper Functions
# =============================================================================

print_header() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${MAGENTA}ℹ $1${NC}"
}

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        print_error "Please run as root or with sudo"
        exit 1
    fi
}

# Check system resources
check_resources() {
    print_step "Checking system resources..."
    
    # Get RAM in GB
    TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
    # Get CPU cores
    CPU_CORES=$(nproc)
    # Get available disk space in GB
    DISK_SPACE=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    
    print_info "RAM: ${TOTAL_RAM}GB | CPU: ${CPU_CORES} cores | Disk: ${DISK_SPACE}GB available"
    
    # Minimum requirements check
    if [ "$TOTAL_RAM" -lt 4 ]; then
        print_error "Insufficient RAM. Minimum 4GB required, 8GB+ recommended"
        return 1
    fi
    
    if [ "$CPU_CORES" -lt 2 ]; then
        print_error "Insufficient CPU cores. Minimum 2 cores required, 4+ recommended"
        return 1
    fi
    
    if [ "$DISK_SPACE" -lt 50 ]; then
        print_error "Insufficient disk space. Minimum 50GB required, 100GB+ recommended"
        return 1
    fi
    
    print_success "System resources check passed"
    log "System resources: RAM=${TOTAL_RAM}GB, CPU=${CPU_CORES}, Disk=${DISK_SPACE}GB"
    
    # Recommend deployment mode based on resources
    if [ "$TOTAL_RAM" -ge 16 ]; then
        print_info "Recommended mode: --full (all services)"
    elif [ "$TOTAL_RAM" -ge 8 ]; then
        print_info "Recommended mode: --full (all services, monitor resource usage)"
    else
        print_warning "Recommended mode: --minimal (essential services only)"
    fi
    
    return 0
}

# Check Docker installation
check_docker() {
    print_step "Checking Docker installation..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        print_info "Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        rm get-docker.sh
        systemctl enable docker
        systemctl start docker
        print_success "Docker installed successfully"
        log "Docker installed"
    else
        print_success "Docker is already installed"
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed"
        print_info "Installing Docker Compose..."
        COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
        curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        print_success "Docker Compose installed successfully"
        log "Docker Compose installed"
    else
        print_success "Docker Compose is already installed"
    fi
}

# Check environment variables
check_env() {
    print_step "Checking environment configuration..."
    
    if [ ! -f "${DEPLOY_DIR}/.env" ]; then
        print_error ".env file not found"
        print_info "Creating .env from template..."
        
        if [ -f "${DEPLOY_DIR}/.env.example" ]; then
            cp "${DEPLOY_DIR}/.env.example" "${DEPLOY_DIR}/.env"
            print_warning "Please edit .env file with your configuration"
            print_info "Required variables: DB_PASSWORD, REDIS_PASSWORD, FAUCET_PRIVATE_KEY, GRAFANA_PASSWORD, VPS_IP, DOMAIN"
            exit 1
        else
            print_error ".env.example not found"
            exit 1
        fi
    fi
    
    # Load environment variables
    source "${DEPLOY_DIR}/.env"
    
    # Check required variables
    REQUIRED_VARS=("DB_PASSWORD" "REDIS_PASSWORD" "GRAFANA_PASSWORD" "VPS_IP")
    MISSING_VARS=()
    
    for var in "${REQUIRED_VARS[@]}"; do
        if [ -z "${!var}" ]; then
            MISSING_VARS+=("$var")
        fi
    done
    
    if [ ${#MISSING_VARS[@]} -gt 0 ]; then
        print_error "Missing required environment variables:"
        for var in "${MISSING_VARS[@]}"; do
            print_error "  - $var"
        done
        exit 1
    fi
    
    print_success "Environment configuration is valid"
    log "Environment variables validated"
}

# Deploy service with health check
deploy_service() {
    local service_name=$1
    local health_check=$2
    local timeout=${3:-60}
    
    print_step "Deploying ${service_name}..."
    
    cd "${DEPLOY_DIR}"
    docker-compose -f docker-compose.vps.yml up -d "$service_name" 2>&1 | tee -a "$LOG_FILE"
    
    if [ -n "$health_check" ]; then
        print_info "Waiting for ${service_name} to be healthy (timeout: ${timeout}s)..."
        local elapsed=0
        while [ $elapsed -lt $timeout ]; do
            if eval "$health_check" &>/dev/null; then
                print_success "${service_name} is healthy"
                log "${service_name} deployed successfully"
                return 0
            fi
            sleep 5
            elapsed=$((elapsed + 5))
            echo -n "."
        done
        echo ""
        print_error "${service_name} health check failed"
        print_info "Check logs: docker-compose -f docker-compose.vps.yml logs ${service_name}"
        return 1
    else
        sleep 10
        print_success "${service_name} deployed"
        log "${service_name} deployed (no health check)"
        return 0
    fi
}

# =============================================================================
# Deployment Phases
# =============================================================================

deploy_phase_1_infrastructure() {
    print_header "PHASE 1: Infrastructure Services"
    
    # PostgreSQL
    deploy_service "postgres" \
        "docker exec axionax-postgres pg_isready -U explorer" \
        60
    
    # Redis
    deploy_service "redis" \
        "docker exec axionax-redis redis-cli ping | grep -q PONG" \
        30
    
    print_success "Phase 1 completed: Infrastructure services are running"
}

deploy_phase_2_core() {
    print_header "PHASE 2: Core Blockchain Services"
    
    # RPC Node (this is the most important service)
    deploy_service "rpc-node" \
        "docker exec axionax-rpc curl -f http://localhost:8545/health" \
        120
    
    print_success "Phase 2 completed: RPC node is running"
}

deploy_phase_3_applications() {
    print_header "PHASE 3: Application Services"
    
    # Block Explorer Backend
    deploy_service "explorer-backend" \
        "docker exec axionax-explorer-backend curl -f http://localhost:3001/api/health" \
        90
    
    # Faucet
    deploy_service "faucet" \
        "docker exec axionax-faucet curl -f http://localhost:3002/health" \
        60
    
    print_success "Phase 3 completed: Application services are running"
}

deploy_phase_4_monitoring() {
    print_header "PHASE 4: Monitoring & Observability"
    
    # Prometheus
    deploy_service "prometheus" \
        "curl -f http://localhost:9090/-/healthy" \
        45
    
    # Grafana (already running, just ensure it's up)
    deploy_service "grafana" \
        "curl -f http://localhost:3000/api/health" \
        45
    
    print_success "Phase 4 completed: Monitoring services are running"
}

deploy_phase_5_proxy() {
    print_header "PHASE 5: Reverse Proxy & SSL"
    
    # Nginx
    deploy_service "nginx" \
        "docker exec axionax-nginx nginx -t" \
        30
    
    # Certbot (runs periodically, just ensure container exists)
    deploy_service "certbot" "" 15
    
    print_success "Phase 5 completed: Nginx and SSL are configured"
}

# =============================================================================
# Deployment Modes
# =============================================================================

deploy_minimal() {
    print_header "MINIMAL DEPLOYMENT MODE"
    print_info "Deploying essential services only (RPC + Faucet)"
    
    deploy_phase_1_infrastructure
    deploy_phase_2_core
    
    # Only faucet from phase 3
    print_header "PHASE 3: Essential Applications"
    deploy_service "faucet" \
        "docker exec axionax-faucet curl -f http://localhost:3002/health" \
        60
    
    deploy_phase_5_proxy
    
    print_success "Minimal deployment completed"
}

deploy_full() {
    print_header "FULL DEPLOYMENT MODE"
    print_info "Deploying all services"
    
    deploy_phase_1_infrastructure
    deploy_phase_2_core
    deploy_phase_3_applications
    deploy_phase_4_monitoring
    deploy_phase_5_proxy
    
    print_success "Full deployment completed"
}

# =============================================================================
# Post-Deployment Verification
# =============================================================================

verify_deployment() {
    print_header "DEPLOYMENT VERIFICATION"
    
    cd "${DEPLOY_DIR}"
    
    print_step "Checking running containers..."
    docker-compose -f docker-compose.vps.yml ps
    
    echo ""
    print_step "Service Health Status:"
    
    # Check each service
    services=(
        "nginx:80:Web Server"
        "nginx:443:HTTPS"
        "grafana:3000:Grafana Dashboard"
        "rpc-node:8545:RPC HTTP"
        "rpc-node:8546:RPC WebSocket"
        "explorer-backend:3001:Explorer API"
        "faucet:3002:Faucet API"
        "prometheus:9090:Prometheus"
        "postgres:5432:PostgreSQL"
        "redis:6379:Redis"
    )
    
    for service in "${services[@]}"; do
        IFS=':' read -r container port description <<< "$service"
        if docker ps | grep -q "axionax-${container}"; then
            if nc -z localhost "$port" 2>/dev/null; then
                print_success "${description} (port ${port})"
            else
                print_warning "${description} (port ${port}) - container running but port not accessible"
            fi
        else
            print_error "${description} (port ${port}) - container not running"
        fi
    done
}

print_access_info() {
    print_header "ACCESS INFORMATION"
    
    source "${DEPLOY_DIR}/.env"
    
    echo -e "${GREEN}Public Endpoints:${NC}"
    echo -e "  Web:       ${CYAN}http://${VPS_IP}${NC}"
    echo -e "  HTTPS:     ${CYAN}https://${VPS_IP}${NC}"
    
    if [ -n "$DOMAIN" ]; then
        echo ""
        echo -e "${GREEN}Domain Endpoints (ensure DNS is configured):${NC}"
        echo -e "  RPC:       ${CYAN}https://rpc.${DOMAIN}${NC}"
        echo -e "  Explorer:  ${CYAN}https://explorer.${DOMAIN}${NC}"
        echo -e "  Faucet:    ${CYAN}https://faucet.${DOMAIN}${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}Direct Access (no SSL):${NC}"
    echo -e "  RPC HTTP:  ${CYAN}http://${VPS_IP}:8545${NC}"
    echo -e "  RPC WS:    ${CYAN}ws://${VPS_IP}:8546${NC}"
    echo -e "  Explorer:  ${CYAN}http://${VPS_IP}:3001${NC}"
    echo -e "  Faucet:    ${CYAN}http://${VPS_IP}:3002${NC}"
    
    echo ""
    echo -e "${GREEN}Monitoring:${NC}"
    echo -e "  Grafana:   ${CYAN}http://${VPS_IP}:3000${NC}"
    echo -e "             ${YELLOW}Username: admin${NC}"
    echo -e "             ${YELLOW}Password: ${GRAFANA_PASSWORD}${NC}"
    echo -e "  Prometheus: ${CYAN}http://${VPS_IP}:9090${NC}"
    
    echo ""
    echo -e "${GREEN}Useful Commands:${NC}"
    echo -e "  View logs:     ${CYAN}cd ${DEPLOY_DIR} && docker-compose -f docker-compose.vps.yml logs -f [service]${NC}"
    echo -e "  Restart all:   ${CYAN}cd ${DEPLOY_DIR} && docker-compose -f docker-compose.vps.yml restart${NC}"
    echo -e "  Stop all:      ${CYAN}cd ${DEPLOY_DIR} && docker-compose -f docker-compose.vps.yml down${NC}"
    echo -e "  Check status:  ${CYAN}cd ${DEPLOY_DIR} && docker-compose -f docker-compose.vps.yml ps${NC}"
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    print_header "axionax Protocol - Service Deployment"
    
    log "Deployment started with mode: $MODE"
    
    # Pre-flight checks
    check_root
    
    if [ "$MODE" != "--check-only" ]; then
        check_resources || exit 1
        check_docker
        check_env
        
        # Deploy based on mode
        case "$MODE" in
            --minimal)
                deploy_minimal
                ;;
            --full)
                deploy_full
                ;;
            *)
                print_error "Unknown mode: $MODE"
                echo "Usage: $0 [--check-only | --minimal | --full]"
                exit 1
                ;;
        esac
        
        # Post-deployment
        verify_deployment
        print_access_info
        
        print_header "DEPLOYMENT COMPLETE! 🚀"
        print_success "All services have been deployed successfully"
        print_info "Log file: ${LOG_FILE}"
        log "Deployment completed successfully"
    else
        # Check-only mode
        check_resources
        check_docker
        check_env
        print_success "All checks passed. Ready for deployment!"
    fi
}

# Run main function
main "$@"
