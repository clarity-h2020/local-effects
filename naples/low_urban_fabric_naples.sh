#!/bin/bash

LAYER="low_urban_fabric"
FILE="../data/UA_IT003L3_NAPOLI/Shapefiles/IT003L3_NAPOLI_UA2012.shp"
SHP=`ogrinfo $FILE | grep '1:' | cut -f 2 -d ' '`
NAME=$SHP"_"$LAYER

#PARAMETERS
PARAMETERS="../parameters"
ALBEDO=`grep -i -F [$LAYER] $PARAMETERS/albedo.dat | cut -f 2 -d ' '`
EMISSIVITY=`grep -i -F [$LAYER] $PARAMETERS/emissivity.dat | cut -f 2 -d ' '`
TRANSMISSIVITY=`grep -i -F [$LAYER] $PARAMETERS/transmissivity.dat | cut -f 2 -d ' '`
RUNOFF_COEFFICIENT=`grep -i -F [$LAYER] $PARAMETERS/run_off_coefficient.dat | cut -f 2 -d ' '`
CONTEXT=`grep -i -F [$LAYER] $PARAMETERS/context.dat | cut -f 2 -d ' '`
FUA_TUNNEL=`grep -i -F [$LAYER] $PARAMETERS/fua_tunnel.dat | cut -f 2 -d ' '`

#LOW URBAN FABRIC (11230 discontinuous low density urban fabric, 11240 discontinuous very low density urban fabric, 11300 isolated structures)
ogr2ogr -sql "SELECT area,perimeter FROM "$SHP" WHERE CODE2012='11230' OR CODE2012='11240' OR CODE2012='11300'" $NAME $FILE
shp2pgsql -k -s 3035 -S -I -d $NAME/$SHP.shp $NAME > $NAME".sql"
rm -r $NAME
psql -d clarity -U postgres -f $NAME".sql"
rm $NAME".sql"

#adding rest of the parameters
echo "...Adding rest of parameters..."
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD albedo real DEFAULT "$ALBEDO";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD emissivity real DEFAULT "$EMISSIVITY";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD transmissivity real DEFAULT "$TRANSMISSIVITY";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD run_off_coefficient real DEFAULT "$RUNOFF_COEFFICIENT";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD context real DEFAULT "$CONTEXT";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD fua_tunnel real DEFAULT "$FUA_TUNNEL";"

#Clusterization
echo "...Clusterizing..."
#psql -U "postgres" -d "clarity" -c "CLUSTER public.\""$NAME"\" USING public.\""$NAME"\"_pkey;"

#FALTA VOLCAR SOBRE TABLA ROADS GLOBAL Y BORRAR LA TABLA ROADS DEL SHAPEFILE ACTUAL(ITALIA-NAPOLES)
#psql -U "postgres" -d "clarity" -c "INSERT INTO low_urban_fabric(SELECT NEXTVAL('low_urban_fabric_gid_seq'), area, perimeter, code2012, geom, albedo, emissivity, transmissivity, run_off_coedfficient, context, fua_tunnel FROM "$NAME");"
#psql -U "postgres" -d "clarity" -c "DROP TABLE "$NAME";"
