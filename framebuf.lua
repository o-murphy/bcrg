-- framebuffer.lua
local Framebuffer = {}
Framebuffer.__index = Framebuffer

function Framebuffer:new(width, height)
    local self = setmetatable({}, Framebuffer)
    self.width = width
    self.height = height
    self.buffer = {}
    for y = 1, height do
        self.buffer[y] = {}
        for x = 1, width do
            self.buffer[y][x] = {0, 0, 0} -- Initialize to black
        end
    end
    return self
end

function Framebuffer:set_pixel(x, y, r, g, b)
    if x > 0 and x <= self.width and y > 0 and y <= self.height then
        self.buffer[y][x] = {r, g, b}
    end
end

function Framebuffer:save_bmp(filename)
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
    for y = self.height, 1, -1 do
        for x = 1, self.width do
            local pixel = self.buffer[y][x]
            file:write(string.char(pixel[3], pixel[2], pixel[1])) -- BGR format
        end
        file:write(string.rep("\0", pad)) -- Padding
    end

    file:close()
end

return Framebuffer
