#!/bin/bash

LAYER="trees"

#PARAMETERS
PARAMETERS="../parameters"
ALBEDO=`grep -i -F [$LAYER] $PARAMETERS/albedo.dat | cut -f 2 -d ' '`
EMISSIVITY=`grep -i -F [$LAYER] $PARAMETERS/emissivity.dat | cut -f 2 -d ' '`
TRANSMISSIVITY=`grep -i -F [$LAYER] $PARAMETERS/transmissivity.dat | cut -f 2 -d ' '`
VEGETATION_SHADOW=`grep -i -F [$LAYER] $PARAMETERS/vegetation_shadow.dat | cut -f 2 -d ' '`
RUNOFF_COEFFICIENT=`grep -i -F [$LAYER] $PARAMETERS/run_off_coefficient.dat | cut -f 2 -d ' '`

#TREES URBAN ATLAS(31000)
FILE_UA="../data/UA_IT003L3_NAPOLI/Shapefiles/IT003L3_NAPOLI_UA2012.shp"
SHP_UA=`ogrinfo $FILE_UA | grep '1:' | cut -f 2 -d ' '`
NAME=$SHP_UA"_"$LAYER
ogr2ogr -sql "SELECT area,perimeter FROM "$SHP_UA" WHERE CODE2012='31000'" $NAME $FILE_UA
shp2pgsql -k -s 3035 -S -I -d $NAME/$SHP_UA.shp $NAME > $NAME".sql"
rm -r $NAME
psql -d clarity -U postgres -f $NAME".sql"
rm $NAME".sql"

#trees STL
FILE_STL="../data/STL_IT003L2_NAPOLI/Shapefiles/IT003L2_NAPOLI_UA2012_STL.shp"
SHP_STL=`ogrinfo $FILE_STL | grep '1:' | cut -f 2 -d ' '`
##NAME2=$SHP_STL"_trees"
NAME2=$SHP_UA"_"$LAYER
ogr2ogr -sql "SELECT shape_area as area, shape_leng as perimeter FROM "$SHP_STL" WHERE STL=1" $NAME2 $FILE_STL
shp2pgsql -k -s 3035 -S -I -a $NAME2/$SHP_STL.shp $NAME2 > $NAME2".sql"
#shp2pgsql -s 3035 -I -d $NAME2/$SHP_STL.shp $NAME2 > $NAME2".sql"
rm -r $NAME2
psql -d clarity -U postgres -f $NAME2".sql"
rm $NAME2".sql"

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
echo "...Adding hillshade building..."
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD hillshade_green_fraction real DEFAULT 0.37;"

#Clusterization
echo "...Clusterizing..."
#psql -U "postgres" -d "clarity" -c "CLUSTER public.\""$NAME"\" USING public.\""$NAME"\"_pkey;"

#FALTA VOLCAR SOBRE TABLA ROADS GLOBAL Y BORRAR LA TABLA trees DEL SHAPEFILE ACTUAL(ITALIA-NAPOLES)
#psql -U "postgres" -d "clarity" -c "INSERT INTO trees(SELECT NEXTVAL('trees_gid_seq'), area, perimeter, code2012, geom, albedo, emissivity, transmissivity, vegetation_shadow, run_off_coedfficient, building_shadow, hillshade_green_fraction FROM "$NAME");"
#psql -U "postgres" -d "clarity" -c "DROP TABLE "$NAME";"
