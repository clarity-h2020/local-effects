#!/bin/bash
CODE="CODE2006"
#CODE="CODE2012"

LAYER="vegetation"
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
#NAME=$(echo $SHP"_"$LAYER | awk '{print tolower($0)}')
NAME=$(echo $CITY"_"$LAYER | awk '{print tolower($0)}')

#ESM RASTER
FOLDER2="data/"$CITY"/esm"
FILE2=`ls -la $FOLDER2/class40_$CITY.tif | cut -f 10 -d ' '`
NAME2=`echo $FILE2 | rev | cut -f 1 -d '/' | rev | cut -f 1 -d '.'`
NAME2=$(echo $NAME2 | awk '{print tolower($0)}')
TIF=$NAME"_calculated.TIF"
SHP2=$NAME"_calculated.shp"

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
# VEGETATION SCRIPT START #
###########################

#PARAMETERS
PARAMETERS="parameters"
ALBEDO=`grep -i -F [$LAYER] $PARAMETERS/albedo.dat | cut -f 2 -d ' '`
EMISSIVITY=`grep -i -F [$LAYER] $PARAMETERS/emissivity.dat | cut -f 2 -d ' '`
TRANSMISSIVITY=`grep -i -F [$LAYER] $PARAMETERS/transmissivity.dat | cut -f 2 -d ' '`
VEGETATION_SHADOW=`grep -i -F [$LAYER] $PARAMETERS/vegetation_shadow.dat | cut -f 2 -d ' '`
RUNOFF_COEFFICIENT=`grep -i -F [$LAYER] $PARAMETERS/run_off_coefficient.dat | cut -f 2 -d ' '`

#URBAN ATLAS (14100 green urban areas, 14200 sport and leisure facilities, 32000 herbaceous vegetation, 33000 Open spaces with little or no vegetations)
echo "...Extract Urban Atlas data..."
#ogr2ogr -sql "SELECT area,perimeter FROM "$SHP" WHERE "$CODE"='14100' OR "$CODE"='14200' OR "$CODE"='32000' OR "$CODE"='33000'" $NAME $FILE
ogr2ogr -overwrite -sql "SELECT Shape_Area as area, Shape_Leng as perimeter FROM "$SHP" WHERE "$CODE"='14100' OR "$CODE"='14200' OR "$CODE"='32000' OR "$CODE"='33000'" $NAME $FILE
shp2pgsql -s 3035 -I -d $NAME/$SHP.shp $NAME > $NAME".sql"
rm -r $NAME
psql -d clarity -U postgres -f $NAME".sql"
rm $NAME".sql"

#raster reclassification with treshold 25
echo "...Reclassifying ESM data..."
NODATA=`gdalinfo $FILE2 | grep 'NoData' | cut -f 2 -d '='`
python gdal_reclassify.py $FILE2 $TIF -r "$NODATA,1" -c "<25,>=25" -d $NODATA -n true -p "COMPRESS=LZW"

#parameters needed for poligonization
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
echo "...ESM raster to shapefile, GRASS polygonization..."
g.proj -c proj4="+proj=laea +lat_0=$LAT +lon_0=$LON +x_0=$X +y_0=$Y +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"
r.external input="$TIF" band=1 output=rast_5bd8903d0a6372 --overwrite -o
g.region n=$N s=$S e=$E w=$W res=$RES
r.to.vect input=rast_5bd8903d0a6372 type="area" column="value" output=output08aad7e15cf0402da3436e32ac40c6c9 --overwrite
v.out.ogr type="auto" input="output08aad7e15cf0402da3436e32ac40c6c9" output="$SHP2" format="ESRI_Shapefile" --overwrite
rm $TIF

#result to databse
echo "...Exporting ESM result to database..."
shp2pgsql -k -s 3035 -I -d $SHP2 $NAME2 > $NAME2.sql
rm $NAME"_calculated".*
psql -d clarity -U postgres -f $NAME2.sql
rm $NAME2.*

#Putting together ESM and UA extracted data
echo "...adding previosuly extracted UA data..."
psql -U "postgres" -d "clarity" -c "INSERT INTO "$NAME" (SELECT NEXTVAL('"$NAME"_gid_seq'), ST_Perimeter(geom), ST_Area(geom) FROM public.\""$NAME2"\");"
psql -U "postgres" -d "clarity" -c "DROP TABLE public.\""$NAME2"\";"

#remove intersections with previous layers
echo "...removing water intersections..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" x SET geom=ST_Multi(ST_CollectionExtract(ST_MakeValid( ST_Difference(x.geom, w.geom)),3)) FROM "$CITY"_water w WHERE ST_Contains(x.geom, w.geom) OR ST_Overlaps(x.geom, w.geom);"
echo "...removing roads intersections..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" x SET geom=ST_Multi(ST_CollectionExtract(ST_MakeValid( ST_Difference(x.geom, r.geom)),3)) FROM "$CITY"_roads r WHERE ST_Contains(x.geom, r.geom) OR ST_Overlaps(x.geom, r.geom);"
echo "...removing railways intersections..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" x SET geom=ST_Multi(ST_CollectionExtract(ST_MakeValid( ST_Difference(x.geom, r.geom)),3)) FROM "$CITY"_railways r WHERE ST_Contains(x.geom, r.geom) OR ST_Overlaps(x.geom, r.geom);"
echo "...removing trees intersections..."
psql -U "postgres" -d "clarity" -c "UPDATE "$NAME" x SET geom=ST_Multi(ST_CollectionExtract(ST_MakeValid( ST_Difference(x.geom, t.geom)),3)) FROM "$CITY"_trees t WHERE ST_Contains(x.geom, t.geom) OR ST_Overlaps(x.geom, t.geom);"

#adding rest of the parameters
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

#building shadow 1 by default(not interseccting) then update with value 0 when intersecting
echo "...Adding building shadow..."
psql -U "postgres" -d "clarity" -c "ALTER TABLE "$NAME" ADD building_shadow smallint DEFAULT 1;"
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET building_shadow=0 FROM "$CITY"_layers9_12 l WHERE ST_Intersects( x.geom , l.geom );"

#Clusterization
echo "...Clusterizying..."
#psql -U "postgres" -d "clarity" -c "CLUSTER public.\""$NAME"\" USING public.\""$NAME"\"_pkey;"

#TAKE EVERYTHING FROM CITY TABLE TO GENERAL TABLE
#psql -U "postgres" -d "clarity" -c "INSERT INTO vegetation (SELECT * FROM "$NAME");"
fi
