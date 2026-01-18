#!/bin/bash

# generate_avchd.sh: output_compliant.mp4からtsMuxeRを使ってAVCHD形式のディレクトリ構造を生成

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
INPUT_VIDEO="output_compliant.mp4"
TIMECODE_FILE="timecode.txt"
if [ ! -f "$INPUT_VIDEO" ]; then
  echo "Error: $INPUT_VIDEO not found. Run previous steps first."
  exit 1
fi
if [ ! -f "$TIMECODE_FILE" ]; then
  echo "Error: $TIMECODE_FILE not found. Run convert.sh first."
  exit 1
fi
if [ ! -d "AVCHD.ok" ]; then
    echo "Error: Reference AVCHD.ok directory not found."
    exit 1
fi


echo "========================================="
echo "Step 2.1: Generating AVCHD structure with tsMuxeR"
echo "========================================="

# 一時ディレクトリと出力ディレクトリの準備
TMP_MUX_DIR="AVCHD.tmp"
FINAL_DIR="AVCHD"
rm -rf "$TMP_MUX_DIR" "$FINAL_DIR"
mkdir -p "$TMP_MUX_DIR"

# timecode.txtからチャプター情報を読み込む
CHAPTERS=$(paste -sd ';' "$TIMECODE_FILE")
echo "Chapters loaded from timecode.txt"

# tsMuxeR用のメタファイルを作成
echo "Creating tsMuxeR meta file..."
cat <<EOF > "$TMP_MUX_DIR/mux.meta"
MUXOPT --no-pcr-on-video-pid --new-audio-pes --avchd --vbr --custom-chapters=${CHAPTERS} --vbv-len=500
V_MPEG4/ISO/AVC, "$PWD/$INPUT_VIDEO", track=1, insertSEI, contSPS, lang=eng
A_AC3, "$PWD/$INPUT_VIDEO", track=2, lang=und
EOF

# tsMuxeRを実行して一時ディレクトリにAVCHDフォルダを生成
echo "Running tsMuxeR to create temporary AVCHD structure..."
"$TSMUXER_PATH" "$TMP_MUX_DIR/mux.meta" "$TMP_MUX_DIR"

echo "========================================="
echo "Step 2.2: Normalizing AVCHD structure to FAT 8.3 format"
echo "========================================="

# tsMuxeRがBDMVフォルダを生成したことを確認
if [ ! -d "$TMP_MUX_DIR/BDMV" ]; then
    echo "Error: tsMuxeR did not create the BDMV directory."
    exit 1
fi

# 大文字に変換しながら新しいAVCHDフォルダに再構築
mkdir -p "$FINAL_DIR"
cd "$TMP_MUX_DIR"

# すべてのディレクトリとファイルを大文字に変換してコピー
find . -depth -name '*' | while read -r file; do
    new_file=$(echo "$file" | tr '[:lower:]' '[:upper:]')
    
    # Zone.Identifierファイルをスキップ
    if [[ "$new_file" == *":ZONE.IDENTIFIER" ]]; then
        continue
    fi

    # 拡張子を変更
    new_file=${new_file//.BDMV/.BDM}
    new_file=${new_file//.CLPI/.CPI}
    new_file=${new_file//.MPLS/.MPL}
    new_file=${new_file//.M2TS/.MTS}

    target_path="../../$FINAL_DIR/$new_file"

    if [ -d "$file" ]; then
        mkdir -p "$target_path"
    else
        mv "$file" "$target_path"
    fi
done

cd ../

# BACKUPフォルダの中身を正しく配置
echo "Creating BACKUP folder contents..."
BACKUP_DIR="$FINAL_DIR/BDMV/BACKUP"
mkdir -p "$BACKUP_DIR/CLIPINF"
mkdir -p "$BACKUP_DIR/PLAYLIST"
cp "$FINAL_DIR/BDMV/INDEX.BDM" "$BACKUP_DIR/INDEX.BDM"
cp "$FINAL_DIR/BDMV/MOVIEOBJ.BDM" "$BACKUP_DIR/MOVIEOBJ.BDM"
cp "$FINAL_DIR/BDMV/CLIPINF/00000.CPI" "$BACKUP_DIR/CLIPINF/00000.CPI"
cp "$FINAL_DIR/BDMV/PLAYLIST/00000.MPL" "$BACKUP_DIR/PLAYLIST/00000.MPL"

echo "========================================="
echo "Step 2.3: Copying additional structure from AVCHD.ok"
echo "========================================="

# AVCHDTN, IISVPLフォルダをコピー、HDAVCTNを作成
if [ -d "AVCHD.ok/AVCHDTN" ]; then
    cp -r "AVCHD.ok/AVCHDTN" "$FINAL_DIR/"
fi
if [ -d "AVCHD.ok/IISVPL" ]; then
    cp -r "AVCHD.ok/IISVPL" "$FINAL_DIR/"
fi
mkdir -p "$FINAL_DIR/HDAVCTN"

# 一時ディレクトリを削除
rm -rf "$TMP_MUX_DIR"

echo ""
echo "AVCHD structure finalized successfully in '$FINAL_DIR/'"
echo ""
echo "Directory structure:"
tree -L 3 "$FINAL_DIR" 2>/dev/null || find "$FINAL_DIR" -maxdepth 4 -print 2>/dev/null
echo ""
echo "✓ AVCHD generation completed successfully!"