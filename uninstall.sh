#!/bin/bash

echo "开始卸载 VoHive..."

# 1. 自动识别并清理后台服务
if command -v systemctl >/dev/null 2>&1; then
    echo "正在清理 systemd 服务..."
    systemctl stop vohive 2>/dev/null
    systemctl disable vohive 2>/dev/null
    rm -f /etc/systemd/system/vohive.service
    systemctl daemon-reload
else
    echo "正在清理 iStoreOS/OpenWrt 服务..."
    /etc/init.d/vohive stop 2>/dev/null
    /etc/init.d/vohive disable 2>/dev/null
    rm -f /etc/init.d/vohive
fi

# 2. 清理程序目录
echo "正在清理程序文件..."
rm -rf /opt/vohive

echo "✅ VoHive 已彻底卸载干净！"
