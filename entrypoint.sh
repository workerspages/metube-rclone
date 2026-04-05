#!/bin/sh
set -e

# ── 环境变量配置 ──────────────────────────────────────────
PUBLIC_DOMAIN="${PUBLIC_DOMAIN:-}"   # PaaS 分配的 HTTPS 域名
PORT="${PORT:-8080}"                 # PaaS 注入的对外端口
METUBE_PORT="8081"                   # metube 内部端口
WEBDAV_PORT="8082"                   # rclone WebDAV 内部端口

WEBDAV_USER="${WEBDAV_USER:-admin}"
WEBDAV_PASS="${WEBDAV_PASS:-admin}"

UI_USER="${UI_USER:-admin}"          # metube Web UI 登录用户名
UI_PASS="${UI_PASS:-admin}"          # metube Web UI 登录密码（明文，启动时自动哈希）

DOWNLOAD_DIR="${DOWNLOAD_DIR:-/downloads}"

# ── 生成 Caddy basicauth 密码哈希 ────────────────────────────
echo "[entrypoint] Hashing UI password for Caddy basicauth..."
UI_PASS_HASH=$(caddy hash-password --plaintext "${UI_PASS}")
export UI_PASS_HASH
export UI_USER

# ── 确保下载目录存在 ───────────────────────────────────
mkdir -p "${DOWNLOAD_DIR}"

# ── 打印启动信息 ──────────────────────────────────────────
echo "[entrypoint] ============================================"
if [ -n "${PUBLIC_DOMAIN}" ]; then
    echo "[entrypoint]  Domain        : ${PUBLIC_DOMAIN} (HTTPS auto)"
    echo "[entrypoint]  metube UI     : https://${PUBLIC_DOMAIN}/"
    echo "[entrypoint]  WebDAV        : https://${PUBLIC_DOMAIN}/dav/"
    export PUBLIC_DOMAIN
else
    echo "[entrypoint]  Domain        : (none, HTTP on port ${PORT})"
    echo "[entrypoint]  metube UI     : http://localhost:${PORT}/"
    echo "[entrypoint]  WebDAV        : http://localhost:${PORT}/dav/"
    sed -i 's|{\$PUBLIC_DOMAIN:":8080"}|:'"${PORT}"'|' /etc/caddy/Caddyfile
fi
echo "[entrypoint]  UI User       : ${UI_USER}"
echo "[entrypoint]  WebDAV User   : ${WEBDAV_USER}"
echo "[entrypoint]  Download dir  : ${DOWNLOAD_DIR}"
echo "[entrypoint] ============================================"

# ── 后台启动 rclone WebDAV ──────────────────────────────────
rclone serve webdav "${DOWNLOAD_DIR}" \
    --addr "127.0.0.1:${WEBDAV_PORT}" \
    --user "${WEBDAV_USER}" \
    --pass "${WEBDAV_PASS}" \
    --vfs-cache-mode full \
    --log-level INFO &
echo "[entrypoint] rclone WebDAV started (PID: $!)"

# ── 后台启动 Caddy ─────────────────────────────────────────
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &
echo "[entrypoint] Caddy started (PID: $!)"

# ── 前台启动 metube ─────────────────────────────────────────
echo "[entrypoint] Starting metube on 127.0.0.1:${METUBE_PORT}..."
export LISTEN_HOST=127.0.0.1
export LISTEN_PORT=${METUBE_PORT}
exec python3 -u /app/ytdl.py
