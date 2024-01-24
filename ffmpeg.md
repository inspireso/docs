# ffmpeg

FFmpeg 是一款功能极其强大的开源跨平台音视频处理工具，它包含了一系列命令行工具，主要用于录制、转换和流化音频与视频。以下是 FFmpeg 常用的一些功能：

## mp4 转 mp3

``` sh
ffmpeg -i input.mp4 -vn -ar 44100 -ac 2 -ab 192k -f mp3 output.mp3

```

- -i input.mp4：输入文件
- -vn：不处理视频
- -ar 44100：设置音频采样率为 44100 Hz
- -ac 2：设置音频声道数为 2
- -ab 192k：设置音频码率为 192k
- -f mp3：输出格式为 mp3
- output.mp3：输出文件

## m4a 转 mp3

``` sh
ffmpeg -i input.m4a -acodec libmp3lame -ab 128k output.mp3

```

- -i input.m4a：输入文件
- -acodec libmp3lame：使用 libmp3lame 编码器
- -ab 128k：设置音频码率为 128k
- output.mp3：输出文件

