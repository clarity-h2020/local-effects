#!/bin/bash

RECIPE="/home/mario.nunez/script/templates/recipe.json"
DATA="/home/mario.nunez/data/height/europe"
TIF=""

for ZIP in $DATA/*.zip;
do
	NAME=`echo $ZIP | cut -d '/' -f 6 | cut -d '.' -f 1`
	unzip $ZIP -d $DATA

	for FOLDER in $DATA;
	do
		if [[ -d $FOLDER ]];
		then
			sudo chmod -R 755 $FOLDER
			TIF=$DATA/$FOLDER/$FOLDER.tif

			CADENA=`sed s/"#COLLECTION#"/"EU_BUILDING_HEIGHT"/g $RECIPE`
			CADENA=${CADENA/"#TIF_PATH#"/$TIF}
			echo $CADENA > "/home/mario.nunez/script/ingredient_"$FOLDER".json"

			echo "Rasdaman import" $TIF
			wcst_import.sh "/home/mario.nunez/script/ingredient_"$FOLDER".json" > "result_wcst_esm_"$FOLDER".xml"

			rm "/home/mario.nunez/script/ingredient_"$FOLDER".json"
			rm -r $DATA/$FOLDER
		fi
	done
rm *.xml
rm *.log
done
