#!/bin/bash
# =============================================================================
# Telegram 监控告警系统 - 启动脚本
# =============================================================================
# 功能：启动/停止/重启服务，安装依赖，查看状态
# 使用：./start.sh [命令] [选项]
# =============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目路径
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$PROJECT_DIR/backend"
FRONTEND_DIR="$PROJECT_DIR/frontend"
VENV_DIR="$BACKEND_DIR/venv"

# =============================================================================
# 辅助函数
# =============================================================================

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}➜ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# =============================================================================
# 环境检查
# =============================================================================

check_python() {
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 未安装"
        echo "请先安装 Python 3.12+"
        exit 1
    fi

    PYTHON_VERSION=$(python3 --version | awk '{print $2}')
    PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
    PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)

    if [ "$PYTHON_MAJOR" -lt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 12 ]); then
        print_error "Python 版本过低 (当前: $PYTHON_VERSION，需要: 3.12+)"
        exit 1
    fi

    print_success "Python 版本: $PYTHON_VERSION"
}

check_node() {
    if ! command -v node &> /dev/null; then
        print_error "Node.js 未安装"
        echo "请先安装 Node.js 18+"
        exit 1
    fi

    NODE_VERSION=$(node --version | cut -d'v' -f2)
    NODE_MAJOR=$(echo $NODE_VERSION | cut -d. -f1)

    if [ "$NODE_MAJOR" -lt 18 ]; then
        print_error "Node.js 版本过低 (当前: $NODE_VERSION，需要: 18+)"
        exit 1
    fi

    print_success "Node.js 版本: $NODE_VERSION"
}

check_mysql() {
    if command -v mysql &> /dev/null; then
        if mysql -u tgmonitor -pTgMonitor2026Secure -e "SELECT 1" &> /dev/null; then
            print_success "MySQL 连接正常"
            return 0
        fi
    fi
    print_warning "MySQL 未配置或无法连接"
    return 1
}

# =============================================================================
# 安装依赖
# =============================================================================

install_backend() {
    print_header "安装后端依赖"

    cd "$BACKEND_DIR"

    # 检查虚拟环境
    if [ ! -d "$VENV_DIR" ]; then
        print_info "创建 Python 虚拟环境..."
        python3 -m venv venv
    fi

    # 激活虚拟环境
    source "$VENV_DIR/bin/activate"

    # 升级 pip
    print_info "升级 pip..."
    pip install --upgrade pip -q

    # 安装依赖
    print_info "安装 Python 依赖..."
    pip install -r requirements.txt -q

    print_success "后端依赖安装完成"
}

install_frontend() {
    print_header "安装前端依赖"

    cd "$FRONTEND_DIR"

    if [ ! -d "node_modules" ]; then
        print_info "安装 npm 依赖..."
        npm install
    else
        print_info "npm 依赖已存在，跳过"
    fi

    print_success "前端依赖安装完成"
}

install_all() {
    print_header "安装所有依赖"
    install_backend
    install_frontend
    print_success "所有依赖安装完成！"
}

# =============================================================================
# 服务管理
# =============================================================================

start_backend() {
    print_header "启动后端服务"

    cd "$BACKEND_DIR"

    # 检查是否已在运行
    if pgrep -f "gunicorn app.main:app" > /dev/null || pgrep -f "uvicorn app.main:app" > /dev/null; then
        print_warning "后端服务已在运行"
        return
    fi

    # 激活虚拟环境
    source "$VENV_DIR/bin/activate"

    # 检查环境变量文件
    if [ ! -f ".env" ]; then
        print_warning ".env 文件不存在，使用默认配置"
    fi

    # 使用 Gunicorn 启动（生产环境）
    # 注意：使用单 Worker 模式，因为 Telegram 客户端不支持多进程
    # 每个 Worker 都会创建独立的客户端连接，导致资源浪费和竞争
    print_info "使用 Gunicorn 启动后端服务（单 Worker 模式）..."
    export HTTP_PROXY=http://127.0.0.1:7890
    export HTTPS_PROXY=http://127.0.0.1:7890
    export NO_PROXY=localhost,127.0.0.1,192.168.0.0/16,10.0.0.0/8
    nohup ./venv/bin/gunicorn app.main:app \
        --bind 0.0.0.0:8000 \
        --workers 1 \
        --worker-class uvicorn.workers.UvicornWorker \
        --timeout 120 \
        --keep-alive 30 \
        --backlog 4096 \
        --log-level info \
        --daemon \
        --access-logfile /tmp/tg-monitor-access.log \
        --error-logfile /tmp/tg-monitor-error.log \
        --max-requests 10000 \
        --max-requests-jitter 1000 \
        > /tmp/tg-monitor.log 2>&1

    sleep 3

    if pgrep -f "gunicorn app.main:app" > /dev/null; then
        print_success "后端服务启动成功 (PID: $(pgrep -f 'gunicorn app.main:app' | head -1 | awk '{print $1}'))"
        print_info "后端地址: http://localhost:8000"
        print_info "API 文档: http://localhost:8000/docs"
    else
        print_error "后端服务启动失败"
        print_info "查看日志: tail -f /tmp/tg-monitor.log"
        exit 1
    fi
}

