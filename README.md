# Whisper-PG: Automated Video Editing with AI

Whisper-PG is a powerful command-line tool for automated video editing, leveraging AI technologies like WhisperX for transcription and diarization, and FFmpeg for video processing.

## Key Features

- **Automatic Silence Removal**: Trim silent portions using audio analysis
- **AI Subtitles**: Generate accurate subtitles using WhisperX
- **Speaker Diarization**: Identify different speakers in the audio
- **Video Effects**: Add fade-in/out effects and adjust playback speed
- **Batch Processing**: Handle multiple files with concatenation and splitting
- **Format Conversion**: Convert between various video/audio formats

## Development Roadmap

- Auto Zoom: Configure anchor points and zoom factors with duration settings
- AutoCut Repeats: Detect video transcript repetitions in Premiere Pro and remove bad takes with AI 
- Auto Resize: Use AI tracking to keep subjects centered in videos
- Auto B-Roll: Set min/max duration parameters to control B-Roll quantity and transitions
- Auto Viral: Analyze viral potential to assist clip selection
- Auto Profanity: Multiple censorship sounds (standard beep, unique tones, duck sounds)
- Auto Chapters: Export YouTube-compatible chapter markers

## Installation

### Prerequisites
- Python 3.8+
- FFmpeg
- WhisperX
- Auto-Editor

```bash
# Install dependencies
pip install whisperx auto-editor
sudo apt install ffmpeg
```

### Installation
```bash
git clone https://github.com/yourusername/whisper-pg.git
cd whisper-pg
```

## Usage

### Basic Command
```bash
bash tools/scripts/auto-edit.sh input.mp4 --unsilence 0.02 --addsub --fade-in output.mp4
```

### Advanced Options
```bash
# Process multiple files
fd -t f -e mp4 | bash tools/scripts/auto-edit.sh --concat --unsilence --split '5min' --speed 1.75 V"%02d.%03d"_"%FT%T".mp4

# Extract audio and process
ffmpeg -i input.mp4 -q:a 0 -map a audio.m4a
bash tools/scripts/auto-edit.sh audio.m4a --unsilence 0.02 --addsub output.mp4
```

## Sample Video Acquisition

### Using yt-dlp
```bash
# Download video with subtitles
yt-dlp --write-subs --sub-lang en --merge-output-format mkv "https://www.youtube.com/watch?v=nWbrlDNiMoQ"

# Convert to MP4 with burned subtitles
HandBrakeCLI -i "input.mkv" -o "output.mp4" --subtitle-burn 1 --preset="Fast 1080p30"
```

## Troubleshooting

### Common Issues
1. **403 Forbidden Error**
```bash
yt-dlp --rm-cache-dir
pip install -U yt-dlp
```

2. **Missing Dependencies**
```bash
# Check installed versions
ffmpeg -version
whisperx --version
auto-editor --version
```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
[MIT](https://choosealicense.com/licenses/mit/)
