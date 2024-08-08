-- Load the framebuffer module
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
    local ax = click_x / zoom
    local ay = click_y / zoom

    --local rate = 5.274 --MILs per 18 angle minute
    --local rate_cm = 51.777836626198464 --CmPer100M per 18 angle minute
    local rate = 9.549

    --local ths = 1 / 6000
    --local ths_in_cm = 10.41

    --local function pxx(v)
    --    return round((v * ths_in_cm) / ax)
    --end
    --
    --local function pxy(v)
    --    return round((v * ths_in_cm) / ay)
    --end

    local function _x(v)
        return round(v / ax)
    end
    local function _y(v)
        return round(v / ay)
    end

    local fb = make_canvas(width, height, 1)
    fb:fill(WHITE)

    for r = 20, round(width / 2), 20 do
        fb:c_ellipse(0, 0, _x(r * rate), _y(r * rate), BLACK)
    end

    fb:c_line(-width, 0, width, 0, BLACK)
    fb:c_line(0, -height, 0, height, BLACK)

    for r = 10, round(width / 2), 20 do
        fb:c_line(_x(r * rate), _y(5 * rate), _x(r * rate), -_y(5 * rate), BLACK)
        fb:c_line(_x(-r * rate), _y(5 * rate), _x(-r * rate), -_y(5 * rate), BLACK)

        fb:c_line(_x(5 * rate), _y(r * rate), -_x(5 * rate), _y(r * rate), BLACK)
        fb:c_line(_x(5 * rate), _y(-r * rate), -_x(5 * rate), _y(-r * rate), BLACK)
    end

    for r = 5, round(width / 2), 5 do
        fb:c_line(_x(r * rate), _y(2.5 * rate), _x(r * rate), -_y(2.5 * rate), BLACK)
        fb:c_line(_x(-r * rate), _y(2.5 * rate), _x(-r * rate), -_y(2.5 * rate), BLACK)

        fb:c_line(_x(2.5 * rate), _y(r * rate), -_x(2.5 * rate), _y(r * rate), BLACK)
        fb:c_line(_x(2.5 * rate), _y(-r * rate), -_x(2.5 * rate), _y(-r * rate), BLACK)
    end
    --
    --local function custom_atan2(y, x)
    --    if x > 0 then
    --        return math.atan(y / x)
    --    elseif x < 0 and y >= 0 then
    --        return math.atan(y / x) + math.pi
    --    elseif x < 0 and y < 0 then
    --        return math.atan(y / x) - math.pi
    --    elseif x == 0 and y > 0 then
    --        return math.pi / 2
    --    elseif x == 0 and y < 0 then
    --        return -math.pi / 2
    --    else
    --        return 0 -- x == 0 and y == 0
    --    end
    --end
    --
    --function find_point_on_circle(x1, y1, r, angle)
    --    --print(x1, y1, r, angle)
    --    -- Перетворимо кут в радіани
    --    local angle_rad = math.rad(angle)
    --
    --    -- Знайдемо кут theta1 в радіанах
    --    local theta1 = custom_atan2(y1, x1)
    --
    --    -- Обчислимо новий кут theta2
    --    local theta2 = theta1 + angle_rad / 2
    --
    --    -- Знайдемо координати точки P2
    --    local x2 = r * math.cos(theta2)
    --    local y2 = r * math.sin(theta2)
    --
    --    return x2, y2
    --end
    --
    --for r = 20, round(width / 2), 20 do
    --    local x2, y2 = find_point_on_circle(0, r, _x(r * rate), 90)
    --    fb:c_circle(round(x2), round(y2), 3, BLACK)
    --end

    local function point(r, angle)
        local a = math.rad(angle)
        local x = r * math.cos(a)
        local y = r * math.sin(a)
        return x, y
    end

    for r = 20, round(width / 2), 20 do
        line_size = math.sqrt(2 * (2.5 ^ 2))
        for a = 45, 315, 180 do
            local x2, y2 = point(r * rate, a)
            --fb:c_circle(round(x2), round(y2), 2, BLACK)
            fb:c_line(
                    _x(x2 + line_size / 2 * rate),
                    _y(y2 + line_size / 2 * rate),
                    _x(x2 - line_size / 2 * rate),
                    _y(y2 - line_size / 2 * rate),
                    BLACK
            )
        end
        for a = 135, 315, 180 do
            local x2, y2 = point(r * rate, a)
            --fb:c_circle(round(x2), round(y2), 2, BLACK)
            fb:c_line(
                    _x(x2 - line_size / 2 * rate),
                    _y(y2 + line_size / 2 * rate),
                    _x(x2 + line_size / 2 * rate),
                    _y(y2 - line_size / 2 * rate),
                    BLACK
            )
        end
    end

    return fb:to_bmp_1bit()
end