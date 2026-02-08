# Dockerfile
FROM openclaw/openclaw:latest

# 安装 Node.js 和 PM2
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g pm2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 创建应用目录
WORKDIR /app

# 复制PM2配置文件
COPY ecosystem.config.js /app/

# 复制启动脚本
COPY start.sh /app/
RUN chmod +x /app/start.sh

# 暴露端口
EXPOSE 8080 7860 9320

# 设置PM2环境
ENV PM2_HOME=/app/.pm2
ENV NODE_ENV=production

# 启动命令
CMD ["/app/start.sh"]