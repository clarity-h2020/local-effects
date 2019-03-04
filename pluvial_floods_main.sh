#!/bin/bash
#INDEX="/home/mario.nunez/script/parameters/pluvial_floods_layers.dat"

DATA="/home/mario.nunez/script/data"
DEM_FOLDER="/home/mario.nunez/data/pluvial_floods/dem"
BASINS_FOLDER="/home/mario.nunez/data/pluvial_floods/basins"
STREAMS_FOLDER="/home/mario.nunez/data/pluvial_floods/streams"

CITY=$(echo "$1" | awk '{print toupper($0)}')
if [ -f $UA_FOLDER/*$CITY* ] && [ -f $STL_FOLDER/*$CITY* ] && [ -f $HEIGHT_FOLDER/*$CITY* ];
then
	echo "Gathering input data sources..."

	#get city bounding box
	MINX=`gdalinfo /home/mario.nunez/data/heat_waves/height/europe/*MADRID* | grep "Upper Left" | cut -f 5 -d ' ' | cut -f 1 -d '.'`
	MAXX=`gdalinfo /home/mario.nunez/data/heat_waves/height/europe/*MADRID* | grep "Upper Right" | cut -f 4 -d ' ' | cut -f 1 -d '.'`
	MINY=`gdalinfo /home/mario.nunez/data/heat_waves/height/europe/*MADRID* | grep "Lower Left" | cut -f 6 -d ' ' | cut -f 1 -d '.'`
	MAXY=`gdalinfo /home/mario.nunez/data/heat_waves/height/europe/*MADRID* | grep "Upper Right" | cut -f 5 -d ' ' | cut -f 1 -d '.'`
	echo $CITY "BBOX" $MAXX $MAXY $MINX $MINY

	#create city folder
	mkdir $DATA/$CITY
	DATA=$DATA/$CITY

	#DEM
	echo "Generating Digital Elevation Model map..."
	mkdir $DATA/esm
	gdal_translate -projwin $MINX $MAXY $MAXX $MINY $DEM_FOLDER/eu_dem.vrt $DATA/esm/dem_$CITY.tif
	gdal_translate -projwin $MINX $MAXY $MAXX $MINY $DEM_FOLDER/eu_dem.vrt $DATA/esm/dem_$CITY.tif
	gdal_translate -projwin $MINX $MAXY $MAXX $MINY $DEM_FOLDER/eu_dem.vrt $DATA/esm/dem_$CITY.tif

	#GENERATE 3 LAYERS
#run each script in corresponding order
#while read -r LINE;
#do
#       LAYER=echo $LINE | cut -f 2 -d ' '
#       source $LAYER.sh
#       wait
#done < "$INDEX"

	#delete city data
	#rm -r $DATA
else
	echo "Data sources missing for "$CITY
	echo "Unable to generate input layers for local effects."
fi
echo "Generation completed for "$CITY
