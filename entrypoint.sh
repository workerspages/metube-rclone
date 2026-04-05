#!/bin/sh
set -e

# ── 环境变量配置（可通过 -e 传入覆盖） ────────────────────
PUBLIC_PORT="${PORT:-8080}"          # PaaS 平台注入的对外端口
METUBE_PORT="8081"                   # metube 内部端口（固定，不对外暴露）
WEBDAV_PORT="8082"                   # rclone WebDAV 内部端口（固定，不对外暴露）
WEBDAV_USER="${WEBDAV_USER:-admin}"
WEBDAV_PASS="${WEBDAV_PASS:-admin}"
DOWNLOAD_DIR="${DOWNLOAD_DIR:-/downloads}"

# ── 替换 Caddyfile 中的监听端口（适配 PaaS 动态端口） ─────────
sed -i "s/:8080/:${PUBLIC_PORT}/" /etc/caddy/Caddyfile

# ── 确保下载目录存在 ─────────────────────────────────
mkdir -p "${DOWNLOAD_DIR}"

echo "[entrypoint] ============================================"
echo "[entrypoint]  Public  port  : ${PUBLIC_PORT}  (Caddy)"
echo "[entrypoint]  metube  port  : ${METUBE_PORT}  (internal)"
echo "[entrypoint]  WebDAV  port  : ${WEBDAV_PORT}  (internal)"
echo "[entrypoint]  Download dir  : ${DOWNLOAD_DIR}"
echo "[entrypoint]  WebDAV path   : http://<host>:${PUBLIC_PORT}/dav/"
echo "[entrypoint] ============================================"

# ── 后台启动 rclone WebDAV ────────────────────────────────
rclone serve webdav "${DOWNLOAD_DIR}" \
    --addr "127.0.0.1:${WEBDAV_PORT}" \
    --user "${WEBDAV_USER}" \
    --pass "${WEBDAV_PASS}" \
    --vfs-cache-mode full \
    --log-level INFO &
echo "[entrypoint] rclone WebDAV started (PID: $!)"

# ── 后台启动 Caddy ──────────────────────────────────────
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &
echo "[entrypoint] Caddy started (PID: $!)"

# ── 前台启动 metube（绑定内部端口） ──────────────────────
echo "[entrypoint] Starting metube on 127.0.0.1:${METUBE_PORT}..."
export LISTEN_HOST=127.0.0.1
export LISTEN_PORT=${METUBE_PORT}
exec python3 -u /app/ytdl.py
