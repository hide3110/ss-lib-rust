#!/bin/bash

# Shadowsocks (libev & rust) 和 simple-obfs 安装脚本
# 适用于 Debian 11/12/13 和 Ubuntu 20.04/22.04/24.04
# 使用方法: sudo bash install_shadowsocks.sh

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 打印函数
print_info() {
    echo -e "${GREEN}[信息]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

print_error() {
    echo -e "${RED}[错误]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[步骤]${NC} $1"
}

# 检查是否以 root 身份运行
if [ "$(id -u)" -ne 0 ]; then
    print_error "此脚本必须以 root 身份运行"
    exit 1
fi

# 检测操作系统
if [ ! -f /etc/os-release ]; then
    print_error "无法检测操作系统"
    exit 1
fi

. /etc/os-release
OS_ID=$ID
OS_VERSION_CODENAME=$(lsb_release -sc 2>/dev/null || echo "$VERSION_CODENAME")

print_info "检测到的操作系统: $OS_ID $VERSION"
print_info "版本代号: $OS_VERSION_CODENAME"

# 验证系统是否支持
case "$OS_ID" in
    debian)
        case "$OS_VERSION_CODENAME" in
            buster|bullseye|bookworm|trixie)
                print_success "支持的 Debian 版本"
                ;;
            *)
                print_error "不支持的 Debian 版本: $OS_VERSION_CODENAME"
                print_info "支持的版本: buster(10), bullseye(11), bookworm(12), trixie(13)"
                exit 1
                ;;
        esac
        ;;
    ubuntu)
        case "$OS_VERSION_CODENAME" in
            focal|jammy|noble)
                print_success "支持的 Ubuntu 版本"
                ;;
            *)
                print_error "不支持的 Ubuntu 版本: $OS_VERSION_CODENAME"
                print_info "支持的版本: focal(20.04), jammy(22.04), noble(24.04)"
                exit 1
                ;;
        esac
        ;;
    *)
        print_error "不支持的操作系统: $OS_ID"
        print_info "此脚本仅支持 Debian 和 Ubuntu"
        exit 1
        ;;
esac

# 配置参数（仅端口可自定义）
LIB_PORT=${LIB_PORT:-65041}
RUST_PORT=${RUST_PORT:-65042}

print_info "配置参数:"
echo "  - Shadowsocks-libev 端口: $LIB_PORT"
echo "  - Shadowsocks-rust 端口: $RUST_PORT"
echo "  - 密码: opj33QlG2TRNOB18xt288A=="
echo "  - Libev 加密方法: aes-256-gcm"
echo "  - Rust 加密方法: aes-128-gcm"
echo "  - 混淆类型: http"
echo

printf "是否继续安装? (y/N): "
read -r REPLY
if ! echo "$REPLY" | grep -qE '^[Yy]$'; then
    print_info "已取消安装"
    exit 0
fi

echo

# 步骤 1: 更新系统并安装依赖
print_step "步骤 1/9: 更新系统并安装必要依赖"
apt-get update
apt-get install -y lsb-release ca-certificates curl gnupg
print_success "依赖安装完成"

echo

# 步骤 2: 添加 GPG 公钥
print_step "步骤 2/9: 添加 Teddysun Shadowsocks Repository 公钥"
curl -fsSL https://dl.lamp.sh/shadowsocks/DEB-GPG-KEY-Teddysun | gpg --dearmor --yes -o /usr/share/keyrings/deb-gpg-key-teddysun.gpg
chmod a+r /usr/share/keyrings/deb-gpg-key-teddysun.gpg
print_success "GPG 公钥添加完成"

echo

# 步骤 3: 添加软件源
print_step "步骤 3/9: 添加 Teddysun Shadowsocks Repository"
if [ "$OS_ID" = "debian" ]; then
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/deb-gpg-key-teddysun.gpg] https://dl.lamp.sh/shadowsocks/debian/ $OS_VERSION_CODENAME main" > /etc/apt/sources.list.d/teddysun.list
elif [ "$OS_ID" = "ubuntu" ]; then
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/deb-gpg-key-teddysun.gpg] https://dl.lamp.sh/shadowsocks/ubuntu/ $OS_VERSION_CODENAME main" > /etc/apt/sources.list.d/teddysun.list
fi
print_success "软件源添加完成"

echo

# 步骤 4: 更新软件包缓存
print_step "步骤 4/9: 更新软件包缓存"
apt-get update
print_success "缓存更新完成"

echo

# 步骤 5: 安装 shadowsocks-libev
print_step "步骤 5/9: 安装 shadowsocks-libev"

# 根据系统版本选择合适的包版本
case "$OS_ID-$OS_VERSION_CODENAME" in
    debian-buster)
        SS_LIBEV_VERSION="3.3.5-12~debian.10~buster"
        ;;
    debian-bullseye)
        SS_LIBEV_VERSION="3.3.5-12~debian.11~bullseye"
        ;;
    debian-bookworm)
        SS_LIBEV_VERSION="3.3.5-12~debian.12~bookworm"
        ;;
    debian-trixie)
        SS_LIBEV_VERSION="3.3.5-12~debian.13~trixie"
        ;;
    ubuntu-focal)
        SS_LIBEV_VERSION="3.3.5-12~ubuntu.20.04~focal"
        ;;
    ubuntu-jammy)
        SS_LIBEV_VERSION="3.3.5-12~ubuntu.22.04~jammy"
        ;;
    ubuntu-noble)
        SS_LIBEV_VERSION="3.3.5-12~ubuntu.24.04~noble"
        ;;
    *)
        print_warn "未知的系统版本，尝试安装最新版本"
        apt-get install -y shadowsocks-libev
        SS_LIBEV_VERSION="installed"
        ;;
