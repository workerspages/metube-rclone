FROM ghcr.io/alexta69/metube:latest

USER root

# 官方镜像基于 Alpine，使用 apk 安装依赖
RUN apk add --no-cache curl fuse3 ca-certificates

# 安装 Caddy（通过官方 Alpine 包）
RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community caddy

# 安装 rclone
RUN curl -fsSL https://rclone.org/install.sh | sh

# 创建必要目录
RUN mkdir -p /root/.config/rclone /downloads /data/caddy

# Caddy 数据目录（存储 ACME 证书）
ENV XDG_DATA_HOME=/data

# 复制配置文件和包装启动脚本
COPY Caddyfile /etc/caddy/Caddyfile
COPY entrypoint.sh /entrypoint-wrapper.sh
RUN chmod +x /entrypoint-wrapper.sh

# 对外暴露单一端口
EXPOSE 8080

ENTRYPOINT ["/entrypoint-wrapper.sh"]
