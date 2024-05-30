require("reticledraw")

function make_reticle(width, height, click_x, click_y, zoom, min_x_step, min_y_step, adjustment)
    -- Initialize the frame buffer

    local ax = click_x / zoom
    local ay = click_y / zoom
    print(ax, ay)

    local function round(v)
        if v < 0 then
            return math.floor(v)
        elseif v > 0 then
            return math.ceil(v)
        else
            return 0
        end
    end

    local function adjx(v)
        return round(v / ax)
    end

    local function adjy(v)
        return round(v / ay)
    end

    local fb = make_canvas(width, height, 1)
    fb:fill(1)
    fb:c_line(adjx(1.25), 0, adjx(100), 0, 0)
    fb:c_line(adjx(-1.25), 0, adjx(-100), 0, 0)
    fb:c_line(0, adjy(1.25), 0, adjy(100), 0, 0)
    fb:c_line(0, adjy(-1.25), 0, adjy(-100), 0, 0)

    for i = 10, 100, 10 do
        fb:c_line(adjx(i), adjy(-2.5), adjx(i), adjy(2.5), 0)
        fb:c_line(adjx(-i), adjy(-2.5), adjx(-i), adjy(2.5), 0)
        fb:c_line(adjx(-2.5), adjy(i), adjx(2.5), adjy(i), 0)
        fb:c_line(adjx(-2.5), adjy(-i), adjx(2.5), adjy(-i), 0)
    end

    for i = 10, 40, 10 do
        fb:c_line(adjx(i), adjy(-5), adjx(i), adjy(5), 0)
        fb:c_line(adjx(-i), adjy(-5), adjx(-i), adjy(5), 0)
    end

    -- step 0.5mil
    if ax <= 1.4 then

        for i = 5, 100, 5 do
            fb:c_line(adjx(i), adjy(-1.25), adjx(i), adjy(1.25), 0)
            fb:c_line(adjx(-i), adjy(-1.25), adjx(-i), adjy(1.25), 0)
            fb:c_line(adjx(-1.25), adjy(i), adjx(1.25), adjy(i), 0)
            fb:c_line(adjx(-1.25), adjy(-i), adjx(1.25), adjy(-i), 0)
        end
    end

    --step 0.2mil
    if ax <= 0.6 then
        for i = 2.5, 40, 2.5 do
            fb:c_line(adjx(i), adjy(-1.25), adjx(i), 0, 0)
            fb:c_line(adjx(-i), adjy(-1.25), adjx(-i), 0, 0)
        end
    end

    if ax <= 1.4 then

        for i = 2.5, 20, 2.5 do
            fb:c_pixel(adjx(i), adjy(10), 0, 0)
            fb:c_pixel(adjx(-i), adjy(10), 0, 0)
        end

        for i = 2.5, 20, 2.5 do
            fb:c_pixel(adjx(i), adjy(20), 0, 0)
            fb:c_pixel(adjx(-i), adjy(20), 0, 0)
        end

        for i = 2.5, 30, 2.5 do
            fb:c_pixel(adjx(i), adjy(30), 0, 0)
            fb:c_pixel(adjx(-i), adjy(30), 0, 0)
        end
        for i = 2.5, 30, 2.5 do
            fb:c_pixel(adjx(i), adjy(40), 0, 0)
            fb:c_pixel(adjx(-i), adjy(40), 0, 0)
        end

        for i = 2.5, 40, 2.5 do
            fb:c_pixel(adjx(i), adjy(50), 0, 0)
            fb:c_pixel(adjx(-i), adjy(50), 0, 0)
        end
        for i = 2.5, 40, 2.5 do
            fb:c_pixel(adjx(i), adjy(60), 0, 0)
            fb:c_pixel(adjx(-i), adjy(60), 0, 0)
        end

        for i = 2.5, 50, 2.5 do
            fb:c_pixel(adjx(i), adjy(70), 0, 0)
            fb:c_pixel(adjx(-i), adjy(70), 0, 0)
        end
        for i = 2.5, 50, 2.5 do
            fb:c_pixel(adjx(i), adjy(80), 0, 0)
            fb:c_pixel(adjx(-i), adjy(80), 0, 0)
        end

        for i = 2.5, 60, 2.5 do
            fb:c_pixel(adjx(i), adjy(90), 0, 0)
            fb:c_pixel(adjx(-i), adjy(90), 0, 0)
        end
        for i = 2.5, 60, 2.5 do
            fb:c_pixel(adjx(i), adjy(100), 0, 0)
            fb:c_pixel(adjx(-i), adjy(100), 0, 0)
        end

    end

    for i = -20, 20, 10 do
        fb:c_line(adjx(i), adjy(10 - 0.5), adjx(i), adjy(10 + 0.4), 0)
        fb:c_line(adjx(i), adjy(20 - 0.5), adjx(i), adjy(20 + 0.4), 0)
    end

    for i = -30, 30, 10 do
        fb:c_line(adjx(i), adjy(30 - 0.5), adjx(i), adjy(30 + 0.4), 0)
        fb:c_line(adjx(i), adjy(40 - 0.5), adjx(i), adjy(40 + 0.4), 0)
    end

    for i = -40, 40, 10 do
        fb:c_line(adjx(i), adjy(50 - 0.5), adjx(i), adjy(50 + 0.4), 0)
        fb:c_line(adjx(i), adjy(60 - 0.5), adjx(i), adjy(60 + 0.4), 0)
    end

    for i = -50, 50, 10 do
        fb:c_line(adjx(i), adjy(70 - 0.5), adjx(i), adjy(70 + 0.4), 0)
        fb:c_line(adjx(i), adjy(80 - 0.5), adjx(i), adjy(80 + 0.4), 0)
    end

    for i = -60, 60, 10 do
        fb:c_line(adjx(i), adjy(90 - 0.5), adjx(i), adjy(90 + 0.4), 0)
        fb:c_line(adjx(i), adjy(100 - 0.5), adjx(i), adjy(100 + 0.4), 0)
    end

    return fb:to_bmp()
end