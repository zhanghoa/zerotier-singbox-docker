# =================================================================
#  STAGE 1: Builder
# =================================================================
FROM debian:12-slim AS builder

# 安装所有构建 sing-box 所需的依赖
RUN apt-get update && \
    apt-get install -y curl ca-certificates unzip coreutils && \
    rm -rf /var/lib/apt/lists/*

# 下载并执行官方安装脚本
# 我们现在已经确认它可以成功执行
RUN curl -fsSL -o /tmp/install.sh https://sing-box.app/install.sh && \
    sh /tmp/install.sh

# =================================================================
#  STAGE 2: Final Image
# =================================================================
FROM zerotier/zerotier:latest

ARG ENABLE_FORWARDING=false
ENV ENABLE_FORWARDING=${ENABLE_FORWARDING}

USER root

# 安装所有最终镜像运行所需的依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends supervisor iproute2 iptables && \
    rm -rf /var/lib/apt/lists/*

# --- 核心修正 ---
# 从第一阶段的正确路径 /usr/bin/sing-box 复制文件
COPY --from=builder /usr/bin/sing-box /usr/local/bin/sing-box

# 后续所有步骤保持不变
RUN mkdir -p /etc/sing-box/ && \
    chown -R zerotier-one:zerotier-one /etc/sing-box/

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY setup_forwarding.sh /usr/local/bin/setup_forwarding.sh
RUN chmod +x /usr/local/bin/setup_forwarding.sh

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
