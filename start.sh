#!/bin/bash
# start.sh

echo "Starting OpenClaw with PM2..."

# 初始化PM2
pm2 init

# 启动应用
pm2 start ecosystem.config.js

# 设置日志轮转
pm2 install pm2-logrotate
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 30

# 使用 pm2-runtime 启动应用 (容器化最佳实践)
echo "Starting application with pm2-runtime..."
exec pm2-runtime start ecosystem.config.js