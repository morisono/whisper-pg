#!/bin/bash

# Auto Video Editor CLI
# Version 0.1.0

# Global variables
declare -a TEMP_FILES=()
declare -i TOTAL_STEPS=5
declare -i CURRENT_STEP=0

# Cleanup function
cleanup() {
    for file in "${TEMP_FILES[@]}"; do
        if [[ -f "$file" ]]; then
            rm -f "$file"
        fi
    done
}

# Error handling function
handle_error() {
    echo "Error: $1" >&2
    cleanup
    exit 1
}

# Check dependencies
check_dependencies() {
    local deps=("$@")
    local missing=()
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        handle_error "Missing dependencies: ${missing[*]}"
    fi
}

# Validate input file
validate_input() {
    if [[ ! -f "$1" ]]; then
        handle_error "Input file not found: $1"
    fi

    # Check if file is valid media (video or audio)
    if ! ffmpeg -i "$1" -c copy -f null - 2>&1 | grep -qE "(frame=|Audio:|Stream #)"; then
        handle_error "Invalid media file: $1"
    fi
}

# Validate parameters
validate_params() {
    if [[ -n "$unsilence_threshold" ]] && ! [[ "$unsilence_threshold" =~ ^[0-9]*\.?[0-9]+$ ]]; then
        handle_error "Invalid unsilence threshold: $unsilence_threshold"
    fi

    if [[ -n "$speed" ]] && ! [[ "$speed" =~ ^[0-9]*\.?[0-9]+$ ]]; then
        handle_error "Invalid speed value: $speed"
    fi

    if [[ -n "$split_duration" ]] && ! [[ "$split_duration" =~ ^[0-9]+(min|s)?$ ]]; then
        handle_error "Invalid split duration format: $split_duration"
    fi
}

# Add temporary file
add_temp_file() {
    TEMP_FILES+=("$1")
}

# Show progress indicator
show_progress() {
    local pid=$1
    local message=$2
    local delay=0.75
    local spinstr='|/-\'

    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf "\r [%c] %s" "$spinstr" "$message"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Show step progress
show_step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo -e "\n[Step $CURRENT_STEP/$TOTAL_STEPS] $1"
}

