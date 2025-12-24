# BCRG - Ballistic reticle generator

### Simple tool to generate dynamic ballistics reticles by .lua templates

[<img src="https://flagicons.lipis.dev/flags/4x3/ua.svg" width="20"/> **Українською**](./README.ua.md)

-----

## Installation 🚀

Install the **BCRG** ballistic reticle generator using `pip` (the standard method) or the newer **`uv`** tool (recommended for speed and efficiency).

### Using uv (Recommended)

If you have the **uv** tool installed, you can manage the package directly:

**Installation:**

```bash
uv tool install bcrg
```

**Upgrade:**

```bash
uv tool upgrade bcrg
```

### Using pip (Standard Method)

If you are using the standard Python package manager:

**Installation:**

```bash
pip install bcrg
```

**Upgrade:**

```bash
pip install --upgrade bcrg
```

-----

## Usage

### As CLI tool (Via Command Line)

Use `bcrg` or `python -m bcrg` to generate reticle images (BMP) from Lua templates:

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

### As Imported module

You can integrate the generator directly into your Python code:

```python
from bcrg import LuaReticleLoader
loader = LuaReticleLoader('my_reticle_template.lua')

# Create 1bit-depth .bmp bytearray
# Parameters: width, height, click_x, click_y, zoom, adjustment
byte_stream = loader.make_bmp(640, 480, 2.27, 2.27, 4, None)
with open("myreticle.bmp", 'wb') as f:
    f.write(byte_stream)
```

### References

  * A reticle template has to implement `make_reticle` function, that gets required arguments and has to return `self:to_bmp` or `self:to_bmp_1bit`.
  * Examples in `./templates` dir.

-----

## 📐 Reticle Template API (Lua)

This section details how to create Lua templates using the **ReticleDraw** library, which extends **`FrameBuffer`**.

### 🛠️ Reticle File Structure and `make_reticle`

Every reticle file must declare a dependency on `reticledraw`

```lua
-- Load the framebuffer module
require("reticledraw") -- 👈 THIS LINE IS CRUCIAL!
```

Every reticle file must contain a single `make_reticle` function.

```lua
function make_reticle(width, height, click_x, click_y, zoom, adjustment)
    -- ... Your drawing code ...
end
```

| Parameter | Type | Description |
| :--- | :--- | :--- |
| **`width`** | `number` | Framebuffer (display) width in pixels. |
| **`height`** | `number` | Framebuffer (display) height in pixels. |
| **`click_x`** | `number` | **Click Value (Correction Value)** on the X-axis (e.g., MILs/MOAs per pixel at *minimum* zoom). |
| **`click_y`** | `number` | **Click Value (Correction Value)** on the Y-axis. |
| **`zoom`** | `number` | Current scope **magnification** (zoom value). |
| **`adjustment`** | `table` | Optional additional reticle parameters/settings. |

### 🚀 General Code Template and Scaling Logic (With Examples)

The core logic converts **reticle units** (MILs/MOAs) into **screen pixels** using the scaling coefficients `ax` and `ay`.

```lua
require("reticledraw")

local BLACK = 0
local WHITE = 1

-- Rounding function (ensures the pixel value is an integer)
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
    -- 1. Calculate scaling coefficients (AX, AY)
    -- AX/AY: how many reticle units correspond to 1 pixel on the screen at the current ZOOM.
    local ax = click_x / zoom
    local ay = click_y / zoom

    -- 2. Helper functions: convert reticle units (v) to pixels
    local function _x(v)
        return round(v / ax)
    end
    local function _y(v)
        return round(v / ay)
    end

    local fb = make_canvas(width, height, 1)
    fb:fill(WHITE)

    -- 3. Examples of drawing reticle elements:

    -- Center dot (3x3 pixels)
    fb:c_fill_rect(0, 0, 3, 3, BLACK) 

    -- Main horizontal line (from -100 to +100 units)
    fb:c_line(_x(-100), 0, _x(100), 0, BLACK) 
    
    -- Dynamic markers: drawing lines every 10 units
    local marker_length = 5 -- marker length in pixels
    local marker_step = 10  -- step in reticle units (MILs/MOAs)
    
    for i = marker_step, 50, marker_step do
        -- Line up
        fb:c_vline(_x(0), _y(i), marker_length, BLACK) 
        -- Line down
        fb:c_vline(_x(0), _y(-i), marker_length, BLACK) 
        
        -- Numerical markers (using 6x6 font)
        fb:c_text6(tostring(i), _x(5), _y(i), BLACK)
    end

    -- Dynamic detail adaptation
    -- If zoom is high (ax < 0.5), draw additional markers every 5 units
    if ax < 0.5 then
        for i = 5, 50, 5 do
            -- Small pixel dot at 5 units to the right
            fb:c_pixel(_x(i), _y(-5), BLACK) 
        end
    end
    
    return fb 
end
```

