import os
import argparse
from lupa import LuaRuntime


class LuaReticleLoader:
    def __init__(self, filename: str = 'main.lua'):
        self._make_bmp = None
        self._make_fb = None
        self._make_reticle = None
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
        # self._make_bmp = self._lua.globals().make_bmp
        # self._make_fb = self._lua.globals().make_fb
        self._make_reticle = self._lua.globals().make_reticle

    # def make_bmp(self, width, height, bit_depth) -> bytes:
    #     if self._make_bmp is not None:
    #         table = self._make_bmp(width, height, bit_depth)
    #         return bytes(self._unpack_lua_table(table))
    #
    # def make_fb(self, width, height, bit_depth) -> bytes:
    #     if self._make_fb is not None:
    #         table = self._make_fb(width, height, bit_depth)
    #         return bytes(self._unpack_lua_table(table))

    def make_reticle(self, width, height, click_x, click_y, zoom, adjustment) -> bytes:
        if self._make_reticle is not None:
            table = self._make_reticle(width, height, click_x, click_y, zoom, adjustment)
            return bytes(self._unpack_lua_table(table))


def loop():
    os.makedirs("../assets/mrad", exist_ok=True)

    lua_ = LuaReticleLoader('mrad.lua')

    ret = []

    for i in range(10, 510, 10):
        c = i / 100
        bmp_bytearray = lua_.make_reticle(
            640,
            640,
            c, c, 1,
            None
        )
        ret.append((c, bmp_bytearray))
    return ret


def save(ret):
    print(len(ret))
    for c, b in ret:
        with open(f"../assets/mrad/mrad_{c:.2f}.bmp", "wb") as bmp_file:
            bmp_file.write(b)


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


def main():
    parser = argparse.ArgumentParser(prog="bcr")
    parser.add_argument("file", action='store')
    parser.add_argument('-o', '--output', action='store', required=True)
    parser.add_argument('-wh', '--width', action='store',
                        help="Canvas width (px)", type=int, metavar="<int>")
    parser.add_argument('-ht', '--height', action='store',
                        help="Canvas height (px)", type=int, metavar="<int>")
    parser.add_argument('-cx', '--click-x', action='store',
                        help="Horizontal click size (cm/100m)", type=float, metavar="<float>")
    parser.add_argument('-cy', '--click-y', action='store',
                        help="Vertical click size (cm/100m)", type=float, metavar="<float>")
    parser.add_argument('-z', '--zoom', action='store', default=1,
                        help="Zoom value (int)", type=int, metavar="<int>")
    # parser.add_argument('-b', '--background', action='store',
    #                     help="Change background color")
    # parser.add_argument('-inv', '--invert', action='store_true',
    #                     default=False, help="Invert colors")
    # parser.add_argument('-bw', '--black-n-white', action='store_true',
    #                     default=False, help="Black and white")

    args = parser.parse_args()
    in_file = args.file
    out_file = args.output
    # fill_color = args.background
    # invert_colors = args.invert
    # black_n_white = args.black_n_white
    click_x, click_y = args.click_x, args.click_y
    if not click_x and not click_y:
        click_x, click_y = 0.5, 0.5
    elif not click_x:
        click_x = click_y
    elif not click_y:
        click_y = click_x
    zoom = args.zoom
    w, h = args.width, args.height

    bmp_bytearray = LuaReticleLoader(in_file).make_reticle(
        w,
        h,
        click_x,
        click_y,
        zoom,
        None
    )

    # Save the bytearray to a BMP file
    with open(out_file, "wb") as bmp_file:
        bmp_file.write(bmp_bytearray)


if __name__ == '__main__':
    main()



