# Shadowsocks (libev & rust) + simple-obfs

这个 Bash 脚本可以帮助你在 Debian 10/11/12/13 和 Ubuntu 20.04/22.04/24.04 系统快速部署 shadowsocks-libev/rust+obfs 代理服务器。

### 一键脚本自定义安装
自定义端口参数如：LIB_PORT=8443(shadowsocks-libev端口)，RUST_PORT=9443(shadowsocks-rust端口)，使用时请自行定义此参数！
```bash
LIB_PORT=8443 RUST_PORT=9443 bash <(curl -fsSL https://raw.githubusercontent.com/hide3110/ss-lib-rust/main/install.sh)
```

### 缷载
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/hide3110/ss-lib-rust/main/uninstall.sh)
```
