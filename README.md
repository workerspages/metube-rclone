# metube-rclone

基于 [ghcr.io/alexta69/metube](https://github.com/alexta69/metube) 镜像构建，
集成 [rclone](https://rclone.org/) WebDAV 服务器，
方便通过任意支持 WebDAV 的客户端（如 Cyberduck、Rclone、Alist 等）访问 metube 的下载目录。

## 项目结构

```
metube-rclone/
├── Dockerfile           # 镜像构建文件
├── entrypoint.sh        # 启动脚本（同时运行 metube 和 rclone WebDAV）
├── docker-compose.yml   # Compose 一键部署
└── README.md
```

## 快速部署

### 方式一：docker compose（推荐）

```bash
# 1. 克隆项目
git clone https://github.com/workerspages/metube-rclone.git
cd metube-rclone

# 2. 修改 docker-compose.yml 中的 WEBDAV_USER / WEBDAV_PASS

# 3. 启动
docker compose up -d
```

### 方式二：docker run

```bash
docker build -t metube-rclone .

docker run -d \
  --name metube-rclone \
  -p 8081:8081 \
  -p 8080:8080 \
  -v $(pwd)/downloads:/downloads \
  -e WEBDAV_USER=admin \
  -e WEBDAV_PASS=yourpassword \
  metube-rclone
```

## 端口说明

| 端口 | 服务 | 说明 |
|------|------|------|
| 8081 | metube Web UI | 视频下载界面 |
| 8080 | rclone WebDAV | 访问下载目录 |

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `DOWNLOAD_DIR` | `/downloads` | metube 下载目录（同时作为 WebDAV 根目录）|
| `WEBDAV_PORT` | `8080` | WebDAV 监听端口 |
| `WEBDAV_USER` | `admin` | WebDAV 认证用户名 |
| `WEBDAV_PASS` | `admin` | WebDAV 认证密码 |

## 连接 WebDAV

WebDAV 服务地址格式：

```
http://<host>:8080/
```

示例（使用 rclone 挂载）：

```bash
rclone copy :webdav,url=http://localhost:8080,user=admin,pass=admin: ./local-dir
```

## 注意事项

- 部署在 PaaS 平台时，确保 **8081** 和 **8080** 端口均已对外开放。
- 建议修改默认的 `WEBDAV_USER` 和 `WEBDAV_PASS` 以保障安全。
- 下载目录 `/downloads` 建议挂载持久化存储，防止容器重启后文件丢失。
