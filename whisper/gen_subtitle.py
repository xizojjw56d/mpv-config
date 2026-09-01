# -*- coding: utf-8 -*-
# gen_subtitle.py - faster-whisper subtitle generator (zh/en, local + online)
# v6: persistent cache - audio cached after first download, srt cached; URL normalized
import sys, os, subprocess, hashlib
HERE = os.path.dirname(os.path.abspath(__file__))
CACHE = os.path.join(HERE, "cache")

def norm_url(u):
    return u.split("?")[0].split("#")[0]

def url_key(u):
    return hashlib.md5(norm_url(u).encode("utf-8", "ignore")).hexdigest()[:10]

def find_model_dir():
    m = os.path.join(HERE, "faster-whisper-small")
    if os.path.exists(os.path.join(m, "model.bin")):
        return m
    m = os.path.join(os.environ.get("APPDATA", ""), "mpv", "whisper", "faster-whisper-small")
    return m

def find_ytdlp():
    cands = [
        os.path.join(HERE, "..", "..", "yt-dlp.exe"),
        os.path.join(HERE, "..", "yt-dlp.exe"),
        r"C:\Program Files\MPV Player\yt-dlp.exe",
        "yt-dlp.exe",
    ]
    for c in cands:
        if os.path.exists(c): return c
    return None

def fetch_audio(url):
    ytdlp = find_ytdlp()
    if not ytdlp:
        print("yt-dlp not found, cannot download audio")
        return None
    k = url_key(url)
    try: os.makedirs(CACHE, exist_ok=True)
    except Exception: pass
    for ext in ("m4a", "webm", "mp3", "opus"):
        p = os.path.join(CACHE, "ai_" + k + "." + ext)
        if os.path.exists(p) and os.path.getsize(p) > 1000:
            print("audio cache hit: " + p)
            return p
    out = os.path.join(CACHE, "ai_" + k + ".%(ext)s")
    # attempt chain: plain -> firefox cookies -> (cookies + proxy)
    proxy_list = []
    for key in ("HTTPS_PROXY", "https_proxy", "HTTP_PROXY", "http_proxy"):
        v = os.environ.get(key)
        if v and v not in proxy_list:
            proxy_list.append(v)
    for extra in ("http://127.0.0.1:10808", "http://127.0.0.1:10809", "socks5://127.0.0.1:10808"):
        if extra not in proxy_list:
            proxy_list.append(extra)
    attempts = []
    attempts.append([])
    attempts.append(["--cookies-from-browser", "firefox"])
    attempts.append(["--cookies-from-browser", "chrome"])
    attempts.append(["--cookies-from-browser", "edge"])
    for prx in proxy_list[:2]:
        attempts.append(["--cookies-from-browser", "firefox", "--proxy", prx])
    last_err = ""
    for extra in attempts:
        try:
            cmd = [ytdlp, "-f", "bestaudio/best", "-o", out, "--no-playlist"] + extra + [url]
            r = subprocess.run(cmd, capture_output=True, timeout=300)
        except Exception as e:
            last_err = str(e)
            continue
        if r.returncode == 0:
            break
        last_err = (r.stderr or b"").decode("utf-8", "ignore")[:300]
    else:
        print("yt-dlp failed: " + last_err)
        return None
    for ext in ("m4a", "webm", "mp3", "opus"):
        p = os.path.join(CACHE, "ai_" + k + "." + ext)
        if os.path.exists(p): return p
    return None

def main():
    # play video first: run at below-normal priority so playback stays smooth
    try:
        import ctypes
        ctypes.windll.kernel32.SetPriorityClass(
            ctypes.windll.kernel32.GetCurrentProcess(), 0x00004000)
    except Exception:
        pass
    if len(sys.argv) < 2:
        print("Usage: gen_subtitle.py <video|url> [srt_path] [lang]")
        return 1
    src = sys.argv[1]
    is_url = src.startswith("http://") or src.startswith("https://")
    if not is_url and not os.path.exists(src):
        print("file not found: " + src)
        return 1
    srt_out = sys.argv[2] if len(sys.argv) > 2 else None
    if not srt_out:
        if is_url:
            try: os.makedirs(CACHE, exist_ok=True)
            except Exception: pass
            srt_out = os.path.join(CACHE, "ai_" + url_key(src) + ".srt")
        else:
            srt_out = os.path.splitext(src)[0] + ".srt"
    lang = sys.argv[3] if len(sys.argv) > 3 else "zh"
    if lang not in ("zh", "en"):
        print("unsupported lang: " + lang)
        return 1
    # srt cache hit: nothing to do
    if os.path.exists(srt_out) and os.path.getsize(srt_out) > 0:
        print("srt cache hit: " + srt_out)
        return 0
    model_dir = find_model_dir()
    if not os.path.exists(os.path.join(model_dir, "model.bin")):
        print("model not found: " + model_dir)
        return 1
    audio = None
    if is_url:
        audio = fetch_audio(src)
        if not audio:
            print("audio download failed")
            return 1
        src = audio
    from faster_whisper import WhisperModel
    n_cores = max(1, min(4, (os.cpu_count() or 4) // 2))
    model = WhisperModel(model_dir, device="cpu", compute_type="int8", cpu_threads=n_cores)
    import time
    time.sleep(0.001)
    prompt = {
        "zh": "以下是普通话的句子。",
        "en": "The following is a transcript in English.",
    }.get(lang, "")
    # vad_filter 过滤静音/音乐段，避免幻觉复读提示词；
    # condition_on_previous_text=False 防止错误滚动累积；
    # no_speech_threshold 过滤无人声段。
    segments, info = model.transcribe(
        src, language=lang, vad_filter=True,
        vad_parameters={"min_silence_duration_ms": 500},
        condition_on_previous_text=False,
        no_speech_threshold=0.6,
        initial_prompt=prompt or None,
    )
    try: os.makedirs(os.path.dirname(srt_out), exist_ok=True)
    except Exception: pass
    n = 0
    with open(srt_out, "w", encoding="utf-8") as f:
        idx = 1
        for seg in segments:
            start = seg.start
            end = seg.end
            text = (seg.text or "").strip()
            # 过滤提示词回声与空段（无语音概率过高的段已由阈值处理，这里兜底）
            if not text: continue
            if prompt and text.replace(" ", "").replace("，", "").replace("。", "") == prompt.replace(" ", "").replace("，", "").replace("。", ""): continue
            f.write(str(idx) + "\r\n")
            f.write(fmt_ts(start) + " --> " + fmt_ts(end) + "\r\n")
            f.write(text + "\r\n\r\n")
            idx += 1
            n += 1
    if n == 0:
        print("no speech detected: " + srt_out)
    else:
        print("OK: " + srt_out)
    return 0

def fmt_ts(t):
    h = int(t // 3600)
    m = int(t % 3600 // 60)
    s = int(t % 60)
    ms = int((t - int(t)) * 1000)
    return "%02d:%02d:%02d,%03d" % (h, m, s, ms)

if __name__ == "__main__":
    sys.exit(main())