#!/usr/bin/env bash

# ==============================================================================
# XianZhu / Lilishop S2B2C - Interactive Single Artifact Build Script (Docker)
# Mục đích: Cho phép chọn build ĐƠN LẺ từng Service Java hoặc UI Module bằng Menu
# ==============================================================================

set -e

# Tắt tự động convert đường dẫn POSIX trên Git Bash (Windows) khi truyền vào Docker
export MSYS_NO_PATHCONV=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "${SCRIPT_DIR}/source-code" ]; then
    PROJECT_ROOT="${SCRIPT_DIR}"
elif [ -d "${SCRIPT_DIR}/../../source-code" ]; then
    PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
else
    PROJECT_ROOT="${SCRIPT_DIR}"
fi

BUILDS_DIR="${PROJECT_ROOT}/operation/builds"
TIMESTAMP="$(date +'%Y%m%d_%H%M%S')"

MAVEN_CACHE_DIR="${HOME}/.m2"
YARN_CACHE_DIR="${HOME}/.cache/yarn"
mkdir -p "${MAVEN_CACHE_DIR}"
mkdir -p "${YARN_CACHE_DIR}"
mkdir -p "${BUILDS_DIR}/backend"
mkdir -p "${BUILDS_DIR}/frontend"

# Auto-load Maven Nexus Credentials nếu có
if [ -f "${PROJECT_ROOT}/.mvn-credenntials" ]; then
    source "${PROJECT_ROOT}/.mvn-credenntials"
elif [ -f "${PROJECT_ROOT}/.mvn-credentials" ]; then
    source "${PROJECT_ROOT}/.mvn-credentials"
fi

# Màu sắc hiển thị Terminal
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ------------------------------------------------------------------------------
# HÀM BUILD ĐƠN LẺ BACKEND JAVA SERVICE
# ------------------------------------------------------------------------------
build_single_backend() {
    local target_service="$1"
    local branch_name="$2"
    local src_dir="$3"

    echo ""
    echo -e "${CYAN}======================================================================${NC}"
    echo -e "${GREEN}☕ Đang biên dịch Backend Service: [ ${BOLD}${target_service}${NC}${GREEN} ] (Branch: ${branch_name})${NC}"
    echo -e "${CYAN}======================================================================${NC}"

    local mvn_target_arg=""
    if [ "${target_service}" = "all-backend" ]; then
        mvn_target_arg="mvn clean install -DskipTests"
    elif [ "${target_service}" = "gateway" ]; then
        mvn_target_arg="mvn clean install -pl gateway -am -DskipTests"
    elif [ "${target_service}" = "consumer" ]; then
        mvn_target_arg="mvn clean install -pl service/consumer -am -DskipTests"
    else
        mvn_target_arg="mvn clean install -pl service/${target_service} -am -DskipTests"
    fi

    docker run --rm \
        -e NEXUS_USERNAME="${NEXUS_USERNAME}" \
        -e NEXUS_PASSWORD="${NEXUS_PASSWORD}" \
        -v "${src_dir}:/app" \
        -v "${MAVEN_CACHE_DIR}:/root/.m2" \
        -v "${PROJECT_ROOT}/operation/scripts/settings.xml:/root/.m2/settings.xml" \
        -w /app \
        maven:3.9.6-eclipse-temurin-21 \
        sh -c "${mvn_target_arg}"

    echo -e "${YELLOW}📦 Đang thu gom file JAR vào ${BUILDS_DIR}/backend/...${NC}"

    if [ "${target_service}" = "all-backend" ]; then
        # Thu gom tất cả
        for sdir in "${src_dir}/gateway" "${src_dir}/service/consumer" "${src_dir}/service/"*-service; do
            if [ -d "${sdir}" ]; then
                sname=$(basename "${sdir}")
                jar_file=$(find "${sdir}/target" -maxdepth 1 -name "*.jar" ! -name "*-sources.jar" ! -name "*.original" 2>/dev/null | head -n 1)
                if [ -n "${jar_file}" ] && [ -f "${jar_file}" ]; then
                    cp "${jar_file}" "${BUILDS_DIR}/backend/${sname}.jar"
                    echo -e "  ${GREEN}[✓] ${sname} -> builds/backend/${sname}.jar${NC}"
                fi
            fi
        done
    else
        local search_path=""
        if [ "${target_service}" = "gateway" ]; then
            search_path="${src_dir}/gateway/target"
        elif [ "${target_service}" = "consumer" ]; then
            search_path="${src_dir}/service/consumer/target"
        else
            search_path="${src_dir}/service/${target_service}/target"
        fi

        jar_file=$(find "${search_path}" -maxdepth 1 -name "*.jar" ! -name "*-sources.jar" ! -name "*.original" 2>/dev/null | head -n 1)
        if [ -n "${jar_file}" ] && [ -f "${jar_file}" ]; then
            cp "${jar_file}" "${BUILDS_DIR}/backend/${target_service}.jar"
            echo -e "  ${GREEN}[✓] HOÀN TẤT: builds/backend/${target_service}.jar${NC}"
        else
            echo -e "  ${YELLOW}[!] Không tìm thấy file JAR đầu ra tại ${search_path}${NC}"
        fi
    fi
}

