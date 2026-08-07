#!/usr/bin/env bash

# ==============================================================================
# XianZhu / Lilishop S2B2C - Containerized Artifacts Collector Script (Docker)
# Mục đích: Biên dịch toàn bộ Backend (Java) & Frontend (UI) BẰNG DOCKER CONTAINER
#          mặc định sử dụng nguồn nhánh 'develop', chỉ đổi sang 'master' khi truyền tham số.
# ==============================================================================

set -e

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

# ------------------------------------------------------------------------------
# PHÂN TÍCH THAM SỐ VÀ CẤU HÌNH NHÁNH (MẶC ĐỊNH DEVELOP)
# ------------------------------------------------------------------------------
MODE="${1:-all}"
BRANCH="${2:-develop}"

# Nếu tham số 1 truyền trực tiếp là 'master' hoặc 'develop', tự động gán Mode=all & Branch=$1
if [ "${MODE}" = "master" ] || [ "${MODE}" = "develop" ]; then
    BRANCH="${MODE}"
    MODE="all"
fi

if [ "${BRANCH}" = "master" ]; then
    TARGET_BACKEND_SRC="${PROJECT_ROOT}/source-code/S2B2B2C-Service"
    TARGET_FRONTEND_SRC="${PROJECT_ROOT}/source-code/S2B2B2C-UI"
    BRANCH_NAME="master"
else
    BRANCH_NAME="develop"
    if [ -d "${PROJECT_ROOT}/source-code/S2B2B2C-Service-develop" ]; then
        TARGET_BACKEND_SRC="${PROJECT_ROOT}/source-code/S2B2B2C-Service-develop"
    else
        TARGET_BACKEND_SRC="${PROJECT_ROOT}/source-code/S2B2B2C-Service"
    fi

    if [ -d "${PROJECT_ROOT}/source-code/S2B2B2C-UI-develop" ]; then
        TARGET_FRONTEND_SRC="${PROJECT_ROOT}/source-code/S2B2B2C-UI-develop"
    else
        TARGET_FRONTEND_SRC="${PROJECT_ROOT}/source-code/S2B2B2C-UI"
    fi
fi

# Thư mục Cache trên Host để tăng tốc độ build
MAVEN_CACHE_DIR="${HOME}/.m2"
YARN_CACHE_DIR="${HOME}/.cache/yarn"
mkdir -p "${MAVEN_CACHE_DIR}"
mkdir -p "${YARN_CACHE_DIR}"
mkdir -p "${BUILDS_DIR}/backend"
mkdir -p "${BUILDS_DIR}/frontend"

echo "======================================================================"
echo "🐳 Khởi chạy Script Build Artifacts Qua Docker Container"
echo "📅 Thời gian: ${TIMESTAMP}"
echo "🌿 Nhánh mã nguồn sử dụng: [ ${BRANCH_NAME} ]"
echo "📂 Backend Source:  ${TARGET_BACKEND_SRC}"
echo "📂 Frontend Source: ${TARGET_FRONTEND_SRC}"
echo "📁 Thư mục xuất Artifacts: ${BUILDS_DIR}"
echo "======================================================================"

# Auto-load Maven Nexus Credentials nếu có
if [ -f "${PROJECT_ROOT}/.mvn-credenntials" ]; then
    source "${PROJECT_ROOT}/.mvn-credenntials"
elif [ -f "${PROJECT_ROOT}/.mvn-credentials" ]; then
    source "${PROJECT_ROOT}/.mvn-credentials"
fi

# ------------------------------------------------------------------------------
# 1. BIÊN DỊCH BACKEND JAVA QUA DOCKER CONTAINER (maven:3.9.6-eclipse-temurin-21)
# ------------------------------------------------------------------------------
build_backend_docker() {
    echo ""
    echo "======================================================================"
    echo "☕ [1/2] Đang biên dịch Backend Java trong Docker Container (${BRANCH_NAME})..."
    echo "======================================================================"

    docker run --rm \
        -e NEXUS_USERNAME="${NEXUS_USERNAME}" \
        -e NEXUS_PASSWORD="${NEXUS_PASSWORD}" \
        -v "${TARGET_BACKEND_SRC}:/app" \
        -v "${MAVEN_CACHE_DIR}:/root/.m2" \
        -v "${PROJECT_ROOT}/operation/deployment/settings.xml:/root/.m2/settings.xml" \
        -w /app \
        maven:3.9.6-eclipse-temurin-21 \
        mvn clean install -DskipTests

    echo "📦 Đang thu gom các file Backend JAR vào ${BUILDS_DIR}/backend/..."

    BACKEND_DIR="${TARGET_BACKEND_SRC}"

    # 1. Gateway
    gateway_jar=$(find "${BACKEND_DIR}/gateway/target" -maxdepth 1 -name "*.jar" ! -name "*-sources.jar" ! -name "*.original" 2>/dev/null | head -n 1)
    if [ -n "${gateway_jar}" ] && [ -f "${gateway_jar}" ]; then
        cp "${gateway_jar}" "${BUILDS_DIR}/backend/gateway.jar"
        echo "  [✓] Gateway JAR -> builds/backend/gateway.jar"
    fi

    # 2. Consumer
    consumer_jar=$(find "${BACKEND_DIR}/service/consumer/target" -maxdepth 1 -name "*.jar" ! -name "*-sources.jar" ! -name "*.original" 2>/dev/null | head -n 1)
    if [ -n "${consumer_jar}" ] && [ -f "${consumer_jar}" ]; then
        cp "${consumer_jar}" "${BUILDS_DIR}/backend/consumer.jar"
        echo "  [✓] Consumer JAR -> builds/backend/consumer.jar"
    fi

    # 3. Các Microservices trong service/*-service/
    for service_dir in "${BACKEND_DIR}/service/"*-service; do
        if [ -d "${service_dir}" ]; then
            service_name=$(basename "${service_dir}")
            target_jar=$(find "${service_dir}/target" -maxdepth 1 -name "*.jar" ! -name "*-sources.jar" ! -name "*.original" 2>/dev/null | head -n 1)
            if [ -n "${target_jar}" ] && [ -f "${target_jar}" ]; then
                cp "${target_jar}" "${BUILDS_DIR}/backend/${service_name}.jar"
                echo "  [✓] ${service_name} -> builds/backend/${service_name}.jar"
            fi
        fi
    done
}

