require("reticledraw")

local BLACK = 0
local WHITE = 1

local function round(v)
    if v < 0 then
        return math.floor(v)
    elseif v > 0 then
        return math.ceil(v)
    else
        return 0
    end
end

function make_reticle(width, height, click_x, click_y, zoom, adjustment)
    -- Initialize the frame buffer

    local ax = click_x / zoom
    local ay = click_y / zoom

    local function _x(v)
        return round(v / ax)
    end
    local function _y(v)
        return round(v / ay)
    end

    local fb = make_canvas(width, height, 1)
    fb:fill(WHITE)

    fb:c_line(0, 0, -7, 7, BLACK)
    fb:c_line(0, 0, 7, 7, BLACK)
    fb:c_line(-4, 5, -6, 7, BLACK)
    fb:c_line(4, 5, 6, 7, BLACK)

    return fb:to_bmp_1bit()
end