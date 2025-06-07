# =================================================================
#  STAGE 1: Builder - Download and Extract .deb package
# =================================================================
FROM debian:12-slim AS builder

# 安装 curl 用于下载
RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

# --- 核心修改：我们自己手动下载并解包 ---

# 1. 下载和 Sing-box 版本相关的 .deb 包
#    注意：这里的架构 (armhf) 是根据您上次的日志推断的。
#    如果您的目标平台是 amd64 或 arm64，需要替换成对应的词 (amd64, arm64)
#    或者我们可以动态确定架构，如下所示。
RUN ARCH=$(dpkg --print-architecture) && \
    case "${ARCH}" in \
        amd64) DEB_ARCH="amd64";; \
        arm64) DEB_ARCH="arm64";; \
        armhf) DEB_ARCH="armhf";; \
        *) echo "Unsupported architecture: ${ARCH}"; exit 1;; \
    esac && \
    curl -fsSL -o /tmp/sing-box.deb \
    "https://github.com/SagerNet/sing-box/releases/download/v1.11.13/sing-box_1.11.13_linux_${DEB_ARCH}.deb"

# 2. 创建一个临时目录用于解压
RUN mkdir -p /tmp/deb_contents

# 3. 使用 dpkg -x 命令将 .deb 包的内容解压到临时目录
RUN dpkg -x /tmp/sing-box.deb /tmp/deb_contents

# 4. 验证我们需要的 sing-box 文件是否在解压后的目录中
#    .deb包通常会将程序放在 /usr/bin/ 目录下
RUN ls -l /tmp/deb_contents/usr/bin/sing-box

# =================================================================
#  STAGE 2: Final Image
# =================================================================
FROM zerotier/zerotier:latest

ARG ENABLE_FORWARDING=false
ENV ENABLE_FORWARDING=${ENABLE_FORWARDING}

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends supervisor iproute2 iptables && \
    rm -rf /var/lib/apt/lists/*

# --- 核心修改：从解压后的正确路径拷贝文件 ---
COPY --from=builder /tmp/deb_contents/usr/bin/sing-box /usr/local/bin/sing-box

# 后续所有步骤保持不变
RUN mkdir -p /etc/sing-box/ && \
    chown -R zerotier-one:zerotier-one /etc/sing-box/

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY setup_forwarding.sh /usr/local/bin/setup_forwarding.sh
RUN chmod +x /usr/local/bin/setup_forwarding.sh

USER zerotier-one

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
