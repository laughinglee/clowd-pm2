# Dockerfile
FROM alpine/openclaw

# 安装 Node.js 和 PM2 (Alpine)
RUN apk add --no-cache nodejs npm curl gnupg && \
    npm install -g pm2

# 创建应用目录
WORKDIR /app

# 复制PM2配置文件
COPY ecosystem.config.js /app/

# 复制应用代码 (确保 index.js 存在)
COPY index.js /app/

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