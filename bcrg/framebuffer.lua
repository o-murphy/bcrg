-- framebuffer._lua

-- Frame buffer format constants
MVLSB = 0  -- Single bit displays (like SSD1306 OLED)
RGB565 = 1 -- 16-bit color displays

-- MVLSB format implementation
MVLSBFormat = {}
MVLSBFormat.__index = MVLSBFormat

function MVLSBFormat:setpixel(fb, x, y, color)
    local index = math.floor(y / 8) * fb.stride + x
    local offset = y % 8
    local current = fb.buf[index + 1]
    local mask = ~(0x01 << offset)
    local value = ((color ~= 0) and 1 or 0) << offset
    fb.buf[index + 1] = (current & mask) | value
end

function MVLSBFormat:getpixel(fb, x, y)
    local index = math.floor(y / 8) * fb.stride + x
    local offset = y % 8
    return (fb.buf[index + 1] >> offset) & 0x01
end

function MVLSBFormat:fill_rect(fb, x, y, width, height, color)
    while height > 0 do
        local index = math.floor(y / 8) * fb.stride + x
        local offset = y % 8
        for ww = 0, width - 1 do
            local current = fb.buf[index + ww + 1]
            local mask = ~(0x01 << offset)
            local value = ((color ~= 0) and 1 or 0) << offset
            fb.buf[index + ww + 1] = (current & mask) | value
        end
        y = y + 1
        height = height - 1
    end
end

-- RGB565 format implementation
RGB565Format = {}
RGB565Format.__index = RGB565Format

function RGB565Format:setpixel(fb, x, y, color)
    local index = (x + y * fb.stride) * 2
    fb.buf[index + 1] = (color >> 8) & 0xFF
    fb.buf[index + 2] = color & 0xFF
end

function RGB565Format:getpixel(fb, x, y)
    local index = (x + y * fb.stride) * 2
    return (fb.buf[index + 1] << 8) | fb.buf[index + 2]
end

function RGB565Format:fill_rect(fb, x, y, width, height, color)
    while height > 0 do
        for ww = 0, width - 1 do
            local index = (ww + x + y * fb.stride) * 2
            fb.buf[index + 1] = (color >> 8) & 0xFF
            fb.buf[index + 2] = color & 0xFF
        end
        y = y + 1
        height = height - 1
    end
end

-- FrameBuffer class
FrameBuffer = {}
FrameBuffer.__index = FrameBuffer

function FrameBuffer:new(buf, width, height, buf_format, stride)
    local fb = setmetatable({}, self)
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
    self.format.fill_rect(self.format, self, 0, 0, self.width, self.height, color)
end

function FrameBuffer:fill_rect(x, y, width, height, color)
    if width < 1 or height < 1 or (x + width) <= 0 or (y + height) <= 0 or y >= self.height or x >= self.width then
        return
    end
    local xend = math.min(self.width, x + width)
    local yend = math.min(self.height, y + height)
    x = math.max(x, 0)
    y = math.max(y, 0)
    self.format.fill_rect(self.format, self, x, y, xend - x, yend - y, color)
end

function FrameBuffer:pixel(x, y, color)
    if x < 0 or x >= self.width or y < 0 or y >= self.height then
        return
    end
    if color == nil then
        return self.format.getpixel(self.format, self, x, y)
    else
        self.format.setpixel(self.format, self, x, y, color)
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
    -- Bresenham's line algorithm
    local dx = math.abs(x1 - x0)
    local dy = math.abs(y1 - y0)
    local x, y = x0, y0
    local sx = (x0 < x1) and 1 or -1
    local sy = (y0 < y1) and 1 or -1
    if dx > dy then
        local err = dx / 2
        while x ~= x1 do
            self:pixel(x, y, color)
            err = err - dy
            if err < 0 then
                y = y + sy
                err = err + dx
            end
            x = x + sx
        end
    else
        local err = dy / 2
        while y ~= y1 do
            self:pixel(x, y, color)
            err = err - dx
            if err < 0 then
                x = x + sx
                err = err + dy
            end
            y = y + sy
        end
    end
    self:pixel(x, y, color)
end

function FrameBuffer:blit()
    error("Not implemented")
end

