#!/bin/bash

# =============================================================================
# axionax Protocol - VPS Status Check Script
# =============================================================================
# This script checks the status of all services and system resources
# Usage: ./check-vps-status.sh [--detailed]
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"

DETAILED="${1}"

print_header() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
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
    echo -e "${BLUE}ℹ $1${NC}"
}

# System Resources
check_system_resources() {
    print_header "SYSTEM RESOURCES"
    
    # RAM
    TOTAL_RAM=$(free -h | awk '/^Mem:/{print $2}')
    USED_RAM=$(free -h | awk '/^Mem:/{print $3}')
    RAM_PERCENT=$(free | awk '/^Mem:/{printf "%.1f", $3/$2 * 100}')
    echo -e "RAM Usage:     ${USED_RAM} / ${TOTAL_RAM} (${RAM_PERCENT}%)"
    
    if (( $(echo "$RAM_PERCENT > 90" | bc -l) )); then
        print_warning "RAM usage is critically high"
    elif (( $(echo "$RAM_PERCENT > 75" | bc -l) )); then
        print_warning "RAM usage is high"
    else
        print_success "RAM usage is normal"
    fi
    
    # CPU
    CPU_LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}')
    CPU_CORES=$(nproc)
    echo -e "CPU Load:      ${CPU_LOAD} (${CPU_CORES} cores available)"
    
    # Disk
    DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    DISK_AVAIL=$(df -h / | awk 'NR==2 {print $4}')
    echo -e "Disk Usage:    ${DISK_USAGE}% (${DISK_AVAIL} available)"
    
    if [ "$DISK_USAGE" -gt 90 ]; then
        print_warning "Disk usage is critically high"
    elif [ "$DISK_USAGE" -gt 75 ]; then
        print_warning "Disk usage is high"
    else
        print_success "Disk usage is normal"
    fi
    
    # Uptime
    UPTIME=$(uptime -p)
    echo -e "System Uptime: ${UPTIME}"
}

# Docker Status
check_docker_status() {
    print_header "DOCKER STATUS"
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        return 1
    fi
    
    if ! systemctl is-active --quiet docker; then
        print_error "Docker service is not running"
        return 1
    fi
    
    print_success "Docker service is running"
    
    # Docker version
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
    echo -e "Docker Version: ${DOCKER_VERSION}"
    
    # Running containers
    RUNNING_CONTAINERS=$(docker ps -q | wc -l)
    TOTAL_CONTAINERS=$(docker ps -a -q | wc -l)
    echo -e "Containers:     ${RUNNING_CONTAINERS} running / ${TOTAL_CONTAINERS} total"
    
    # Docker disk usage
    echo ""
    docker system df
}

# Service Health Checks
check_service_health() {
    print_header "SERVICE HEALTH STATUS"
    
    cd "${DEPLOY_DIR}" 2>/dev/null || {
        print_error "Deployment directory not found: ${DEPLOY_DIR}"
        return 1
    }
    
    # Define services and their health checks
    declare -A services=(
        ["nginx"]="Web Server|80|curl -sf http://localhost/"
        ["nginx-ssl"]="HTTPS|443|nc -z localhost 443"
        ["grafana"]="Grafana|3030|curl -sf http://localhost:3030/api/health"
        ["rpc-node"]="RPC HTTP|8545|curl -sf http://localhost:8545/health"
        ["rpc-ws"]="RPC WebSocket|8546|nc -z localhost 8546"
        ["explorer"]="Explorer API|3001|docker ps --filter name=axionax-explorer-api --filter status=running --format '{{.Names}}'"
        ["faucet"]="Faucet API|3002|docker ps --filter name=axionax-faucet-api --filter status=running --format '{{.Names}}'"
        ["prometheus"]="Prometheus|9090|curl -sf http://localhost:9090/-/healthy"
        ["postgres"]="PostgreSQL|5432|docker exec axionax-postgres pg_isready -U explorer"
        ["redis"]="Redis|6379|docker exec axionax-redis redis-cli ping"
    )
    
    printf "%-20s %-8s %-10s\n" "Service" "Port" "Status"
    printf "%-20s %-8s %-10s\n" "-------" "----" "------"
    
    for service in "${!services[@]}"; do
        IFS='|' read -r name port check <<< "${services[$service]}"
        
        # Check if container is running (for docker exec commands)
        if [[ "$check" == "docker exec"* ]]; then
            container_name=$(echo "$check" | awk '{print $3}')
            if ! docker ps --format '{{.Names}}' | grep -q "$container_name"; then
                printf "%-20s %-8s " "$name" "$port"
                print_error "Container not running"
                continue
            fi
        fi
        
        # Run health check
        if eval "$check" &>/dev/null; then
            printf "%-20s %-8s " "$name" "$port"
            print_success "Healthy"
        else
            printf "%-20s %-8s " "$name" "$port"
            print_error "Unhealthy"
        fi
    done
}

# Container Details
show_container_details() {
    print_header "CONTAINER DETAILS"
    
    cd "${DEPLOY_DIR}" 2>/dev/null || return 1
    
    if [ -f "docker-compose.vps.yml" ]; then
        docker-compose -f docker-compose.vps.yml ps
    else
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    fi
}

