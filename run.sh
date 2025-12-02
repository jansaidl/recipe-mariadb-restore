#!/bin/bash
set -e

# Default values
SOURCE_URL=""
SOURCE_DATABASE=""
SOURCE_PARAMS="-B"
OUTPUT_FILE="backup.sql"
BACKUP_DIR="/var/www/backup"
SOCKET="/tmp/mysql-restore-$$.sock"
PORT=3307

# Help function
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Downloads MariaDB backup from Zerops and creates SQL dump.

Required parameters:
    -u, --url URL           Backup download URL
    -d, --database DB       Database name

Optional parameters:
    -o, --output FILE       Output file (default: backup.sql)
    -P, --port PORT         Port for temporary DB (default: 3307)
    -b, --backup-dir DIR    Directory for extraction (default: /var/www/backup)
    --params PARAMS         Extra parameters for mariadb-dump (default: -B)
    -h, --help              Show this help

Examples:
    $(basename "$0") -u "https://api..." -d mydb
    $(basename "$0") --url "https://api..." --database mydb -o output.sql

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--url)
            SOURCE_URL="$2"
            shift 2
            ;;
        -d|--database)
            SOURCE_DATABASE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -P|--port)
            PORT="$2"
            shift 2
            ;;
        -b|--backup-dir)
            BACKUP_DIR="$2"
            shift 2
            ;;
        --params)
            SOURCE_PARAMS="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown parameter: $1"
            show_help
            exit 1
            ;;
    esac
done

# Check required parameters
if [ -z "$SOURCE_URL" ] || [ -z "$SOURCE_DATABASE" ]; then
    echo "ERROR: Missing required parameters!"
    echo ""
    show_help
    exit 1
fi

# Cleanup function
cleanup() {
    echo "Cleaning up..."
    if [ ! -z "$MARIADB_PID" ]; then
        sudo kill -9 $MARIADB_PID 2>/dev/null || true
        wait $MARIADB_PID 2>/dev/null || true
    fi
    rm -rf "$BACKUP_DIR"
    rm -f "$SOCKET"
}

trap cleanup EXIT

# Main logic
echo "=== Downloading and preparing backup ==="
rm -rf "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

curl "${SOURCE_URL}" | gzip -d -c - | mbstream -x -C "$BACKUP_DIR"
mariabackup --prepare --target-dir="$BACKUP_DIR"

echo ""
echo "=== Starting temporary MariaDB instance ==="
sudo mariadbd --datadir="$BACKUP_DIR" --skip-grant-tables --user=mysql --socket="$SOCKET" --port="$PORT" &
MARIADB_PID=$!

echo "Waiting for MariaDB to start..."
for i in {1..30}; do
    if mysqladmin -S "$SOCKET" ping &>/dev/null; then
        echo "✓ MariaDB ready"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "✗ Timeout waiting for MariaDB!"
        exit 1
    fi
    sleep 1
done

echo ""
echo "=== Creating SQL dump ==="
mariadb-dump -S "$SOCKET" ${SOURCE_PARAMS} "${SOURCE_DATABASE}" > "$OUTPUT_FILE"

echo "✓ Dump created: $OUTPUT_FILE ($(du -h "$OUTPUT_FILE" | cut -f1))"
echo ""
echo "=== Terminating MariaDB ==="

echo "Done!"