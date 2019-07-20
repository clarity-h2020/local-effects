#!/bin/bash

# create the database table structure 
psql -U "postgres" -d "claritydb" -f ./sql/01_create-model.sql

# load the European Reference Grid
ogr2ogr PG:"dbname='claritydb' host='localhost' port='5432' user='clarity' password='IMHnl8ORQcuNtaujfY0V84BM6TWovROt'" -append -nln laea_etrs_500m laea_etrs_500m.gpkg

# perform cleaning on the table and cluster the data based on the eorigin and norigin index
psql -U "postgres" -d "claritydb" -c "VACUUM ANALYZE laea_etrs_500m; CLUSTER public.laea_etrs_500m USING laea_etrs_500m_eorigin_norigin_idx;"