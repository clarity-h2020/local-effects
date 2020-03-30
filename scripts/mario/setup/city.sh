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
#ESM being a raster, there is always data for a given city

#Create city table in postgresql if it does not exists
psql -U "postgres" -d "clarity" -c "SELECT to_regclass('public.city');" > city.out
FOUND=`sed "3q;d" city.out | cut -f 2 -d ' '`
rm city.out
if [ "$FOUND" != 'city' ];
then
	echo "Creating table CITY..."
#	psql -U "postgres" -d "clarity" -c "CREATE TABLE city( id SERIAL PRIMARY KEY, name VARCHAR(32), heat_wave BOOLEAN DEFAULT FALSE, pluvial_flood BOOLEAN DEFAULT FALSE,boundary GEOMETRY(MULTIPOLYGON, 3035), code VARCHAR(5), hh_mm_ss time without time zone );"
psql -U "postgres" -d "clarity" -c "CREATE TABLE city( id SERIAL PRIMARY KEY, name VARCHAR(32), heat_wave time without time zone, pluvial_flood time without time zone, total interval, size integer, boundary GEOMETRY(MULTIPOLYGON, 3035), code VARCHAR(5) );"
	psql -U "postgres" -d "clarity" -c "CREATE INDEX city_geom_idx ON city USING GIST(bbox);"
else
        echo "City table already exists!"
fi

for FILE in $UA_FOLDER/*.zip;
do
	CITY=`echo $FILE | cut -f 7 -d '/' | cut -f 1 -d '.' | cut -f 2-7 -d '_'`
	echo $CITY

	#check STL data source availability for each city (heat waves)
	if [ -f $STL_FOLDER/*$CITY* ];
	then
		#UA extracting to get city files
                mkdir $TEMP_DATA/ua
                ZIP=`ls $UA_FOLDER/*$CITY*`
                NAME=`echo $ZIP | cut -f 7 -d '/' | cut -f 1 -d '.' | cut -f 1-5 -d '_'`
		CODE=`echo $NAME | cut -f 1 -d '_'`
                unzip $ZIP -d $TEMP_DATA/ua
                #GET CITY BBOX FROM UA
#                YMAX=`ogrinfo -ro -so -al $TEMP_DATA/ua/$NAME/Shapefiles/$NAME"_"$UA_VERSION_FILE".shp" | grep "Extent" | cut -f 2 -d ')' | cut -f 4 -d ' '`
#                YMIN=`ogrinfo -ro -so -al $TEMP_DATA/ua/$NAME/Shapefiles/$NAME"_"$UA_VERSION_FILE".shp" | grep "Extent" | cut -f 1 -d ')' | cut -f 3 -d ' '`
#                XMAX=`ogrinfo -ro -so -al $TEMP_DATA/ua/$NAME/Shapefiles/$NAME"_"$UA_VERSION_FILE".shp" | grep "Extent" | cut -f 3 -d '(' | cut -f 1 -d ','`
#                XMIN=`ogrinfo -ro -so -al $TEMP_DATA/ua/$NAME/Shapefiles/$NAME"_"$UA_VERSION_FILE".shp" | grep "Extent" | cut -f 2 -d '(' | cut -f 1 -d ','`

		#UA boundary
		SHP_FILE=$TEMP_DATA/ua/$NAME/Shapefiles/$NAME"_"$UA_VERSION_FILE"_Boundary.shp"
		NAME=$(echo $CITY"_boundary" | awk '{print tolower($0)}')
		shp2pgsql -k -s 3035 -I -d $SHP_FILE $NAME > $NAME".sql"
		psql -d clarity -U postgres -f $NAME".sql"
		rm $NAME".sql"

		rm -r $TEMP_DATA/ua

                #LOAD CITY INTO DATABASE WITH ITS GEOMETRY
#                echo -e "\e[36m"$CITY "BBOX" $XMAX $YMAX $XMIN $YMIN"\e[0m"
		echo -e "\e[36m"$CITY"\e[0m"
                psql -U "postgres" -d "clarity" -c "SELECT EXISTS(SELECT * FROM city WHERE UPPER(name)=UPPER('"$CITY"'));" > city.out
                FOUND=`sed "3q;d" city.out | cut -f 2 -d ' '`
                rm city.out
                if [ $FOUND == 'f' ];
                then
                        #city is not in database, a new register is created for it
			echo $CITY "has been inserted in database!"
#                       psql -U "postgres" -d "clarity" -c "INSERT INTO city (name, heat_wave, pluvial_flood, bbox, code) VALUES (UPPER('"$CITY"'), false, false, ST_MakeEnvelope("$XMIN","$YMIN","$XMAX","$YMAX",3035), substring(1,5,'"$CODE"') );"
			psql -U "postgres" -d "clarity" -c "INSERT INTO city (name, heat_wave, pluvial_flood, code) VALUES (UPPER('"$CITY"'), false, false, substring(1,5,'"$CODE"') );"
			psql -U "postgres" -d "clarity" -c "UPDATE city SET boundary=sq.geom FROM (SELECT geom FROM "$NAME") as sq WHERE name='"$CITY"';"
			psql -U "postgres" -d "clarity" -c "DROP TABLE "$NAME";"

			#insert land use grid cell references for the city by using boudaries (not BBOX)
        		psql -U "postgres" -d "clarity" -c "INSERT INTO land_use_grid(cell,city) SELECT g.gid,c.id FROM laea_etrs_500m g, city c WHERE ST_Intersects(g.geom,c.boundary) AND c.name='"$CITY"';"
		else
			echo $CITY "already exists in database, skipping..."
                fi

	fi

done
echo "Cities checked."
##query in geoserver for mortality layer (brings mortality, boundary and city code)
##select c.id,c.name,c.code, m.deaths,m.population, m.rate, c.boundary from mortality m, city c where c.id=m.city and m.name is not null order by c.id ASC;
