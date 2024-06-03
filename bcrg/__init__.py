import os
from lupa import LuaRuntime
from pathlib import Path


_LIB_ROOT = Path(__file__).parent.as_posix()


class LuaReticleLoader:
    def __init__(self, filename: str = 'main.lua'):
        # self._make_bmp = None
        # self._make_fb = None
        self._make_reticle = None
        self._get_buffer = None
        self._lua = LuaRuntime(unpack_returned_tuples=True)
        self._load(filename)

    @staticmethod
    def _unpack_lua_table(table):
        return [int(table[i]) for i in range(1, len(table) + 1)]

    def _load(self, filename: str) -> None:
        # Load the Lua script

        # Set the Lua package path
        self._lua.execute(f"""
        package.path = package.path .. ";./?.lua;{_LIB_ROOT}/?.lua"
        """)

        with open(filename, 'r') as lua_file:
            lua_code = lua_file.read()
        self._lua.execute(lua_code)
        # Get the function from Lua
        # self._make_bmp = self._lua.globals().make_bmp
        # self._make_fb = self._lua.globals().make_fb
        self._get_buffer = self._lua.globals().get_buffer
        self._make_reticle = self._lua.globals().make_reticle

    def make_bmp(self, width, height, click_x, click_y, zoom, adjustment) -> bytes:
        if self._make_reticle is not None:
            table = self._make_reticle(width, height, click_x, click_y, zoom, adjustment)
            return bytes(self._unpack_lua_table(table))

    def make_buf(self, width, height, click_x, click_y, zoom, adjustment) -> bytes:
        if self._make_reticle is not None:
            table = self._make_reticle(width, height, click_x, click_y, zoom, adjustment)
            return bytes(self._unpack_lua_table(table))


# def loop():
#     os.makedirs("../assets/mrad", exist_ok=True)
#
#     lua_ = LuaReticleLoader('mrad.lua')
#
#     ret = []
#
#     for i in range(10, 510, 10):
#         c = i / 100
#         bmp_bytearray = lua_.make_buf(
#             640,
#             640,
#             c, c, 1,
#             None
#         )
#         ret.append((c, bmp_bytearray))
#     return ret
#
#
# def save(ret):
#     print(len(ret))
#     for c, b in ret:
#         with open(f"../assets/mrad/mrad_{c:.2f}.bmp", "wb") as bmp_file:
#             bmp_file.write(b)


# def main():
#
#     bmp_bytearray = LuaReticleLoader('3milr.lua').make_reticle(
#         720,
#         576,
#         2.27,
#         2.27,
#         4,
#         None
#     )
#
#     # Save the bytearray to a BMP file
#     with open("../assets/3milr.bmp", "wb") as bmp_file:
#         bmp_file.write(bmp_bytearray)
#
#     print("BMP file created successfully!")
#
#
# if __name__ == '__main__':
#     from timeit import timeit
#     print(timeit(loop, number=1))

