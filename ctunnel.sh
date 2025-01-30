#!/bin/bash
# ==============================================
# Cloudflare Tunnel 管理工具
# 版本: 3.0
# 功能: 状态监控/令牌更新/完整卸载
# ==============================================

# 配置参数
CONFIG_DIR="/etc/cloudflared"
TOKEN_FILE="${CONFIG_DIR}/token"
LOG_FILE="/var/log/cloudflared.log"

# 颜色定义
COLOR_RED='\033[31m'
COLOR_GREEN='\033[32m'
COLOR_YELLOW='\033[33m'
COLOR_RESET='\033[0m'

# 错误处理
die() { echo -e "${COLOR_RED}错误: $*${COLOR_RESET}" >&2; exit 1; }

# 服务状态检测
service_status() {
  case "$(uname -s)" in
    Linux)
      if systemctl is-active cloudflared >/dev/null; then
        echo -e "服务状态: ${COLOR_GREEN}运行中${COLOR_RESET}"
        return 0
      else
        echo -e "服务状态: ${COLOR_RED}未运行${COLOR_RESET}"
        return 1
      fi
      ;;
    Darwin)
      if launchctl list | grep -q com.cloudflare.tunnel; then
        echo -e "服务状态: ${COLOR_GREEN}运行中${COLOR_RESET}"
        return 0
      else
        echo -e "服务状态: ${COLOR_RED}未运行${COLOR_RESET}"
        return 1
      fi
      ;;
  esac
}

# 安全读取新令牌
read_new_token() {
  echo -ne "${COLOR_YELLOW}请输入新令牌 (输入不可见): ${COLOR_RESET}"
  if [ -t 0 ]; then
    stty -echo
    read -r NEW_TOKEN
    stty echo
    echo
  else
    read -r NEW_TOKEN
  fi
  [[ "$NEW_TOKEN" =~ ^eyJ ]] || die "令牌格式错误"
}

# 令牌更新
update_token() {
  read_new_token
  
  echo "$NEW_TOKEN" | sudo tee "$TOKEN_FILE" >/dev/null
  sudo chmod 600 "$TOKEN_FILE"

  case "$(uname -s)" in
    Linux)
      sudo sed -i "s|--token .*|--token $NEW_TOKEN|" /etc/systemd/system/cloudflared.service
      sudo systemctl restart cloudflared
      ;;
    Darwin)
      sudo launchctl unload /Library/LaunchDaemons/com.cloudflare.tunnel.plist
      sudo launchctl load -w /Library/LaunchDaemons/com.cloudflare.tunnel.plist
      ;;
  esac
  echo -e "${COLOR_GREEN}✔ 令牌已更新并重启服务${COLOR_RESET}"
}

# 完全卸载
uninstall() {
  echo -e "${COLOR_YELLOW}⚠️ 警告: 此操作将永久删除所有数据！${COLOR_RESET}"
  read -p "确认要卸载吗？(y/N) " -n 1 -r
  [[ $REPLY =~ ^[Yy]$ ]] || exit 0

  echo -e "\n-> 停止服务..."
  case "$(uname -s)" in
    Linux)
      sudo systemctl stop cloudflared
      sudo systemctl disable cloudflared
      sudo rm -f /etc/systemd/system/cloudflared.service
      ;;
    Darwin)
      sudo launchctl unload /Library/LaunchDaemons/com.cloudflare.tunnel.plist
      sudo rm -f /Library/LaunchDaemons/com.cloudflare.tunnel.plist
      ;;
  esac

  echo "-> 清理文件..."
  sudo rm -rf "$CONFIG_DIR" \
              /usr/local/bin/cloudflared \
              /usr/local/bin/ctunnel \
              "$LOG_FILE"

  echo -e "\n${COLOR_GREEN}✔ 已彻底卸载 Cloudflare Tunnel${COLOR_RESET}"
}

# 主逻辑
case "$1" in
  status)
    service_status
    ;;
  update)
    update_token
    ;;
  uninstall)
    uninstall
    ;;
  *)
    echo "使用方法: ctunnel [command]"
    echo "可用命令:"
    echo "  status     - 查看服务状态"
    echo "  update     - 更新隧道令牌"
    echo "  uninstall  - 完全卸载服务"
    exit 1
    ;;
esac