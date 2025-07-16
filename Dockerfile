# 使用官方的 Playwright Python 镜像，它已经包含了所有浏览器依赖
FROM mcr.microsoft.com/playwright/python:v1.44.0-jammy

# 设置工作目录
WORKDIR /app

# 复制依赖文件
COPY requirements.txt .

# 安装 Python 依赖
# 使用 --no-cache-dir 减小镜像体积
RUN pip install --no-cache-dir -r requirements.txt

# 复制所有应用代码到工作目录
# .dockerignore 文件会控制哪些文件被复制
COPY . .

# 声明服务运行的端口
EXPOSE 8000

# 容器启动时执行的命令
CMD ["python", "web_server.py"]
