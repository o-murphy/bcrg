import argparse
import io
import os
import sys
import zipfile
from pathlib import Path

from bcrg import LuaReticleLoader


def store_to_zip(file_data_dict, output_filename):
    with io.BytesIO() as byte_stream:
        with zipfile.ZipFile(byte_stream, 'w', zipfile.ZIP_DEFLATED) as zipf:
            for filename, data in file_data_dict.items():
                zipf.writestr(filename, data)

        # Write the in-memory ZIP archive to a file
        with open(output_filename, 'wb') as f:
            f.write(byte_stream.getvalue())


def store_to_dir(file_data_dict, output_dirname):
    os.makedirs(output_dirname, exist_ok=True)

    for name, data in file_data_dict.items():
        # Save the bytearray to a BMP file
        with open(Path(output_dirname, name), "wb") as bmp_file:
            bmp_file.write(data)


def main():

    def is_dir(string):
        if Path(string).is_dir():
            return string
        else:
            parser.error(f"'{string}' is not a valid output path")

    def is_ext_exp(extensions):
        def check_extension(filename):
            if Path(filename).is_dir():
                parser.error(f"Expected file, but '{filename}' is dir")
            if not Path(filename).is_file():
                parser.error(f"File not found '{filename}'")

            ext = Path(filename).suffix.lower()

            if ext not in extensions:
                parser.error(f"File doesn't have one of the expected extensions: {', '.join(extensions)}")
            return filename

        return check_extension

    parser = argparse.ArgumentParser(prog="bcr", exit_on_error=False)
    # parser.add_argument("file", action='store', type=argparse.FileType('r'),
    parser.add_argument("file", action='store', type=is_ext_exp({'.lua'}),
                        help="Reticle template file in .lua format")
    parser.add_argument('-o', '--output', action='store', type=is_dir, default="./",
                        help="Output directory path, defaults to ./")
    parser.add_argument('-W', '--width', action='store', default=640,
                        help="Canvas width (px)", type=int, metavar="<int>")
    parser.add_argument('-H', '--height', action='store', default=640,
                        help="Canvas height (px)", type=int, metavar="<int>")
    parser.add_argument('-cx', '--click-x', action='store',
                        help="Horizontal click size (cm/100m)", type=float, metavar="<float>")
    parser.add_argument('-cy', '--click-y', action='store',
                        help="Vertical click size (cm/100m)", type=float, metavar="<float>")
    parser.add_argument('-z', '--zoom', nargs="*", default=[1, 2, 3, 4, 6],
                        help="Zoom value (int)", type=int, metavar="<int>")
    parser.add_argument('-Z', '--zip', action="store_true", default=False,
                        help="Store as .zip")

    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
        sys.exit(1)

    args = parser.parse_args()

    cx, cy = args.click_x, args.click_y
    if not cx and not cy:
        cx, cy = 0.5, 0.5
    elif not cx:
        cx = cy
    elif not cy:
        cy = cx

    loader = LuaReticleLoader(args.file)

    stem = Path(args.file).stem
    out_dir = f"{stem}_{cx}x{cy}"

    zip_arr = {}

    try:
        for z in args.zoom:
            bmp_bytearray = loader.make_bmp(
                args.width, args.height, cx, cy, z, None
            )
            out_file_name = f"{z}.bmp"

            zip_arr[out_file_name] = bmp_bytearray

        if args.zip:
            store_to_zip(zip_arr, f"{out_dir}.zip")
        else:
            store_to_dir(zip_arr, Path(args.output, out_dir))
    except Exception as e:
        print(e)
        sys.exit(1)


if __name__ == '__main__':
    main()
