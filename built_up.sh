
#!/bin/bash

LAYER="built_up"
CITY=$(echo "$1" | awk '{print toupper($0)}')

FOLDER="data/"$CITY"/esm"
FILE=`ls -la $FOLDER/class50_$CITY.tif | cut -f 9 -d ' '`
NAME2=`echo $FILE | rev | cut -f 1 -d '/' | rev | cut -f 1 -d '.'`
NAME2=$(echo $NAME2 | awk '{print tolower($0)}')

FOLDER2="data/"$CITY"/ua"
FILE2=`ls -la $FOLDER2/*.shp | cut -f 9 -d ' '`
SHP2=`ogrinfo $FILE2 | grep '1:' | cut -f 2 -d ' '`
NAME=$(echo $SHP2"_"$LAYER | awk '{print tolower($0)}')
DATA=$(echo $SHP2"_layers9_12" | awk '{print tolower($0)}')

if [ ! "$FILE" ] || [ ! "$FILE2" ]; then
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
rm $FILE

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
shp2pgsql -k -s 3035 -S -I -d $SHP $NAME > $NAME.sql
psql -d clarity -U postgres -f $NAME.sql
rm $NAME"_calculated.TIF"
rm $NAME"_calculated.prj"
rm $NAME"_calculated.shx"
rm $NAME"_calculated.shp"
#rm $NAME"_calculated.prj"
rm $NAME"_calculated.dbf"
rm $NAME".sql"

#REMOVE INTERSECTIONS WITH LAYERS 6,5,4,3,2,1 check in postgis...
echo "...Intersection removal..."
psql -U "postgres" -d "clarity" -c "DELETE FROM public.\""$NAME"\" USING water w WHERE ST_Intersects( public.\""$NAME"\".geom , w.geom );"
psql -U "postgres" -d "clarity" -c "DELETE FROM public.\""$NAME"\" USING roads r WHERE ST_Intersects( public.\""$NAME"\".geom , r.geom );"
psql -U "postgres" -d "clarity" -c "DELETE FROM public.\""$NAME"\" USING railways r WHERE ST_Intersects( public.\""$NAME"\".geom , r.geom );"
psql -U "postgres" -d "clarity" -c "DELETE FROM public.\""$NAME"\" USING trees t WHERE ST_Intersects( public.\""$NAME"\".geom , t.geom );"
psql -U "postgres" -d "clarity" -c "DELETE FROM public.\""$NAME"\" USING vegetation v WHERE ST_Intersects( public.\""$NAME"\".geom , v.geom );"
psql -U "postgres" -d "clarity" -c "DELETE FROM public.\""$NAME"\" USING agricultural_areas a WHERE ST_Intersects( public.\""$NAME"\".geom , a.geom );"

#drop not needed columns
echo "...Dropping not needed columns..."
psql -U "postgres" -d "clarity" -c "ALTER TABLE public.\""$NAME"\" DROP COLUMN cat;"
psql -U "postgres" -d "clarity" -c "ALTER TABLE public.\""$NAME"\" DROP COLUMN value;"
psql -U "postgres" -d "clarity" -c "ALTER TABLE public.\""$NAME"\" DROP COLUMN label;"

#add rest of the parameters to the layer
echo "...Adding rest of parameters..."
psql -U "postgres" -d "clarity" -c "ALTER TABLE public.\""$NAME"\" ADD albedo real DEFAULT "$ALBEDO";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE public.\""$NAME"\" ADD emissivity real DEFAULT "$EMISSIVITY";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE public.\""$NAME"\" ADD transmissivity real DEFAULT "$TRANSMISSIVITY";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE public.\""$NAME"\" ADD vegetation_shadow real DEFAULT "$VEGETATION_SHADOW";"
psql -U "postgres" -d "clarity" -c "ALTER TABLE public.\""$NAME"\" ADD run_off_coefficient real DEFAULT "$RUNOFF_COEFFICIENT";"

######ADD HEIGHT
HEIGHT_FILE="/home/mario.nunez/script/data/height/$CITY"_height".tif"
if [ -f $HEIGHT_FILE ];
then
######TO-DO
######https://github.com/perrygeo/python-rasterstats
echo "...Adding height data..."
fi

#building shadow 1 by default(not intersecting) then update with value 0 when intersecting
echo "...Adding building shadow..."
psql -U "postgres" -d "clarity" -c "ALTER TABLE public.\""$NAME"\" ADD building_shadow smallint DEFAULT 1;"
psql -U "postgres" -d "clarity" -c "UPDATE public.\""$NAME"\" x SET building_shadow=0 FROM "$DATA" l WHERE ST_Intersects( x.geom , l.geom ) IS TRUE;"

#Heat capacity, default 1 unless local data state otherwise (heavy_weight=0.9, medium_weight=1, light_weigth=1.1)
echo "...Adding heat capacity..."
psql -U "postgres" -d "clarity" -c "ALTER TABLE public.\""$NAME"\" ADD heat_capacity smallint DEFAULT 1;"

#Clusterization
echo "...Clusterizing..."
#psql -U "postgres" -d "clarity" -c "CLUSTER public.\""$NAME"\" USING public.\""$NAME"\"_pkey;"

#FALTA VOLCAR SOBRE TABLA ROADS GLOBAL Y BORRAR LA TABLA ROADS DEL SHAPEFILE ACTUAL(ITALIA-NAPOLES)
##psql -U "postgres" -d "clarity" -c "INSERT INTO buildings (SELECT NEXTVAL('buildings_gid_seq'), area, perimeter, geom, albedo, emissivity, transmissivity, vegetation_shadow, run_off_coefficient, building_shadow FROM public.\""$NAME"\");"
##psql -U "postgres" -d "clarity" -c "DROP TABLE public.\""$NAME"\";"
fi
