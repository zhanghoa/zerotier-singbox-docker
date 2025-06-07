# =================================================================
#  阶段一 (Stage 1): 构建/下载阶段 (Builder)
#  我们使用一个临时的 Debian 镜像来下载 Sing-box
# =================================================================
FROM debian:12-slim AS builder

# 在这个临时环境中，安装 curl 用于下载
RUN apt-get update && apt-get install -y curl ca-certificates && rm -rf /var/lib/apt/lists/*

# 下载并安装 Sing-box，它的二进制文件会出现在 /usr/local/bin/sing-box
RUN curl -fsSL https://sing-box.app/install.sh | sh

# =================================================================
#  阶段二 (Stage 2): 最终镜像 (Final Image)
#  以我们需要的 ZeroTier 镜像为基础
# =================================================================
FROM zerotier/zerotier:latest

# 声明和设置环境变量，逻辑保持不变
ARG ENABLE_FORWARDING=false
ENV ENABLE_FORWARDING=${ENABLE_FORWARDING}

USER root

# 只安装【运行】所必需的依赖，不再需要 curl
RUN apt-get update && \
    apt-get install -y --no-install-recommends supervisor iproute2 iptables && \
    rm -rf /var/lib/apt/lists/*

# --- 关键步骤 ---
# 从第一阶段 (builder) 中，只把 sing-box 的可执行文件拷贝过来
COPY --from=builder /usr/local/bin/sing-box /usr/local/bin/sing-box

# 后续步骤保持完全不变
RUN mkdir -p /etc/sing-box/ && \
    chown -R zerotier-one:zerotier-one /etc/sing-box/

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY setup_forwarding.sh /usr/local/bin/setup_forwarding.sh
RUN chmod +x /usr/local/bin/setup_forwarding.sh

USER zerotier-one

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