# Main function
main() {
    # Parse arguments
    local input_file=""
    local output_file=""
    local unsilence_threshold=0.02
    local add_subtitles=false
    local diarize=false
    local fade_in=false
    local concat=false
    local split_duration=""
    local speed=1.0
    local play=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --unsilence)
                unsilence_threshold=$2
                shift 2
                ;;
            --addsub)
                add_subtitles=true
                shift
                ;;
            --diarise)
                diarize=true
                shift
                ;;
            --fade-in)
                fade_in=true
                shift
                ;;
            --concat)
                concat=true
                shift
                ;;
            --split)
                split_duration=$2
                shift 2
                ;;
            --speed)
                speed=$2
                shift 2
                ;;
            --play)
                play=true
                shift
                ;;
            *)
                if [[ -z "$input_file" ]]; then
                    input_file=$1
                else
                    output_file=$1
                fi
                shift
                ;;
        esac
    done

    # Validate input
    validate_input "$input_file"
    validate_params

    if [[ -z "$output_file" ]]; then
        output_file="output.mp4"
    fi

    # Check dependencies and codecs
    required_deps=("ffmpeg" "auto-editor" "whisperx")
    if $play; then
        required_deps+=("mpv")
    fi
    check_dependencies "${required_deps[@]}"

    # Verify codec availability
    # if ! ffmpeg -codecs | grep -q libx264; then
    #     echo "Installing required codecs..."
    #     sudo apt-get update && sudo apt-get install -y libx264-dev libdav1d-dev
    # fi

    # Process video
    show_step "Starting video processing"
    echo "Input file: $input_file"
    echo "Output file: $output_file"

    # Step 1: Trim silence
    show_step "Trimming silence"
    local temp_trimmed="temp_trimmed_$(date +%s).mp4"
    add_temp_file "$temp_trimmed"

    # Check if file is audio-only
    if ffmpeg -i "$input_file" 2>&1 | grep -q "Video: none"; then
        # Use audio-based silence detection directly on audio file
        auto-editor "$input_file" \
         --edit "audio:threshold=$unsilence_threshold" --output "$temp_trimmed" &
        pid=$!
        show_progress $pid "Trimming silence (audio)"
    else
        # Use motion detection for video files with explicit codec
        auto-editor "$input_file" \
            --edit "motion:threshold=$unsilence_threshold" \
            --output "$temp_trimmed" &
        pid=$!
        show_progress $pid "Trimming silence (video)"
    fi

    if ! wait $pid; then
        handle_error "Failed to trim silence"
    fi

    # Step 2: Adjust speed if needed
    if (( $(echo "$speed != 1.0" | bc -l) )); then
        show_step "Adjusting speed"
        local temp_speed="temp_speed_$(date +%s).mp4"
        add_temp_file "$temp_speed"

        ffmpeg -i "$temp_trimmed" -filter:v "setpts=PTS/$speed" -filter:a "atempo=$speed"  "$temp_speed" &
        pid=$!
        show_progress $pid "Adjusting speed"

        if ! wait $pid; then
            handle_error "Failed to adjust speed"
        fi
        mv "$temp_speed" "$temp_trimmed"
    fi

    # Step 3: Add fade in if requested
    if $fade_in; then
        show_step "Adding fade in effect"
        local temp_fade="temp_fade_$(date +%s).mp4"
        add_temp_file "$temp_fade"

        ffmpeg -i "$temp_trimmed" -vf "fade=t=in:st=0:d=1" "$temp_fade" &
        pid=$!
        show_progress $pid "Adding fade in"

        if ! wait $pid; then
            handle_error "Failed to add fade in effect"
        fi
        mv "$temp_fade" "$temp_trimmed"
    fi

    # Step 4: Add subtitles if requested
    if $add_subtitles; then
        show_step "Generating subtitles"
        local temp_srt="temp_$(date +%s).srt"
        add_temp_file "$temp_srt"

        whisperx "$temp_trimmed" --model small --output_format srt --temperature 0.9 --beam_size 15 --best_of 3 --fp16 False --align_model WAV2VEC2_ASR_LARGE_LV60K_960H --batch_size 4 &
        pid=$!
        show_progress $pid "Generating subtitles"

        if ! wait $pid; then
            handle_error "Failed to generate subtitles"
        fi

        if $diarize; then
            show_step "Adding diarization"
            whisperx "$temp_trimmed" --diarise --highlight_words True &
            pid=$!
            show_progress $pid "Adding diarization"

            if ! wait $pid; then
                handle_error "Failed to add diarization"
            fi
        fi

        show_step "Burning subtitles into video"
        local temp_subtitled="temp_subtitled_$(date +%s).mp4"
        add_temp_file "$temp_subtitled"

        ffmpeg -i "$temp_trimmed" -vf "subtitles=$temp_srt:force_style='FontSize=16,Outline=0,BorderStyle=3,BackColour=&H80000000,OutlineColour=&H00000000,BorderStyle=2,MarginV=20,MarginL=20,MarginR=20'" -c:v libx264 -crf 15 -b:v 3000k "$temp_subtitled" &
        pid=$!
        show_progress $pid "Burning subtitles"

        if ! wait $pid; then
            handle_error "Failed to burn subtitles"
        fi
        mv "$temp_subtitled" "$temp_trimmed"
    fi

    # Step 5: Handle concatenation or splitting if needed
    if $concat; then
        show_step "Concatenating videos"
        local concat_list="concat_list_$(date +%s).txt"
        add_temp_file "$concat_list"

        echo "file '$temp_trimmed.mp4'" > "$concat_list"

        # Read piped input if available
        if [[ -p /dev/stdin ]]; then
            while read -r line; do
                echo "file '$line'" >> "$concat_list"
            done
        fi

        local temp_concat="temp_concat_$(date +%s).mp4"
        add_temp_file "$temp_concat"

        ffmpeg -f concat -safe 0 -i "$concat_list" -c copy "$temp_concat" &
        pid=$!
        show_progress $pid "Concatenating videos"

        if ! wait $pid; then
            handle_error "Failed to concatenate videos"
        fi
        mv "$temp_concat" "$temp_trimmed"
        rm "$concat_list"

    elif [[ -n "$split_duration" ]]; then
        show_step "Splitting video"
        ffmpeg -i "$temp_trimmed" -c copy -map 0 -f segment -segment_time "$split_duration" -reset_timestamps 1 -strftime 1 "${output_file%.*}_%03d.mp4" &
        pid=$!
        show_progress $pid "Splitting video"

        if ! wait $pid; then
            handle_error "Failed to split video"
        fi
        echo "Split complete. Multiple files created with pattern: ${output_file%.*}_XXX.mp4"
        cleanup
        exit 0
    fi

    # Final output
    ffmpeg -i "$temp_trimmed" -c:v libx264 "$output_file"
    echo -e "\nProcessing complete. Output saved to: $output_file"

    if $play; then
        echo -e "\nPlaying output file with mpv..."
        mpv "$output_file"
    fi

    cleanup
}

main "$@"
