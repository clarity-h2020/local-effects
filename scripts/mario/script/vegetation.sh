#!/bin/bash
#CODE="CODE2006"
CODE="CODE2012"

START_TOTAL=$(date +%s)

LAYER="vegetation"
if [[ $# -eq 0 ]] ; then
    echo -e "\e[33mERROR: No city name provided!\e[0m"
    exit 1
fi
CITY=$(echo "$1" | awk '{print toupper($0)}')
NAME=$(echo $CITY"_"$LAYER | awk '{print tolower($0)}')

#UA DATA
FOLDER_UA="data/"$CITY"/ua"
FILE_UA=`ls -la $FOLDER_UA/*.shp | cut -f 2 -d ':' | cut -f 2 -d ' '`
if [ ! "$FILE_UA" ]; then
    echo -e "\e[33mERROR: City UA data not found!\e[0m"
else
SHP_UA=`ogrinfo $FILE_UA | grep '1:' | cut -f 2 -d ' '`

#ESM40 RASTER
FOLDER_ESM="data/"$CITY"/esm"
FILE_ESM40=`ls -la $FOLDER_ESM/class40_$CITY.tif | rev | cut -f 1 -d ' ' | rev`
if [ ! "$FILE_ESM40" ]; then
    echo -e "\e[33mERROR: City ESM class40 data not found!\e[0m"
else
NAME_ESM40=`echo $FILE_ESM40 | rev | cut -f 1 -d '/' | rev | cut -f 1 -d '.'`
NAME_ESM40=$(echo $NAME_ESM40 | awk '{print tolower($0)}')
TIF_ESM40=$NAME"_calculated_class40.TIF"
SHP_ESM40=$NAME"_calculated_class40.shp"

#ESM20 RASTER
FILE_ESM20=`ls -la $FOLDER_ESM/class20_$CITY.tif | rev | cut -f 1 -d ' ' | rev`
if [ ! "$FILE_ESM20" ]; then
    echo -e "\e[33mERROR: City ESM class20 data not found!\e[0m"
else
NAME_ESM20=`echo $FILE_ESM20 | rev | cut -f 1 -d '/' | rev | cut -f 1 -d '.'`
NAME_ESM20=$(echo $NAME_ESM20 | awk '{print tolower($0)}')
TIF_ESM20=$NAME"_calculated_class20.TIF"
SHP_ESM20=$NAME"_calculated_class20.shp"


###############
# GRASS SETUP #
###############

echo -e "\e[36m...GRASS setup...\e[0m"
# path to GRASS binaries and libraries:
export GISBASE=/usr/lib/grass76
export PATH=$PATH:$GISBASE/bin:$GISBASE/scripts
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$GISBASE/lib

# set PYTHONPATH to include the GRASS Python lib
if [ ! "$PYTHONPATH" ] ; then
   PYTHONPATH="$GISBASE/etc/python"
else
   PYTHONPATH="$GISBASE/etc/python:$PYTHONPATH"
fi
export PYTHONPATH

# use process ID (PID) as lock file number:
export GIS_LOCK=$$

# settings for graphical output to PNG file (optional)
export GRASS_PNGFILE=/tmp/grass6output.png
export GRASS_TRUECOLOR=TRUE
export GRASS_WIDTH=900
export GRASS_HEIGHT=1200
export GRASS_PNG_COMPRESSION=1
export GRASS_MESSAGE_FORMAT=plain

# path to GRASS settings file
export GISRC=$HOME/.grassrc7

# path to GRASS settings file
export GISRC=/tmp/grass7-${USER}-$GIS_LOCK/gisrc
# remove any leftover files/folder
rm -fr /tmp/grass7-${USER}-$GIS_LOCK
mkdir /tmp/grass7-${USER}-$GIS_LOCK
export TMPDIR="/tmp/grass7-${USER}-$GIS_LOCK"
# set GISDBASE, LOCATION_NAME, and/or MAPSET
echo "GISDBASE: /home/mario.nunez/script/grass" >>$GISRC
echo "LOCATION_NAME: location" >>$GISRC
echo "MAPSET: PERMANENT" >>$GISRC
# start in text mode
echo "GRASS_GUI: text" >>$GISRC

echo -e "\e[36mgrass configuration done\e[0m"

###########################
# VEGETATION SCRIPT START #
###########################

#URBAN ATLAS (14100 green urban areas, 32000 herbaceous vegetation, 33000 Open spaces with little or no vegetations,13300 land without use)
echo -e "\e[36m...Extract Urban Atlas data...\e[0m"
ogr2ogr -overwrite -sql "SELECT Shape_Area as area FROM "$SHP_UA" WHERE "$CODE"='14100' OR "$CODE"='32000' OR "$CODE"='33000' OR "$CODE"='13400'" $NAME $FILE_UA
shp2pgsql -s 3035 -I -d $NAME/$SHP_UA.shp $NAME > $NAME".sql"
rm -r $NAME
psql -d clarity -U postgres -f $NAME".sql"
rm $NAME".sql"

#ESM40 raster reclassification with treshold 25
echo -e "\e[36m...Reclassifying ESM40 data...\e[0m"
NODATA=`gdalinfo $FILE_ESM40 | grep 'NoData' | cut -f 2 -d '='`
python gdal_reclassify.py $FILE_ESM40 $TIF_ESM40 -r "$NODATA,1" -c "<25,>=25" -d $NODATA -n true -p "COMPRESS=LZW"

#parameters needed for poligonization
LAT=`gdalinfo $TIF_ESM40 | grep 'latitude_of_center' | cut -f 2 -d ',' | cut -f 1 -d ']'`
LON=`gdalinfo $TIF_ESM40 | grep 'longitude_of_center' | cut -f 2 -d ',' | cut -f 1 -d ']'`
X=`gdalinfo $TIF_ESM40 | grep 'false_easting' | cut -f 2 -d ',' | cut -f 1 -d ']'`
Y=`gdalinfo $TIF_ESM40 | grep 'false_northing' | cut -f 2 -d ',' | cut -f 1 -d ']'`
N=`gdalinfo $TIF_ESM40 | grep 'Upper Left' | cut -f 6 -d ' ' | cut -f 1 -d ')'`
S=`gdalinfo $TIF_ESM40 | grep 'Lower Right' | cut -f 5 -d ' ' | cut -f 1 -d ')'`
E=`gdalinfo $TIF_ESM40 | grep 'Lower Right' | cut -f 4 -d ' ' | cut -f 1 -d ','`
W=`gdalinfo $TIF_ESM40 | grep 'Upper Left' | cut -f 5 -d ' ' | cut -f 1 -d ','`
RES=`gdalinfo $TIF_ESM40 | grep 'Pixel Size' | cut -f 4 -d ' ' | cut -f 1 -d ',' | cut -f 2 -d '('`

#poligonization with grass
echo -e "\e[36m...ESM40 raster to shapefile, GRASS polygonization...\e[0m"
g.proj -c proj4="+proj=laea +lat_0=$LAT +lon_0=$LON +x_0=$X +y_0=$Y +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"
r.external input="$TIF_ESM40" band=1 output=rast_5bd8903d0a6372 --overwrite -o
g.region n=$N s=$S e=$E w=$W res=$RES
r.to.vect input=rast_5bd8903d0a6372 type="area" column="value" output=output08aad7e15cf0402da3436e32ac40c6c9 --overwrite
v.out.ogr type="auto" input="output08aad7e15cf0402da3436e32ac40c6c9" output="$SHP_ESM40" format="ESRI_Shapefile" --overwrite
rm $TIF_ESM40

#result to database
echo -e "\e[36m...Exporting ESM40 result to database...\e[0m"
shp2pgsql -k -s 3035 -I -d $SHP_ESM40 $NAME_ESM40 > $NAME_ESM40.sql
rm $NAME"_calculated_class40".*
psql -d clarity -U postgres -f $NAME_ESM40.sql
rm $NAME_ESM40.*

#Putting together ESM40 and UA extracted data
echo -e "\e[36m...adding ESM40 to previosuly extracted UA data...\e[0m"
psql -U "postgres" -d "clarity" -c "INSERT INTO "$NAME" (SELECT NEXTVAL('"$NAME"_gid_seq') as gid, ST_Area(geom) as area, geom FROM public.\""$NAME_ESM40"\");"
psql -U "postgres" -d "clarity" -c "DROP TABLE public.\""$NAME_ESM40"\";"



#ESM20 raster reclassification with treshold 25
echo -e "\e[36m...Reclassifying ESM20 data...\e[0m"
NODATA=`gdalinfo $FILE_ESM40 | grep 'NoData' | cut -f 2 -d '='`
python gdal_reclassify.py $FILE_ESM20 $TIF_ESM20 -r "$NODATA,1" -c "<25,>=25" -d $NODATA -n true -p "COMPRESS=LZW"

#parameters needed for poligonization
LAT=`gdalinfo $TIF_ESM20 | grep 'latitude_of_center' | cut -f 2 -d ',' | cut -f 1 -d ']'`
LON=`gdalinfo $TIF_ESM20 | grep 'longitude_of_center' | cut -f 2 -d ',' | cut -f 1 -d ']'`
X=`gdalinfo $TIF_ESM20 | grep 'false_easting' | cut -f 2 -d ',' | cut -f 1 -d ']'`
Y=`gdalinfo $TIF_ESM20 | grep 'false_northing' | cut -f 2 -d ',' | cut -f 1 -d ']'`
N=`gdalinfo $TIF_ESM20 | grep 'Upper Left' | cut -f 6 -d ' ' | cut -f 1 -d ')'`
S=`gdalinfo $TIF_ESM20 | grep 'Lower Right' | cut -f 5 -d ' ' | cut -f 1 -d ')'`
E=`gdalinfo $TIF_ESM20 | grep 'Lower Right' | cut -f 4 -d ' ' | cut -f 1 -d ','`
W=`gdalinfo $TIF_ESM20 | grep 'Upper Left' | cut -f 5 -d ' ' | cut -f 1 -d ','`
RES=`gdalinfo $TIF_ESM20 | grep 'Pixel Size' | cut -f 4 -d ' ' | cut -f 1 -d ',' | cut -f 2 -d '('`

#poligonization with grass
echo -e "\e[36m...ESM20 raster to shapefile, GRASS polygonization...\e[0m"
g.proj -c proj4="+proj=laea +lat_0=$LAT +lon_0=$LON +x_0=$X +y_0=$Y +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"
r.external input="$TIF_ESM20" band=1 output=rast_5bd8903d0a6372 --overwrite -o
g.region n=$N s=$S e=$E w=$W res=$RES
r.to.vect input=rast_5bd8903d0a6372 type="area" column="value" output=output08aad7e15cf0402da3436e32ac40c6c9 --overwrite
v.out.ogr type="auto" input="output08aad7e15cf0402da3436e32ac40c6c9" output="$SHP_ESM20" format="ESRI_Shapefile" --overwrite
rm $TIF_ESM20

#result to database
echo -e "\e[36m...Exporting ESM20 result to database...\e[0m"
shp2pgsql -k -s 3035 -I -d $SHP_ESM20 $NAME_ESM20 > $NAME_ESM20.sql
rm $NAME"_calculated_class20".*
psql -d clarity -U postgres -f $NAME_ESM20.sql
rm $NAME_ESM20.*

#Putting together ESM20 and UA extracted data
echo -e "\e[36m...adding ESM20 to previosuly extracted UA data...\e[0m"
psql -U "postgres" -d "clarity" -c "INSERT INTO "$NAME" (SELECT NEXTVAL('"$NAME"_gid_seq') as gid, ST_Area(geom) as area, geom FROM public.\""$NAME_ESM20"\");"
psql -U "postgres" -d "clarity" -c "DROP TABLE public.\""$NAME_ESM20"\";"



#GEOMETRY INTEGRITY CHECK
echo -e "\e[36m...doing geometry integrity checks...\e[0m"
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" SET geom=St_MakeValid(geom);"
psql -U "postgres" -d "clarity" -c "SELECT * FROM "$NAME" WHERE NOT ST_Isvalid(geom);" > check.out
COUNT=`sed -n '3p' < check.out | cut -f 1 -d ' ' | cut -f 2 -d '('`
if [ $COUNT -gt 0 ];
then
        echo -e "\e[33m"$COUNT "problems found!\e[0m"
        echo -e "\e[36m......deleting affected geometries to avoid further problems with them...\e[0m"
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
psql -U "postgres" -d "clarity" -c "CREATE INDEX "$NAME"_geom_index ON "$NAME" USING GIST (geom);"
psql -U "postgres" -d "clarity" -c "CREATE TABLE "$NAME"_grid (LIKE "$NAME" INCLUDING ALL);"
psql -U "postgres" -d "clarity" -c "DROP SEQUENCE "$NAME"_grid_seq;"
psql -U "postgres" -d "clarity" -c "CREATE SEQUENCE "$NAME"_grid_seq START WITH 1;"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME"_grid ALTER COLUMN gid SET DEFAULT nextval('"$NAME"_grid_seq');"
psql -U "postgres" -d "clarity" -c "INSERT INTO "$NAME"_grid (geom,city,cell) (SELECT ST_Multi(ST_CollectionExtract(ST_Intersection(ST_MakeValid(ST_SnapToGrid(ST_Union(a.geom),0.0001)), m.geom),3)) as geom, "$ID" as city,m.gid as cell FROM "$NAME" a, laea_etrs_500m m, land_use_grid l WHERE l.city="$ID" AND l.cell=m.gid AND ST_Intersects(a.geom, m.geom) GROUP BY m.geom,m.gid);"
psql -U "postgres" -d "clarity" -c "DROP TABLE "$NAME" CASCADE;"
NAME=$(echo $CITY"_"$LAYER"_GRID" | awk '{print tolower($0)}')

#remove intersections with previous layers
echo -e "\e[36m...removing water intersections...\e[0m"
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" SET geom=sq.geom FROM (SELECT t.gid as id, ST_Multi(ST_CollectionExtract(ST_Difference(ST_MakeValid(ST_SnapToGrid(t.geom,0.0001)),ST_MakeValid(ST_SnapToGrid(r.geom,0.0001))),3) ) as geom FROM "$NAME" t, "$CITY"_water_grid r WHERE r.cell=t.cell) as sq WHERE gid=sq.id;"
echo -e "\e[36m...removing roads intersections...\e[0m"
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" SET geom=sq.geom FROM (SELECT t.gid as id, ST_Multi(ST_CollectionExtract(ST_Difference(ST_MakeValid(ST_SnapToGrid(t.geom,0.0001)),ST_MakeValid(ST_SnapToGrid(r.geom,0.0001))),3) ) as geom FROM "$NAME" t, "$CITY"_roads_grid r WHERE r.cell=t.cell) as sq WHERE gid=sq.id;"
echo -e "\e[36m...removing railways intersections...\e[0m"
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" SET geom=sq.geom FROM (SELECT t.gid as id, ST_Multi(ST_CollectionExtract(ST_Difference(ST_MakeValid(ST_SnapToGrid(t.geom,0.0001)),ST_MakeValid(ST_SnapToGrid(r.geom,0.0001))),3) ) as geom FROM "$NAME" t, "$CITY"_railways_grid r WHERE r.cell=t.cell) as sq WHERE gid=sq.id;"
echo -e "\e[36m...removing trees intersections...\e[0m"
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" SET geom=sq.geom FROM (SELECT t.gid as id, ST_Multi(ST_CollectionExtract(ST_Difference(ST_MakeValid(ST_SnapToGrid(t.geom,0.0001)),ST_MakeValid(ST_SnapToGrid(r.geom,0.0001))),3) ) as geom FROM "$NAME" t, "$CITY"_trees_grid r WHERE r.cell=t.cell) as sq WHERE gid=sq.id;"

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

#hillshade_buildings - NOW DONE FROM land use grid SCRIPT
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD hillshade_building real DEFAULT NULL;"

HILLSHADE_GREEN_FRACTION=`grep -i -F [$LAYER] $PARAMETERS/hillshade_green_fraction.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD hillshade_green_fraction real DEFAULT "$HILLSHADE_GREEN_FRACTION";"
BUILDING_SHADOW=`grep -i -F [$LAYER] $PARAMETERS/building_shadow.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD building_shadow real DEFAULT "$BUILDING_SHADOW";"
VEGETATION_SHADOW=`grep -i -F [$LAYER] $PARAMETERS/vegetation_shadow.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD vegetation_shadow real DEFAULT "$VEGETATION_SHADOW";"
RUNOFF_COEFFICIENT=`grep -i -F [$LAYER] $PARAMETERS/run_off_coefficient.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD run_off_coefficient real DEFAULT "$RUNOFF_COEFFICIENT";"

#Adding FUA_TUNNEL, apply 1 as default
echo -e "\e[36m...Adding FUA_TUNNEL...\e[0m"
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD fua_tunnel real DEFAULT 1;"
FUA_TUNNEL=`grep -i -F ['dense_urban_fabric'] $PARAMETERS/fua_tunnel.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET fua_tunnel="$FUA_TUNNEL" FROM "$CITY"_layers9_12 l WHERE ("$CODE"='11100' OR "$CODE"='11210') AND ST_Intersects( x.geom , l.geom );"
FUA_TUNNEL=`grep -i -F ['medium_urban_fabric'] $PARAMETERS/fua_tunnel.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET fua_tunnel="$FUA_TUNNEL" FROM "$CITY"_layers9_12 l WHERE "$CODE"='11220' AND ST_Intersects( x.geom , l.geom );"


#TAKE EVERYTHING FROM CITY TABLE TO GENERAL TABLE
echo -e "\e[36m...moving data to final table...\e[0m"
psql -U "postgres" -d "clarity" -c "INSERT INTO "$LAYER" (geom,city,cell,albedo,emissivity,transmissivity,hillshade_building,hillshade_green_fraction,building_shadow,vegetation_shadow,run_off_coefficient,fua_tunnel) (SELECT geom,city,cell,albedo,emissivity,transmissivity,hillshade_building,hillshade_green_fraction,building_shadow,vegetation_shadow,run_off_coefficient,fua_tunnel FROM "$NAME");"
fi
fi
fi

END_TOTAL=$(date +%s)
TIME_TOTAL=`echo $((END_TOTAL-START_TOTAL)) | awk '{printf "%d:%02d:%02d", $1/3600, ($1/60)%60, $1%60}'`
echo -e "\e[36m- "$LAYER" ended - total time is "$TIME_TOTAL"\e[0m"