start_frontend() {
    print_header "启动前端服务"

    cd "$FRONTEND_DIR"

    # 检查是否已在运行
    if pgrep -f "vite.*5173" > /dev/null; then
        print_warning "前端服务已在运行"
        return
    fi

    # 检查依赖
    if [ ! -d "node_modules" ]; then
        print_error "前端依赖未安装"
        print_info "请先运行: ./start.sh install"
        exit 1
    fi

    # 启动开发服务器
    print_info "启动前端开发服务器..."
    nohup npm run dev > /tmp/tg-frontend.log 2>&1 &

    sleep 3

    if pgrep -f "vite.*5173" > /dev/null; then
        print_success "前端服务启动成功 (PID: $(pgrep -f 'vite.*5173' | head -1 | awk '{print $1}'))"
        print_info "前端地址: http://localhost:5173"
    else
        print_error "前端服务启动失败"
        print_info "查看日志: tail -f /tmp/tg-frontend.log"
        exit 1
    fi
}

start_all() {
    print_header "启动所有服务"
    start_backend
    start_frontend
    print_success "所有服务启动完成！"
}

stop_backend() {
    print_header "停止后端服务"

    if pgrep -f "gunicorn app.main:app" > /dev/null; then
        pkill -f "gunicorn app.main:app"
        print_success "后端服务已停止"
    elif pgrep -f "uvicorn app.main:app" > /dev/null; then
        pkill -f "uvicorn app.main:app"
        print_success "后端服务已停止"
    else
        print_info "后端服务未运行"
    fi
}

stop_frontend() {
    print_header "停止前端服务"

    if pgrep -f "vite.*5173" > /dev/null; then
        pkill -f "vite.*5173"
        print_success "前端服务已停止"
    else
        print_info "前端服务未运行"
    fi
}

stop_all() {
    print_header "停止所有服务"
    stop_backend
    stop_frontend
    print_success "所有服务已停止"
}

restart_backend() {
    stop_backend
    sleep 2
    start_backend
}

restart_frontend() {
    stop_frontend
    sleep 2
    start_frontend
}

restart_all() {
    stop_all
    sleep 2
    start_all
}

# =============================================================================
# 状态查看
# =============================================================================

show_status() {
    print_header "服务状态"

    # 后端状态
    echo -e "\n${BLUE}【后端服务】${NC}"
    if pgrep -f "gunicorn app.main:app" > /dev/null; then
        PIDS=$(pgrep -f "gunicorn app.main:app")
        COUNT=$(echo "$PIDS" | wc -l)
        echo -e "  状态: ${GREEN}运行中${NC} (Gunicorn)"
        echo -e "  进程数: $COUNT"
        echo -e "  PID: $(echo $PIDS | tr '\n' ' ')"
        echo -e "  地址: http://localhost:8000"
    elif pgrep -f "uvicorn app.main:app" > /dev/null; then
        echo -e "  状态: ${GREEN}运行中${NC} (Uvicorn)"
        echo -e "  PID: $(pgrep -f 'uvicorn app.main:app' | head -1 | awk '{print $1}')"
        echo -e "  地址: http://localhost:8000"
    else
        echo -e "  状态: ${RED}未运行${NC}"
    fi

    # 前端状态
    echo -e "\n${BLUE}【前端服务】${NC}"
    if pgrep -f "vite.*5173" > /dev/null; then
        echo -e "  状态: ${GREEN}运行中${NC}"
        echo -e "  PID: $(pgrep -f 'vite.*5173' | head -1 | awk '{print $1}')"
        echo -e "  地址: http://localhost:5173"
    else
        echo -e "  状态: ${RED}未运行${NC}"
    fi

    # MySQL 状态
    echo -e "\n${BLUE}【数据库】${NC}"
    if check_mysql; then
        echo -e "  状态: ${GREEN}正常${NC}"
    else
        echo -e "  状态: ${YELLOW}未配置或无法连接${NC}"
    fi
}

