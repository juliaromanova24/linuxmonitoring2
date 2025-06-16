#!/bin/bash


LOG_DIR="./nginx_logs"
mkdir -p "$LOG_DIR"

RESPONSE_CODES=(200 201 400 401 403 404 500 501 502 503)
HTTP_METHODS=("GET" "POST" "PUT" "PATCH" "DELETE")
USER_AGENTS=(
    "Mozilla"
    "Chrome"
    "Edg"
    "Safari"
    "Opera"
    "Mozilla"
    "curl"
    "Wget"
)

URL_PATHS=(
    "/" "/index.html" "/about" "/contact" "/login" "/api/data" "/search" "/dashboard"
    "/profile" "/settings" "/register" "/admin" "/robots.txt" "/favicon.ico"
)


cat << 'EOF'
# Коды ответов:
# 200 — OK
# 201 — Created
# 400 — Bad Request
# 401 — Unauthorized
# 403 — Forbidden
# 404 — Not Found
# 500 — Internal Server Error
# 501 — Not Implemented
# 502 — Bad Gateway
# 503 — Service Unavailable
EOF
generate_random() {
    local max=$(( RANDOM-1))
    shuf -i 0-$max -n 1
}

START_DATE="2025-02-06"
for i in {0..4}; do
    LOG_DATE=$(date -d "$START_DATE +$i days" +"%d/%b/%Y")
    FILENAME="$LOG_DIR/access-$(date -d "$START_DATE +$i days" +"%Y-%m-%d").log"
    RECORD_COUNT=$((generate_random % 901 + 100))

    echo "Generating $RECORD_COUNT records for $LOG_DATE -> $FILENAME"

    > "$FILENAME"

    START_TIME=$(date -d "$LOG_DATE" +%s)
    END_TIME=$((START_TIME + 86400))

    for ((j=1; j<=RECORD_COUNT; j++)); do
        ip="$((RANDOM%256)).$((RANDOM%256)).$((RANDOM%256)).$((RANDOM%256))"
        method=${HTTP_METHODS[ $((RANDOM%${#HTTP_METHODS[@]}))]}
        url=${URL_PATHS[$((RANDOM%${#URL_PATHS[@]}))]}

        code=${RESPONSE_CODES[$((RANDOM%${#RESPONSE_CODES[@]}))]}

        size=$((RANDOM%10240))

        rand_sec=$((generate_random % 86400))
        timestamp=$(date -d "today -${index} days" "+%d/%b/%Y:%H:%M:%S %z")

        user_agent="${USER_AGENTS[$((RANDOM%${#USER_AGENTS[@]}))]}"

        line="$ip - - [$timestamp] \"$method $url HTTP/1.1\" $code $size - \"$user_agent\""
	echo "$line" >> "$FILENAME"
	echo "DEBUG: Wrote line to $FILENAME: $line"

    done
done

echo "Logs generated successfully in directory: $LOG_DIR"
