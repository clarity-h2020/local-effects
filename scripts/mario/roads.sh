
#!/bin/bash
#CODE="CODE2006"
CODE="CODE2012"

LAYER="roads"
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

#ROADS (12210 Fast transit roads and associated land,12220 Other roads and associated land)
echo -e "\e[36m...Extract Urban Atlas data...\e[0m"
ogr2ogr -overwrite -sql "SELECT Shape_Area as area FROM "$SHP" WHERE "$CODE"='12210' OR "$CODE"='12220'" $NAME $FILE
shp2pgsql -k -s 3035 -I -d $NAME/$SHP.shp $NAME > $NAME".sql"
rm -r $NAME
psql -d clarity -U postgres -f $NAME".sql"
rm $NAME".sql"

#GEOMETRY INTEGRITY CHECK
echo -e "\e[36m...doing geometry integrity checks...\e[0m"
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" SET geom=St_MakeValid(geom);"
psql -U "postgres" -d "clarity" -c "SELECT * FROM "$NAME" WHERE NOT ST_Isvalid(geom);" > check.out
COUNT=`sed -n '3p' < check.out | cut -f 1 -d ' ' | cut -f 2 -d '('`
if [ $COUNT -gt 0 ];
then
        echo "\e[33m"$COUNT "problems found\e[0m"
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

#MAKING GOEMETRIES GRID LIKE
echo -e "\e[36m...generating grided geometries...\e[0m"
psql -U "postgres" -d "clarity" -c "DROP TABLE IF EXISTS "$NAME"_grid;"
psql -U "postgres" -d "clarity" -c "DROP SEQUENCE IF EXISTS "$NAME"_grid_seq;"

psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" DROP COLUMN area;"
psql -U "postgres" -d "clarity" -c "CREATE TABLE "$NAME"_grid (LIKE "$NAME" INCLUDING ALL);"
psql -U "postgres" -d "clarity" -c "CREATE SEQUENCE "$NAME"_grid_seq START WITH 1;"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME"_grid ALTER COLUMN gid SET DEFAULT nextval('"$NAME"_grid_seq');"
psql -U "postgres" -d "clarity" -c "INSERT INTO "$NAME"_grid (geom,city,cell) (SELECT ST_Multi(ST_CollectionExtract(ST_Intersection(ST_MakeValid(ST_SnapToGrid(ST_Union(a.geom),0.0001)), m.geom),3)) as geom,"$ID" as city,m.gid as cell FROM "$NAME" a, laea_etrs_500m m, city c WHERE c.name='"$CITY"' AND ST_Intersects(c.boundary,m.geom) AND ST_Intersects(a.geom, m.geom) GROUP BY m.geom,m.gid);"
psql -U "postgres" -d "clarity" -c "DROP TABLE "$NAME";"
NAME=$(echo $CITY"_"$LAYER"_GRID" | awk '{print tolower($0)}')

#NOT NEED TO REMOVE INTERSECTIONS

#PARAMETERS
PARAMETERS="parameters"
ALBEDO=`grep -i -F [$LAYER] $PARAMETERS/albedo.dat | cut -f 2 -d ' '`
EMISSIVITY=`grep -i -F [$LAYER] $PARAMETERS/emissivity.dat | cut -f 2 -d ' '`
TRANSMISSIVITY=`grep -i -F [$LAYER] $PARAMETERS/transmissivity.dat | cut -f 2 -d ' '`
VEGETATION_SHADOW=`grep -i -F [$LAYER] $PARAMETERS/vegetation_shadow.dat | cut -f 2 -d ' '`
RUNOFF_COEFFICIENT=`grep -i -F [$LAYER] $PARAMETERS/run_off_coefficient.dat | cut -f 2 -d ' '`

#adding rest of parameters
echo -e "\e[36m...Adding rest of parameters...\e[0m"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD albedo real DEFAULT "$ALBEDO";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD emissivity real DEFAULT "$EMISSIVITY";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD transmissivity real DEFAULT "$TRANSMISSIVITY";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD vegetation_shadow real DEFAULT "$VEGETATION_SHADOW";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD run_off_coefficient real DEFAULT "$RUNOFF_COEFFICIENT";"

