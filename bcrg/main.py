from lupa import LuaRuntime


class LuaReticleLoader:
    def __init__(self, filename: str = 'main.lua'):
        self._make_bmp = None
        self._make_fb = None
        self._lua = LuaRuntime(unpack_returned_tuples=True)
        self._load(filename)

    @staticmethod
    def _unpack_lua_table(table):
        return [int(table[i]) for i in range(1, len(table) + 1)]

    def _load(self, filename: str) -> None:
        # Load the Lua script
        with open(filename, 'r') as lua_file:
            lua_code = lua_file.read()
        self._lua.execute(lua_code)
        # Get the function from Lua
        self._make_bmp = self._lua.globals().make_bmp
        self._make_fb = self._lua.globals().make_fb
        self._make_reticle = self._lua.globals().make_reticle

    def make_bmp(self, width, height, bit_depth) -> bytes:
        if self._make_bmp is not None:
            table = self._make_bmp(width, height, bit_depth)
            return bytes(self._unpack_lua_table(table))

    def make_fb(self, width, height, bit_depth) -> bytes:
        if self._make_fb is not None:
            table = self._make_fb(width, height, bit_depth)
            return bytes(self._unpack_lua_table(table))

    def make_reticle(self, width, height, click_x, click_y, zoom, adjustment) -> bytes:
        if self._make_reticle is not None:
            table = self._make_reticle(width, height, click_x, click_y, zoom, adjustment)
            return bytes(self._unpack_lua_table(table))


if __name__ == '__main__':
    # Call the function with desired parameters (e.g., 1-bit depth)
    width, height, bit_depth = 640, 640, 1
    # bmp_bytearray = LuaReticleLoader().make_bmp(
    #     width, height,1    )

    bmp_bytearray = LuaReticleLoader('mrad.lua').make_reticle(
        720,
        576,
        0.355,
        0.355,
        1,
        None
    )

    # Save the bytearray to a BMP file
    with open("../assets/mrad.bmp", "wb") as bmp_file:
        bmp_file.write(bmp_bytearray)

    print("BMP file created successfully!")
