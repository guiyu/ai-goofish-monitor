#!/bin/bash

# 脚本配置
SESSION_NAME="goofish-monitor"
SCRIPT_DIR="/Users/weiyi/workspaces/ai-goofish-monitor"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 显示详细状态
show_detailed_status() {
    echo ""
    echo -e "${CYAN}=== Goofish Monitor 服务详细状态 ===${NC}"
    echo ""
    
    # 1. Screen 会话状态
    echo -e "${BLUE}[Screen 会话]${NC}"
    local sessions=$(screen -list 2>/dev/null | grep "$SESSION_NAME")
    if [ -n "$sessions" ]; then
        echo -e "  ${GREEN}✓${NC} 找到 Screen 会话:"
        echo "$sessions" | sed 's/^/    /'
    else
        echo -e "  ${RED}✗${NC} 未找到 Screen 会话"
    fi
    echo ""
    
    # 2. Python 进程状态
    echo -e "${BLUE}[Python 进程]${NC}"
    local processes=$(ps aux | grep "[w]eb_server.py")
    if [ -n "$processes" ]; then
        echo -e "  ${GREEN}✓${NC} 找到 Python 进程:"
        echo "$processes" | while IFS= read -r line; do
            local pid=$(echo "$line" | awk '{print $2}')
            local cpu=$(echo "$line" | awk '{print $3}')
            local mem=$(echo "$line" | awk '{print $4}')
            local start_time=$(echo "$line" | awk '{print $9}')
            echo "    PID: $pid, CPU: $cpu%, MEM: $mem%, 启动时间: $start_time"
        done
    else
        echo -e "  ${RED}✗${NC} 未找到 Python 进程"
    fi
    echo ""
    
    # 3. 端口状态
    echo -e "${BLUE}[端口状态]${NC}"
    local port_info=$(lsof -i:8000 2>/dev/null)
    if [ -n "$port_info" ]; then
        echo -e "  ${GREEN}✓${NC} 端口 8000 已被占用:"
        echo "$port_info" | tail -n +2 | while IFS= read -r line; do
            local process=$(echo "$line" | awk '{print $1}')
            local pid=$(echo "$line" | awk '{print $2}')
            local state=$(echo "$line" | awk '{print $10}')
            echo "    进程: $process, PID: $pid, 状态: $state"
        done
    else
        echo -e "  ${RED}✗${NC} 端口 8000 未被占用"
    fi
    echo ""
    
    # 4. Web 服务状态
    echo -e "${BLUE}[Web 服务状态]${NC}"
    if curl -s --connect-timeout 3 http://localhost:8000/api/settings/status > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} Web 服务正常响应"
        echo "  📱 Web 管理界面: http://localhost:8000"
    else
        echo -e "  ${RED}✗${NC} Web 服务无响应"
    fi
    echo ""
    
    # 5. 日志文件状态
    echo -e "${BLUE}[日志文件]${NC}"
    local log_files=("logs/stdout.log" "logs/stderr.log" "logs/restart.log")
    for log_file in "${log_files[@]}"; do
        if [ -f "$log_file" ]; then
            local size=$(ls -lh "$log_file" | awk '{print $5}')
            local mod_time=$(ls -l "$log_file" | awk '{print $6, $7, $8}')
            echo -e "  ${GREEN}✓${NC} $log_file (大小: $size, 修改时间: $mod_time)"
        else
            echo -e "  ${YELLOW}⚠${NC} $log_file 不存在"
        fi
    done
    echo ""
    
    # 6. 配置文件状态
    echo -e "${BLUE}[配置文件]${NC}"
    local config_files=(".env" "config.json" "requirements.txt")
    for config_file in "${config_files[@]}"; do
        if [ -f "$config_file" ]; then
            echo -e "  ${GREEN}✓${NC} $config_file 存在"
        else
            echo -e "  ${RED}✗${NC} $config_file 不存在"
        fi
    done
    echo ""
    
    # 7. 虚拟环境状态
    echo -e "${BLUE}[虚拟环境]${NC}"
    if [ -d "venv" ]; then
        echo -e "  ${GREEN}✓${NC} 虚拟环境存在"
        if [ -f "venv/bin/activate" ]; then
            echo -e "  ${GREEN}✓${NC} 激活脚本存在"
        else
            echo -e "  ${RED}✗${NC} 激活脚本不存在"
        fi
    else
        echo -e "  ${RED}✗${NC} 虚拟环境不存在"
    fi
    echo ""
}

# 显示最近日志
show_recent_logs() {
    echo -e "${CYAN}=== 最近日志 (最后 10 行) ===${NC}"
    echo ""
    
    local log_files=("logs/stdout.log" "logs/stderr.log" "logs/restart.log")
    for log_file in "${log_files[@]}"; do
        if [ -f "$log_file" ]; then
            echo -e "${BLUE}[$log_file]${NC}"
            tail -10 "$log_file" | sed 's/^/  /'
            echo ""
        fi
    done
}

# 显示使用帮助
show_help() {
    echo ""
    echo -e "${CYAN}=== 服务管理命令 ===${NC}"
    echo ""
    echo "启动服务:     ./start_server.sh"
    echo "停止服务:     ./stop_server.sh"
    echo "查看状态:     ./status_server.sh"
    echo "查看日志:     ./status_server.sh --logs"
    echo ""
    echo "实时监控:"
    echo "  实时输出日志: tail -f logs/stdout.log"
    echo "  实时错误日志: tail -f logs/stderr.log"
    echo "  进入 Screen:  screen -r $SESSION_NAME"
    echo ""
}

# 主函数
main() {
    # 切换到脚本目录
    cd "$SCRIPT_DIR" || {
        echo -e "${RED}[ERROR]${NC} 无法切换到项目目录: $SCRIPT_DIR"
        exit 1
    }
    
    case "${1:-}" in
        --logs|-l)
            show_recent_logs
            ;;
        --help|-h)
            show_help
            ;;
        *)
            show_detailed_status
            show_help
            ;;
    esac
}

# 执行主函数
main "$@"
