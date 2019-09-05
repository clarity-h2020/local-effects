#!/bin/bash
#NOTE: Execute the script like this: bash ./script.sh, otherwise some commands may not work, e.g., source, <<<, etc.


source ./env.sh

cat ${DATA_ROOT}'/database-backup/'${PGDATABASE}.pgsql.gz* | gunzip | psql -U ${PGUSER} -h ${PGHOST} -p ${PGPORT} -d ${PGDATABASE}