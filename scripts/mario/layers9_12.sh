#!/bin/bash

CITY=$(echo "$1" | awk '{print toupper($0)}')
FOLDER="data/"$CITY"/ua"
#FILE=`ls -la $FOLDER/*.shp | cut -f 10 -d ' '`
FILE=`ls $FOLDER/*.shp`
if [ ! "$FILE" ]; then
    echo "ERROR: City data not found!"
else
	NAME=`ogrinfo $FILE | grep '1:' | cut -f 2 -d ' '`

	#UA2012
	ogr2ogr -sql "SELECT CODE2012 FROM "$NAME" WHERE CODE2012='11230' OR CODE2012='11240' OR CODE2012='11300' OR CODE2012='12100' OR CODE2012='11220' OR CODE2012='11100' OR CODE2012='11210'" $NAME"_layers9_12" $FILE
	#UA2006
	#ogr2ogr -sql "SELECT Shape_Area as area, Shape_Leng as perimeter, CODE2006 FROM "$NAME" WHERE CODE2006='11230' OR CODE2006='11240' OR CODE2006='11300' OR CODE2006='12100' OR CODE2006='11220' OR CODE2006='11100' OR CODE2006='11210'" $NAME"_layers9_12" $FILE

	shp2pgsql -s 3035 -I -d "$NAME"_layers9_12/"$NAME".shp "$CITY"_layers9_12 > "$CITY"_layers9_12.sql
	rm -r $NAME"_layers9_12"
	psql -d clarity -U postgres -f "$CITY"_layers9_12.sql
	rm $CITY"_layers9_12.sql"
fi
