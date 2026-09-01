-- v6obs.lua: 每秒记录 wall delta + pos
local t0 = os.clock()
local f = io.open(os.getenv('TEMP') .. '/v6pos.log', 'w')
f:write('wall,pos\n')
f:close()
mp.register_event('tick', function()
    local p = mp.get_property_number('time-pos')
    local wall = os.clock() - t0
    local f2 = io.open(os.getenv('TEMP') .. '/v6pos.log', 'a')
    f2:write(string.format('%.2f,%.3f\n', wall, p or -1))
    f2:close()
end)