### 🎨 ReticleDraw Methods (Centered Coordinates)

These methods automatically draw relative to the display center (`0,0`). **Always use `_x()` and `_y()`** for all coordinates measured in reticle units.

| Method | Description | Example |
| :--- | :--- | :--- |
| **`fb:c_pixel(x, y, color)`** | Draws a single pixel. | `fb:c_pixel(_x(10), _y(10), BLACK)` |
| **`fb:c_line(x0, y0, x1, y1, color)`** | Draws a line. | `fb:c_line(0, 0, _x(50), 0, BLACK)` |
| **`fb:c_hline(x, y, width, color)`** | Draws a horizontal line. | `fb:c_hline(_x(-50), _y(20), _x(100), BLACK)` |
| **`fb:c_vline(x, y, height, color)`** | Draws a vertical line. | `fb:c_vline(_x(30), _y(-50), _y(100), BLACK)` |
| **`fb:c_rect(x, y, w, h, color)`** | Draws a rectangle outline (center `x, y`). | `fb:c_rect(_x(10), _y(10), 20, 20, BLACK)` |
| **`fb:c_fill_rect(x, y, w, h, color)`**| Draws a filled rectangle. | `fb:c_fill_rect(0, 0, 3, 3, BLACK)` |
| **`fb:c_circle(x, y, r, color)`** | Draws a circle outline. `r` is the radius in **pixels**. | `fb:c_circle(0, _y(30), 5, BLACK)` |
| **`fb:c_fill_circle(x, y, r, color)`** | Draws a filled circle. | `fb:c_fill_circle(0, 0, 2, BLACK)` |
| **`fb:c_text6(s, x, y, color)`** | Draws text using the **6x6** pixel font. | `fb:c_text6("10", _x(10), _y(-10), BLACK)` |
| **`fb:c_arc(x, y, rx, ry, start_angle, end_angle, color)`** | Draws an arc from `start_angle` to `end_angle` (degrees, 0° = 12 o'clock). | `fb:c_arc(0, 0, 20, 20, 0, 90, BLACK)` |


### 📐 Inherited FrameBuffer Methods (Absolute Coordinates)

These methods require **absolute pixel coordinates** (`0,0` is the top-left corner).

| Method | Coordinate Requirement | Description |
| :--- | :--- | :--- |
| **`fb:pixel(x, y, color)`** | Absolute | Sets the color of a pixel. |
| **`fb:fill(color)`** | Absolute | Fills the entire buffer. |
| **`fb:fill_rect(x, y, w, h, c)`** | Absolute | Fills a rectangle. |
| **`fb:rect(x, y, w, h, c)`** | Absolute | Draws a rectangle outline. |
| **`fb:line(x0, y0, x1, y1, color)`**| Absolute | Draws an arbitrary line. |
| **`fb:hline(x, y, w, color)`** | Absolute | Draws a horizontal line. |
| **`fb:vline(x, y, h, color)`** | Absolute | Draws a vertical line. |
| **`fb:circle(x, y, r, color)`** | Absolute | Draws a circle outline. |
| **`fb:fill_circle(x, y, r, color)`** | Absolute | Draws a filled circle. |
| **`fb:ellipse(x, y, rx, ry, color)`** | Absolute | Draws an ellipse outline. |
| **`fb:polygon(points, color)`** | Absolute | Draws a filled polygon. |
| **`fb:text(s, x0, y0, col)`** | Absolute | Draws text using the standard **8x8** pixel font. |
| **`fb:arc(cx, cy, rx, ry, start_angle, end_angle, color)`** | Absolute | Draws an arc. Angles in degrees, 0° = 12 o'clock. |
