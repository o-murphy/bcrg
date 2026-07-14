-- Load the framebuffer module
require("reticledraw")

local BLACK = 0
local WHITE = 1

local DOTTED_CIRCLES = true
local DASHED_CROSS = true
local CENTER_SMALL_CROSS = true

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

-- helper: float range без акумуляції похибок
local function frange(start, stop, step)
    local t = {}
    local v = start
    while v < stop do
        t[#t + 1] = v
        v = start + #t * step  -- обчислюємо від start, а не v += step
    end
    return t
end

local function draw_dash(fb, rx, ry, a1, a2, color)
    local r1 = math.rad(a1)
    local r2 = math.rad(a2)

    local x1 = rx * math.cos(r1)
    local y1 = ry * math.sin(r1)
    local x2 = rx * math.cos(r2)
    local y2 = ry * math.sin(r2)

    fb:c_line(round(x1), round(y1), round(x2), round(y2), color)
end

local function c_dotted_circle(fb, rx, ry, color, step_deg, dash_deg)
    -- працюємо тільки в 0..90
    for a = 0, 90 - dash_deg, step_deg do
        local a1 = a
        local a2 = a + dash_deg

        -- 0..90
        draw_dash(fb, rx, ry,  a1,  a2, color)
        -- 90..180
        draw_dash(fb, rx, ry, 180 - a2, 180 - a1, color)
        -- 180..270
        draw_dash(fb, rx, ry, 180 + a1, 180 + a2, color)
        -- 270..360
        draw_dash(fb, rx, ry, 360 - a2, 360 - a1, color)
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

    -- Circles
    for r = 20, round(width / 2), 20 do
        if DOTTED_CIRCLES then
            c_dotted_circle(fb, _x(r), _y(r), BLACK, _x(0.6), _x(0.2))
        else
            fb:c_ellipse(0, 0, _x(r), _y(r), BLACK)
        end
    end

    -- Small Cross
    if CENTER_SMALL_CROSS then
        fb:c_line(-1, 0, 1, 0, BLACK)
        fb:c_line(0, -1, 0, 1, BLACK)
    end

    -- Cross
    if DASHED_CROSS then
        
    else
        fb:c_line(-width, 0, _x(-5), 0, BLACK)
        fb:c_line(width, 0, _x(5), 0, BLACK)
        fb:c_line(0, -height, 0, _y(-5), BLACK)
        fb:c_line(0, height, 0, _y(5), BLACK)
    end

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

    if DASHED_CROSS then
        local s_ = 2.5 / 2
        for _, r in ipairs(frange(2.5, math.floor(width / 2), 5)) do
            fb:c_line(_x(r), _y(s_), _x(r), -_y(s_), BLACK)
            fb:c_line(_x(-r), _y(s_), _x(-r), -_y(s_), BLACK)
            fb:c_line(_x(s_), _y(r), -_x(s_), _y(r), BLACK)
            fb:c_line(_x(s_), _y(-r), -_x(s_), _y(-r), BLACK)
        end

        for _, r in ipairs(frange(1.25, math.floor(width / 2), 2.5)) do
            fb:c_line(_x(r), 0, _x(r), 0, BLACK)
            fb:c_line(_x(-r), 0, _x(-r), 0, BLACK)
            fb:c_line(0, _y(r), 0, _y(r), BLACK)
            fb:c_line(0, _y(-r), 0, _y(-r), BLACK)
        end
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
            local x2, y2 = point(r, a)
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
            local x2, y2 = point(r, a)
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

    -- radial lines

    --local rlo = 5
    --local rhi = 100
    --for th = 0, 360, 30 do
    --    local tha = math.rad(th)
    --    fb:c_line(
    --        _x(rlo * math.cos(tha)),
    --        _y(rlo * math.sin(tha)),
    --        _x(rhi * math.cos(tha)),
    --        _y(rhi * math.sin(tha)),
    --        BLACK
    --    )
    --end

    --local rlo = 10
    --local rhi = 100
    --local dotLength = 1  -- Length of each dot
    --local spaceLength = 2  -- Space between dots
    --
    --for th = 0, 360, 30 do
    --    if th % 90 == 0 then
    --        goto continue
    --    end
    --
    --    local tha = math.rad(th)
    --    local x0 = rlo * math.cos(tha)
    --    local y0 = rlo * math.sin(tha)
    --    local x1 = rhi * math.cos(tha)
    --    local y1 = rhi * math.sin(tha)
    --
    --    -- Calculate the total length of the line
    --    local lineLength = math.sqrt((x1 - x0)^2 + (y1 - y0)^2)
    --
    --    -- Calculate the number of dots that fit in the line
    --    local numDots = math.floor(lineLength / (dotLength + spaceLength))
    --
    --    -- Draw the dots
    --    for i = 0, numDots - 1 do
    --        local fraction = i / numDots
    --        local x0Dot = x0 + fraction * (x1 - x0)
    --        local y0Dot = y0 + fraction * (y1 - y0)
    --        local x1Dot = x0Dot + dotLength * (x1 - x0) / lineLength
    --        local y1Dot = y0Dot + dotLength * (y1 - y0) / lineLength
    --        fb:c_line(_x(x0Dot), _y(y0Dot), _x(x1Dot), _y(y1Dot), BLACK)
    --    end
    --
    --    ::continue::
    --end

    local rhi = 100
    local rd = 10
    local st = 10
    for th = 0, 360, 30 do
        if th % 90 == 0 then
            goto continue
        end

        local tha = math.rad(th)
        local rlo = 10

        for i = _x(rlo), _x(rhi), rd+st do
            fb:c_line(
                math.floor(i * math.cos(tha)),
                math.floor(i * math.sin(tha)),
                math.floor((i + rd) * math.cos(tha)),
                math.floor((i + rd) * math.sin(tha)),
                BLACK
            )
            rlo = rlo + st
        end

        ::continue::
    end

    return fb:to_bmp_1bit()
end