#!/bin/sh
set -e

# 环境变量配置
PUBLIC_DOMAIN="${PUBLIC_DOMAIN:-}"
PORT="${PORT:-8080}"
METUBE_PORT="8081"
WEBDAV_PORT="8082"

WEBDAV_USER="${WEBDAV_USER:-admin}"
WEBDAV_PASS="${WEBDAV_PASS:-admin}"
UI_USER="${UI_USER:-admin}"
UI_PASS="${UI_PASS:-admin}"
DOWNLOAD_DIR="${DOWNLOAD_DIR:-/downloads}"

# 生成 Caddy basicauth 密码哈希
echo "[wrapper] Hashing UI password for Caddy basicauth..."
UI_PASS_HASH=$(caddy hash-password --plaintext "${UI_PASS}")

# 确保下载目录存在
mkdir -p "${DOWNLOAD_DIR}"

# 将实际用户名和哈希直接写入 Caddyfile（替换占位符）
sed -i "s|AUTH_PLACEHOLDER|${UI_USER} ${UI_PASS_HASH}|" /etc/caddy/Caddyfile

# 设置监听地址：有域名用 HTTPS，无域名用 HTTP
if [ -n "${PUBLIC_DOMAIN}" ]; then
    sed -i "s|LISTEN_PLACEHOLDER|${PUBLIC_DOMAIN}|" /etc/caddy/Caddyfile
    echo "[wrapper]  Domain    : ${PUBLIC_DOMAIN} (HTTPS auto)"
    echo "[wrapper]  UI        : https://${PUBLIC_DOMAIN}/"
    echo "[wrapper]  WebDAV    : https://${PUBLIC_DOMAIN}/dav/"
else
    sed -i "s|LISTEN_PLACEHOLDER|:${PORT}|" /etc/caddy/Caddyfile
    echo "[wrapper]  Domain    : (none, HTTP on :${PORT})"
    echo "[wrapper]  UI        : http://localhost:${PORT}/"
    echo "[wrapper]  WebDAV    : http://localhost:${PORT}/dav/"
fi

echo "[wrapper] ============================================"
echo "[wrapper]  UI User   : ${UI_USER}"
echo "[wrapper]  DAV User  : ${WEBDAV_USER}"
echo "[wrapper]  DL Dir    : ${DOWNLOAD_DIR}"
echo "[wrapper] ============================================"

# 后台启动 rclone WebDAV
rclone serve webdav "${DOWNLOAD_DIR}" \
    --addr "127.0.0.1:${WEBDAV_PORT}" \
    --user "${WEBDAV_USER}" \
    --pass "${WEBDAV_PASS}" \
    --vfs-cache-mode full \
    --log-level INFO &
echo "[wrapper] rclone WebDAV started (PID: $!)"

# 后台启动 Caddy
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &
echo "[wrapper] Caddy started (PID: $!)"

# 直接调用 metube 官方入口脚本
echo "[wrapper] Handing off to metube official entrypoint..."
export LISTEN_HOST=127.0.0.1
export LISTEN_PORT=${METUBE_PORT}
exec /app/docker-entrypoint.sh
