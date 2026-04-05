#!/bin/sh
set -e

# 环境变量配置（可通过 docker run -e 传入）
WEBDAV_PORT="${WEBDAV_PORT:-8080}"
WEBDAV_USER="${WEBDAV_USER:-admin}"
WEBDAV_PASS="${WEBDAV_PASS:-admin}"
DOWNLOAD_DIR="${DOWNLOAD_DIR:-/downloads}"

# 确保下载目录存在
mkdir -p "${DOWNLOAD_DIR}"

echo "[entrypoint] Starting rclone WebDAV server..."
echo "[entrypoint]   - Download dir : ${DOWNLOAD_DIR}"
echo "[entrypoint]   - WebDAV port  : ${WEBDAV_PORT}"
echo "[entrypoint]   - WebDAV user  : ${WEBDAV_USER}"

# 后台启动 rclone serve webdav
rclone serve webdav "${DOWNLOAD_DIR}" \
    --addr "0.0.0.0:${WEBDAV_PORT}" \
    --user "${WEBDAV_USER}" \
    --pass "${WEBDAV_PASS}" \
    --vfs-cache-mode full \
    --log-level INFO &

RCLONE_PID=$!
echo "[entrypoint] rclone WebDAV started (PID: ${RCLONE_PID})"

# 启动 metube（官方镜像默认通过 python 启动）
echo "[entrypoint] Starting metube..."
exec python3 -u /app/ytdl.py
