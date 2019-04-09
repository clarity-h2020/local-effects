#!/bin/bash
CODE="CODE2006"
#CODE="CODE2012"

LAYER="roads"
if [[ $# -eq 0 ]] ; then
    echo -e "\e[33mERROR: No city name provided!\e[0m"
    exit 1
fi
CITY=$(echo "$1" | awk '{print toupper($0)}')
FOLDER="data/"$CITY"/ua"
FILE=`ls -la $FOLDER/*.shp | cut -f 10 -d ' '`
if [ ! "$FILE" ]; then
    echo "ERROR: City data not found!"
else
SHP=`ogrinfo $FILE | grep '1:' | cut -f 2 -d ' '`
NAME=$(echo $CITY"_"$LAYER | awk '{print tolower($0)}')

#PARAMETERS
PARAMETERS="parameters"
ALBEDO=`grep -i -F [$LAYER] $PARAMETERS/albedo.dat | cut -f 2 -d ' '`
EMISSIVITY=`grep -i -F [$LAYER] $PARAMETERS/emissivity.dat | cut -f 2 -d ' '`
TRANSMISSIVITY=`grep -i -F [$LAYER] $PARAMETERS/transmissivity.dat | cut -f 2 -d ' '`
VEGETATION_SHADOW=`grep -i -F [$LAYER] $PARAMETERS/vegetation_shadow.dat | cut -f 2 -d ' '`
RUNOFF_COEFFICIENT=`grep -i -F [$LAYER] $PARAMETERS/run_off_coefficient.dat | cut -f 2 -d ' '`

#ROADS (12210 Fast transit roads and associated land,12220 Other roads and associated land)
echo "...Extract Urban Atlas data..."
#ogr2ogr -sql "SELECT area,perimeter FROM "$SHP" WHERE "$CODE"='12210' OR "$CODE"='12220'" $NAME $FILE
ogr2ogr -overwrite -sql "SELECT Shape_Area as area, Shape_Leng as perimeter FROM "$SHP" WHERE "$CODE"='12210' OR "$CODE"='12220'" $NAME $FILE
shp2pgsql -k -s 3035 -S -I -d $NAME/$SHP.shp $NAME > $NAME".sql"
rm -r $NAME
psql -d clarity -U postgres -f $NAME".sql"
rm $NAME".sql"

#NOT NEED TO REMOVE INTERSECTIONS

#adding rest of parameters
echo "...Adding rest of parameters..."
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD albedo real DEFAULT "$ALBEDO";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD emissivity real DEFAULT "$EMISSIVITY";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD transmissivity real DEFAULT "$TRANSMISSIVITY";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD vegetation_shadow real DEFAULT "$VEGETATION_SHADOW";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD run_off_coefficient real DEFAULT "$RUNOFF_COEFFICIENT";"

#Adding FUA_TUNNEL, apply 1 as default
echo "...Adding FUA_TUNNEL..."
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD fua_tunnel real DEFAULT 1;"
FUA_TUNNEL=`grep -i -F ['dense_urban_fabric'] $PARAMETERS/fua_tunnel.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET fua_tunnel="$FUA_TUNNEL" FROM "$CITY"_layers9_12 l WHERE ("$CODE"='11100' OR "$CODE"='11210') AND ST_Intersects( x.geom , l.geom );"
FUA_TUNNEL=`grep -i -F ['medium_urban_fabric'] $PARAMETERS/fua_tunnel.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET fua_tunnel="$FUA_TUNNEL" FROM "$CITY"_layers9_12 l WHERE "$CODE"='11220' AND ST_Intersects( x.geom , l.geom );"

#building shadow 1 by default(not intersecting) then update with value 0 when intersection occurs
echo "...Adding building shadow..."
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD building_shadow smallint DEFAULT 1;"
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET building_shadow=0 FROM "$CITY"_layers9_12 l WHERE ST_Intersects( x.geom , l.geom ) IS TRUE;"

echo "...Adding hillshade building..."
#hillshade_building 1 by default then update depending on intersections
psql -U "postgres" -d "clarity" -c "ALTER TABLE public.\""$NAME"\" ADD hillshade_building real DEFAULT 1;"
#hillshade_building intersection with public_military_industrial(CODE=12100)
VALUE=`grep -i -F [public_military_industrial] parameters/hillshade_buildings.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET hillshade_building="$VALUE" FROM "$CITY"_layers9_12 l WHERE l."$CODE"='12100' AND ST_Intersects( x.geom , l.geom ) IS TRUE;"
#hillshade_building intersection with low_urban_fabric(CODE=11230,11240,11300)
VALUE=`grep -i -F [low_urban_fabric] parameters/hillshade_buildings.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET hillshade_building="$VALUE" FROM "$CITY"_layers9_12 l WHERE l."$CODE"='11230' AND ST_Intersects( x.geom , l.geom ) IS TRUE;"
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET hillshade_building="$VALUE" FROM "$CITY"_layers9_12 l WHERE l."$CODE"='11240' AND ST_Intersects( x.geom , l.geom ) IS TRUE;"
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET hillshade_building="$VALUE" FROM "$CITY"_layers9_12 l WHERE l."$CODE"='11300' AND ST_Intersects( x.geom , l.geom ) IS TRUE;"
#hillshade_building intersection with medium_urban_fabric(CODE=11220)
VALUE=`grep -i -F [medium_urban_fabric] parameters/hillshade_buildings.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET hillshade_building="$VALUE" FROM "$CITY"_layers9_12 l WHERE l."$CODE"='11220' AND ST_Intersects( x.geom , l.geom ) IS TRUE;"
#hillshade_building intersection with dense_urban_fabric(CODE=11210,11100)
VALUE=`grep -i -F [dense_urban_fabric] parameters/hillshade_buildings.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET hillshade_building="$VALUE" FROM "$CITY"_layers9_12 l WHERE l."$CODE"='11210' AND ST_Intersects( x.geom , l.geom ) IS TRUE;"
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET hillshade_building="$VALUE" FROM "$CITY"_layers9_12 l WHERE l."$CODE"='11100' AND ST_Intersects( x.geom , l.geom ) IS TRUE;"

#Clusterization
echo "...Clusterizing..."
#psql -U "postgres" -d "clarity" -c "CLUSTER public.\""$NAME"\" USING public.\""$NAME"\"_pkey;"

#TAKE EVERYTHING FROM CITY TABLE TO GENERAL TABLE
#psql -U "postgres" -d "clarity" -c "INSERT INTO roads (SELECT * FROM "$NAME");"
fi
