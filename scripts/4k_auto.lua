-- 4k_auto.lua - 自动检测 4K 内容并应用 [超高清] profile
local applied = false
local function check_4k()
    if applied then return end
    local h = mp.get_property_native("video-params/h") or 0
    if h >= 2160 then
        mp.commandv("apply-profile", "超高清")
        applied = true
        mp.msg.info("4K detected, applied [超高清] profile")
    end
end
mp.register_event("video-reconfig", check_4k)
mp.add_timeout(3, check_4k)