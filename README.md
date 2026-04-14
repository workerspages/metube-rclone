# metube-rclone

基于 [ghcr.io/alexta69/metube](https://github.com/alexta69/metube) 镜像构建，
集成 [rclone](https://rclone.org/) WebDAV 与 [Caddy](https://caddyserver.com/) 反向代理。

- **单一端口**：适合 PaaS 平台（Railway、Render、Zeabur 等）只开放一个端口的限制
- **自动 HTTPS**：Zeabur 外层已处理 TLS，Caddy 负责认证与路由
- **双重认证**：metube Web UI 和 WebDAV 分别有独立的 Basic Auth 保护

## 架构

```
外部请求 → :PORT (Caddy 对外监听)
               ├─ /dav/*  → 127.0.0.1:8082 (rclone WebDAV，rclone 自身认证)
               └─ /*      → 127.0.0.1:8083 (metube Web UI，Caddy basicauth 保护)
```

## 项目结构

```
metube-rclone/
├── Dockerfile           # 镜像构建（metube + rclone + Caddy）
├── Caddyfile            # Caddy 路由 + basicauth 配置
├── entrypoint.sh        # 启动脚本（自动哈希密码、动态端口适配）
├── docker-compose.yml   # 本地 / 自托管一键部署
└── README.md
```

## 环境变量

| 变量 | 默认値 | 说明 |
|------|--------|------|
| `PUBLIC_DOMAIN` | _(空)_ | PaaS 分配的域名，如 `myapp.zeabur.app`。仅用于日志显示，不影响 Caddy 监听方式 |
| `PORT` | `8080` | **由 PaaS 平台自动注入**，即 Caddy 对外监听端口。无需手动设置 |
| `UI_USER` | `admin` | metube Web UI 登录用户名 |
| `UI_PASS` | `admin` | metube Web UI 登录密码（**明文**，启动时由 Caddy 自动哈希）|
| `WEBDAV_USER` | `admin` | WebDAV 认证用户名 |
| `WEBDAV_PASS` | `admin` | WebDAV 认证密码 |
| `DOWNLOAD_DIR` | `/downloads` | 下载目录（同时作为 WebDAV 根目录）|

> **注意**：`PORT` 变量由 PaaS 平台自动提供，metube 内部端口硬编码为 `127.0.0.1:8083`，与 Caddy 监听端口自动隔离，无需额外配置。

 [MeTube 官方变量](/metube-environment.md) 
## 快速部署

### docker compose（本地 / 自托管）

```bash
git clone https://github.com/workerspages/metube-rclone.git
cd metube-rclone
# 修改 docker-compose.yml 中的密码
docker compose up -d
```

### Zeabur 部署

1. 将仓库连接到 Zeabur，平台会自动构建镜像并注入 `PORT`
2. 在平台控制台设置以下环境变量（**不要**手动设置 `PORT`）：

```
PUBLIC_DOMAIN=metube-rclone.zeabur.app
UI_USER=yourname
UI_PASS=yourpassword
WEBDAV_USER=yourname
WEBDAV_PASS=yourpassword
DOWNLOAD_DIR=/downloads
OUTPUT_TEMPLATE=%(title).100B.%(ext)s
OUTPUT_TEMPLATE_CHAPTER=%(title)s - %(section_number)s %(section_title)s.%(ext)s
```

3. 部署后访问 `https://metube-rclone.zeabur.app/`，浏览器会弹出 Basic Auth 登录框。

### Uptime Kuma 监听 URL
1. Uptime Kuma 监听 URL `https://metube-rclone.xxxx.com/health`

### 其他 PaaS 平台（Railway / Render 等）

1. 将仓库连接到平台，平台自动注入 `$PORT`
2. 在控制台设置环境变量（同上）
3. 如需自定义域名，设置 `PUBLIC_DOMAIN` 为平台分配的域名

## 访问地址

| 功能 | 地址 |
|------|------|
| metube Web UI | `https://<PUBLIC_DOMAIN>/` |
| WebDAV 根目录 | `https://<PUBLIC_DOMAIN>/dav/` |

## 连接 WebDAV 示例

```bash
# rclone
rclone copy :webdav,url=https://metube-rclone.zeabur.app/dav/,user=yourname,pass=yourpassword: ./local-dir

# macOS Finder / Windows 资源管理器 / Cyberduck
# 地址：https://myapp.zeabur.app/dav/
```

## 注意事项

- **务必修改所有默认密码**，默认値仅供本地测试。
- Caddy 证书文件存储于 `/data/caddy`，建议挂载持久化存储以避免重启时重复申请证书。
- Zeabur 外层已处理 TLS，Caddy 内部使用 HTTP 模式并禁用了自动 HTTPS。
- 下载文件建议挂载持久化磁盘，PaaS 容器重启后临时文件系统会清空。
- **不要**在 Zeabur 环境变量中手动设置 `PORT`，平台自动注入的值就是正确的对外端口。
