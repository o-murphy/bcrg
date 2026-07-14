-- Load the framebuffer module
require("reticledraw")

local BLACK = 0
local WHITE = 1

local function round(v)
    -- invert flor and ceil to set high/low precision
    if v < 0 then
        return math.floor(v)
    elseif v > 0 then
        return math.ceil(v)
    else
        return 0
    end
end

function make_reticle(width, height, click_x, click_y, zoom, adjustment)
    local ax = click_x / zoom
    local ay = click_y / zoom

    --local rate = 5.274 --MILs per 18 angle minute
    --local rate_cm = 51.777836626198464 --CmPer100M per 18 angle minute
    --local rate = 9.549
    local ratio = 10.47  -- 1 Ths = 1.06 MIL = 1.047 MRAD = 10.47 CmPer100m

    local function _x(v)
        return round(v * ratio / ax)
    end
    local function _y(v)
        return round(v * ratio / ay)
    end

    local fb = make_canvas(width, height, 1)
    fb:fill(WHITE)

    for r = 20, round(width / 2), 20 do
        fb:c_ellipse(0, 0, _x(r), _y(r), BLACK)
    end

    fb:c_line(-width, 0, _x(- 5), 0, BLACK)
    fb:c_line(width, 0, _x(5), 0, BLACK)
    fb:c_line(0, -height, 0, _y(-5), BLACK)
    fb:c_line(0, height, 0, _y(5), BLACK)

    for r = 10, round(width / 2), 20 do
        fb:c_line(_x(r), _y(5), _x(r), -_y(5), BLACK)
        fb:c_line(_x(-r), _y(5), _x(-r), -_y(5), BLACK)

        fb:c_line(_x(5), _y(r), -_x(5), _y(r), BLACK)
        fb:c_line(_x(5), _y(-r), -_x(5), _y(-r), BLACK)
    end

    for r = 5, round(width / 2), 5 do
        fb:c_line(_x(r), _y(2.5), _x(r), -_y(2.5), BLACK)
        fb:c_line(_x(-r), _y(2.5), _x(-r), -_y(2.5), BLACK)

        fb:c_line(_x(2.5), _y(r), -_x(2.5), _y(r), BLACK)
        fb:c_line(_x(2.5), _y(-r), -_x(2.5), _y(-r), BLACK)
    end

    local function point(r, angle)
        local a = math.rad(angle)
        local x = r * math.cos(a)
        local y = r * math.sin(a)
        return x, y
    end

    for r = 20, round(width / 2), 20 do
        line_size = math.sqrt(2 * (2.5 ^ 2))
        for a = 45, 315, 180 do
            local x2, y2 = point(r , a)
            --fb:c_circle(round(x2), round(y2), 2, BLACK)
            fb:c_line(
                    _x(x2 + line_size / 2),
                    _y(y2 + line_size / 2),
                    _x(x2 - line_size / 2),
                    _y(y2 - line_size / 2),
                    BLACK
           )
        end
        for a = 135, 315, 180 do
            local x2, y2 = point(r , a)
            --fb:c_circle(round(x2), round(y2), 2, BLACK)
            fb:c_line(
                    _x(x2 - line_size / 2),
                    _y(y2 + line_size / 2),
                    _x(x2 + line_size / 2),
                    _y(y2 - line_size / 2),
                    BLACK
           )
        end
    end

    return fb:to_bmp_1bit()
end