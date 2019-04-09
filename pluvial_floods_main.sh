#!/bin/bash
#INDEX="/home/mario.nunez/script/parameters/pluvial_floods_layers.dat"
UA_VERSION="UA2006"
UA_VERSION_FILE="UA2006_Revised"
#UA_VERSION="UA2012"
#UA_VERSION_FILE="UA2012"

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

	#ALL THIS 3 LOADS ONLY HAS TO BE DONE ONCE, NOT FOR EACH CITY

	#Create city table in postgresql if it does not exists
	psql -U "postgres" -d "clarity" -c "SELECT to_regclass('public.city');" > check.out
	FOUND=`sed "3q;d" check.out | cut -f 2 -d ' '`
        rm check.out
        if [ -z $FOUND ];
        then
		echo -e "\e[36mCreating city table\e[0m"
		psql -U "postgres" -d "clarity" -c "CREATE TABLE city( id SERIAL PRIMARY KEY, name VARCHAR(32),heat_wave BOOLEAN DEFAULT FALSE, pluvial_flood BOOLEAN DEFAULT FALSE, bbox GEOMETRY(Polygon,3035) );"
	fi

	#Create streams final table
	psql -U "postgres" -d "clarity" -c "SELECT to_regclass('public.streams');" > check.out
        FOUND=`sed "3q;d" check.out | cut -f 2 -d ' '`
        rm check.out
        if [ -z $FOUND ];
        then
		echo -e "\e[36mCreating streams table\e[0m"
		psql -U "postgres" -d "clarity" -c "CREATE TABLE streams(gid integer PRIMARY KEY,stream_typ character varying(254) COLLATE pg_catalog.\"default\",\"Shape_Leng\" numeric,geom geometry(LineString,3035), start_height numeric, end_height numeric);"
	fi
	#loading complete STREAMS geometries into database
	##shp2pgsql -k -s 3035 -I $STREAMS_FOLDER/streams.shp "streams_europe" > $STREAMS_FOLDER/streams.sql
	##psql -d clarity -U postgres -f $STREAMS_FOLDER/streams.sql

	#Create basins final table
	psql -U "postgres" -d "clarity" -c "SELECT to_regclass('public.basins');" > check.out
        FOUND=`sed "3q;d" check.out | cut -f 2 -d ' '`
        rm check.out
        if [ -z $FOUND ];
        then
		echo -e "\e[36mCreating basins table\e[0m"
		psql -U "postgres" -d "clarity" -c "CREATE TABLE basins(gid integer PRIMARY KEY,\"AREA_KM2\" numeric,\"SHAPE_Leng\" numeric,\"SHAPE_Area\" numeric,geom geometry(MultiPolygon,3035));"
	fi
	#Loading complete BASINS geometries into database
        ##shp2pgsql -k -s 3035 -I -W "latin1" $BASINS_FOLDER/basins.shp "basins_europe" > $BASINS_FOLDER/basins.sql
        ##psql -d clarity -U postgres -f $BASINS_FOLDER/basins.sql

	#checking provided city exists already in database
	psql -U "postgres" -d "clarity" -c "SELECT pluvial_flood FROM city WHERE UPPER(name)=UPPER('"$CITY"');" > city.out
	FOUND=`sed "3q;d" city.out | cut -f 2 -d ' '`
	rm city.out
	if [ $FOUND == 't' ];
	then
		echo -e "\e[33mERROR: "$CITY" pluvial flood already loaded into the database!\e[0m"
		echo -e "\e[33mTry removing NAPOLI registry from city table or setting up pluvial_flood attribute to false\e[0m"
	else
		echo -e "\e[36mLoading pluvial flood "$CITY" data...\e[0m"

		#create city folder
        	mkdir -p $DATA/$CITY
	        DATA=$DATA/$CITY

        	#GET CITY BBOX FROM UA
	        mkdir $DATA/ua
	        ZIP=`ls $UA_FOLDER/*$CITY*`
	        NAME=`echo $ZIP | cut -f 7 -d '/' | cut -f 1 -d '.' | cut -f 1,2 -d '_'`
	        unzip $ZIP -d $DATA/$UA_VERSION
	        cp $DATA/$UA_VERSION/$NAME/Shapefiles/$NAME"_"$UA_VERSION_FILE".shp" $DATA/ua/
	        cp $DATA/$UA_VERSION/$NAME/Shapefiles/$NAME"_"$UA_VERSION_FILE".shx" $DATA/ua/
	        cp $DATA/$UA_VERSION/$NAME/Shapefiles/$NAME"_"$UA_VERSION_FILE".dbf" $DATA/ua/
	        cp $DATA/$UA_VERSION/$NAME/Shapefiles/$NAME"_"$UA_VERSION_FILE".prj" $DATA/ua/
	        rm -r $DATA/$UA_VERSION

	        YMAX=`ogrinfo -ro -so -al $DATA/ua/$NAME"_"$UA_VERSION_FILE".shp" | grep "Extent" | cut -f 2 -d ')' | cut -f 4 -d ' '`
	        YMIN=`ogrinfo -ro -so -al $DATA/ua/$NAME"_"$UA_VERSION_FILE".shp" | grep "Extent" | cut -f 1 -d ')' | cut -f 3 -d ' '`
	        XMAX=`ogrinfo -ro -so -al $DATA/ua/$NAME"_"$UA_VERSION_FILE".shp" | grep "Extent" | cut -f 3 -d '(' | cut -f 1 -d ','`
	        XMIN=`ogrinfo -ro -so -al $DATA/ua/$NAME"_"$UA_VERSION_FILE".shp" | grep "Extent" | cut -f 2 -d '(' | cut -f 1 -d ','`

		#LOAD CITY INTO DATABASE WITH ITS BBOX
		echo -e "\e[36m"$CITY "BBOX" $XMAX $YMAX $XMIN $YMIN"\e[0m"
		psql -U "postgres" -d "clarity" -c "SELECT EXISTS(SELECT * FROM city WHERE UPPER(name)=UPPER('"$CITY"'));" > city.out
		FOUND=`sed "3q;d" city.out | cut -f 2 -d ' '`
		rm city.out
		if [ $FOUND == 't' ];
		then
			#as city already exists in database just set pluvial_flood data to true since now there is pluvial_flood data
			psql -U "postgres" -d "clarity" -c "UPDATE city SET pluvial_flood=true;"
		else
			#as city is not in database, it has to be created a new register for it with pluvial_flood data true
			psql -U "postgres" -d "clarity" -c "INSERT INTO city (name,heat_wave,pluvial_flood,bbox) VALUES (UPPER('"$CITY"'),false,true, ST_MakeEnvelope("$XMIN","$YMIN","$XMAX","$YMAX",3035));"
		fi

		#BASINS
		echo -e "\e[36m...Extract basins...\e[0m"
		#create table insert into cogiendo lo que intersecta
		psql -U "postgres" -d "clarity" -c "CREATE TABLE basins_"$CITY"(gid integer PRIMARY KEY,\"AREA_KM2\" numeric,\"SHAPE_Leng\" numeric,\"SHAPE_Area\" numeric,geom geometry(MultiPolygon,3035));"
		psql -U "postgres" -d "clarity" -c "INSERT INTO basins_"$CITY"(SELECT b.gid,b.\"AREA_KM2\",b.\"SHAPE_Leng\",b.\"SHAPE_Area\",b.geom FROM basins_europe b, city c WHERE ST_Intersects(b.geom,c.bbox) and c.name='"$CITY"');"

		#Clusterization
		#echo -e "\e[36m...Clusterizing basins...\e[0m"
		#psql -U "postgres" -d "clarity" -c "CLUSTER basins USING basins_pkey;"

		#FALTA VOLCAR SOBRE TABLA GLOBAL Y BORRAR LA TABLA DEL SHAPEFILE DE LA CIUDAD ACTUAL
		psql -U "postgres" -d "clarity" -c "insert into basins (select * from basins_"$CITY_low");"
		psql -U "postgres" -d "clarity" -c "DROP TABLE basins_"$CITY_low";"

		#STREAMS
	        echo -e "\e[36m...Extract streams...\e[0m"
		#create table insert into cogiendo lo que intersecta
		psql -U "postgres" -d "clarity" -c "CREATE TABLE streams_"$CITY"(gid integer PRIMARY KEY,stream_typ character varying(254) COLLATE pg_catalog.\"default\",\"Shape_Leng\" numeric,geom geometry(LineString,3035));"
		psql -U "postgres" -d "clarity" -c "INSERT INTO streams_"$CITY"(SELECT s.gid,s.stream_typ,s.\"Shape_Leng\",ST_LineMerge(s.geom) FROM streams_europe s, city c WHERE ST_Intersects(s.geom,c.bbox) and c.name='"$CITY"');"

		#get bbox from streams clipped in database to calculate DEM AREA TO LOAD INTO DATABASE
		XMIN=`psql -U "postgres" -d "clarity" -c "SELECT ST_Extent(geom) as extent FROM streams_napoli;" | grep 'BOX' | cut -f 1 -d ',' | cut -f 2 -d '(' | cut -f 1 -d ' '`
		YMIN=`psql -U "postgres" -d "clarity" -c "SELECT ST_Extent(geom) as extent FROM streams_napoli;" | grep 'BOX' | cut -f 1 -d ',' | cut -f 2 -d '(' | cut -f 2 -d ' '`
		XMAX=`psql -U "postgres" -d "clarity" -c "SELECT ST_Extent(geom) as extent FROM streams_napoli;" | grep 'BOX' | cut -f 2 -d ',' | cut -f 1 -d ')' | cut -f 1 -d ' '`
		YMAX=`psql -U "postgres" -d "clarity" -c "SELECT ST_Extent(geom) as extent FROM streams_napoli;" | grep 'BOX' | cut -f 2 -d ',' | cut -f 1 -d ')' | cut -f 2 -d ' '`
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
		psql -U "postgres" -d "clarity" -c "insert into streams (select * from streams_"$CITY_low");"
                psql -U "postgres" -d "clarity" -c "DROP TABLE streams_"$CITY_low";"

		#delete city data
	        rm -r $DATA
	        echo -e "\e[36mGeneration completed for "$CITY"\e[0m"
	fi
else
	echo -e "\e[33mERROR: No data avaiable in the file system for "$CITY"!\e[0m"
	echo -e "\e[33mUnable to generate input layers for pluvial floods local effects.\e[0m"
fi

#TO RUN IT AGAIN FROM THE VERY BEGINNING
#DROP TABLE basins;
#DROP TABLE streams;
#UPDATE city SET pluvial_flood=false WHERE name='NAPOLI';

