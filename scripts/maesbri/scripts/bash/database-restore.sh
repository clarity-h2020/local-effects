#!/bin/bash

source ./env.sh

cat ${DATA_ROOT}'/database-backup/'${PGDATABASE}.pgsql.gz* | gunzip | psql -U ${PGUSER} -h ${PGHOST} -p ${PGPORT} -d ${PGDATABASE}