-- rtx-vsr-guard.lua - RTX VSR 硬解联动检测
-- 当 VF 列表包含 d3d11vpp（RTX VSR）但硬解不是 d3d11va 时给出 OSD 提示
-- 无需 mode flag：直接检测 VF 列表中是否有 d3d11vpp
mp.observe_property("vf", "native", function()
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
end)
