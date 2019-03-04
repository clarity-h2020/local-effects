#!/bin/bash
#INDEX="/home/mario.nunez/script/parameters/heat_wave_layers.dat"

DATA="/home/mario.nunez/script/data"
UA_FOLDER="/home/mario.nunez/data/heat_waves/ua"
STL_FOLDER="/home/mario.nunez/data/heat_waves/stl"
HEIGHT_FOLDER="/home/mario.nunez/data/heat_waves/height/europe"
ESM30_FOLDER="/home/mario.nunez/data/heat_waves/esm/class_30"
ESM40_FOLDER="/home/mario.nunez/data/heat_waves/esm/class_40"
ESM50_FOLDER="/home/mario.nunez/data/heat_waves/esm/class_50"

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

	#ESM
	echo "Generating European Setlement Map data..."
	mkdir $DATA/esm
	gdal_translate -projwin $MINX $MAXY $MAXX $MINY $ESM30_FOLDER/esm_class_30.vrt $DATA/esm/class30_$CITY.tif
	gdal_translate -projwin $MINX $MAXY $MAXX $MINY $ESM40_FOLDER/esm_class_40.vrt $DATA/esm/class40_$CITY.tif
	gdal_translate -projwin $MINX $MAXY $MAXX $MINY $ESM50_FOLDER/esm_class_50.vrt $DATA/esm/class50_$CITY.tif

	#UA
	echo "Generating Urban Atlas data..."
	mkdir $DATA/ua
	ZIP=`ls $UA_FOLDER/*$CITY*`
	NAME=`echo $ZIP | cut -f 7 -d '/' | cut -f 1 -d '.' | cut -f 1,2 -d '_'`
	unzip $ZIP -d $DATA/ua
	cp $DATA/ua/$NAME/Shapefiles/$NAME"_UA2012.shp" $DATA/ua/
	cp $DATA/ua/$NAME/Shapefiles/$NAME"_UA2012.shx" $DATA/ua/
	cp $DATA/ua/$NAME/Shapefiles/$NAME"_UA2012.dbf" $DATA/ua/
	cp $DATA/ua/$NAME/Shapefiles/$NAME"_UA2012.prj" $DATA/ua/
	cp $DATA/ua/$NAME/Shapefiles/$NAME"_UA2012.qpj" $DATA/ua/
	rm -r $DATA/ua/$NAME

	#STL
	echo "Generating Street Tree Layer data..."
	mkdir $DATA/stl
	ZIP=`ls $STL_FOLDER/*$CITY*`
        NAME=`echo $ZIP | cut -f 7 -d '/' | cut -f 1 -d '.' | cut -f 1,2 -d '_'`
        unzip $ZIP -d $DATA/stl
        cp $DATA/stl/$NAME/Shapefiles/$NAME"_UA2012_STL.shp" $DATA/stl/
	cp $DATA/stl/$NAME/Shapefiles/$NAME"_UA2012_STL.dbf" $DATA/stl/
	cp $DATA/stl/$NAME/Shapefiles/$NAME"_UA2012_STL.shx" $DATA/stl/
	cp $DATA/stl/$NAME/Shapefiles/$NAME"_UA2012_STL.prj" $DATA/stl/
	cp $DATA/stl/$NAME/Shapefiles/$NAME"_UA2012_STL.qpj" $DATA/stl/
        rm -r $DATA/stl/$NAME

	#HEIGHT
	echo "Generating height data..."
	mkdir $DATA/height
	TIF=`ls $HEIGHT_FOLDER/*$CITY*`
	NAME=`echo $TIF | cut -f 7 -d '/' | cut -f 1 -d '.' | cut -f 1,2 -d '_'`
	echo $NAME
	cp $TIF $DATA/height/$CITY"_height".tif

	echo "Generating input layers..."
	#GENERATE LAYERS 9-12 TOGETHER
	source layers9_12.sh
	wait

	#GENERATE 12 LAYERS
#run each script in corresponding order
#while read -r LINE;
#do
#       LAYER=echo $LINE | cut -f 2 -d ' '
#       source $LAYER.sh > $LAYER.out
#       wait
#done < "$INDEX"

#put current region water data on global water table and delete current region water table
#psql -U "postgres" -d "clarity" -c "INSERT INTO water(SELECT NEXTVAL('water_gid_seq'), area, perimeter, code2012, geom, albedo, emissivity, transmissivity, vegetation_shadow, run_off_coedfficient, building_shadow FROM "$NAME"_water);"
#psql -U "postgres" -d "clarity" -c "DROP TABLE "$CITY"_water;"
#TODO: rest of the layers migrations...

#once import finished then delete layers9_12 from database (HOW TO CHECK IF REGION IS ALREADY LOADED IN THE SYSTEM?)
#psql -U "postgres" -d "clarity" -c "DROP TABLE "$CITY"_layers9_12;"


	#delete city data
	#rm -r $DATA
else
	echo "Data sources missing for "$CITY
	echo "Unable to generate input layers for local effects."
fi
echo "Generation completed for "$CITY
