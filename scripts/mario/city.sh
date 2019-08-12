#!/bin/bash
#UA_VERSION="UA2006"
#UA_VERSION_FILE="UA2006_Revised"
UA_VERSION="UA2012"
UA_VERSION_FILE="UA2012"
DATA="/home/mario.nunez/data"
TEMP_DATA="/home/mario.nunez/script/data"

#heat waves data sources
UA_FOLDER=$DATA"/heat_waves/"$UA_VERSION
STL_FOLDER=$DATA"/heat_waves/stl"
#HEIGHT_FOLDER=$DATA"/heat_waves/height/europe"
ESM30_FOLDER=$DATA"/heat_waves/esm/class_30"
ESM40_FOLDER=$DATA"/heat_waves/esm/class_40"
ESM50_FOLDER=$DATA"/heat_waves/esm/class_50"

#pluvial floods data sources
DEM_FOLDER=$DATA"/pluvial_floods/dem"
BASINS_FOLDER=$DATA"/pluvial_floods/basins"
STREAMS_FOLDER=$DATA"/pluvial_floods/streams"

#Create city table in postgresql if it does not exists
psql -U "postgres" -d "clarity" -c "SELECT to_regclass('public.city');" > city.out
FOUND=`sed "3q;d" city.out | cut -f 2 -d ' '`
#rm city.out
if [ "$FOUND" != 'city' ];
then
	echo "Creating table CITY..."
        psql -U "postgres" -d "clarity" -c "CREATE TABLE city( id SERIAL PRIMARY KEY, name VARCHAR(32), heat_wave BOOLEAN DEFAULT FALSE, pluvial_flood BOOLEAN DEFAULT FALSE, bbox GEOMETRY(Polygon,3035),boundary GEOMETRY(MULTIPOLYGON, 3035), code VARCHAR(7) );"
	psql -U "postgres" -d "clarity" -c "CREATE INDEX city_geom_idx ON city USING GIST(bbox);"
else
        echo "City table already exists!"
fi

for FILE in $UA_FOLDER/*.zip;
do
	CITY=`echo $FILE | cut -f 7 -d '/' | cut -f 1 -d '.' | cut -f 2-7 -d '_'`
	echo $CITY

	#check data sources for heat waves
	if [ -f $STL_FOLDER/*$CITY* ];
	then
		#UA extracting to get city BBOX
                mkdir $TEMP_DATA/ua
                ZIP=`ls $UA_FOLDER/*$CITY*`
                NAME=`echo $ZIP | cut -f 7 -d '/' | cut -f 1 -d '.' | cut -f 1-5 -d '_'`
		CODE=`echo $NAME | cut -f 1 -d '_'`
                unzip $ZIP -d $TEMP_DATA/ua
                #GET CITY BBOX FROM UA
                YMAX=`ogrinfo -ro -so -al $TEMP_DATA/ua/$NAME/Shapefiles/$NAME"_"$UA_VERSION_FILE".shp" | grep "Extent" | cut -f 2 -d ')' | cut -f 4 -d ' '`
                YMIN=`ogrinfo -ro -so -al $TEMP_DATA/ua/$NAME/Shapefiles/$NAME"_"$UA_VERSION_FILE".shp" | grep "Extent" | cut -f 1 -d ')' | cut -f 3 -d ' '`
                XMAX=`ogrinfo -ro -so -al $TEMP_DATA/ua/$NAME/Shapefiles/$NAME"_"$UA_VERSION_FILE".shp" | grep "Extent" | cut -f 3 -d '(' | cut -f 1 -d ','`
                XMIN=`ogrinfo -ro -so -al $TEMP_DATA/ua/$NAME/Shapefiles/$NAME"_"$UA_VERSION_FILE".shp" | grep "Extent" | cut -f 2 -d '(' | cut -f 1 -d ','`

		#UA boundary
		SHP_FILE=$TEMP_DATA/ua/$NAME/Shapefiles/$NAME"_"$UA_VERSION_FILE"_Boundary.shp"
		NAME=$(echo $CITY"_boundary" | awk '{print tolower($0)}')
		shp2pgsql -k -s 3035 -I -d $SHP_FILE $NAME > $NAME".sql"
		psql -d clarity -U postgres -f $NAME".sql"
		rm $NAME".sql"

		rm -r $TEMP_DATA/ua

                #LOAD CITY INTO DATABASE WITH ITS BBOX
                echo -e "\e[36m"$CITY "BBOX" $XMAX $YMAX $XMIN $YMIN"\e[0m"
                psql -U "postgres" -d "clarity" -c "SELECT EXISTS(SELECT * FROM city WHERE UPPER(name)=UPPER('"$CITY"'));" > city.out
                FOUND=`sed "3q;d" city.out | cut -f 2 -d ' '`
                rm city.out
                if [ $FOUND == 'f' ];
                then
                        #city is not in database, a new register is created for it with bbox, name and code
			echo $CITY "has been inserted in database!"
                        psql -U "postgres" -d "clarity" -c "INSERT INTO city (name, heat_wave, pluvial_flood, bbox, code) VALUES (UPPER('"$CITY"'), false, false, ST_MakeEnvelope("$XMIN","$YMIN","$XMAX","$YMAX",3035), '"$CODE"');"
			psql -U "postgres" -d "clarity" -c "UPDATE city SET boundary=sq.geom FROM (SELECT geom FROM "$NAME") as sq WHERE name='"$CITY"';"
			psql -U "postgres" -d "clarity" -c "DROP TABLE "$NAME";"
		else
			echo $CITY "already exists in database, skipping..."
                fi

	fi

done
echo "Cities checked."
