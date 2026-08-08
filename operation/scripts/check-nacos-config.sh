#!/usr/bin/env bash

# ==============================================================================
# XianZhu S2B2C - Script kiểm tra Nacos Configurations tồn tại (Bash version)
# Chạy: ./operation/scripts/check-nacos-config.sh
# ==============================================================================

NACOS_URL="${NACOS_URL:-http://localhost:8848/nacos}"
NAMESPACE_ID="${NAMESPACE_ID:-middle}"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

# Danh sách Data ID (DEFAULT_GROUP)
DEFAULT_CONFIGS=(
    "application-dev.yml"
    "gateway-dev.yml"
    "auth-service.yml"
    "user-service.yml"
    "goods-service.yml"
    "order-service.yml"
    "payment-service.yml"
    "promotion-service.yml"
    "statistics-service.yml"
    "system-service.yml"
    "supplier-service.yml"
    "resource-service.yml"
    "broadcast-service.yml"
    "im-service.yml"
    "distribution-service.yml"
    "xianzhu-service.yml"
)

echo -e "${CYAN}======================================================================${NC}"
echo -e "${BOLD}${GREEN}🔍 CHECKING NACOS CONFIGURATIONS (Namespace: '${NAMESPACE_ID}')${NC}"
echo -e "${CYAN}======================================================================${NC}"

MISSING_COUNT=0
SUCCESS_COUNT=0

check_config() {
    local data_id="$1"
    local group="$2"

    local response
    response=$(curl -s -X GET "${NACOS_URL}/v1/cs/configs?dataId=${data_id}&group=${group}&tenant=${NAMESPACE_ID}")

    if [[ -n "$response" && "$response" != *"config data not exist"* && "$response" != *"404"* ]]; then
        local bytes=${#response}
        printf "  [ %bOK%b ] Data ID: %-28s | Group: %-13s | Size: %d bytes\n" "${GREEN}${BOLD}" "${NC}" "${data_id}" "${group}" "${bytes}"
        ((SUCCESS_COUNT++))
    else
        printf "  [ %bMISSING%b ] Data ID: %-28s | Group: %-13s\n" "${RED}${BOLD}" "${NC}" "${data_id}" "${group}"
        ((MISSING_COUNT++))
    fi
}

# 1. Kiểm tra các config thuộc DEFAULT_GROUP
for cfg in "${DEFAULT_CONFIGS[@]}"; do
    check_config "${cfg}" "DEFAULT_GROUP"
done

# 2. Kiểm tra seataServer.properties thuộc SEATA_GROUP
check_config "seataServer.properties" "SEATA_GROUP"

TOTAL_CONFIGS=$((SUCCESS_COUNT + MISSING_COUNT))

echo -e "${CYAN}======================================================================${NC}"
if [ "${MISSING_COUNT}" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}🎉 SUCCESS: Tất cả ${SUCCESS_COUNT}/${TOTAL_CONFIGS} Nacos Configs đã TỒN TẠI!${NC}"
else
    echo -e "${RED}${BOLD}⚠️  WARNING: Có ${MISSING_COUNT} Nacos Configs đang BỊ THIẾU!${NC}"
    echo -e "${YELLOW}Vui lòng chạy: python operation/scripts/init-nacos-config.py${NC}"
fi
echo -e "${CYAN}======================================================================${NC}"
