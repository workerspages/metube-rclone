FROM ghcr.io/alexta69/metube:latest

USER root

# ── 安装依赖（不依赖 apk，全部用静态二进制或官方脚本）──────────

# 安装 rclone（官方脚本，自动识别架构，仅依赖 curl）
# metube 镜像已内置 curl，直接使用
RUN curl -fsSL https://rclone.org/install.sh | sh

# 安装 Caddy（官方 GitHub Release 静态二进制，按 TARGETARCH 选择）
ARG TARGETARCH
ARG CADDY_VERSION=2.9.1
RUN set -eux; \
    case "${TARGETARCH}" in \
        amd64) CADDY_ARCH="amd64" ;; \
        arm64) CADDY_ARCH="arm64" ;; \
        arm)   CADDY_ARCH="armv7" ;; \
        *)     echo "Unsupported arch: ${TARGETARCH}"; exit 1 ;; \
    esac; \
    curl -fsSL "https://github.com/caddyserver/caddy/releases/download/v${CADDY_VERSION}/caddy_${CADDY_VERSION}_linux_${CADDY_ARCH}.tar.gz" \
        | tar -xz -C /usr/local/bin caddy; \
    chmod +x /usr/local/bin/caddy

# 创建必要目录
RUN mkdir -p /root/.config/rclone /downloads /data/caddy

# Caddy 证书持久化目录
ENV XDG_DATA_HOME=/data

COPY Caddyfile /etc/caddy/Caddyfile
COPY entrypoint.sh /entrypoint-wrapper.sh
RUN chmod +x /entrypoint-wrapper.sh

EXPOSE 8080

ENTRYPOINT ["/entrypoint-wrapper.sh"]
