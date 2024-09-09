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
    --print(ax, ay)  -- for debug only

    local function _x(v)
        return round(v / ax)
    end
    local function _y(v)
        return round(v / ay)
    end

    local fb = make_canvas(width, height, 1)
    fb:fill(WHITE)

    local _step = 100

    -- step 1 or 2mil ruler
    for i = 0, fb.width, _step do
        fb:c_line(_x(i), _y(-5.0), _x(i), _y(5.0), BLACK)
        fb:c_line(_x(-i), _y(-5.0), _x(-i), _y(5.0), BLACK)
        fb:c_line(_x(-5.0), _y(i), _x(5.0), _y(i), BLACK)
        fb:c_line(_x(-5.0), _y(-i), _x(5.0), _y(-i), BLACK)
    end

    -- step 1 or 2mil ruler
    for i = 50, fb.width, _step do
        fb:c_line(_x(i), _y(-2.5), _x(i), _y(2.5), BLACK)
        fb:c_line(_x(2.5), _y(-i), _x(-2.5), _y(-i), BLACK)
        fb:c_line(_x(-i), _y(-2.5), _x(-i), _y(2.5), BLACK)
        fb:c_line(_x(-2.5), _y(i), _x(2.5), _y(i), BLACK)
    end

    -- numbers ruler
    for i = 100, fb.width, _step do
        fb:c_text6(tostring(i // 10), _x(i), _y(-20), BLACK)
        fb:c_text6(tostring(i // 10), _x(25), _y(-i), BLACK)
        fb:c_text6(tostring(-i // 10), _x(-i), _y(-20), BLACK)
        fb:c_text6(tostring(-i // 10), _x(25), _y(i), BLACK)
    end

    return fb:to_bmp_1bit()
end