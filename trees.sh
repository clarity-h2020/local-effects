#!/bin/bash
CODE="CODE2006"
VALUE="30000"
#CODE="CODE2012"
#VALUE="31000"

LAYER="trees"
if [[ $# -eq 0 ]] ; then
    echo -e "\e[33mERROR: No city name provided!\e[0m"
    exit 1
fi
CITY=$(echo "$1" | awk '{print toupper($0)}')
FOLDER_UA="data/"$CITY"/ua"
FILE_UA=`ls -la $FOLDER_UA/*.shp | cut -f 10 -d ' '`
SHP_UA=`ogrinfo $FILE_UA | grep '1:' | cut -f 2 -d ' '`
#NAME=$(echo $SHP_UA"_"$LAYER | awk '{print tolower($0)}')
NAME=$(echo $CITY"_"$LAYER | awk '{print tolower($0)}')

FOLDER_STL="data/"$CITY"/stl"
FILE_STL=`ls -la $FOLDER_STL/*.shp | cut -f 10 -d ' '`
SHP_STL=`ogrinfo $FILE_STL | grep '1:' | cut -f 2 -d ' '`

if [ ! "$FILE_UA" ] || [ ! "$FILE_STL" ]; then
    echo "ERROR: City data not found!"
else

#TREES URBAN ATLAS
#WATCH OUT CODE IS (31000 in UA2012 but it is 30000 in UA 2006)
echo "...Extract Urban Atlas data..."
ogr2ogr -overwrite -sql "SELECT Shape_Area as area, Shape_Leng as perimeter FROM "$SHP_UA" WHERE "$CODE"='30000'" $NAME"_UA" $FILE_UA
shp2pgsql -k -s 3035 -I -d $NAME"_UA"/$SHP_UA.shp $NAME > $NAME"_UA.sql"
rm -r $NAME"_UA"
psql -d clarity -U postgres -f $NAME"_UA.sql"
rm $NAME"_UA.sql"

#trees STL
echo "...Extract STL data..."
ogr2ogr -sql "SELECT Shape_Area as area, Shape_Leng as perimeter FROM "$SHP_STL" WHERE STL=1" $NAME"_STL" $FILE_STL
shp2pgsql -k -s 3035 -I -a $NAME"_STL"/$SHP_STL.shp $NAME > $NAME"_STL.sql"
rm -r $NAME"_STL"
psql -d clarity -U postgres -f $NAME"_STL.sql"
rm $NAME"_STL.sql"

#PARAMETERS
PARAMETERS="parameters"
ALBEDO=`grep -i -F [$LAYER] $PARAMETERS/albedo.dat | cut -f 2 -d ' '`
EMISSIVITY=`grep -i -F [$LAYER] $PARAMETERS/emissivity.dat | cut -f 2 -d ' '`
TRANSMISSIVITY=`grep -i -F [$LAYER] $PARAMETERS/transmissivity.dat | cut -f 2 -d ' '`
VEGETATION_SHADOW=`grep -i -F [$LAYER] $PARAMETERS/vegetation_shadow.dat | cut -f 2 -d ' '`
RUNOFF_COEFFICIENT=`grep -i -F [$LAYER] $PARAMETERS/run_off_coefficient.dat | cut -f 2 -d ' '`

#remove intersections with previous layers
echo "...removing water intersections..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" x SET geom=ST_Multi(ST_CollectionExtract(ST_MakeValid( ST_Difference(x.geom, w.geom)),3)) FROM "$CITY"_water w WHERE ST_Contains(x.geom, w.geom) OR ST_Overlaps(x.geom, w.geom);"
echo "...removing roads intersections..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" x SET geom=ST_Multi(ST_CollectionExtract(ST_MakeValid( ST_Difference(x.geom, r.geom)),3)) FROM "$CITY"_roads r WHERE ST_Contains(x.geom, r.geom) OR ST_Overlaps(x.geom, r.geom);"
echo "...removing railways intersections..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" x SET geom=ST_Multi(ST_CollectionExtract(ST_MakeValid( ST_Difference(x.geom, r.geom)),3)) FROM "$CITY"_railways r WHERE ST_Contains(x.geom, r.geom) OR ST_Overlaps(x.geom, r.geom);"

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

#building shadow 1 by default(not intersecting) then update with value 0 when intersecting
echo "...Adding building shadow..."
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD building_shadow smallint DEFAULT 1;"
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET building_shadow=0 FROM "$CITY"_layers9_12 l WHERE ST_Intersects( x.geom , l.geom );"

###HILLSHADE GREEN FRACTION, we do not know where to get tree type... so we set default value 0.37
echo "...Adding hillshade green fraction..."
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD hillshade_green_fraction real DEFAULT 0.37;"

#Clusterization
echo "...Clusterizing..."
#psql -U "postgres" -d "clarity" -c "CLUSTER public.\""$NAME"\" USING public.\""$NAME"\"_pkey;"

#TAKE EVERYTHING FROM CITY TABLE TO GENERAL TABLE
#psql -U "postgres" -d "clarity" -c "INSERT INTO trees (SELECT * FROM "$NAME");"
fi