function FrameBuffer:scroll()
    error("Not implemented")
end

function FrameBuffer:text()
    error("Not implemented")
end

--function FrameBuffer:to_bmp()
--    local function int_to_bytes(n, bytes)
--        local res = {}
--        for i = 1, bytes do
--            res[i] = string.char(n % 256)
--            n = math.floor(n / 256)
--        end
--        return table.concat(res)
--    end
--
--    local function get_bmp_header(width, height, filesize)
--        local fileHeader = "BM" .. int_to_bytes(filesize, 4) .. "\0\0\0\0" .. int_to_bytes(54, 4)
--        local dibHeader = int_to_bytes(40, 4) .. int_to_bytes(width, 4) .. int_to_bytes(height, 4) ..
--                          int_to_bytes(1, 2) .. int_to_bytes(24, 2) .. "\0\0\0\0" ..
--                          int_to_bytes(filesize - 54, 4) .. "\x13\x0B\0\0\x13\x0B\0\0\0\0\0\0\0\0\0\0"
--        return fileHeader .. dibHeader
--    end
--
--    local function get_pixel_data(fb)
--        local pixel_data = {}
--        for y = fb.height - 1, 0, -1 do
--            for x = 0, fb.width - 1 do
--                local color
--                if fb.format == MVLSBFormat then
--                    color = fb:pixel(x, y) == 1 and {255, 255, 255} or {0, 0, 0}
--                elseif fb.format == RGB565Format then
--                    local color565 = fb:pixel(x, y)
--                    color = {
--                        ((color565 >> 11) & 0x1F) * 255 / 31,
--                        ((color565 >> 5) & 0x3F) * 255 / 63,
--                        (color565 & 0x1F) * 255 / 31
--                    }
--                end
--                table.insert(pixel_data, string.char(color[3], color[2], color[1]))
--            end
--            -- Pad row to multiple of 4 bytes
--            while (#pixel_data % 4 ~= 0) do
--                table.insert(pixel_data, "\0")
--            end
--        end
--        return table.concat(pixel_data)
--    end
--
--    local pixel_data = get_pixel_data(self)
--    local filesize = 54 + #pixel_data
--    local bmp_header = get_bmp_header(self.width, self.height, filesize)
--    return bmp_header .. pixel_data
--end


--function FrameBuffer:to_bmp()
--    local function int_to_bytes(n, bytes)
--        local res = {}
--        for i = 1, bytes do
--            res[i] = n % 256
--            n = math.floor(n / 256)
--        end
--        return res
--    end
--
--    local function get_bmp_header(width, height, filesize)
--        local fileHeader = {66, 77} -- "BM"
--        for _, v in ipairs(int_to_bytes(filesize, 4)) do table.insert(fileHeader, v) end
--        for _, v in ipairs({0, 0, 0, 0}) do table.insert(fileHeader, v) end
--        for _, v in ipairs(int_to_bytes(54, 4)) do table.insert(fileHeader, v) end
--
--        local dibHeader = {}
--        for _, v in ipairs(int_to_bytes(40, 4)) do table.insert(dibHeader, v) end
--        for _, v in ipairs(int_to_bytes(width, 4)) do table.insert(dibHeader, v) end
--        for _, v in ipairs(int_to_bytes(height, 4)) do table.insert(dibHeader, v) end
--        for _, v in ipairs(int_to_bytes(1, 2)) do table.insert(dibHeader, v) end
--        for _, v in ipairs(int_to_bytes(24, 2)) do table.insert(dibHeader, v) end
--        for _, v in ipairs({0, 0, 0, 0}) do table.insert(dibHeader, v) end
--        for _, v in ipairs(int_to_bytes(filesize - 54, 4)) do table.insert(dibHeader, v) end
--        for _, v in ipairs({19, 11, 0, 0, 19, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}) do table.insert(dibHeader, v) end
--
--        for _, v in ipairs(dibHeader) do table.insert(fileHeader, v) end
--        return fileHeader
--    end
--
--    local function get_pixel_data(fb)
--        local pixel_data = {}
--        for y = fb.height - 1, 0, -1 do
--            for x = 0, fb.width - 1 do
--                local color
--                if fb.format == MVLSBFormat then
--                    color = fb:pixel(x, y) == 1 and {255, 255, 255} or {0, 0, 0}
--                elseif fb.format == RGB565Format then
--                    local color565 = fb:pixel(x, y)
--                    color = {
--                        ((color565 >> 11) & 0x1F) * 255 / 31,
--                        ((color565 >> 5) & 0x3F) * 255 / 63,
--                        (color565 & 0x1F) * 255 / 31
--                    }
--                end
--                table.insert(pixel_data, color[3])
--                table.insert(pixel_data, color[2])
--                table.insert(pixel_data, color[1])
--            end
--            -- Pad row to multiple of 4 bytes
--            while (#pixel_data % 4 ~= 0) do
--                table.insert(pixel_data, 0)
--            end
--        end
--        return pixel_data
--    end
--
--    local pixel_data = get_pixel_data(self)
--    local filesize = 54 + #pixel_data
--    local bmp_header = get_bmp_header(self.width, self.height, filesize)
--    local bmp_data = {}
--
--    for _, v in ipairs(bmp_header) do table.insert(bmp_data, v) end
--    for _, v in ipairs(pixel_data) do table.insert(bmp_data, v) end
--
--    return string.char(table.unpack(bmp_data))
--end


function FrameBuffer:to_bmp()
    local function int_to_bytes(n, bytes)
        local res = {}
        for i = 1, bytes do
            res[i] = n % 256
            n = math.floor(n / 256)
        end
        return res
    end

    local function get_bmp_header(width, height, filesize)
        local fileHeader = {66, 77} -- "BM"
        for _, v in ipairs(int_to_bytes(filesize, 4)) do table.insert(fileHeader, v) end
        for _, v in ipairs({0, 0, 0, 0}) do table.insert(fileHeader, v) end
        for _, v in ipairs(int_to_bytes(54, 4)) do table.insert(fileHeader, v) end

        local dibHeader = {}
        for _, v in ipairs(int_to_bytes(40, 4)) do table.insert(dibHeader, v) end
        for _, v in ipairs(int_to_bytes(width, 4)) do table.insert(dibHeader, v) end
        for _, v in ipairs(int_to_bytes(height, 4)) do table.insert(dibHeader, v) end
        for _, v in ipairs(int_to_bytes(1, 2)) do table.insert(dibHeader, v) end
        for _, v in ipairs(int_to_bytes(24, 2)) do table.insert(dibHeader, v) end
        for _, v in ipairs({0, 0, 0, 0}) do table.insert(dibHeader, v) end
        for _, v in ipairs(int_to_bytes(filesize - 54, 4)) do table.insert(dibHeader, v) end
        for _, v in ipairs({19, 11, 0, 0, 19, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}) do table.insert(dibHeader, v) end

        for _, v in ipairs(dibHeader) do table.insert(fileHeader, v) end
        return fileHeader
    end

    local function get_pixel_data(fb)
        local pixel_data = {}
        for y = fb.height - 1, 0, -1 do
            for x = 0, fb.width - 1 do
                local color
                if fb.format == MVLSBFormat then
                    color = fb:pixel(x, y) == 1 and {255, 255, 255} or {0, 0, 0}
                elseif fb.format == RGB565Format then
                    local color565 = fb:pixel(x, y)
                    color = {
                        ((color565 >> 11) & 0x1F) * 255 / 31,
                        ((color565 >> 5) & 0x3F) * 255 / 63,
                        (color565 & 0x1F) * 255 / 31
                    }
                end
                table.insert(pixel_data, color[3])
                table.insert(pixel_data, color[2])
                table.insert(pixel_data, color[1])
            end
            -- Pad row to multiple of 4 bytes
            while (#pixel_data % 4 ~= 0) do
                table.insert(pixel_data, 0)
            end
        end
        return pixel_data
    end

    local pixel_data = get_pixel_data(self)
    local filesize = 54 + #pixel_data
    local bmp_header = get_bmp_header(self.width, self.height, filesize)
    local bmp_data = {}

    for _, v in ipairs(bmp_header) do table.insert(bmp_data, v) end
    for _, v in ipairs(pixel_data) do table.insert(bmp_data, v) end

    return bmp_data
end


return FrameBuffer