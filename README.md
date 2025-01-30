# Cloudflare Tunnel 一键部署
只需一条命令即可完成隧道服务的安装、配置和启动！

### 作者：_额丶Y_
版本：1.0

## 🚀 快速开始
### 国际网络用户
```bash
curl -sSL https://raw.githubusercontent.com/yourusername/cloudflare-tunnel-oneshot/main/install.sh | sudo bash -s -- --token=你的隧道令牌
```
### 中国大陆用户
```bash
curl -sSL https://gitee.com/yourusername/cloudflare-tunnel-oneshot/raw/main/install.sh | sudo bash -s -- --token=你的隧道令牌 --cn
```
## 📜 使用说明
安装后使用 `ctunnel` 命令管理服务：
```bash
ctunnel status    # 查看服务状态
ctunnel update    # 更新隧道令牌
ctunnel uninstall # 完全卸载服务
```
## 🛠️ 功能特性
- 全自动安装流程
- 智能识别系统架构
- 国内镜像加速支持
- 服务状态监控
- 令牌热更新
## 📝 注意事项
1. 令牌需从 Cloudflare Zero Trust 面板获取
2. macOS 需要管理员权限
3. 卸载命令将永久删除所有相关文件
## 📄 开源协议
[MIT License](LICENSE)