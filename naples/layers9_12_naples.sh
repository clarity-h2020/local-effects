#!/bin/bash

FILE="data/UA_IT003L2_NAPOLI/Shapefiles/IT003L2_NAPOLI_UA2006_Revised.shp"
NAME=`ogrinfo $FILE | grep '1:' | cut -f 2 -d ' '`
echo "NOMBRE:"$NAME
ogr2ogr -sql "SELECT area, perimeter, CODE2012 FROM "$NAME" WHERE CODE2012='11230' OR CODE2012='11240' OR CODE2012='11300' OR CODE2012='12100' OR CODE2012='11220' OR CODE2012='11100' OR CODE2012='11210'" $NAME"_layers9_12" $FILE
shp2pgsql -s 3035 -I -d "$NAME"_layers9_12/"$NAME".shp "$NAME"_layers9_12 > "$NAME"_layers9_12.sql
psql -d clarity -U postgres -f "$NAME"_layers9_12.sql
#rm $NAME"_layers9_12.sql"
