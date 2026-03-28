#!/bin/bash
# =============================================================================
# TG 监控系统自动恢复脚本
# =============================================================================
# 当服务出现问题时自动重启
# 建议添加到 crontab 每 5 分钟运行一次
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 项目路径
PROJECT_DIR="/home/xingchuan/桌面/tgjiankong"
RESTART_LOG="$PROJECT_DIR/logs/auto-restart.log"
ALERT_SENT="$PROJECT_DIR/.alert_sent_flag"
LOCK_FILE="/tmp/tg-auto-restart-running.lock"
MIN_RESTART_INTERVAL=300  # 最小重启间隔 5 分钟

mkdir -p "$(dirname "$RESTART_LOG")"

# 辅助函数
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$RESTART_LOG"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✓ $1${NC}" | tee -a "$RESTART_LOG"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ✗ $1${NC}" | tee -a "$RESTART_LOG"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠ $1${NC}" | tee -a "$RESTART_LOG"
}

# 检查是否已有脚本在运行
check_running() {
    if [ -f "$LOCK_FILE" ]; then
        local pid=$(cat "$LOCK_FILE" 2>/dev/null)
        if [ -n "$pid" ] && ps -p "$pid" > /dev/null 2>&1; then
            log "已有重启脚本在运行 (PID: $pid)，跳过本次检查"
            exit 0
        else
            # 锁文件存在但进程不存在，清理锁
            rm -f "$LOCK_FILE"
        fi
    fi

    # 创建锁文件
    echo $$ > "$LOCK_FILE"
    trap 'rm -f "$LOCK_FILE"' EXIT
}

# 检查重启间隔
check_restart_interval() {
    if [ -f "$PROJECT_DIR/.last_restart" ]; then
        local last_restart=$(cat "$PROJECT_DIR/.last_restart" 2>/dev/null)
        local now=$(date +%s)
        local diff=$((now - last_restart))

        if [ "$diff" -lt "$MIN_RESTART_INTERVAL" ]; then
            log "距离上次重启仅 ${diff} 秒，需要等待 $((MIN_RESTART_INTERVAL - diff)) 秒"
            return 1
        fi
    fi
    return 0
}

# 检查后端是否需要重启
need_restart() {
    # 1. 检查进程是否存在
    if ! pgrep -f "gunicorn app.main:app" > /dev/null; then
        log "进程未运行，需要重启"
        return 0
    fi

    # 2. 检查 API 是否响应（增加超时和重试）
    local response_ok=false
    for i in {1..3}; do
        if curl -s --max-time 5 http://localhost:8000/health > /dev/null 2>&1; then
            response_ok=true
            break
        fi
        sleep 2
    done

    if ! $response_ok; then
        log "API 无响应（重试3次失败），需要重启"
        return 0
    fi

    # 3. 检查 CPU 是否持续过高（可能是死循环）
    local pid=$(pgrep -f "gunicorn app.main:app" | head -1)
    if [ -n "$pid" ]; then
        local cpu=$(ps -p "$pid" -o %cpu --no-headers | tr -d ' ')
        # CPU > 90% 持续高可能是卡死
        if (( $(echo "$cpu > 90" | bc -l) )); then
            log_warning "CPU 使用率过高 (${cpu}%)"

            # 检查进程运行时间，避免误判启动阶段
            local elapsed=$(ps -p "$pid" -o etimes --no-headers | tr -d ' ')
            if [ "$elapsed" -gt 300 ]; then
                log "CPU 持续过高超过 5 分钟，需要重启"
                return 0
            fi
        fi
    fi

    # 4. 检查内存是否持续增长（内存泄漏）
    local mem=$(ps -p "$pid" -o rss --no-headers | tr -d ' ')
    local mem_mb=$((mem / 1024))
    if [ "$mem_mb" -gt 2000 ]; then
        log_warning "内存使用过高 (${mem_mb}MB)，可能内存泄漏"
        return 0
    fi

    return 1
}

# 重启服务
restart_service() {
    # 记录重启时间
    date +%s > "$PROJECT_DIR/.last_restart"

    log "开始重启后端服务..."

    # 停止旧进程
    log "停止旧进程..."
    pkill -9 -f "gunicorn app.main:app" 2>/dev/null || true
    pkill -9 -f "uvicorn app.main" 2>/dev/null || true
    rm -f /tmp/tg-auto-backup.lock 2>/dev/null || true

    sleep 5

    # 启动新进程
    log "启动新进程..."
    cd "$PROJECT_DIR/backend"
    source venv/bin/activate
    nohup ./venv/bin/gunicorn app.main:app \
        --bind 0.0.0.0:8000 \
        --workers 1 \
        --worker-class uvicorn.workers.UvicornWorker \
        --timeout 120 \
        --daemon \
        --access-logfile /tmp/tg-monitor-access.log \
        --error-logfile /tmp/tg-monitor-error.log \
        > /tmp/tg-monitor.log 2>&1

    # 等待启动完成
    log "等待服务启动..."
    sleep 15

    # 验证启动
    if pgrep -f "gunicorn app.main:app" > /dev/null; then
        # 进一步验证 API 可用性
        if curl -s --max-time 10 http://localhost:8000/health > /dev/null 2>&1; then
            log_success "服务重启成功且 API 响应正常"

            # 清除告警标志
            rm -f "$ALERT_SENT"

            # 发送通知（可选）
            # 可以在这里添加钉钉、企微等通知
            return 0
        else
            log_error "服务已启动但 API 无响应"
            return 1
        fi
    else
        log_error "服务启动失败！"
        return 1
    fi
}

# 发送告警通知
send_alert() {
    # 避免频繁发送告警（1小时内只发送一次）
    if [ -f "$ALERT_SENT" ]; then
        local last_sent=$(stat -c %Y "$ALERT_SENT" 2>/dev/null || echo "0")
        local now=$(date +%s)
        local diff=$((now - last_sent))

        if [ "$diff" -lt 3600 ]; then
            return 0
        fi
    fi

    log "发送告警通知..."

    # 创建告警标志
    touch "$ALERT_SENT"

    # 这里可以添加钉钉、企微等通知方式
    # 示例：curl -X POST "钉钉webhook" -d '{"text":"TG监控服务已自动重启"}'

    return 0
}

# 主流程
main() {
    # 检查是否已有脚本在运行
    check_running

    # 检查重启间隔
    if ! check_restart_interval; then
        exit 0
    fi

    # 检查是否需要重启
    if need_restart; then
        log_error "检测到服务异常，准备重启..."
        restart_service

        if [ $? -eq 0 ]; then
            send_alert
        fi
    else
        # 服务正常，清除告警标志
        rm -f "$ALERT_SENT"
    fi
}

# 运行
main
