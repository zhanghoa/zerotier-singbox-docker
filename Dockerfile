# =================================================================
#  STAGE 1: Builder (Debug Mode to find the file)
# =================================================================
FROM debian:12-slim AS builder

RUN apt-get update && \
    apt-get install -y curl ca-certificates unzip coreutils && \
    rm -rf /var/lib/apt/lists/*

# --- 核心修改部分 ---
# 在这里，我们在执行安装脚本后，增加一个 `find` 命令来搜索全部分区
RUN curl -fsSL -o /tmp/install.sh https://sing-box.app/install.sh && \
    sh /tmp/install.sh && \
    echo "Searching for sing-box executable..." && \
    find / -name "sing-box"

# =================================================================
#  STAGE 2: Final Image
#  (此阶段暂时保持不变，但很可能会因为第一阶段的改动而失败，这是预期的)
# =================================================================
FROM zerotier/zerotier:latest

ARG ENABLE_FORWARDING=false
ENV ENABLE_FORWARDING=${ENABLE_FORWARDING}

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends supervisor iproute2 iptables && \
    rm -rf /var/lib/apt/lists/*

# 我们暂时保持这一行不变，但预计它会失败
COPY --from=builder /usr/local/bin/sing-box /usr/local/bin/sing-box

RUN mkdir -p /etc/sing-box/ && \
    chown -R zerotier-one:zerotier-one /etc/sing-box/

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY setup_forwarding.sh /usr/local/bin/setup_forwarding.sh
RUN chmod +x /usr/local/bin/setup_forwarding.sh

USER zerotier-one

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
