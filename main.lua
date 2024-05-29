-- main.lua
local Framebuffer = require("framebuf")

local fb = Framebuffer:new(640, 480)

-- Draw a red rectangle
for y = 100, 200 do
    for x = 150, 300 do
        fb:set_pixel(x, y, 255, 0, 0)
    end
end

-- Save the framebuffer to a BMP file
fb:save_bmp("output.bmp")
