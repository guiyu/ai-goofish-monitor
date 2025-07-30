#!/bin/bash

# 脚本配置
SESSION_NAME="goofish-monitor"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 停止服务函数
stop_service() {
    log_step "停止 Goofish Monitor 服务..."
    
    local stopped_something=false
    
    # 1. 停止所有 screen 会话
    local sessions=$(screen -list | grep "$SESSION_NAME" | awk '{print $1}' | cut -d'.' -f1)
    if [ -n "$sessions" ]; then
        log_info "发现 screen 会话，正在停止..."
        echo "$sessions" | while read -r session_id; do
            if [ -n "$session_id" ]; then
                screen -X -S "$session_id.$SESSION_NAME" quit
                log_info "已停止 screen 会话: $session_id.$SESSION_NAME"
            fi
        done
        stopped_something=true
        sleep 2
    fi
    
    # 2. 停止所有 web_server.py 进程
    local pids=$(pgrep -f "web_server.py" | tr '\n' ' ')
    if [ -n "$pids" ]; then
        log_info "发现 web_server.py 进程: $pids"
        pkill -f "web_server.py"
        stopped_something=true
        sleep 3
        
        # 检查是否还有进程存在
        pids=$(pgrep -f "web_server.py" | tr '\n' ' ')
        if [ -n "$pids" ]; then
            log_warn "进程仍在运行，强制终止: $pids"
            pkill -9 -f "web_server.py"
            sleep 2
        fi
    fi
    
    # 3. 检查端口占用
    local port_pid=$(lsof -ti:8000)
    if [ -n "$port_pid" ]; then
        log_warn "端口 8000 被进程 $port_pid 占用，正在终止..."
        kill "$port_pid" 2>/dev/null || kill -9 "$port_pid" 2>/dev/null
        stopped_something=true
        sleep 2
    fi
    
    if [ "$stopped_something" = true ]; then
        log_info "服务已停止"
    else
        log_info "未发现运行中的服务"
    fi
}

# 显示状态
show_status() {
    echo ""
    echo "=== Goofish Monitor 服务状态 ==="
    
    # 检查 screen 会话
    local sessions=$(screen -list | grep "$SESSION_NAME" | awk '{print $1}')
    if [ -n "$sessions" ]; then
        echo "Screen 会话: $sessions"
    else
        echo "Screen 会话: 无"
    fi
    
    # 检查进程
    local pids=$(pgrep -f "web_server.py" | tr '\n' ' ')
    if [ -n "$pids" ]; then
        echo "Python 进程: $pids"
    else
        echo "Python 进程: 无"
    fi
    
    # 检查端口
    local port_pid=$(lsof -ti:8000)
    if [ -n "$port_pid" ]; then
        echo "端口 8000: 被进程 $port_pid 占用"
    else
        echo "端口 8000: 空闲"
    fi
    
    echo ""
}

# 主函数
main() {
    log_info "Goofish Monitor 服务停止脚本"
    
    # 显示停止前状态
    show_status
    
    # 停止服务
    stop_service
    
    # 显示停止后状态
    show_status
    
    echo "如需重新启动服务，请运行: ./start_server.sh"
}

# 执行主函数
main
