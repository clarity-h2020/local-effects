#!/bin/bash
CODE="CODE2006"
#CODE="CODE2012"

LAYER="built_up"
if [[ $# -eq 0 ]] ; then
    echo -e "\e[33mERROR: No city name provided!\e[0m"
    exit 1
fi
CITY=$(echo "$1" | awk '{print toupper($0)}')
FOLDER="data/"$CITY"/esm"
FILE=`ls -la $FOLDER/class50_$CITY.tif | cut -f 10 -d ' '`

NAME=$(echo $CITY"_"$LAYER | awk '{print tolower($0)}')
if [ ! "$FILE" ]; then
    echo "ERROR: City data not found!"
else

###############
# GRASS SETUP #
###############

echo "...GRASS setup..."
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


###########################
# BUILDINGS SCRIPT START #
###########################

TIF=$NAME"_calculated.TIF"
SHP=$NAME"_calculated.shp"

#PARAMETERS
PARAMETERS="parameters"
ALBEDO=`grep -i -F [$LAYER] $PARAMETERS/albedo.dat | cut -f 2 -d ' '`
EMISSIVITY=`grep -i -F [$LAYER] $PARAMETERS/emissivity.dat | cut -f 2 -d ' '`
TRANSMISSIVITY=`grep -i -F [$LAYER] $PARAMETERS/transmissivity.dat | cut -f 2 -d ' '`
VEGETATION_SHADOW=`grep -i -F [$LAYER] $PARAMETERS/vegetation_shadow.dat | cut -f 2 -d ' '`
RUNOFF_COEFFICIENT=`grep -i -F [$LAYER] $PARAMETERS/run_off_coefficient.dat | cut -f 2 -d ' '`

#raster reclassification with treshold 45
echo "...Reclassifying..."
NODATA=`gdalinfo $FILE | grep 'NoData' | cut -f 2 -d '='`
python gdal_reclassify.py $FILE $TIF -r "$NODATA,1" -c "<45,>=45" -d $NODATA -n true -p "COMPRESS=LZW"

#raster parameters needed for polygonization
LAT=`gdalinfo $TIF | grep 'latitude_of_center' | cut -f 2 -d ',' | cut -f 1 -d ']'`
LON=`gdalinfo $TIF | grep 'longitude_of_center' | cut -f 2 -d ',' | cut -f 1 -d ']'`
X=`gdalinfo $TIF | grep 'false_easting' | cut -f 2 -d ',' | cut -f 1 -d ']'`
Y=`gdalinfo $TIF | grep 'false_northing' | cut -f 2 -d ',' | cut -f 1 -d ']'`
N=`gdalinfo $TIF | grep 'Upper Left' | cut -f 6 -d ' ' | cut -f 1 -d ')'`
S=`gdalinfo $TIF | grep 'Lower Right' | cut -f 5 -d ' ' | cut -f 1 -d ')'`
E=`gdalinfo $TIF | grep 'Lower Right' | cut -f 4 -d ' ' | cut -f 1 -d ','`
W=`gdalinfo $TIF | grep 'Upper Left' | cut -f 5 -d ' ' | cut -f 1 -d ','`
RES=`gdalinfo $TIF | grep 'Pixel Size' | cut -f 4 -d ' ' | cut -f 1 -d ',' | cut -f 2 -d '('`

#poligonization with grass
echo "...Raster to shapefile, GRASS polygonization..."
g.proj -c proj4="+proj=laea +lat_0=$LAT +lon_0=$LON +x_0=$X +y_0=$Y +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"
r.external input="$TIF" band=1 output=rast_5bd8903d0a6372 --overwrite -o
g.region n=$N s=$S e=$E w=$W res=$RES
r.to.vect input=rast_5bd8903d0a6372 type="area" column="value" output=output08aad7e15cf0402da3436e32ac40c6c9 --overwrite
v.out.ogr type="auto" input="output08aad7e15cf0402da3436e32ac40c6c9" output="$SHP" format="ESRI_Shapefile" --overwrite

#result to database
echo "...Exporting results to database..."
shp2pgsql -k -s 3035 -I -d $SHP $NAME > $NAME.sql
psql -d clarity -U postgres -f $NAME.sql
rm $NAME"_calculated.TIF"
rm $NAME"_calculated.shp"
rm $NAME"_calculated.dbf"
rm $NAME"_calculated.shx"
rm $NAME"_calculated.prj"
rm $NAME".sql"

#GEOMETRY INTEGRITY CHECK
echo "...doing geometry integrity checks..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" SET geom=St_MakeValid(St_Multi(St_Buffer(geom,0.0001)));"
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
echo "ID CIUDAD:" $ID
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
if [ $FOUND ];
then
        echo "...deleting old table..."
        psql -U "postgres" -d "clarity" -c "DROP TABLE "$NAME"_grid;"
fi
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" DROP COLUMN area;"
psql -U "postgres" -d "clarity" -c "CREATE TABLE "$NAME"_grid (LIKE "$NAME" INCLUDING ALL);"
psql -U "postgres" -d "clarity" -c "INSERT INTO "$NAME"_grid (geom,city,cell) (SELECT ST_Multi(ST_Intersection(ST_Union(a.geom), m.geom)) as geom,"$ID" as city, m.gid as cell FROM "$NAME" a, laea_etrs_500m m, city c WHERE c.name='"$CITY"' AND ST_Intersects(c.bbox,m.geom) AND ST_Intersects(a.geom, m.geom) GROUP BY m.geom,m.gid);"
psql -U "postgres" -d "clarity" -c "DROP TABLE "$NAME" CASCADE;"
NAME=$(echo $CITY"_"$LAYER"_GRID" | awk '{print tolower($0)}')

#remove intersections with previous layers
echo "...removing water intersections..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" set geom=sq.geom from (SELECT ST_Multi(ST_CollectionExtract(ST_Difference( ST_Union(t.geom),ST_Multi(ST_Intersection(ST_Union(t.geom),ST_Union(r.geom))) ),3 ) )  as geom, m.gid FROM "$NAME" t, water r, land_use_grid g, laea_etrs_500m m WHERE g.city=1 AND g.cell=m.gid AND m.gid=t.cell AND r.cell=t.cell GROUP BY m.gid,m.geom) sq where cell=sq.gid;"
echo "...removing roads intersections..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" set geom=sq.geom from (SELECT ST_Multi(ST_CollectionExtract(ST_Difference( ST_Union(t.geom),ST_Multi(ST_Intersection(ST_Union(t.geom),ST_Union(r.geom))) ),3 ) )  as geom, m.gid FROM "$NAME" t, roads r, land_use_grid g, laea_etrs_500m m WHERE g.city=1 AND g.cell=m.gid AND m.gid=t.cell AND r.cell=t.cell GROUP BY m.gid,m.geom) sq where cell=sq.gid;"
echo "...removing railways intersections..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" set geom=sq.geom from (SELECT ST_Multi(ST_CollectionExtract(ST_Difference( ST_Union(t.geom),ST_Multi(ST_Intersection(ST_Union(t.geom),ST_Union(r.geom))) ),3 ) )  as geom, m.gid FROM "$NAME" t, railways r, land_use_grid g, laea_etrs_500m m WHERE g.city=1 AND g.cell=m.gid AND m.gid=t.cell AND r.cell=t.cell GROUP BY m.gid,m.geom) sq where cell=sq.gid;"
echo "...removing trees intersections..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" set geom=sq.geom from (SELECT ST_Multi(ST_CollectionExtract(ST_Difference( ST_Union(t.geom),ST_Multi(ST_Intersection(ST_Union(t.geom),ST_Union(r.geom))) ),3 ) )  as geom, m.gid FROM "$NAME" t, trees r, land_use_grid g, laea_etrs_500m m WHERE g.city=1 AND g.cell=m.gid AND m.gid=t.cell AND r.cell=t.cell GROUP BY m.gid,m.geom) sq where cell=sq.gid;"
echo "...removing vegetation intersections..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" set geom=sq.geom from (SELECT ST_Multi(ST_CollectionExtract(ST_Difference( ST_Union(t.geom),ST_Multi(ST_Intersection(ST_Union(t.geom),ST_Union(r.geom))) ),3 ) )  as geom, m.gid FROM "$NAME" t, vegetation r, land_use_grid g, laea_etrs_500m m WHERE g.city=1 AND g.cell=m.gid AND m.gid=t.cell AND r.cell=t.cell GROUP BY m.gid,m.geom) sq where cell=sq.gid;"
echo "...removing agricultural areas intersections..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" set geom=sq.geom from (SELECT ST_Multi(ST_CollectionExtract(ST_Difference( ST_Union(t.geom),ST_Multi(ST_Intersection(ST_Union(t.geom),ST_Union(r.geom))) ),3 ) )  as geom, m.gid FROM "$NAME" t, agricultural_areas r, land_use_grid g, laea_etrs_500m m WHERE g.city=1 AND g.cell=m.gid AND m.gid=t.cell AND r.cell=t.cell GROUP BY m.gid,m.geom) sq where cell=sq.gid;"

#drop not needed columns
echo "...Dropping not needed columns..."
psql -U "postgres" -d "clarity" -c "ALTER TABLE public.\""$NAME"\" DROP COLUMN cat;"
psql -U "postgres" -d "clarity" -c "ALTER TABLE public.\""$NAME"\" DROP COLUMN value;"
psql -U "postgres" -d "clarity" -c "ALTER TABLE public.\""$NAME"\" DROP COLUMN label;"

#add perimeter and area
echo "...adding perimeter..."
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD area real;"
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" SET area=ST_Area(geom);"
echo "...adding area..."
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD perimeter real;"
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" SET area=ST_Perimeter(geom);"

#add rest of the parameters to the layer
echo "...Adding rest of parameters..."
psql -U "postgres" -d "clarity" -c "ALTER TABLE public.\""$NAME"\" ADD albedo real DEFAULT "$ALBEDO";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE public.\""$NAME"\" ADD emissivity real DEFAULT "$EMISSIVITY";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE public.\""$NAME"\" ADD transmissivity real DEFAULT "$TRANSMISSIVITY";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE public.\""$NAME"\" ADD vegetation_shadow real DEFAULT "$VEGETATION_SHADOW";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE public.\""$NAME"\" ADD run_off_coefficient real DEFAULT "$RUNOFF_COEFFICIENT";"

#Adding FUA_TUNNEL, apply 1 as default
echo "...Adding FUA_TUNNEL..."
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD fua_tunnel real DEFAULT 1;"
FUA_TUNNEL=`grep -i -F ['dense_urban_fabric'] $PARAMETERS/fua_tunnel.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET fua_tunnel="$FUA_TUNNEL" FROM "$CITY"_layers9_12 l WHERE ("$CODE"='11100' OR "$CODE"='11210') AND ST_Intersects( x.geom , l.geom );"
FUA_TUNNEL=`grep -i -F ['medium_urban_fabric'] $PARAMETERS/fua_tunnel.dat | cut -f 2 -d ' '`
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET fua_tunnel="$FUA_TUNNEL" FROM "$CITY"_layers9_12 l WHERE "$CODE"='11220' AND ST_Intersects( x.geom , l.geom );"

######ADD HEIGHT
#HEIGHT_FILE="/home/mario.nunez/script/data/height/$CITY"_height".tif"
#if [ -f $HEIGHT_FILE ];then
######TO-DO media de altura del raster para cada poligono de edificio
######https://github.com/perrygeo/python-rasterstats

#building shadow 1 by default(not intersecting) then update with value 0 when intersecting
echo "...Adding building shadow..."
psql -U "postgres" -d "clarity" -c "ALTER TABLE public.\""$NAME"\" ADD building_shadow smallint DEFAULT 1;"
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET building_shadow=0 FROM "$CITY"_layers9_12 l WHERE ST_Intersects( x.geom , l.geom );"

#Clusterization
echo "...Clusterizing..."
#psql -U "postgres" -d "clarity" -c "CLUSTER public.\""$NAME"\" USING public.\""$NAME"\"_pkey;"

#TAKE EVERYTHING FROM CITY TABLE TO GENERAL TABLE
#psql -U "postgres" -d "clarity" -c "INSERT INTO built_up (SELECT * FROM "$NAME");"
#psql -U "postgres" -d "clarity" -c "DROP TABLE "$NAME";"
fi
