# 144fps 高帧档（高刷屏用，pel=2）
import os
import vapoursynth as vs
core = vs.core

if not hasattr(core, 'mv'):
    core.std.LoadPlugin(os.path.join(os.environ.get("APPDATA", ""), "mpv", "vs-plugins", "libmvtools.dll"))

clip = video_in
fps = container_fps
if fps <= 0 or fps > 120:
    fps = 24.0
clip = core.std.AssumeFPS(clip, fpsnum=round(fps * 1001), fpsden=1001)

super = core.mv.Super(clip, pel=2, hpad=16, vpad=16)
backward = core.mv.Analyse(super, isb=True, delta=1, overlap=4)
forward = core.mv.Analyse(super, isb=False, delta=1, overlap=4)
backward = core.mv.Recalculate(super, backward, overlap=4)
forward = core.mv.Recalculate(super, forward, overlap=4)
out = core.mv.FlowFPS(clip, super, backward, forward, num=144, den=1)
out.set_output()