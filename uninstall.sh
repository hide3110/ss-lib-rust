#!/bin/bash

# Shadowsocks (libev & rust) 和 simple-obfs 卸载脚本
# 适用于 Debian 11/12/13 和 Ubuntu 20.04/22.04/24.04
# 使用方法: sudo bash uninstall_shadowsocks.sh

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

echo

# 显示警告信息
print_warn "=========================================="
print_warn "此操作将完全卸载 Shadowsocks 相关组件"
print_warn "=========================================="
echo
print_warn "将要执行的操作:"
echo "  1. 停止并禁用 shadowsocks-libev 服务"
echo "  2. 停止并禁用 shadowsocks-rust 服务"
echo "  3. 卸载 shadowsocks-libev 软件包"
echo "  4. 卸载 shadowsocks-rust 软件包"
echo "  5. 卸载 simple-obfs 软件包"
echo "  6. 删除配置文件"
echo "  7. 删除软件源配置"
echo "  8. 删除 GPG 密钥"
echo

printf "确定要继续卸载吗? 此操作不可恢复 (y/N): "
read -r REPLY
if ! echo "$REPLY" | grep -qE '^[Yy]$'; then
    print_info "已取消卸载"
    exit 0
fi

echo

# 步骤 1: 停止并禁用 shadowsocks-libev 服务
print_step "步骤 1/8: 停止并禁用 shadowsocks-libev 服务"
if systemctl is-active --quiet shadowsocks-libev-server 2>/dev/null; then
    print_info "正在停止 shadowsocks-libev 服务..."
    systemctl stop shadowsocks-libev-server
    print_success "shadowsocks-libev 服务已停止"
else
    print_warn "shadowsocks-libev 服务未运行"
fi

if systemctl is-enabled --quiet shadowsocks-libev-server 2>/dev/null; then
    print_info "正在禁用 shadowsocks-libev 服务..."
    systemctl disable shadowsocks-libev-server
    print_success "shadowsocks-libev 服务已禁用"
else
    print_warn "shadowsocks-libev 服务未启用"
fi

echo

# 步骤 2: 停止并禁用 shadowsocks-rust 服务
print_step "步骤 2/8: 停止并禁用 shadowsocks-rust 服务"
if systemctl is-active --quiet shadowsocks-rust-server 2>/dev/null; then
    print_info "正在停止 shadowsocks-rust 服务..."
    systemctl stop shadowsocks-rust-server
    print_success "shadowsocks-rust 服务已停止"
else
    print_warn "shadowsocks-rust 服务未运行"
fi

if systemctl is-enabled --quiet shadowsocks-rust-server 2>/dev/null; then
    print_info "正在禁用 shadowsocks-rust 服务..."
    systemctl disable shadowsocks-rust-server
    print_success "shadowsocks-rust 服务已禁用"
else
    print_warn "shadowsocks-rust 服务未启用"
fi

echo

# 步骤 3: 卸载 shadowsocks-libev
print_step "步骤 3/8: 卸载 shadowsocks-libev"
if dpkg -l | grep -q shadowsocks-libev; then
    print_info "正在卸载 shadowsocks-libev..."
    apt-get purge -y shadowsocks-libev
    print_success "shadowsocks-libev 已卸载"
else
    print_warn "shadowsocks-libev 未安装"
fi

echo

# 步骤 4: 卸载 shadowsocks-rust
print_step "步骤 4/8: 卸载 shadowsocks-rust"
if dpkg -l | grep -q shadowsocks-rust; then
    print_info "正在卸载 shadowsocks-rust..."
    apt-get purge -y shadowsocks-rust
    print_success "shadowsocks-rust 已卸载"
else
    print_warn "shadowsocks-rust 未安装"
fi

echo

# 步骤 5: 卸载 simple-obfs
print_step "步骤 5/8: 卸载 simple-obfs"
if dpkg -l | grep -q shadowsocks-simple-obfs; then
    print_info "正在卸载 simple-obfs..."
    apt-get purge -y shadowsocks-simple-obfs
    print_success "simple-obfs 已卸载"
else
    print_warn "simple-obfs 未安装"
fi

echo

# 步骤 6: 删除配置文件
print_step "步骤 6/8: 删除配置文件"
if [ -d /etc/shadowsocks ]; then
    print_info "正在删除配置目录..."
    rm -rf /etc/shadowsocks
    print_success "配置目录已删除"
else
    print_warn "配置目录不存在"
fi

echo

# 步骤 7: 删除软件源配置
print_step "步骤 7/8: 删除软件源配置"
if [ -f /etc/apt/sources.list.d/teddysun.list ]; then
    print_info "正在删除软件源配置..."
    rm -f /etc/apt/sources.list.d/teddysun.list
    print_success "软件源配置已删除"
else
    print_warn "软件源配置不存在"
fi

echo

# 步骤 8: 删除 GPG 密钥
print_step "步骤 8/8: 删除 GPG 密钥"
if [ -f /usr/share/keyrings/deb-gpg-key-teddysun.gpg ]; then
    print_info "正在删除 GPG 密钥..."
    rm -f /usr/share/keyrings/deb-gpg-key-teddysun.gpg
    print_success "GPG 密钥已删除"
else
    print_warn "GPG 密钥不存在"
fi

echo

# 清理无用的依赖包
print_info "正在清理无用的依赖包..."
apt-get autoremove -y
apt-get autoclean -y

echo

# 更新软件包缓存
print_info "正在更新软件包缓存..."
apt-get update

echo

# 显示卸载总结
print_success "=========================================="
print_success "Shadowsocks 卸载完成！"
print_success "=========================================="
echo
print_info "卸载总结:"
echo "  - shadowsocks-libev: 已卸载"
echo "  - shadowsocks-rust: 已卸载"
echo "  - simple-obfs: 已卸载"
echo "  - 配置文件: 已删除"
echo "  - 软件源: 已删除"
echo "  - GPG 密钥: 已删除"
echo

print_info "验证卸载状态:"
if command -v ss-server >/dev/null 2>&1; then
    print_warn "ss-server 命令仍然存在"
else
    print_success "ss-server 命令已移除"
fi

if command -v ssservice >/dev/null 2>&1; then
    print_warn "ssservice 命令仍然存在"
else
    print_success "ssservice 命令已移除"
fi

if command -v obfs-server >/dev/null 2>&1; then
    print_warn "obfs-server 命令仍然存在"
else
    print_success "obfs-server 命令已移除"
fi

echo
print_success "系统已清理完毕！"
