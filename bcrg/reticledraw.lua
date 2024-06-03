-- Load the framebuffer module
require("framebuf")

ReticleDraw = setmetatable({}, { __index = FrameBuffer })
ReticleDraw.__index = ReticleDraw

function ReticleDraw:new(buf, width, height, buf_format, stride)
    -- Ensure width and height are integers
    width = math.ceil(width)  -- Maybe ceil
    height = math.ceil(height)  -- Maybe ceil

    local self = FrameBuffer.new(self, buf, width, height, buf_format, stride)
    self.cx = self.width // 2
    self.cy = self.height // 2
    return self
end

function ReticleDraw:c_fill_rect(x, y, width, height, color)
    --print(self.cx, self.cy)
    --print((self.cx + x) - (width // 2), (self.cy + y) - (height // 2), width, height)
    self:fill_rect(
            (self.cx + x) - (width // 2),
            (self.cy + y) - (height // 2),
            width,
            height,
            color
    )
end

function ReticleDraw:c_pixel(x, y, color)
    self:pixel(self.cx + x, self.cy + y, color)
end

function ReticleDraw:c_hline(x, y, width, color)
    self:hline(
            (self.cx + x),
            (self.cy + y),
            width,
            color
    )
end

function ReticleDraw:c_vline(x, y, height, color)
    self:vline(
            (self.cx + x),
            (self.cy + y),
            height,
            color
    )
end

function ReticleDraw:true_rect(x, y, width, height, color)
    self:line(x, y, x + width - 1, y, color)
    self:line(x, y, x, y + height - 1, color)
    self:line(x, y + height - 1, x + width - 1, y + height - 1, color)
    self:line(x + width - 1, y + height - 1, x + width - 1, y, color)
end


function ReticleDraw:c_rect(x, y, width, height, color)
    --print((width // 2))
    self:true_rect(
            (self.cx + x) - (width // 2),
            (self.cy + y) - (height // 2),
            width, height, color
    )
end

function ReticleDraw:c_line(x0, y0, x1, y1, color)
    self:line(
            self.cx + x0,
            self.cy + y0,
            self.cx + x1,
            self.cy + y1,
            color
    )
end

function ReticleDraw:c_ellipse(x, y, rx, ry, color)
    self:ellipse_by_center(self.cx + x, self.cy + y, rx, ry, color)
end

function ReticleDraw:c_fill_ellipse(x, y, rx, ry, color)
    self:c_ellipse(self.cx + x, self.cy + y, rx, ry, color)
end

function ReticleDraw:c_circle(x, y, r, color)
    self:ellipse_by_center(self.cx + x, self.cy + y, r, r, color)
end

function ReticleDraw:c_fill_circle(x, y, r, color)
    self:fill_ellipse_by_center(self.cx + x, self.cy + y, r, r, color)
end

function ReticleDraw:c_text6(s, x, y, color)
    local sh = 2
    local l = string.len(s)
    local hw = l * 5.8 // 2
    self:text6(s, self.cx + x - hw, self.cy + y - sh, color)
end

function make_canvas(width, height, bit_depth)
    local buffer_size = (width * height * bit_depth) / 8

    -- Create a buffer for the display
    local buf = {}
    for i = 1, buffer_size do
        buf[i] = 0
    end

    -- Initialize the frame buffer
    local fb = ReticleDraw:new(buf, width, height, bit_depth == 1 and MVLSB or NMLSB)
    return fb
end


function FrameBuffer:get_buffer()
    return self.buf
end


function FrameBuffer:to_bmp_1bit()
    local function int_to_bytes(n, bytes)
        local res = {}
        for i = 1, bytes do
            res[i] = n % 256
            n = math.floor(n / 256)
        end
        return res
    end

    local function get_bmp_header(width, height, filesize, depth)
        local fileHeader = { 66, 77 } -- "BM"
        for _, v in ipairs(int_to_bytes(filesize, 4)) do
            table.insert(fileHeader, v)
        end
        for _, v in ipairs({ 0, 0, 0, 0 }) do
            table.insert(fileHeader, v)
        end
        for _, v in ipairs(int_to_bytes(54 + (depth == 1 and 8 or 0), 4)) do
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
        for _, v in ipairs(int_to_bytes(depth, 2)) do
            table.insert(dibHeader, v)
        end
        for _, v in ipairs({ 0, 0, 0, 0 }) do
            table.insert(dibHeader, v)
        end
        for _, v in ipairs(int_to_bytes(filesize - 54 - (depth == 1 and 8 or 0), 4)) do
            table.insert(dibHeader, v)
        end
        for _, v in ipairs({ 19, 11, 0, 0, 19, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }) do
            table.insert(dibHeader, v)
        end

        if depth == 1 then
            -- Color palette for 1-bit BMP (black and white)
            table.insert(dibHeader, 0) -- black
            table.insert(dibHeader, 0)
            table.insert(dibHeader, 0)
            table.insert(dibHeader, 0)
            table.insert(dibHeader, 255) -- white
            table.insert(dibHeader, 255)
            table.insert(dibHeader, 255)
            table.insert(dibHeader, 0)
        end

        for _, v in ipairs(dibHeader) do
            table.insert(fileHeader, v)
        end
        return fileHeader
    end

    local function get_pixel_data_1bit(fb)
        local pixel_data = {}
        local row_padding = (4 - math.ceil(fb.width / 8) % 4) % 4
        for y = fb.height - 1, 0, -1 do
            local row = {}
            for x = 0, fb.width - 1, 8 do
                local byte = 0
                for bit = 0, 7 do
                    if x + bit < fb.width then
                        local color = fb:pixel(x + bit, y)
                        byte = byte + (color == 1 and 1 or 0) * 2 ^ (7 - bit)
                    end
                end
                table.insert(row, byte)
            end
            for _, v in ipairs(row) do
                table.insert(pixel_data, v)
            end
            for _ = 1, row_padding do
                table.insert(pixel_data, 0)
            end
        end
        return pixel_data
    end

    local pixel_data = get_pixel_data_1bit(self)
    local filesize = 54 + 8 + #pixel_data
    local bmp_header = get_bmp_header(self.width, self.height, filesize, 1)
    local bmp_data = {}

    for _, v in ipairs(bmp_header) do
        table.insert(bmp_data, v)
    end
    for _, v in ipairs(pixel_data) do
        table.insert(bmp_data, v)
    end

    return bmp_data
end