# Network Connectivity
check_network() {
    print_header "NETWORK CONNECTIVITY"
    
    # Load environment
    if [ -f "${DEPLOY_DIR}/.env" ]; then
        source "${DEPLOY_DIR}/.env"
    fi
    
    # Check public ports
    declare -a public_ports=(
        "80:HTTP"
        "443:HTTPS"
        "3000:Grafana"
    )
    
    echo "Public Port Status:"
    for port_info in "${public_ports[@]}"; do
        IFS=':' read -r port name <<< "$port_info"
        if nc -z -w2 localhost "$port" 2>/dev/null; then
            printf "  Port %-5s (%-10s): " "$port" "$name"
            print_success "Open"
        else
            printf "  Port %-5s (%-10s): " "$port" "$name"
            print_error "Closed"
        fi
    done
    
    # Check internal services
    echo ""
    echo "Internal Service Ports:"
    declare -a internal_ports=(
        "8545:RPC HTTP"
        "8546:RPC WS"
        "3001:Explorer"
        "3002:Faucet"
        "9090:Prometheus"
        "5432:PostgreSQL"
        "6379:Redis"
    )
    
    for port_info in "${internal_ports[@]}"; do
        IFS=':' read -r port name <<< "$port_info"
        if nc -z -w2 localhost "$port" 2>/dev/null; then
            printf "  Port %-5s (%-10s): " "$port" "$name"
            print_success "Listening"
        else
            printf "  Port %-5s (%-10s): " "$port" "$name"
            print_warning "Not listening"
        fi
    done
}

# Recent Logs
show_recent_errors() {
    print_header "RECENT ERRORS (Last 24 hours)"
    
    cd "${DEPLOY_DIR}" 2>/dev/null || return 1
    
    if [ -f "docker-compose.vps.yml" ]; then
        # Get logs from last 24 hours with errors
        docker-compose -f docker-compose.vps.yml logs --since 24h 2>&1 | \
            grep -iE "error|fatal|panic|failed" | \
            tail -20
        
        if [ $? -ne 0 ]; then
            print_success "No recent errors found"
        fi
    fi
}

# Database Status
check_database() {
    print_header "DATABASE STATUS"
    
    if docker ps | grep -q "axionax-postgres"; then
        print_success "PostgreSQL container is running"
        
        # Database size
        DB_SIZE=$(docker exec axionax-postgres psql -U explorer -d explorer -t -c "SELECT pg_size_pretty(pg_database_size('explorer'));" 2>/dev/null | xargs)
        echo -e "Database Size:     ${DB_SIZE}"
        
        # Connection count
        CONNECTIONS=$(docker exec axionax-postgres psql -U explorer -d explorer -t -c "SELECT count(*) FROM pg_stat_activity;" 2>/dev/null | xargs)
        echo -e "Active Connections: ${CONNECTIONS}"
        
        # Table count
        TABLES=$(docker exec axionax-postgres psql -U explorer -d explorer -t -c "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | xargs)
        echo -e "Tables:            ${TABLES}"
    else
        print_error "PostgreSQL container is not running"
    fi
    
    echo ""
    
    if docker ps | grep -q "axionax-redis"; then
        print_success "Redis container is running"
        
        # Redis memory usage
        REDIS_MEM=$(docker exec axionax-redis redis-cli INFO memory 2>/dev/null | grep "used_memory_human" | cut -d: -f2 | tr -d '\r')
        echo -e "Redis Memory:      ${REDIS_MEM}"
        
        # Redis keys
        REDIS_KEYS=$(docker exec axionax-redis redis-cli DBSIZE 2>/dev/null | awk '{print $2}')
        echo -e "Redis Keys:        ${REDIS_KEYS}"
    else
        print_error "Redis container is not running"
    fi
}

# Performance Metrics
show_performance() {
    print_header "PERFORMANCE METRICS"
    
    # Container resource usage
    echo "Container Resource Usage:"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | head -11
}

# Quick Summary
show_summary() {
    print_header "QUICK SUMMARY"
    
    cd "${DEPLOY_DIR}" 2>/dev/null || return 1
    
    # Count running services
    EXPECTED_SERVICES=9
    RUNNING_SERVICES=$(docker-compose -f docker-compose.vps.yml ps --services --filter "status=running" 2>/dev/null | wc -l)
    
    echo -e "Services Status: ${RUNNING_SERVICES}/${EXPECTED_SERVICES} running"
    
    if [ "$RUNNING_SERVICES" -eq "$EXPECTED_SERVICES" ]; then
        print_success "All services are running"
    elif [ "$RUNNING_SERVICES" -gt 0 ]; then
        print_warning "Some services are not running"
    else
        print_error "No services are running"
    fi
    
    # System health
    RAM_PERCENT=$(free | awk '/^Mem:/{printf "%.0f", $3/$2 * 100}')
    DISK_PERCENT=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    echo ""
    echo "Resource Usage:"
    echo -e "  RAM:  ${RAM_PERCENT}%"
    echo -e "  Disk: ${DISK_PERCENT}%"
    
    # Overall health
    echo ""
    if [ "$RUNNING_SERVICES" -eq "$EXPECTED_SERVICES" ] && [ "$RAM_PERCENT" -lt 90 ] && [ "$DISK_PERCENT" -lt 90 ]; then
        print_success "Overall Status: HEALTHY ✨"
    else
        print_warning "Overall Status: NEEDS ATTENTION ⚠️"
    fi
}

# Main execution
main() {
    clear
    print_header "axionax VPS Status Check"
    echo -e "${BLUE}Timestamp: $(date)${NC}"
    echo -e "${BLUE}Hostname:  $(hostname)${NC}"
    echo -e "${BLUE}IP:        $(hostname -I | awk '{print $1}')${NC}"
    
    show_summary
    check_system_resources
    check_docker_status
    check_service_health
    
    if [ "$DETAILED" == "--detailed" ]; then
        show_container_details
        check_network
        check_database
        show_performance
        show_recent_errors
    else
        echo ""
        print_info "Run with --detailed flag for more information"
    fi
    
    echo ""
    print_header "Status check complete"
}

main "$@"
