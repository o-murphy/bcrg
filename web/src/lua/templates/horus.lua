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
    fb:c_line(4, 0, _x(100), 0, BLACK)
    fb:c_line(-4, 0, _x(-100), 0, BLACK)
    --fb:c_line(0, 2, 0, _y(100), 0, BLACK)
    fb:c_line(0, -4, 0, _y(-50), 0, BLACK)

    local _step = (ax <= 2.01) and 10 or 20

    -- step 1 or 2mil ruler
    for i = 10, 50, _step do
        fb:c_line(_x(-2.5), _y(-i), _x(2.5), _y(-i), BLACK)
    end

    for i = 10, 100, _step do
        fb:c_line(_x(i), _y(-2.5), _x(i), _y(2.5), BLACK)
        fb:c_line(_x(-i), _y(-2.5), _x(-i), _y(2.5), BLACK)
        --fb:c_line(_x(-2.5), _y(i), _x(2.5), _y(i), BLACK)
    end

    for i = 0, 150, 10 do
        fb:c_pixel(0, _y(i), 0, BLACK)
    end

    -- tree dot 1mil
    for y = 10, 150, 10 do

        local x = 0
        local x1 = 0

        local num = y // 10
        if num > 0 and num <= 4 then
            x = _x(37.5)
            x1 = 30
        end

        if num > 4 and num <= 8 then
            x = _x(47.5)
            x1 = 40
        end

        if num > 8 and num <= 9 then
            x = _x(57.5)
            x1 = 50
        end

        if num > 9 and num <= 15 then
            x = _x(57.5) + 3
            x1 = 50
        end

        if ax <= 0.9 then
            fb:c_text6(tostring(y // 10), x, _y(y), BLACK)
            fb:c_text6(tostring(y // 10), -x, _y(y), BLACK)
        end

        --dots
        if ax <= 0.6 then
            for x2 = 0, x1, 2.5 do
                fb:c_pixel(_x(x2), _y(y), 0, BLACK)
                fb:c_pixel(_x(-x2), _y(y), 0, BLACK)
            end
        end

        for x2 = 10, x1, 10 do
            fb:c_pixel(_x(x2), _y(y) - 1, 0, BLACK)
            fb:c_pixel(_x(-x2), _y(y) - 1, 0, BLACK)
            fb:c_pixel(_x(x2), _y(y) + 1, 0, BLACK)
            fb:c_pixel(_x(-x2), _y(y) + 1, 0, BLACK)
        end
    end


    -- step 0.5mil
    if ax <= 1.4 then

        if ax > 0.35 then
            for i = 5, 100, 10 do
                fb:c_line(_x(i), _y(-1.25), _x(i), _y(1.25), BLACK)
                fb:c_line(_x(-i), _y(-1.25), _x(-i), _y(1.25), BLACK)
            end
        end

        for i = 5, 150, 10 do
            fb:c_line(_x(-1.25), _y(i), _x(1.25), _y(i), BLACK)
        end

        for i = 5, 150, 10 do
            fb:c_line(0, _y(i - 2.75), _x(0), _y(i + 2.75), BLACK)
            fb:c_line(0, _y(i - 2.75), _x(0), _y(i + 2.75), BLACK)
        end

        for i = 10, 150, 10 do
            local shift = 2.5
            fb:c_line(_x(-shift) - 1, _y(i), _x(-shift) + 1, _y(i), BLACK)
            fb:c_line(_x(shift) - 1, _y(i), _x(shift) + 1, _y(i), BLACK)
        end

        fb:c_line(_x(-1.25), _y(-5), _x(1.25), _y(-5), BLACK)
    end

    if ax <= 0.9 then
        -- numbers ruler
        for x = 10, 100, 10 do
            fb:c_text6(tostring(x // 10), _x(x), _y(-10), BLACK)
            fb:c_text6(tostring(x // 10), _x(-x), _y(-10), BLACK)
        end

        ---- numbers tree
        for y = 20, 50, 10 do
            fb:c_text6(tostring(y // 10), _x(10), _y(-y), BLACK)
        end
    end

    if ax <= 0.6 and ax > 0.35 then
        --step 0.2mil
        for i = 2.5, 40, 2.5 do
            fb:c_line(_x(i), _y(1.25), _x(i), 0, BLACK)
            fb:c_line(_x(-i), _y(1.25), _x(-i), 0, BLACK)
        end
    end

    if ax <= 0.35 then
        -- step 0.2mil
        for i = 0, 100, 10 do
            for sw = -1, 1, 2 do
                fb:c_line(sw*_x(i+2), _y(1.25), sw*_x(i+2), 0, BLACK)
                fb:c_line(sw*_x(i+4), _y(-1.25), sw*_x(i+4), 0, BLACK)
                fb:c_line(sw*_x(i+6), _y(-1.25), sw*_x(i+6), 0, BLACK)
                fb:c_line(sw*_x(i+8), _y(1.25), sw*_x(i+8), 0, BLACK)
            end
        end
    end

    return fb:to_bmp_1bit()
end