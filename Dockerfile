FROM ghcr.io/alexta69/metube:latest

USER root

# 安装 rclone 及依赖
RUN apt-get update && \
    apt-get install -y curl fuse3 && \
    curl -fsSL https://rclone.org/install.sh | bash && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 创建必要目录
RUN mkdir -p /root/.config/rclone /downloads

# 复制启动脚本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# metube 端口 8081，WebDAV 端口 8080
EXPOSE 8081
EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
