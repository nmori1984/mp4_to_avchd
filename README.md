# mp4_to_avchd
- mp4が入ったフォルダをAVCHD形式に変換します。

# prerequisites
- windows
- ffmpeg
- WinAppDriver

## how to use
- カレントディレクトリに00.origというフォルダを置き、その中にMP4ファイルを入れておく。
- 下記のコマンドを実行
```
sh mp4_to_avchd.sh
```
- AVCHD.yyyymmdd_hhmmss というフォルダを作成し、その中にAVCHD形式のデータが保存される

## mp4_to_avchd.shの内部動作
- convert.shを実行
  - output.mp4とtimecode.txtが作成される
- PyAutoGUIでMultiAVCHDをRPA操作する。
  - output.mp4をリストに追加
  - output.mp4のプロパティを開き、timecode.txtの値をコピペする
  - 出力先を${CWD}/AVCHD.yyyymmdd_hhmmssにする
  - AVCHD変換を開始する
  - CamCoder/NTSC/60Hz形式を指定する


