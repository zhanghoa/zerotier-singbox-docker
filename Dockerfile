# =================================================================
#  STAGE 1: Builder (Final Debug Mode)
# =================================================================
FROM debian:12-slim AS builder

# 安装所有可能的依赖
RUN apt-get update && \
    apt-get install -y curl ca-certificates unzip coreutils && \
    rm -rf /var/lib/apt/lists/*

# --- 核心调试步骤 ---
# 我们将执行脚本的命令单独放在一个 RUN 指令中，
# 并将标准错误（stderr）重定向到标准输出（stdout），以确保能看到所有信息
RUN curl -fsSL -o /tmp/install.sh https://sing-box.app/install.sh && \
    sh /tmp/install.sh 2>&1

# =================================================================
#  STAGE 2: Final Image (保持不变)
# =================================================================
FROM zerotier/zerotier:latest

ARG ENABLE_FORWARDING=false
ENV ENABLE_FORWARDING=${ENABLE_FORWARDING}

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

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
