# RIFE AI 补帧到 120fps（DirectML 后端，RTX 显卡 DX12 加速，画质优于 mvtools 光流）
# 需 vsort.dll + onnxruntime（vs-mlrt v16）+ RIFE 模型（%APPDATA%\mpv\vs-plugins\models\rife\）
# 注意：ncnn 后端在 mpv 中会崩溃，必须用 ORT_DML（DirectML）
# 2026-08-22 完善：路径改为动态读取 %APPDATA%，不再硬编码用户名，加载失败给明确报错
import os
import vapoursynth as vs

VS_PLUGINS = os.path.join(os.environ.get("APPDATA", ""), "mpv", "vs-plugins")

def _load(name, attr):
    if hasattr(core, attr):
        return
    path = os.path.join(VS_PLUGINS, name)
    if not os.path.exists(path):
        raise RuntimeError("[interp_rife] 插件不存在: " + path)
    core.std.LoadPlugin(path)

core = vs.core
core.max_cache_size = 8192

_load("vsncnn.dll", "ncnn")
_load("vsort.dll", "ort")

import vsmlrt

clip = video_in
fps = container_fps
if fps <= 0 or fps > 120:
    fps = 24.0

# RIFE 输入需要 RGB float（YUV→RGB，BT.709）
clip = core.resize.Bicubic(clip, format=vs.RGBS, matrix_in_s="709")
# RIFE tile 要求 32 倍数尺寸：pad 后处理，再裁回原尺寸
src_w, src_h = clip.width, clip.height
pad_w = (src_w + 31) // 32 * 32
pad_h = (src_h + 31) // 32 * 32
if pad_w != src_w or pad_h != src_h:
    clip = core.std.AddBorders(clip, 0, 0, pad_w - src_w, pad_h - src_h)
# 补到 120fps：multi = 最近整数倍（23.976→5、30→4、60→2，避免非整数倍误差）
multi = max(1, round(120.0 / fps))
out = vsmlrt.RIFE(clip, multi=multi, model=vsmlrt.RIFEModel.v4_6,
                  backend=vsmlrt.Backend.ORT_DML(), ensemble=False)
if pad_w != src_w or pad_h != src_h:
    out = core.std.CropRel(out, 0, 0, out.width - src_w, out.height - src_h)
# mpv 的 vapoursynth 滤镜不支持 float RGB 输出，转回 YUV420P8
out = core.resize.Bicubic(out, format=vs.YUV420P8, matrix_s="709")
out.set_output()
