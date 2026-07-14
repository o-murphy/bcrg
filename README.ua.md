# BCRG - Ballistic reticle generator

[![license]](LICENSE)
[![version]][pypi]
[![python]][pypi]
[![Made in Ukraine]][SWUBadge]

### Simple tool to generate dynamic ballistics reticles by .lua templates

[<img src="https://flagicons.lipis.dev/flags/4x3/gb.svg" width="20"/> **English**](./README.md)

-----

## 🌐 Веб-застосунок

Спробуйте генератор сіток прямо в браузері, без встановлення: **[o-murphy.github.io/bcrg](https://o-murphy.github.io/bcrg/)**

-----

## Installation 🚀

Встановіть генератор балістичних сіток **BCRG** за допомогою `pip` (стандартний метод) або новішого інструменту `uv` (рекомендовано для швидкої роботи).

### Встановлення та Оновлення за допомогою uv (Рекомендовано)

Якщо ви використовуєте **uv**, ви можете керувати інструментом напряму:

**Встановлення:**

```bash
uv tool install bcrg
```

**Оновлення:**

```bash
uv tool upgrade bcrg
```

### Встановлення за допомогою pip (Стандартний метод)

Якщо ви використовуєте стандартний Python-менеджер пакетів:

```bash
pip install bcrg
```

**Оновлення:**

```bash
pip install --upgrade bcrg
```

-----

## Usage (Використання)

### As CLI tool (Через командний рядок)

Використовуйте `bcrg` or `python -m bcrg` для генерації зображень сіток (BMP) з Lua-шаблонів:

```bash
usage: bcr [-h] [-o OUTPUT] [-f] [-W <int>] [-H <int>] [-cx <float>] [-cy <float>] [-z [<int> ...]] [-T | -Z] file

positional arguments:
  file                  Reticle template file in .lua format

options:
  -h, --help            show this help message and exit
  -o OUTPUT, --output OUTPUT
                        Output directory path, defaults to ./
  -f, --force           Force overwrite existing files without prompt
  -W <int>, --width <int>
                        Canvas width (px)
  -H <int>, --height <int>
                        Canvas height (px)
  -cx <float>, --click-x <float>
                        Horizontal click size (cm/100m)
  -cy <float>, --click-y <float>
                        Vertical click size (cm/100m)
  -z [<int> ...], --zoom [<int> ...]
                        Zoom value (int)
  -V, --version         show program\'s version number and exit

archiving options:
  -T, --tar             Store as .tar.gz (overrides --zip)
  -Z, --zip             Store as .zip
```

### As Imported module (Як імпортований модуль)

Ви можете інтегрувати генератор безпосередньо у ваш Python-код:

```python
from bcrg import LuaReticleLoader
loader = LuaReticleLoader('my_reticle_template.lua')

# Create 1bit-depth .bmp bytearray
byte_stream = loader.make_bmp(640, 480, 2.27, 2.27, 4, None)
with open("myreticle.bmp", 'wb') as f:
    f.write(byte_stream)
```

### References (Довідкова інформація)

  * A reticle template have to implement `make_reticle` function, that gets required arguments and have to return `self:to_bmp` or `self:to_bmp_1bit`.
  * Examples in `./templates` dir.

-----

## 📐 Reticle Template API (Lua)

Цей розділ детально описує, як створювати Lua-шаблони, використовуючи бібліотеку **ReticleDraw**.

### 🛠️ Структура Файлів Сітки та `make_reticle`

Кожен файл сітки обов'язково має декларувати залежність від `reticledraw`

```lua
-- Завантажуємо framebuffer модуль
require("reticledraw") -- 👈 ЦЕЙ РЯДОК Є КЛЮЧОВИМ!
```

Кожен файл сітки повинен містити єдину функцію `make_reticle`.

```lua
function make_reticle(width, height, click_x, click_y, zoom, adjustment)
    -- ... Ваш код малювання ...
end
```

| Параметр         | Тип      | Опис                                        |
| :--------------- | :------- | :------------------------------------------ |
| **`click_x`**    | `number` | **Ціна кліку (Correction Value)** по осі X. |
| **`zoom`**       | `number` | Поточне **збільшення** прицілу.             |
| **`adjustment`** | `table`  | Додаткові параметри/настройки сітки.        |

### 🚀 Загальний Шаблон Коду та Логіка Масштабування (З Прикладами)

Використовуйте коефіцієнти `ax/ay` та функції `_x(v)`/`_y(v)` для перетворення **одиниць прицілу** (MILs/MOAs) у **пікселі екрана**.

```lua
require("reticledraw")

local BLACK = 0
local WHITE = 1

-- Функція округлення (забезпечує, що піксель буде цілим)
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
    -- 1. Обчислення коефіцієнтів масштабування (AX, AY)
    local ax = click_x / zoom
    local ay = click_y / zoom

    -- 2. Допоміжні функції: перетворюють одиниці прицілу (v) в пікселі
    local function _x(v)
        return round(v / ax)
    end
    local function _y(v)
        return round(v / ay)
    end

    local fb = make_canvas(width, height, 1)
    fb:fill(WHITE)

    -- 3. Приклади малювання елементів сітки:

    -- Центральна точка (3x3 пікселі)
    fb:c_fill_rect(0, 0, 3, 3, BLACK) 

    -- Головна горизонтальна лінія (від -100 до +100 одиниць)
    fb:c_line(_x(-100), 0, _x(100), 0, BLACK) 
    
    -- Динамічні мітки: малюємо лінії кожні 10 одиниць
    local marker_length = 5 -- довжина мітки у пікселях
    local marker_step = 10  -- крок у одиницях прицілу (MILs/MOAs)
    
    for i = marker_step, 50, marker_step do
        -- Лінія вгору
        fb:c_vline(_x(0), _y(i), marker_length, BLACK) 
        -- Лінія вниз
        fb:c_vline(_x(0), _y(-i), marker_length, BLACK) 
        
        -- Цифрові мітки (використовуємо 6x6 шрифт)
        fb:c_text6(tostring(i), _x(5), _y(i), BLACK)
    end

    -- Динамічна адаптація деталізації
    -- Якщо збільшення високе (ax < 0.5), малюємо додаткові мітки кожні 5 одиниць
    if ax < 0.5 then
        for i = 5, 50, 5 do
            -- Маленька точка на 5 одиниць праворуч
            fb:c_pixel(_x(i), _y(-5), BLACK) 
        end
    end
    
    return fb 
end
```

### 🎨 Методи ReticleDraw (Центровані Координати)

Ці методи автоматично малюють відносно центру дисплея (`0,0`).

| Метод                                                       | Опис                                                                              | Приклад                                       |
| :---------------------------------------------------------- | :-------------------------------------------------------------------------------- | :-------------------------------------------- |
| **`fb:c_pixel(x, y, color)`**                               | Малює один піксель.                                                               | `fb:c_pixel(_x(10), _y(10), BLACK)`           |
| **`fb:c_line(x0, y0, x1, y1, color)`**                      | Малює лінію.                                                                      | `fb:c_line(0, 0, _x(50), 0, BLACK)`           |
| **`fb:c_hline(x, y, width, color)`**                        | Малює горизонтальну лінію.                                                        | `fb:c_hline(_x(-50), _y(20), _x(100), BLACK)` |
| **`fb:c_vline(x, y, height, color)`**                       | Малює вертикальну лінію.                                                          | `fb:c_vline(_x(30), _y(-50), _y(100), BLACK)` |
| **`fb:c_rect(x, y, w, h, color)`**                          | Малює контур прямокутника (центр `x, y`).                                         | `fb:c_rect(_x(10), _y(10), 20, 20, BLACK)`    |
| **`fb:c_fill_rect(x, y, w, h, color)`**                     | Малює заповнений прямокутник.                                                     | `fb:c_fill_rect(0, 0, 3, 3, BLACK)`           |
| **`fb:c_circle(x, y, r, color)`**                           | Малює контур кола. `r` — радіус у **пікселях**.                                   | `fb:c_circle(0, _y(30), 5, BLACK)`            |
| **`fb:c_fill_circle(x, y, r, color)`**                      | Малює заповнене коло.                                                             | `fb:c_fill_circle(0, 0, 2, BLACK)`            |
| **`fb:c_text6(s, x, y, color)`**                            | Малює текст шрифтом **6x6** пікселів.                                             | `fb:c_text6("10", _x(10), _y(-10), BLACK)`    |
| **`fb:c_arc(x, y, rx, ry, start_angle, end_angle, color)`** | Малює дугу від `початкового_кутла` до `кінцевого_кутла` (градуси, 0° = 12 годин). | `fb:c_arc(0, 0, 20, 20, 0, 90, BLACK)`        |

### 📐 Успадковані Методи FrameBuffer (Абсолютні Координати)

Ці методи вимагають **абсолютних піксельних координат** (`0,0` — верхній лівий кут).

| Метод                                                       | Вимоги до координат | Опис                                              |
| :---------------------------------------------------------- | :------------------ | :------------------------------------------------ |
| **`fb:pixel(x, y, color)`**                                 | Абсолютні           | Встановлює колір пікселя.                         |
| **`fb:fill(color)`**                                        | Абсолютні           | Заливає весь буфер.                               |
| **`fb:fill_rect(x, y, w, h, c)`**                           | Абсолютні           | Заливає прямокутник.                              |
| **`fb:rect(x, y, w, h, c)`**                                | Абсолютні           | Малює контур прямокутника.                        |
| **`fb:line(x0, y0, x1, y1, color)`**                        | Абсолютні           | Малює довільну лінію.                             |
| **`fb:hline(x, y, w, color)`**                              | Абсолютні           | Малює горизонтальну лінію.                        |
| **`fb:vline(x, y, h, color)`**                              | Абсолютні           | Малює вертикальну лінію.                          |
| **`fb:circle(x, y, r, color)`**                             | Абсолютні           | Малює контур кола.                                |
| **`fb:fill_circle(x, y, r, color)`**                        | Абсолютні           | Малює заповнене коло.                             |
| **`fb:ellipse(x, y, rx, ry, color)`**                       | Абсолютні           | Малює контур еліпса.                              |
| **`fb:polygon(points, color)`**                             | Абсолютні           | Малює заповнений багатокутник.                    |
| **`fb:text(s, x0, y0, col)`**                               | Абсолютні           | Малює текст стандартним шрифтом **8x8** пікселів. |
| **`fb:arc(cx, cy, rx, ry, start_angle, end_angle, color)`** | Абсолютні           | Малює дугу. Кути в градусах, 0° = 12 годин.       |


<!-- REUSABLE LINKS -->

[license]: https://img.shields.io/github/license/o-murphy/bcrg
[version]: https://img.shields.io/pypi/v/bcrg?logo=pypi
[pypi]: https://pypi.org/project/bcrg
[python]: https://img.shields.io/pypi/pyversions/bcrg?logo=python

[web]: https://o-murphy.github.io/bcrg

[Made in Ukraine]: https://img.shields.io/badge/made_in-Ukraine-ffd700.svg?labelColor=0057b7&style=flat-square
[SWUBadge]: https://stand-with-ukraine.pp.ua