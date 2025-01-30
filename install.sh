#!/bin/bash
set -euo pipefail

# ==============================================
# Cloudflare Tunnel 终极一键安装脚本
# 支持系统: Linux (systemd)/macOS (launchd)
# 仓库: https://github.com/yourusername/cloudflare-tunnel-oneshot
# ==============================================

# 配置参数
TOKEN=""
REPO="yourusername/cloudflare-tunnel-oneshot"
CN_MIRROR="https://gitee.com/yourusername/cloudflare-tunnel-oneshot/raw/main"
GITHUB_RAW="https://raw.githubusercontent.com/$REPO/main"
BIN_PATH="/usr/local/bin/cloudflared"
CONFIG_PATH="/etc/cloudflared/token"

# 解析参数
while [[ $# -gt 0 ]]; do
  case "$1" in
    --token=*)
      TOKEN="${1#*=}"
      shift
      ;;
    --cn)
      SOURCE_URL="$CN_MIRROR"
      shift
      ;;
    *)
      echo "未知参数: $1"
      exit 1
      ;;
  esac
done

SOURCE_URL="${SOURCE_URL:-$GITHUB_RAW}"

# 字体颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

fail() { echo -e "${RED}[错误] $*${NC}" >&2; exit 1; }
success() { echo -e "${GREEN}[成功] $*${NC}"; }

# 令牌验证
validate_token() {
  [[ "$TOKEN" =~ ^eyJ ]] || fail "令牌格式错误！应以 eyJ 开头"
}

# 安装依赖
install_deps() {
  if ! command -v wget &>/dev/null; then
    echo "-> 安装系统依赖..."
    (apt-get update && apt-get install -y wget) || \
    (yum install -y wget) || \
    fail "无法安装 wget"
  fi
}

# 下载组件
download_component() {
  local component=$1
  local target_path=$2
  echo "-> 下载 $component..."
  wget -q "$SOURCE_URL/$component" -O "$target_path" || fail "下载失败: $component"
  chmod +x "$target_path"
}

# 配置Linux服务
setup_linux() {
  echo "-> 配置 systemd 服务..."
  wget -q "$SOURCE_URL/cloudflared.service" -O /etc/systemd/system/cloudflared.service
  sed -i "s|{TOKEN}|$TOKEN|g" /etc/systemd/system/cloudflared.service
  systemctl daemon-reload
  systemctl enable --now cloudflared
}

# 配置macOS服务
setup_macos() {
  echo "-> 配置 launchd 服务..."
  PLIST_PATH="/Library/LaunchDaemons/com.cloudflare.tunnel.plist"
  sudo tee "$PLIST_PATH" >/dev/null <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.cloudflare.tunnel</string>
  <key>ProgramArguments</key>
  <array>
    <string>$BIN_PATH</string>
    <string>tunnel</string>
    <string>run</string>
    <string>--token</string>
    <string>$TOKEN</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
</dict>
</plist>
EOF
  launchctl load -w "$PLIST_PATH"
}

# 主安装流程
main() {
  clear
  echo "======= Cloudflare Tunnel 一键安装 ======="
  validate_token
  install_deps
  
  # 获取系统架构
  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64)  ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    *)       fail "不支持的架构: $ARCH" ;;
  esac

  # 下载cloudflared
  echo "-> 下载 cloudflared ($ARCH)..."
  wget -q "$SOURCE_URL/cloudflared-linux-$ARCH" -O "$BIN_PATH" || fail "下载二进制失败"
  chmod +x "$BIN_PATH"

  # 安装管理脚本
  download_component ctunnel /usr/local/bin/ctunnel

  # 配置服务
  case "$(uname -s)" in
    Linux*)  setup_linux ;;
    Darwin*) setup_macos ;;
    *)       fail "不支持的操作系统" ;;
  esac

  success "安装完成！"
  echo "运行命令管理隧道:"
  echo "  ctunnel status    # 查看状态"
  echo "  ctunnel update    # 更新令牌"
  echo "  ctunnel uninstall # 完全卸载"
}

main