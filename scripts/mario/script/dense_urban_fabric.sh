#!/bin/bash
#CODE="CODE2006"
CODE="CODE2012"

START_TOTAL=$(date +%s)

LAYER="dense_urban_fabric"
if [[ $# -eq 0 ]] ; then
    echo -e "\e[33mERROR: No city name provided!\e[0m"
    exit 1
fi
CITY=$(echo "$1" | awk '{print toupper($0)}')
FOLDER="data/"$CITY"/ua"
FILE=`ls -la $FOLDER/*.shp | cut -f 2 -d ':' | cut -f 2 -d ' '`
if [ ! "$FILE" ]; then
    echo -e "\e[33mERROR: City data not found!\e[0m"
else
SHP=`ogrinfo $FILE | grep '1:' | cut -f 2 -d ' '`
NAME=$(echo $CITY"_"$LAYER | awk '{print tolower($0)}')

#DENSE URBAN FABRIC (11100 continuous urban fabric, 11210 discontinuous dense urban fabric)
ogr2ogr -overwrite -sql "SELECT Shape_Area as area FROM "$SHP" WHERE "$CODE"='11100' OR "$CODE"='11210'" $NAME $FILE
shp2pgsql -k -s 3035 -I -d $NAME/$SHP.shp $NAME > $NAME".sql"
rm -r $NAME
psql -d clarity -U postgres -f $NAME".sql"
rm $NAME".sql"

#GEOMETRY INTEGRITY CHECK
echo -e "\e[36m...doing geometry integrity checks...\e[0m"
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" SET geom=St_MakeValid(geom);"
##St_Multi(St_Buffer(geom,0.0001)));"
psql -U "postgres" -d "clarity" -c "SELECT * FROM "$NAME" WHERE NOT ST_Isvalid(geom);" > check.out
COUNT=`sed -n '3p' < check.out | cut -f 1 -d ' ' | cut -f 2 -d '('`
if [ $COUNT -gt 0 ];
then
        echo -e "\e[33m"$COUNT "Problems found\e[0m"
        echo -e "\e[36m...deleting affected geometries to avoid further problems with them...\e[0m"
        psql -U "postgres" -d "clarity" -c "DELETE FROM "$NAME" WHERE NOT ST_Isvalid(geom);"
fi
rm check.out

#ADD RELATION COLUMNS
echo -e "\e[36m...adding relational columns...\e[0m"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD city integer;"
psql -U "postgres" -d "clarity" -c "SELECT id from city where name='"$CITY"';" > id.out
ID=`sed "3q;d" id.out | sed -e 's/^[ \t]*//'`
rm id.out
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" SET city="$ID";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD CONSTRAINT "$NAME"_city_fkey FOREIGN KEY (city) REFERENCES city (id);"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD cell integer;"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD CONSTRAINT "$NAME"_cell_fkey FOREIGN KEY (cell) REFERENCES laea_etrs_500m (gid);"

#FIT GEOMETRIES TO CITY BOUNDARY
echo -e "\e[36m...deleting geometries out of boundary...\e[0m"
psql -U "postgres" -d "clarity" -c "DELETE FROM "$NAME" WHERE gid NOT IN (SELECT g.gid FROM "$NAME" g, city c WHERE c.NAME='"$CITY"' AND ST_Intersects(g.geom, c.boundary) );"
echo -e "\e[36m...deleting partial geometries out of boundary...\e[0m"
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" SET geom=sq.geom FROM (SELECT v.gid,ST_Multi(ST_Union(ST_CollectionExtract(ST_Intersection(v.geom,c.boundary),3))) as geom FROM city c, "$NAME" v WHERE c.NAME='"$CITY"' AND ST_Overlaps(v.geom,c.boundary) GROUP BY v.gid) as sq WHERE "$NAME".gid=sq.gid;"

#MAKING GOEMETRIES GRID LIKE
echo -e "\e[36m...generating grided geometries...\e[0m"
psql -U "postgres" -d "clarity" -c "CREATE TABLE "$NAME"_grid (LIKE "$NAME" INCLUDING ALL);"
psql -U "postgres" -d "clarity" -c "DROP SEQUENCE "$NAME"_grid_seq;"
psql -U "postgres" -d "clarity" -c "CREATE SEQUENCE "$NAME"_grid_seq START WITH 1;"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME"_grid ALTER COLUMN gid SET DEFAULT nextval('"$NAME"_grid_seq');"
psql -U "postgres" -d "clarity" -c "INSERT INTO "$NAME"_grid (geom,city,cell) (SELECT ST_Multi(ST_CollectionExtract(ST_Intersection(ST_MakeValid(ST_SnapToGrid(ST_Union(a.geom),0.0001)), m.geom),3)) as geom, "$ID" as city,m.gid as cell FROM "$NAME" a, laea_etrs_500m m, land_use_grid l WHERE l.city="$ID" AND l.cell=m.gid AND ST_Intersects(a.geom, m.geom) GROUP BY m.geom,m.gid);"
psql -U "postgres" -d "clarity" -c "DROP TABLE "$NAME" CASCADE;"
NAME=$(echo $CITY"_"$LAYER"_GRID" | awk '{print tolower($0)}')

#remove intersections with previous layers
#echo -e "\e[36m...removing water intersections...\e[0m"
#psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" SET geom=sq.geom FROM (SELECT t.gid as id, ST_Multi(ST_CollectionExtract(ST_Difference(ST_MakeValid(ST_SnapToGrid(t.geom,0.0001)),ST_MakeValid(ST_SnapToGrid(r.geom,0.0001))),3) ) as geom FROM "$NAME" t, "$CITY"_water_grid r WHERE r.cell=t.cell) as sq WHERE gid=sq.id;
#echo -e "\e[36m...removing roads intersections...\e[0m"
#psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" SET geom=sq.geom FROM (SELECT t.gid as id, ST_Multi(ST_CollectionExtract(ST_Difference(ST_MakeValid(ST_SnapToGrid(t.geom,0.0001)),ST_MakeValid(ST_SnapToGrid(r.geom,0.0001))),3) ) as geom FROM "$NAME" t, "$CITY"_roads_grid r WHERE r.cell=t.cell) as sq WHERE gid=sq.id;"
#echo -e "\e[36m...removing railways intersections...\e[0m"
#psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" SET geom=sq.geom FROM (SELECT t.gid as id, ST_Multi(ST_CollectionExtract(ST_Difference(ST_MakeValid(ST_SnapToGrid(t.geom,0.0001)),ST_MakeValid(ST_SnapToGrid(r.geom,0.0001))),3) ) as geom FROM "$NAME" t, "$CITY"_railways_grid r WHERE r.cell=t.cell) as sq WHERE gid=sq.id;"
echo -e "\e[36m...removing trees intersections...\e[0m"
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" SET geom=sq.geom FROM (SELECT t.gid as id, ST_Multi(ST_CollectionExtract(ST_Difference(ST_MakeValid(ST_SnapToGrid(t.geom,0.0001)),ST_MakeValid(ST_SnapToGrid(r.geom,0.0001))),3) ) as geom FROM "$NAME" t, "$CITY"_trees_grid r WHERE r.cell=t.cell) as sq WHERE gid=sq.id;"
echo -e "\e[36m...removing vegetation intersections...\e[0m"
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" SET geom=sq.geom FROM (SELECT t.gid as id, ST_Multi(ST_CollectionExtract(ST_Difference(ST_MakeValid(ST_SnapToGrid(t.geom,0.0001)),ST_MakeValid(ST_SnapToGrid(r.geom,0.0001))),3) ) as geom FROM "$NAME" t, "$CITY"_vegetation_grid r WHERE r.cell=t.cell) as sq WHERE gid=sq.id;"
#echo -e "\e[36m...removing agricultural areas intersections...\e[0m"
#psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" SET geom=sq.geom FROM (SELECT t.gid as id, ST_Multi(ST_CollectionExtract(ST_Difference(ST_MakeValid(ST_SnapToGrid(t.geom,0.0001)),ST_MakeValid(ST_SnapToGrid(r.geom,0.0001))),3) ) as geom FROM "$NAME" t, "$CITY"_agricultural_areas_grid r WHERE r.cell=t.cell) as sq WHERE gid=sq.id;"
echo -e "\e[36m...removing built open spaces intersections...\e[0m"
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" SET geom=sq.geom FROM (SELECT t.gid as id, ST_Multi(ST_CollectionExtract(ST_Difference(ST_MakeValid(ST_SnapToGrid(t.geom,0.0001)),ST_MakeValid(ST_SnapToGrid(r.geom,0.0001))),3) ) as geom FROM "$NAME" t, "$CITY"_built_open_spaces_grid r WHERE r.cell=t.cell) as sq WHERE gid=sq.id;"
##echo -e "\e[36m...removing built_up intersections...\e[0m"
##psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" SET geom=sq.geom FROM (SELECT t.gid as id, ST_Multi(ST_CollectionExtract(ST_Difference(ST_MakeValid(ST_SnapToGrid(t.geom,0.0001)),ST_MakeValid(ST_SnapToGrid(r.geom,0.0001))),3) ) as geom FROM "$NAME" t, "$CITY"_built_up r WHERE r.cell=t.cell) as sq WHERE gid=sq.id;"
#echo -e "\e[36m...removing sports intersections...\e[0m"
#psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" SET geom=sq.geom FROM (SELECT t.gid as id, ST_Multi(ST_CollectionExtract(ST_Difference(ST_MakeValid(ST_SnapToGrid(t.geom,0.0001)),ST_MakeValid(ST_SnapToGrid(r.geom,0.0001))),3) ) as geom FROM "$NAME" t, "$CITY"_sports_grid r WHERE r.cell=t.cell) as sq WHERE gid=sq.id;"

#FIX
echo -e "\e[36m...fixing geometries by buffering...\e[0m"
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" SET geom=St_MakeValid(geom);"

#PARAMETERS
PARAMETERS="parameters"
echo -e "\e[36m...Adding parameters...\e[0m"
ALBEDO=`grep -i -F [$LAYER] $PARAMETERS/albedo.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD albedo real DEFAULT "$ALBEDO";"
EMISSIVITY=`grep -i -F [$LAYER] $PARAMETERS/emissivity.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD emissivity real DEFAULT "$EMISSIVITY";"
TRANSMISSIVITY=`grep -i -F [$LAYER] $PARAMETERS/transmissivity.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD transmissivity real DEFAULT "$TRANSMISSIVITY";"

#hillshade_buildings
HILLSHADE_BUILDING=`grep -i -F ['DEFAULT'] $PARAMETERS/hillshade_buildings.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD hillshade_building real DEFAULT "$HILLSHADE_BUILDING";"

HILLSHADE_GREEN_FRACTION=`grep -i -F [$LAYER] $PARAMETERS/hillshade_green_fraction.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD hillshade_green_fraction real DEFAULT "$HILLSHADE_GREEN_FRACTION";"
BUILDING_SHADOW=`grep -i -F [$LAYER] $PARAMETERS/building_shadow.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD building_shadow real DEFAULT "$BUILDING_SHADOW";"
VEGETATION_SHADOW=`grep -i -F [$LAYER] $PARAMETERS/vegetation_shadow.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD vegetation_shadow real DEFAULT "$VEGETATION_SHADOW";"

RUNOFF_COEFFICIENT=`grep -i -F [$LAYER] $PARAMETERS/run_off_coefficient.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD run_off_coefficient real DEFAULT "$RUNOFF_COEFFICIENT";"

#Adding FUA_TUNNEL, apply 1 as default
FUA_TUNNEL=`grep -i -F ['DEFAULT'] $PARAMETERS/fua_tunnel.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD fua_tunnel real DEFAULT "$FUA_TUNNEL";"

#TAKE EVERYTHING FROM CITY TABLE TO GENERAL TABLE
echo -e "\e[36m...moving data to final table...\e[0m"
psql -U "postgres" -d "clarity" -c "INSERT INTO "$LAYER" (geom,city,cell,albedo,emissivity,transmissivity,hillshade_building,hillshade_green_fraction,building_shadow,vegetation_shadow,run_off_coefficient,fua_tunnel) (SELECT geom,city,cell,albedo,emissivity,transmissivity,hillshade_building,hillshade_green_fraction,building_shadow,vegetation_shadow,run_off_coefficient,fua_tunnel FROM "$NAME");"
fi

END_TOTAL=$(date +%s)
TIME_TOTAL=`echo $((END_TOTAL-START_TOTAL)) | awk '{printf "%d:%02d:%02d", $1/3600, ($1/60)%60, $1%60}'`
echo -e "\e[36m- "$LAYER" ended - total time is "$TIME_TOTAL" -\e[0m"
