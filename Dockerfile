# STAGE 1: Builder (保持不变)
FROM debian:12-slim AS builder
RUN apt-get update && \
    apt-get install -y curl ca-certificates unzip coreutils && \
    curl -fsSL -o /tmp/install.sh https://sing-box.app/install.sh && \
    sh /tmp/install.sh && \
    ls -l /usr/local/bin/sing-box && \
    rm -rf /var/lib/apt/lists/*

# STAGE 2: Final Image
FROM zerotier/zerotier:latest

ARG ENABLE_FORWARDING=false
ENV ENABLE_FORWARDING=${ENABLE_FORWARDING}

# --- 核心修改部分 ---
# 我们将以 root 用户完成所有配置，并让 Supervisor 以 root 身份启动
USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends supervisor iproute2 iptables && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/bin/sing-box /usr/local/bin/sing-box

RUN mkdir -p /etc/sing-box/ && \
    chown -R zerotier-one:zerotier-one /etc/sing-box/

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY setup_forwarding.sh /usr/local/bin/setup_forwarding.sh
RUN chmod +x /usr/local/bin/setup_forwarding.sh

# --- 核心修改部分 ---
# 1. 移除了最后的 `USER zerotier-one` 指令。
# 2. 将 `CMD` 改为 `ENTRYPOINT`，从而彻底覆盖基础镜像的启动脚本。
ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
