#!/bin/bash

# Let's export the password for 'clarity' database user so it is not asked everytime we use the psql command
export PGUSER='clarity'
export PGPASSWORD='IMHnl8ORQcuNtaujfY0V84BM6TWovROt'
export PGDATABASE='claritydb'
export PGHOST='localhost'
export PGPORT='5432'



# Data sources
export DATA_ROOT='/media/maesbri/57AA17F37EE06F89/clarity/data'
export DATA_LAEA_GRID_ZIPFILE=${DATA_ROOT}'/european-reference-grid/laea_etrs_500m.gpkg.zip'
#export DATA_URBAN_ATLAS_ZIPFILE=${DATA_ROOT}'/urban-atlas/2012/urban-atlas-2012.zip'
export DATA_URBAN_ATLAS_ZIPFILE=${DATA_ROOT}'/urban-atlas/2012/fake-urban-atlas-2012.zip'
export DATA_ESM_ZIPFILE=${DATA_ROOT}'/european-settlement-map-2012-Rel2017/ESM2012_Rel2017_200km_10m.zip'
export DATA_STL_ZIPFILE=${DATA_ROOT}'/street-tree-layer/street-tree-layer.zip'

# Temporal processing directory
#export DATA_TMP=${DATA_ROOT}'/tmp'
export DATA_TMP='/data/clarity-data'

export DATA_TMP_LAEA_GRID=${DATA_TMP}'/european-reference-grid'

export DATA_TMP_ESM=${DATA_TMP}'/esm'
export DATA_TMP_ESM_CLASS_30=${DATA_TMP_ESM}'/class_30'
export DATA_TMP_ESM_CLASS_40=${DATA_TMP_ESM}'/class_40'
export DATA_TMP_ESM_CLASS_50=${DATA_TMP_ESM}'/class_50'

export DATA_TMP_CITY=${DATA_TMP}'/city'
export DATA_TMP_CITY_URBAN_ATLAS=${DATA_TMP_CITY}'/ua'
export DATA_TMP_CITY_ESM=${DATA_TMP_CITY}'/esm'
export DATA_TMP_CITY_STL=${DATA_TMP_CITY}'/stl'