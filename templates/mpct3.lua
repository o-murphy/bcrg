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

    local A = 1
    local B = 1.33
    local C = 1
    local D = 1.66
    local E = 2
    local F = 2
    local G = 1
    local H = 2
    local I = 3
    local J = 0.36
    local K = 0.34
    local L = 10
    local M = 3

    local fb = make_canvas(width, height, 1)
    fb:fill(WHITE)

    fb:c_pixel(0, 0, BLACK)
    fb:c_line(_x(2), 0, _x(80), 0, BLACK)
    fb:c_line(_x(-2), 0, _x(-80), 0, BLACK)
    fb:c_line(0, _y(-2), 0, _y(-40), BLACK)
    fb:c_line(0, _y(2), 0, _y(140), BLACK)

    fb:text("MCPT3", fb.width // 6, fb.height // 5, BLACK)
    print(ax, ay)
    function prect(x, y)
        if ax <= 0.5 and ay <= 0.5 then
            fb:c_ellipse(_x(x), _y(y), _x(F / 4), _y(F / 4), BLACK)
            --fb:c_circle(_x(x), _y(y), _x(F/4)-1, WHITE)
            fb:c_rect(_x(x), _y(y), _x(F / 4), _y(F / 4), WHITE)
            --fb:c_circle(_x(x), _y(y), 3, 3, BLACK)
            --fb:c_rect(_x(x), _y(y), 3, 3, BLACK)
            --fb:c_pixel(_x(x), _y(y), WHITE)
        elseif ax <= 0.9 and ay <= 0.9 then
            fb:c_rect(_x(x), _y(y), 3, 3, BLACK)
            fb:c_pixel(_x(x), _y(y), WHITE)
        else
            fb:c_pixel(_x(x), _y(y), BLACK)
        end
    end

    for x = 10, 80, 10 do
        prect(x, 0)
        prect(-x, 0)
    end

    for y = 10, 40, 10 do
        prect(0, -y)
    end

    for y = 10, 140, 10 do
        prect(0, y)
    end

    for y = 20, 140, 10 do
        for x = 10, 20, 10 do
            prect(x, y)
            prect(-x, y)
        end
    end

    prect(-10, 10)
    prect(10, 10)

    for y = 30, 140, 10 do
        prect(30, y)
        prect(-30, y)
    end

    for y = 60, 140, 10 do
        prect(40, y)
        prect(-40, y)
    end

    for y = 80, 140, 10 do
        prect(50, y)
        prect(-50, y)
    end

    for y = 100, 140, 10 do
        prect(60, y)
        prect(-60, y)
    end

    function horgr(x)
        if ay <= 0.9 then
            fb:c_line(_x(x + 2), 0, _x(x + 2), _y(1), BLACK)
            fb:c_line(_x(x + 8), 0, _x(x + 8), _y(1), BLACK)
            fb:c_line(_x(x + 4), 0, _x(x + 4), _y(1.33), BLACK)
            fb:c_line(_x(x + 6), 0, _x(x + 6), _y(1.33), BLACK)
        end
    end

    function horgr40(x)
        if ay <= 0.9 then
            fb:c_line(_x(x + 4), 0, _x(x + 4), _y(1), BLACK)
            fb:c_line(_x(x + 6), 0, _x(x + 6), _y(1), BLACK)
        end
    end

    for x = 10, 30, 10 do
        horgr(x)
        horgr(x + 40)
        horgr(-x - 10)
        horgr(-x - 50)
    end

    for x = 5, 80, 10 do
        fb:c_line(_x(x), _y(-1), _x(x), 0, BLACK)
        fb:c_line(_x(-x), _y(-1), _x(-x), 0, BLACK)
    end

    fb:c_line(_x(45), _y(-M / 2), _x(45), _y(M / 2), BLACK)
    fb:c_line(_x(-45), _y(-M / 2), _x(-45), _y(M / 2), BLACK)

    for _, x in ipairs({ 1, 2, 4, 5 }) do
        fb:c_line(_x(40 + x * D), _y(-1), _x(40 + x * D), 0, BLACK)
        fb:c_line(-_x(40 + x * D), _y(-1), -_x(40 + x * D), 0, BLACK)
    end

    fb:c_line(_x(2), _y(A), _x(2), 0, BLACK)
    fb:c_line(_x(4), _y(B), _x(4), 0, BLACK)
    fb:c_line(_x(6), _y(D), _x(6), 0, BLACK)
    fb:c_line(_x(8), _y(E), _x(8), 0, BLACK)
    fb:c_line(-_x(2), _y(A), -_x(2), 0, BLACK)
    fb:c_line(-_x(4), _y(B), -_x(4), 0, BLACK)
    fb:c_line(-_x(6), _y(D), -_x(6), 0, BLACK)
    fb:c_line(-_x(8), _y(E), -_x(8), 0, BLACK)

    horgr40(40)
    horgr40(-50)

    function vert(y)
        fb:c_line(_x(-H / 2), _y(y + 2), _x(H / 2), _y(y + 2), BLACK)
        fb:c_line(_x(-I / 2), _y(y + 4), _x(I / 2), _y(y + 4), BLACK)
        fb:c_line(_x(-I / 2), _y(y + 6), _x(I / 2), _y(y + 6), BLACK)
        fb:c_line(_x(-H / 2), _y(y + 8), _x(H / 2), _y(y + 8), BLACK)
    end

    if ax <= 0.9 then
        for y = -40, 130, 10 do
            vert(y)
        end
    end

    function hdotsplus(x, y)
        if ax <= 0.9 then
            fb:c_pixel(_x(x + 2), _y(y), BLACK)
            fb:c_pixel(_x(x + 4), _y(y), BLACK)
            fb:c_pixel(_x(x + 6), _y(y), BLACK)
            fb:c_pixel(_x(x + 8), _y(y), BLACK)
        end
    end

    function hdotsminus(x, y)
        if ax <= 0.9 then
            fb:c_pixel(_x(x - 2), _y(y), BLACK)
            fb:c_pixel(_x(x - 4), _y(y), BLACK)
            fb:c_pixel(_x(x - 6), _y(y), BLACK)
            fb:c_pixel(_x(x - 8), _y(y), BLACK)
        end
    end

    function vdots(x, y)
        if ax <= 0.9 then
            fb:c_pixel(_x(x), _y(y + 2), BLACK)
            fb:c_pixel(_x(x), _y(y + 4), BLACK)
            fb:c_pixel(_x(x), _y(y + 6), BLACK)
            fb:c_pixel(_x(x), _y(y + 8), BLACK)
        end
    end

    for x = 0, 10, 10 do
        hdotsplus(x, 20)
        hdotsminus(-x, 20)
    end

    for y = 30, 40, 10 do
        for x = 0, 20, 10 do
            hdotsplus(x, y)
            hdotsminus(-x, y)
        end
    end

    for x = 0, 20, 10 do
        hdotsplus(x, 50)
        hdotsminus(-x, 50)
    end

    for y = 60, 70, 10 do
        for x = 0, 30, 10 do
            hdotsplus(x, y)
            hdotsminus(-x, y)
        end
    end

    for y = 80, 90, 10 do
        for x = 0, 40, 10 do
            hdotsplus(x, y)
            hdotsminus(-x, y)
        end
    end

    for y = 100, 140, 10 do
        for x = 0, 50, 10 do
            hdotsplus(x, y)
            hdotsminus(-x, y)
        end
    end

    for y = 30, 130, 10 do
        for x = 10, 30, 10 do
            vdots(-x, y)
            vdots(x, y)
        end
    end

    local x = 40
    for s = 60, 100, 20 do
        for y = s, 130, 10 do
            vdots(-x, y)
            vdots(x, y)
        end
        x = x + 10
    end

    fb:c_rect(_x(85) + fb.width / 2, 0, fb.width, _y(M), BLACK)
    fb:c_rect(_x(-85) - fb.width / 2, 0, fb.width, _y(M), BLACK)
    fb:c_rect(0, _y(145) + fb.height / 2, _x(M), fb.height, BLACK)

    if ax <= 0.9 then
        for x = 20, 100, 20 do
            fb:c_text6(tostring(x // 10), _x(x), _y(-5), BLACK)
            fb:c_text6(tostring(x // 10), _x(-x), _y(-5), BLACK)
        end
    end

    return fb:to_bmp_1bit()
end