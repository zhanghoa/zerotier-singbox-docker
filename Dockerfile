# =================================================================
#  阶段一 (Stage 1): 构建/下载阶段 (Builder)
# =================================================================
FROM debian:12-slim AS builder

# --- 核心修正 ---
# 在安装 curl 的同时，安装 sing-box 安装脚本所必需的 unzip 和 coreutils
RUN apt-get update && \
    apt-get install -y curl ca-certificates unzip coreutils && \
    # 1. 先下载安装脚本
    curl -fsSL -o /tmp/install.sh https://sing-box.app/install.sh && \
    # 2. 执行安装脚本
    sh /tmp/install.sh && \
    # 3. 验证文件是否已成功安装到目标位置
    ls -l /usr/local/bin/sing-box && \
    # 4. 清理工作
    rm -rf /var/lib/apt/lists/*

# =================================================================
#  阶段二 (Stage 2): 最终镜像 (Final Image)
# =================================================================
FROM zerotier/zerotier:latest

ARG ENABLE_FORWARDING=false
ENV ENABLE_FORWARDING=${ENABLE_FORWARDING}

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends supervisor iproute2 iptables && \
    rm -rf /var/lib/apt/lists/*

# 从第一阶段拷贝预先构建好的 sing-box 二进制文件
COPY --from=builder /usr/local/bin/sing-box /usr/local/bin/sing-box

# 后续所有步骤保持不变
RUN mkdir -p /etc/sing-box/ && \
    chown -R zerotier-one:zerotier-one /etc/sing-box/

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY setup_forwarding.sh /usr/local/bin/setup_forwarding.sh
RUN chmod +x /usr/local/bin/setup_forwarding.sh

USER zerotier-one

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
