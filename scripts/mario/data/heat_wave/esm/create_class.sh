#!/bin/bash

#Pasar como parametro al comando el numero de la clase a extraer
CLASS=$(echo "$1")

#ESM folder
FOLDER="/home/mario.nunez/data/heat_waves/esm"

#PUT PATH TO FOLDER WITH ALL SMALL ZIPS
SOURCE=$FOLDER/european_settlement_map_geotiff

TARGET=$FOLDER/class_$CLASS
mkdir $TARGET

for ZIP in $SOURCE/*.zip;
do
  NAME=`echo $ZIP | rev | cut -f 1 -d '/' | rev | cut -f 1 -d '.' | rev | cut -f 1 -d '_' | rev`
  unzip -j $ZIP $NAME/class_$CLASS/"200km_10m_"$NAME"_class"$CLASS.TIF -d $TARGET
done

#create index
gdaltindex $TARGET/index_esm_class_$CLASS.shp $TARGET/*.TIF
gdalbuildvrt $TARGET/esm_class_$CLASS.vrt $TARGET/index_esm_class_$CLASS.shp

#permissions and ownership
chmod -R 755 $TARGET
chown -R mario.nunez:mario.nunez $TARGET

###Ahora puedes extraer partes de ese conjunto usando el recurso virtual
###gdal_translate -projwin ulx uly lrx lry inraster.tif outraster.tif
