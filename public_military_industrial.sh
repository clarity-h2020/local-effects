#!/bin/bash
CODE="CODE2006"
#CODE="CODE2012"

LAYER="public_military_industrial"
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
RUNOFF_COEFFICIENT=`grep -i -F [$LAYER] $PARAMETERS/run_off_coefficient.dat | cut -f 2 -d ' '`

#LOW URBAN FABRIC (12100 Industrial, commercial, public, military and private units)
#ogr2ogr -sql "SELECT area,perimeter FROM "$SHP" WHERE "$CODE"='12100'" $NAME $FILE
ogr2ogr -overwrite -sql "SELECT Shape_Area as area, Shape_Leng as perimeter FROM "$SHP" WHERE "$CODE"='12100'" $NAME $FILE
shp2pgsql -k -s 3035 -I -d $NAME/$SHP.shp $NAME > $NAME".sql"
rm -r $NAME
psql -d clarity -U postgres -f $NAME".sql"
rm $NAME".sql"

#remove intersections with previous layers
echo "...removing water intersections..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" x SET geom=ST_Multi(ST_CollectionExtract(ST_MakeValid( ST_Difference(x.geom, w.geom)),3)) FROM "$CITY"_water w WHERE ST_Contains(x.geom, w.geom) OR ST_Overlaps(x.geom, w.geom);"
echo "...removing roads intersections..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" x SET geom=ST_Multi(ST_CollectionExtract(ST_MakeValid( ST_Difference(x.geom, r.geom)),3)) FROM "$CITY"_roads r WHERE ST_Contains(x.geom, r.geom) OR ST_Overlaps(x.geom, r.geom);"
echo "...removing railways intersections..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" x SET geom=ST_Multi(ST_CollectionExtract(ST_MakeValid( ST_Difference(x.geom, r.geom)),3)) FROM "$CITY"_railways r WHERE ST_Contains(x.geom, r.geom) OR ST_Overlaps(x.geom, r.geom);"
echo "...removing trees intersections..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" x SET geom=ST_Multi(ST_CollectionExtract(ST_MakeValid( ST_Difference(x.geom, t.geom)),3)) FROM "$CITY"_trees t WHERE ST_Contains(x.geom, t.geom) OR ST_Overlaps(x.geom, t.geom);"
echo "...removing vegetation intersections..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" x SET geom=ST_Multi(ST_CollectionExtract(ST_MakeValid( ST_Difference(x.geom, v.geom)),3)) FROM "$CITY"_vegetation v WHERE ST_Contains(x.geom, v.geom) OR ST_Overlaps(x.geom, v.geom);"
echo "...removing agricultural areas intersections..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" x SET geom=ST_Multi(ST_CollectionExtract(ST_MakeValid( ST_Difference(x.geom, a.geom)),3)) FROM "$CITY"_agricultural_areas a WHERE ST_Contains(x.geom, a.geom) OR ST_Overlaps(x.geom, a.geom);"
echo "...removing built up intersections..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" x SET geom=ST_Multi(ST_CollectionExtract(ST_MakeValid( ST_Difference(x.geom, b.geom)),3)) FROM "$CITY"_built_up b WHERE ST_Contains(x.geom, b.geom) OR ST_Overlaps(x.geom, b.geom);"
echo "...removing built open spaces intersections..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" x SET geom=ST_Multi(ST_CollectionExtract(ST_MakeValid( ST_Difference(x.geom, b.geom)),3)) FROM "$CITY"_built_open_spaces b WHERE ST_Contains(x.geom, b.geom) OR ST_Overlaps(x.geom, b.geom);"

#adding rest of the parameters
echo "...Adding rest of parameters..."
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD albedo real DEFAULT "$ALBEDO";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD emissivity real DEFAULT "$EMISSIVITY";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD transmissivity real DEFAULT "$TRANSMISSIVITY";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD run_off_coefficient real DEFAULT "$RUNOFF_COEFFICIENT";"

#Clusterization
echo "...Clusterizing..."
#psql -U "postgres" -d "clarity" -c "CLUSTER public.\""$NAME"\" USING public.\""$NAME"\"_pkey;"

#TAKE EVERYTHING FROM CITY TABLE TO GENERAL TABLE
#psql -U "postgres" -d "clarity" -c "INSERT INTO public_military_industrial (SELECT * FROM "$NAME");"
fi