# ------------------------------------------------------------------------------
# 2. BIÊN DỊCH FRONTEND UI QUA DOCKER CONTAINER (node:22-alpine)
# ------------------------------------------------------------------------------
build_frontend_docker() {
    echo ""
    echo "======================================================================"
    echo "🎨 [2/2] Đang biên dịch Frontend UI Modules trong Docker Container (${BRANCH_NAME})..."
    echo "======================================================================"

    UI_MODULES=("buyer" "seller" "manager" "supplier-platform" "im")

    for module in "${UI_MODULES[@]}"; do
        if [ -d "${TARGET_FRONTEND_SRC}/${module}" ]; then
            echo "🔨 Đang build UI Module: [ ${module} ] qua Docker (${BRANCH_NAME})..."
            
            docker run --rm \
                -v "${TARGET_FRONTEND_SRC}/${module}:/src_module" \
                -v "${YARN_CACHE_DIR}:/root/.cache/yarn" \
                node:22-alpine \
                sh -c "mkdir -p /tmp/app && cp -r /src_module/* /tmp/app/ 2>/dev/null || true; cd /tmp/app && yarn config set registry https://registry.npmmirror.com && yarn config set strict-ssl false && rm -rf dist && yarn install --ignore-engines --silent && NODE_OPTIONS=--max-old-space-size=4096 yarn --ignore-engines build && mkdir -p /src_module/dist && cp -r dist/* /src_module/dist/"

            if [ -d "${TARGET_FRONTEND_SRC}/${module}/dist" ]; then
                mkdir -p "${BUILDS_DIR}/frontend/${module}"
                cp -r "${TARGET_FRONTEND_SRC}/${module}/dist"/* "${BUILDS_DIR}/frontend/${module}/"
                echo "  [✓] UI Module ${module} -> builds/frontend/${module}/"
            fi
        fi
    done
}

# ------------------------------------------------------------------------------
# 3. TẠO FILE METADATA CHO BẢN BUILD
# ------------------------------------------------------------------------------
generate_metadata() {
    GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "N/A")

    cat <<EOF > "${BUILDS_DIR}/metadata.json"
{
  "project": "XianZhu-S2B2C",
  "build_type": "docker-containerized",
  "build_branch": "${BRANCH_NAME}",
  "build_time": "${TIMESTAMP}",
  "git_commit": "${GIT_COMMIT}",
  "artifacts": {
    "backend_jars": [
$(find "${BUILDS_DIR}/backend" -name "*.jar" -exec basename {} \; 2>/dev/null | sed 's/^/      "/' | sed 's/$/",/' | sed '$ s/,$//')
    ],
    "frontend_modules": [
$(find "${BUILDS_DIR}/frontend" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; 2>/dev/null | sed 's/^/      "/' | sed 's/$/",/' | sed '$ s/,$//')
    ]
  }
}
EOF
    echo "📄 Đã tạo file thống kê builds/metadata.json"
}

# ------------------------------------------------------------------------------
# THỰC THI CHÍNH
# ------------------------------------------------------------------------------
case "${MODE}" in
    backend)
        build_backend_docker
        ;;
    frontend)
        build_frontend_docker
        ;;
    all)
        build_backend_docker
        build_frontend_docker
        ;;
    *)
        echo "Lỗi: Tham số không hợp lệ! Sử dụng: $0 [all|backend|frontend] [develop|master]"
        exit 1
        ;;
esac

generate_metadata

echo ""
echo "======================================================================"
echo "🎉 HOÀN TẤT BẢN BUILD ARTIFACTS QUA DOCKER (BRANCH: ${BRANCH_NAME})!"
echo "📁 Cấu trúc thư mục artifacts tại: ${BUILDS_DIR}"
echo "======================================================================"
