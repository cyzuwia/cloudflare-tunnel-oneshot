#!/bin/bash
# ==============================================
# Cloudflare Tunnel 管理脚本
# 作者: yourusername
# 版本: 1.0
# ==============================================

# 配置参数
CONFIG_PATH="/etc/cloudflared/token"
SERVICE_NAME="cloudflared"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# 错误处理
die() { echo -e "${RED}错误: $*${NC}" >&2; exit 1; }
success() { echo -e "${GREEN}$*${NC}"; }
warn() { echo -e "${YELLOW}$*${NC}"; }

# 服务状态检查
status() {
  case "$(uname -s)" in
    Linux)
      systemctl is-active "$SERVICE_NAME" >/dev/null && \
        echo -e "服务状态: ${GREEN}运行中${NC}" || \
        echo -e "服务状态: ${RED}未运行${NC}"
      ;;
    Darwin)
      launchctl list | grep -q com.cloudflare.tunnel && \
        echo -e "服务状态: ${GREEN}运行中${NC}" || \
        echo -e "服务状态: ${RED}未运行${NC}"
      ;;
  esac
}

# 更新令牌
update_token() {
  read -p "请输入新令牌 (eyJ...): " NEW_TOKEN
  [[ "$NEW_TOKEN" =~ ^eyJ ]] || die "令牌格式无效"
  echo "$NEW_TOKEN" | sudo tee "$CONFIG_PATH" >/dev/null

  case "$(uname -s)" in
    Linux)
      sudo sed -i "s|--token.*|--token $NEW_TOKEN|" /etc/systemd/system/cloudflared.service
      sudo systemctl restart cloudflared
      ;;
    Darwin)
      sudo launchctl unload /Library/LaunchDaemons/com.cloudflare.tunnel.plist
      sudo launchctl load -w /Library/LaunchDaemons/com.cloudflare.tunnel.plist
      ;;
  esac
  success "令牌已更新并重启服务"
}

# 完全卸载
uninstall() {
  warn "此操作将永久删除所有相关文件！"
  read -p "确认卸载？(y/N) " -n 1 -r
  [[ $REPLY =~ ^[Yy]$ ]] || exit 0

  case "$(uname -s)" in
    Linux)
      sudo systemctl stop "$SERVICE_NAME"
      sudo systemctl disable "$SERVICE_NAME"
      sudo rm -f /etc/systemd/system/cloudflared.service
      ;;
    Darwin)
      sudo launchctl unload /Library/LaunchDaemons/com.cloudflare.tunnel.plist
      sudo rm -f /Library/LaunchDaemons/com.cloudflare.tunnel.plist
      ;;
  esac

  sudo rm -f /usr/local/bin/cloudflared
  sudo rm -f /usr/local/bin/ctunnel
  success "已完全卸载 Cloudflare Tunnel 服务"
}

# 主菜单
case "$1" in
  status)    status ;;
  update)    update_token ;;
  uninstall) uninstall ;;
  *)
    echo "使用方法: ctunnel [command]"
    echo "可用命令:"
    echo "  status    查看服务状态"
    echo "  update    更新隧道令牌"
    echo "  uninstall 完全卸载服务"
    exit 1
    ;;
esac