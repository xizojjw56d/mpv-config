-- rtx-vsr-guard.lua - RTX VSR 硬解联动检测
-- 监听 vf 列表和 hwdec-current 两个属性：
--   vf 变化时检查（进入直播优化模式时触发）
--   hwdec-current 变化时检查（Ctrl+Shift+H 切硬解时触发）
local function check_vsr()
    local vf = mp.get_property_native("vf")
    local has_vsr = false
    if vf then
        for _, f in ipairs(vf) do
            if f.name and f.name:find("d3d11vpp") then
                has_vsr = true
                break
            end
        end
    end
    if has_vsr then
        local hwdec = mp.get_property("hwdec-current")
        if hwdec and hwdec ~= "d3d11va" and hwdec ~= "" then
            mp.osd_message("⚠ RTX VSR 需要硬解=d3d11va，当前=" .. hwdec .. "，按 Ctrl+Shift+H 切换", 4)
        end
    end
end
mp.observe_property("vf", "native", check_vsr)
mp.observe_property("hwdec-current", "string", check_vsr)
