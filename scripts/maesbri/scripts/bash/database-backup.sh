#!/bin/bash
#NOTE: Execute the script like this: bash ./script.sh, otherwise some commands may not work, e.g., source, <<<, etc.

source ./env.sh

pg_dump -U ${PGUSER} -h ${PGHOST} -p ${PGPORT} -d ${PGDATABASE} | gzip -9 | split -b 500M - ${DATA_ROOT}'/database-backup/'${PGDATABASE}.pgsql.gz