FROM ghcr.io/alexta69/metube:latest

USER root

# metube 镜像内 /bin/sh 为 dash，无 bash/apk，全部改用静态二进制直接下载

# 安装 rclone（按 TARGETARCH 下载对应静态二进制，无需 bash）
ARG TARGETARCH
ARG RCLONE_VERSION=v1.69.1
RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64) RCLONE_ARCH="amd64" ;; \
        arm64) RCLONE_ARCH="arm64" ;; \
        arm)   RCLONE_ARCH="arm-v7" ;; \
        *)     echo "Unsupported arch: ${TARGETARCH}"; exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/rclone/rclone/releases/download/${RCLONE_VERSION}/rclone-${RCLONE_VERSION}-linux-${RCLONE_ARCH}.zip" \
        -o /tmp/rclone.zip && \
    unzip -q /tmp/rclone.zip -d /tmp/rclone-tmp && \
    mv /tmp/rclone-tmp/rclone-*/rclone /usr/local/bin/rclone && \
    chmod +x /usr/local/bin/rclone && \
    rm -rf /tmp/rclone.zip /tmp/rclone-tmp

# 安装 Caddy（按 TARGETARCH 下载对应静态二进制）
ARG CADDY_VERSION=2.9.1
RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64) CADDY_ARCH="amd64" ;; \
        arm64) CADDY_ARCH="arm64" ;; \
        arm)   CADDY_ARCH="armv7" ;; \
        *)     echo "Unsupported arch: ${TARGETARCH}"; exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/caddyserver/caddy/releases/download/v${CADDY_VERSION}/caddy_${CADDY_VERSION}_linux_${CADDY_ARCH}.tar.gz" \
        | tar -xz -C /usr/local/bin caddy && \
    chmod +x /usr/local/bin/caddy

# 创建必要目录
RUN mkdir -p /root/.config/rclone /downloads /data/caddy

# Caddy 证书持久化目录
ENV XDG_DATA_HOME=/data

# 将 metube 监听地址固定为 127.0.0.1:8081，避免与 Caddy 的 8080 冲突
# 这里用 ENV 而不是在 entrypoint.sh 里 export，确保 metube 官方入口就能读到
ENV LISTEN_HOST=127.0.0.1
ENV LISTEN_PORT=8081

COPY Caddyfile /etc/caddy/Caddyfile
COPY entrypoint.sh /entrypoint-wrapper.sh
RUN chmod +x /entrypoint-wrapper.sh

EXPOSE 8080

ENTRYPOINT ["/entrypoint-wrapper.sh"]
