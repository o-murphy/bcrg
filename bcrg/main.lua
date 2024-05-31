-- Load the framebuffer module
require("framebuffer")
require("reticledraw")

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
    local fb = ReticleDraw:new(buf, width, height, bit_depth == 1 and MVLSB or NMLSB)

    -- Fill the frame buffer with white (1 for 1-bit, 255 for 8-bit, etc.)
    local fill_value = bit_depth == 1 and 1 or 255
    fb:fill(fill_value)

    -- Draw a black rectangle (0 for 1-bit, 0 for 8-bit, etc.) at position (100, 100) with width 200 and height 150
    fb:c_fill_rect(-100, -50, 200, 100, 0)

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
    local fb = ReticleDraw:new(buf, width, height, bit_depth == 1 and MVLSB or NMLSB)

    -- Fill the frame buffer with white (1 for 1-bit, 255 for 8-bit, etc.)
    local fill_value = bit_depth == 1 and 1 or 255
    fb:fill(fill_value)

    -- Draw a black rectangle (0 for 1-bit, 0 for 8-bit, etc.) at position (100, 100) with width 200 and height 150
    fb:c_fill_rect(0, 0, 200, 100, 0)

    fb:c_fill_circle(0, 0, 20, 1)

    local points = {
        { 10, 10 },
        { 20, 30 },
        { 30, 10 },
        { 40, 30 },
        { 50, 10 }
    }

    fb:polygon(points, 0)

    fb:hline(-0.0000000001, 0, 10, 0)

    -- Return the buffer data as a bytearray
    --return fb:to_bmp()
    return fb:to_bmp()
end