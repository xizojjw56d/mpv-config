-- huya_auto.lua - auto-route Huya URLs through the local concat proxy
-- Fixes: opening a huya.com link directly with mpv dies within seconds
-- (the signed stream URL expires every 0.1~0.5s). This hook starts
-- huya_http.py (v5 single concat stream) and switches the playback
-- source to http://127.0.0.1:8899/live (stable, zero PTS resets).
-- Works no matter how mpv was launched (file assoc / shell extension /
-- "mpv play" buttons / drag & drop / clipboard).
local utils = require("mp.utils")
local PREFIX = "http://127.0.0.1:8899/live"
local active = false

local function resolve()
    local cand = {}
    local pf = os.getenv("PROGRAMFILES") or "C:\\Program Files"
    table.insert(cand, pf .. "\\MPV Player")
    local pf86 = os.getenv("PROGRAMFILES(X86)")
    if pf86 and pf86 ~= "" then table.insert(cand, pf86 .. "\\MPV Player") end
    local cfg = mp.get_property("config-dir") or ""
    local up = cfg:gsub("[\\/][^\\/]*$", "")
    if up ~= cfg and up ~= "" then table.insert(cand, up) end
    for _, d in ipairs(cand) do
        if io.open(d .. "\\huya_http.py", "r") then
            local py = d .. "\\python313\\python.exe"
            if not io.open(py, "r") then
                py = (os.getenv("LOCALAPPDATA") or "") .. "\\Programs\\Python\\Python313\\python.exe"
                if not io.open(py, "r") then py = "python" end
            end
            return d, py
        end
    end
    return nil, nil
end

local function kill_stale()
    local pidfile = os.getenv("TEMP") .. "\\huya_live\\proxy.pid"
    local f = io.open(pidfile, "r")
    if f then
        local pid = (f:read("*a") or ""):match("%d+")
        f:close()
        if pid then
            utils.subprocess({args = {"taskkill", "/f", "/pid", pid}})
        end
    end
end

local function cleanup()
    if not active then return end
    active = false
    kill_stale()
    local pidfile = os.getenv("TEMP") .. "\\huya_live\\proxy.pid"
    os.remove(pidfile)
    mp.msg.info("huya proxy stopped")
end

mp.add_hook("on_load", 5, function()
    local path = mp.get_property("path") or ""
    if not path:lower():find("huya") then return end
    local room = path:match("huya%.com/(%d+)") or path:match("(%d%d%d%d%d%d%d+)")
    if not room then
        mp.msg.warn("huya_auto: no room id in " .. path)
        return
    end
    local dir, py = resolve()
    if not dir then
        mp.msg.warn("huya_auto: MPV Player directory not found")
        return
    end
    kill_stale()
    mp.msg.info("huya_auto: starting proxy for room " .. room)
    -- detached console-free start
    utils.subprocess({args = {
        "cmd.exe", "/c", "start", "", "/min",
        py, dir .. "\\huya_http.py", room, "best", "8899"
    }})
    -- wait for proxy readiness (pidfile written by huya_http.py)
    local pidfile = os.getenv("TEMP") .. "\\huya_live\\proxy.pid"
    local ready = false
    for i = 1, 8 do
        utils.subprocess({args = {"cmd.exe", "/c", "ping 127.0.0.1 -n 2 >nul"}})
        if io.open(pidfile, "r") then ready = true break end
    end
    if ready then
        -- small extra settle for the HTTP server socket
        utils.subprocess({args = {"cmd.exe", "/c", "ping 127.0.0.1 -n 2 >nul"}})
        active = true
        mp.msg.info("huya_auto: proxy ready, switching to " .. PREFIX)
        mp.commandv("loadfile", PREFIX, "replace")
    else
        mp.msg.warn("huya_auto: proxy failed to start; falling back to direct URL")
    end
end)

mp.register_event("end-file", function() cleanup() end)
mp.register_event("shutdown", function() cleanup() end)

print("[huya_auto] loaded: huya URLs are auto-routed through the stable proxy")
