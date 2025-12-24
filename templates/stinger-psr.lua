-- Load the framebuffer module
require("reticledraw")

local BLACK = 0
local WHITE = 1

local CENTER_SMALL_CROSS = true

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
    
    local fb = make_canvas(width, height, 1)
    fb:fill(WHITE)

    local ax = click_x / zoom
    local ay = click_y / zoom
    --print(ax, ay)  -- for debug only

    local function _x(v)
        return round(v / ax)
    end
    local function _y(v)
        return round(v / ay)
    end

    -- Small Cross
    if CENTER_SMALL_CROSS then
        fb:c_line(-2, 0, 2, 0, BLACK)
        fb:c_line(0, -2, 0, 2, BLACK)
    end

    -- Focusing arc
    fb:c_arc(0, -_y(565), 10, 10, -165, 165, BLACK)

    local brick_spacing = _x(565)
    local brick_offset = brick_spacing//2
    local brick_width = _x(282)
    local brick_y = _y(451)
    
    local canoe_rx = _x(282)
    local canoe_ry = _y(282)

    local canoe_cx = brick_offset + brick_width + canoe_rx
    local canoe_cy = brick_y

    fb:c_line(brick_offset, brick_y, brick_offset+brick_width, brick_y, BLACK)
    fb:c_line(-brick_offset, brick_y, -(brick_offset+brick_width), brick_y, BLACK)

    fb:c_line(brick_offset, brick_y, brick_offset, fb.cx, BLACK)
    fb:c_line(-brick_offset, brick_y, -brick_offset, fb.cy, BLACK)

    -- ПРАВА ДУГА (використовуємо c_arc, координати відносні центру)
    -- x = canoe_cx, y = canoe_cy
    fb:c_arc(canoe_cx, canoe_cy, canoe_rx, canoe_ry, 90, 270, BLACK)
    
    -- ЛІВА ДУГА (використовуємо c_arc, координати відносні центру)
    -- x = -canoe_cx, y = canoe_cy
    fb:c_arc(-canoe_cx, canoe_cy, canoe_rx, canoe_ry, 90, 270, BLACK)

    return fb:to_bmp_1bit()
end