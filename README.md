# BCRG - Ballistic reticle generator
### Simple tool to generate dynamic ballistics reticles by .lua templates

## Installation
```bash
pip install bcrg
```

## Usage

### As CLI tool
```bash
python -m bcrg 
usage: bcr [-h] [-o OUTPUT] [-W <int>] [-H <int>] [-cx <float>] [-cy <float>] [-z [<int> ...]] [-Z] file

positional arguments:
  file                  Reticle template file in .lua format

options:
  -h, --help            show this help message and exit
  -o OUTPUT, --output OUTPUT
                        Output directory path, defaults to ./
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
  -Z, --zip             Store as .zip

```

### As Imported module
```python
from bcrg import LuaReticleLoader
loader = LuaReticleLoader('my_reticle_template.lua')

# Create 1bit-depth .bmp bytearray
byte_stream = loader.make_bmp(640, 480, 2.27, 2.27, 4, None)
with open("myreticle.bmp", 'b') as f:
    f.write(byte_stream)
```

[//]: # (# Create direct bytearray from lua framebuffer )

[//]: # (byte_stream = loader.make_buf&#40;640, 480, 2.27, 2.27, 4, None&#41;)

### References
* A reticle template have to implement `make_reticle` function, that gets required arguments and have to return `self:to_bmp` or `self:to_bmp_1bit`
* Examples in ./templates dir


