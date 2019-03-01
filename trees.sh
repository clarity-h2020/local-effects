#!/bin/bash

LAYER="trees"
CITY=$(echo "$1" | awk '{print toupper($0)}')

FOLDER_UA="data/"$CITY"/ua"
FILE_UA=`ls -la $FOLDER_UA/*.shp | cut -f 9 -d ' '`
SHP_UA=`ogrinfo $FILE_UA | grep '1:' | cut -f 2 -d ' '`
NAME=$(echo $SHP_UA"_"$LAYER | awk '{print tolower($0)}')

FOLDER_STL="data/"$CITY"/stl"
FILE_STL=`ls -la $FOLDER_STL/*.shp | cut -f 9 -d ' '`
SHP_STL=`ogrinfo $FILE_STL | grep '1:' | cut -f 2 -d ' '`

if [ ! "$FILE_UA" ] || [ ! "$FILE_STL" ]; then
    echo "ERROR: City data not found!"
else

#TREES URBAN ATLAS(31000)
echo "...Extract Urban Atlas data..."
ogr2ogr -sql "SELECT area,perimeter FROM "$SHP_UA" WHERE CODE2012='31000'" $NAME $FILE_UA
shp2pgsql -k -s 3035 -S -I -d $NAME/$SHP_UA.shp $NAME > $NAME".sql"
rm -r $NAME
psql -d clarity -U postgres -f $NAME".sql"
rm $NAME".sql"

#trees STL
echo "...Extract STL data..."
ogr2ogr -sql "SELECT shape_area as area, shape_leng as perimeter FROM "$SHP_STL" WHERE STL=1" $NAME $FILE_STL
shp2pgsql -k -s 3035 -S -I -a $NAME/$SHP_STL.shp $NAME > $NAME".sql"
rm -r $NAME
psql -d clarity -U postgres -f $NAME".sql"
rm $NAME".sql"

#PARAMETERS
PARAMETERS="parameters"
ALBEDO=`grep -i -F [$LAYER] $PARAMETERS/albedo.dat | cut -f 2 -d ' '`
EMISSIVITY=`grep -i -F [$LAYER] $PARAMETERS/emissivity.dat | cut -f 2 -d ' '`
TRANSMISSIVITY=`grep -i -F [$LAYER] $PARAMETERS/transmissivity.dat | cut -f 2 -d ' '`
VEGETATION_SHADOW=`grep -i -F [$LAYER] $PARAMETERS/vegetation_shadow.dat | cut -f 2 -d ' '`
RUNOFF_COEFFICIENT=`grep -i -F [$LAYER] $PARAMETERS/run_off_coefficient.dat | cut -f 2 -d ' '`

#adding rest of parameters
echo "...Adding rest of parameters..."
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD albedo real DEFAULT "$ALBEDO";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD emissivity real DEFAULT "$EMISSIVITY";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD transmissivity real DEFAULT "$TRANSMISSIVITY";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD vegetation_shadow real DEFAULT "$VEGETATION_SHADOW";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD run_off_coefficient real DEFAULT "$RUNOFF_COEFFICIENT";"

#building shadow 1 by default(not intersecting) then update with value 0 when intersecting
echo "...Adding building shadow..."
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD building_shadow smallint DEFAULT 1;"
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET building_shadow=0 FROM "$SHP_UA"_layers9_12 l WHERE ST_Intersects( x.geom , l.geom ) IS TRUE;"

###MISSING HILLSHADE GREEN FRACTION, we do not know where to get tree type... so we set default value 0.37
echo "...Adding hillshade green fraction..."
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD hillshade_green_fraction real DEFAULT 0.37;"

#Clusterization
echo "...Clusterizing..."
#psql -U "postgres" -d "clarity" -c "CLUSTER public.\""$NAME"\" USING public.\""$NAME"\"_pkey;"

#FALTA VOLCAR SOBRE TABLA ROADS GLOBAL Y BORRAR LA TABLA trees DEL SHAPEFILE ACTUAL(ITALIA-NAPOLES)
#psql -U "postgres" -d "clarity" -c "INSERT INTO trees(SELECT NEXTVAL('trees_gid_seq'), area, perimeter, code2012, geom, albedo, emissivity, transmissivity, vegetation_shadow, run_off_coedfficient, building_shadow, hillshade_green_fraction FROM "$NAME");"
#psql -U "postgres" -d "clarity" -c "DROP TABLE "$NAME";"
fi
