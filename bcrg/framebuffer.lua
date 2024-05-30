-- framebuffer._lua

require("font")

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

--function FrameBuffer:text()
--    error("Not implemented")
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
        local fileHeader = { 66, 77 } -- "BM"
        for _, v in ipairs(int_to_bytes(filesize, 4)) do
            table.insert(fileHeader, v)
        end
        for _, v in ipairs({ 0, 0, 0, 0 }) do
            table.insert(fileHeader, v)
        end
        for _, v in ipairs(int_to_bytes(54, 4)) do
            table.insert(fileHeader, v)
        end

        local dibHeader = {}
        for _, v in ipairs(int_to_bytes(40, 4)) do
            table.insert(dibHeader, v)
        end
        for _, v in ipairs(int_to_bytes(width, 4)) do
            table.insert(dibHeader, v)
        end
        for _, v in ipairs(int_to_bytes(height, 4)) do
            table.insert(dibHeader, v)
        end
        for _, v in ipairs(int_to_bytes(1, 2)) do
            table.insert(dibHeader, v)
        end
        for _, v in ipairs(int_to_bytes(24, 2)) do
            table.insert(dibHeader, v)
        end
        for _, v in ipairs({ 0, 0, 0, 0 }) do
            table.insert(dibHeader, v)
        end
        for _, v in ipairs(int_to_bytes(filesize - 54, 4)) do
            table.insert(dibHeader, v)
        end
        for _, v in ipairs({ 19, 11, 0, 0, 19, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }) do
            table.insert(dibHeader, v)
        end

        for _, v in ipairs(dibHeader) do
            table.insert(fileHeader, v)
        end
        return fileHeader
    end

    local function get_pixel_data(fb)
        local pixel_data = {}
        for y = fb.height - 1, 0, -1 do
            for x = 0, fb.width - 1 do
                local color
                if fb.format == MVLSBFormat then
                    color = fb:pixel(x, y) == 1 and { 255, 255, 255 } or { 0, 0, 0 }
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

    for _, v in ipairs(bmp_header) do
        table.insert(bmp_data, v)
    end
    for _, v in ipairs(pixel_data) do
        table.insert(bmp_data, v)
    end

    return bmp_data
end

function FrameBuffer:ellipse(x0, y0, a, b, color)
    local x = 0
    local y = b
    local a2 = a * a
    local b2 = b * b
    local crit1 = -(a2 / 4 + a % 2 + b2)
    local crit2 = -(b2 / 4 + b % 2 + a2)
    local crit3 = -(b2 / 4 + b % 2)
    local t = -a2 * y
    local dxt = 2 * b2 * x
    local dyt = -2 * a2 * y
    local d2xt = 2 * b2
    local d2yt = 2 * a2

    while y >= 0 and x <= a do
        self:pixel(x0 + x, y0 + y, color)
        self:pixel(x0 - x, y0 + y, color)
        self:pixel(x0 + x, y0 - y, color)
        self:pixel(x0 - x, y0 - y, color)
        if t + b2 * x <= crit1 or t + a2 * y <= crit3 then
            x = x + 1
            dxt = dxt + d2xt
            t = t + dxt
        elseif t - a2 * y > crit2 then
            y = y - 1
            dyt = dyt + d2yt
            t = t + dyt
        else
            x = x + 1
            dxt = dxt + d2xt
            t = t + dxt
            y = y - 1
            dyt = dyt + d2yt
            t = t + dyt
        end
    end
end

function FrameBuffer:fill_ellipse_by_center(cx, cy, rx, ry, color)
    local x = 0
    local y = ry
    local rx2 = rx * rx
    local ry2 = ry * ry
    local crit1 = -(rx2 / 4 + rx % 2 + ry2)
    local crit2 = -(ry2 / 4 + ry % 2 + rx2)
    local crit3 = -(ry2 / 4 + ry % 2)
    local t = -rx2 * y
    local dxt = 2 * ry2 * x
    local dyt = -2 * rx2 * y
    local d2xt = 2 * ry2
    local d2yt = 2 * rx2

    while y >= 0 and x <= rx do
        for i = cx - x, cx + x do
            self:pixel(i, cy + y, color)
            self:pixel(i, cy - y, color)
        end
        if t + ry2 * x <= crit1 or t + rx2 * y <= crit3 then
            x = x + 1
            dxt = dxt + d2xt
            t = t + dxt
        elseif t - rx2 * y > crit2 then
            y = y - 1
            dyt = dyt + d2yt
            t = t + dyt
        else
            x = x + 1
            dxt = dxt + d2xt
            t = t + dxt
            y = y - 1
            dyt = dyt + d2yt
            t = t + dyt
        end
    end
end