# ------------------------------------------------------------------------------
# HÀM BUILD ĐƠN LẺ FRONTEND UI MODULE
# ------------------------------------------------------------------------------
build_single_frontend() {
    local target_module="$1"
    local branch_name="$2"
    local src_dir="$3"

    echo ""
    echo -e "${CYAN}======================================================================${NC}"
    echo -e "${MAGENTA}🎨 Đang biên dịch Frontend UI Module: [ ${BOLD}${target_module}${NC}${MAGENTA} ] (Branch: ${branch_name})${NC}"
    echo -e "${CYAN}======================================================================${NC}"

    local modules_to_build=()
    if [ "${target_module}" = "all-frontend" ]; then
        modules_to_build=("buyer" "seller" "manager" "supplier-platform" "im")
    else
        modules_to_build=("${target_module}")
    fi

    for mod in "${modules_to_build[@]}"; do
        if [ -d "${src_dir}/${mod}" ]; then
            echo -e "${BLUE}🔨 Đang build UI Module: [ ${mod} ] qua Docker (Node 22)...${NC}"
            
            docker run --rm \
                -v "${src_dir}/${mod}:/src_module" \
                -v "${YARN_CACHE_DIR}:/root/.cache/yarn" \
                node:22-alpine \
                sh -c "mkdir -p /tmp/app && cp -r /src_module/* /tmp/app/ 2>/dev/null || true; cd /tmp/app && yarn config set registry https://registry.npmmirror.com && yarn config set strict-ssl false && rm -rf dist && yarn install --ignore-engines --silent && NODE_OPTIONS=--max-old-space-size=4096 yarn --ignore-engines build --mode dev && mkdir -p /src_module/dist && cp -r dist/* /src_module/dist/"

            if [ -d "${src_dir}/${mod}/dist" ]; then
                mkdir -p "${BUILDS_DIR}/frontend/${mod}"
                cp -r "${src_dir}/${mod}/dist"/* "${BUILDS_DIR}/frontend/${mod}/"

                # Cập nhật giá trị API_DEV từ tham số truyền vào script (Mặc định: http://localhost:8888)
                TARGET_API_DEV="${API_DEV:-http://localhost:8888}"
                if [ -f "${BUILDS_DIR}/frontend/${mod}/config.js" ]; then
                    sed -i "s|gateway: *\"[^\"]*\"|gateway: \"${TARGET_API_DEV}\"|1" "${BUILDS_DIR}/frontend/${mod}/config.js" 2>/dev/null || true
                fi
                echo -e "  ${GREEN}[✓] HOÀN TẤT: UI Module ${mod} (API_DEV=${TARGET_API_DEV}) -> builds/frontend/${mod}/${NC}"
            fi
        else
            echo -e "  ${YELLOW}[!] Thư mục ${src_dir}/${mod} không tồn tại!${NC}"
        fi
    done
}

# ------------------------------------------------------------------------------
# HÀM HIỂN THỊ MENU CHỌN TƯƠNG TÁC
# ------------------------------------------------------------------------------
show_menu() {
    clear
    echo -e "${CYAN}======================================================================${NC}"
    echo -e "${BOLD}${GREEN}🚀 XIANZHU S2B2C - CHỌN BIÊN DỊCH ARTIFACT ĐƠN LẺ QUA DOCKER${NC}"
    echo -e "${CYAN}======================================================================${NC}"
    echo -e "Vui lòng chọn Nhánh Mã Nguồn muốn build:"
    echo -e "  ${BOLD}1)${NC} develop  ${GREEN}(Mặc định - Mã nguồn mới nhất)${NC}"
    echo -e "  ${BOLD}2)${NC} master   ${BLUE}(Nhánh chính gộp)${NC}"
    echo -n "👉 Nhập lựa chọn nhánh [1/2] (Mặc định 1): "
    read branch_choice

    local BRANCH_NAME="develop"
    local SRC_BACKEND=""
    local SRC_FRONTEND=""

    if [ "${branch_choice}" = "2" ] || [ "${branch_choice}" = "master" ]; then
        BRANCH_NAME="master"
        SRC_BACKEND="${PROJECT_ROOT}/source-code/S2B2B2C-Service"
        SRC_FRONTEND="${PROJECT_ROOT}/source-code/S2B2B2C-UI"
    else
        BRANCH_NAME="develop"
        if [ -d "${PROJECT_ROOT}/source-code/S2B2B2C-Service-develop" ]; then
            SRC_BACKEND="${PROJECT_ROOT}/source-code/S2B2B2C-Service-develop"
        else
            SRC_BACKEND="${PROJECT_ROOT}/source-code/S2B2B2C-Service"
        fi

        if [ -d "${PROJECT_ROOT}/source-code/S2B2B2C-UI-develop" ]; then
            SRC_FRONTEND="${PROJECT_ROOT}/source-code/S2B2B2C-UI-develop"
        else
            SRC_FRONTEND="${PROJECT_ROOT}/source-code/S2B2B2C-UI"
        fi
    fi

    echo ""
    echo -e "${CYAN}----------------------------------------------------------------------${NC}"
    echo -e "🌿 Đã chọn nhánh: ${BOLD}${GREEN}${BRANCH_NAME}${NC}"
    echo -e "${CYAN}----------------------------------------------------------------------${NC}"
    echo -e "${BOLD}${YELLOW}☕ DANH SÁCH BACKEND JAVA MICROSERVICES:${NC}"
    echo -e "  ${BOLD}1)${NC} gateway              ${BOLD}2)${NC} consumer             ${BOLD}3)${NC} auth-service"
    echo -e "  ${BOLD}4)${NC} user-service         ${BOLD}5)${NC} goods-service        ${BOLD}6)${NC} order-service"
    echo -e "  ${BOLD}7)${NC} payment-service      ${BOLD}8)${NC} promotion-service    ${BOLD}9)${NC} statistics-service"
    echo -e "  ${BOLD}10)${NC} system-service       ${BOLD}11)${NC} supplier-service     ${BOLD}12)${NC} resource-service"
    echo -e "  ${BOLD}13)${NC} broadcast-service    ${BOLD}14)${NC} im-service           ${BOLD}15)${NC} xianzhu-service"
    echo -e "  ${BOLD}16)${NC} distribution-service ${BOLD}17)${NC} [TẤT CẢ BACKEND SERVICES]"
    echo ""
    echo -e "${BOLD}${MAGENTA}🎨 DANH SÁCH FRONTEND UI MODULES:${NC}"
    echo -e "  ${BOLD}18)${NC} buyer (Người mua)    ${BOLD}19)${NC} seller (Người bán)   ${BOLD}20)${NC} manager (Admin)"
    echo -e "  ${BOLD}21)${NC} supplier-platform    ${BOLD}22)${NC} im (Chat UI)         ${BOLD}23)${NC} [TẤT CẢ FRONTEND MODULES]"
    echo ""
    echo -e "  ${BOLD}0)${NC} Thoát"
    echo -e "${CYAN}----------------------------------------------------------------------${NC}"
    echo -n "👉 Nhập số tương ứng với Service / Module bạn muốn build: "
    read option

    case "${option}" in
        1)  build_single_backend "gateway" "${BRANCH_NAME}" "${SRC_BACKEND}" ;;
        2)  build_single_backend "consumer" "${BRANCH_NAME}" "${SRC_BACKEND}" ;;
        3)  build_single_backend "auth-service" "${BRANCH_NAME}" "${SRC_BACKEND}" ;;
        4)  build_single_backend "user-service" "${BRANCH_NAME}" "${SRC_BACKEND}" ;;
        5)  build_single_backend "goods-service" "${BRANCH_NAME}" "${SRC_BACKEND}" ;;
        6)  build_single_backend "order-service" "${BRANCH_NAME}" "${SRC_BACKEND}" ;;
        7)  build_single_backend "payment-service" "${BRANCH_NAME}" "${SRC_BACKEND}" ;;
        8)  build_single_backend "promotion-service" "${BRANCH_NAME}" "${SRC_BACKEND}" ;;
        9)  build_single_backend "statistics-service" "${BRANCH_NAME}" "${SRC_BACKEND}" ;;
        10) build_single_backend "system-service" "${BRANCH_NAME}" "${SRC_BACKEND}" ;;
        11) build_single_backend "supplier-service" "${BRANCH_NAME}" "${SRC_BACKEND}" ;;
        12) build_single_backend "resource-service" "${BRANCH_NAME}" "${SRC_BACKEND}" ;;
        13) build_single_backend "broadcast-service" "${BRANCH_NAME}" "${SRC_BACKEND}" ;;
        14) build_single_backend "im-service" "${BRANCH_NAME}" "${SRC_BACKEND}" ;;
        15) build_single_backend "xianzhu-service" "${BRANCH_NAME}" "${SRC_BACKEND}" ;;
        16) build_single_backend "distribution-service" "${BRANCH_NAME}" "${SRC_BACKEND}" ;;
        17) build_single_backend "all-backend" "${BRANCH_NAME}" "${SRC_BACKEND}" ;;
        18) build_single_frontend "buyer" "${BRANCH_NAME}" "${SRC_FRONTEND}" ;;
        19) build_single_frontend "seller" "${BRANCH_NAME}" "${SRC_FRONTEND}" ;;
        20) build_single_frontend "manager" "${BRANCH_NAME}" "${SRC_FRONTEND}" ;;
        21) build_single_frontend "supplier-platform" "${BRANCH_NAME}" "${SRC_FRONTEND}" ;;
        22) build_single_frontend "im" "${BRANCH_NAME}" "${SRC_FRONTEND}" ;;
        23) build_single_frontend "all-frontend" "${BRANCH_NAME}" "${SRC_FRONTEND}" ;;
        0)  echo "Thoát program."; exit 0 ;;
        *)  echo -e "${YELLOW}Lựa chọn không hợp lệ!${NC}"; exit 1 ;;
    esac
}

# ------------------------------------------------------------------------------
# KHỞI CHẠY (TRUYỀN THAM SỐ HOẶC CHẠY MENU)
# ------------------------------------------------------------------------------
TARGET_ARG="${1}"
BRANCH_ARG="${2:-develop}"

if [ -z "${TARGET_ARG}" ]; then
    show_menu
else
    BRANCH_NAME="develop"
    if [ "${BRANCH_ARG}" = "master" ]; then
        BRANCH_NAME="master"
        SRC_BACKEND="${PROJECT_ROOT}/source-code/S2B2B2C-Service"
        SRC_FRONTEND="${PROJECT_ROOT}/source-code/S2B2B2C-UI"
    else
        BRANCH_NAME="develop"
        if [ -d "${PROJECT_ROOT}/source-code/S2B2B2C-Service-develop" ]; then
            SRC_BACKEND="${PROJECT_ROOT}/source-code/S2B2B2C-Service-develop"
        else
            SRC_BACKEND="${PROJECT_ROOT}/source-code/S2B2B2C-Service"
        fi

        if [ -d "${PROJECT_ROOT}/source-code/S2B2B2C-UI-develop" ]; then
            SRC_FRONTEND="${PROJECT_ROOT}/source-code/S2B2B2C-UI-develop"
        else
            SRC_FRONTEND="${PROJECT_ROOT}/source-code/S2B2B2C-UI"
        fi
    fi

    case "${TARGET_ARG}" in
        buyer|seller|manager|supplier-platform|im)
            build_single_frontend "${TARGET_ARG}" "${BRANCH_NAME}" "${SRC_FRONTEND}"
            ;;
        gateway|consumer|auth-service|user-service|goods-service|order-service|payment-service|promotion-service|statistics-service|system-service|supplier-service|resource-service|broadcast-service|im-service|xianzhu-service|distribution-service)
            build_single_backend "${TARGET_ARG}" "${BRANCH_NAME}" "${SRC_BACKEND}"
            ;;
        *)
            echo -e "${YELLOW}Lỗi: Tên service/module không hợp lệ! Hãy chạy không tham số để mở Menu.${NC}"
            exit 1
            ;;
    esac
fi
