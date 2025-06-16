#!/bin/bash

if [ "$#" -ne 6 ]; then
    echo "Usage: $0 <dir> <nested_levels> <folder_chars> <files_per_folder> <file_chars> <file_size_kb>"
    exit 1
fi

TARGET_DIR="$1"
NESTED_LEVELS="$2"
FOLDER_CHARS="$3"
FILES_PER_FOLDER="$4"
FILE_CHARS="$5"
FILE_SIZE_KB="$6"

DATE_SUFFIX=$(date +"%d%m%y")

LOG_FILE="${TARGET_DIR}/creation_log_${DATE_SUFFIX}.log"

if [[ ! "$TARGET_DIR" =~ ^/ ]]; then
    echo "Error: First parameter must be an absolute path."
    exit 1
fi

mkdir -p "$TARGET_DIR"
if [ $? -ne 0 ]; then
    echo "Error: Cannot create or access target directory '$TARGET_DIR'."
    exit 1
fi

if ! [[ "$NESTED_LEVELS" =~ ^[0-9]+$ ]]; then
    echo "Error: Second parameter must be a number (nested folder levels)."
    exit 1
fi


if ! [[ "$FILES_PER_FOLDER" =~ ^[0-9]+$ ]]; then
    echo "Error: Fourth parameter must be a number (number of files per folder)."
    exit 1
fi

if ! [[ "$FILE_SIZE_KB" =~ ^([1-9][0-9]{0,2}|1000)$ ]]; then
    echo "Error: Sixth parameter must be a number between 1 and 1000 KB."
    exit 1
fi

is_valid_chars() {
    local chars="$1"
    if [[ "$chars" =~ [^a-zA-Z.] ]]; then
        return 1
    fi
    return 0
}

if ! is_valid_chars "$FOLDER_CHARS"; then
    echo "Error: Third parameter contains invalid characters. Only lowercase or uppercase a-z allowed."
    exit 1
fi

if [ "${#FOLDER_CHARS}" -gt 7 ]; then
    echo "Error: Third parameter can have at most 7 letters for folder names."
    exit 1
fi

if ! is_valid_chars "$FILE_CHARS"; then
    echo "Error: Fifth parameter contains invalid characters. Only lowercase or uppercase a-z allowed."
    exit 1
fi

IFS='.' read -r FILE_NAME_CHARS FILE_EXT_CHARS <<< "$FILE_CHARS"
if [ -z "$FILE_EXT_CHARS" ]; then
    FILE_EXT_CHARS="txt"
fi

if [ "${#FILE_EXT_CHARS}" -gt 3 ]; then
    echo "Error: File extension part in fifth parameter must be at most 3 characters."
    exit 1
fi

if [ "${#FILE_NAME_CHARS}" -gt 7 ]; then
    echo "Error: Filename part in fifth parameter must be at most 7 characters."
    exit 1
fi

generate_name() {
    local chars="$1"
    local min_length=4
    local max_length=10
    local length=$((RANDOM % (max_length - min_length + 1) + min_length))

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
    
check_disk_space() {
    local free_space=$(df -k / | awk 'NR==2 {print $4}')
    if [ "$free_space" -lt 1048576 ]; then # 1GB = 1048576KB
        echo "Not enough disk space. At least 1 GB required."
        exit 0
    fi
}

create_structure() {
    local current_path="$1"
    local level="$2"
    local prefix="$3"

    if [ "$level" -le 0 ]; then
        return
    fi

    for ((i=1; i<=NESTED_LEVELS; i++))
    do
        folder_part=$(generate_name "$FOLDER_CHARS")
        folder_name="${folder_part}_${DATE_SUFFIX}"
        folder_path="${current_path}/${folder_name}"

        mkdir -p "$folder_path"
        if [ $? -eq 0 ]; then
            echo "$(date +"%Y-%m-%d %H:%M:%S") Created folder: $folder_path" >> "$LOG_FILE"
        else
            echo "Failed to create folder: $folder_path"
            continue
        fi

        for ((f=1; f<=FILES_PER_FOLDER; f++))
        do
            file_name_part=$(generate_name "$FILE_NAME_CHARS")
            file_name="${file_name_part}.${FILE_EXT_CHARS}"
            file_path="${folder_path}/${file_name}"


            check_disk_space

            dd if=/dev/zero of="$file_path" bs=1024 count="$FILE_SIZE_KB" >/dev/null 2>&1
            if [ $? -eq 0 ]; then
                echo "$(date +"%Y-%m-%d %H:%M:%S") Created file: $file_path ($FILE_SIZE_KB KB)" >> "$LOG_FILE"
            else
                echo "Failed to create file: $file_path"
            fi
        done

        create_structure "$folder_path" $((level-1)) ""
    done
}


echo "Starting creation process..." > "$LOG_FILE"
create_structure "$TARGET_DIR" "$NESTED_LEVELS"
echo "Creation completed. Log saved to $LOG_FILE"
