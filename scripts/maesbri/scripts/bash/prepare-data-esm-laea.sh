#!/bin/bash

source ./env.sh #this is the same as source ./env.sh


#################################################################################
### European Settlement Map
###
###
#################################################################################

prepare_esm_data() {
  # remove the temporal esm folder and recretate again the class 30, 40 y 50 folders
  echo '${DATA_TMP_ESM}: ' ${DATA_TMP_ESM}

  rm -r ${DATA_TMP_ESM}
  mkdir -p ${DATA_TMP_ESM_CLASS_30} ${DATA_TMP_ESM_CLASS_40} ${DATA_TMP_ESM_CLASS_50}


  unzip ${DATA_ESM_ZIPFILE} -d ${DATA_TMP_ESM}
  #unzip the European Settlement Map classes zip file to the temporal destinations
  for esm_file in `unzip -Z1 ${DATA_ESM_ZIPFILE} | sort`;
  do
    unzip -j ${DATA_TMP_ESM}/${esm_file} "**/class_30/*" -d ${DATA_TMP_ESM_CLASS_30}
    unzip -j ${DATA_TMP_ESM}/${esm_file} "**/class_40/*" -d ${DATA_TMP_ESM_CLASS_40}
    unzip -j ${DATA_TMP_ESM}/${esm_file} "**/class_50/*" -d ${DATA_TMP_ESM_CLASS_50}
    rm ${DATA_TMP_ESM}/${esm_file}
  done

  # build a VRT (Virtual Dataset) that is a mosaic of the list of each of the geotiffs contained in classes folders (30, 40 and 50)
  echo "Building a VRT mosaic of class 30"
  gdalbuildvrt ${DATA_TMP_ESM_CLASS_30}/class_30_index.vrt ${DATA_TMP_ESM_CLASS_30}/*.TIF
  echo "Building a VRT mosaic of class 40"
  gdalbuildvrt ${DATA_TMP_ESM_CLASS_40}/class_40_index.vrt ${DATA_TMP_ESM_CLASS_40}/*.TIF
  echo "Building a VRT mosaic of class 50"
  gdalbuildvrt ${DATA_TMP_ESM_CLASS_50}/class_50_index.vrt ${DATA_TMP_ESM_CLASS_50}/*.TIF

}

#################################################################################
### European Reference Grid (LAEA)
###
###
#################################################################################

prepare_laea_data() {
  # unzip and load the European Reference Grid into the database
  unzip ${DATA_LAEA_GRID_ZIPFILE} -d ${DATA_TMP_LAEA_GRID}
  
  ogr2ogr PG:"dbname=${PGDATABASE} host=${PGHOST} port=${PGPORT} user=${PGUSER} password=${PGPASSWORD}" -append -nln laea_etrs_500m ${DATA_TMP_LAEA_GRID}'/laea_etrs_500m.gpkg'

  # remove the European Reference Grid file
  rm -r ${DATA_TMP_LAEA_GRID}

  # perform clustering of the data and cleaning on the table based on the geohash index
  #psql -U "clarity" -h localhost -d "claritydb" -c "VACUUM ANALYZE laea_etrs_500m; CLUSTER public.laea_etrs_500m USING laea_etrs_500m_eorigin_norigin_idx;"
  psql -U ${PGUSER} -h ${PGHOST} -p ${PGPORT} -d ${PGDATABASE} -c "CLUSTER public.laea_etrs_500m USING laea_etrs_500m_geom_geohash_idx;"
  psql -U ${PGUSER} -h ${PGHOST} -p ${PGPORT} -d ${PGDATABASE} -c "VACUUM ANALYZE laea_etrs_500m;"

}



prepare_esm_data
#prepare_laea_data