#!/bin/bash

RECIPE="/home/mario.nunez/script/templates/recipe.json"
ESM_DATA="/home/mario.nunez/data/esm"
TILE=""

for ZIP in $ESM_DATA/*.zip;
do
echo "ZIP: "$ZIP
	NAME=`echo $ZIP | cut -d '/' -f 6 | cut -d '.' -f 1`
echo "NAME: "$NAME
	TILE=`echo $NAME | cut -d '_' -f 5`
echo "TILE: "$TILE
	unzip $ZIP -d $ESM_DATA
	echo "Rasdaman importing tile" $TILE

	CADENA30=`sed s/"#COLLECTION#"/"ESM_class30"/g $RECIPE`
        CADENA40=`sed s/"#COLLECTION#"/"ESM_class40"/g $RECIPE`
       	CADENA50=`sed s/"#COLLECTION#"/"ESM_class50"/g $RECIPE`
	CADENA30=${CADENA30/"#TIF_PATH#"/"\""$ESM_DATA"/"$TILE"/class_30/200km_10m_"$TILE"_class30.TIF\""}
	CADENA40=${CADENA40/"#TIF_PATH#"/"\""$ESM_DATA"/"$TILE"/class_40/200km_10m_"$TILE"_class40.TIF\""}
	CADENA50=${CADENA50/"#TIF_PATH#"/"\""$ESM_DATA"/"$TILE"/class_50/200km_10m_"$TILE"_class50.TIF\""}
	echo $CADENA30 > "/home/mario.nunez/script/ingredient_"$TILE"_class30.json"
	echo $CADENA40 > "/home/mario.nunez/script/ingredient_"$TILE"_class40.json"
	echo $CADENA50 > "/home/mario.nunez/script/ingredient_"$TILE"_class50.json"

	echo "running import class_30"
	wcst_import.sh "/home/mario.nunez/script/ingredient_"$TILE"_class30.json" > "result_wcst_esm_"$TILE"_class30.xml"
	wait
	echo "running import class_40"
	wcst_import.sh "/home/mario.nunez/script/ingredient_"$TILE"_class40.json" > "result_wcst_esm_"$TILE"_class40.xml"
	wait
	echo "running import class_50"
	wcst_import.sh "/home/mario.nunez/script/ingredient_"$TILE"_class50.json" > "result_wcst_esm_"$TILE"_class50.xml"
	wait

	rm "/home/mario.nunez/script/ESM_class30.resume.json"
	rm "/home/mario.nunez/script/ESM_class40.resume.json"
	rm "/home/mario.nunez/script/ESM_class50.resume.json"
	rm "/home/mario.nunez/script/ingredient_"$TILE"_class30.json"
	rm "/home/mario.nunez/script/ingredient_"$TILE"_class40.json"
	rm "/home/mario.nunez/script/ingredient_"$TILE"_class50.json"
	rm -r $ESM_DATA/$TILE
done
rm *.xml
rm *.log
echo "SCRIPT END"
