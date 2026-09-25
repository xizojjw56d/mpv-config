-- codec_switch.lua v8 - Bilibili codec switch (AV1/AVC/HEVC/default)
-- Architecture: resolve URLs via yt-dlp subprocess -> loadfile(video) -> attach audio.
--             (mp.utils.subprocess removed in new mpv; loadfile options audio-file
--              unsupported -> use audio-files-append property after loadfile)
local codecs = {
    av1     = {'bestvideo[vcodec~=av01]+bestaudio/best', 'AV1'},
    avc     = {'bestvideo[vcodec~=avc]+bestaudio/best', 'AVC(H.264)'},
    hevc    = {'bestvideo[vcodec~=hvc]+bestaudio/best', 'HEVC'},
    default = {'bestvideo[vcodec~=av01][height<=?2160]+bestaudio/bestvideo[height<=?2160]+bestaudio/best', 'default (AV1 first)'},
}

local function find_ytdl()
    local mpvdir = 'C:/Program Files/MPV Player/yt-dlp.exe'
    local f = io.open(mpvdir, 'r')
    if f then f:close(); return mpvdir end
    return 'yt-dlp.exe'
end
local YTDL_PATH = find_ytdl()

local function find_python()
    local mpvdir = 'C:/Program Files/MPV Player/python313/python.exe'
    local f = io.open(mpvdir, 'r')
    if f then f:close(); return mpvdir end
    local la = (os.getenv('LOCALAPPDATA') or '') .. '/Programs/Python/Python313/python.exe'
    f = io.open(la, 'r')
    if f then f:close(); return la end
    return 'python'
end
local PYTHON = find_python()

local function get_original_url()
    local u = mp.get_opt('codec-switch-url')
    if u and u ~= '' then return u:gsub('{AMP}', '&') end
    local url = mp.get_property('playlist/0/filename')
    if not url or url == '' then url = mp.get_property('filename') end
    if url then url = url:gsub('^ytdl://', ''):gsub('{AMP}', '&') end
    return url
end

local LIVE_SITES = { ['www.huya.com']=true, ['huya.com']=true, ['www.douyu.com']=true, ['douyu.com']=true }

local function is_live_url(url)
    if not url then return false end
    for site in pairs(LIVE_SITES) do
        if url:find(site, 1, true) then return true end
    end
    return false
end

local function is_proxy_live(url)
    if not url then return false end
    return url:find('127.0.0.1:') ~= nil or url:find('localhost:') ~= nil
end

-- huya: probe codec INSIDE the local proxy (huya_http.py v6 /switch).
-- Huya CDN formats (hs/al/tx) are all H.264 on most rooms; AV1/HEVC only
-- on a few rooms. The proxy probes availability and only reloads when real.
local function huya_proxy_switch(url, codec)
    if codec == 'avc' or codec == 'default' then
        mp.osd_message('current codec: H.264 (this room)', 3)
        return
    end
    local c = (codec == 'av1' or codec == 'hevc') and codec or 'av1'
    local target = url:gsub('/live.*$', '') .. '/switch?codec=' .. c
    mp.osd_message('probe ' .. string.upper(c) .. ' ...', 4)
    local res = mp.command_native({
        name = 'subprocess',
        args = {PYTHON, '-B', '-c',
                'import urllib.request,sys,json;d=json.loads(urllib.request.urlopen(sys.argv[1],timeout=20).read());print(("OK" if d.get("ok") else "NO")+":"+str(d.get("codec","")))',
                target},
        capture_stdout = true,
        capture_stderr = true,
        playback_only = false,
    })
    local out = res and (res.stdout or ''):match('^(%a+):(.*)$')
    if out and out[1] == 'OK' then
        mp.osd_message('codec: ' .. string.upper(out[2] or c) .. ' (reloading)', 4)
        mp.commandv('loadfile', url, 'replace')
    else
        mp.osd_message('this room: H.264 only (no ' .. string.upper(c) .. ')', 4)
    end
end

local function do_switch(codec)
    local url = get_original_url()
    if not url or url == '' then
        mp.osd_message('cannot get url', 2)
        return
    end
    if is_proxy_live(url) then
        huya_proxy_switch(url, codec)
        return
    end
    if is_live_url(url) or url == '-' then
        mp.osd_message('live stream: only H.264, no codec switch', 4)
        return
    end
    local c = codecs[codec]
    if not c then return end
    mp.osd_message('switching to ' .. c[2] .. ' ...', 5)
    local res = mp.command_native({
        name = 'subprocess',
        args = {YTDL_PATH, '--no-check-certificates', '--cookies-from-browser', 'firefox:xxxxx.default-release', '-f', c[1], '--get-url', '--no-progress', url},
        capture_stdout = true,
        capture_stderr = true,
        playback_only = false,
    })
    if not res or res.status ~= 0 then
        local err = tostring(res and res.stderr or '')
        local e1 = err:gsub('\n.*', ''):sub(1, 60)
        mp.osd_message('codec switch failed: ' .. e1, 4)
        mp.msg.error('yt-dlp failed: ' .. err)
        return
    end
    local out = res.stdout or ''
    local v_url, a_url = nil, nil
    for line in out:gmatch('[^\r\n]+') do
        local ln = line:gsub('^%s+', ''):gsub('%s+$', '')
        if ln ~= '' then
            if not v_url then v_url = ln
            elseif not a_url then a_url = ln end
        end
    end
    if not v_url then
        mp.osd_message('codec switch failed: no stream', 3)
        return
    end
    -- loadfile video only, then attach audio (reversed: video starts, audio follows)
    mp.commandv('loadfile', v_url, 'replace')
    mp.set_property('ytdl-format', c[1])
    if a_url then
        mp.set_property('audio-files-append', '')
        mp.set_property('audio-files-append', a_url)
    end
    mp.osd_message('codec: ' .. c[2] .. ' (reloading)', 5)
end

mp.register_script_message('codec_switch', function(codec)
    do_switch(codec)
end)