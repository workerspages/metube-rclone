# metube-rclone

基于 [ghcr.io/alexta69/metube](https://github.com/alexta69/metube) 镜像构建，
集成 [rclone](https://rclone.org/) WebDAV 与 [Caddy](https://caddyserver.com/) 反向代理，
**仅暴露单一端口**，适合 PaaS 平台（Railway、Render、Zeabur 等）一端口限制部署。

## 架构

```
外部请求 → :PORT (Caddy)
               ├─ /dav/*  → 127.0.0.1:8082 (rclone WebDAV)
               └─ /*      → 127.0.0.1:8081 (metube Web UI)
```

所有内部服务仅监听 `127.0.0.1`，对外只有 Caddy 的统一端口可访问。

## 项目结构

```
metube-rclone/
├── Dockerfile           # 镜像构建（metube + rclone + Caddy）
├── Caddyfile            # Caddy 路由配置
├── entrypoint.sh        # 启动脚本
├── docker-compose.yml   # 本地 / 自托管一键部署
└── README.md
```

## 快速部署

### docker compose（本地 / 自托管）

```bash
git clone https://github.com/workerspages/metube-rclone.git
cd metube-rclone
# 按需修改 docker-compose.yml 中的 WEBDAV_USER / WEBDAV_PASS
docker compose up -d
```

### PaaS 平台（Railway / Render / Zeabur 等）

1. 将仓库连接到 PaaS 平台
2. 平台会自动注入 `$PORT` 环境变量，entrypoint.sh 会自动读取
3. 设置以下环境变量：

| 变量 | 说明 |
|------|------|
| `WEBDAV_USER` | WebDAV 认证用户名 |
| `WEBDAV_PASS` | WebDAV 认证密码 |
| `DOWNLOAD_DIR` | 下载目录（默认 `/downloads`）|

## 访问地址

| 功能 | 路径 |
|------|------|
| metube Web UI | `http://<host>:<PORT>/` |
| WebDAV 根目录 | `http://<host>:<PORT>/dav/` |

## 连接 WebDAV 示例

```bash
# rclone
rclone copy :webdav,url=http://localhost:8080/dav/,user=admin,pass=admin: ./local-dir

# macOS Finder / Windows 资源管理器
# 地址栏输入：http://<host>:8080/dav/
```

## 注意事项

- 请务必修改默认的 `WEBDAV_USER` 和 `WEBDAV_PASS`，避免数据泄露。
- PaaS 平台通常不提供持久化存储，建议挂载对象存储或使用平台的持久化磁盘。
- 若平台已提供 HTTPS，Caddy 的 `auto_https off` 可保持不变，TLS 由平台层处理。
