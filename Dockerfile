FROM ghcr.io/alexta69/metube:latest

USER root

# 安装 rclone、Caddy 及依赖
RUN apt-get update && \
    apt-get install -y curl debian-keyring debian-archive-keyring apt-transport-https fuse3 && \
    # 安装 Caddy
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg && \
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list && \
    apt-get update && \
    apt-get install -y caddy && \
    # 安装 rclone
    curl -fsSL https://rclone.org/install.sh | bash && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 创建必要目录
RUN mkdir -p /root/.config/rclone /downloads /data/caddy

# Caddy 数据目录（存储 ACME 证书）
ENV XDG_DATA_HOME=/data

# 复制配置文件和启动脚本
COPY Caddyfile /etc/caddy/Caddyfile
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 对外暴露单一端口
EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
