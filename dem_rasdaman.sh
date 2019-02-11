#!/bin/bash

RECIPE="/home/mario.nunez/script/templates/recipe.json"
DEM_DATA="/home/mario.nunez/data/eu_dem"
TIF=""

CADENA=`sed s/"#COLLECTION#"/"EU_DEM"/g $RECIPE`
for FILE in $DEM_DATA/*.TIF;
do
	TIF=$DEM_DATA/$FILE
	CADENA=${CADENA/"#TIF_PATH#"/$TIF}
	echo "adding raster file:" $TIF
done
echo $CADENA > "/home/mario.nunez/script/ingredient_"$FILE".json"
echo "Starting Rasdaman import"
wcst_import.sh "/home/mario.nunez/script/ingredient_"$FILE".json" > "result_wcst_DEM_"$FILE".xml"
rm "/home/mario.nunez/script/ingredient_"$FILE".json"
rm *.xml
rm *.log
echo "IMPORT END"
