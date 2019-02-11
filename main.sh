#!/bin/bash

INDEX="parameters/layers.dat"
FILE="data/UA_IT003L3_NAPOLI/Shapefiles/IT003L3_NAPOLI_UA2012.shp"
#FILE1=$1
NAME=`ogrinfo $FILE | grep '1:' | cut -f 2 -d ' ' | tr [:upper:] [:lower:]`

echo "Importing..." $NAME

#create database table layers_9_12 for other scripts to operate
#source layers9_12.sh

#run each script in corresponding order
#while read -r LINE;
#do
#	LAYER=echo $LINE | cut -f 2 -d ' '
#	source $LAYER.sh
#done < "$INDEX"

#TODO: rasterize every data table generated to get a tif raster file

#put current region water data on global water table and delete current region water table
#psql -U "postgres" -d "clarity" -c "INSERT INTO water(SELECT NEXTVAL('water_gid_seq'), area, perimeter, code2012, geom, albedo, emissivity, transmissivity, vegetation_shadow, run_off_coedfficient, building_shadow FROM "$NAME"_water);"
#psql -U "postgres" -d "clarity" -c "DROP TABLE "$NAME"_water;"
#TODO: rest of the layers migrations...

#once import finished then delete layers9_12 from database (HOW TO CHECK IF REGION IS ALREADY LOADED IN THE SYSTEM?)
#psql -U "postgres" -d "clarity" -c "DROP TABLE "$NAME"_layers9_12;"
