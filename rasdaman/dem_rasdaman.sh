#!/bin/bash

RECIPE="/home/mario.nunez/script/templates/recipe.json"
DEM_DATA="/home/mario.nunez/data/eu_dem"
TIF=""

for FILE in $DEM_DATA/*.TIF;
do
	CADENA=`sed s/"#COLLECTION#"/"EU_DEM"/g $RECIPE`
	TIF=`echo $FILE | cut -d '/' -f 6 | cut -d '.' -f 1`
	echo "Importing raster file:" $TIF
	CADENA=${CADENA/"#TIF_PATH#"/"\""$FILE"\""}
	echo $CADENA > "/home/mario.nunez/script/ingredient_DEM_"$TIF".json"
	wcst_import.sh "/home/mario.nunez/script/ingredient_DEM_"$TIF".json" > "result_wcst_DEM_"$TIF".xml"
	wait
	rm "/home/mario.nunez/script/ingredient_DEM_"$TIF".json"
done
rm *.xml
rm *.log
echo "SCRIPT END"
