#!/bin/sh
set -e

# ================================================================
# 端口配置说明：
# metube 基础镜像默认 ENV PORT=8081，Zeabur 也可能通过 PORT 注入端口。
# CADDY_PORT 使用专用变量名避开冲突，默认值 8080。
# MeTube 内部端口硬编码 8083，确保与 Caddy/WebDAV 完全隔离。
# ================================================================

# 环境变量配置
PUBLIC_DOMAIN="${PUBLIC_DOMAIN:-}"
# Caddy 对外监听端口：优先使用 CADDY_PORT，否则用 PORT，最后回退到 8080
CADDY_PORT="${CADDY_PORT:-${PORT:-8080}}"
WEBDAV_PORT="8082"

WEBDAV_USER="${WEBDAV_USER:-admin}"
WEBDAV_PASS="${WEBDAV_PASS:-admin}"
UI_USER="${UI_USER:-admin}"
UI_PASS="${UI_PASS:-admin}"
DOWNLOAD_DIR="${DOWNLOAD_DIR:-/downloads}"

# metube 内部端口硬编码为 8083，避免与 Caddy 监听端口冲突
METUBE_HOST="127.0.0.1"
METUBE_PORT="8083"

echo "Initializing directories..."
# 每次容器启动时，检测并创建这些子目录
# 因为你在 Dockerfile 开头写了 USER root，这里是以 root 身份执行，不会报错
mkdir -p /downloads/Twitter
mkdir -p /downloads/经典

# 可选：如果你担心权限问题导致 metube 无法写入，可以顺手赋权
chmod 777 /downloads/Twitter
chmod 777 /downloads/经典

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
# 将 Caddyfile 中 metube 的反向代理地址占位符替换为实际的 MeTube 端口
sed -i "s|METUBE_PROXY_PLACEHOLDER|${METUBE_HOST}:${METUBE_PORT}|" /etc/caddy/Caddyfile

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
    --baseurl /dav \
    --user "${WEBDAV_USER}" \
    --pass "${WEBDAV_PASS}" \
    --vfs-cache-mode full \
    --log-level INFO &
echo "[wrapper] rclone WebDAV started (PID: $!)"

caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &
echo "[wrapper] Caddy started (PID: $!)"

# 通过环境变量强制覆盖 metube 监听地址
export HOST="${METUBE_HOST}"
export PORT="${METUBE_PORT}"
echo "[wrapper] Handing off to metube official entrypoint (HOST=${HOST} PORT=${PORT})..."
exec /app/docker-entrypoint.sh
