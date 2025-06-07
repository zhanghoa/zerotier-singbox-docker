#!/bin/sh
set -e

# 通过读取环境变量来决定是否执行转发配置
# 这个环境变量的值由 Dockerfile 在构建时设定
if [ "$ENABLE_FORWARDING" != "true" ]; then
    echo "IP forwarding is disabled in this image build. Exiting setup script."
    exit 0
fi

echo "IP forwarding is ENABLED in this image build. Applying settings..."

# 开启内核转发功能
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1

# 根据您的主机环境修改这里的出口网卡名称，通常是 eth0
EXIT_IF="eth0"
echo "Applying iptables rules for exit interface ${EXIT_IF}..."

# 配置防火墙规则
iptables -A FORWARD -i zt+ -o ${EXIT_IF} -j ACCEPT
iptables -A FORWARD -i ${EXIT_IF} -o zt+ -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -t nat -A POSTROUTING -o ${EXIT_IF} -j MASQUERADE

echo "IP forwarding rules applied successfully."
