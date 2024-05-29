from lupa import LuaRuntime
import struct

def generate_bmp_from_buffer(buffer, width, height):
    # BMP file header
    file_size = 14 + 40 + (width * height // 8)
    bmp_header = struct.pack('<2sIHHI', b'BM', file_size, 0, 0, 54)

    # DIB header for BMP
    dib_header = struct.pack('<IIIHHIIIIII',
                             40,        # DIB header size
                             width,     # Width
                             height,    # Height
                             1,         # Color planes
                             1,         # Bits per pixel
                             0,         # Compression
                             width * height // 8,  # Image size
                             0, 0, 0, 0)  # Pixels per meter, total colors, important colors

    # Pixel array (inverting the buffer)
    pixel_data = bytearray(buffer)

    # Write to BMP file
    with open('framebuffer.bmp', 'wb') as f:
        f.write(bmp_header)
        f.write(dib_header)
        f.write(pixel_data)

# Initialize Lua runtime
lua = LuaRuntime(unpack_returned_tuples=True)

# Load Lua script
with open('draw.lua', 'r') as file:
    lua_code = file.read()

# Execute Lua script and get the buffer
buffer = lua.execute(lua_code)

# Generate BMP file from buffer
generate_bmp_from_buffer(buffer, 640, 640)