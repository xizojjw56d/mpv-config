-- shader_toggle.lua — 着色器开关，带明确的开/关状态反馈
local shaders = {
    cas      = "~~/shaders/igv/adaptive-sharpen_luma.glsl",
    anime4k  = "~~/shaders/Anime4K/Anime4K_Restore_CNN_M.glsl",
    fsrcnnx  = "~~/shaders/igv/FSRCNNX_x2.glsl",
    ssim     = "~~/shaders/igv/SSimSuperRes.glsl",
}

local function is_on(shader)
    local list = mp.get_property('glsl-shaders', '')
    -- 逐项比较（含 ~~ 展开与路径规范化，直接做子串匹配）
    local probe = shader:gsub('~~', '')
    return list:find(probe:gsub('%$', '%%$'), 1, true) ~= nil
end

local function toggle(name)
    local sh = shaders[name]
    if not sh then return end
    local on = is_on(sh)
    mp.commandv('change-list', 'glsl-shaders', on and 'remove' or 'append', sh)
    mp.osd_message((on and '已关闭: ' or '已开启: ') .. name, 1.5)
end

mp.register_script_message('shader_toggle', function(name)
    toggle(name)
end)
