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
RUN mkdir -p /root/.config/rclone /data/caddy

# Caddy 证书持久化目录
ENV XDG_DATA_HOME=/data

COPY Caddyfile /etc/caddy/Caddyfile
COPY entrypoint.sh /entrypoint-wrapper.sh
RUN chmod +x /entrypoint-wrapper.sh

# Option Presets (预设)
COPY presets.json /config/presets.json
# 让 MeTube 自动读取并应用该预设文件
ENV YTDL_OPTIONS_PRESETS_FILE=/config/presets.json

# 常用环境变量
# 允许同时进行的最大下载数量
ENV MAX_CONCURRENT_DOWNLOADS=5
# 自动从“已完成”列表中移除已完成（和失败）下载记录的等待秒数。默认值：0（禁用自动清除）
ENV CLEAR_COMPLETED_AFTER=0
# 是否支持自动创建不存在的子目录。启用后，你可以直接在下拉框输入文字，MeTube 会自动创建该目录。默认值：true
ENV CREATE_CUSTOM_DIRS=true
# 是否在 UI 的高级选项中显示一个输入框，允许用户每次下载时手动覆盖/写入特定选项。默认值：false（开启此项有执行任意命令的安全风险，仅限信任环境使用）。
ENV ALLOW_YTDL_OPTIONS_OVERRIDES=false

# 覆盖 metube 基础镜像的 ENV PORT=8081，让 Caddy 默认监听 8080
# （Zeabur 等 PaaS 平台可能通过 PORT 环境变量注入实际端口）
ENV PORT=8080

EXPOSE 8080

# 使用 tini 作为 PID 1（与 metube 原始镜像一致），确保信号正确传播
ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/entrypoint-wrapper.sh"]
