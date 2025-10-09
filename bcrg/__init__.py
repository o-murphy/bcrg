from pathlib import Path

from lupa import LuaRuntime

_LIB_ROOT = Path(__file__).parent.as_posix()


class LuaReticleLoader:
    def __init__(self, filename: str = "main.lua"):
        self._make_reticle = None
        self._get_buffer = None
        self._lua = LuaRuntime(unpack_returned_tuples=True)
        self._load(filename)

    @staticmethod
    def _unpack_lua_table(table):
        return [int(table[i]) for i in range(1, len(table) + 1)]

    def _load(self, filename: str) -> None:
        # Set the Lua package path
        self._lua.execute(f"""
        package.path = package.path .. ";./?.lua;{_LIB_ROOT}/?.lua"
        """)

        # Load the Lua script
        with open(filename, "r") as lua_file:
            lua_code = lua_file.read()
        self._lua.execute(lua_code)
        # Get the function from Lua
        self._get_buffer = self._lua.globals().get_buffer
        self._make_reticle = self._lua.globals().make_reticle

    def make_bmp(self, width, height, click_x, click_y, zoom, adjustment) -> bytes:
        if self._make_reticle is not None:
            table = self._make_reticle(
                width, height, click_x, click_y, zoom, adjustment
            )
            return bytes(self._unpack_lua_table(table))

    def make_buf(self, width, height, click_x, click_y, zoom, adjustment) -> bytes:
        if self._make_reticle is not None:
            table = self._make_reticle(
                width, height, click_x, click_y, zoom, adjustment
            )
            return bytes(self._unpack_lua_table(table))
