#!/bin/bash
#INDEX="/home/mario.nunez/script/parameters/pluvial_floods_layers.dat"
#UA_VERSION="UA2006"
#UA_VERSION_FILE="UA2006_Revised"
UA_VERSION="UA2012"
UA_VERSION_FILE="UA2012"

DATA="/home/mario.nunez/script/data"
UA_FOLDER="/home/mario.nunez/data/heat_waves/"$UA_VERSION
DEM_FOLDER="/home/mario.nunez/data/pluvial_floods/dem"
BASINS_FOLDER="/home/mario.nunez/data/pluvial_floods/basins"
STREAMS_FOLDER="/home/mario.nunez/data/pluvial_floods/streams"

if [[ $# -eq 0 ]] ; then
    echo -e "\e[33mERROR: No city name provided!\e[0m"
    exit 1
fi
CITY=$(echo "$1" | awk '{print toupper($0)}')
CITY_low=$(echo "$1" | awk '{print tolower($0)}')
if [ -f $UA_FOLDER/*_$CITY.zip ] && [ -f $STREAMS_FOLDER/streams.shp ] && [ -f $BASINS_FOLDER/basins.shp ];
then
	echo -e "\e[36mIt seems like" $CITY "is an available city in the file system, gathering data...\e[0m"

	#checking provided city pluvial flood is already loaded in database
	psql -U "postgres" -d "clarity" -c "SELECT pluvial_flood FROM city WHERE UPPER(name)=UPPER('"$CITY"');" > city.out
	FOUND=`sed "3q;d" city.out | cut -f 2 -d ' '`
	rm city.out
	if [ $FOUND == 't' ];
	then
		echo -e "\e[33mERROR: "$CITY" pluvial flood already loaded into the database!\e[0m"
 		echo -e "\e[33mTry setting up pluvial_flood "$CITY" attribute to false\e[0m"
	else
		echo -e "\e[36mLoading pluvial flood "$CITY" data...\e[0m"

		#create city folder
        	mkdir -p $DATA/$CITY
	        DATA=$DATA/$CITY

        	#GET CITY BBOX FROM UA
	        mkdir $DATA/ua
	        ZIP=`ls $UA_FOLDER/*$CITY*`
	        NAME=`echo $ZIP | cut -f 7 -d '/' | cut -f 1 -d '.' | cut -f 1-5 -d '_'`
		CODE=`echo $NAME | cut -f 1 -d '_'`
	        unzip $ZIP -d $DATA/$UA_VERSION
	        cp $DATA/$UA_VERSION/$NAME/Shapefiles/$NAME"_"$UA_VERSION_FILE".shp" $DATA/ua/
	        cp $DATA/$UA_VERSION/$NAME/Shapefiles/$NAME"_"$UA_VERSION_FILE".shx" $DATA/ua/
	        cp $DATA/$UA_VERSION/$NAME/Shapefiles/$NAME"_"$UA_VERSION_FILE".dbf" $DATA/ua/
	        cp $DATA/$UA_VERSION/$NAME/Shapefiles/$NAME"_"$UA_VERSION_FILE".prj" $DATA/ua/
	        rm -r $DATA/$UA_VERSION

		#GET CITY BBOX FROM UA
                MAXY=`ogrinfo -ro -so -al $DATA/ua/$NAME"_"$UA_VERSION_FILE".shp" | grep "Extent" | cut -f 2 -d ')' | cut -f 4 -d ' '`
                MINY=`ogrinfo -ro -so -al $DATA/ua/$NAME"_"$UA_VERSION_FILE".shp" | grep "Extent" | cut -f 1 -d ')' | cut -f 3 -d ' '`
                MAXX=`ogrinfo -ro -so -al $DATA/ua/$NAME"_"$UA_VERSION_FILE".shp" | grep "Extent" | cut -f 3 -d '(' | cut -f 1 -d ','`
                MINX=`ogrinfo -ro -so -al $DATA/ua/$NAME"_"$UA_VERSION_FILE".shp" | grep "Extent" | cut -f 2 -d '(' | cut -f 1 -d ','`

		#BASINS
		echo -e "\e[36m...Extract basins...\e[0m"
		#create table insert into cogiendo lo que intersecta
		psql -U "postgres" -d "clarity" -c "CREATE TABLE basins_"$CITY"(gid integer PRIMARY KEY,\"AREA_KM2\" numeric,\"SHAPE_Leng\" numeric,\"SHAPE_Area\" numeric,geom geometry(MultiPolygon,3035),city integer);"
		psql -U "postgres" -d "clarity" -c "CREATE INDEX basins_"$CITY"_idx ON basins_"$CITY" USING GIST(geom);"
		psql -U "postgres" -d "clarity" -c "INSERT INTO basins_"$CITY"(SELECT b.gid,b.\"AREA_KM2\",b.\"SHAPE_Leng\",b.\"SHAPE_Area\",b.geom,c.id  FROM basins_europe b, city c WHERE ST_Intersects(b.geom,c.boundary) and c.name='"$CITY"');"
		#Clusterization
		#echo -e "\e[36m...Clusterizing basins...\e[0m"
		#psql -U "postgres" -d "clarity" -c "CLUSTER basins USING basins_pkey;"

		#FALTA VOLCAR SOBRE TABLA GLOBAL Y BORRAR LA TABLA DEL SHAPEFILE DE LA CIUDAD ACTUAL
		echo -e "\e[36m...insert generated basins in final table...\e[0m"
		psql -U "postgres" -d "clarity" -c "insert into basins (\"AREA_KM2\",\"SHAPE_Leng\",\"SHAPE_Area\",geom,city) (select \"AREA_KM2\",\"SHAPE_Leng\",\"SHAPE_Area\",geom,city from basins_"$CITY_low");"
		psql -U "postgres" -d "clarity" -c "DROP TABLE basins_"$CITY_low";"

		#STREAMS
	        echo -e "\e[36m...Extract streams...\e[0m"
		#create table insert into cogiendo lo que intersecta
		psql -U "postgres" -d "clarity" -c "CREATE TABLE streams_"$CITY"(gid integer PRIMARY KEY,stream_typ character varying(254) COLLATE pg_catalog.\"default\",\"Shape_Leng\" numeric,geom geometry(LineString,3035),city integer);"
		psql -U "postgres" -d "clarity" -c "CREATE INDEX streams_"$CITY"_idx ON streams_"$CITY" USING GIST(geom);"
		psql -U "postgres" -d "clarity" -c "INSERT INTO streams_"$CITY"(SELECT s.gid,s.stream_typ,s.\"Shape_Leng\",ST_LineMerge(s.geom),c.id FROM streams_europe s, city c WHERE ST_Intersects(s.geom,c.boundary) and c.name='"$CITY"');"

		#get bbox from streams clipped in database to calculate DEM AREA TO LOAD INTO DATABASE
		XMIN=`psql -U "postgres" -d "clarity" -c "SELECT ST_Extent(geom) as extent FROM streams_"$CITY";" | grep 'BOX' | cut -f 1 -d ',' | cut -f 2 -d '(' | cut -f 1 -d ' '`
		YMIN=`psql -U "postgres" -d "clarity" -c "SELECT ST_Extent(geom) as extent FROM streams_"$CITY";" | grep 'BOX' | cut -f 1 -d ',' | cut -f 2 -d '(' | cut -f 2 -d ' '`
		XMAX=`psql -U "postgres" -d "clarity" -c "SELECT ST_Extent(geom) as extent FROM streams_"$CITY";" | grep 'BOX' | cut -f 2 -d ',' | cut -f 1 -d ')' | cut -f 1 -d ' '`
		YMAX=`psql -U "postgres" -d "clarity" -c "SELECT ST_Extent(geom) as extent FROM streams_"$CITY";" | grep 'BOX' | cut -f 2 -d ',' | cut -f 1 -d ')' | cut -f 2 -d ' '`
		echo -e "\e[36mBBOX:" $XMIN $YMIN $XMAX $YMAX"\e[0m"
		XMIN=`echo $XMIN | cut -f 1 -d '.'`
		XMIN=$((XMIN-200))
		YMIN=`echo $YMIN | cut -f 1 -d '.'`
		YMIN=$((YMIN-200))
		XMAX=`echo $XMAX | cut -f 1 -d '.'`
		XMAX=$((XMAX+200))
		YMAX=`echo $YMAX | cut -f 1 -d '.'`
		YMAX=$((YMAX+200))
		echo -e "\e[36mBBOX EXTENDED:" $XMIN $YMIN $XMAX $YMAX"\e[0m"

		#DEM
                echo -e "\e[36mGenerating Digital Elevation Model map...\e[0m"
                mkdir $DATA/dem
                gdal_translate -projwin $XMIN $YMAX $XMAX $YMIN $DEM_FOLDER/eu_dem.vrt $DATA/dem/dem_$CITY.tif
                raster2pgsql -I -C -s 3035 -M $DATA/dem/dem_$CITY.tif dem_$CITY > dem_$CITY.sql
                psql -d clarity -U postgres -f dem_$CITY.sql
                rm dem_$CITY.sql

		#Calculate ends height with DEM
                echo -e "\e[36m...getting ends height...\e[0m"
		psql -U "postgres" -d "clarity" -c "ALTER TABLE streams_"$CITY" ADD COLUMN start_height numeric;"
		psql -U "postgres" -d "clarity" -c "ALTER TABLE streams_"$CITY" ADD COLUMN end_height numeric;"
		psql -U "postgres" -d "clarity" -c "UPDATE streams_"$CITY" SET start_height=ST_Value(rast, ST_StartPoint(geom),false) FROM dem_"$CITY" WHERE ST_Intersects(geom,ST_Envelope(rast));"
		psql -U "postgres" -d "clarity" -c "UPDATE streams_"$CITY" SET end_height=ST_Value(rast, ST_EndPoint(geom),false) FROM dem_"$CITY" WHERE ST_Intersects(geom,ST_Envelope(rast));"
		psql -U "postgres" -d "clarity" -c "DROP TABLE dem_"$CITY";"
		#Clusterization
		#echo -e "\e[36m...Clusterizing streams...\e[0m"
		#psql -U "postgres" -d "clarity" -c "CLUSTER streams USING streams_pkey;"

		#FALTA VOLCAR SOBRE TABLA GLOBAL Y BORRAR LA TABLA DEL SHAPEFILE DE LA CIUDAD ACTUAL
		echo -e "\e[36m...insert generated streams in final table...\e[0m"
		psql -U "postgres" -d "clarity" -c "insert into streams (stream_typ,\"Shape_Leng\",geom,city,start_height,end_height) (select stream_typ,\"Shape_Leng\",geom,city,start_height,end_height from streams_"$CITY_low");"
                psql -U "postgres" -d "clarity" -c "DROP TABLE streams_"$CITY_low";"

		#delete city data
##	        rm -r $DATA
	        echo -e "\e[36mGeneration completed for "$CITY"\e[0m"
		#REGISTER THAT NEEDED DATA IS PREPARED FOR THE CITY
                psql -U "postgres" -d "clarity" -c "UPDATE city SET pluvial_flood=TRUE WHERE NAME='"$CITY"';"
	fi
else
	echo -e "\e[33mERROR: No data avaiable in the file system for "$CITY"!\e[0m"
	echo -e "\e[33mUnable to generate input layers for pluvial floods local effects.\e[0m"
fi

#TO RUN IT AGAIN FROM THE VERY BEGINNING
#DROP TABLE basins;
#DROP TABLE streams;

