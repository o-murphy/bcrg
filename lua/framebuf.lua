-- Pure Lua implementation of MicroPython framebuf module.
-- This is intended for boards with limited flash memory and the inability to
-- use the native C version of the framebuf module. This Lua module can be
-- added to the board's file system to provide a functionally identical framebuf
-- interface but at the expense of speed (this Lua version will be _much_
-- slower than the C version).

-- framebuf.lua

-- Framebuf format constants:
MVLSB = 0  -- Single bit displays (like SSD1306 OLED)
RGB565 = 1  -- 16-bit color displays
GS4_HMSB = 2  -- Unimplemented!

MVLSBFormat = {}

function MVLSBFormat:setpixel(fb, x, y, color)
    local index = math.floor(y / 8) * fb.stride + x
    local offset = y % 8
    fb.buf[index] = (fb.buf[index] & ~(1 << offset)) | ((color ~= 0 and 1 or 0) << offset)
end

function MVLSBFormat:getpixel(fb, x, y)
    local index = math.floor(y / 8) * fb.stride + x
    local offset = y % 8
    return (fb.buf[index] >> offset) & 1
end

function MVLSBFormat:fill_rect(fb, x, y, width, height, color)
    while height > 0 do
        local index = math.floor(y / 8) * fb.stride + x
        local offset = y % 8
        for ww = 0, width - 1 do
            fb.buf[index + ww] = (fb.buf[index + ww] & ~(1 << offset)) | ((color ~= 0 and 1 or 0) << offset)
        end
        y = y + 1
        height = height - 1
    end
end

RGB565Format = {}

function RGB565Format:setpixel(fb, x, y, color)
    local index = (x + y * fb.stride) * 2
    fb.buf[index] = (color >> 8) & 0xFF
    fb.buf[index + 1] = color & 0xFF
end

function RGB565Format:getpixel(fb, x, y)
    local index = (x + y * fb.stride) * 2
    return (fb.buf[index] << 8) | fb.buf[index + 1]
end

function RGB565Format:fill_rect(fb, x, y, width, height, color)
    while height > 0 do
        for ww = 0, width - 1 do
            local index = (ww + x + y * fb.stride) * 2
            fb.buf[index] = (color >> 8) & 0xFF
            fb.buf[index + 1] = color & 0xFF
        end
        y = y + 1
        height = height - 1
    end
end

FrameBuffer = {}

function FrameBuffer:new(buf, width, height, buf_format, stride)
    local fb = {}
    setmetatable(fb, self)
    self.__index = self
    fb.buf = buf
    fb.width = width
    fb.height = height
    fb.stride = stride or width
    if buf_format == MVLSB then
        fb.format = MVLSBFormat
    elseif buf_format == RGB565 then
        fb.format = RGB565Format
    else
        error("invalid format")
    end
    return fb
end

function FrameBuffer:fill(color)
    self.format:fill_rect(self, 0, 0, self.width, self.height, color)
end

function FrameBuffer:fill_rect(x, y, width, height, color)
    if width < 1 or height < 1 or (x + width) <= 0 or (y + height) <= 0 or y >= self.height or x >= self.width then
        return
    end
    local xend = math.min(self.width, x + width)
    local yend = math.min(self.height, y + height)
    x = math.max(x, 0)
    y = math.max(y, 0)
    self.format:fill_rect(self, x, y, xend - x, yend - y, color)
end

function FrameBuffer:pixel(x, y, color)
    if x < 0 or x >= self.width or y < 0 or y >= self.height then
        return
    end
    if color == nil then
        return self.format:getpixel(self, x, y)
    else
        self.format:setpixel(self, x, y, color)
    end
end

function FrameBuffer:hline(x, y, width, color)
    self:fill_rect(x, y, width, 1, color)
end

function FrameBuffer:vline(x, y, height, color)
    self:fill_rect(x, y, 1, height, color)
end

function FrameBuffer:rect(x, y, width, height, color)
    self:fill_rect(x, y, width, 1, color)
    self:fill_rect(x, y + height, width, 1, color)
    self:fill_rect(x, y, 1, height, color)
    self:fill_rect(x + width, y, 1, height, color)
end

function FrameBuffer:line(x0, y0, x1, y1, color)
    local dx = math.abs(x1 - x0)
    local dy = math.abs(y1 - y0)
    local sx = x0 < x1 and 1 or -1
    local sy = y0 < y1 and 1 or -1
    local err = (dx > dy and dx or -dy) / 2

    while true do
        self:pixel(x0, y0, color)
        if x0 == x1 and y0 == y1 then break end
        local e2 = err
        if e2 > -dx then err = err - dy x0 = x0 + sx end
        if e2 < dy then err = err + dx y0 = y0 + sy end
    end
end

function FrameBuffer:save_bmp(filename)
    local file = io.open(filename, "wb")
    local pad = (4 - (self.width * 3) % 4) % 4
    local filesize = 54 + (3 * self.width + pad) * self.height

    -- BMP Header
    file:write("BM")
    file:write(string.pack("<I4I2I2I4", filesize, 0, 0, 54))

    -- DIB Header
    file:write(string.pack("<I4I4I4I2I2I4I4I4I4I4I4",
        40, self.width, self.height, 1, 24, 0, 0, 2835, 2835, 0, 0))

    -- Pixel Data
    for y = self.height - 1, 0, -1 do
        for x = 0, self.width - 1 do
            local color = self.format:getpixel(self, x, y) == 1 and 255 or 0
            file:write(string.char(color, color, color)) -- BGR format
        end
        file:write(string.rep("\0", pad)) -- Padding
    end

    file:close()
end

function FrameBuffer:blit()
    error("NotImplementedError")
end

function FrameBuffer:scroll()
    error("NotImplementedError")
end

function FrameBuffer:text()
    error("NotImplementedError")
end

FrameBuffer1 = FrameBuffer

return FrameBuffer