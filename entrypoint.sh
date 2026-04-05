#!/bin/sh
set -e

# ── 环境变量配置 ──────────────────────────────────────────
PUBLIC_DOMAIN="${PUBLIC_DOMAIN:-}"
PORT="${PORT:-8080}"
METUBE_PORT="8081"
WEBDAV_PORT="8082"

WEBDAV_USER="${WEBDAV_USER:-admin}"
WEBDAV_PASS="${WEBDAV_PASS:-admin}"
UI_USER="${UI_USER:-admin}"
UI_PASS="${UI_PASS:-admin}"
DOWNLOAD_DIR="${DOWNLOAD_DIR:-/downloads}"

# ── 生成 Caddy basicauth 密码哈希 ────────────────────────────
echo "[wrapper] Hashing UI password for Caddy basicauth..."
UI_PASS_HASH=$(caddy hash-password --plaintext "${UI_PASS}")
export UI_PASS_HASH
export UI_USER

# ── 确保下载目录存在 ───────────────────────────────────
mkdir -p "${DOWNLOAD_DIR}"

# ── 打印启动信息 ──────────────────────────────────────────
echo "[wrapper] ============================================"
if [ -n "${PUBLIC_DOMAIN}" ]; then
    echo "[wrapper]  Domain    : ${PUBLIC_DOMAIN} (HTTPS auto)"
    echo "[wrapper]  UI        : https://${PUBLIC_DOMAIN}/"
    echo "[wrapper]  WebDAV    : https://${PUBLIC_DOMAIN}/dav/"
    export PUBLIC_DOMAIN
else
    echo "[wrapper]  Domain    : (none, HTTP on :${PORT})"
    echo "[wrapper]  UI        : http://localhost:${PORT}/"
    echo "[wrapper]  WebDAV    : http://localhost:${PORT}/dav/"
    sed -i "s|{\\$PUBLIC_DOMAIN:\\":8080\"}|:${PORT}|" /etc/caddy/Caddyfile
fi
echo "[wrapper]  UI User   : ${UI_USER}"
echo "[wrapper]  DAV User  : ${WEBDAV_USER}"
echo "[wrapper]  DL Dir    : ${DOWNLOAD_DIR}"
echo "[wrapper] ============================================"

# ── 后台启动 rclone WebDAV ──────────────────────────────────
rclone serve webdav "${DOWNLOAD_DIR}" \
    --addr "127.0.0.1:${WEBDAV_PORT}" \
    --user "${WEBDAV_USER}" \
    --pass "${WEBDAV_PASS}" \
    --vfs-cache-mode full \
    --log-level INFO &
echo "[wrapper] rclone WebDAV started (PID: $!)"

# ── 后台启动 Caddy ─────────────────────────────────────────
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &
echo "[wrapper] Caddy started (PID: $!)"

# ── 交由官方 docker-entrypoint.sh 启动 metube（保留原始 tini 进程树）──
echo "[wrapper] Handing off to metube official entrypoint..."
export LISTEN_HOST=127.0.0.1
export LISTEN_PORT=${METUBE_PORT}
exec /sbin/tini -g -- /app/docker-entrypoint.sh
