根据 MeTube 官方 `README.md` 的文档，MeTube 提供了非常丰富的环境变量来进行自定义配置。为了方便你查看，我将它们按照功能类别进行了完整整理翻译：

### ⬇️ 下载行为控制 (Download Behavior)
* **`MAX_CONCURRENT_DOWNLOADS`**: 允许同时进行的最大下载数量。例如设置为 `5`，则最多同时下载5个任务，其余任务排队等待。默认值：`3`。
* **`DELETE_FILE_ON_TRASHCAN`**: 如果设置为 `true`，当你在 Web UI 的“已完成 (Completed)”列表中点击垃圾桶删除记录时，服务器上的实体文件也会被一并删除。默认值：`false`。
* **`DEFAULT_OPTION_PLAYLIST_ITEM_LIMIT`**: 默认允许下载的播放列表最大项目数。默认值：`0`（无限制）。
* **`SUBSCRIPTION_DEFAULT_CHECK_INTERVAL`**: 自动检查订阅更新的默认间隔（分钟）。默认值：`60`。
* **`SUBSCRIPTION_SCAN_PLAYLIST_END`**: 每次检查订阅时获取的最大播放列表/频道条目数（从最新开始算）。默认值：`50`。
* **`SUBSCRIPTION_MAX_SEEN_IDS`**: 每个订阅存储的已见视频 ID 的上限，用于防止状态文件无限增长。默认值：`50000`。
* **`CLEAR_COMPLETED_AFTER`**: 自动从“已完成”列表中移除已完成（和失败）下载记录的等待秒数。默认值：`0`（禁用自动清除）。

### 📁 存储与目录路径 (Storage & Directories)
* **`DOWNLOAD_DIR`**: 视频下载保存路径。Docker 中默认为 `/downloads`，独立运行默认为当前目录 `.`。
* **`AUDIO_DOWNLOAD_DIR`**: 仅音频下载的保存路径（如果你想把纯音频和视频分开放）。默认与 `DOWNLOAD_DIR` 相同。
* **`CUSTOM_DIRS`**: 是否允许将视频下载到 `DOWNLOAD_DIR` 内的自定义子目录中。启用后，UI 中的“Add”按钮旁会出现下拉菜单。默认值：`true`。
* **`CREATE_CUSTOM_DIRS`**: 是否支持自动创建不存在的子目录。启用后，你可以直接在下拉框输入文字，MeTube 会自动创建该目录。默认值：`true`。
* **`CUSTOM_DIRS_EXCLUDE_REGEX`**: 排除某些不希望显示在自定义目录下拉列表中的正则表达式。默认为 `(^|/)[.@].*$`（排除以 `.` 或 `@` 开头的隐藏目录）。
* **`DOWNLOAD_DIRS_INDEXABLE`**: 设置为 `true` 时，允许在 Web 服务器上对下载目录进行索引（文件列表预览）。默认值：`false`。
* **`STATE_DIR`**: MeTube 存放持久化状态文件（如队列、历史、订阅配置等 json 文件）的路径。Docker 中默认为 `/downloads/.metube`。
* **`TEMP_DIR`**: 中间下载文件（缓存/临时文件）的保存路径。Docker 中默认为 `/downloads`。*建议将其映射到 SSD 或内存盘 (`tmpfs`) 以提升性能。*
* **`CHOWN_DIRS`**: 如果设为 `false`，容器启动时不会更改下载及状态目录的权限所属。默认值：`true`。

### 📝 文件命名与 yt-dlp 高级配置 (File Naming & yt-dlp)
* **`OUTPUT_TEMPLATE`**: 下载视频的文件名模板（参考 yt-dlp 规范）。默认值：`%(title)s.%(ext)s`。
* **`OUTPUT_TEMPLATE_CHAPTER`**: 当通过后处理分割章节时使用的模板。默认值：`%(title)s - %(section_number)s %(section_title)s.%(ext)s`。
* **`OUTPUT_TEMPLATE_PLAYLIST`**: 列表下载时的文件名模板。默认值：`%(playlist_title)s/%(title)s.%(ext)s`（留空则退回默认模板）。
* **`OUTPUT_TEMPLATE_CHANNEL`**: 频道下载时的文件名模板。默认值：`%(channel)s/%(title)s.%(ext)s`。
* **`YTDL_OPTIONS`**: 传递给 yt-dlp 的全局附加选项，需使用 JSON 格式字符串输入。
* **`YTDL_OPTIONS_FILE`**: 包含 yt-dlp 全局选项的 JSON 文件路径，修改后会自动重新加载。
* **`YTDL_OPTIONS_PRESETS`**: 定义在 UI 下拉列表中可选的 yt-dlp 预设集合（JSON格式）。
* **`YTDL_OPTIONS_PRESETS_FILE`**: 包含选项预设的 JSON 文件路径（就是你之前用到的那个）。
* **`ALLOW_YTDL_OPTIONS_OVERRIDES`**: 是否在 UI 的高级选项中显示一个输入框，允许用户每次下载时手动覆盖/写入特定选项。默认值：`false`（开启此项有执行任意命令的安全风险，仅限信任环境使用）。

### 🌐 Web 服务器与网络通信 (Web Server & URLs)
* **`HOST`**: Web 服务器绑定的主机地址。默认值：`0.0.0.0`。
* **`PORT`**: Web 服务器监听的端口。默认值：`8081`。
* **`URL_PREFIX`**: Web 服务器的基础路径（反向代理时使用）。默认值：`/`。
* **`PUBLIC_HOST_URL`**: UI 中展示“已完成文件”的下载直链基础 URL。如果通过其他工具（如 Nginx）提供文件访问，可以在这里自定义。
* **`PUBLIC_HOST_AUDIO_URL`**: 针对纯音频下载文件的直链基础 URL。
* **`HTTPS`**: 是否启用 HTTPS 模式（需配合下方证书使用）。默认值：`false`。
* **`CERTFILE`**: HTTPS 证书文件路径。
* **`KEYFILE`**: HTTPS 密钥文件路径。
* **`CORS_ALLOWED_ORIGINS`**: 允许跨域请求 MeTube API 的白名单来源（使用书签工具或浏览器插件时需配置，如 `https://www.youtube.com`）。
* **`ROBOTS_TXT`**: 挂载入容器内的 `robots.txt` 路径，用于控制搜索引擎爬虫。

### 🏠 基础运行环境 (Basic Setup)
* **`PUID`**: 运行 MeTube 的用户 ID。默认值：`1000`。
* **`PGID`**: 运行 MeTube 的用户组 ID。默认值：`1000`。
* **`UMASK`**: MeTube 创建文件的默认 Umask 值。默认值：`022`。
* **`DEFAULT_THEME`**: Web UI 的默认主题，可选 `light`、`dark` 或 `auto`（跟随系统）。默认值：`auto`。
* **`LOGLEVEL`**: 日志输出级别。可选 `DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL`, `NONE`。默认值：`INFO`。
* **`ENABLE_ACCESSLOG`**: 是否启用 Web 访问请求日志。默认值：`false`。

这些变量都可以直接添加到你 `docker-compose.yml` 文件的 `environment:` 列表，或者在 Dockerfile 里用 `ENV` 命令声明。