#Adding FUA_TUNNEL, apply 1 as default
echo -e "\e[36m...Adding FUA_TUNNEL...\e[0m"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD fua_tunnel real DEFAULT 1;"
FUA_TUNNEL=`grep -i -F ['dense_urban_fabric'] $PARAMETERS/fua_tunnel.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET fua_tunnel="$FUA_TUNNEL" FROM "$CITY"_layers9_12 l WHERE ("$CODE"='11100' OR "$CODE"='11210') AND ST_Intersects( x.geom , l.geom );"
FUA_TUNNEL=`grep -i -F ['medium_urban_fabric'] $PARAMETERS/fua_tunnel.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET fua_tunnel="$FUA_TUNNEL" FROM "$CITY"_layers9_12 l WHERE "$CODE"='11220' AND ST_Intersects( x.geom , l.geom );"

#building shadow 1 by default(not intersecting) then update with value 0 when intersection occurs
echo -e "\e[36m...Adding building shadow...\e[0m"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD building_shadow smallint DEFAULT 1;"
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET building_shadow=0 FROM "$CITY"_layers9_12 l WHERE ST_Intersects( x.geom , l.geom );"

echo -e "\e[36m...Adding hillshade building...\e[0m"
#hillshade_building 1 by default then update depending on intersections
psql -U "postgres" -d "clarity" -c "ALTER TABLE public.\""$NAME"\" ADD hillshade_building real DEFAULT 1;"
#hillshade_building intersection with public_military_industrial(CODE=12100)
VALUE=`grep -i -F [public_military_industrial] parameters/hillshade_buildings.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET hillshade_building="$VALUE" FROM "$CITY"_layers9_12 l WHERE l."$CODE"='12100' AND ST_Intersects( x.geom , l.geom );"
#hillshade_building intersection with low_urban_fabric(CODE=11230,11240,11300)
VALUE=`grep -i -F [low_urban_fabric] parameters/hillshade_buildings.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET hillshade_building="$VALUE" FROM "$CITY"_layers9_12 l WHERE l."$CODE"='11230' AND ST_Intersects( x.geom , l.geom );"
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET hillshade_building="$VALUE" FROM "$CITY"_layers9_12 l WHERE l."$CODE"='11240' AND ST_Intersects( x.geom , l.geom );"
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET hillshade_building="$VALUE" FROM "$CITY"_layers9_12 l WHERE l."$CODE"='11300' AND ST_Intersects( x.geom , l.geom );"
#hillshade_building intersection with medium_urban_fabric(CODE=11220)
VALUE=`grep -i -F [medium_urban_fabric] parameters/hillshade_buildings.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET hillshade_building="$VALUE" FROM "$CITY"_layers9_12 l WHERE l."$CODE"='11220' AND ST_Intersects( x.geom , l.geom );"
#hillshade_building intersection with dense_urban_fabric(CODE=11210,11100)
VALUE=`grep -i -F [dense_urban_fabric] parameters/hillshade_buildings.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET hillshade_building="$VALUE" FROM "$CITY"_layers9_12 l WHERE l."$CODE"='11210' AND ST_Intersects( x.geom , l.geom );"
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET hillshade_building="$VALUE" FROM "$CITY"_layers9_12 l WHERE l."$CODE"='11100' AND ST_Intersects( x.geom , l.geom );"

#TAKE EVERYTHING FROM CITY TABLE TO GENERAL TABLE
echo -e "\e[36m...moving data to final table...\e[0m"
psql -U "postgres" -d "clarity" -c "INSERT INTO "$LAYER" (geom,city,cell,albedo,emissivity,transmissivity,vegetation_shadow,run_off_coefficient,fua_tunnel,building_shadow,hillshade_building) (SELECT geom,city,cell,albedo,emissivity,transmissivity,vegetation_shadow,run_off_coefficient,fua_tunnel,building_shadow,hillshade_building FROM "$NAME");"
fi
