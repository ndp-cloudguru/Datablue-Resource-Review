#!/usr/bin/env bash

# ==============================================================================
# XianZhu / Lilishop S2B2C - Health Check Script For Stack Services
# Mục đích: Kiểm tra nhanh trạng thái UP / DOWN của toàn bộ Middleware, Backend & Frontend
# ==============================================================================

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${CYAN}======================================================================${NC}"
echo -e "${BOLD}${GREEN}🔍 XIANZHU S2B2C - SCRIPT KIỂM TRA TRẠM THÁI CỤM SERVICES DOCKER${NC}"
echo -e "${CYAN}======================================================================${NC}"

check_port() {
    local name="$1"
    local host="$2"
    local port="$3"

    if nc -z -w 3 "${host}" "${port}" 2>/dev/null || (exec 3<>/dev/tcp/"${host}"/"${port}") 2>/dev/null; then
        printf "  %-32s [ %bONLINE%b ] (Port %s)\n" "${name}" "${GREEN}${BOLD}" "${NC}" "${port}"
    else
        printf "  %-32s [ %bOFFLINE%b ] (Port %s)\n" "${name}" "${RED}${BOLD}" "${NC}" "${port}"
    fi
}

check_container() {
    local name="$1"
    local cname="$2"

    local cstatus
    cstatus=$(docker inspect -f '{{.State.Status}}' "${cname}" 2>/dev/null || echo "not-found")

    if [ "${cstatus}" = "running" ]; then
        printf "  %-32s [ %bRUNNING%b ]\n" "${name}" "${GREEN}${BOLD}" "${NC}"
    else
        printf "  %-32s [ %bNOT RUNNING%b ]\n" "${name}" "${RED}${BOLD}" "${NC}"
    fi
}

echo -e "\n${BOLD}${YELLOW}1. MIDDLEWARE SERVICES (HẠ TẦNG TRUNG TRẠM):${NC}"
check_port "MySQL Database" "127.0.0.1" 3306
check_port "Redis Cache" "127.0.0.1" 6379
check_port "Nacos Config Server" "127.0.0.1" 8848
check_port "RabbitMQ Broker" "127.0.0.1" 5672
check_port "RabbitMQ Dashboard" "127.0.0.1" 15672
check_port "Elasticsearch Engine" "127.0.0.1" 9200

echo -e "\n${BOLD}${BLUE}2. BACKEND MICROSERVICES (JAVA SERVICES):${NC}"
check_port "Gateway API Service" "127.0.0.1" 8888
check_container "Auth Service" "builds-auth-service"
check_container "User Service" "builds-user-service"
check_container "Goods Service" "builds-goods-service"
check_container "Order Service" "builds-order-service"
check_container "Supplier Service" "builds-supplier-service"
check_container "System Service" "builds-system-service"
check_container "Payment Service" "builds-payment-service"
check_container "Promotion Service" "builds-promotion-service"
check_container "Statistics Service" "builds-statistics-service"
check_container "Resource Service" "builds-resource-service"
check_container "Broadcast Service" "builds-broadcast-service"
check_port "IM Service (Chat)" "127.0.0.1" 11130
check_container "Distribution Service" "builds-distribution-service"
check_container "Consumer Service" "builds-consumer"
check_container "Xianzhu Service" "builds-xianzhu-service"

echo -e "\n${BOLD}${CYAN}3. FRONTEND UI (GIAO DIỆN WEB TĨNH):${NC}"
check_port "Buyer UI (Port 8080)" "127.0.0.1" 8080
check_container "Buyer UI Container" "builds-buyer-ui"

echo -e "\n${CYAN}======================================================================${NC}"
echo -e "${GREEN}🎉 Hoàn tất kiểm tra trạng thái sức khỏe cụm dịch vụ!${NC}"
echo -e "${CYAN}======================================================================${NC}"
