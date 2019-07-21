#!/bin/bash

# Let's export the password for 'clarity' database user so it is not asked everytime we use the psql command
export PGPASSWORD='IMHnl8ORQcuNtaujfY0V84BM6TWovROt'

# create the database table structure 
psql -U "clarity" -h localhost -d "claritydb" -f ./sql/create-database-model.sql

# load the European Reference Grid
ogr2ogr PG:"dbname='claritydb' host='localhost' port='5432' user='clarity' password=${PGPASSWORD}" -append -nln laea_etrs_500m laea_etrs_500m.gpkg

# perform clustering of the data and cleaning on the table based on the geohash index
#psql -U "clarity" -h localhost -d "claritydb" -c "VACUUM ANALYZE laea_etrs_500m; CLUSTER public.laea_etrs_500m USING laea_etrs_500m_eorigin_norigin_idx;"
psql -U "clarity" -h localhost -d "claritydb" -c "CLUSTER public.laea_etrs_500m USING laea_etrs_500m_geom_geohash_idx;"
psql -U "clarity" -h localhost -d "claritydb" -c "VACUUM ANALYZE laea_etrs_500m;"