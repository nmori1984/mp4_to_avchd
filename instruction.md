# はじめに
このプロジェクトはMP4ファイル群からAVCHD形式のフォルダを作成するコンバータです

# prerequisistes
- ubuntu/wsl2
- ffmpeg

# input
- mp4 files

# output
- avchd files

# specifications
- TV/Camcoder(NTSC 60Hz)
- Output can be used with selected Panasonic Viera TV sets and Canon, Panasonic, JVC and Sony camcoders if transferred to SDHC card (no menu).

# inner process
- start
- call convert.sh and output output.mp4 and timecode.txt 
- call generate_avchd.sh to retrieve the mp4 and txt files and then generate AVCHD files
- end
# how to

# links
