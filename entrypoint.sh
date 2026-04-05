#!/bin/sh
set -e

# 环境变量配置
PUBLIC_DOMAIN="${PUBLIC_DOMAIN:-}"
# Caddy 对外监听端口，与 metube 的 PORT 变量区分开
CADDY_PORT="${CADDY_PORT:-8080}"
WEBDAV_PORT="8082"

WEBDAV_USER="${WEBDAV_USER:-admin}"
WEBDAV_PASS="${WEBDAV_PASS:-admin}"
UI_USER="${UI_USER:-admin}"
UI_PASS="${UI_PASS:-admin}"
DOWNLOAD_DIR="${DOWNLOAD_DIR:-/downloads}"

echo "[wrapper] HOST=${HOST}, PORT=${PORT} (metube internal)"
echo "[wrapper] CADDY_PORT=${CADDY_PORT} (public-facing)"

# 生成 Caddy basicauth 密码哈希
echo "[wrapper] Hashing UI password for Caddy basicauth..."
UI_PASS_HASH="$(caddy hash-password --plaintext "${UI_PASS}" | tr -d '\r\n')"

# 哈希为空则直接退出
if [ -z "${UI_PASS_HASH}" ]; then
    echo "[wrapper] ERROR: failed to generate Caddy password hash, aborting."
    exit 1
fi

# 确保下载目录存在
mkdir -p "${DOWNLOAD_DIR}"

# 将实际用户名和哈希写入 Caddyfile
sed -i "s|AUTH_PLACEHOLDER|${UI_USER} ${UI_PASS_HASH}|" /etc/caddy/Caddyfile

# 始终使用端口监听模式
sed -i "s|LISTEN_PLACEHOLDER|:${CADDY_PORT}|" /etc/caddy/Caddyfile

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

# 打印最终 Caddyfile
echo "[wrapper] Rendered Caddyfile:"
cat /etc/caddy/Caddyfile

# 校验 Caddyfile
caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile

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

# 调用 metube 官方入口脚本
# HOST=127.0.0.1, PORT=8081 已通过 Dockerfile ENV 设定
echo "[wrapper] Handing off to metube official entrypoint..."
exec /app/docker-entrypoint.sh
