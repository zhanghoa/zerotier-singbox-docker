FROM zerotier/zerotier:latest

# 声明一个构建参数，可以从 `docker build` 命令接收
# 它的值将由 GitHub Actions 工作流在构建时动态传入
ARG ENABLE_FORWARDING=false
# 将这个参数的值设为容器的环境变量，以便脚本和Supervisor可以访问
ENV ENABLE_FORWARDING=${ENABLE_FORWARDING}

USER root

# 安装所有依赖: supervisor, iptables, curl, iproute2
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates supervisor iproute2 iptables && \
    rm -rf /var/lib/apt/lists/*

# 安装 Sing-box
RUN curl -fsSL https://sing-box.app/install.sh | sh

# 创建 Sing-box 的配置目录并赋予权限
RUN mkdir -p /etc/sing-box/ && \
    chown -R zerotier-one:zerotier-one /etc/sing-box/

# 复制 Supervisor 配置文件
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# 复制转发脚本并赋予执行权限
COPY setup_forwarding.sh /usr/local/bin/setup_forwarding.sh
RUN chmod +x /usr/local/bin/setup_forwarding.sh

USER zerotier-one

# 设置容器启动时运行 Supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
