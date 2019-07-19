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

#LOW URBAN FABRIC (12100 Industrial, commercial, public, military and private units)
#ogr2ogr -sql "SELECT area,perimeter FROM "$SHP" WHERE "$CODE"='12100'" $NAME $FILE
ogr2ogr -overwrite -sql "SELECT Shape_Area as area FROM "$SHP" WHERE "$CODE"='12100'" $NAME $FILE
shp2pgsql -k -s 3035 -I -d $NAME/$SHP.shp $NAME > $NAME".sql"
rm -r $NAME
psql -d clarity -U postgres -f $NAME".sql"
rm $NAME".sql"

#GEOMETRY INTEGRITY CHECK
echo "...doing geometry integrity checks..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" SET geom=St_MakeValid(geom);"
##St_Multi(St_Buffer(geom,0.0001)));"
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
ID=`sed "3q;d" id.out | cut -f 3 -d ' '`
rm id.out
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" SET city="$ID";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD CONSTRAINT "$NAME"_city_fkey FOREIGN KEY (city) REFERENCES city (id);"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD cell integer;"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD CONSTRAINT "$NAME"_cell_fkey FOREIGN KEY (cell) REFERENCES laea_etrs_500m (gid);"

#MAKING GOEMETRIES GRID LIKE
echo "...generating grided geometries..."
psql -U "postgres" -d "clarity" -c "SELECT to_regclass('public."$NAME"_grid');" > check.out
FOUND=`sed "3q;d" check.out | cut -f 2 -d ' '`
rm check.out
if [ ! -z $FOUND ];
then
        psql -U "postgres" -d "clarity" -c "DROP TABLE "$NAME"_grid;"
        psql -U "postgres" -d "clarity" -c "DROP SEQUENCE "$NAME"_grid_seq;"
fi
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" DROP COLUMN area;"
psql -U "postgres" -d "clarity" -c "CREATE TABLE "$NAME"_grid (LIKE "$NAME" INCLUDING ALL);"
psql -U "postgres" -d "clarity" -c "CREATE SEQUENCE "$NAME"_grid_seq START WITH 1;"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME"_grid ALTER COLUMN gid SET DEFAULT nextval('"$NAME"_grid_seq');"
psql -U "postgres" -d "clarity" -c "INSERT INTO "$NAME"_grid (geom,city,cell) (SELECT ST_Multi(ST_CollectionExtract(ST_Intersection(ST_MakeValid(ST_SnapToGrid(ST_Union(a.geom),0.0001)), m.geom),3)) as geom,"$ID" as city,m.gid as cell FROM "$NAME" a, laea_etrs_500m m, city c WHERE c.name='"$CITY"' AND ST_Intersects(c.bbox,m.geom) AND ST_Intersects(a.geom, m.geom) GROUP BY m.geom,m.gid);"
psql -U "postgres" -d "clarity" -c "DROP TABLE "$NAME";"
NAME=$(echo $CITY"_"$LAYER"_GRID" | awk '{print tolower($0)}')

