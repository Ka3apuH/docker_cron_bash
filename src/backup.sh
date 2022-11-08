#!/usr/bin/env bash

set -eu
set -o pipefail

source /project_env.sh

echo "Creating backup of $POSTGRES_DATABASE database..."
pg_dump --format=custom \
        -h $POSTGRES_HOST \
        -p $POSTGRES_PORT \
        -U $POSTGRES_USER \
        -d $POSTGRES_DATABASE \
        $PGDUMP_EXTRA_OPTS \
        | gzip > db.dump.gz

timestamp=$(date +"%Y-%m-%dT%H:%M:%S")

s3_minio_uri_base="myminio/${MINIO_BUSKET_PATH}/${POSTGRES_DATABASE}_${timestamp}.dump.gz"


if [ -n "$PASSPHRASE" ]; then
  echo "Encrypting backup..."
  gpg --symmetric --batch --passphrase "$PASSPHRASE" db.dump
  rm db.dump
  local_file="db.dump.gz.gpg"
  s3_uri="${s3_minio_uri_base}.gpg"
else
  local_file="db.dump.gz"
  s3_uri="${s3_minio_uri_base}"
fi

mcli cp "$local_file" "$s3_uri"
rm "$local_file"

echo "Backup complete."
