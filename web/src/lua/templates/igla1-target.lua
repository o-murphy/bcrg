-- Load the framebuffer module
require("reticledraw")

local BLACK = 0
local WHITE = 1

local DISPLAY_RULER = true
local DISPLAY_LEGEND = true

-- =============================================================
-- КОНФІГУРАЦІЯ ЦІЛІ (Змініть це значення для перерахунку)
-- =============================================================
local TARGET_SIZE = 3 -- 15 для літака, 3 для Шахеда
-- =============================================================

local function round(v)
    if v < 0 then return math.floor(v)
    elseif v > 0 then return math.ceil(v)
    else return 0 end
end

-- Допоміжна функція малювання сегментів кола
local function draw_dash(fb, rx, ry, a1, a2, color)
    local r1 = math.rad(a1)
    local r2 = math.rad(a2)
    local x1, y1 = rx * math.cos(r1), ry * math.sin(r1)
    local x2, y2 = rx * math.cos(r2), ry * math.sin(r2)
    fb:c_line(round(x1), round(y1), round(x2), round(y2), color)
end

-- Пунктирне коло (для 3.5км та зовнішнього кільця)
local function c_dotted_circle(fb, rx, ry, color, step_deg, dash_deg)
    if rx <= 0 or ry <= 0 then return end
    for a = 0, 90 - dash_deg, step_deg do
        local a1, a2 = a, a + dash_deg
        draw_dash(fb, rx, ry, a1, a2, color)          -- Q1
        draw_dash(fb, rx, ry, 180 - a2, 180 - a1, color) -- Q2
        draw_dash(fb, rx, ry, 180 + a1, 180 + a2, color) -- Q3
        draw_dash(fb, rx, ry, 360 - a2, 360 - a1, color) -- Q4
    end
end

-- Пунктирна лінія для далекомірної шкали (Ruler)
local function dashed_line(fb, x0, y0, x1, y1, color, dash_len, gap_len)
    dash_len, gap_len = dash_len or 5, gap_len or 3
    local period = dash_len + gap_len
    local dx, dy = math.abs(x1 - x0), math.abs(y1 - y0)
    local x, y, dist = x0, y0, 0
    local sx = (x0 < x1) and 1 or -1
    local sy = (y0 < y1) and 1 or -1
    
    if dx > dy then
        local err = dx / 2
        while x ~= x1 do
            if (dist % period) < dash_len then fb:pixel(x, y, color) end
            dist, err, x = dist + 1, err - dy, x + sx
            if err < 0 then y, err = y + sy, err + dx end
        end
    else
        local err = dy / 2
        while y ~= y1 do
            if (dist % period) < dash_len then fb:pixel(x, y, color) end
            dist, err, y = dist + 1, err - dx, y + sy
            if err < 0 then x, err = x + sx, err + dy end
        end
    end
end

function make_reticle(width, height, click_x, click_y, zoom, adjustment)
    local ax = click_x / zoom
    local ay = click_y / zoom

    -- АВТОМАТИЧНИЙ РОЗРАХУНОК ГЕОМЕТРІЇ (см/100м)
    -- Базове коло на 1.5 км
    local dia_1500m = (TARGET_SIZE / 1500) * 10000 
    local radius_1500m = dia_1500m / 2

    -- Далекомірні кола
    local radius_3000m = radius_1500m * (1500 / 3000)
    local radius_3500m = radius_1500m * (1500 / 3500)
    
    -- Зовнішнє обмежувальне коло (в 3 рази більше за основне)
    local big_radius = radius_1500m * 3

    -- Переклад фізичних одиниць у пікселі з захистом від нульового розміру
    local function _px(v)
        local p = round(v / ax)
        if v > 0 and p == 0 then return 1 end -- гарантуємо видимість
        return p
    end
    local function _py(v)
        local p = round(v / ay)
        if v > 0 and p == 0 then return 1 end
        return p
    end

    local fb = make_canvas(width, height, 1)
    fb:fill(WHITE)

    -- 1. Малюємо кола прицілу
    c_dotted_circle(fb, _px(big_radius), _py(big_radius), BLACK, 6, 3) -- Зовнішнє
    fb:c_ellipse(0, 0, _px(radius_1500m), _py(radius_1500m), BLACK)     -- 1.5 км (Л)
    fb:c_ellipse(0, 0, _px(radius_3000m), _py(radius_3000m), BLACK)     -- 3.0 км
    -- c_dotted_circle(fb, _px(radius_3500m), _py(radius_3500m), BLACK, 8, 1) -- 3.5 км

    -- 2. Текстова інформація
    local top_m, left_m, h_sp, v_sp = 100, 60, 20, 15
    fb:text6("IGLA", left_m - 7, top_m - 40, BLACK)
    fb:text6("TARGET: " .. TARGET_SIZE .. "M", left_m - 7, top_m - 25, BLACK)

    -- 3. Легенда (якщо увімкнена)
    if DISPLAY_LEGEND then
        fb:text6("RANGES:", left_m - 7, top_m, BLACK)
        fb:ellipse(left_m, top_m + v_sp, 2, 2, BLACK)
        fb:text6("3.0 KM", left_m + h_sp, top_m + v_sp - 3, BLACK)
        fb:ellipse(left_m, top_m + v_sp*2, 4, 4, BLACK)
        fb:text6("1.5 KM", left_m + h_sp, top_m + v_sp*2 - 3, BLACK)
    end

    -- 4. Далекомірна лінійка (Ruler)
    if DISPLAY_RULER then
        -- Шкала 1.5 км
        dashed_line(fb, left_m, fb.cy - _py(radius_1500m), left_m, fb.cy + _py(radius_1500m), BLACK, 2, 4)
        fb:line(left_m - 3, fb.cy - _py(radius_1500m), left_m + 3, fb.cy - _py(radius_1500m), BLACK)
        fb:line(left_m - 3, fb.cy + _py(radius_1500m), left_m + 3, fb.cy + _py(radius_1500m), BLACK)
        fb:text6("1.5km", left_m + 10, fb.cy + _py(radius_1500m) - 3, BLACK)

        -- Шкала 3 км
        dashed_line(fb, left_m + 25, fb.cy - _py(radius_3000m), left_m + 25, fb.cy + _py(radius_3000m), BLACK, 2, 4)
        fb:line(left_m + 22, fb.cy - _py(radius_3000m), left_m + 28, fb.cy - _py(radius_3000m), BLACK)
        fb:line(left_m + 22, fb.cy + _py(radius_3000m), left_m + 28, fb.cy + _py(radius_3000m), BLACK)
        fb:text6("3km", left_m + 35, fb.cy + _py(radius_3000m) - 3, BLACK)
    end

    return fb:to_bmp_1bit()
end