#remove intersections with previous layers
echo "...removing water intersections..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" set geom=sq.geom from (SELECT ST_Multi(ST_CollectionExtract(ST_Difference(ST_MakeValid(ST_SnapToGrid(ST_Union(t.geom),0.0001)),ST_Multi(ST_Intersection(ST_MakeValid(ST_SnapToGrid(ST_Union(t.geom),0.0001)),ST_MakeValid(ST_SnapToGrid(ST_Union(r.geom),0.0001))))),3) ) as geom, m.gid FROM "$NAME" t, "$CITY"_water_grid r, land_use_grid g, laea_etrs_500m m WHERE g.city=1 AND g.cell=m.gid AND m.gid=t.cell AND r.cell=t.cell GROUP BY m.gid,m.geom) sq where cell=sq.gid;"
echo "...removing roads intersections..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" set geom=sq.geom from (SELECT ST_Multi(ST_CollectionExtract(ST_Difference(ST_MakeValid(ST_SnapToGrid(ST_Union(t.geom),0.0001)),ST_Multi(ST_Intersection(ST_MakeValid(ST_SnapToGrid(ST_Union(t.geom),0.0001)),ST_MakeValid(ST_SnapToGrid(ST_Union(r.geom),0.0001))))),3) ) as geom, m.gid FROM "$NAME" t, "$CITY"_roads_grid r, land_use_grid g, laea_etrs_500m m WHERE g.city=1 AND g.cell=m.gid AND m.gid=t.cell AND r.cell=t.cell GROUP BY m.gid,m.geom) sq where cell=sq.gid;"
echo "...removing railways intersections..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" set geom=sq.geom from (SELECT ST_Multi(ST_CollectionExtract(ST_Difference(ST_MakeValid(ST_SnapToGrid(ST_Union(t.geom),0.0001)),ST_Multi(ST_Intersection(ST_MakeValid(ST_SnapToGrid(ST_Union(t.geom),0.0001)),ST_MakeValid(ST_SnapToGrid(ST_Union(r.geom),0.0001))))),3) ) as geom, m.gid FROM "$NAME" t, "$CITY"_railways_grid r, land_use_grid g, laea_etrs_500m m WHERE g.city=1 AND g.cell=m.gid AND m.gid=t.cell AND r.cell=t.cell GROUP BY m.gid,m.geom) sq where cell=sq.gid;"
echo "...removing trees intersections..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" set geom=sq.geom from (SELECT ST_Multi(ST_CollectionExtract(ST_Difference(ST_MakeValid(ST_SnapToGrid(ST_Union(t.geom),0.0001)),ST_Multi(ST_Intersection(ST_MakeValid(ST_SnapToGrid(ST_Union(t.geom),0.0001)),ST_MakeValid(ST_SnapToGrid(ST_Union(r.geom),0.0001))))),3) ) as geom, m.gid FROM "$NAME" t, "$CITY"_trees_grid r, land_use_grid g, laea_etrs_500m m WHERE g.city=1 AND g.cell=m.gid AND m.gid=t.cell AND r.cell=t.cell GROUP BY m.gid,m.geom) sq where cell=sq.gid;"
echo "...removing vegetation intersections..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" set geom=sq.geom from (SELECT ST_Multi(ST_CollectionExtract(ST_Difference(ST_MakeValid(ST_SnapToGrid(ST_Union(t.geom),0.0001)),ST_Multi(ST_Intersection(ST_MakeValid(ST_SnapToGrid(ST_Union(t.geom),0.0001)),ST_MakeValid(ST_SnapToGrid(ST_Union(r.geom),0.0001))))),3) ) as geom, m.gid FROM "$NAME" t, "$CITY"_vegetation_grid r, land_use_grid g, laea_etrs_500m m WHERE g.city=1 AND g.cell=m.gid AND m.gid=t.cell AND r.cell=t.cell GROUP BY m.gid,m.geom) sq where cell=sq.gid;"
echo "...removing agricultural areas intersections..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" set geom=sq.geom from (SELECT ST_Multi(ST_CollectionExtract(ST_Difference(ST_MakeValid(ST_SnapToGrid(ST_Union(t.geom),0.0001)),ST_Multi(ST_Intersection(ST_MakeValid(ST_SnapToGrid(ST_Union(t.geom),0.0001)),ST_MakeValid(ST_SnapToGrid(ST_Union(r.geom),0.0001))))),3) ) as geom, m.gid FROM "$NAME" t, "$CITY"_agricutltural_areas_grid r, land_use_grid g, laea_etrs_500m m WHERE g.city=1 AND g.cell=m.gid AND m.gid=t.cell AND r.cell=t.cell GROUP BY m.gid,m.geom) sq where cell=sq.gid;"
echo "...removing built up intersections..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" set geom=sq.geom from (SELECT ST_Multi(ST_CollectionExtract(ST_Difference(ST_MakeValid(ST_SnapToGrid(ST_Union(t.geom),0.0001)),ST_Multi(ST_Intersection(ST_MakeValid(ST_SnapToGrid(ST_Union(t.geom),0.0001)),ST_MakeValid(ST_SnapToGrid(ST_Union(r.geom),0.0001))))),3) ) as geom, m.gid FROM "$NAME" t, "$CITY"_built_up_grid r, land_use_grid g, laea_etrs_500m m WHERE g.city=1 AND g.cell=m.gid AND m.gid=t.cell AND r.cell=t.cell GROUP BY m.gid,m.geom) sq where cell=sq.gid;"
echo "...removing built open spaces intersections..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" set geom=sq.geom from (SELECT ST_Multi(ST_CollectionExtract(ST_Difference(ST_MakeValid(ST_SnapToGrid(ST_Union(t.geom),0.0001)),ST_Multi(ST_Intersection(ST_MakeValid(ST_SnapToGrid(ST_Union(t.geom),0.0001)),ST_MakeValid(ST_SnapToGrid(ST_Union(r.geom),0.0001))))),3) ) as geom, m.gid FROM "$NAME" t, "$CITY"_built_open_spaces_grid r, land_use_grid g, laea_etrs_500m m WHERE g.city=1 AND g.cell=m.gid AND m.gid=t.cell AND r.cell=t.cell GROUP BY m.gid,m.geom) sq where cell=sq.gid;"

#PARAMETERS
PARAMETERS="parameters"
ALBEDO=`grep -i -F [$LAYER] $PARAMETERS/albedo.dat | cut -f 2 -d ' '`
EMISSIVITY=`grep -i -F [$LAYER] $PARAMETERS/emissivity.dat | cut -f 2 -d ' '`
TRANSMISSIVITY=`grep -i -F [$LAYER] $PARAMETERS/transmissivity.dat | cut -f 2 -d ' '`
RUNOFF_COEFFICIENT=`grep -i -F [$LAYER] $PARAMETERS/run_off_coefficient.dat | cut -f 2 -d ' '`
CONTEXT=`grep -i -F [$LAYER] $PARAMETERS/context.dat | cut -f 2 -d ' '`

#adding rest of the parameters
echo "...Adding rest of parameters..."
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD albedo real DEFAULT "$ALBEDO";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD emissivity real DEFAULT "$EMISSIVITY";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD transmissivity real DEFAULT "$TRANSMISSIVITY";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD run_off_coefficient real DEFAULT "$RUNOFF_COEFFICIENT";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD context real DEFAULT "$CONTEXT";"

#Clusterization
echo "...Clusterizing..."
#psql -U "postgres" -d "clarity" -c "CLUSTER public.\""$NAME"\" USING public.\""$NAME"\"_pkey;"

#TAKE EVERYTHING FROM CITY TABLE TO GENERAL TABLE
psql -U "postgres" -d "clarity" -c "INSERT INTO public_military_industrial (SELECT * FROM "$NAME");"
fi
