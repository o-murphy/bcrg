from bcrg.bcrg import LuaReticleLoader
import argparse


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


