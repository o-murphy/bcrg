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

    fb:c_line(-width, 0, _x(-5), 0, BLACK)
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