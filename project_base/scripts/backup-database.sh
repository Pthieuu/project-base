#!/usr/bin/env sh
set -eu

compose_file="${COMPOSE_FILE:-compose.prod.yaml}"
env_file="${ENV_FILE:-.env.production}"
backup_dir="${BACKUP_DIR:-backups}"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup_path="${backup_dir}/expense-manager-${timestamp}.sql"

mkdir -p "$backup_dir"
docker compose --env-file "$env_file" -f "$compose_file" exec -T database \
  sh -c 'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysqldump --single-transaction --routines --triggers -u root "$MYSQL_DATABASE"' \
  > "$backup_path"

chmod 600 "$backup_path"
echo "Database backup written to $backup_path"
