#!/bin/bash
CODE="CODE2006"
#CODE="CODE2012"

LAYER="low_urban_fabric"
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
NAME=$(echo $SHP"_"$LAYER | awk '{print tolower($0)}')

#PARAMETERS
PARAMETERS="parameters"
ALBEDO=`grep -i -F [$LAYER] $PARAMETERS/albedo.dat | cut -f 2 -d ' '`
EMISSIVITY=`grep -i -F [$LAYER] $PARAMETERS/emissivity.dat | cut -f 2 -d ' '`
TRANSMISSIVITY=`grep -i -F [$LAYER] $PARAMETERS/transmissivity.dat | cut -f 2 -d ' '`
RUNOFF_COEFFICIENT=`grep -i -F [$LAYER] $PARAMETERS/run_off_coefficient.dat | cut -f 2 -d ' '`

#LOW URBAN FABRIC (11230 discontinuous low density urban fabric, 11240 discontinuous very low density urban fabric, 11300 isolated structures)
#ogr2ogr -sql "SELECT area,perimeter FROM "$SHP" WHERE "$CODE"='11230' OR "$CODE"='11240' OR "$CODE"='11300'" $NAME $FILE
ogr2ogr -overwrite -sql "SELECT Shape_Area as area, Shape_Leng as perimeter FROM "$SHP" WHERE "$CODE"='11230' OR "$CODE"='11240' OR "$CODE"='11300'" $NAME $FIL
shp2pgsql -k -s 3035 -S -I -d $NAME/$SHP.shp $NAME > $NAME".sql"
rm -r $NAME
psql -d clarity -U postgres -f $NAME".sql"
rm $NAME".sql"

#remove intersections with previous layers
echo "...removing water intersections..."
psql -U "postgres" -d "clarity" -c "DELETE FROM "$NAME" x USING "$CITY"_water w WHERE ST_Contains(x.geom, w.geom) OR ST_Overlaps(x.geom, w.geom);"
echo "...removing roads intersections..."
psql -U "postgres" -d "clarity" -c "DELETE FROM "$NAME" x USING "$CITY"_roads r WHERE ST_Contains(x.geom, r.geom) OR ST_Overlaps(x.geom, r.geom);"
echo "...removing railways intersections..."
psql -U "postgres" -d "clarity" -c "DELETE FROM "$NAME" x USING "$CITY"_roads r WHERE ST_Contains(x.geom, r.geom) OR ST_Overlaps(x.geom, r.geom);"
echo "...removing trees intersections..."
psql -U "postgres" -d "clarity" -c "DELETE FROM "$NAME" x USING "$CITY"_trees t WHERE ST_Contains(x.geom, t.geom) OR ST_Overlaps(x.geom, t.geom);"
echo "...removing vegetation intersections..."
psql -U "postgres" -d "clarity" -c "DELETE FROM "$NAME" x USING "$CITY"_vegetation v WHERE ST_Contains(x.geom, v.geom) OR ST_Overlaps(x.geom, v.geom);"
echo "...removing agricultural areas intersections..."
psql -U "postgres" -d "clarity" -c "DELETE FROM "$NAME" x USING "$CITY"_agricultural_areas a WHERE ST_Contains(x.geom, a.geom) OR ST_Overlaps(x.geom, a.geom);"
echo "...removing built up intersections..."
psql -U "postgres" -d "clarity" -c "DELETE FROM "$NAME" x USING "$CITY"_built_up b WHERE ST_Contains(x.geom, b.geom) OR ST_Overlaps(x.geom, b.geom);"
echo "...removing built open spaces intersections..."
psql -U "postgres" -d "clarity" -c "DELETE FROM "$NAME" x USING "$CITY"_built_open_spaces b WHERE ST_Contains(x.geom, b.geom) OR ST_Overlaps(x.geom, b.geom);"

#adding rest of the parameters
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD albedo real DEFAULT "$ALBEDO";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD emissivity real DEFAULT "$EMISSIVITY";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD transmissivity real DEFAULT "$TRANSMISSIVITY";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD run_off_coefficient real DEFAULT "$RUNOFF_COEFFICIENT";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD fua_tunnel real DEFAULT "$FUA_TUNNEL";"

#Clusterization
#psql -U "postgres" -d "clarity" -c "CLUSTER public.\""$NAME"\" USING public.\""$NAME"\"_pkey;"

#TAKE EVERYTHING FROM CITY TABLE TO GENERAL TABLE
#psql -U "postgres" -d "clarity" -c "INSERT INTO low_urban_fabric (SELECT * FROM "$NAME");"
fi
