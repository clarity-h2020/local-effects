#!/bin/bash

. ./env.sh

export CHECK_DISK_FREE_SPACE='NO'

# This method extracts the extent of a geospatial (vector-based) file as an arrary as the following:
# extent[0] = XMIN; extent[1] = YMIN; extent[2] = XMAX; extent[3] = YMAX
function get_extent() {
  local shpfile = $1
  local extent
  IFS=',' read -r -a extent <<< `ogrinfo -ro -so -al ${shpfile} | grep "Extent" | sed 's/[a-zA-Z\: ]//g' | sed 's/)\-(/,/g' | sed 's/[()]//g'`
  echo "${file} --> extent: ${extent[@]}"

  return extent
}

function get_geometry_as_wkt() {
  local shpfile = $1
  #Please, note that there are two blank spaces in the grep regular expression, this is necessary to find where the MULTIPOLYGON geometry string starts
  local wkt_geometry = `ogrinfo -ro -nomd -noextent -al -geom=ISO_WKT ${shpfile} | grep '^  MULTIPOLYGON'`

  return wkt_geometry
}


for city_file in `unzip -Z1 ${DATA_URBAN_ATLAS_ZIPFILE} | sort`;
do
  #let's extract from the filename the city code and name
  city_code=${city_file%_*} # remove from the filename everything from the "_" character (included)
  city_name=${city_file%.zip}
  city_name=${city_name:8}

  echo "Processing city file ${city_file} (name=${city_name}, code=${city_code}) ..."

  # prepare the temporal folder for processing the city
  rm -r ${DATA_TMP_CITY}



  # Let's first check whether we have all necessary layers

  # What this does is it lists all files in street-tree-layer.zip, pipes them to grep which searches for ${city_file}.
  # grep exits with exit code 0 if it has find a match. -q silences the output of grep and exits immediatelly with exit code 0 when it finds a match.
  # The echo $? will print the exit code of grep
  echo `unzip -Z1 ${DATA_STL_ZIPFILE} | sort | grep ${city_name}`
  unzip -Z1 ${DATA_STL_ZIPFILE} | grep -q ${city_name}
  if [ "$?" != "0" ]
  then
    echo "There is not STL for this city (${city_name}), let's skip it and process the next one"
    echo ${city_file%.zip} >> skipped_cities.txt
    continue
  fi;

  # Now, let's extract the different datasets we need for this city

  #############
  # URBAN ATLAS
  #############
  echo -e "\e[36mPreparing Urban Atlas data for the city (${city_name}) ...\e[0m"
  # create temporal ua (urban atlas) folder for this city
  mkdir -p ${DATA_TMP_CITY_URBAN_ATLAS}
  # extract from the large "urban-atlas-2012.zip" file the specific city .zip file
  unzip -j ${DATA_URBAN_ATLAS_ZIPFILE} "*${city_name}*.zip" -d ${DATA_TMP_CITY_URBAN_ATLAS}
  # and then extract only for that city the shapefile files with all the cartography and the boundaries
  unzip -j ${DATA_TMP_CITY_URBAN_ATLAS}/*${city_name}*.zip "*${city_name}*/Shapefiles/*${city_name}*_UA2012*" -d ${DATA_TMP_CITY_URBAN_ATLAS}
  rm ${DATA_TMP_CITY_URBAN_ATLAS}/*${city_name}*.zip
 
  ua_boundary_shpfile=`ls ${DATA_TMP_CITY_URBAN_ATLAS}/*UA2012_Boundary.shp`

  ua_shpfile=`ls ${DATA_TMP_CITY_URBAN_ATLAS}/*UA2012.shp`
  ua_table=`echo $(basename "${ua_shpfile%.shp}")`

  # get the city boundary
  city_boundary_wkt = `ogrinfo -ro -nomd -noextent -al -geom=ISO_WKT ${ua_boundary_shpfile} | grep '^  MULTIPOLYGON'`
  echo "${ua_shpfile} --> boundary: ${city_boundary_wkt}"

  # get the city bbox
  IFS=',' read -r -a city_extent <<< `ogrinfo -ro -so -al ${ua_boundary_shpfile} | grep "Extent" | sed 's/[a-zA-Z\: ]//g' | sed 's/)\-(/,/g' | sed 's/[()]//g'`
  echo "${ua_shpfile} --> extent: ${city_extent[@]}"

  
  #############
  # STL
  #############
  echo -e "\e[36mPreparing Street Tree Layer data for the city (${city_name}) ...\e[0m"
  # create temporal stl (street tree layer) folder for this city
  mkdir -p ${DATA_TMP_CITY_STL}
  # extract from the large "street-tree-layer.zip" file the specific city stl .zip file
  unzip -j ${DATA_STL_ZIPFILE} "*${city_name}*.zip" -d ${DATA_TMP_CITY_STL}
  # and then extract only for that city the shapefile files with all the trees cartography
  unzip -j ${DATA_TMP_CITY_STL}/*${city_name}*.zip "*${city_name}*/Shapefiles/*${city_name}*_UA2012_STL.*" -d ${DATA_TMP_CITY_STL}
  rm ${DATA_TMP_CITY_STL}/*${city_name}*.zip

  stl_shpfile=`ls ${DATA_TMP_CITY_STL}/*.shp`
  stl_table=`echo $(basename "${stl_shpfile%.shp}")`

  #############
  # ESM
  #############  
	echo -e "\e[36mClipping European Setlement Map data for the city (${city_name}) ...\e[0m"
  mkdir -p ${DATA_TMP_CITY_ESM}
  echo ${city_extent[0]} ${city_extent[2]} ${city_extent[1]} ${city_extent[3]}
	#Extracting bbox from VRT mosaic index all raster ESM files for the city
  #gdal_translate -projwin MINX MAXY MAXX MINY file.vrt output.tif
  
	gdal_translate -projwin ${city_extent[0]} ${city_extent[2]} ${city_extent[1]} ${city_extent[3]} ${DATA_TMP_ESM_CLASS_30}/class_30_index.vrt ${DATA_TMP_CITY_ESM}/class_30.tif
	gdal_translate -projwin ${city_extent[0]} ${city_extent[2]} ${city_extent[1]} ${city_extent[3]} ${DATA_TMP_ESM_CLASS_40}/class_40_index.vrt ${DATA_TMP_CITY_ESM}/class_40.tif
	gdal_translate -projwin ${city_extent[0]} ${city_extent[2]} ${city_extent[1]} ${city_extent[3]} ${DATA_TMP_ESM_CLASS_50}/class_50_index.vrt ${DATA_TMP_CITY_ESM}/class_50.tif

  


  
  # create the temporal tables structure in the database for processing the current city
  psql -U ${PGUSER} -h ${PGHOST} -p ${PGPORT} -d ${PGDATABASE} -f ../sql/create-tmp-city-tables.sql

  # insert in temporary "__urban_atlas" table the land use features needed for the processing
  echo "Inserting urban atlas data in database for city (${city_name}) ..."
  ogr2ogr PG:"dbname=${PGDATABASE} host=${PGHOST} port=${PGPORT} user=${PGUSER} password=${PGPASSWORD}" \
          -sql "SELECT CODE2012 AS featuretype_code FROM ${ua_table}" \
          -append -nln __urban_atlas ${ua_shpfile}

  #        -sql "SELECT CITIES AS city_name, FUA_OR_CIT AS city_code, COUNTRY AS countrycode, CODE2012 AS featuretype_code, FROM ${city_file%.zip} WHERE CODE2012 IN ['11100','11210','11220','11230','11240','11300','12100']" \

  # insert in temporary "__street_trees" table the tree features needed for the processing
  echo "Inserting street trees data in database for city (${city_name}) ..."
  ogr2ogr PG:"dbname=${PGDATABASE} host=${PGHOST} port=${PGPORT} user=${PGUSER} password=${PGPASSWORD}" \
          -sql "SELECT COUNTRY FROM ${stl_table}" \
          -append -nln __street_trees ${stl_shpfile}

  #        -sql "SELECT CITIES AS city_name, FUA_OR_CIT AS city_code, COUNTRY AS countrycode, CODE2012 AS featuretype_code, FROM ${city_file%.zip} WHERE CODE2012 IN ['11100','11210','11220','11230','11240','11300','12100']" \

  psql -U ${PGUSER} -h ${PGHOST} -p ${PGPORT} -d ${PGDATABASE} \
       -v city_name="'${city_name}'" \
       -v city_code="'${city_code}'" \
       -v country_code="'${city_code:0:2}'" \
       -v city_boundary="'${city_boundary}'" \
       -f ../sql/process-tmp-city-tables.sql

done;

