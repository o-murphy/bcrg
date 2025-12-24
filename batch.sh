#!/usr/bin/env bash
set -e

# Check arguments
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <INPUT_FILE> <OUTPUT_DIR>"
  exit 1
fi

INPUT_FILE="$1"
OUTPUT_DIR="$2"

# Validate input file
if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: input file not found: $INPUT_FILE"
  exit 1
fi

# Create output directories
mkdir -p \
  "$OUTPUT_DIR/640x480" \
  "$OUTPUT_DIR/640x640" \
  "$OUTPUT_DIR/720x576"

# Loop over resolutions
for R in 640x480 640x640 720x576; do
  case "$R" in
    640x480)
      WIDTH=640
      HEIGHT=480
      ;;
    640x640)
      WIDTH=640
      HEIGHT=640
      ;;
    720x576)
      WIDTH=720
      HEIGHT=576
      ;;
  esac

  # Loop over cx values
  for C in 4.26 3.01 2.27 2.13 2.01 1.42; do
    echo "Running: bcrg -W $WIDTH -H $HEIGHT -cx $C -o $OUTPUT_DIR/$R $INPUT_FILE"

    bcrg -W "$WIDTH" -H "$HEIGHT" -cx "$C" \
         -o "$OUTPUT_DIR/$R" \
         "$INPUT_FILE"

    echo "Command done for -W $WIDTH -H $HEIGHT -cx $C -o $OUTPUT_DIR/$R"
  done
done
