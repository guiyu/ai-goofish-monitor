#!/bin/bash

cd /Users/weiyi/workspaces/ai-goofish-monitor
mkdir -p logs

# 使用 nohup 后台运行，带自动重启
nohup bash -c '
while true; do
    echo "$(date): Starting web_server.py" >> logs/restart.log
    python3 web_server.py >> logs/stdout.log 2>> logs/stderr.log
    exit_code=$?
    echo "$(date): web_server.py exited with code $exit_code, restarting in 5 seconds..." >> logs/restart.log
    sleep 5
done
' > /dev/null 2>&1 &

echo $! > logs/daemon.pid
echo "服务已启动，PID: $(cat logs/daemon.pid)"
echo "停止服务: kill \$(cat logs/daemon.pid)"
echo "查看日志: tail -f logs/stdout.log"
