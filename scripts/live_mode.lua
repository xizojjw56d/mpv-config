-- live_mode.lua - mark pipe streams as live (hide progress bar in uosc)
local active = false

local function set_live()
    if mp.get_property("path") == "-" or not active then return end
    mp.set_property("duration", "inf")
    mp.msg.error("LIVE: duration set to inf")
end

mp.observe_property("path", "string", function(name, val)
    active = (val == "-")
    if active then
        mp.set_property("duration", "inf")
        mp.msg.error("LIVE MODE: pipe stream")
    end
end)

mp.register_event("file-loaded", function()
    if mp.get_property("path") == "-" then
        mp.set_property("duration", "inf")
        mp.msg.error("LIVE MODE: file-loaded set inf")
    end
end)
