#!/bin/bash
# start.sh - Debian/Ubuntu 部署脚本

# 遇到错误立即退出
set -e

# 检查是否为 root 用户, 决定是否使用 sudo
if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
else
    # 非 root 用户需要 sudo
    if ! command -v sudo &> /dev/null; then
        echo "[ERROR] 当前非 root 用户且未安装 sudo。请切换到 root 或安装 sudo。"
        exit 1
    fi
    SUDO="sudo"
fi

echo "=== 开始在 Debian/Ubuntu 上配置 OpenClaw/PM2 环境 ==="

# 0. 检查并安装基础依赖 (curl, gnupg)
# NodeSource 脚本脚本依赖这些工具
echo "[INFO] 检查基础依赖..."
if ! command -v curl &> /dev/null || ! command -v gpg &> /dev/null; then
    echo "[INFO] 安装 curl 和 gnupg..."
    $SUDO apt-get update
    $SUDO apt-get install -y curl gnupg
fi

# 1. 检查 Node.js 环境
if ! command -v node &> /dev/null; then
    echo "[INFO] 未检测到 Node.js, 正在安装 Node.js 22.x..."
    # 使用 NodeSource 安装源 (兼容 Debian 和 Ubuntu)
    curl -fsSL https://deb.nodesource.com/setup_22.x | $SUDO -E bash -
    $SUDO apt-get install -y nodejs
else
    echo "[INFO] Node.js 已安装: $(node -v)"
fi

# 检查 npm
if ! command -v npm &> /dev/null; then
    echo "[ERROR] npm 未安装, 请检查 Node.js 安装状态。"
    exit 1
fi

# 2. 安装 PM2 (全局)
if ! command -v pm2 &> /dev/null; then
    echo "[INFO] 正在全局安装 PM2..."
    $SUDO npm install -g pm2
else
    echo "[INFO] PM2 已安装: $(pm2 -v)"
fi

# 3. 安装依赖 (如果有 package.json)
if [ -f "package.json" ]; then
    echo "[INFO] 检测到 package.json, 正在安装依赖..."    
    # 安装构建工具 (防止某些包编译失败)
    if ! dpkg -s build-essential &> /dev/null; then
        echo "[INFO] 安装构建工具 (build-essential)..."
        $SUDO apt-get update && $SUDO apt-get install -y build-essential
    fi

    # 设置 npm 镜像源加速
    npm config set registry https://wc61weef.mirror.aliyuncs.com
        npm install
else
    echo "[WARN] 未找到 package.json, 跳过依赖安装。"
fi

# 4. 配置日志轮转 (防止日志占满磁盘)
echo "[INFO] 配置 PM2 日志轮转..."
pm2 install pm2-logrotate || true
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 30

# 5. 启动应用
echo "[INFO] 正在启动应用..."
# 检查 ecosystem.config.js 是否存在
if [ ! -f "ecosystem.config.js" ]; then
    echo "[ERROR] 找不到 ecosystem.config.js 配置文件！"
    exit 1
fi

# 启动或重载
pm2 start ecosystem.config.js

# 6. 保存并提示开机自启
pm2 save
echo ""
echo "=== 部署完成 ==="
echo "服务已通过 PM2 启动。可以使用以下命令管理："
echo "  pm2 list        # 查看服务状态"
echo "  pm2 logs        # 查看日志"
echo "  pm2 monit       # 监控资源"
echo ""
echo "【重要】如需设置开机自启, 请运行以下命令并按提示操作："
echo "  pm2 startup"