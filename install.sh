#!/bin/bash

echo "开始安装 VoHive..."

# =======================================================
# 1. 架构检测与变量设置
# =======================================================
ARCH=$(uname -m)
echo "检测到当前系统架构为: $ARCH"

URL_AMD64="https://gitgo.cfang.qzz.io/fang910130/VH/main/vohive_v1.5.5_linux_amd64"
URL_ARM64="https://gitgo.cfang.qzz.io/fang910130/VH/main/vohive_v1.5.5_linux_arm64"
URL_CONFIG="https://gitgo.cfang.qzz.io/fang910130/VH/main/config.yaml"

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
# 2. 停止并清理旧服务 (自动识别系统类型)
# =======================================================
if command -v systemctl >/dev/null 2>&1; then
    systemctl stop vohive 2>/dev/null
    systemctl disable vohive 2>/dev/null
elif [ -f /etc/init.d/vohive ]; then
    /etc/init.d/vohive stop 2>/dev/null
    /etc/init.d/vohive disable 2>/dev/null
fi

# =======================================================
# 3. 创建规范的安装目录
# =======================================================
mkdir -p /opt/vohive/bin
mkdir -p /opt/vohive/config
mkdir -p /opt/vohive/data

# =======================================================
# 4. 下载文件（带进度条）
# =======================================================
echo "正在下载主程序..."
wget -q --show-progress -O /opt/vohive/bin/vohive "$DOWNLOAD_URL"
if [ $? -ne 0 ]; then
    echo "❌ 错误: 主程序下载失败，请检查链接。"
    exit 1
fi

echo "正在下载配置文件..."
wget -q --show-progress -O /opt/vohive/config/config.yaml "$URL_CONFIG"
if [ $? -ne 0 ]; then
    echo "❌ 错误: 配置文件下载失败，请检查链接。"
    exit 1
fi

chmod +x /opt/vohive/bin/vohive

# =======================================================
# 5. 生成后台服务与开机自启 (核心修复：自动适配 iStoreOS)
# =======================================================
if command -v systemctl >/dev/null 2>&1; then
    # 【Debian/Ubuntu 虚拟机分支】
    echo "检测到标准 Linux 系统，正在配置 systemd 服务..."
    cat <<EOF > /etc/systemd/system/vohive.service
[Unit]
Description=VoHive Service
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/vohive
ExecStart=/opt/vohive/bin/vohive -c /opt/vohive/config/config.yaml
Restart=on-failure
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable vohive
    systemctl restart vohive

else
    # 【iStoreOS / OpenWrt 路由系统分支】
    echo "检测到 iStoreOS/OpenWrt 系统，正在配置 procd 守护服务..."
    cat <<EOF > /etc/init.d/vohive
#!/bin/sh /etc/rc.common
START=95
USE_PROCD=1

start_service() {
    cd /opt/vohive
    procd_open_instance
    procd_set_param command /opt/vohive/bin/vohive -c /opt/vohive/config/config.yaml
    procd_set_param respawn 3600 5 5
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_close_instance
}
EOF
    chmod +x /etc/init.d/vohive
    /etc/init.d/vohive enable
    /etc/init.d/vohive restart
fi

echo "✅ VoHive 部署完成！服务已在后台常驻运行。"
