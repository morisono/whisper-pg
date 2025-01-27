# Whisper-PG: AIによる自動動画編集ツール

Whisper-PGは、WhisperXとFFmpegを活用した自動動画編集コマンドラインツールです。

## 主な機能

- **無音部分の自動削除**: 音声分析による無音部分のトリミング
- **AI字幕生成**: WhisperXを使用した高精度な字幕生成
- **話者分離**: 音声中の異なる話者を識別
- **ビデオエフェクト**: フェードイン/アウト、再生速度調整
- **バッチ処理**: 複数ファイルの連結と分割
- **フォーマット変換**: 各種動画/音声フォーマットの変換

## インストール

### 前提条件
- Python 3.8+
- FFmpeg
- WhisperX
- Auto-Editor

```bash
# 依存関係のインストール
pip install whisperx auto-editor
sudo apt install ffmpeg
```

### インストール方法
```bash
git clone https://github.com/yourusername/whisper-pg.git
cd whisper-pg
```

## 使用方法

### 基本コマンド
```bash
bash tools/scripts/auto-edit.sh input.mp4 --unsilence 0.02 --addsub --fade-in output.mp4
```

### 高度なオプション
```bash
# 複数ファイルの処理
fd -t f -e mp4 | bash tools/scripts/auto-edit.sh --concat --unsilence --split '5min' --speed 1.75 V"%02d.%03d"_"%FT%T".mp4

# 音声抽出と処理
ffmpeg -i input.mp4 -q:a 0 -map a audio.m4a
bash tools/scripts/auto-edit.sh audio.m4a --unsilence 0.02 --addsub output.mp4
```

## サンプル動画の取得

### yt-dlpを使用
```bash
# set url "https://www.youtube.com/shorts/O5WOyZadFm0"
set url "https://www.youtube.com/shorts/TmnKpKMMcyo"

# 字幕付きで動画をダウンロード
yt-dlp --config-location yt-dlp.conf $url

# (Optional)字幕を焼き込んでMP4に変換
# yt-dlp --config-location yt-dlp.conf $url | xargs -i \
# HandBrakeCLI -i {} -o "sub."{} --subtitle-burn 1 --preset="Fast 1080p30"

# yt-dlp --config-location yt-dlp.conf $url --exec \
#  "mkdir temp && ffmpeg -i {} -vf subtitles={}:force_style='FontName=cinecaption' -acodec copy temp/{} && mv -f temp/{} {} && rm -r temp" --restrict-filenames AO4In7d6X-c

# Windows
# ffmpeg.exe -i "input.mp4" -vf subtitles="filename='input.mp4':force_style='FontSize=20,FontName=Arial'" -c:v libx264 -x264-params crf=22 -preset fast -profile:v high "output.mp4"
```

## トラブルシューティング

### よくある問題
1. **403 Forbidden エラー**
```bash
yt-dlp --rm-cache-dir
pip install -U yt-dlp
```

2. **依存関係の不足**
```bash
# インストール済みバージョンの確認
ffmpeg -version
whisperx --version
auto-editor --version
```

## 貢献方法
プルリクエストは歓迎します。大きな変更を加える場合は、まずIssueを開いてください。

## ライセンス
[MIT](https://choosealicense.com/licenses/mit/)
