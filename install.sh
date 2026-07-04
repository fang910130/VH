#!/bin/bash

echo "开始安装 VoHive..."

# =======================================================
# 1. 架构检测与变量设置
# =======================================================
ARCH=$(uname -m)
echo "检测到当前系统架构为: $ARCH"

# 定义不同架构的下载链接（请将下面三个引号里的链接替换为你自己的 GitHub Raw 直链）
URL_AMD64="https://github.com/fang910130/VH/blob/main/vohive_v1.5.5_linux_amd64"
URL_ARM64="https://github.com/fang910130/VH/blob/main/vohive_v1.5.5_linux_arm64"
URL_CONFIG="https://raw.githubusercontent.com/fang910130/VH/refs/heads/main/config.yaml"

# 根据架构选择主程序链接
if [ "$ARCH" = "x86_64" ]; then
    DOWNLOAD_URL=$URL_AMD64
    echo "将下载 AMD64 版本主程序..."
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "armv8l" ]; then
    DOWNLOAD_URL=$URL_ARM64
    echo "将下载 ARM64 (aarch64) 版本主程序..."
else
    echo "❌ 错误: 暂不支持当前的系统架构 ($ARCH)，脚本退出。"
    exit 1
fi

# =======================================================
# 2. 停止并清理旧服务
# =======================================================
systemctl stop vohive 2>/dev/null
systemctl disable vohive 2>/dev/null

# =======================================================
# 3. 创建规范的安装目录
# =======================================================
mkdir -p /opt/vohive/bin
mkdir -p /opt/vohive/config

# =======================================================
# 4. 下载文件
# =======================================================
echo "正在下载文件..."
# 使用 -q 参数让 wget 静默下载，-O 指定输出路径
wget -q -O /opt/vohive/bin/vohive "$DOWNLOAD_URL"
if [ $? -ne 0 ]; then
    echo "❌ 错误: 主程序下载失败，请检查链接。"
    exit 1
fi

wget -q -O /opt/vohive/config/config.yaml "$URL_CONFIG"
if [ $? -ne 0 ]; then
    echo "❌ 错误: 配置文件下载失败，请检查链接。"
    exit 1
fi

# =======================================================
# 5. 赋予执行权限
# =======================================================
chmod +x /opt/vohive/bin/vohive

# =======================================================
# 6. 生成系统服务 (开机自启和后台运行)
# =======================================================
echo "配置系统服务..."
cat <<EOF > /etc/systemd/system/vohive.service
[Unit]
Description=VoHive Service
After=network.target

[Service]
Type=simple
ExecStart=/opt/vohive/bin/vohive -c /opt/vohive/config/config.yaml
Restart=on-failure
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF

# =======================================================
# 7. 重载并启动服务
# =======================================================
systemctl daemon-reload
systemctl enable vohive
systemctl restart vohive

echo "✅ VoHive 部署完成！服务已在后台运行。"
echo "可以使用命令 'systemctl status vohive' 查看运行状态。"
