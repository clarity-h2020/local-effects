#!/bin/bash

LAYER="water"
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

#WATER AREAS (50000)
echo "...extract Urban Atlas data..."
ogr2ogr -sql "SELECT area,perimeter FROM "$SHP" WHERE CODE2012='50000'" $NAME $FILE
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

#building shadow 1 by default (not intersecting) and update with value 0 when interscting
echo "...Adding building shadow..."
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD building_shadow smallint DEFAULT 1;"
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET building_shadow=0 FROM "$SHP"_layers9_12 l WHERE ST_Intersects( x.geom , l.geom ) IS TRUE;"

#Clusterization
echo "...Clusterizing..."
#psql -U "postgres" -d "clarity" -c "CLUSTER public.\""$NAME"\" USING public.\""$NAME"\"_pkey;"

#FALTA VOLCAR SOBRE TABLA ROADS GLOBAL Y BORRAR LA TABLA ROADS DEL SHAPEFILE ACTUAL(ITALIA-NAPOLES)
#psql -U "postgres" -d "clarity" -c "INSERT INTO water(SELECT NEXTVAL('water_gid_seq'), area, perimeter, code2012, geom, albedo, emissivity, transmissivity, vegetation_shadow, run_off_coedfficient, building_shadow FROM "$NAME");"
#psql -U "postgres" -d "clarity" -c "DROP TABLE "$NAME";"
fi
