# Stage 1: Build the environment with dependencies
FROM python:3.11-slim-bookworm AS builder

# 设置环境变量以防止交互式提示
ENV DEBIAN_FRONTEND=noninteractive

# 创建虚拟环境
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# 安装 Python 依赖到虚拟环境中
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 安装 Playwright 的系统依赖和 Chromium 浏览器
# 我们只安装 curl 来运行 playwright 命令，然后就删除它
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && playwright install-deps chromium \
    && playwright install chromium \
    && apt-get purge -y --auto-remove curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Stage 2: Create the final, lean image
FROM python:3.11-slim-bookworm

WORKDIR /app

# 从 builder 阶段复制虚拟环境
COPY --from=builder /opt/venv /opt/venv

# 从 builder 阶段复制 Playwright 浏览器缓存
# Playwright 浏览器存储在 /root/.cache/ms-playwright
COPY --from=builder /root/.cache/ms-playwright /root/.cache/ms-playwright

# 复制应用代码
# .dockerignore 文件会处理排除项
COPY . .

# 为最终镜像设置环境变量
ENV PATH="/opt/venv/bin:$PATH"
ENV PYTHONUNBUFFERED=1
# 告知 Playwright 在哪里找到浏览器
ENV PLAYWRIGHT_BROWSERS_PATH=/root/.cache/ms-playwright

# 声明服务运行的端口
EXPOSE 8000

# 容器启动时执行的命令
CMD ["python", "web_server.py"]
