---- main._lua
--
---- Load the framebuffer module
--require("framebuffer")
--
---- Function to create a framebuffer, fill it with white, and draw a black rectangle
--local function create_framebuffer_with_rect(width, height, bit_depth)
--    -- Calculate the buffer size based on the bit depth
--    local buffer_size = (width * height * bit_depth) / 8
--
--    -- Create a buffer for the display
--    local buf = {}
--    for i = 1, buffer_size do
--        buf[i] = 0
--    end
--
--    -- Initialize the frame buffer
--    local fb = FrameBuffer:new(buf, width, height, bit_depth == 1 and MVLSB or NMLSB)
--
--    -- Fill the frame buffer with white (1 for 1-bit, 255 for 8-bit, etc.)
--    local fill_value = bit_depth == 1 and 1 or 255
--    fb:fill(fill_value)
--
--    -- Draw a black rectangle (0 for 1-bit, 0 for 8-bit, etc.) at position (100, 100) with width 200 and height 150
--    fb:rect(100, 100, 200, 150, 0)
--
--    -- For demonstration purposes, let's print a portion of the buffer to see the result
--    for y = 0, 10 do
--        for x = 0, 10 do
--            local pixel_value = fb:pixel(x, y)
--            if bit_depth == 1 then
--                io.write(pixel_value == 1 and "1" or "0")
--            else
--                io.write(string.format("%03d ", pixel_value))
--            end
--        end
--        io.write("\n")
--    end
--end
--
---- Return the function so it can be called elsewhere
--return create_framebuffer_with_rect


-- framebuffer._lua

-- Load the framebuffer module
require("framebuffer")

-- Function to create a framebuffer, fill it with white, and draw a black rectangle
function make_fb(width, height, bit_depth)
    -- Calculate the buffer size based on the bit depth
    local buffer_size = (width * height * bit_depth) / 8

    -- Create a buffer for the display
    local buf = {}
    for i = 1, buffer_size do
        buf[i] = 0
    end

    -- Initialize the frame buffer
    local fb = FrameBuffer:new(buf, width, height, bit_depth == 1 and MVLSB or NMLSB)

    -- Fill the frame buffer with white (1 for 1-bit, 255 for 8-bit, etc.)
    local fill_value = bit_depth == 1 and 1 or 255
    fb:fill(fill_value)

    -- Draw a black rectangle (0 for 1-bit, 0 for 8-bit, etc.) at position (100, 100) with width 200 and height 150
    fb:rect(100, 100, 200, 150, 0)

    -- Return the buffer data
    return fb.buf
end


-- Function to create a framebuffer, fill it with white, and draw a black rectangle
function make_bmp(width, height, bit_depth)
    -- Calculate the buffer size based on the bit depth
    local buffer_size = (width * height * bit_depth) / 8

    -- Create a buffer for the display
    local buf = {}
    for i = 1, buffer_size do
        buf[i] = 0
    end

    -- Initialize the frame buffer
    local fb = FrameBuffer:new(buf, width, height, bit_depth == 1 and MVLSB or NMLSB)

    -- Fill the frame buffer with white (1 for 1-bit, 255 for 8-bit, etc.)
    local fill_value = bit_depth == 1 and 1 or 255
    fb:fill(fill_value)

    -- Draw a black rectangle (0 for 1-bit, 0 for 8-bit, etc.) at position (100, 100) with width 200 and height 150
    fb:rect(100, 100, 200, 150, 0)

    -- Return the buffer data as a bytearray
    return fb:to_bmp()
end