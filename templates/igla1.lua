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

    local ratio_3500m = 34 / 2 * 2.13
    local ratio_500m = 243 / 2 * 2.13

    local function _x(v)
        return round(v / ax)
    end
    local function _y(v)
        return round(v / ay)
    end

    local fb = make_canvas(width, height, 1)
    fb:fill(WHITE)

    fb:c_ellipse(0, 0, _x(ratio_3500m), _y(ratio_3500m), BLACK)
    fb:c_ellipse(0, 0, _x(ratio_500m), _y(ratio_500m), BLACK)

    print(zoom, ax, ay)
    if (ax <= 2.12) and (ay <= 2.12) then
        fb:c_text6("3.5km", -_x(ratio_3500m/1.4), _y((ratio_3500m/1.4+4)), BLACK)
        fb:c_text6("0.5km", -_x((ratio_500m/1.4-6)), _y((ratio_500m/1.4-6)), BLACK)
    end

    for i, _ratio in ipairs({ ratio_3500m, ratio_500m }) do

        fb:c_line(
                _x(_ratio / 2 * click_x),
                _y(i * click_y),
                _x(_ratio / 2 * click_x),
                -_y(i * click_y),
                BLACK
        )

        fb:c_line(
                -_x(_ratio / 2 * click_x),
                _y(i * click_y),
                -_x(_ratio / 2 * click_x),
                -_y(i * click_y),
                BLACK
        )

        fb:c_line(
                _x(i * click_x),
                _y(_ratio / 2 * click_y),
                -_x(i * click_x),
                _y(_ratio / 2 * click_y),
                BLACK
        )

        fb:c_line(
                _x(i * click_x),
                -_y(_ratio / 2 * click_y),
                -_x(i * click_x),
                -_y(_ratio / 2 * click_y),
                BLACK
        )

    end

    return fb:to_bmp_1bit()
end