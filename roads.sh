#!/bin/bash

LAYER="roads"
CITY=$(echo "$1" | awk '{print toupper($0)}')
FOLDER="data/"$CITY"/ua"
FILE=`ls -la $FOLDER/*.shp | cut -f 9 -d ' '`
if [ ! "$FILE" ]; then
    echo "ERROR: City data not found!"
else
SHP=`ogrinfo $FILE | grep '1:' | cut -f 2 -d ' '`
NAME=$(echo $SHP"_"$LAYER | awk '{print tolower($0)}')

#PARAMETERS
PARAMETERS="parameters"
ALBEDO=`grep -i -F [$LAYER] $PARAMETERS/albedo.dat | cut -f 2 -d ' '`
EMISSIVITY=`grep -i -F [$LAYER] $PARAMETERS/emissivity.dat | cut -f 2 -d ' '`
TRANSMISSIVITY=`grep -i -F [$LAYER] $PARAMETERS/transmissivity.dat | cut -f 2 -d ' '`
VEGETATION_SHADOW=`grep -i -F [$LAYER] $PARAMETERS/vegetation_shadow.dat | cut -f 2 -d ' '`
RUNOFF_COEFFICIENT=`grep -i -F [$LAYER] $PARAMETERS/run_off_coefficient.dat | cut -f 2 -d ' '`

#ROADS (12210 Fast transit roads and associated land,12220 Other roads and associated land)
echo "...Extract Urban Atlas data..."
ogr2ogr -sql "SELECT area,perimeter FROM "$SHP" WHERE CODE2012='12210' OR CODE2012='12220'" $NAME $FILE
shp2pgsql -k -s 3035 -S -I -d $NAME/$SHP.shp $NAME > $NAME".sql"
rm -r $NAME
psql -d clarity -U postgres -f $NAME".sql"
rm $NAME".sql"

#adding rest of parameters
echo "...Adding rest of parameters..."
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD albedo real DEFAULT "$ALBEDO";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD emissivity real DEFAULT "$EMISSIVITY";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD transmissivity real DEFAULT "$TRANSMISSIVITY";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD vegetation_shadow real DEFAULT "$VEGETATION_SHADOW";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD run_off_coefficient real DEFAULT "$RUNOFF_COEFFICIENT";"

#building shadow 1 by default(not intersecting) then update with value 0 when intersection occurs
echo "...Adding building shadow..."
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD building_shadow smallint DEFAULT 1;"
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET building_shadow=0 FROM "$SHP"_layers9_12 l WHERE ST_Intersects( x.geom , l.geom ) IS TRUE;"

echo "...Adding hillshade building..."
#hillshade_building 0 by default then update depending on intersections
psql -U "postgres" -d "clarity" -c "ALTER TABLE public.\""$NAME"\" ADD hillshade_building real DEFAULT 0;"
#hillshade_building intersection with public_military_industrial(CODE2012=12100)
VALUE=`grep -i -F [12100] parameters/hillshade_buildings.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET hillshade_building="$VALUE" FROM "$SHP"_layers9_12 l WHERE l.CODE2012='12100' AND ST_Intersects( x.geom , l.geom ) IS TRUE;"
#hillshade_building intersection with low_urban_fabric(CODE2012=11230,11240,11300)
VALUE=`grep -i -F [11230] parameters/hillshade_buildings.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET hillshade_building="$VALUE" FROM "$SHP"_layers9_12 l WHERE l.CODE2012='11230' AND ST_Intersects( x.geom , l.geom ) IS TRUE;"
VALUE=`grep -i -F [11240] parameters/hillshade_buildings.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET hillshade_building="$VALUE" FROM "$SHP"_layers9_12 l WHERE l.CODE2012='11240' AND ST_Intersects( x.geom , l.geom ) IS TRUE;"
VALUE=`grep -i -F [11300] parameters/hillshade_buildings.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET hillshade_building="$VALUE" FROM "$SHP"_layers9_12 l WHERE l.CODE2012='11300' AND ST_Intersects( x.geom , l.geom ) IS TRUE;"
#hillshade_building intersection with medium_urban_fabric(CODE2012=11220)
VALUE=`grep -i -F [11220] parameters/hillshade_buildings.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET hillshade_building="$VALUE" FROM "$SHP"_layers9_12 l WHERE l.CODE2012='11220' AND ST_Intersects( x.geom , l.geom ) IS TRUE;"
#hillshade_building intersection with dense_urban_fabric(CODE2012=11210,11100)
VALUE=`grep -i -F [11210] parameters/hillshade_buildings.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET hillshade_building="$VALUE" FROM "$SHP"_layers9_12 l WHERE l.CODE2012='11210' AND ST_Intersects( x.geom , l.geom ) IS TRUE;"
VALUE=`grep -i -F [11100] parameters/hillshade_buildings.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET hillshade_building="$VALUE" FROM "$SHP"_layers9_12 l WHERE l.CODE2012='11100' AND ST_Intersects( x.geom , l.geom ) IS TRUE;"

#Clusterization
echo "...Clusterizing..."
#psql -U "postgres" -d "clarity" -c "CLUSTER public.\""$NAME"\" USING public.\""$NAME"\"_pkey;"

#FALTA VOLCAR SOBRE TABLA ROADS GLOBAL Y BORRAR LA TABLA ROADS DEL SHAPEFILE ACTUAL(ITALIA-NAPOLES)
#psql -U "postgres" -d "clarity" -c "INSERT INTO roads(SELECT NEXTVAL('roads_gid_seq'), area, perimeter, code2012, geom, albedo, emissivity, transmissivity, vegetation_shadow, run_off_coedfficient, building_shadow, hillshade_building FROM "$NAME");"
#psql -U "postgres" -d "clarity" -c "DROP TABLE "$NAME";"
fi
