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

---



# Custom yt-dlp Options
**“Custom yt-dlp Options”（自定义 yt-dlp 选项）** 是 MeTube 中非常强大的一个高级功能。

### 💡 它有什么用？

MeTube 本质上是一个提供图形界面的“套壳”程序，它真正在后台执行下载任务的核心引擎是 **`yt-dlp`**。
因为 `yt-dlp` 拥有成百上千种极其强大的功能（比如内嵌字幕、下载封面、限制网速、使用特定代理等），MeTube 的网页界面不可能把所有功能都做成按钮。

这个输入框的作用就是提供一个**“后门”**，让你能够绕过 MeTube 界面的限制，直接向底层的 `yt-dlp` 引擎发送高级指令，实现那些界面上没有提供的下载需求。

---

### 🛠️ 怎么用？

这个框不能随便输入普通的文字，它**必须严格遵守 JSON 格式**（键值对格式），并且使用的参数名称必须是 `yt-dlp` 的 Python API 参数名（而不是你在命令行里敲的横杠参数，例如不是 `--write-sub`，而是 `"writesubtitles"`）。

**基本语法格式：**
`{"参数名": 参数值}`
如果有多个参数，用逗号隔开：`{"参数名1": 参数值1, "参数名2": 参数值2}`

#### 常见的实用示例（直接复制粘贴到该框中即可）：

1. **下载视频自带字幕**（这也是输入框自带的提示例子）：
   ```json
   {"writesubtitles": true}
   ```

2. **下载 YouTube 自动生成的机翻字幕**：
   ```json
   {"writeautomaticsub": true}
   ```

3. **下载视频封面（缩略图）**：
   ```json
   {"writethumbnail": true}
   ```

4. **限制下载速度**（例如限制为 1MB/s，单位是字节 bytes，1MB = 1048576 bytes）：
   ```json
   {"ratelimit": 1048576}
   ```

5. **为下载设置专属代理**（如果某些视频限制地区，可以单独指定代理）：
   ```json
   {"proxy": "http://127.0.0.1:7890"}
   ```

6. **内嵌元数据**（将视频标题、作者等信息直接写进视频文件的属性里）：
   ```json
   {"postprocessors": [{"key": "FFmpegMetadata"}]}
   ```

7. **组合使用**（同时下载字幕、封面并限制网速）：
   ```json
   {"writesubtitles": true, "writethumbnail": true, "ratelimit": 1048576}
   ```



这里再为你整理一波 **更进阶、更实用的 yt-dlp JSON 参数配置**。

---

### 1. 📝 字幕与信息提取进阶

*   **只下载特定语言的字幕（如中文和英文）**
    如果你开启了下载字幕，但不想把视频自带的几十种语言全下载下来，可以指定语言代码：
    ```json
    {"writesubtitles": true, "subtitleslangs":["zh-Hans", "zh-Hant", "en"]}
    ```
    *(注：`zh-Hans`为简体，`zh-Hant`为繁体，`en`为英语。支持正则表达式，比如写成 `["zh.*", "en"]` 就能匹配所有中文和英文)*

*   **将字幕直接“内嵌”到视频文件中（硬/软字幕）**
    默认情况下下载字幕会生成一个单独的 `.vtt` 或 `.srt` 文件。如果你希望字幕和视频合并成一个文件（方便在各种播放器或电视上播放），可以使用后期处理：
    ```json
    {"writesubtitles": true, "postprocessors": [{"key": "FFmpegEmbedSubtitle"}]}
    ```

*   **下载视频的简介（Description）**
    有时候某些教程视频的简介里有很多有用的链接或时间轴，你可以将其保存为一个单独的 `.description` 文本文件：
    ```json
    {"writedescription": true}
    ```

*   **下载视频的所有评论（保存到 JSON 数据中）**
    如果你有做数据分析的需求，这个选项可以把评论抓取下来（保存在 `.info.json` 文件里）：
    ```json
    {"writeinfojson": true, "getcomments": true}
    ```

---

### 2. 🗂️ 播放列表（Playlist）精确控制

虽然 MeTube 界面上有 `Items Limit`（限制数量），但如果你想更精确地控制：

*   **只下载播放列表中的第 5 集 到 第 10 集**
    ```json
    {"playliststart": 5, "playlistend": 10}
    ```

*   **倒序下载播放列表（从最新一集开始下载）**
    很多播客或连载默认是从最老的一期开始排的，用这个可以反过来：
    ```json
    {"playlistreverse": true}
    ```

---

### 3. 🛡️ 网络防封禁与文件处理

*   **随机延迟下载（防封 IP）**
    如果你在下载一个包含几百个视频的大型播放列表，频繁的请求可能会被 YouTube 暂时封禁 IP。加入随机休眠时间可以模拟人类操作：
    ```json
    {"sleep_interval": 3, "max_sleep_interval": 8}
    ```
    *(意思是在下载每个视频之间，随机暂停 3 到 8 秒)*

*   **强制纯英文/数字安全文件名（去除特殊字符和 Emoji）**
    有时候视频标题里全是各种奇奇怪怪的 Emoji 或者特殊符号，可能导致一些老旧系统的播放器或 NAS 无法读取文件。开启此项会把文件名净化为纯 ASCII 字符：
    ```json
    {"restrictfilenames": true}
    ```

---

### 4. 🚀 黑科技：自动跳过/删除视频内的“恰饭广告” (SponsorBlock)

这是一个非常强大的功能！`yt-dlp` 内置了对 **SponsorBlock**（一个由社区维护的浏览器插件数据库，专门标记视频中 YouTuber 自己插入的口播广告、求订阅片段等）的支持。

*   **在下载时直接把“口播广告”片段剪掉：**
    ```json
    {"postprocessors":[{"key": "SponsorBlock", "categories": ["sponsor", "selfpromo"]}]}
    ```
    *(执行这个操作后，下载下来的视频会自动切除掉 `sponsor`（赞助商广告）和 `selfpromo`（UP主自我推销）的片段。)*

---

### 💡 终极组合技演示

如果你想**“下载一个有几十集的中文教程播放列表的第1-5集，限制文件名不带乱码，合并中英文字幕到视频里，并每下载完一个随机休息几秒防止被封”**，你可以把它们组合成一条完美的配置：

```json
{
  "playliststart": 1,
  "playlistend": 5,
  "restrictfilenames": true,
  "writesubtitles": true,
  "subtitleslangs": ["zh.*", "en"],
  "postprocessors": [{"key": "FFmpegEmbedSubtitle"}],
  "sleep_interval": 2,
  "max_sleep_interval": 5
}
```
*(直接将上面这段完整复制粘贴到 MeTube 的框里，就可以实现如此复杂的自动化下载流程了)*
你可以根据需求，直接将下面的 JSON 代码复制到 **“Custom yt-dlp Options”** 框中（注意：可以把多个参数组合在一个大括号 `{}` 里使用逗号分隔）。
