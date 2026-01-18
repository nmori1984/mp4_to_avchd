@echo off
setlocal

:: 00.origのサブディレクトリにある全ての.mp4ファイルを.aviに変換します
FOR /R "00.orig" %%F IN (*.mp4) DO (
    ffmpeg -y -i "%%F" -vf scale=720:480,fps=30000/1001 -c:v rawvideo -pix_fmt yuv420p -c:a pcm_s16le -ar 48000 -af "loudnorm,aresample=async=1,aformat=channel_layouts=stereo" "%%~dpnF.avi"
)

:: ffmpeg concat用のavi.txtを作成します
(for /f "delims=" %%A in ('dir /b /s "00.orig\*.avi"') do @echo file '%%A') > avi.txt

:: aviファイルを連結してoutput.mp4を作成します
ffmpeg -y -f concat -safe 0 -i avi.txt -fflags +genpts -fflags +igndts -vf fps=30000/1001,scale=720:480 -c:v libx264 -r 30000/1001 -c:a aac -ar 48000 output.mp4

:: タイムコードを生成します
CALL make_timecodes.bat avi.txt timecode.txt

:: 生成されたタイムコードを表示します
echo.
echo Generated timecodes:
type timecode.txt

endlocal
