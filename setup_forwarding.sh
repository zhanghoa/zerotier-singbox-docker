#!/bin/sh
set -e

# 检查环境变量 ENABLE_FORWARDING 是否为 "true"
if [ "$ENABLE_FORWARDING" != "true" ]; then
    echo "IP forwarding is disabled by environment variable. Exiting setup script."
    exit 0
fi

# --- 只有当 ENABLE_FORWARDING=true 时，以下代码才会执行 ---

echo "IP forwarding is ENABLED. Applying settings..."

# 1. 开启内核转发功能
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1

# 2. 应用 iptables 规则
# 请根据您的主机环境修改这里的出口网卡名称，通常是 eth0
EXIT_IF="eth0"
echo "Applying iptables rules for exit interface ${EXIT_IF}..."

iptables -A FORWARD -i zt+ -o ${EXIT_IF} -j ACCEPT
iptables -A FORWARD -i ${EXIT_IF} -o zt+ -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -t nat -A POSTROUTING -o ${EXIT_IF} -j MASQUERADE

echo "IP forwarding rules applied successfully."
