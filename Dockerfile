# =================================================================
#  阶段一 (Stage 1): 构建/下载阶段 (Builder)
#  我们使用一个临时的 Debian 镜像来下载 Sing-box
# =================================================================
FROM debian:12-slim AS builder

# --- 核心修改部分 ---
# 将所有操作合并到一层，并增加验证，使其更健壮
RUN apt-get update && \
    apt-get install -y curl ca-certificates && \
    # 1. 先下载安装脚本，而不是直接通过管道执行
    curl -fsSL -o /tmp/install.sh https://sing-box.app/install.sh && \
    # 2. 执行安装脚本
    sh /tmp/install.sh && \
    # 3. 关键：立即验证文件是否已成功安装到目标位置
    #    如果文件不存在，这一步会失败，构建会立即停止，错误信息会非常清晰。
    ls -l /usr/local/bin/sing-box && \
    # 4. 清理工作
    rm -rf /var/lib/apt/lists/*

# =================================================================
#  阶段二 (Stage 2): 最终镜像 (Final Image)
#  (此阶段及之后的所有内容保持不变)
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

USER zerotier-one

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
