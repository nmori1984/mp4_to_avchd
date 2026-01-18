@echo off
setlocal enabledelayedexpansion

:: make_timecodes.bat: ffmpeg用concatファイルリストから各ファイルの開始タイムコード（ミリ秒付き）を計算・出力するスクリプト
::
:: 使い方: make_timecodes.bat input_file_list output_timecodes
::   input_file_list  : ffmpeg concat用ファイルリスト
::   output_timecodes : 出力するタイムコードファイル名

if "%~1"=="" (
    echo 使い方: %0 input_file_list output_timecodes
    exit /b 1
)
if "%~2"=="" (
    echo 使い方: %0 input_file_list output_timecodes
    exit /b 1
)

set "file_list=%~1"
set "output=%~2"
set "offset=0.0"

:: 出力ファイルを初期化（空にする）
> "%output%"

:: ファイルリストを一行ずつ読み込む
for /f "usebackq tokens=1,2 delims='" %%L in ("%file_list%") do (
    set "filepath=%%M"

    :: ffprobeで動画長秒（小数点付き）を取得
    :: まず現在のオフセットをHH:MM:SS.mmm形式に変換して出力
    for /f %%i in ('powershell -Command "[int][math]::Floor(%offset%)"') do set offset_int=%%i
    
    :: powershellを使って小数部分を取得
    for /f %%f in ('powershell -Command "($parts = \"%offset%\".Split('.'))[1]"') do set "offset_frac=%%f"

    :: 小数部がなければ"000"をセットし、3桁にパディングする
    if not defined offset_frac (
        set "offset_frac=000"
    ) else (
        set "offset_frac=!offset_frac!000"
        set "offset_frac=!offset_frac:~0,3!"
    )

    set /a "h=!offset_int! / 3600"
    set /a "m=(!offset_int! %% 3600) / 60"
    set /a "s=!offset_int! %% 60"

    :: ゼロパディング
    if !h! lss 10 set h=0!h!
    if !m! lss 10 set m=0!m!
    if !s! lss 10 set s=0!s!

    echo !h!:!m!:!s!.!offset_frac!>> "%output%"

    :: ffprobeで動画の長さを取得
    for /f "delims=" %%D in ('ffprobe -v error -select_streams v:0 -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "!filepath!" 2^>nul') do (
        set "duration=%%D"
    )

    :: PowerShellを使ってオフセットを更新
    if defined duration (
        for /f %%N in ('powershell -Command "%offset% + %duration%"') do (
            set "offset=%%N"
        )
    )
)

echo Timecodes saved to %output%
endlocal
