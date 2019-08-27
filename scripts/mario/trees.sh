#!/bin/bash
#CODE="CODE2006"
#VALUE="30000"
CODE="CODE2012"
VALUE="31000"

LAYER="trees"
if [[ $# -eq 0 ]] ; then
    echo -e "\e[33mERROR: No city name provided!\e[0m"
    exit 1
fi
CITY=$(echo "$1" | awk '{print toupper($0)}')
FOLDER_UA="data/"$CITY"/ua"
FILE_UA=`ls -la $FOLDER_UA/*.shp | cut -f 2 -d ':' | cut -f 2 -d ' '`
SHP_UA=`ogrinfo $FILE_UA | grep '1:' | cut -f 2 -d ' '`
NAME=$(echo $CITY"_"$LAYER | awk '{print tolower($0)}')

FOLDER_STL="data/"$CITY"/stl"
FILE_STL=`ls -la $FOLDER_STL/*.shp | rev | cut -f 1 -d ' ' | rev`
SHP_STL=`ogrinfo $FILE_STL | grep '1:' | cut -f 2 -d ' '`

if [ ! "$FILE_UA" ] || [ ! "$FILE_STL" ]; then
    echo "ERROR: City data not found!"
else

#TREES URBAN ATLAS
#WATCH OUT CODE IS (31000 in UA2012 but it is 30000 in UA 2006)
echo "...Extract Urban Atlas data..."
ogr2ogr -overwrite -sql "SELECT Shape_Area as area FROM "$SHP_UA" WHERE "$CODE"='"$VALUE"'" $NAME"_UA" $FILE_UA
shp2pgsql -k -s 3035 -I -d $NAME"_UA"/$SHP_UA.shp $NAME > $NAME"_UA.sql"
rm -r $NAME"_UA"
psql -d clarity -U postgres -f $NAME"_UA.sql"
rm $NAME"_UA.sql"

#trees STL
echo "...Extract STL data..."
ogr2ogr -sql "SELECT Shape_Area as area FROM "$SHP_STL" WHERE STL=1" $NAME"_STL" $FILE_STL
shp2pgsql -k -s 3035 -I -a $NAME"_STL"/$SHP_STL.shp $NAME > $NAME"_STL.sql"
rm -r $NAME"_STL"
psql -d clarity -U postgres -f $NAME"_STL.sql"
rm $NAME"_STL.sql"

#FIT GEOMETRIES TO CITY BOUNDARY
echo "...deleting geometries out of boundary..."
psql -U "postgres" -d "clarity" -c "DELETE FROM "$NAME" WHERE gid NOT IN (SELECT g.gid FROM "$NAME" g, city c WHERE c.NAME='"$CITY"' AND ST_Intersects(g.geom, c.boundary) );"

#GEOMETRY INTEGRITY CHECK
echo "...doing geometry integrity checks..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" SET geom=St_MakeValid(geom);"
psql -U "postgres" -d "clarity" -c "SELECT * FROM "$NAME" WHERE NOT ST_Isvalid(geom);" > check.out
COUNT=`sed -n '3p' < check.out | cut -f 1 -d ' ' | cut -f 2 -d '('`
if [ $COUNT -gt 0 ];
then
        echo $COUNT "Problems found"
        echo "...deleting affected geometries to avoid further problems with them..."
        psql -U "postgres" -d "clarity" -c "DELETE FROM "$NAME" WHERE NOT ST_Isvalid(geom);"
fi
rm check.out

#ADD RELATION COLUMNS
echo "...adding relational columns..."
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD city integer;"
psql -U "postgres" -d "clarity" -c "SELECT id from city where name='"$CITY"';" > id.out
ID=`sed "3q;d" id.out | sed -e 's/^[ \t]*//'`
rm id.out
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" SET city="$ID";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD CONSTRAINT "$NAME"_city_fkey FOREIGN KEY (city) REFERENCES city (id);"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD cell integer;"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD CONSTRAINT "$NAME"_cell_fkey FOREIGN KEY (cell) REFERENCES laea_etrs_500m (gid);"

#MAKING GOEMETRIES GRID LIKE
echo "...generating grided geometries..."
psql -U "postgres" -d "clarity" -c "DROP TABLE IF EXISTS "$NAME"_grid;"
psql -U "postgres" -d "clarity" -c "DROP SEQUENCE IF EXISTS "$NAME"_grid_seq;"

psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" DROP COLUMN area;"
psql -U "postgres" -d "clarity" -c "CREATE TABLE "$NAME"_grid (LIKE "$NAME" INCLUDING ALL);"
psql -U "postgres" -d "clarity" -c "CREATE SEQUENCE "$NAME"_grid_seq START WITH 1;"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME"_grid ALTER COLUMN gid SET DEFAULT nextval('"$NAME"_grid_seq');"
psql -U "postgres" -d "clarity" -c "INSERT INTO "$NAME"_grid (geom,city,cell) (SELECT ST_Multi(ST_CollectionExtract(ST_Intersection(ST_MakeValid(ST_SnapToGrid(ST_Union(a.geom),0.0001)), m.geom),3)) as geom,"$ID" as city,m.gid as cell FROM "$NAME" a, laea_etrs_500m m, city c WHERE c.name='"$CITY"' AND ST_Intersects(c.boundary,m.geom) AND ST_Intersects(a.geom, m.geom) GROUP BY m.geom,m.gid);"
psql -U "postgres" -d "clarity" -c "DROP TABLE "$NAME";"
NAME=$(echo $CITY"_"$LAYER"_GRID" | awk '{print tolower($0)}')

#REMOVAL OF AREAS OUT CITY BOUNDARY
#drop old table (from previous runs...)
psql -U "postgres" -d "clarity" -c "DROP TABLE IF EXISTS "$CITY"_"$LAYER";"
psql -U "postgres" -d "clarity" -c "DROP SEQUENCE IF EXISTS "$CITY"_"$LAYER"_seq;"
#create new aux table
psql -U "postgres" -d "clarity" -c "CREATE TABLE "$CITY"_"$LAYER" (LIKE "$NAME" INCLUDING ALL);"
psql -U "postgres" -d "clarity" -c "CREATE SEQUENCE "$CITY"_"$LAYER"_seq START WITH 1;"
#insert geometries within boundary
echo "...get grid tiles within boundary..."
psql -U "postgres" -d "clarity" -c "INSERT INTO "$CITY"_"$LAYER" (geom,city,cell) (SELECT geom,v.city,v.cell FROM "$NAME" v, city c WHERE c.NAME='"$CITY"' AND ST_Within(v.geom, c.boundary));"
#insert intersection of outer geometries with city boundary
echo "...get grid tile intersections with boundary..."
psql -U "postgres" -d "clarity" -c "INSERT INTO "$CITY"_"$LAYER" (geom,city,cell) (SELECT ST_Multi(ST_Union(ST_CollectionExtract(ST_Intersection(v.geom,c.boundary),3))) as geom,v.city,v.cell FROM city c, "$NAME" v WHERE ST_Overlaps(v.geom,c.boundary) GROUP BY v.gid);"
#delete old table
psql -U "postgres" -d "clarity" -c "DROP TABLE "$NAME" CASCADE;"
#psql -U "postgres" -d "clarity" -c "DROP SEQUENCE "$NAME"_seq;"
NAME=$(echo $CITY"_"$LAYER | awk '{print tolower($0)}')

#remove intersections with previous layers
echo "...removing water intersections..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" SET geom=sq.geom FROM (SELECT t.gid as id, ST_Multi(ST_CollectionExtract(ST_Difference(ST_MakeValid(ST_SnapToGrid(t.geom,0.0001)),ST_MakeValid(ST_SnapToGrid(r.geom,0.0001))),3) ) as geom FROM "$NAME" t, "$CITY"_water_grid r WHERE r.cell=t.cell) as sq WHERE gid=sq.id;"
echo "...removing roads intersections..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" SET geom=sq.geom FROM (SELECT t.gid as id, ST_Multi(ST_CollectionExtract(ST_Difference(ST_MakeValid(ST_SnapToGrid(t.geom,0.0001)),ST_MakeValid(ST_SnapToGrid(r.geom,0.0001))),3) ) as geom FROM "$NAME" t, "$CITY"_roads_grid r WHERE r.cell=t.cell) as sq WHERE gid=sq.id;"
echo "...removing railways intersections..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" SET geom=sq.geom FROM (SELECT t.gid as id, ST_Multi(ST_CollectionExtract(ST_Difference(ST_MakeValid(ST_SnapToGrid(t.geom,0.0001)),ST_MakeValid(ST_SnapToGrid(r.geom,0.0001))),3) ) as geom FROM "$NAME" t, "$CITY"_railways_grid r WHERE r.cell=t.cell) as sq WHERE gid=sq.id;"

#FIX
echo "...fixing geometries by buffering..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" SET geom=St_MakeValid(geom);"

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

#TAKE EVERYTHING FROM CITY TABLE TO GENERAL TABLE
psql -U "postgres" -d "clarity" -c "INSERT INTO "$LAYER" (geom,city,cell,albedo,emissivity,transmissivity,vegetation_shadow,run_off_coefficient,fua_tunnel,building_shadow,hillshade_green_fraction) (SELECT geom,city,cell,albedo,emissivity,transmissivity,vegetation_shadow,run_off_coefficient,fua_tunnel,building_shadow,hillshade_green_fraction FROM "$NAME");"
fi
