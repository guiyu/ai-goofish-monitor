#!/bin/bash

# 脚本配置
SCRIPT_DIR="/Users/weiyi/workspaces/ai-goofish-monitor"
SESSION_NAME="goofish-monitor"
VENV_PATH="$SCRIPT_DIR/venv"
LOG_DIR="$SCRIPT_DIR/logs"

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

# 检查并安装依赖函数
check_dependencies() {
    log_step "检查系统依赖..."
    
    # 检查 screen 是否安装
    if ! command -v screen &> /dev/null; then
        log_error "screen 未安装，请先安装: brew install screen"
        exit 1
    fi
    
    # 检查 Python 虚拟环境
    if [ ! -d "$VENV_PATH" ]; then
        log_warn "虚拟环境不存在，正在创建..."
        python3 -m venv "$VENV_PATH"
        if [ $? -ne 0 ]; then
            log_error "创建虚拟环境失败"
            exit 1
        fi
        log_info "虚拟环境创建成功"
    fi
    
    # 检查 requirements.txt 是否存在
    if [ ! -f "$SCRIPT_DIR/requirements.txt" ]; then
        log_error "requirements.txt 文件不存在"
        exit 1
    fi
    
    # 激活虚拟环境并检查依赖
    source "$VENV_PATH/bin/activate"
    if ! python -c "import uvicorn" &> /dev/null; then
        log_warn "依赖包未安装或不完整，正在安装..."
        pip install -r "$SCRIPT_DIR/requirements.txt"
        if [ $? -ne 0 ]; then
            log_error "安装依赖包失败"
            exit 1
        fi
        log_info "依赖包安装成功"
    fi
    deactivate
    
    log_info "所有依赖检查通过"
}

# 停止现有进程函数
stop_existing_processes() {
    log_step "停止现有进程..."
    
    # 1. 停止所有 screen 会话
    local sessions=$(screen -list | grep "$SESSION_NAME" | awk '{print $1}' | cut -d'.' -f1)
    if [ -n "$sessions" ]; then
        log_info "发现现有的 screen 会话，正在停止..."
        echo "$sessions" | while read -r session_id; do
            if [ -n "$session_id" ]; then
                screen -X -S "$session_id.$SESSION_NAME" quit
                log_info "已停止 screen 会话: $session_id.$SESSION_NAME"
            fi
        done
        sleep 2
    fi
    
    # 2. 停止所有 web_server.py 进程
    local pids=$(pgrep -f "web_server.py" | tr '\n' ' ')
    if [ -n "$pids" ]; then
        log_info "发现现有的 web_server.py 进程: $pids"
        pkill -f "web_server.py"
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
    local port_pid=$(lsof -ti:8099)
    if [ -n "$port_pid" ]; then
        log_warn "端口 8099 被进程 $port_pid 占用，正在终止..."
        kill "$port_pid" 2>/dev/null || kill -9 "$port_pid" 2>/dev/null
        sleep 2
    fi
    
    log_info "现有进程清理完成"
}

# 启动服务函数
start_service() {
    log_step "启动服务..."
    
    # 创建日志目录
    mkdir -p "$LOG_DIR"
    
    # 记录启动时间
    echo "$(date): Script started by user $(whoami)" >> "$LOG_DIR/startup.log"
    
    # 启动 screen 会话
    screen -dmS "$SESSION_NAME" bash -c "
        source '$VENV_PATH/bin/activate'
        cd '$SCRIPT_DIR'
        while true; do
            echo \"\$(date): Starting web_server.py\" >> logs/restart.log
            python web_server.py >> logs/stdout.log 2>> logs/stderr.log
            exit_code=\$?
            echo \"\$(date): web_server.py exited with code \$exit_code, restarting in 5 seconds...\" >> logs/restart.log
            if [ \$exit_code -eq 130 ] || [ \$exit_code -eq 143 ]; then
                echo \"\$(date): Received termination signal, stopping restart loop\" >> logs/restart.log
                break
            fi
            sleep 5
        done
    "
    
    # 等待服务启动
    sleep 3
    
    # 验证服务是否启动成功
    if screen -list | grep -q "$SESSION_NAME"; then
        log_info "服务启动成功！"
        
        # 等待 web 服务器启动
        local wait_count=0
        while [ $wait_count -lt 10 ]; do
            if curl -s http://localhost:8099/api/settings/status > /dev/null 2>&1; then
                log_info "Web 服务器已启动，可以访问 http://localhost:8099"
                break
            fi
            sleep 1
            ((wait_count++))
        done
        
        if [ $wait_count -eq 10 ]; then
            log_warn "Web 服务器可能未完全启动，请检查日志"
        fi
    else
        log_error "服务启动失败，请检查日志"
        return 1
    fi
}

# 显示使用说明
show_usage() {
    echo ""
    echo "=== Goofish Monitor 服务管理 ==="
    echo "服务已在后台启动，session 名称: $SESSION_NAME"
    echo ""
    echo "常用命令:"
    echo "  查看运行状态: screen -r $SESSION_NAME"
    echo "  停止服务:     screen -X -S $SESSION_NAME quit"
    echo "  查看实时日志: tail -f logs/stdout.log"
    echo "  查看错误日志: tail -f logs/stderr.log"
    echo "  查看重启日志: tail -f logs/restart.log"
    echo "  重新启动:     $0"
    echo ""
    echo "Web 管理界面: http://localhost:8099"
    echo ""
}

# 主函数
main() {
    log_info "启动 Goofish Monitor 服务管理脚本"
    
    # 切换到项目目录
    cd "$SCRIPT_DIR" || {
        log_error "无法切换到项目目录: $SCRIPT_DIR"
        exit 1
    }
    
    # 检查依赖
    check_dependencies
    
    # 停止现有进程
    stop_existing_processes
    
    # 启动服务
    if start_service; then
        show_usage
    else
        log_error "服务启动失败"
        exit 1
    fi
}

# 执行主函数
main
