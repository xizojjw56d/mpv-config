-- speed_control.lua — 动态速度控制：0.1x ~ 3.0x，步进 ±0.1
-- 键盘 [ / ] 步进调节；菜单通过 script-message speed_down / speed_up 调用
local MIN, MAX, STEP = 0.1, 3.0, 0.1

local function set_speed(s)
    s = math.max(MIN, math.min(MAX, s))
    s = math.floor(s * 10 + 0.5) / 10  -- 取整到 0.1
    mp.set_property_number("speed", s)
    mp.osd_message(string.format("速度: %.1fx", s), 1)
end

local function speed_down()
    set_speed(mp.get_property_number("speed", 1.0) - STEP)
end

local function speed_up()
    set_speed(mp.get_property_number("speed", 1.0) + STEP)
end

mp.add_key_binding("[", "speed-down", speed_down)
mp.add_key_binding("]", "speed-up", speed_up)
mp.register_script_message("speed_down", speed_down)
mp.register_script_message("speed_up", speed_up)
