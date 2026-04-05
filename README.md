# metube-rclone

基于 [ghcr.io/alexta69/metube](https://github.com/alexta69/metube) 镜像构建，
集成 [rclone](https://rclone.org/) WebDAV 与 [Caddy](https://caddyserver.com/) 反向代理。

- **单一端口**：适合 PaaS 平台（Railway、Render、Zeabur 等）只开放一个端口的限制
- **自动 HTTPS**：配置域名后，Caddy 自动申请并续签 Let's Encrypt 证书
- **双重认证**：metube Web UI 和 WebDAV 分别有独立的 Basic Auth 保护

## 架构

```
外部请求 → :PORT / HTTPS domain (Caddy)
               ├─ /dav/*  → 127.0.0.1:8082 (rclone WebDAV，rclone 自身认证)
               └─ /*      → 127.0.0.1:8081 (metube Web UI，Caddy basicauth 保护)
```

## 项目结构

```
metube-rclone/
├── Dockerfile           # 镜像构建（metube + rclone + Caddy）
├── Caddyfile            # Caddy 路由 + basicauth + 自动 TLS 配置
├── entrypoint.sh        # 启动脚本（自动哈希密码、动态端口适配）
├── docker-compose.yml   # 本地 / 自托管一键部署
└── README.md
```

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `PUBLIC_DOMAIN` | _(空)_ | PaaS 分配的 HTTPS 域名，如 `myapp.railway.app`。留空则使用 HTTP |
| `PORT` | `8080` | 对外监听端口（PaaS 自动注入 `$PORT`）|
| `UI_USER` | `admin` | metube Web UI 登录用户名 |
| `UI_PASS` | `admin` | metube Web UI 登录密码（**明文**，启动时由 Caddy 自动哈希）|
| `WEBDAV_USER` | `admin` | WebDAV 认证用户名 |
| `WEBDAV_PASS` | `admin` | WebDAV 认证密码 |
| `DOWNLOAD_DIR` | `/downloads` | 下载目录（同时作为 WebDAV 根目录）|

## 快速部署

### docker compose（本地 / 自托管）

```bash
git clone https://github.com/workerspages/metube-rclone.git
cd metube-rclone
# 修改 docker-compose.yml 中的密码
docker compose up -d
```

### PaaS 平台（Railway / Render / Zeabur 等）

1. 将仓库连接到 PaaS 平台，平台自动注入 `$PORT`
2. 在平台控制台设置环境变量：

```
PUBLIC_DOMAIN=myapp.railway.app
UI_USER=yourname
UI_PASS=yourpassword
WEBDAV_USER=yourname
WEBDAV_PASS=yourpassword
```

3. 部署后 Caddy 自动向 Let's Encrypt 申请证书，首次访问稍等片刻即可。

## 访问地址

| 功能 | 地址 |
|------|------|
| metube Web UI | `https://<PUBLIC_DOMAIN>/` |
| WebDAV 根目录 | `https://<PUBLIC_DOMAIN>/dav/` |

## 连接 WebDAV 示例

```bash
# rclone
rclone copy :webdav,url=https://myapp.railway.app/dav/,user=admin,pass=yourpassword: ./local-dir

# macOS Finder / Windows 资源管理器 / Cyberduck
# 地址：https://myapp.railway.app/dav/
```

## 注意事项

- **务必修改所有默认密码**，默认值仅供本地测试。
- Caddy 证书文件存储于 `/data/caddy`，建议挂载持久化存储以避免重启时重复申请证书（Let's Encrypt 有频率限制）。
- 若 PaaS 平台已在前端处理 TLS（如 Cloudflare Tunnel），可将 `PUBLIC_DOMAIN` 留空，Caddy 直接使用 HTTP 模式。
- 下载文件建议挂载持久化磁盘或对象存储，PaaS 容器重启后临时文件系统会清空。
