#!/bin/bash

source env.sh

# load the European Reference Grid
ogr2ogr PG:"dbname=${PGDATABASE} host=${PGHOST} port=${PGPORT} user=${PGUSER} password=${PGPASSWORD}" -append -nln laea_etrs_500m ${DATA_ROOT}/"european-reference-grid/laea_etrs_500m.gpkg"

# perform clustering of the data and cleaning on the table based on the geohash index
#psql -U "clarity" -h localhost -d "claritydb" -c "VACUUM ANALYZE laea_etrs_500m; CLUSTER public.laea_etrs_500m USING laea_etrs_500m_eorigin_norigin_idx;"
psql -U ${PGUSER} -h ${PGHOST} -p ${PGPORT} -d ${PGDATABASE} -c "CLUSTER public.laea_etrs_500m USING laea_etrs_500m_geom_geohash_idx;"
psql -U ${PGUSER} -h ${PGHOST} -p ${PGPORT} -d ${PGDATABASE} -c "VACUUM ANALYZE laea_etrs_500m;"