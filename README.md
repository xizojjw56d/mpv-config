# MPV Player 配置

基于 [emoeem/mpv](https://github.com/emoeem/mpv) 深度定制，适配 **Windows 10** + **RTX 4060 Laptop** + **2K 280Hz 显示器**。

## 目录

- [快速开始](#快速开始)
- [功能概览](#功能概览)
- [快捷键速查](#快捷键速查)
- [画质模式](#画质模式)
- [字幕系统](#字幕系统)
- [剧集连播](#剧集连播)
- [直播平台](#直播平台)
- [硬解与渲染](#硬解与渲染)
- [4K 插帧](#4k-插帧)
- [菜单结构](#菜单结构)
- [依赖安装](#依赖安装)
- [常见问题](#常见问题)

## 快速开始

### 安装

```bash
git clone https://github.com/xizojjw56d/mpv-config.git ~/AppData/Roaming/mpv
```

### 配置自己的 Firefox 账号

如果你有 B站大会员或需要登录各平台，修改 `mpv.conf` 中的 Firefox 路径：

```bash
# 在 mpv.conf 中搜索 YOUR_PROFILE，替换成你的 Firefox 实际配置文件名
# 默认位置: C:/Users/你的用户名/AppData/Roaming/Mozilla/Firefox/Profiles/xxxx.default-release
```

### 启动

```bash
mpv.exe --force-window=yes
```

或双击 `MPV-Play.bat`（在 mpv 安装目录下，放剪贴板 URL 后双击）。

---

## 功能概览

| 功能 | 说明 | 快捷键 |
|------|------|--------|
| **AI 字幕** | 利用 faster-whisper 本地生成中/英文字幕 | `Alt+F` / `Alt+G` |
| **剧集连播** | B站/本地剧集自动展开整季，播完自动下一集 | `F6` 选集 |
| **画质模式** | 6 种一键切换的着色器链路 | `Ctrl+Alt+F7~F12` |
| **虎牙直播** | FLV 中继 + 多 CDN 故障转移 + 限流退避 | 双击 MPV-Play |
| **弹幕** | B站/爱奇艺/优酷/腾讯/芒果弹幕 | `Ctrl+D` 开关 |
| **4K 插帧** | sphinx 时域插帧，4K 下 GPU 零开销 | 自动触发 |
| **280Hz 适配** | 插帧自动匹配显示器刷新率 | 自动 |
| **片头跳过** | 自动识别并跳过片头片尾 | `Ctrl+Alt+B` |
| **命令面板** | 搜索执行任意命令 | `Ctrl+P` |

---

## 快捷键速查

### 播放控制

| 按键 | 功能 |
|------|------|
| `空格` | 暂停/播放 |
| `双击` | 全屏切换 |
| `ESC` | 退出全屏 |
| `F4` | 综合菜单 |
| `F6` | **选集菜单**（电视剧/番剧/系列） |

### 字幕

| 按键 | 功能 |
|------|------|
| `Alt+F` / `Ctrl+F` | AI 生成**中文**字幕 |
| `Alt+G` / `Ctrl+G` | AI 生成**英文**字幕 |
| `Ctrl+Shift+F` | 从 assrt.net 下载字幕 |
| `Ctrl+M` | 字幕内容菜单（点击跳转） |
| `Alt+M` | 导出内封字幕 |
| `Ctrl+Alt+M` | 字幕同步 |
| `Y` | 音轨列表 |
| `J` | 切换字幕轨 |
| `V` | 字幕可见性 |
| `K` | 次字幕 |

### 画质

| 按键 | 模式 | 适合场景 |
|------|------|----------|
| `Ctrl+Alt+F7` | **真人最优** | 电视剧/电影/真人秀 |
| `Ctrl+Alt+F8` | **动画最优** | 番剧/动画 |
| `Ctrl+Alt+F9` | **直播优化** | 低码率直播 |
| `Ctrl+Alt+F10` | **4K降采样** | 4K片源在2K屏 |
| `Ctrl+Alt+F11` | **电影全链路** | 本地高码率电影 |
| `Ctrl+Alt+F12` | **默认** | 恢复默认 |

### 硬解

| 按键 | 功能 |
|------|------|
| `Ctrl+Shift+H` | 循环切换硬解模式 |
| `Ctrl+Shift+Q` | 关闭补帧 |

硬解循环顺序：`auto-safe → d3d11va-copy → nvdec-copy → vulkan-copy → vulkan → 软解`

### 直播

| 按键 | 功能 |
|------|------|
| `Ctrl+D` | 弹幕开关 |
| `Ctrl+D`（大写） | 弹幕综合菜单 |
| `Ctrl+Alt+B` | 自动跳过片头片尾 |
| `F3` | 跳到静音位置 |
| `DEL` | 删除当前文件 |

### 工具

| 按键 | 功能 |
|------|------|
| `Ctrl+P` | **命令面板** |
| `Ctrl+Alt+I` | 播放信息面板 |
| `Ctrl+Alt+Shift+S` | 截图到剪贴板 |
| `Ctrl+Alt+Shift+T` | 复制时间戳 |
| `Ctrl+O` | 原生文件对话框 |
| `Ctrl+Alt+P` | 画中画 |
| `Ctrl+Alt+R` | 重新加载文件 |
| `M` | 检查更新脚本和着色器 |
| `` ` `` | 历史记录 |
| `N` | 书签菜单 |
| `Ctrl+Alt+H` | 最近播放 |
| `~` | 控制台 |

### 画面

| 按键 | 功能 |
|------|------|
| `Alt+I` | 内置补帧开关 |
| `D` | 去色带开关 |
| `Alt+Z/X` | 去色带强度 +/- |
| `A` | 循环宽高比 |
| `Ctrl+I` | ICC 校色开关 |
| `1-8` | 对比度/明度/伽马/饱和度 |
| `S` | 截图（无字幕） |
| `s` | 截图（带字幕） |

### 编码/画质（B站在线视频）

| 按键 | 功能 |
|------|------|
| `Ctrl+F1` | 编码 AV1 |
| `Ctrl+F2` | 编码 AVC(H.264) |
| `Ctrl+F3` | 编码 HEVC |
| `Ctrl+F4` | 编码 默认 |
| `Ctrl+F5` | 画质 4K |
| `Ctrl+F6` | 画质 2K |
| `Ctrl+F7` | 画质 1080P |
| `Ctrl+F8` | 画质 720P |
| `Ctrl+F9` | 画质 自动最高 |
| `Ctrl+F10` | 画质 8K |

---

## 画质模式

6 种一键切换的全链路着色器方案，**右键菜单 → 画质模式** 或快捷键：

### 真人最优（Ctrl+Alt+F7）
```
KrigBilateral.glsl         ← 色度升采样（色彩瞬间清晰）
FSRCNNX_x2_8-0-4-1.glsl    ← 神经网络放大（比内置缩放更锐）
SSimSuperRes.glsl           ← 自适应锐化（按结构相似性智能处理）
```
→ **看电视剧、电影、真人秀首选**

### 动画最优（Ctrl+Alt+F8）
```
Anime4K_Clamp_Highlights    ← 高光保护
Anime4K_Restore_CNN_VL     ← 最强修复（修复线条+压缩伪影）
Anime4K_Upscale_CNN_x2_VL  ← 神经网络放大
Anime4K_AutoDownscalePre   ← 预处理降采样
KrigBilateral               ← 色度升采样
```
→ **看番剧、动画首选，1080p→2K 观感接近原生 4K**

### 直播优化（Ctrl+Alt+F9）
```
KrigBilateral + adaptive-sharpen + 强化去色带
```
→ **低码率直播最佳方案**

### 4K降采样（Ctrl+Alt+F10）
```
SSimDownscaler + KrigBilateral
```
→ **4K片源在2K屏上播放最优**

### 电影全链路（Ctrl+Alt+F11）
```
KrigBilateral + FSRCNNX + SSimSuperRes + adaptive-sharpen + SSimDownscaler
```
→ **本地高码率电影，五着色器全开**

### 默认（Ctrl+Alt+F12）
清除全部着色器，回到 mpv 内置画质。

---

## 字幕系统

### AI 字幕（faster-whisper）

本地 AI 语音识别生成字幕，支持**中文和英文**，**纯音频文件也能生成**。

| 按键 | 语言 | 适用场景 |
|------|------|----------|
| `Alt+F` / `Ctrl+F` | 中文 | 视频/音频生成中文字幕 |
| `Alt+G` / `Ctrl+G` | 英文 | 视频/音频生成英文字幕 |

**首次使用**：第一次生成较慢（加载模型约 20 秒），之后音频会缓存，秒出。

**纯音频**：mp3、flac、m4a、wav 等格式也能生成字幕（播放时按 `Alt+F`）。

**依赖**：需要 `faster-whisper` Python 包和 `faster-whisper-small` 模型。

### 字幕下载

`Ctrl+Shift+F` → 从 assrt.net 搜索下载字幕（需注册 API token）。

### 字幕内容菜单

`Ctrl+M` → 显示当前字幕列表，点击可跳转到对应时间点。

### 字幕同步

`Ctrl+Alt+M` → 自动同步字幕时间轴。

---

## 剧集连播

### B站剧集/番剧

1. 复制**任意一集**的 URL
2. 双击 `MPV-Play.bat`
3. 启动后自动拉取整季列表，自动展开连播
4. 按 `F6` 打开选集菜单，自由跳转

### 本地剧集

1. 将剧集命名为 `剧名 第01集.mp4`、`剧名 第02集.mp4` 等格式
2. 打开第 1 集→自动加载同目录其余集
3. 播完自动下一集

### 选集菜单

按 `F6`（或右键菜单 → 导航 → 选集菜单）：
- **B站剧集** → 弹出整季选集列表，支持搜索
- **本地文件** → 打开播放列表

---

## 直播平台

### 虎牙直播

使用 `MPV-Play.bat` 或 `mpv-huya.bat`：

```bash
mpv-huya.bat "https://www.huya.com/房间号" --danmu
```

**架构**：v8.2 FLV 中继 + 多 CDN 故障转移
- 自动解析房间页，获取全部 CDN 线路（HS/AL/TX）
- 优先选 HS 线（华省，最稳定）
- 单线失败自动换线
- 令牌自动续签，断流自愈
- 防反爬：指数退避，不重试延长冷却

**限流说明**：短时间对同一房间多次解析会触发虎牙反爬，冷却 15-30 分钟后自动恢复。

### B站直播

支持弹幕 + 大会员 cookie 解锁高码率。

### YouTube

需要 v2rayN 代理（`http://127.0.0.1:10808`），cookie 来自 Firefox 登录。

---

## 硬解与渲染

### 硬件

- **GPU**: NVIDIA RTX 4060 Laptop (8GB VRAM)
- **显示器**: 2560x1440 @ 280Hz
- **操作系统**: Windows 10

### 默认配置

```
vo=gpu-next
gpu-api=d3d11
hwdec=auto-safe
```

### 硬解循环

```
Ctrl+Shift+H → auto-safe → d3d11va-copy → nvdec-copy → vulkan-copy → vulkan → 软解
```

### GPU API 切换

右键菜单 → 解码 → GPU 渲染 API → D3D11 / Vulkan（需重启生效）

---

## 4K 插帧

系统自动按分辨率选择最优插帧方案：

| 分辨率 | 插帧引擎 | 性能 | 画质 |
|--------|----------|------|------|
| 4K (≥2160p) | `tscale=sphinx`（GPU） | ★★★★★ 零开销 | ★★★★（4K 下肉眼无差别） |
| 1080p 及以下 | VapourSynth mvtools（CPU） | ★★★ | ★★★★★ 运动向量精确 |

**4K 内容自动触发 [超高清] profile**：
- 插帧引擎切换为 GPU tscale=sphinx（不占 CPU）
- 自动清 VapourSynth（CPU 扛不住 4K）
- 自动降低着色器负载给插帧腾 GPU 余量
- 插帧到 280Hz（自动匹配显示器刷新率）

---

## 菜单结构

右键菜单 → 16 个一级菜单，179 项功能：

```
文件(19) → 停止/置顶/全屏/循环/速度/删除文件/随机播放
画面(28) → 宽高比/旋转/缩放/ICC/调色/去色带
HDR(6)   → 映射曲线/动态映射/直通/TRC/峰值/色域
视频(9)  → 补帧开关/去交错/截图/逐帧
补帧(6)  → 60fps/120fps/144fps/RIFE AI/关闭
导航(16) → OSD/列表/精准跳转/静音跳过/章节制作
音频(12) → 音轨/静音/延迟/声道/独占/响度均衡
字幕(21) → 切轨/AI字幕/下载/内容菜单/导出/同步/智能选择
着色器(5)→ CAS/Anime4K/FSRCNNX/SSim
滤镜(8)  → 翻转/旋转/伽马/帧率/填充/色温
配置组(7)→ 性能/电影/动画/Anime4K/默认/高码率
解码(9)  → 硬解循环/vulkan-copy/vulkan/软解/GPU API
编码(4)  → AV1/AVC/HEVC/默认（B站）
画质(6)  → 4K/2K/1080P/720P/自动/8K（在线视频）
打开(8)  → 原生对话框/历史/书签/近期播放
工具(12) → 画中画/控制台/弹幕/标题栏/复制/截图/命令面板/更新器
画质模式(6) → 真人最优/动画最优/直播优化/4K降采样/电影全链路/默认
```

---

## 依赖安装

### Python 3.13 + faster-whisper

```bash
# 安装 Python 3.13（如果未安装）
# 下载地址: https://www.python.org/downloads/

# 安装 faster-whisper
pip install faster-whisper

# 下载模型（约 500MB）
# 放到 whisper/faster-whisper-small/ 目录下
```

### VapourSynth（补帧用）

```bash
# VapourSynth + vs-plugins 已包含在便携版中
# 补帧脚本在 vs/ 目录下
```

### 其他工具

- **yt-dlp**: 已包含在便携版中
- **ffmpeg/ffprobe**: 已包含在便携版中
- **v2rayN**: YouTube 直播需要（可选）

### DLSSNR（NVIDIA NGX 画质增强，RTX 专用）

基于 [Magpie experimental](https://github.com/SAOG0721/Magpie) 移植的 VapourSynth 插件，源自 [Rygtx/mpv_PlayKit](https://github.com/Rygtx/mpv_PlayKit)（dlssnr 分支）。

```bash
# 需要自行构建 DLL：
# 1. 安装 Visual Studio 2022 Community（勾选"C++ 桌面开发"）
# 2. git clone -b dlssnr https://github.com/Rygtx/mpv_PlayKit.git
# 3. cd mpv_PlayKit/native/scripts
# 4. powershell -File fetch-deps.ps1   # 下载 NGX SDK + VapourSynth 头文件
# 5. powershell -File build.ps1        # 编译 vs_dlssnr.dll
# 6. 复制文件到本配置目录：
#    native/bin/vs_dlssnr.dll          → %APPDATA%\mpv\vs-plugins\
#    native/bin/dlssnr_panel.exe       → %APPDATA%\mpv\vs-plugins\（可选，控制面板）
#    native/bin/ngx/nvngx_dlssnr.dll   → %APPDATA%\mpv\vs-plugins\ngx\
# 7. 重启 mpv，按 Ctrl+Alt+n 开关 DLSSNR

# 注意：RTX 40/50 系走官方 NGX 签名链，不需要 RTX 20/30 系的代理组件
```

### RTX Video Super Resolution（直播优化内置）

使用 NVIDIA RTX Video SDK 的低码率超分，已内置在"直播优化"画质模式中：
- 需要 `hwdec=d3d11va`（直播优化 profile 已自动设置）
- 需要 RTX 20 系+ 与 r550.58+ 驱动
- 如果硬解被切到其他模式，`rtx-vsr-guard.lua` 会在 OSD 提示

### 着色器致谢

| 着色器 | 来源 |
|--------|------|
| ArtCNN_C4F16 | [Artoriuz/ArtCNN](https://github.com/Artoriuz/ArtCNN) |
| CfL_Prediction | [AdrianEddy/tech](https://github.com/AdrianEddy/tech)（cfl 分支） |
| SSimSuperRes / SSimDownscaler / adaptive-sharpen | [igv/FSRCNN_x](https://github.com/igv/FSRCNN_x) |
| Anime4K 全系列 | [bloc97/Anime4K](https://github.com/bloc97/Anime4K) |

---

## 常见问题

### Q: 虎牙打不开/卡顿？

A: ① 检查代理端口 8899 是否被占用；② 虎牙限流时冷却 15-30 分钟自动恢复；③ 运行 `huya-diagnostic` 技能一键诊断。

### Q: AI 字幕不生效？

A: 确认 Python 3.13 已安装、`faster-whisper` 包已安装、模型文件已下载。按 `Alt+F` 后 OSD 会显示进度。

### Q: 4K 插帧卡顿？

A: 系统已自动在 4K 时切换为 GPU tscale 插帧（不占 CPU），如果仍卡顿，检查是否打开过多着色器。

### Q: 菜单点不动？

A: 杀掉多余 mpv 进程（任务管理器 → 结束所有 mpv.exe），重新打开。如果有多开 mpv 实例会互相干扰。

### Q: 如何更新脚本和着色器？

A: 按 `M` 键，manager 会自动检查配置的第三方来源更新。

---

## 许可证

基于 [emoeem/mpv](https://github.com/emoeem/mpv) 修改，遵循 MIT 许可证。