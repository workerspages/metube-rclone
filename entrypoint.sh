#!/bin/sh
set -e

# 环境变量配置
PUBLIC_DOMAIN="${PUBLIC_DOMAIN:-}"
# Caddy 对外监听端口：Zeabur 会强制注入 PORT 变量，所以用专用 CADDY_PORT 避开冲突
CADDY_PORT="${PORT:-8080}"
WEBDAV_PORT="8082"

WEBDAV_USER="${WEBDAV_USER:-admin}"
WEBDAV_PASS="${WEBDAV_PASS:-admin}"
UI_USER="${UI_USER:-admin}"
UI_PASS="${UI_PASS:-admin}"
DOWNLOAD_DIR="${DOWNLOAD_DIR:-/downloads}"

# metube 内部端口硬编码为 8081，避免被 Zeabur 强制注入的 PORT 变量覆盖
METUBE_HOST="127.0.0.1"
METUBE_PORT="8081"

echo "[wrapper] Caddy will listen on :${CADDY_PORT}"
echo "[wrapper] MeTube internal: ${METUBE_HOST}:${METUBE_PORT}"

# 生成 Caddy basicauth 密码哈希
echo "[wrapper] Hashing UI password for Caddy basicauth..."
UI_PASS_HASH="$(caddy hash-password --plaintext "${UI_PASS}" | tr -d '\r\n')"

if [ -z "${UI_PASS_HASH}" ]; then
    echo "[wrapper] ERROR: failed to generate Caddy password hash, aborting."
    exit 1
fi

mkdir -p "${DOWNLOAD_DIR}"

sed -i "s|AUTH_PLACEHOLDER|${UI_USER} ${UI_PASS_HASH}|" /etc/caddy/Caddyfile
sed -i "s|LISTEN_PLACEHOLDER|:${CADDY_PORT}|" /etc/caddy/Caddyfile
# 将 Caddyfile 中 metube 的内部地址改为硬编码的 8081
# (Caddyfile 中已是 127.0.0.1:8081，无需替换)

if [ -n "${PUBLIC_DOMAIN}" ]; then
    echo "[wrapper]  Domain    : ${PUBLIC_DOMAIN} (HTTPS handled by Zeabur)"
    echo "[wrapper]  UI        : https://${PUBLIC_DOMAIN}/"
    echo "[wrapper]  WebDAV    : https://${PUBLIC_DOMAIN}/dav/"
else
    echo "[wrapper]  Domain    : (none, HTTP on :${CADDY_PORT})"
    echo "[wrapper]  UI        : http://localhost:${CADDY_PORT}/"
    echo "[wrapper]  WebDAV    : http://localhost:${CADDY_PORT}/dav/"
fi

echo "[wrapper] ============================================"
echo "[wrapper]  UI User   : ${UI_USER}"
echo "[wrapper]  DAV User  : ${WEBDAV_USER}"
echo "[wrapper]  DL Dir    : ${DOWNLOAD_DIR}"
echo "[wrapper] ============================================"

echo "[wrapper] Rendered Caddyfile:"
cat /etc/caddy/Caddyfile

caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile

rclone serve webdav "${DOWNLOAD_DIR}" \
    --addr "127.0.0.1:${WEBDAV_PORT}" \
    --user "${WEBDAV_USER}" \
    --pass "${WEBDAV_PASS}" \
    --vfs-cache-mode full \
    --log-level INFO &
echo "[wrapper] rclone WebDAV started (PID: $!)"

caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &
echo "[wrapper] Caddy started (PID: $!)"

# 通过环境变量强制覆盖 metube 监听地址，使用 HOST/PORT 变量名（metube 原生变量）
export HOST="${METUBE_HOST}"
export PORT="${METUBE_PORT}"
echo "[wrapper] Handing off to metube official entrypoint (HOST=${HOST} PORT=${PORT})..."
exec /app/docker-entrypoint.sh