show_logs() {
    local SERVICE=${1:-backend}

    case $SERVICE in
        backend)
            print_header "后端日志"
            tail -f /tmp/tg-monitor.log
            ;;
        frontend)
            print_header "前端日志"
            tail -f /tmp/tg-frontend.log
            ;;
        access)
            print_header "访问日志"
            tail -f /tmp/tg-monitor-access.log
            ;;
        error)
            print_header "错误日志"
            tail -f /tmp/tg-monitor-error.log
            ;;
        *)
            print_error "未知服务: $SERVICE"
            echo "可用选项: backend, frontend, access, error"
            exit 1
            ;;
    esac
}

# =============================================================================
# 工具函数
# =============================================================================

clean_logs() {
    print_header "清理日志文件"

    > /tmp/tg-monitor.log
    > /tmp/tg-frontend.log
    > /tmp/tg-monitor-access.log
    > /tmp/tg-monitor-error.log

    print_success "日志文件已清理"
}

clean_backups() {
    print_header "清理旧备份"

    BACKUP_DIR="$BACKEND_DIR/backups"
    if [ -d "$BACKUP_DIR" ]; then
        # 保留最新5个备份
        ls -t "$BACKUP_DIR" | tail -n +6 | xargs -I {} rm -rf "$BACKUP_DIR/{}" 2>/dev/null
        print_success "旧备份已清理（保留最新5个）"
    else
        print_info "备份目录不存在"
    fi
}

show_help() {
    cat << EOF
${BLUE}Telegram 监控告警系统 - 启动脚本${NC}

${YELLOW}用法:${NC}
  ./start.sh [命令] [选项]

${YELLOW}命令:${NC}
  install         安装所有依赖
  install-backend 安装后端依赖
  install-frontend 安装前端依赖

  start           启动所有服务
  start-backend   启动后端服务
  start-frontend  启动前端服务

  stop            停止所有服务
  stop-backend    停止后端服务
  stop-frontend   停止前端服务

  restart         重启所有服务
  restart-backend 重启后端服务
  restart-frontend 重启前端服务

  status          查看服务状态
  logs [服务]     查看日志 (backend/frontend/access/error)

  clean-logs      清理日志文件
  clean-backups   清理旧备份

  help            显示帮助信息

${YELLOW}示例:${NC}
  ./start.sh install          # 安装依赖
  ./start.sh start            # 启动服务
  ./start.sh status           # 查看状态
  ./start.sh logs backend     # 查看后端日志
  ./start.sh logs access      # 查看访问日志

${YELLOW}服务地址:${NC}
  后端: http://localhost:8000
  前端: http://localhost:5173
  API:  http://localhost:8000/docs

EOF
}

# =============================================================================
# 主程序
# =============================================================================

main() {
    local COMMAND=${1:-help}

    case $COMMAND in
        install)
            install_all
            ;;
        install-backend)
            install_backend
            ;;
        install-frontend)
            install_frontend
            ;;
        start)
            start_all
            ;;
        start-backend)
            start_backend
            ;;
        start-frontend)
            start_frontend
            ;;
        stop)
            stop_all
            ;;
        stop-backend)
            stop_backend
            ;;
        stop-frontend)
            stop_frontend
            ;;
        restart)
            restart_all
            ;;
        restart-backend)
            restart_backend
            ;;
        restart-frontend)
            restart_frontend
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs "${2:-backend}"
            ;;
        clean-logs)
            clean_logs
            ;;
        clean-backups)
            clean_backups
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "未知命令: $COMMAND"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 运行主程序
main "$@"
