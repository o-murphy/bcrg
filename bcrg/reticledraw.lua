-- Load the framebuffer module
require("framebuffer")

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
            width,
            color
    )
end

function ReticleDraw:c_rect(x, y, width, height, color)
    self:rect(
            (self.cx + x) - (width // 2),
            (self.cy + y) - (height // 2),
            width, height, color
    )
end

function ReticleDraw:c_rect(x, y, width, height, color)
    self:rect(
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
