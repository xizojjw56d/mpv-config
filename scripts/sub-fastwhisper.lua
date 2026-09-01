-- sub-fastwhisper v2.7: faster-whisper subtitles (zh/en, local + online, cached)
-- ALT+f / CTRL+f = CN srt, ALT+g / CTRL+g = EN srt; right-click menu too
-- online srt cache: <script_dir>/cache/ai_sub_<urlhash>.srt  (audio cached by py)
local function find_python()
    local exedir = mp.get_property("executable-dir") or ""
    local cands = {
        exedir .. "/python313/python.exe",
        exedir .. "/python.exe",
        "C:/Program Files/MPV Player/python313/python.exe",
        "C:/Program Files/MPV Player/python.exe",
        os.getenv("LOCALAPPDATA") .. "/Programs/Python/Python313/python.exe",
    }
    for _, c in ipairs(cands) do
        if c and c ~= "" then
            local f = io.open(c, "r")
            if f then f:close() return c end
        end
    end
    return "python.exe"
end
local PYTHON = find_python()

local function find_script()
    local p = mp.find_config_file("whisper/gen_subtitle.py")
    if p then return p end
    local a = os.getenv("APPDATA") .. "/mpv/whisper/gen_subtitle.py"
    local f = io.open(a, "r")
    if f then f:close() return a end
    return "gen_subtitle.py"
end
local SCRIPT = find_script()

-- original URL: MPV-Play passes the real page URL via codec-switch-url
-- (mpv-bili/yt/etc resolve to CDN m4s, whose path would break downloads)
local function get_source()
    local u = mp.get_opt("codec-switch-url")
    if u and u ~= "" then return u:gsub("{AMP}", "&") end
    local url = mp.get_property("playlist/0/filename")
    if not url or url == "" then url = mp.get_property("path") or mp.get_property("filename") end
    if url then url = url:gsub("^ytdl://", ""):gsub("{AMP}", "&") end
    return url
end

-- normalized url hash: query/tracking params stripped so cache hits are stable
local function url_hash(u)
    local clean = u:match("^([^?#]+)") or u
    local h = 0
    for i = 1, #clean do
        h = (h * 31 + string.byte(clean, i)) % 2147483647
    end
    return tostring(h)
end

local function generate(lang)
    local path = get_source()
    if not path or path == "" then
        mp.osd_message("no video", 2)
        return
    end
    local is_url = path:match("^https?://") or path:match("^magnet:")
    -- local proxy streams (huya etc) are live feeds: no AI subtitles
    if path:match("^https?://127%.0%.0%.1") or path:match("^https?://localhost") then
        mp.osd_message("live stream: AI sub not supported", 2)
        return
    end
    if is_url then
        local cache_dir = (SCRIPT:match("^(.*)[/\\]") or ".") .. "/cache"
        local srt_path = cache_dir .. "/ai_sub_" .. url_hash(path) .. ".srt"
        local f = io.open(srt_path, "r")
        if f then
            f:close()
            mp.osd_message("cached srt loaded", 1)
            mp.commandv("sub_add", srt_path)
            return
        end
        mp.osd_message(lang == "en" and "EN sub: download+recognize (bg)..." or "CN sub: download+recognize (bg)...", 0)
        mp.command_native_async({
            name = "subprocess",
            args = {PYTHON, SCRIPT, path, srt_path, lang},
            capture_stdout = true,
            capture_stderr = true,
            playback_only = false,
        }, function(success, res)
            if not success or not res then
                mp.osd_message("AI sub spawn failed", 3)
                return
            end
            local errlog = os.getenv("TEMP") .. "\\ai_sub_err.log"
            local ef = io.open(errlog, "w")
            if ef then
                ef:write("status=" .. tostring(res.status) .. "\n")
                ef:write("stdout=" .. tostring(res.stdout or "") .. "\n")
                ef:write("stderr=" .. tostring(res.stderr or "") .. "\n")
                ef:close()
            end
            if res.status ~= 0 then
                local e = tostring(res.stderr or "")
                local first = e:match("([^\n]+)") or ""
                mp.osd_message("AI sub failed: " .. first, 3)
                return
            end
            local f2 = io.open(srt_path, "r")
            if f2 then
                local size = f2:seek("end") or 0
                f2:close()
                if size > 0 then
                    mp.osd_message("AI 字幕已生成（已缓存）", 2)
                    mp.commandv("sub_add", srt_path)
                else
                    mp.osd_message("未检测到语音（音乐/静音段）", 2)
                end
            else
                mp.osd_message("gen failed: no srt output", 3)
            end
        end)
        return
    end
    -- local file
    local base = path:match("^(.*)%.[^%.]+$") or path
    local suffix = ""
    if lang == "en" then suffix = "_en" end
    local srt_path = base .. suffix .. ".srt"
    local f = io.open(srt_path, "r")
    if f then
        local esize = f:seek("end") or 0
        f:close()
        if esize > 0 then
            mp.osd_message("loaded existing srt", 1)
            mp.commandv("sub_add", srt_path)
            return
        end
    end
    mp.osd_message(lang == "en" and "AI EN subtitle generating (bg)..." or "AI CN subtitle generating (bg)...", 0)
    mp.command_native_async({
        name = "subprocess",
        args = {PYTHON, SCRIPT, path, srt_path, lang},
        capture_stdout = false,
        capture_stderr = false,
        playback_only = false,
    }, function(success, res)
        if not success or not res or res.status ~= 0 then
            mp.osd_message("AI sub gen failed", 3)
            return
        end
        local f2 = io.open(srt_path, "r")
        if f2 then
            local size = f2:seek("end") or 0
            f2:close()
            if size > 0 then
                mp.osd_message(lang == "en" and "EN srt done" or "CN srt done", 2)
                mp.commandv("sub_add", srt_path)
            else
                mp.osd_message("未检测到语音（音乐/静音段）", 2)
            end
        else
            mp.osd_message("gen failed: no srt output", 3)
        end
    end)
end

mp.add_key_binding("Alt+f", "fastwhisper-zh", function() generate("zh") end)
mp.add_key_binding("Ctrl+f", "fastwhisper-zh2", function() generate("zh") end)
mp.add_key_binding("Alt+g", "fastwhisper-en", function() generate("en") end)
mp.add_key_binding("Ctrl+g", "fastwhisper-en2", function() generate("en") end)
mp.register_script_message("sub-fastwhisper", function() generate("zh") end)
mp.register_script_message("sub-fastwhisper-en", function() generate("en") end)