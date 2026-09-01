-- quality_switch.lua v2 - 在线视频画质切换（B 站 / YouTube 通用）
-- v2: 接口对齐 codec-switch-url (与 codec_switch.lua 同源)
--     旧版读 playlist/0/filename 拿到的是 CDN 流地址 -> ytdl:// 重解析必失败
--     v2 用 command_native subprocess 调 yt-dlp 直接取流 -> loadfile(视频) + audio-files-append
local quals_bili = {
    q8k   = {'bestvideo[height<=?4320]+bestaudio/best', '8K (4320P)'},
    q4k   = {'bestvideo[height<=?2160]+bestaudio/best', '4K (2160P)'},
    q2k   = {'bestvideo[height<=?1440]+bestaudio/best', '2K (1440P)'},
    q1080 = {'bestvideo[height<=?1080]+bestaudio/best', '1080P'},
    q720  = {'bestvideo[height<=?720]+bestaudio/best', '720P'},
    qauto = {'bestvideo[vcodec~=av01][height<=?2160]+bestaudio/bestvideo[height<=?2160]+bestaudio/best', '自动最高'},
}
local quals_yt = {
    q8k   = {'bestvideo[height<=?4320]+bestaudio/best', '8K (4320P)'},
    q4k   = {'bestvideo[height<=?2160]+bestaudio/best', '4K (2160P)'},
    q2k   = {'bestvideo[height<=?1440]+bestaudio/best', '2K (1440P)'},
    q1080 = {'bestvideo[height<=?1080]+bestaudio/best', '1080P'},
    q720  = {'bestvideo[height<=?720]+bestaudio/best', '720P'},
    qauto = {'bestvideo[vcodec~=av01]+bestaudio/bestvideo+bestaudio/best', '自动最高'},
}

local function find_ytdl()
    local mpvdir = 'C:/Program Files/MPV Player/yt-dlp.exe'
    local f = io.open(mpvdir, 'r')
    if f then f:close(); return mpvdir end
    return 'yt-dlp.exe'
end
local YTDL_PATH = find_ytdl()

local function get_original_url()
    -- 接口对齐: 优先取入口 bat 传的 codec-switch-url
    local u = mp.get_opt('codec-switch-url')
    if u and u ~= '' then return u:gsub('{AMP}', '&') end
    local url = mp.get_property('playlist/0/filename')
    if not url or url == '' then url = mp.get_property('filename') end
    if url then url = url:gsub('^ytdl://', ''):gsub('{AMP}', '&') end
    return url
end

local function is_youtube(url)
    local u = string.lower(url or '')
    return string.find(u, 'youtube%.com') ~= nil or string.find(u, 'youtu%.be') ~= nil
end

local function do_switch(q)
    local url = get_original_url()
    if not url or url == '' then
        mp.osd_message('无法获取链接', 2)
        return
    end
    local quals = is_youtube(url) and quals_yt or quals_bili
    local c = quals[q]
    if not c then return end
    mp.osd_message('画质: ' .. c[2] .. ' ...', 5)
    -- 取流(带 cookie/proxy)
    local args = {YTDL_PATH, '--no-check-certificates', '-f', c[1], '--get-url', '--no-progress', url}
    if is_youtube(url) then
        local proxy = os.getenv('HTTP_PROXY') or os.getenv('http_proxy')
        if proxy and proxy ~= '' then
            table.insert(args, 2, '--proxy')
            table.insert(args, 3, proxy)
        end
    else
        -- B 站需要 cookie 大会员画质
        table.insert(args, 2, '--cookies-from-browser')
        table.insert(args, 3, 'firefox:gmunjri5.default-release')
    end
    local res = mp.command_native({
        name = 'subprocess',
        args = args,
        capture_stdout = true,
        capture_stderr = true,
        playback_only = false,
    })
    if not res or res.status ~= 0 then
        local err = tostring(res and res.stderr or '')
        local e1 = err:gsub('\n.*', ''):sub(1, 60)
        mp.osd_message('画质切换失败: ' .. e1, 4)
        mp.msg.error('quality yt-dlp failed: ' .. err)
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
        mp.osd_message('画质切换失败: 无流', 3)
        return
    end
    -- v8 架构: 先视频后音频
    mp.commandv('loadfile', v_url, 'replace')
    mp.set_property('ytdl-format', c[1])
    if a_url then
        mp.set_property('audio-files-append', '')
        mp.set_property('audio-files-append', a_url)
    end
    mp.osd_message('画质: ' .. c[2] .. ' (重载中)', 5)
end

mp.register_script_message('quality_switch', function(q)
    do_switch(q)
end)