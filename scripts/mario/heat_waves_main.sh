#!/bin/bash
#INDEX="/home/mario.nunez/script/parameters/heat_wave_layers.dat"
#UA_VERSION="UA2006"
#UA_VERSION_FILE="UA2006_Revised"
UA_VERSION="UA2012"
UA_VERSION_FILE="UA2012"

DATA="/home/mario.nunez/script/data"
UA_FOLDER="/home/mario.nunez/data/heat_waves/"$UA_VERSION
STL_FOLDER="/home/mario.nunez/data/heat_waves/stl"
ESM20_FOLDER="/home/mario.nunez/data/heat_waves/esm/class_20"
ESM30_FOLDER="/home/mario.nunez/data/heat_waves/esm/class_30"
ESM40_FOLDER="/home/mario.nunez/data/heat_waves/esm/class_40"
ESM50_FOLDER="/home/mario.nunez/data/heat_waves/esm/class_50"

#falta despues de agricultural_areas poner BUILT_UP
LAYERS=("water" "roads" "railways" "trees" "vegetation" "agricultural_areas" "built_open_spaces" "sports" "dense_urban_fabric" "medium_urban_fabric" "low_urban_fabric" "public_military_industrial")

if [[ $# -eq 0 ]] ; then
    echo -e "\e[33mERROR: No city name provided!\e[0m"
    exit 1
fi
CITY=$(echo "$1" | awk '{print toupper($0)}')
if [ -f $UA_FOLDER/*$CITY* ] && [ -f $STL_FOLDER/*$CITY* ];
#&& [ -f $HEIGHT_FOLDER/*$CITY* ];
then
	echo -e "\e[36mIt seems like" $CITY "is an available city in the file system, gathering data...\e[0m"

	#checking provided city heat wave is already loaded in database
        psql -U "postgres" -d "clarity" -c "SELECT id FROM city WHERE pluvial_flood is null AND UPPER(name)=UPPER('"$CITY"');" > city.out
        ID=`sed "3q;d" city.out | sed -e 's/^[ \t]*//'`
        rm city.out

        if [[ $ID =~ "(0 rows)" ]];
        then
		echo -e "\e[33mERROR: "$CITY" heat wave data already loaded into the database!\e[0m"
		echo -e "\e[33mTry setting up heat_wave "$CITY" attribute to NULL\e[0m"
        else
		echo ""
	        echo -e "\e[36m"$CITY" database ID is "$ID
        	START=$(date '+%Y-%m-%d %H:%M:%S')
        	echo "Starting at:" $START
        	echo -e "\e[0m"

		#create city folder
		mkdir $DATA/$CITY
		DATA=$DATA/$CITY

		#UA
		echo -e "\e[36mLoading heat wave Urban Atlas "$CITY" data...\e[0m"
	        mkdir $DATA/ua
	        ZIP=`ls $UA_FOLDER/*$CITY*`
	        NAME=`echo $ZIP | cut -f 7 -d '/' | cut -f 1 -d '.' | cut -f 1-5 -d '_'`
		CODE=`echo $NAME | cut -f 1 -d '_'`
	        unzip $ZIP -d $DATA/ua
	        cp $DATA/ua/$NAME/Shapefiles/$NAME"_"$UA_VERSION_FILE".shp" $DATA/ua/
	        cp $DATA/ua/$NAME/Shapefiles/$NAME"_"$UA_VERSION_FILE".shx" $DATA/ua/
	        cp $DATA/ua/$NAME/Shapefiles/$NAME"_"$UA_VERSION_FILE".dbf" $DATA/ua/
	        cp $DATA/ua/$NAME/Shapefiles/$NAME"_"$UA_VERSION_FILE".prj" $DATA/ua/
		#boundary
		mkdir $DATA/ua/boundary
		cp $DATA/ua/$NAME/Shapefiles/$NAME"_"$UA_VERSION_FILE"_Boundary.shp" $DATA/ua/boundary/$CITY"_boundary.shp"
		cp $DATA/ua/$NAME/Shapefiles/$NAME"_"$UA_VERSION_FILE"_Boundary.shx" $DATA/ua/boundary/$CITY"_boundary.shx"
		cp $DATA/ua/$NAME/Shapefiles/$NAME"_"$UA_VERSION_FILE"_Boundary.dbf" $DATA/ua/boundary/$CITY"_boundary.dbf"
		cp $DATA/ua/$NAME/Shapefiles/$NAME"_"$UA_VERSION_FILE"_Boundary.prj" $DATA/ua/boundary/$CITY"_boundary.prj"
		rm -r $DATA/ua/$NAME

		#GET CITY BBOX FROM UA
		MAXY=`ogrinfo -ro -so -al $DATA/ua/$NAME"_"$UA_VERSION_FILE".shp" | grep "Extent" | cut -f 2 -d ')' | cut -f 4 -d ' '`
		MINY=`ogrinfo -ro -so -al $DATA/ua/$NAME"_"$UA_VERSION_FILE".shp" | grep "Extent" | cut -f 1 -d ')' | cut -f 3 -d ' '`
		MAXX=`ogrinfo -ro -so -al $DATA/ua/$NAME"_"$UA_VERSION_FILE".shp" | grep "Extent" | cut -f 3 -d '(' | cut -f 1 -d ','`
		MINX=`ogrinfo -ro -so -al $DATA/ua/$NAME"_"$UA_VERSION_FILE".shp" | grep "Extent" | cut -f 2 -d '(' | cut -f 1 -d ','`

		#ESM
		echo -e "\e[36mGenerating and clipping European Setlement Map data...\e[0m"
		mkdir $DATA/esm
		#Extracting bbox from VRT SHP indexing all raster ESM files
		gdal_translate -projwin $MINX $MAXY $MAXX $MINY $ESM20_FOLDER/esm_class_20.vrt $DATA/esm/class20_$CITY.tif
		gdal_translate -projwin $MINX $MAXY $MAXX $MINY $ESM30_FOLDER/esm_class_30.vrt $DATA/esm/class30_$CITY.tif
		gdal_translate -projwin $MINX $MAXY $MAXX $MINY $ESM40_FOLDER/esm_class_40.vrt $DATA/esm/class40_$CITY.tif
		###BUILDINGS#gdal_translate -projwin $MINX $MAXY $MAXX $MINY $ESM50_FOLDER/esm_class_50.vrt $DATA/esm/class50_$CITY.tif

		#STL
		echo -e "\e[36mGenerating Street Tree Layer data...\e[0m"
		mkdir $DATA/stl
		#locate and unzip STL city data
		ZIP=`ls $STL_FOLDER/*$CITY*`
	        NAME=`echo $ZIP | cut -f 7 -d '/' | cut -f 1 -d '.' | cut -f 1-5 -d '_'`
	        unzip $ZIP -d $DATA/stl
		#copying STL city SHP file
	        cp $DATA/stl/$NAME/Shapefiles/$NAME"_UA2012_STL.shp" $DATA/stl/
		cp $DATA/stl/$NAME/Shapefiles/$NAME"_UA2012_STL.dbf" $DATA/stl/
		cp $DATA/stl/$NAME/Shapefiles/$NAME"_UA2012_STL.shx" $DATA/stl/
		cp $DATA/stl/$NAME/Shapefiles/$NAME"_UA2012_STL.prj" $DATA/stl/
	        rm -r $DATA/stl/$NAME

		#store logs
		mkdir -p ./output/$CITY/layers

		echo -e "\e[36mGenerating auxiliar layers 9-12...\e[0m"
		#GENERATE LAYERS 9-12 TOGETHER
		source layers9_12.sh $CITY > output/$CITY/layers/layers9_12.out 2>&1
		wait

		#insert records with cell references for current city boundary (not bbox)
		echo -e "\e[36mGenerating land use registers...\e[0m"
		psql -U "postgres" -d "clarity" -c "INSERT INTO land_use_grid(cell,city) SELECT g.gid,c.id FROM laea_etrs_500m g, city c WHERE ST_Intersects(g.geom,c.boundary) AND c.name='"$CITY"';"

		#SET CITY SIZE (IN CELL NUMBER)
		psql -U "postgres" -d "clarity" -c "UPDATE city SET size=(SELECT COUNT(*) FROM laea_etrs_500m g, city c WHERE c.id="$ID" and ST_Intersects(g.geom,c.boundary)) WHERE id="$ID";"

		#GENERATE 12 LAYERS
		#run each script in corresponding order
		echo -e "\e[36mInput layer generation...\e[0m"
		for LAYER in "${LAYERS[@]}";
		do
			echo -e "\e[7m..."$LAYER"...\e[27m"
		        source $LAYER.sh > output/$CITY/layers/$LAYER.out 2>&1
		        wait
		done

		#once import finished then delete all city layers from database
		for LAYER in "${LAYERS[@]}";
                do
			echo -e "\e[36mDeleting "$LAYER" auxuliar table...\e[0m"
			psql -U "postgres" -d "clarity" -c "DROP TABLE IF EXISTS "$CITY"_"$LAYER"_grid CASCADE;"
			psql -U "postgres" -d "clarity" -c "DROP SEQUENCE IF EXISTS "$CITY"_"$LAYER"_grid_seq CASCADE;"
			psql -U "postgres" -d "clarity" -c "DROP TABLE IF EXISTS "$CITY"_"$LAYER" CASCADE;"
                        psql -U "postgres" -d "clarity" -c "DROP SEQUENCE IF EXISTS "$CITY"_"$LAYER"_seq CASCADE;"
                done

		#once import finished then delete layers9_12 from database (HOW TO CHECK IF REGION IS ALREADY LOADED IN THE SYSTEM?)
		echo -e "\e[36mDeleting auxiliar layer 9-12...\e[0m"
		psql -U "postgres" -d "clarity" -c "DROP TABLE "$CITY"_layers9_12;"

		#generate land use percentages per city cell
		echo -e "\e[36mGenerating land use from heat wave data...\e[0m"
                for TYPE in "${LAYERS[@]}";
                do
			echo -e "\e[36m...generating" $TYPE "percentages...\e[0m"
        	        psql -U "postgres" -d "clarity" -c "update land_use_grid set "$TYPE"=sq.percentage from (select l.cell as cell,st_area(w.geom)/st_area(g.geom) as percentage from "$TYPE" w, land_use_grid l, laea_etrs_500m g where w.cell=l.cell AND l.cell=g.gid AND l.city="$ID") as sq where sq.cell=land_use_grid.cell;"
		done

		#ASSIGNMENT OF HILLSHADE_BUILDING VALUES TO LAYERS (roads,railways,vegetation,agricultura_areas,built_open_spaces)
		LAYERS=("roads" "railways" "vegetation" "agricultural_areas" "built_open_spaces")
		#CALCULATE BUILT AREAS PERCENTAGE IN A CELL IS THE SUM PERCENTAGES OF LAND USE OF (sports,dense_urban_fabric,medium_urban_fabric,low_urban_fabric,public_military_industrial)
		#DETERMINE WHICH RANGE CORRESPONDS WITH CALCULATED BUILT AREAS PERCENTAGE AND APPLY CORRSPONDING HILLSHADE_BUILDING VALUE:
		#VERY_LOW=0.1 --> assign 0.6
		#LOW=0.25 --> assign 0.8
		#MEDIUM=0.6 --> assign 0.9
		#HIGH=1 --> assign 1

		#BUILT DENSITY CALCULATION
		echo -e "\e[36m...generating built_density...\e[0m"
		psql -U "postgres" -d "clarity" -c "UPDATE land_use_grid SET built_density=sq.built_density FROM (SELECT cell,sports+built_open_spaces+dense_urban_fabric+medium_urban_fabric+low_urban_fabric+public_military_industrial as built_density FROM land_use_grid WHERE city="$ID" ) as sq WHERE land_use_grid.cell=sq.cell;"

		#ASSIGN HILLSHADE_BUILDING
		for LAYER in "${LAYERS[@]}";
		do
        		echo -e "\e[36m...assigning hillshade building for" $LAYER"...\e[0m"
        		psql -U "postgres" -d "clarity" -c "UPDATE "$LAYER" SET hillshade_building=sq.hillshade_building FROM (SELECT cell, CASE WHEN built_density<0 THEN NULL WHEN built_density<=0.1 THEN 1 WHEN built_density<=0.25 THEN 0.9 WHEN built_density<=0.6 THEN 0.8 WHEN built_density<=1 THEN 0.6 ELSE NULL END AS hillshade_building FROM land_use_grid WHERE city="$ID") AS sq WHERE \""$LAYER"\".city="$ID" AND \""$LAYER"\".cell=sq.cell;"
		done

		echo ""
                END=$(date '+%Y-%m-%d %H:%M:%S')
                echo -e "\e[36mEnding at:" $END
                echo -e "\e[0m"
		echo -e "\e[36mGeneration completed for "$CITY"\e[0m"
		TIME=`date -u -d @$(($(date -d "$END" '+%s') - $(date -d "$START" '+%s'))) '+%T'`
                psql -U "postgres" -d "clarity" -c "UPDATE city SET heat_wave='"$TIME"' WHERE ID="$ID";"
	fi
else
	echo -e "\e[33mData sources missing for "$CITY"\e[0m"
	echo -e "\e[33mUnable to generate input layers for outdoor heat waves local effects.\e[0m"
fi
