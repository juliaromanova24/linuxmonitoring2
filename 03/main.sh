#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <mode> [additional parameters]"
    echo "Modes:"
    echo "  1 <logfile>       : Delete by log file"
    echo "  2 <start> <end>   : Delete by time range (format: YYYY-MM-DD HH:MM)"
    echo "  3 <name_mask>     : Delete by name mask (e.g. az_050425)"
    exit 1
fi

MODE="$1"

case "$MODE" in
    1)
        if [ -z "$2" ] ||  [ ! -f "$2" ]; then
            echo "Error: Log file not found or missing."
            exit 1
        fi
        LOG_FILE="$2"

        echo "Deleting files and folders listed in log file: $LOG_FILE"
        while IFS= read -r line; do
            if [[ "$line" =~ Created\ (folder|file):\ (.*)$ ]]; then
                path="${BASH_REMATCH[2]}"
                if [ -e "$path" ]; then
                    echo "Removing: $path"
                    rm -rf "$path"
                fi
            fi
        done < "$LOG_FILE"
        ;;

    2)
        START_TIME="$2"
        END_TIME="$3"

        if [ -z "$START_TIME" ] || [ -z "$END_TIME" ]; then
            read -p "Enter start time (YYYY-MM-DD HH:MM): " START_TIME
            read -p "Enter end time (YYYY-MM-DD HH:MM): " END_TIME
        fi

        START_TS=$(date -d "$START_TIME" +%s 2>/dev/null)
        END_TS=$(date -d "$END_TIME" +%s 2>/dev/null)

        if [ $? -ne 0 ]; then
            echo "Error: Invalid date format. Use 'YYYY-MM-DD HH:MM'"
            exit 1
        fi

        echo "Deleting files created between '$START_TIME' and '$END_TIME'..."

        find / -type f -name "*_*" -newermt "$START_TIME" ! -newermt "$END_TIME" 2>/dev/null | while read -r file; do
            folder=$(dirname "$file")
            echo "Removing file: $file"
            rm -f "$file"
            rmdir "$folder" 2>/dev/null
        done
        ;;
    3)

read -p "Enter name mask (e.g. az_06125): " maska

if [[ "$maska" =~ ^([a-zA-Z]+)_([0-9]{6})$ ]]; then
    NAME_CHARS="${BASH_REMATCH[1]}"
    DATE_SUFFIX="${BASH_REMATCH[2]}"
else
    echo "Error: Mask must be in format '<letters>_<DDMMYY>', e.g. az_06125"
    exit 1
fi

echo "Searching by:"
echo " - Name chars: $NAME_CHARS"
echo " - Date suffix: _$DATE_SUFFIX"

find / \( ! -path '/bin/*' -a ! -path '/sbin/*' \) -type f,d -name "*_${DATE_SUFFIX}" 2>/dev/null | while read -r name_path; do
    base=$(basename "$name_path")
    name_part="${base%_*}"
    if [[ "$name_part" =~ ^[$NAME_CHARS]+$ ]]; then
        echo "Found: $name_path"
        rm -rf "$name_path"
    else
        echo "Skipped: $name_path (invalid characters)"
    fi
done

;;
    *)
        echo "Invalid mode: $MODE"
        echo "Use 1, 2 or 3"
        exit 1
        ;;
esac

echo "Cleanup completed."
