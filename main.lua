local gatogoto = require("gatogoto")

local clock = os.clock
local function sleep(n) -- You can strip this out if you want, i just added it to make it go slow
   local t0 = clock()
   while clock() - t0 <= n do
   end
end

local myInstance = gatogoto()
local err = myInstance:parse([[
    set $count 2 

    mul $count $count 2
    meow $count
    goto -3
]])
assert(err==nil, tostring(err))

local shouldrun = true
while shouldrun do
    if shouldrun then
        shouldrun, err = myInstance:run()
    end

    sleep(0.1)
    assert(err==nil, tostring(err))
end