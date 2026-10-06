#!/usr/bin/env bash
# Sauvegarde quotidienne de la base PostgreSQL (cron 02:00).
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-/var/backups/app}"
STAMP="$(date +%F)"

mkdir -p "$BACKUP_DIR"
docker compose exec -T db pg_dump -U "$DB_USER" "$DB_NAME" | gzip > "$BACKUP_DIR/db-$STAMP.sql.gz"
find "$BACKUP_DIR" -name 'db-*.sql.gz' -mtime +14 -delete