esac

if [ "$SS_LIBEV_VERSION" != "installed" ]; then
    apt-get install -y shadowsocks-libev=$SS_LIBEV_VERSION
fi

# 验证安装
if command -v ss-server >/dev/null 2>&1; then
    print_success "shadowsocks-libev 安装完成"
    ss-server -h | head -n 1
else
    print_error "shadowsocks-libev 安装失败"
    exit 1
fi

echo

# 步骤 6: 安装 shadowsocks-rust
print_step "步骤 6/9: 安装 shadowsocks-rust"
apt-get install -y shadowsocks-rust

# 验证安装
if command -v ssservice >/dev/null 2>&1; then
    print_success "shadowsocks-rust 安装完成"
    ssservice --version
else
    print_error "shadowsocks-rust 安装失败"
    exit 1
fi

echo

# 步骤 7: 安装 simple-obfs
print_step "步骤 7/9: 安装 simple-obfs 插件"
apt-get install -y shadowsocks-simple-obfs

# 验证安装
if command -v obfs-server >/dev/null 2>&1; then
    print_success "simple-obfs 安装完成"
    obfs-server -h | head -n 1
else
    print_error "simple-obfs 安装失败"
    exit 1
fi

echo

# 步骤 8: 创建配置文件
print_step "步骤 8/9: 创建配置文件"

# 确保配置目录存在
mkdir -p /etc/shadowsocks

# 创建 shadowsocks-libev 配置文件
print_info "创建 shadowsocks-libev 配置文件..."
cat > /etc/shadowsocks/shadowsocks-libev-config.json <<EOF
{
    "server": "0.0.0.0",
    "server_port": $LIB_PORT,
    "password": "opj33QlG2TRNOB18xt288A==",
    "timeout": 300,
    "method": "aes-256-gcm",
    "fast_open": true,
    "nameserver": "8.8.8.8",
    "mode": "tcp_only",
    "plugin": "obfs-server",
    "plugin_opts": "obfs=http"
}
EOF

# 创建 shadowsocks-rust 配置文件
print_info "创建 shadowsocks-rust 配置文件..."
cat > /etc/shadowsocks/shadowsocks-rust-config.json <<EOF
{
    "server": "0.0.0.0",
    "server_port": $RUST_PORT,
    "password": "opj33QlG2TRNOB18xt288A==",
    "timeout": 300,
    "method": "aes-128-gcm",
    "fast_open": true,
    "nameserver": "8.8.8.8",
    "mode": "tcp_only",
    "plugin": "obfs-server",
    "plugin_opts": "obfs=http"
}
EOF

print_success "配置文件创建完成"

echo

# 步骤 9: 启动服务
print_step "步骤 9/9: 启动并启用服务"

print_info "启动 shadowsocks-libev 服务..."
systemctl enable shadowsocks-libev-server --now
sleep 2

if systemctl is-active --quiet shadowsocks-libev-server; then
    print_success "shadowsocks-libev 服务已启动"
else
    print_error "shadowsocks-libev 服务启动失败"
    systemctl status shadowsocks-libev-server --no-pager
fi

print_info "启动 shadowsocks-rust 服务..."
systemctl enable shadowsocks-rust-server --now
sleep 2

if systemctl is-active --quiet shadowsocks-rust-server; then
    print_success "shadowsocks-rust 服务已启动"
else
    print_error "shadowsocks-rust 服务启动失败"
    systemctl status shadowsocks-rust-server --no-pager
fi

echo

# 显示安装总结
print_success "=========================================="
print_success "Shadowsocks 安装完成！"
print_success "=========================================="
echo
print_info "配置信息:"
echo "  服务器地址: $(curl -s ifconfig.me || echo "获取失败")"
echo "  Shadowsocks-libev 端口: $LIB_PORT"
echo "  Shadowsocks-rust 端口: $RUST_PORT"
echo "  密码: opj33QlG2TRNOB18xt288A=="
echo "  Libev 加密方法: aes-256-gcm"
echo "  Rust 加密方法: aes-128-gcm"
echo "  混淆插件: obfs-server"
echo "  混淆类型: http"
echo
print_info "配置文件位置:"
echo "  - /etc/shadowsocks/shadowsocks-libev-config.json"
echo "  - /etc/shadowsocks/shadowsocks-rust-config.json"
echo
print_info "服务管理命令:"
echo "  - 查看 libev 状态: systemctl status shadowsocks-libev-server"
echo "  - 查看 rust 状态: systemctl status shadowsocks-rust-server"
echo
print_info "日志查看命令:"
echo "  - journalctl -u shadowsocks-libev-server -f"
echo "  - journalctl -u shadowsocks-rust-server -f"
echo
print_warn "请确保防火墙已开放端口 $LIB_PORT 和 $RUST_PORT"
