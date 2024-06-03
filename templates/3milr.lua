require("reticledraw")

function make_reticle(width, height, click_x, click_y, zoom, adjustment)
    -- Initialize the frame buffer

    local BLACK = 0
    local WHITE = 1

    local ax = click_x / zoom
    local ay = click_y / zoom
    --print(ax, ay)  -- for debug only

    local function round(v)
        if v < 0 then
            return math.floor(v)
        elseif v > 0 then
            return math.ceil(v)
        else
            return 0
        end
    end

    local function _x(v)
        return round(v / ax)
    end
    local function _y(v)
        return round(v / ay)
    end

    local fb = make_canvas(width, height, 1)
    fb:fill(WHITE)


    if ax > 1.6 then
        for i = -30, 30, 30 do
            fb:c_rect(_x(i), 0, 3, 3, BLACK)
            fb:c_rect(_x(-i), 0, 3, 3, BLACK)
            fb:c_rect(0, _x(i), 3, 3, BLACK)
        end
        local lines = {
            {1, 0, _x(20), 0, 0},
            {_x(30)+1, 0, _x(50), 0, 0},
            {-1, 0, _x(-20), 0, 0},
            {_x(-30)-1, 0, _x(-50), 0, 0},
            {0, 1, 0, _y(20), 0},
            {0, _y(30)+1, 0, _y(50), 0},
            {0, -1, 0, _y(-20), 0},
            {0, _y(-30)-1, 0, _y(-50), 0},
        }
        for _, c in ipairs(lines) do
            fb:c_line(table.unpack(c))
        end
    end

    if ax <= 1.6 then

        fb:c_line(_x(1), 0, _x(2), 0, 0)
        fb:c_line(0, _y(1), 0, _y(2), 0)
        fb:c_line(_x(-1), 0, _x(-2), 0, 0)
        fb:c_line(0, _y(-1), 0, _y(-2), 0)

        for i = 10, 30, 10 do
            fb:c_rect(_x(i), 0, 3, 3, 0)
            fb:c_rect(_x(-i), 0, 3, 3, 0)
            fb:c_rect(0, _x(i), 3, 3, 0)
        end

        for y = 10, 20, 10 do
            fb:c_rect(0, _x(-y), 3, 3, 0)
        end

        if ax <= 1.1 then
            for i = 5, 25, 10 do
                fb:c_line(_x(i), -1, _x(i), 1, 0)
                fb:c_line(_x(-i), -1, _x(-i), 1, 0)
                fb:c_line(-1, _x(i), 1, _x(i), 0)
            end
            for i = 5, 15, 10 do
                fb:c_line(-1, _x(-i), 1, _x(-i), 0)
            end
        end
    end
    return fb:to_bmp()
end