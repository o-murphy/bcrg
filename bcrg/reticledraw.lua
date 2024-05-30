-- Load the framebuffer module
require("framebuffer")

ReticleDraw = setmetatable({}, { __index = FrameBuffer })
ReticleDraw.__index = ReticleDraw

function ReticleDraw:new(buf, width, height, buf_format, stride)
    -- Ensure width and height are integers
    width = math.floor(width)  -- Maybe ceil
    height = math.floor(height)  -- Maybe ceil

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
            (self.cx + x) - width,
            (self.cy + y),
            width,
            color
    )
end

function ReticleDraw:c_vline(x, y, height, color)
    self:vline(
            (self.cx + x),
            (self.cy + y) - height,
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
            (self.cx + x0),
            (self.cy + y0),
            (self.cx + x1),
            (self.cy + y1),
            color
    )
end