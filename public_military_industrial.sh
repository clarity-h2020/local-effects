#!/bin/bash

LAYER="public_military_industrial"
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
RUNOFF_COEFFICIENT=`grep -i -F [$LAYER] $PARAMETERS/run_off_coefficient.dat | cut -f 2 -d ' '`
CONTEXT=`grep -i -F [$LAYER] $PARAMETERS/context.dat | cut -f 2 -d ' '`
FUA_TUNNEL=`grep -i -F [$LAYER] $PARAMETERS/fua_tunnel.dat | cut -f 2 -d ' '`

#LOW URBAN FABRIC (12100 Industrial, commercial, public, military and private units)
ogr2ogr -sql "SELECT area,perimeter,CODE2012 FROM "$SHP" WHERE CODE2012='12100'" $NAME $FILE
shp2pgsql -k -s 3035 -S -I -d $NAME/$SHP.shp $NAME > $NAME".sql"
rm -r $NAME
psql -d clarity -U postgres -f $NAME".sql"
rm $NAME".sql"
#adding rest of the parameters
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD albedo real DEFAULT "$ALBEDO";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD emissivity real DEFAULT "$EMISSIVITY";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD transmissivity real DEFAULT "$TRANSMISSIVITY";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD run_off_coefficient real DEFAULT "$RUNOFF_COEFFICIENT";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD context real DEFAULT "$CONTEXT";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD fua_tunnel real DEFAULT "$FUA_TUNNEL";"

#Clusterization
#psql -U "postgres" -d "clarity" -c "CLUSTER public.\""$NAME"\" USING public.\""$NAME"\"_pkey;"

#FALTA VOLCAR SOBRE TABLA ROADS GLOBAL Y BORRAR LA TABLA ROADS DEL SHAPEFILE ACTUAL(ITALIA-NAPOLES)
#psql -U "postgres" -d "clarity" -c "INSERT INTO public_military_industrial(SELECT NEXTVAL('public_military_industrial_gid_seq'), area, perimeter, code2012, geom, albedo, emissivity, transmissivity, run_off_coedfficient, context, fua_tunnel FROM "$NAME");"
#psql -U "postgres" -d "clarity" -c "DROP TABLE "$NAME";"

fi
