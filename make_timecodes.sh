#!/bin/bash

# make_timecodes.sh: ffmpeg用concatファイルリストから各ファイルの開始タイムコード（ミリ秒付き）を計算・出力するスクリプト

if [ $# -ne 2 ]; then
  echo "Usage: $0 input_file_list output_timecodes"
  echo "  input_file_list  : ffmpeg concat用ファイルリスト"
  echo "  output_timecodes : 出力するタイムコードファイル名"
  exit 1
fi

file_list="$1"
output="$2"
offset=0

> "$output"  # 出力ファイル初期化（空にする）

while IFS= read -r line
do
  # 行が file '...' の形式と仮定してファイルパス部分のみ抽出
  file=$(echo "$line" | sed -e "s/file '\(.*\)'/\1/")

  # offset（秒の小数）をHH:MM:SS.mmm形式に変換
  offset_int=${offset%.*}
  offset_frac=${offset#*.}
  
  # 小数部が無ければ"000"をセット
  if [ "$offset_frac" = "$offset" ]; then
    offset_frac="000"
  else
    # ミリ秒3桁に切り詰め＆0埋め
    offset_frac=${offset_frac:0:3}
    while [ ${#offset_frac} -lt 3 ]; do
      offset_frac="${offset_frac}0"
    done
  fi

  h=$((offset_int / 3600))
  m=$(((offset_int % 3600) / 60))
  s=$((offset_int % 60))

  printf '%02d:%02d:%02d.%s\n' $h $m $s $offset_frac >> "$output"

  # ffprobeで動画長秒（小数点付き）を取得
  duration=$(ffprobe -v error -select_streams v:0 -show_entries format=duration \
            -of default=noprint_wrappers=1:nokey=1 "$file")

  # offsetを更新
  offset=$(echo "$offset + $duration" | bc)

done < "$file_list"

echo "Timecodes saved to $output"
