-- Load the framebuffer module
require("reticledraw")

local BLACK = 0
local WHITE = 1

local CENTER_SMALL_CROSS = true
local BIAS_ARROWS = true

local function round(v)
    if v < 0 then
        return math.floor(v)
    elseif v > 0 then
        return math.ceil(v)
    else
        return 0
    end
end


local function arrow(fb, x, y, angle_deg, size, wing_angle_deg, color)
    -- Використовуємо локальну функцію округлення для точності
    local function _round(v)
        return math.floor(v + 0.5)
    end

    -- Напрямок стрілки: віднімаємо 90, щоб 0 градусів було "вгору"
    local angle_rad = math.rad(angle_deg - 90)
    local wing_rad = math.rad(wing_angle_deg)

    -- Обчислюємо вектори крил відносно вершини
    -- Ми використовуємо ПЛЮС для розрахунку точок від вершини назад
    -- angle_rad + math.pi повертає вектор у протилежний від "носа" бік
    local base_angle = angle_rad + math.pi
    
    local x1 = x + size * math.cos(base_angle - wing_rad)
    local y1 = y + size * math.sin(base_angle - wing_rad)
    
    local x2 = x + size * math.cos(base_angle + wing_rad)
    local y2 = y + size * math.sin(base_angle + wing_rad)

    -- Малюємо лінії, використовуючи округлення
    fb:line(_round(x), _round(y), _round(x1), _round(y1), color)
    fb:line(_round(x), _round(y), _round(x2), _round(y2), color)
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

    local function c_h_line(x0, x1, y)
        fb:c_line(x0, y, x1, y, BLACK)
    end

    local function c_v_line(y1, y2, x)
        fb:c_line(x, y1, x, y2, BLACK)
    end

    local function c_arrow(x, y, angle)
        arrow(fb, -x+fb.cx, y+fb.cy, angle, 5, 45, BLACK)
    end

    -- Small Cross
    if CENTER_SMALL_CROSS then
        c_h_line(-2, 2, 0)
        c_v_line(-2, 2, 0)
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

    -- Horizontal top lines
    -- Inner:
    c_h_line(brick_offset, brick_offset+brick_width, brick_y)
    c_h_line(-brick_offset, -(brick_offset+brick_width), brick_y)
    -- Outer:
    c_h_line(brick_offset+canoe_cx, brick_offset+canoe_cx+brick_width, brick_y)
    c_h_line(-(brick_offset+canoe_cx), -(brick_offset+canoe_cx+brick_width), brick_y)
    
    -- Vertical lines
    c_v_line(brick_y, brick_y+canoe_ry, brick_offset)
    c_v_line(brick_y, brick_y+canoe_ry, -brick_offset)

    -- Horizontal bootom line
    c_h_line(brick_offset, -brick_offset, brick_y+canoe_ry)

    -- RIGHT ARC (use c_arc, coordinates relative to center)
    -- x = canoe_cx, y = canoe_cy
    fb:c_arc(canoe_cx, canoe_cy, canoe_rx, canoe_ry, 90, 270, BLACK)
    
    -- LEFT ARC (use c_arc, coordinates are relative to center)
    -- x = -canoe_cx, y = canoe_cy
    fb:c_arc(-canoe_cx, canoe_cy, canoe_rx, canoe_ry, 90, 270, BLACK)

    -- Bias
    if BIAS_ARROWS then
        local x1 = canoe_cx-8
        local x2 = canoe_cx+8
        local y = canoe_cy+canoe_ry//3
        c_h_line(x1, x2, y)
        c_h_line(-x1, -x2, y)
        c_arrow(x1, y, 90)
        c_arrow(-x1, y, -90)
    end

    return fb:to_bmp_1bit()
end