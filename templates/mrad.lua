require("reticledraw")

local BLACK = 0
local WHITE = 1

local function round(v)
    if v < 0 then
        return math.ceil(v)
    elseif v > 0 then
        return math.floor(v)
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

    -- main cross
    fb:c_line(2, 0, _x(100), 0, BLACK)
    fb:c_line(-2, 0, _x(-100), 0, BLACK)
    fb:c_line(0, 2, 0, _y(100), 0, BLACK)
    fb:c_line(0, -2, 0, _y(-100), 0, BLACK)

    local _step = (ax <= 2.01) and 10 or 20

    -- step 1 or 2mil ruler
    for i = 10, 100, _step do
        fb:c_line(_x(i), _y(-2.5), _x(i), _y(2.5), BLACK)
        fb:c_line(_x(-i), _y(-2.5), _x(-i), _y(2.5), BLACK)
        fb:c_line(_x(-2.5), _y(i), _x(2.5), _y(i), BLACK)
        fb:c_line(_x(-2.5), _y(-i), _x(2.5), _y(-i), BLACK)
    end

    -- step 1 or 2mil ruler
    for i = 10, 40, _step do
        fb:c_line(_x(i), _y(-5), _x(i), _y(5), BLACK)
        fb:c_line(_x(-i), _y(-5), _x(-i), _y(5), BLACK)
    end

    -- step 0.5mil
    if ax <= 1.4 then
        for i = 5, 100, 5 do
            fb:c_line(_x(i), _y(-1.25), _x(i), _y(1.25), BLACK)
            fb:c_line(_x(-i), _y(-1.25), _x(-i), _y(1.25), BLACK)
            fb:c_line(_x(-1.25), _y(i), _x(1.25), _y(i), BLACK)
            fb:c_line(_x(-1.25), _y(-i), _x(1.25), _y(-i), BLACK)
        end
    end

    if ax <= 0.6 then

        --step 0.2mil
        for i = 2.5, 40, 2.5 do
            fb:c_line(_x(i), _y(-1.25), _x(i), 0, BLACK)
            fb:c_line(_x(-i), _y(-1.25), _x(-i), 0, BLACK)
        end

        --step 0.2mil, tree
        local W = 20
        for y = 10, 100, 20 do
            for x = -W, W, 2.5 do
                fb:c_pixel(_x(x), _y(y), 0, BLACK)
                fb:c_pixel(_x(-x), _y(y + 10), 0, BLACK)
            end
            W = W + 10
        end
    end

    --step 1mil, tree
    local W = 20
    for y = 10, 100, 20 do
        for x = -W, W, 10 do
            fb:c_pixel(_x(x), _y(y) - 1, 0, BLACK)
            fb:c_pixel(_x(x), _y(y) + 1, 0, BLACK)
            fb:c_pixel(_x(x), _y(y + 10) - 1, 0, BLACK)
            fb:c_pixel(_x(x), _y(y + 10) + 1, 0, BLACK)
        end
        W = W + 10
    end

    if ax <= 0.9 then
        -- numbers ruler
        for x = 10, 40, 10 do
            fb:c_text6(tostring(x // 10), _x(x), _y(-10), BLACK)
            fb:c_text6(tostring(x // 10), _x(-x), _y(-10), BLACK)
        end

        for x = 60, 100, 20 do
            fb:c_text6(tostring(x // 10), _x(x), _y(-7.5), BLACK)
            fb:c_text6(tostring(x // 10), _x(-x), _y(-7.5), BLACK)
        end

        -- numbers tree
        for y = 20, 100, 20 do
            fb:c_text6(tostring(y // 10), _x(10), _y(-y), BLACK)
        end

        local y = 10
        for x = 25, 65, 10 do
            fb:c_text6(tostring(y // 10), _x(x), _y(y), BLACK)
            fb:c_text6(tostring(y // 10), _x(-x), _y(y), BLACK)
            fb:c_text6(tostring(y // 10 + 1), _x(x), _y(y + 10), BLACK)
            fb:c_text6(tostring(y // 10 + 1), _x(-x), _y(y + 10), BLACK)
            y = y + 20
        end
    end

    return fb:to_bmp_1bit()
end