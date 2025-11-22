#!/bin/bash

# =============================================================================
# axionax Protocol - Quick Service Manager
# =============================================================================
# Simple interface to manage individual services
# Usage: ./manage-services.sh [start|stop|restart|logs|status] [service-name|all]
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="${DEPLOY_DIR}/docker-compose.vps.yml"

ACTION=$1
SERVICE=$2

# Available services
SERVICES=(
    "nginx"
    "certbot"
    "rpc-node"
    "explorer-backend"
    "faucet"
    "postgres"
    "redis"
    "prometheus"
    "grafana"
)

print_usage() {
    echo "Usage: $0 [action] [service|all]"
    echo ""
    echo "Actions:"
    echo "  start     - Start service(s)"
    echo "  stop      - Stop service(s)"
    echo "  restart   - Restart service(s)"
    echo "  logs      - View service logs (follow mode)"
    echo "  status    - Show service status"
    echo "  rebuild   - Rebuild and restart service"
    echo ""
    echo "Services:"
    for svc in "${SERVICES[@]}"; do
        echo "  - $svc"
    done
    echo "  - all (for all services)"
    echo ""
    echo "Examples:"
    echo "  $0 start rpc-node"
    echo "  $0 restart all"
    echo "  $0 logs faucet"
    echo "  $0 status nginx"
}

check_compose_file() {
    if [ ! -f "$COMPOSE_FILE" ]; then
        echo -e "${RED}Error: docker-compose.vps.yml not found at ${COMPOSE_FILE}${NC}"
        exit 1
    fi
}

validate_service() {
    local service=$1
    if [ "$service" == "all" ]; then
        return 0
    fi
    
    for svc in "${SERVICES[@]}"; do
        if [ "$svc" == "$service" ]; then
            return 0
        fi
    done
    
    echo -e "${RED}Error: Invalid service name: $service${NC}"
    echo "Available services: ${SERVICES[*]} all"
    exit 1
}

service_start() {
    local service=$1
    echo -e "${BLUE}Starting $service...${NC}"
    docker-compose -f "$COMPOSE_FILE" up -d "$service"
    echo -e "${GREEN}✓ $service started${NC}"
}

service_stop() {
    local service=$1
    echo -e "${YELLOW}Stopping $service...${NC}"
    docker-compose -f "$COMPOSE_FILE" stop "$service"
    echo -e "${GREEN}✓ $service stopped${NC}"
}

service_restart() {
    local service=$1
    echo -e "${BLUE}Restarting $service...${NC}"
    docker-compose -f "$COMPOSE_FILE" restart "$service"
    echo -e "${GREEN}✓ $service restarted${NC}"
}

service_logs() {
    local service=$1
    echo -e "${CYAN}Viewing logs for $service (Ctrl+C to exit)...${NC}"
    docker-compose -f "$COMPOSE_FILE" logs -f --tail=100 "$service"
}

service_status() {
    local service=$1
    if [ "$service" == "all" ]; then
        docker-compose -f "$COMPOSE_FILE" ps
    else
        docker-compose -f "$COMPOSE_FILE" ps "$service"
    fi
}

service_rebuild() {
    local service=$1
    echo -e "${YELLOW}Rebuilding $service...${NC}"
    docker-compose -f "$COMPOSE_FILE" up -d --build "$service"
    echo -e "${GREEN}✓ $service rebuilt and restarted${NC}"
}

# Main execution
if [ -z "$ACTION" ] || [ -z "$SERVICE" ]; then
    print_usage
    exit 1
fi

check_compose_file
validate_service "$SERVICE"

cd "$DEPLOY_DIR"

case "$ACTION" in
    start)
        if [ "$SERVICE" == "all" ]; then
            echo -e "${BLUE}Starting all services...${NC}"
            docker-compose -f "$COMPOSE_FILE" up -d
            echo -e "${GREEN}✓ All services started${NC}"
        else
            service_start "$SERVICE"
        fi
        ;;
    stop)
        if [ "$SERVICE" == "all" ]; then
            echo -e "${YELLOW}Stopping all services...${NC}"
            docker-compose -f "$COMPOSE_FILE" down
            echo -e "${GREEN}✓ All services stopped${NC}"
        else
            service_stop "$SERVICE"
        fi
        ;;
    restart)
        if [ "$SERVICE" == "all" ]; then
            echo -e "${BLUE}Restarting all services...${NC}"
            docker-compose -f "$COMPOSE_FILE" restart
            echo -e "${GREEN}✓ All services restarted${NC}"
        else
            service_restart "$SERVICE"
        fi
        ;;
    logs)
        service_logs "$SERVICE"
        ;;
    status)
        service_status "$SERVICE"
        ;;
    rebuild)
        if [ "$SERVICE" == "all" ]; then
            echo -e "${YELLOW}Rebuilding all services...${NC}"
            docker-compose -f "$COMPOSE_FILE" up -d --build
            echo -e "${GREEN}✓ All services rebuilt${NC}"
        else
            service_rebuild "$SERVICE"
        fi
        ;;
    *)
        echo -e "${RED}Error: Invalid action: $ACTION${NC}"
        print_usage
        exit 1
        ;;
esac
