-- dlssnr_toggle.lua - DLSSNR 开关
local active = false
mp.register_script_message("dlssnr-toggle", function()
    if active then
        mp.commandv("vf", "remove", "@dlssnr")
        active = false
        mp.osd_message("DLSSNR: OFF")
    else
        mp.commandv("vf", "add", "@dlssnr", "vapoursynth=file=~~/vs/DLSSNR_NV.vpy")
        active = true
        mp.osd_message("DLSSNR: ON")
    end
end)
