#!/bin/bash

RECIPE="/home/mario.nunez/script/templates/recipe.json"
DATA="/home/mario.nunez/data/height/europe"
TIF=""
FOLDER=""

for ZIP in $DATA/*.zip;
do
	NAME=`echo $ZIP | cut -d '/' -f 7 | cut -d '.' -f 1`
	unzip $ZIP -d $DATA
	FOLDER=$NAME"_UA2012_DHM"
	TIF=$DATA/$FOLDER/$FOLDER.tif

	CADENA=`sed s/"#COLLECTION#"/"EU_BUILDING_HEIGHT"/g $RECIPE`
	CADENA=${CADENA/"#TIF_PATH#"/"\""$TIF"\""}
	echo $CADENA > "/home/mario.nunez/script/ingredient_"$NAME".json"

	echo "Rasdaman import" $TIF
	wcst_import.sh "/home/mario.nunez/script/ingredient_"$NAME".json" > "result_wcst_esm_"$NAME".xml"
	wait

	rm "/home/mario.nunez/script/ingredient_"$NAME".json"
	rm -r $DATA/$FOLDER

	rm *.xml
	rm *.log
done
echo "SCRIPT END"