function FrameBuffer:ellipse_by_center(cx, cy, rx, ry, color)
    local x = 0
    local y = ry
    local rx2 = rx * rx
    local ry2 = ry * ry
    local crit1 = -(rx2 / 4 + rx % 2 + ry2)
    local crit2 = -(ry2 / 4 + ry % 2 + rx2)
    local crit3 = -(ry2 / 4 + ry % 2)
    local t = -rx2 * y
    local dxt = 2 * ry2 * x
    local dyt = -2 * rx2 * y
    local d2xt = 2 * ry2
    local d2yt = 2 * rx2

    while y >= 0 and x <= rx do
        self:pixel(cx + x, cy + y, color)
        self:pixel(cx - x, cy + y, color)
        self:pixel(cx + x, cy - y, color)
        self:pixel(cx - x, cy - y, color)
        if t + ry2 * x <= crit1 or t + rx2 * y <= crit3 then
            x = x + 1
            dxt = dxt + d2xt
            t = t + dxt
        elseif t - rx2 * y > crit2 then
            y = y - 1
            dyt = dyt + d2yt
            t = t + dyt
        else
            x = x + 1
            dxt = dxt + d2xt
            t = t + dxt
            y = y - 1
            dyt = dyt + d2yt
            t = t + dyt
        end
    end
end

function FrameBuffer:polyline(points, color)
    if not points or #points < 2 then
        error("Invalid points table passed to polyline method")
    end

    for i = 1, #points - 1 do
        local p1 = points[i]
        local p2 = points[i + 1]
        self:line(p1[1], p1[2], p2[1], p2[2], color)
    end
    -- Close the polygon by connecting the last point to the first
    local p1 = points[#points]
    local p2 = points[1]
    self:line(p1[1], p1[2], p2[1], p2[2], color)
end


function FrameBuffer:polygon(points, color)
    -- Draw the edges of the polygon
    self:polyline(points, color)

    -- Fill the polygon using scanline fill algorithm
    local minY = math.huge
    local maxY = -math.huge

    for _, p in ipairs(points) do
        if p[2] < minY then minY = p[2] end
        if p[2] > maxY then maxY = p[2] end
    end

    for y = minY, maxY do
        local nodes = {}

        local j = #points
        for i = 1, #points do
            local pi = points[i]
            local pj = points[j]
            if (pi[2] < y and pj[2] >= y) or (pj[2] < y and pi[2] >= y) then
                local x = pi[1] + (y - pi[2]) / (pj[2] - pi[2]) * (pj[1] - pi[1])
                table.insert(nodes, x)
            end
            j = i
        end

        table.sort(nodes)

        for i = 1, #nodes - 1, 2 do
            for x = math.floor(nodes[i]), math.floor(nodes[i + 1]) do
                self:pixel(x, y, color)
            end
        end
    end
end



-- Custom bitwise operations
function bit_band(a, b)
    local result = 0
    local bitval = 1
    while a > 0 and b > 0 do
        local abit = a % 2
        local bbit = b % 2
        if abit + bbit > 1 then
            result = result + bitval
        end
        bitval = bitval * 2
        a = math.floor(a / 2)
        b = math.floor(b / 2)
    end
    return result
end

function bit_lshift(a, b)
    return a * 2^b
end


function FrameBuffer:text(s, x0, y0, col)
    col = col or 1
    for i = 1, #s do
        local chr = string.byte(s, i)
        if chr < 32 or chr > 127 then
            chr = 127
        end
        local chr_data = {}
        for j = 0, 7 do
            chr_data[j+1] = font_petme128_8x8[(chr - 32) * 8 + j + 1]
        end
        for j = 1, 8 do
            if x0 + j - 1 >= self.width then
                break
            end
            local vline_data = chr_data[j]
            for bit = 0, 7 do
                if bit_band(vline_data, bit_lshift(1, bit)) ~= 0 then
                    local y = y0 + bit
                    if y >= 1 and y <= self.height then
                        self:pixel(x0 + j - 1, y, col)
                    end
                end
            end
        end
        x0 = x0 + 8
    end
end

function FrameBuffer:text6(s, x0, y0, col)
    col = col or 1
    for i = 1, #s do
        local chr = string.byte(s, i)
        if chr < 32 or chr > 127 then
            chr = 127
        end
        local chr_data = {}
        for j = 0, 5 do
            chr_data[j+1] = font_128_6x6[(chr - 32) * 6 + j + 1]
        end
        for j = 1, 6 do
            if x0 + j - 1 >= self.width then
                break
            end
            local vline_data = chr_data[j]
            for bit = 0, 5 do
                if bit_band(vline_data, bit_lshift(1, bit)) ~= 0 then
                    local y = y0 + bit
                    if y >= 1 and y <= self.height then
                        self:pixel(x0 + j - 1, y, col)
                    end
                end
            end
        end
        x0 = x0 + 6
    end
end

return FrameBuffer