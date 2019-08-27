#!/bin/bash
#INDEX="/home/mario.nunez/script/parameters/heat_wave_layers.dat"
#UA_VERSION="UA2006"
#UA_VERSION_FILE="UA2006_Revised"
UA_VERSION="UA2012"
UA_VERSION_FILE="UA2012"

DATA="/home/mario.nunez/script/data"
UA_FOLDER="/home/mario.nunez/data/heat_waves/"$UA_VERSION
STL_FOLDER="/home/mario.nunez/data/heat_waves/stl"
#HEIGHT_FOLDER="/home/mario.nunez/data/heat_waves/height/europe"
ESM30_FOLDER="/home/mario.nunez/data/heat_waves/esm/class_30"
ESM40_FOLDER="/home/mario.nunez/data/heat_waves/esm/class_40"
ESM50_FOLDER="/home/mario.nunez/data/heat_waves/esm/class_50"

LAYERS=("water" "roads" "railways" "trees" "vegetation" "agricultural_areas" "built_up" "built_open_spaces" "dense_urban_fabric" "medium_urban_fabric" "low_urban_fabric" "public_military_industrial")

if [[ $# -eq 0 ]] ; then
    echo -e "\e[33mERROR: No city name provided!\e[0m"
    exit 1
fi
CITY=$(echo "$1" | awk '{print toupper($0)}')
if [ -f $UA_FOLDER/*$CITY* ] && [ -f $STL_FOLDER/*$CITY* ];
#&& [ -f $HEIGHT_FOLDER/*$CITY* ];
then
	echo -e "\e[36mIt seems like" $CITY "is an available city in the file system, gathering data...\e[0m"

	#Inserting cell references from european grid corresponding to the city bbox
        psql -U "postgres" -d "clarity" -c "INSERT INTO land_use_grid(cell,city) (SELECT g.gid,c.id FROM laea_etrs_500m g, city c WHERE ST_Intersects(g.geom,c.boundary) AND c.name='"$CITY"');"

	#checking provided city heat wave is already loaded in database
        psql -U "postgres" -d "clarity" -c "SELECT heat_wave FROM city WHERE UPPER(name)=UPPER('"$CITY"');" > city.out
        FOUND=`sed "3q;d" city.out | cut -f 2 -d ' '`
        rm city.out
	if [ $FOUND == 't' ];
        then
		echo -e "\e[33mERROR: "$CITY" heat wave data already loaded into the database!\e[0m"
		echo -e "\e[33mTry setting up heat_wave "$CITY" attribute to false\e[0m"
        else
                echo -e "\e[36mLoading heat wave "$CITY" data...\e[0m"

		#create city folder
		mkdir $DATA/$CITY
		DATA=$DATA/$CITY

		#UA
	        echo -e "\e[36mGenerating Urban Atlas data...\e[0m"
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
		gdal_translate -projwin $MINX $MAXY $MAXX $MINY $ESM30_FOLDER/esm_class_30.vrt $DATA/esm/class30_$CITY.tif
		gdal_translate -projwin $MINX $MAXY $MAXX $MINY $ESM40_FOLDER/esm_class_40.vrt $DATA/esm/class40_$CITY.tif
		gdal_translate -projwin $MINX $MAXY $MAXX $MINY $ESM50_FOLDER/esm_class_50.vrt $DATA/esm/class50_$CITY.tif

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

		#HEIGHT (SOLO INDOOR)
#		if [ -f $HEIGHT_FOLDER/*$CITY* ];
#		then
#			echo -e "\e[36mGenerating height data...\e[0m"
#			mkdir $DATA/height
#			TIF=`ls $HEIGHT_FOLDER/*$CITY*`
#			NAME=`echo $TIF | cut -f 7 -d '/' | cut -f 1 -d '.' | cut -f 1,2 -d '_'`
#			echo $NAME
#			cp $TIF $DATA/height/$CITY"_height".tif
#		fi

		echo -e "\e[36mGeneratingauxiliar layers 9-12...\e[0m"
		#GENERATE LAYERS 9-12 TOGETHER
		source layers9_12.sh $CITY
		wait

		#REGISTER THAT NEEDED DATA IS PREPARED FOR THE CITY
		echo -e "\e[36mRegisteing data generation...\e[0m"
		psql -U "postgres" -d "clarity" -c "UPDATE CITY SET heat_wave=TRUE WHERE NAME='"$CITY"';"

		#GENERATE 12 LAYERS
		#run each script in corresponding order
		echo -e "\e[36mInput layer generation...\e[0m"
		for LAYER in "${LAYERS[@]}";
		do
			echo -e "\e[7minverted..."$LAYER"...\e[27mNormal"
		        source $LAYER.sh > $LAYER.out
		        wait
		done

		#once import finished then delete all city layers from database
		for LAYER in "${LAYERS[@]}";
                do
			echo -e "\e[36mDeleting "$LAYER" auxuliar table...\e[0m"
			psql -U "postgres" -d "clarity" -c "DROP TABLE IF EXISTS "$CITY"_"$LAYER"_grid;"
			psql -U "postgres" -d "clarity" -c "DROP SEQUENCE IF EXISTS "$CITY"_"$LAYER"_grid_seq;"
			psql -U "postgres" -d "clarity" -c "DROP TABLE IF EXISTS "$CITY"_"$LAYER";"
                        psql -U "postgres" -d "clarity" -c "DROP SEQUENCE IF EXISTS "$CITY"_"$LAYER"_seq;"
                done

		#once import finished then delete layers9_12 from database (HOW TO CHECK IF REGION IS ALREADY LOADED IN THE SYSTEM?)
		echo -e "\e[36mDeleting auxiliar layer 9-12...\e[0m"
		psql -U "postgres" -d "clarity" -c "DROP TABLE "$CITY"_layers9_12;"

		#delete city data
		echo -e "\e[36mDeleting file sytem source data...\e[0m"
		rm -r $DATA

		echo -e "\e[36mGeneration completed for "$CITY"\e[0m"
	fi
else
	echo -e "\e[33mData sources missing for "$CITY"\e[0m"
	echo -e "\e[33mUnable to generate input layers for outdoor heat waves local effects.\e[0m"
fi
