-- draw.lua

-- Require the FrameBuffer module
local FrameBuffer = require("framebuf")

-- Create a buffer for 640x640 monochrome display
local width, height = 640, 640
local buffer_size = (width * height) // 8  -- Calculate the buffer size for monochrome display
local buf = {}
for i = 1, buffer_size do
    buf[i] = 0
end

-- Initialize the FrameBuffer
local fb = FrameBuffer:new(buf, width, height, MVLSB)

-- Fill the framebuffer with white color
fb:fill(1)

-- Draw a black rectangle in the center
local rect_width, rect_height = 200, 200
local rect_x = (width - rect_width) // 2
local rect_y = (height - rect_height) // 2

fb:fill_rect(rect_x, rect_y, rect_width, rect_height, 0)

-- Output the buffer content in hexadecimal format
for i = 1, buffer_size do
    io.write(string.char(buf[i]))
end

return buf
