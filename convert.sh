#!/bin/bash
for mp4 in 00.orig/*.mp4
do
  ffmpeg -y -i "${mp4}" -vf scale=720:480,fps=30000/1001 -c:v rawvideo -pix_fmt yuv420p -c:a pcm_s16le -ar 48000 -af "loudnorm,aresample=async=1,aformat=channel_layouts=stereo"  "${mp4%.*}.avi"
done

ls 00.orig/*/*.avi | sed "s/^/file '/g" | sed "s/$/'/g" | tee avi.txt
ffmpeg -y -f concat -safe 0 -i avi.txt -fflags +genpts  -fflags +igndts -vf fps=30000/1001,scale=720:480 -c:v libx264 -r 30000/1001 -c:a aac -ar 48000  output.mp4

bash make_timecodes.sh avi.txt timecode.txt
cat timecode.txt

