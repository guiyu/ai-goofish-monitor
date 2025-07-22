#!/bin/bash

# 切换到项目目录
cd /Users/weiyi/workspaces/ai-goofish-monitor

# 创建日志目录
mkdir -p logs

# 使用 screen 在后台运行服务，并自动重启
screen -dmS goofish-monitor bash -c '
while true; do
    echo "$(date): Starting web_server.py" >> logs/restart.log
    python3 web_server.py >> logs/stdout.log 2>> logs/stderr.log
    echo "$(date): web_server.py exited with code $?, restarting in 5 seconds..." >> logs/restart.log
    sleep 5
done
'

echo "服务已在后台启动，session 名称: goofish-monitor"
echo "查看运行状态: screen -r goofish-monitor"
echo "停止服务: screen -X -S goofish-monitor quit"
echo "查看日志: tail -f logs/stdout.log"
