#!/usr/bin/env bash

# ==============================================================================
# XianZhu S2B2C - Script khởi tạo Nacos Configurations (Bash version)
# Chạy: ./operation/scripts/init-nacos-config.sh
# ==============================================================================

NACOS_URL="${NACOS_URL:-http://localhost:8848/nacos}"
NAMESPACE_ID="${NAMESPACE_ID:-middle}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/nacos-config/config"
SEATA_FILE="${SCRIPT_DIR}/nacos-config/seataServer.properties"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}======================================================================${NC}"
echo -e "${BOLD}${GREEN}🚀 IMPORTING NACOS CONFIGURATIONS FROM: ${CONFIG_DIR}${NC}"
echo -e "${CYAN}======================================================================${NC}"

# 1. Tạo Namespace nếu chưa có
echo -e "${YELLOW}[1/3] Creating Namespace '${NAMESPACE_ID}'...${NC}"
create_res=$(curl -s -X POST "${NACOS_URL}/v1/console/namespaces" \
    --data-urlencode "customNamespaceId=${NAMESPACE_ID}" \
    --data-urlencode "namespaceName=${NAMESPACE_ID}" \
    --data-urlencode "namespaceDesc=Local development")
echo -e "  Result: ${create_res}"

# Hàm publish 1 config file
publish_config() {
    local file_path="$1"
    local group="$2"
    local config_type="$3"
    local data_id
    data_id=$(basename "${file_path}")

    local res
    res=$(curl -s -X POST "${NACOS_URL}/v1/cs/configs" \
        --data-urlencode "tenant=${NAMESPACE_ID}" \
        --data-urlencode "group=${group}" \
        --data-urlencode "dataId=${data_id}" \
        --data-urlencode "type=${config_type}" \
        --data-urlencode "content=$(cat "${file_path}")")

    if [ "${res}" = "true" ]; then
        printf "  [ %bOK%b ] Published %-28s (Group: %s)\n" "${GREEN}${BOLD}" "${NC}" "${data_id}" "${group}"
    else
        printf "  [ %bERR%b ] Failed %-28s (Group: %s): %s\n" "${RED}${BOLD}" "${NC}" "${data_id}" "${group}" "${res}"
    fi
}

# 2. Publish các file .yml (DEFAULT_GROUP)
echo -e "\n${YELLOW}[2/3] Publishing YAML configs to DEFAULT_GROUP...${NC}"
if [ -d "${CONFIG_DIR}" ]; then
    for yml_file in "${CONFIG_DIR}"/*.yml; do
        if [ -f "${yml_file}" ]; then
            publish_config "${yml_file}" "DEFAULT_GROUP" "yaml"
        fi
    done
else
    echo -e "  ${RED}Config directory not found: ${CONFIG_DIR}${NC}"
fi

# 3. Publish seataServer.properties (SEATA_GROUP)
echo -e "\n${YELLOW}[3/3] Publishing Seata config to SEATA_GROUP...${NC}"
if [ -f "${SEATA_FILE}" ]; then
    publish_config "${SEATA_FILE}" "SEATA_GROUP" "properties"
else
    echo -e "  ${RED}Seata file not found: ${SEATA_FILE}${NC}"
fi

echo -e "${CYAN}======================================================================${NC}"
echo -e "${GREEN}${BOLD}🎉 Tất cả Nacos Configurations đã được nạp thành công!${NC}"
echo -e "${CYAN}======================================================================${NC}"
