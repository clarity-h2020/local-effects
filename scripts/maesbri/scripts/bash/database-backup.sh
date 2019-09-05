#!/bin/bash

. ./env.sh

pg_dump -U ${PGUSER} -h ${PGHOST} -p ${PGPORT} -d ${PGDATABASE} | gzip -9 | split -b 500M - ${DATA_ROOT}'/database-backup/'${PGDATABASE}.pgsql.gz