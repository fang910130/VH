#!/bin/bash

echo "开始卸载 VoHive..."

# 1. 停止并禁用后台服务
echo "正在停止并移除系统服务..."
systemctl stop vohive 2>/dev/null
systemctl disable vohive 2>/dev/null
rm -f /etc/systemd/system/vohive.service

# 2. 刷新系统服务列表
systemctl daemon-reload

# 3. 彻底删除程序文件夹（包括主程序、配置和数据库）
echo "正在清理程序文件和数据..."
rm -rf /opt/vohive

echo "✅ 卸载完成！VoHive 已彻底从这台机器上移除，干干净净。"
