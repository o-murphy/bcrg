import argparse
import io
import sys
import zipfile
import tarfile
from pathlib import Path

from bcrg import LuaReticleLoader


try:
    from importlib.metadata import metadata

    __version__ = metadata("bcrg").get("Version", "Unknown")
except ImportError:
    __version__ = "Unknown"


def _overwrite_check(path, /, force=False):
    if not force and path.exists():
        return input(f"The {path} already exists, overwrite? (y/N): ").lower() in {
            "y",
            "yes",
        }
    return True


def store_to_zip(file_data_dict, output_filename, /, force=False):
    if not _overwrite_check(output_filename, force=force):
        print("Operation cancelled.")
        return

    output_filename.parent.mkdir(parents=True, exist_ok=True)

    with io.BytesIO() as byte_stream:
        with zipfile.ZipFile(byte_stream, "w", zipfile.ZIP_DEFLATED) as zipf:
            for filename, data in file_data_dict.items():
                zipf.writestr(filename, data)

        # Write the in-memory ZIP archive to a file
        with open(output_filename, "wb") as f:
            f.write(byte_stream.getvalue())

    print(f"Successfully stored to {output_filename}")


def store_to_tar_gz(file_data_dict, output_filename, /, force=False):
    if not _overwrite_check(output_filename, force=force):
        print("Operation cancelled.")
        return

    output_filename.parent.mkdir(parents=True, exist_ok=True)

    with tarfile.open(output_filename, "w:gz") as tarf:
        for filename, data in file_data_dict.items():
            info = tarfile.TarInfo(name=filename)
            info.size = len(data)

            data_stream = io.BytesIO(data)

            tarf.addfile(info, data_stream)

    print(f"Successfully stored to {output_filename}")


def store_to_dir(file_data_dict, output_dirname, /, force=False):
    if not _overwrite_check(output_dirname, force=force):
        print("Operation cancelled.")
        return

    output_dirname.mkdir(parents=True, exist_ok=True)

    for name, data in file_data_dict.items():
        # Save the bytearray to a BMP file
        with open(Path(output_dirname, name), "wb") as bmp_file:
            bmp_file.write(data)

    print(f"Successfully stored to {output_dirname}")


def main():
    def is_dir(string):
        path = Path(string)
        if not path.exists() or path.is_dir():
            return string
        parser.error(f"'{string}' is not a valid output path")

    def is_ext_exp(extensions):
        def check_extension(filename):
            if Path(filename).is_dir():
                parser.error(f"Expected file, but '{filename}' is dir")
            if not Path(filename).is_file():
                parser.error(f"File not found '{filename}'")

            ext = Path(filename).suffix.lower()

            if ext not in extensions:
                parser.error(
                    f"File doesn't have one of the expected extensions: {', '.join(extensions)}"
                )
            return filename

        return check_extension

    parser = argparse.ArgumentParser(prog="bcr", exit_on_error=True)
    # parser.add_argument("file", action='store', type=argparse.FileType('r'),
    parser.add_argument(
        "file",
        action="store",
        type=is_ext_exp({".lua"}),
        help="Reticle template file in .lua format",
    )
    parser.add_argument(
        "-o",
        "--output",
        action="store",
        type=is_dir,
        default="./",
        help="Output directory path, defaults to ./",
    )
    parser.add_argument(
        "-f",
        "--force",
        action="store_true",
        default=False,
        help="Force overwrite existing files without prompt",
    )
    parser.add_argument(
        "-W",
        "--width",
        action="store",
        default=640,
        help="Canvas width (px)",
        type=int,
        metavar="<int>",
    )
    parser.add_argument(
        "-H",
        "--height",
        action="store",
        default=640,
        help="Canvas height (px)",
        type=int,
        metavar="<int>",
    )
    parser.add_argument(
        "-cx",
        "--click-x",
        action="store",
        help="Horizontal click size (cm/100m)",
        type=float,
        metavar="<float>",
    )
    parser.add_argument(
        "-cy",
        "--click-y",
        action="store",
        help="Vertical click size (cm/100m)",
        type=float,
        metavar="<float>",
    )
    parser.add_argument(
        "-z",
        "--zoom",
        nargs="*",
        default=[1, 2, 3, 4, 6],
        help="Zoom value (int)",
        type=int,
        metavar="<int>",
    )
    parser.add_argument("-V", "--version", action="version", version=__version__)

    output_group = parser.add_argument_group("archiving options")
    output_group_exclusive = output_group.add_mutually_exclusive_group()

    output_group_exclusive.add_argument(
        "-T",
        "--tar",
        action="store_true",
        default=False,
        help="Store as .tar.gz (overrides --zip)",
    )
    output_group_exclusive.add_argument(
        "-Z", "--zip", action="store_true", default=False, help="Store as .zip"
    )

    if len(sys.argv) == 1:
        parser.parse_args(["--help"])

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
    output_dst_name = f"{stem}_{cx}x{cy}"

    zip_arr = {}

    try:
        for z in args.zoom:
            bmp_bytearray = loader.make_bmp(args.width, args.height, cx, cy, z, None)
            out_file_name = f"{z}.bmp"

            zip_arr[out_file_name] = bmp_bytearray

        destination_base = Path(args.output) / output_dst_name

        if args.zip:
            store_to_zip(
                zip_arr, destination_base.with_suffix(".zip"), force=args.force
            )
        elif args.tar:
            store_to_zip(
                zip_arr, destination_base.with_suffix(".tar.gz"), force=args.force
            )
        else:
            store_to_dir(zip_arr, destination_base, force=args.force)
    except Exception as e:
        parser.error(e)

    parser.exit(0)


if __name__ == "__main__":
    main()
