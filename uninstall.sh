#!/bin/bash

# Shadowsocks (libev & rust) + simple-obfs 一键卸载脚本 (最终自动化版)
# 适用于 Debian / Ubuntu
# 使用方法: bash uninstall.sh

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 打印函数
print_info() { echo -e "${GREEN}[信息]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[警告]${NC} $1"; }
print_error() { echo -e "${RED}[错误]${NC} $1"; }
print_success() { echo -e "${GREEN}[成功]${NC} $1"; }
print_step() { echo -e "${BLUE}[步骤]${NC} $1"; }

# 检查 root 权限
if [ "$(id -u)" -ne 0 ]; then
    print_error "此脚本必须以 root 身份运行"
    exit 1
fi

print_warn "================================================="
print_warn "=== Shadowsocks 全自动卸载脚本 ==="
print_warn "================================================="
print_info "脚本将直接开始卸载..."
sleep 2

# 步骤 1: 停止并禁用服务
print_step "步骤 1/5: 停止并禁用服务"

# 停止 libev
print_info "处理 shadowsocks-libev 服务..."
if systemctl is-active --quiet shadowsocks-libev 2>/dev/null; then
    systemctl stop shadowsocks-libev
    print_success "shadowsocks-libev 服务已停止"
fi
if systemctl is-enabled --quiet shadowsocks-libev 2>/dev/null; then
    systemctl disable shadowsocks-libev
    print_success "shadowsocks-libev 服务已禁用"
fi

# 停止 rust
print_info "处理 shadowsocks-rust 服务..."
if systemctl is-active --quiet shadowsocks-rust 2>/dev/null; then
    systemctl stop shadowsocks-rust
    print_success "shadowsocks-rust 服务已停止"
fi
if systemctl is-enabled --quiet shadowsocks-rust 2>/dev/null; then
    systemctl disable shadowsocks-rust
    print_success "shadowsocks-rust 服务已禁用"
fi

echo

# 步骤 2: 删除 systemd 服务文件
print_step "步骤 2/5: 删除 systemd 服务文件"

SERVICE_FILE_RUST="/usr/lib/systemd/system/shadowsocks-rust.service"
if [ -f "$SERVICE_FILE_RUST" ]; then
    rm -f "$SERVICE_FILE_RUST"
    print_success "已删除手动创建的 shadowsocks-rust 服务文件"
fi

# libev 的服务文件将由 apt purge 自动处理
systemctl daemon-reload
print_success "systemd 配置已重新加载"

echo

# 步骤 3: 卸载软件包和删除二进制文件
print_step "步骤 3/5: 卸载软件和删除二进制文件"

# 卸载 shadowsocks-libev 软件包
print_info "卸载 shadowsocks-libev 软件包..."
if dpkg -l | grep -q shadowsocks-libev; then
    apt-get remove --purge -y shadowsocks-libev
    print_success "shadowsocks-libev 已通过 apt purge 完全卸载"
else
    print_info "shadowsocks-libev 未通过 apt 安装（跳过）"
fi

# 删除手动安装的 shadowsocks-rust 二进制文件
print_info "删除手动安装的 shadowsocks-rust 二进制文件..."
RUST_BINS=(
    /usr/bin/sslocal
    /usr/bin/ssserver
    /usr/bin/ssmanager
    /usr/bin/ssurl
    /usr/bin/ssservice
)
for bin in "${RUST_BINS[@]}"; do
    if [ -f "$bin" ]; then
        rm -f "$bin"
        print_success "已删除 $bin"
    fi
done

# 删除 simple-obfs 二进制文件
print_info "删除 simple-obfs 二进制文件..."
OBFS_BINS=(
    /usr/bin/obfs-server
    /usr/bin/obfs-local
)
for bin in "${OBFS_BINS[@]}"; do
    if [ -f "$bin" ]; then
        rm -f "$bin"
        print_success "已删除 $bin"
    fi
done

echo

# 步骤 4: 删除配置文件和目录
print_step "步骤 4/5: 删除配置文件和目录"

if [ -d /etc/shadowsocks-libev ]; then
    rm -rf /etc/shadowsocks-libev
    print_success "已删除 /etc/shadowsocks-libev 目录"
fi

if [ -d /etc/shadowsocks-rust ]; then
    rm -rf /etc/shadowsocks-rust
    print_success "已删除 /etc/shadowsocks-rust 目录"
fi

echo

# 步骤 5: 清理系统
print_step "步骤 5/5: 清理系统"

# 清理安装时下载的临时文件
print_info "清理临时文件..."
TEMP_FILES=(
    /tmp/shadowsocks-rust.tar.xz
    /tmp/simple-obfs.tar.gz
)
for file in "${TEMP_FILES[@]}"; do
    if [ -f "$file" ]; then
        rm -f "$file"
        print_success "已删除 $file"
    fi
done

# 清理 APT 缓存和无用依赖
print_info "清理 APT 缓存和无用依赖..."
apt-get autoremove -y > /dev/null
apt-get clean > /dev/null
print_success "APT 清理完成"

echo

# 卸载总结
print_success "=========================================="
print_success "所有卸载操作已完成！"
print_success "=========================================="
echo

# 最终检查
print_info "最终检查残留..."
RESIDUAL=false
COMMANDS_TO_CHECK=("ss-server" "ssserver" "obfs-server" "sslocal")

for cmd in "${COMMANDS_TO_CHECK[@]}"; do
    if command -v $cmd >/dev/null 2>&1; then
        print_warn "发现残留: 命令 '$cmd' 仍然存在于 $(command -v $cmd)"
        RESIDUAL=true
    fi
done

if [ "$RESIDUAL" = false ]; then
    print_success "未发现主要残留命令，系统已清理干净。"
fi

echo
print_success "=========================================="
