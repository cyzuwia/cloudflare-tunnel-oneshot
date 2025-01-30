#!/bin/bash
# =================================================================
# Cloudflare Tunnel 交互式一键安装脚本
# 支持: Linux (systemd)/macOS (launchd)
# 版本: 3.0
# =================================================================
set -euo pipefail
# 全局配置
BIN_PATH="/usr/local/bin/cloudflared"
CONFIG_DIR="/etc/cloudflared"
LOG_FILE="/var/log/cloudflared.log"
# 镜像源配置
declare -A MIRRORS=(
    ["github"]="https://raw.githubusercontent.com/cyzuwia/cloudflare-tunnel-oneshot/main"
    ["gitee"]="https://gitee.com/cyzuwia/cloudflare-tunnel-oneshot/raw/main"
)
# 颜色定义
COLOR_RED='\033[31m'
COLOR_GREEN='\033[32m'
COLOR_YELLOW='\033[33m'
COLOR_RESET='\033[0m'
# 错误处理
die() {
    echo -e "${COLOR_RED}错误: $*${COLOR_RESET}" >&2
    exit 1
}
success() {
    echo -e "${COLOR_GREEN}$*${COLOR_RESET}"
}
# 智能选择镜像源
select_mirror() {
    if curl -m 3 -sI https://raw.githubusercontent.com | grep -q "HTTP/2 200"; then
        echo "github"
    else
        echo "gitee"
    fi
}
# 安全读取令牌
read_token() {
    echo -ne "${COLOR_YELLOW}请输入 Cloudflare 隧道令牌 (输入不可见): ${COLOR_RESET}"
    # 终端环境隐藏输入
    if [ -t 0 ]; then
        stty -echo
        read -r TOKEN
        stty echo
        echo
    else
        read -r TOKEN
    fi
    [[ "$TOKEN" =\~ ^eyJ ]] || die "令牌格式错误！应以 eyJ 开头"
}
# 安装依赖
install_deps() {
    if ! command -v wget &>/dev/null; then
        echo "-> 安装系统依赖..."
        (apt-get update && apt-get install -y wget curl) || \
        (yum install -y wget curl) || \
        die "依赖安装失败"
    fi
}
# 下载组件
download_component() {
    local url="$1"
    local output="$2"
    if ! wget -q --tries=3 --timeout=10 -O "$output" "$url"; then
        die "下载失败: ${url}"
    fi
}
# 配置Linux服务
setup_linux() {
    echo "-> 部署 systemd 服务..."
    download_component "${SOURCE_URL}/cloudflared.service" "/tmp/cloudflared.service"
    sed -i "s|{TOKEN}|${TOKEN}|g; s|{LOG_FILE}|${LOG_FILE}|g" /tmp/cloudflared.service
    sudo mv /tmp/cloudflared.service /etc/systemd/system/cloudflared.service
    sudo systemctl daemon-reload
    sudo systemctl enable --now cloudflared
}
# 配置macOS服务
setup_macos() {
    echo "-> 部署 launchd 服务..."
    sudo tee "/Library/LaunchDaemons/com.cloudflare.tunnel.plist" >/dev/null <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
<key>Label</key>
<string>com.cloudflare.tunnel</string>
<key>ProgramArguments</key>
<array>
<string>${BIN_PATH}</string>
<string>tunnel</string>
<string>run</string>
<string>--token</string>
<string>${TOKEN}</string>
</array>
<key>StandardOutPath</key>
<string>${LOG_FILE}</string>
<key>StandardErrorPath</key>
<string>${LOG_FILE}</string>
<key>RunAtLoad</key>
<true/>
<key>KeepAlive</key>
<true/>
</dict>
</plist>
EOF
    sudo launchctl load -w "/Library/LaunchDaemons/com.cloudflare.tunnel.plist"
}
# 主流程
main() {
    clear
    echo -e "\n${COLOR_GREEN}=== Cloudflare Tunnel 交互式安装 ===${COLOR_RESET}"
    # 参数处理
    SOURCE_URL="${MIRRORS[gitee]}"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --cn) shift ;;
            *) die "未知参数: $1" ;;
        esac
    done
    [[ "$SOURCE_URL" == "${MIRRORS[gitee]}" ]] || SOURCE_URL="${MIRRORS[$(select_mirror)]}"
    # 核心步骤
    read_token
    install_deps
    # 下载组件
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)  ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        *)       die "不支持的架构: $ARCH" ;;
    esac
    download_component "${SOURCE_URL}/cloudflared-${ARCH}" "$BIN_PATH"
    sudo chmod +x "$BIN_PATH"
    download_component "${SOURCE_URL}/ctunnel" "/usr/local/bin/ctunnel"
    sudo chmod +x "/usr/local/bin/ctunnel"
    # 配置服务
    case "$(uname -s)" in
        Linux*)  setup_linux ;;
        Darwin*) setup_macos ;;
        *)       die "不支持的操作系统" ;;
    esac
    # 安全存储令牌
    sudo mkdir -p "$CONFIG_DIR"
    echo "$TOKEN" | sudo tee "${CONFIG_DIR}/token" >/dev/null
    sudo chmod 600 "${CONFIG_DIR}/token"
    success "\n✔ 安装成功！"
    echo -e "管理命令:"
    echo -e "  ctunnel status    # 查看状态"
    echo -e "  ctunnel update    # 更新令牌"
    echo -e "  ctunnel uninstall # 完全卸载"
    echo -e "\n日志文件: ${LOG_FILE}"
}
main "$@"
