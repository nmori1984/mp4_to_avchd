#!/bin/bash

# generate_avchd.sh: output.mp4からtsMuxeRを使ってAVCHD形式のディレクトリ構造を生成

set -e

# tsMuxeRのパスを自動検出
if [ -x "/home/mona/tsMuxer/tsMuxer-2.7.0-linux/tsMuxeR" ]; then
    TSMUXER_PATH="/home/mona/tsMuxer/tsMuxer-2.7.0-linux/tsMuxeR"
elif command -v tsMuxeR &> /dev/null; then
    TSMUXER_PATH=$(command -v tsMuxeR)
else
    echo "Error: tsMuxeR executable not found."
    echo "Please install tsMuxeR and make it available in your PATH, or check the path in this script."
    exit 1
fi

echo "Using tsMuxeR at: $TSMUXER_PATH"

# 入力ファイルの確認
if [ ! -f "output_compliant.mp4" ]; then
  echo "Error: output_compliant.mp4 not found. Run convert.sh and re-encoding step first."
  exit 1
fi
if [ ! -f "timecode.txt" ]; then
  echo "Error: timecode.txt not found. Run convert.sh first."
  exit 1
fi

echo "========================================="
echo "Step 2: Generating AVCHD structure with tsMuxeR"
echo "========================================="

# 一時ディレクトリと出力ディレクトリの準備
TMP_DIR="tmp_avchd"
OUTPUT_DIR="AVCHD"
rm -rf "$TMP_DIR" "$OUTPUT_DIR"
mkdir -p "$TMP_DIR"

# timecode.txtからチャプター情報を読み込む
CHAPTERS=$(paste -sd ';' timecode.txt)
echo "Chapters loaded from timecode.txt"

# tsMuxeR用のメタファイルを作成
# output.mp4を直接入力とし、tsMuxeRに音声変換を任せる
echo "Creating tsMuxeR meta file..."
cat <<EOF > "$TMP_DIR/mux.meta"
MUXOPT --no-pcr-on-video-pid --new-audio-pes --blu-ray --vbr --custom-chapters=${CHAPTERS} --vbv-len=500
V_MPEG4/ISO/AVC, "$PWD/output_compliant.mp4", track=1, insertSEI, contSPS
A_AC3, "$PWD/output_compliant.mp4", track=2
EOF

# tsMuxeRを実行してAVCHDフォルダを生成
echo "Running tsMuxeR to create AVCHD structure..."
"$TSMUXER_PATH" "$TMP_DIR/mux.meta" "$OUTPUT_DIR"

# 一時ディレクトリを削除
rm -rf "$TMP_DIR"

echo ""
echo "AVCHD structure generated successfully in '$OUTPUT_DIR/'"
echo ""
echo "Directory structure:"
tree -L 3 "$OUTPUT_DIR" 2>/dev/null || find "$OUTPUT_DIR" -maxdepth 4 -print 2>/dev/null
echo ""
echo "✓ All steps completed successfully!"
