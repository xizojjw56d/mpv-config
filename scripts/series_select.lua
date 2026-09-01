-- series_select.lua — 剧集连播与选集（电视剧分P / 番剧 / 本地系列）
-- 功能：
--   1) B站剧集 URL 自动展开为播放列表（播完自动下一集）
--   2) F6 选集菜单：本地系列→uosc 播放列表；B站→整季选集
--   3) 进度条章节标记由 uosc(chapter_display) + skip-segments(片头片尾) 提供
local utils = require "mp.utils"
local msg = require "mp.msg"

local YTDLP = nil
local function find_ytdlp()
    if YTDLP then return YTDLP end
    for _, c in ipairs({
        "C:/Program Files/MPV Player/yt-dlp.exe",
        (mp.get_property("executable-dir") or "") .. "/yt-dlp.exe",
        "yt-dlp.exe",
    }) do
        if c and #c > 4 then
            local f = io.open(c, "r")
            if f then f:close() YTDLP = c return c end
        end
    end
    return "yt-dlp.exe"
end

local expanded = {}     -- series_url -> true（已展开，防重复）
local cache = {}        -- series_url -> episodes table
local MENU_TYPE = "series_select"

-- 支持的剧集平台：B站 / 爱奇艺 / 优酷 / 腾讯视频 / 芒果TV / 搜狐
local SITES = { "bilibili%.com", "b23%.tv", "iqiyi%.com", "youku%.com",
    "v%.qq%.com", "mgtv%.com", "tv%.sohu%.com" }
local function is_bili(u)
    if type(u) ~= "string" then return false end
    for _, d in ipairs(SITES) do
        if u:find(d, 1, false) then return true end
    end
    return false
end

local function current_series_url()
    local u = mp.get_opt("codec-switch-url")
    if u and u ~= "" then u = u:gsub("{AMP}", "&") end
    if not is_bili(u) then u = mp.get_property("path") end
    return is_bili(u) and u or nil
end

-- 解析 yt-dlp --flat-playlist 输出 "index|title|id"
local function parse_entries(text)
    local eps = {}
    for line in text:gmatch("[^\r\n]+") do
        local idx, title, id, eurl = line:match("^(%d*)|(.*)|(%S+)|(.*)$")
        if id then
            eps[#eps + 1] = {
                index = tonumber(idx) or #eps + 1,
                title = (title ~= "" and title ~= "NA") and title or ("第 " .. (#eps + 1) .. " 集"),
                id = id,
                url = (eurl and eurl ~= "" and eurl ~= "NA") and eurl or nil,
            }
        end
    end
    return eps
end

local function entry_url(series_url, ep)
    -- 各平台 flat-playlist 直接给出成品链接时优先用（爱奇艺/优酷/腾讯/芒果等）
    if ep.url then return ep.url end
    if series_url:find("/bangumi/", 1, false) then
        return "https://www.bilibili.com/bangumi/play/ep" .. ep.id
    end
    local bvid = series_url:match("/video/([%w]+)")
        or series_url:match("bilibili%.com/video/([%w]+)") or ep.id
    return "https://www.bilibili.com/video/" .. bvid .. "?p=" .. ep.index
end

local function fetch_entries(series_url, callback)
    local cached = cache[series_url]
    if cached then callback(cached) return end
    local cmd = { find_ytdlp(), "--flat-playlist", "--no-warnings",
        "--print", "%(playlist_index)s|%(title)s|%(id)s|%(url)s", series_url }
    mp.command_native_async({
        name = "subprocess", args = cmd,
        capture_stdout = true, capture_stderr = true, playback_only = false,
    }, function(ok, res)
        if not ok or not res or res.status ~= 0 or not res.stdout or res.stdout == "" then
            msg.warn("flat-playlist failed: " .. tostring(res and res.stderr or ""))
            callback(nil)
            return
        end
        local eps = parse_entries(res.stdout)
        if #eps == 0 then callback(nil) return end
        cache[series_url] = eps
        callback(eps)
    end)
end

-- 播放列表自动展开：把当前集之后的剧集 append（实现自动连播）
local function auto_expand()
    local series = current_series_url()
    if not series then return end
    if mp.get_property_number("playlist-count", 1) > 1 then return end
    if expanded[series] then return end
    expanded[series] = true
    local cur_p = tonumber(series:match("[?&]p=(%d+)") or 1) or 1
    mp.add_timeout(2.5, function()
        fetch_entries(series, function(eps)
            if not eps then return end
            local added = 0
            for _, ep in ipairs(eps) do
                if ep.index > cur_p then
                    mp.commandv("loadfile", entry_url(series, ep), "append-play")
                    added = added + 1
                end
            end
            if added > 0 then
                mp.osd_message("剧集列表已展开：" .. added .. " 集待播（自动连播）", 2)
            end
        end)
    end)
end

-- 选集菜单
local function open_menu()
    local path = mp.get_property("path") or ""
    -- 本地文件 / 非B站：直接用 uosc 播放列表（autoload 已建好本地系列）
    if not is_bili(path) and not is_bili(mp.get_opt("codec-switch-url")) then
        mp.commandv("script-binding", "uosc/playlist")
        return
    end
    local series = current_series_url()
    if not series then
        mp.osd_message("当前不是可展开的剧集页面", 2)
        return
    end
    mp.osd_message("正在获取剧集列表...", 1)
    fetch_entries(series, function(eps)
        if not eps then
            mp.osd_message("未获取到剧集列表（无分集/需登录/会员DRM请用浏览器观看）", 3)
            return
        end
        local items = {}
        for _, ep in ipairs(eps) do
            items[#items + 1] = {
                title = string.format("%02d  %s", ep.index, ep.title),
                value = entry_url(series, ep),
            }
        end
        local menu = {
            type = MENU_TYPE,
            title = "选集（" .. #items .. " 集）",
            search_style = "on_demand",
            search_suggestion = "搜索集数/标题",
            items = items,
            callback = { mp.get_script_name(), "menu-event" },
        }
        mp.commandv("script-message-to", "uosc", "open-menu", utils.format_json(menu))
    end)
end

mp.register_script_message("menu-event", function(json)
    local ev = utils.parse_json(json)
    if type(ev) ~= "table" or ev.type ~= "activate" then return end
    local url = tostring(ev.value or "")
    if url == "" then return end
    mp.commandv("loadfile", url, "replace")
    mp.commandv("script-message-to", "uosc", "close-menu", MENU_TYPE)
end)

mp.register_script_message("series_select", open_menu)
mp.register_event("file-loaded", auto_expand)
