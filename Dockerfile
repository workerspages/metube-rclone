FROM ghcr.io/alexta69/metube:latest

USER root

# metube 镜像内 /bin/sh 为 dash，无 bash/apk，全部改用静态二进制直接下载

# 安装 rclone
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

# 安装 Caddy
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

# metube 监听地址固定为 127.0.0.1:8081
# 注意：metube 用的环境变量是 HOST 和 PORT
# PORT 环境变量不能用于 Caddy 对外端口，需用 CADDY_PORT 区分
ENV HOST=127.0.0.1
ENV PORT=8081

COPY Caddyfile /etc/caddy/Caddyfile
COPY entrypoint.sh /entrypoint-wrapper.sh
RUN chmod +x /entrypoint-wrapper.sh

EXPOSE 8080

ENTRYPOINT ["/entrypoint-wrapper.sh"]
