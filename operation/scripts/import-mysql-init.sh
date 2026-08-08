#!/usr/bin/env bash

# ==============================================================================
# XianZhu S2B2C - Script khởi tạo MySQL Database trong Docker (Bash version)
# Chạy: ./operation/scripts/import-mysql-init.sh
# ==============================================================================

CONTAINER_NAME="${CONTAINER_NAME:-xianzhu-mysql}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASS="${MYSQL_PASS:-lilishop}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_DIR="${SCRIPT_DIR}/../../source-code/S2B2B2C-Service-develop/docker/dev/mysql/init"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

if [ ! -d "${SQL_DIR}" ]; then
    echo -e "${RED}Error: Thư mục chứa file SQL không tồn tại: ${SQL_DIR}${NC}"
    exit 1
fi

echo -e "${CYAN}======================================================================${NC}"
echo -e "${BOLD}${GREEN}📦 IMPORTING MYSQL INIT SCRIPTS INTO CONTAINER: ${CONTAINER_NAME}${NC}"
echo -e "${CYAN}======================================================================${NC}"

# Lấy danh sách file .sql và sắp xếp theo thứ tự tên file
if [ ! -d "${SQL_DIR}" ]; then
    echo -e "${RED}Error: Thư mục chứa file SQL không tồn tại: ${SQL_DIR}${NC}"
    exit 1
fi

find "${SQL_DIR}" -maxdepth 1 -name "*.sql" | sort | while read -r sql_file; do
    filename=$(basename "${sql_file}")
    echo -ne "Importing ${filename} ... "

    err_output=$(docker exec -i "${CONTAINER_NAME}" mysql -u"${MYSQL_USER}" -p"${MYSQL_PASS}" --default-character-set=utf8mb4 < "${sql_file}" 2>&1)
    ret_code=$?

    if [ ${ret_code} -eq 0 ]; then
        echo -e "[ ${GREEN}${BOLD}OK${NC} ]"
    else
        echo -e "[ ${RED}${BOLD}ERR${NC} ]"
        echo -e "  ${YELLOW}${err_output}${NC}"
    fi
done

echo -e "${CYAN}======================================================================${NC}"
echo -e "${GREEN}${BOLD}🎉 Khởi tạo dữ liệu MySQL hoàn tất!${NC}"
echo -e "${CYAN}======================================================================${NC}"
