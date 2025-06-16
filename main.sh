#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <folder_chars> <file_chars> <file_size>"
    exit 1
fi

FOLDER_CHARS="$1"
FILE_CHARS="$2"
RAW_FILE_SIZE="$3"

DATE_SUFFIX=$(date +"%d%m%y")
LOG_FILE="/tmp/creation_log_${DATE_SUFFIX}.log"


START_TIME=$(date +%s)

format_time() {
    local t=$1
    printf "%02d:%02d:%02d" $((t/3600)) $(((t/60)%60)) $((t%60))
}


if [[ "$RAW_FILE_SIZE" =~ ^([1-9][0-9]{0,2})[Mm][Bb]$ ]]; then
    FILE_SIZE_MB=$(echo "$RAW_FILE_SIZE" | sed -E 's/[^0-9]//g')
    if (( FILE_SIZE_MB > 100 )); then
        echo "Error: File size must be less than or equal to 100 MB."
        exit 1
    fi
elif [[ "$RAW_FILE_SIZE" =~ ^([1-9][0-9]{0,2})$ ]]; then
    FILE_SIZE_MB="$RAW_FILE_SIZE"
    if (( FILE_SIZE_MB > 100 )); then
        echo "Error: File size must be less than or equal to 100 MB."
        exit 1
    fi
else
    echo "Error: Invalid file size format. Use e.g., '3Mb' or '5'."
    exit 1
fi

if ! [[ "$FOLDER_CHARS" =~ ^[a-zA-Z]+$ ]] || (( ${#FOLDER_CHARS} > 7 )); then
    echo "Error: First parameter must contain only letters and up to 7 characters."
    exit 1
fi


IFS='.' read -r FILE_NAME_CHARS FILE_EXT_CHARS <<< "$FILE_CHARS"
if [ -z "$FILE_EXT_CHARS" ]; then
    FILE_EXT_CHARS="txt"
fi

if ! [[ "$FILE_NAME_CHARS" =~ ^[a-zA-Z]+$ ]] || (( ${#FILE_NAME_CHARS} > 7 )); then
    echo "Error: Filename part in second parameter is invalid."
    exit 1
fi

if ! [[ "$FILE_EXT_CHARS" =~ ^[a-zA-Z]+$ ]] || (( ${#FILE_EXT_CHARS} > 3 )); then
    echo "Error: File extension part in second parameter is invalid."
    exit 1
fi

check_disk_space() {
    local free_kb=$(df -k / | awk 'NR==2 {print $4}')
    if (( free_kb < 1048576 )); then
        echo "$(date +"%Y-%m-%d %H:%M:%S") Not enough disk space. Script stopped." >> "$LOG_FILE"
        log_footer_and_exit
    fi
}


generate_name() {
    local chars="$1"
    local min_length=5
    local max_length=10
    local length=$(( RANDOM % (max_length - min_length + 1) + min_length ))

    local used=""
    for ((i=0; i<${#chars}; i++)); do
        used+="${chars:$i:1}"
    done

    while [ ${#used} -lt $length ]; do
        used+="${chars:RANDOM%${#chars}:1}"
    done

    declare -a letters
    for ((i=0; i<${#used}; i++)); do
        letters[i]="${used:$i:1}"
    done

    sorted=()
    for c in $(echo "$chars" | fold -w1); do
        for l in "${letters[@]}"; do
            if [[ "$l" == "$c" ]]; then
                sorted+=("$l")
            fi
        done
    done

    result=$(printf "%s" "${sorted[@]:0:$length}")
    echo "$result"
}

get_random_dir() {
    local dirs=(/tmp /var/tmp /home /root /opt /usr/local /etc)
    local safe_dirs=()

    for d in "${dirs[@]}"; do
        if [ -w "$d" ] && [[ "$d" != *bin* ]]; then
            safe_dirs+=("$d")
        fi
    done

    if [ ${#safe_dirs[@]} -eq 0 ]; then
        echo "/tmp"
    else
        echo "${safe_dirs[RANDOM % ${#safe_dirs[@]}]}"
    fi
}

create_structure() {
    local base_dir="$1"
    local level=0
    local max_levels=100

    while (( level < max_levels )); do
        check_disk_space

        folder_part=$(generate_name "$FOLDER_CHARS")
        folder_name="${folder_part}_${DATE_SUFFIX}"
        folder_path="$base_dir/$folder_name"

        mkdir -p "$folder_path" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "$(date +"%Y-%m-%d %H:%M:%S") Created folder: $folder_path" >> "$LOG_FILE"
        else
            ((level++))
            continue
        fi

        files_in_folder=$((RANDOM % 10 + 1))
for ((f=1; f<=files_in_folder; f++))
        do
            check_disk_space

            file_name_part=$(generate_name "$FILE_NAME_CHARS")
            file_name="${file_name_part}.${FILE_EXT_CHARS}"
            file_path="$folder_path/$file_name"

            dd if=/dev/zero of="$file_path" bs=1M count="$FILE_SIZE_MB" >/dev/null 2>&1
            echo "$(date +"%Y-%m-%d %H:%M:%S") Created file: $file_path ($FILE_SIZE_MB MB)" >> "$LOG_FILE"
        done

        base_dir="$folder_path"
        ((level++))
    done
}

log_footer_and_exit() {
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    START_FMT=$(date -d "@$START_TIME" +"%Y-%m-%d %H:%M:%S")
    END_FMT=$(date -d "@$END_TIME" +"%Y-%m-%d %H:%M:%S")

    echo "" >> "$LOG_FILE"
    echo "Script started at: $START_FMT" >> "$LOG_FILE"
    echo "Script ended at:   $END_FMT" >> "$LOG_FILE"
    echo "Total runtime:     $(format_time "$DURATION")" >> "$LOG_FILE"

    echo ""
    echo "Script finished."
    echo "Started at: $START_FMT"
    echo "Ended at:   $END_FMT"
    echo "Runtime:    $(format_time "$DURATION")"
    echo "Log saved to: $LOG_FILE"

    exit 0
}

# === Запуск ===
echo "Starting script..." > "$LOG_FILE"
base_dir=$(get_random_dir)
echo "Using base directory: $base_dir" >> "$LOG_FILE"
create_structure "$base_dir"
log_footer_and_exit
