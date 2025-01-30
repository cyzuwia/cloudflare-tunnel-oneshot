# 🌐 Cloudflare Tunnel 交互式安装

**一条命令 + 安全交互**，零门槛部署 Cloudflare 隧道服务！

### 作者：_额丶Y_
版本：1.0

## 🚀 极简安装

### 国际网络用户
```bash
curl -sSL https://raw.githubusercontent.com/yourusername/cloudflare-tunnel-oneshot/main/install.sh | sudo bash
```

### 中国大陆用户
```bash
curl -sSL https://gitee.com/yourusername/cloudflare-tunnel-oneshot/raw/main/install.sh | sudo bash -s -- --cn
```

安装过程会提示输入令牌，**终端环境下输入自动隐藏**

## 🛠️ 管理命令
```bash
ctunnel status    # 查看服务状态
ctunnel update    # 更新隧道令牌
ctunnel uninstall # 彻底卸载服务
```

## 🔍 日志监控
```bash
tail -f /var/log/cloudflared.log  # 实时查看日志
```

## 🛡️ 安全特性
- 终端输入自动隐藏
- 令牌文件权限 600
- 完全卸载不留痕

## 📌 注意事项
1. 令牌需从 [Cloudflare 控制台](https://dash.cloudflare.com/)获取
2. macOS 需要管理员密码授权
3. 卸载操作不可逆，请谨慎执行

> 💡 提示：使用 `--cn` 参数可加速国内下载
## 📄 开源协议
[MIT License](LICENSE)