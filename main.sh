#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <option>"
    echo "Options:"
    echo "  1: Sort entries by response code"
    echo "  2: Show unique IPs"
    echo "  3: Show error requests (4xx or 5xx)"
    echo "  4: Show unique IPs from error requests"
    exit 1
fi

OPTION="$1"

LOG_FILE="../04/nginx_logs/access-2025-02-06.log"

if [ ! -f "$LOG_FILE" ]; then
    echo "Error: Log file not found at $LOG_FILE"
    exit 1
fi

case "$OPTION" in
    1)
        awk '{print ($9, $0)}' "$LOG_FILE" | sort -n
        ;;
    2)
        awk '{print $1}' "$LOG_FILE" | sort | uniq
        ;;
    3)
        awk '($9>=400 && $9<=503) {print}' "$LOG_FILE"
        ;;
    4)
        awk '($9>=400 && $9<=503) {print $1}' "$LOG_FILE" | sort | uniq
        ;;
    *)
        echo "Invalid option. Use 1, 2, 3, or 4."
        exit 1
        ;;
esac
