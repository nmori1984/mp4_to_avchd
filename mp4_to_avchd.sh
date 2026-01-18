#!/bin/bash

# mp4_to_avchd.sh: MP4ファイル群からAVCHD形式のフォルダを作成するメインスクリプト

set -e  # エラーが発生したら即座に終了

echo "========================================="
echo "MP4 to AVCHD Converter"
echo "========================================="
echo ""

# 入力ディレクトリの確認
if [ ! -d "00.orig" ]; then
  echo "Error: 00.orig directory not found"
  echo "Please create 00.orig directory and place MP4 files in subdirectories"
  echo "Example: 00.orig/video1/file1.mp4"
  exit 1
fi

# MP4ファイルの存在確認
mp4_count=$(find 00.orig -name "*.mp4" 2>/dev/null | wc -l)
if [ "$mp4_count" -eq 0 ]; then
  echo "Error: No MP4 files found in 00.orig directory"
  echo "Please place MP4 files in subdirectories under 00.orig/"
  exit 1
fi

echo "Found $mp4_count MP4 file(s) to process"
echo ""

# Step 1: Convert MP4 files
echo "========================================="
echo "Step 1: Converting MP4 files"
echo "========================================="
if [ ! -f "convert.sh" ]; then
  echo "Error: convert.sh not found"
  exit 1
fi

chmod +x convert.sh make_timecodes.sh
bash convert.sh

if [ ! -f "output.mp4" ] || [ ! -f "timecode.txt" ]; then
  echo "Error: convert.sh failed to create output.mp4 or timecode.txt"
  exit 1
fi

echo ""
echo "✓ Conversion completed successfully"
echo ""

# Step 1.5: Re-encoding for AVCHD compliance
echo "========================================="
echo "Step 1.5: Re-encoding for AVCHD compliance"
echo "========================================="
ffmpeg -y -i output.mp4 \
-c:v libx264 -profile:v high -level 4.1 -pix_fmt yuv420p \
-x264-params "nal-hrd=avchd:aud=1:bluray-compat=1" \
-b:v 6000k -maxrate 9000k -bufsize 9000k \
-c:a ac3 -b:a 128k \
output_compliant.mp4
echo "✓ Re-encoding completed successfully"
echo ""

# Step 2: Generate AVCHD structure
echo "========================================="
echo "Step 2: Generating AVCHD structure"
echo "========================================="
if [ ! -f "generate_avchd.sh" ]; then
  echo "Error: generate_avchd.sh not found"
  exit 1
fi

chmod +x generate_avchd.sh
bash generate_avchd.sh

if [ ! -d "AVCHD" ]; then
  echo "Error: generate_avchd.sh failed to create AVCHD directory"
  exit 1
fi

echo ""
echo "========================================="
echo "✓ All steps completed successfully!"
echo "========================================="
echo ""
echo "Output: AVCHD/"
echo ""
echo "Next steps:"
echo "1. Copy the AVCHD folder to the root of your SDHC card"
echo "2. Insert the card into your Panasonic Viera TV or compatible camcorder"
echo "3. The device should recognize it as AVCHD content"
echo ""
