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
    echo "ERROR: No city name provided!"
    exit 1
fi
CITY=$(echo "$1" | awk '{print toupper($0)}')
CITY_low=$(echo "$1" | awk '{print tolower($0)}')
if [ -f $UA_FOLDER/*_$CITY.zip ] && [ -f $STREAMS_FOLDER/streams.shp ] && [ -f $BASINS_FOLDER/basins.shp ];
then
	echo "It seems like" $CITY "is an available city in the file system, gathering data..."

	#ALL THIS 3 LOADS ONLY HAS TO BE DONE ONCE, NOT FOR EACH CITY

	#Create city table in postgresql if it does not exists
	#psql -U "postgres" -d "clarity" -c "CREATE TABLE city( id SERIAL PRIMARY KEY, name VARCHAR(32), bbox GEOMETRY(Polygon,3035) );"

	#Create strams final table
	#Lsql -U "postgres" -d "clarity" -c "CREATE TABLE streams(gid integer PRIMARY KEY,stream_typ character varying(254) COLLATE pg_catalog.\"default\",\"Shape_Leng\" numeric,geom geometry(LineString,3035), start_height numeric, end_height numeric);"
	#loading complete STREAMS geometries into database
	#shp2pgsql -k -s 3035 -I $STREAMS_FOLDER/streams.shp "streams_europe" > $STREAMS_FOLDER/streams.sql
	#psql -d clarity -U postgres -f $STREAMS_FOLDER/streams.sql

	#Create basins final table
	#psql -U "postgres" -d "clarity" -c "CREATE TABLE basins(gid integer PRIMARY KEY,\"AREA_KM2\" numeric,\"SHAPE_Leng\" numeric,\"SHAPE_Area\" numeric,geom geometry(MultiPolygon,3035));"
	#Loading complete BASINS geometries into database
        #shp2pgsql -k -s 3035 -I -W "latin1" $BASINS_FOLDER/basins.shp "basins_europe" > $BASINS_FOLDER/basins.sql
        #psql -d clarity -U postgres -f $BASINS_FOLDER/basins.sql

	#checking provided city exists already in database
	psql -U "postgres" -d "clarity" -c "SELECT EXISTS(SELECT * FROM city WHERE UPPER(name)=UPPER('"$CITY"'));" > city.out
	FOUND=`sed "3q;d" city.out | cut -f 2 -d ' '`
	rm city.out
	if [ $FOUND == 't' ];
	then
		echo "ERROR: "$CITY" is already loaded into the database!"
	else
		echo "Loading "$CITY" data..."

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
		echo $CITY "BBOX" $XMAX $YMAX $XMIN $YMIN
		psql -U "postgres" -d "clarity" -c "INSERT INTO city (name,bbox) VALUES (UPPER('"$CITY"'), ST_MakeEnvelope("$XMIN","$YMIN","$XMAX","$YMAX",3035));"

		#BASINS
		echo "...Extract basins..."
		#create table insert into cogiendo lo que intersecta
		psql -U "postgres" -d "clarity" -c "CREATE TABLE basins_"$CITY"(gid integer PRIMARY KEY,\"AREA_KM2\" numeric,\"SHAPE_Leng\" numeric,\"SHAPE_Area\" numeric,geom geometry(MultiPolygon,3035));"
		psql -U "postgres" -d "clarity" -c "INSERT INTO basins_"$CITY"(SELECT b.gid,b.\"AREA_KM2\",b.\"SHAPE_Leng\",b.\"SHAPE_Area\",b.geom FROM basins_europe b, city c WHERE ST_Intersects(b.geom,c.bbox) and c.name='"$CITY"');"

		#Clusterization
		echo "...Clusterizing basins..."
		#psql -U "postgres" -d "clarity" -c "CLUSTER basins USING basins_pkey;"

		#FALTA VOLCAR SOBRE TABLA GLOBAL Y BORRAR LA TABLA DEL SHAPEFILE DE LA CIUDAD ACTUAL
		psql -U "postgres" -d "clarity" -c "insert into basins (select * from basins_"$CITY_low");"
		psql -U "postgres" -d "clarity" -c "DROP TABLE basins_"$CITY_low";"

		#STREAMS
	        echo "...Extract streams..."
		#create table insert into cogiendo lo que intersecta
		psql -U "postgres" -d "clarity" -c "CREATE TABLE streams_"$CITY"(gid integer PRIMARY KEY,stream_typ character varying(254) COLLATE pg_catalog.\"default\",\"Shape_Leng\" numeric,geom geometry(LineString,3035));"
		psql -U "postgres" -d "clarity" -c "INSERT INTO streams_"$CITY"(SELECT s.gid,s.stream_typ,s.\"Shape_Leng\",ST_LineMerge(s.geom) FROM streams_europe s, city c WHERE ST_Intersects(s.geom,c.bbox) and c.name='"$CITY"');"

		#get bbox from streams clipped in database to calculate DEM AREA TO LOAD INTO DATABASE
		XMIN=`psql -U "postgres" -d "clarity" -c "SELECT ST_Extent(geom) as extent FROM streams_napoli;" | grep 'BOX' | cut -f 1 -d ',' | cut -f 2 -d '(' | cut -f 1 -d ' '`
		YMIN=`psql -U "postgres" -d "clarity" -c "SELECT ST_Extent(geom) as extent FROM streams_napoli;" | grep 'BOX' | cut -f 1 -d ',' | cut -f 2 -d '(' | cut -f 2 -d ' '`
		XMAX=`psql -U "postgres" -d "clarity" -c "SELECT ST_Extent(geom) as extent FROM streams_napoli;" | grep 'BOX' | cut -f 2 -d ',' | cut -f 1 -d ')' | cut -f 1 -d ' '`
		YMAX=`psql -U "postgres" -d "clarity" -c "SELECT ST_Extent(geom) as extent FROM streams_napoli;" | grep 'BOX' | cut -f 2 -d ',' | cut -f 1 -d ')' | cut -f 2 -d ' '`
		echo "BBOX:" $XMIN $YMIN $XMAX $YMAX
		XMIN=`echo $XMIN | cut -f 1 -d '.'`
		XMIN=$((XMIN-200))
		YMIN=`echo $YMIN | cut -f 1 -d '.'`
		YMIN=$((YMIN-200))
		XMAX=`echo $XMAX | cut -f 1 -d '.'`
		XMAX=$((XMAX+200))
		YMAX=`echo $YMAX | cut -f 1 -d '.'`
		YMAX=$((YMAX+200))
		echo "BBOX EXTENDED:" $XMIN $YMIN $XMAX $YMAX

		#DEM
                echo "Generating Digital Elevation Model map..."
                mkdir $DATA/dem
                gdal_translate -projwin $XMIN $YMAX $XMAX $YMIN $DEM_FOLDER/eu_dem.vrt $DATA/dem/dem_$CITY.tif
                raster2pgsql -I -C -s 3035 -M $DATA/dem/dem_$CITY.tif dem_$CITY > dem_$CITY.sql
                psql -d clarity -U postgres -f dem_$CITY.sql
                rm dem_$CITY.sql

		#Calculate ends height with DEM
                echo "...getting ends height..."
		psql -U "postgres" -d "clarity" -c "ALTER TABLE streams_"$CITY" ADD COLUMN start_height numeric;"
		psql -U "postgres" -d "clarity" -c "ALTER TABLE streams_"$CITY" ADD COLUMN end_height numeric;"
		psql -U "postgres" -d "clarity" -c "UPDATE streams_"$CITY" SET start_height=ST_Value(rast, ST_StartPoint(geom),false) FROM dem_"$CITY" WHERE ST_Intersects(geom,ST_Envelope(rast));"
		psql -U "postgres" -d "clarity" -c "UPDATE streams_"$CITY" SET end_height=ST_Value(rast, ST_EndPoint(geom),false) FROM dem_"$CITY" WHERE ST_Intersects(geom,ST_Envelope(rast));"
		psql -U "postgres" -d "clarity" -c "DROP TABLE dem_"$CITY";"
		#Clusterization
		echo "...Clusterizing streams..."
		#psql -U "postgres" -d "clarity" -c "CLUSTER streams USING streams_pkey;"

		#FALTA VOLCAR SOBRE TABLA GLOBAL Y BORRAR LA TABLA DEL SHAPEFILE DE LA CIUDAD ACTUAL
		psql -U "postgres" -d "clarity" -c "insert into streams (select * from streams_"$CITY_low");"
                psql -U "postgres" -d "clarity" -c "DROP TABLE streams_"$CITY_low";"

		#delete city data
	        rm -r $DATA
	        echo "Generation completed for "$CITY
	fi
else
	echo "ERROR: No data avaiable in the file system for "$CITY"!"
	echo "Unable to generate input layers for pluvial floods local effects."
fi

#TO RUN IT AGAIN FROM THE VERY BEGINNING
#psql -U "postgres" -d "clarity" -c "DELETE FROM city;"
#psql -U "postgres" -d "clarity" -c "ALTER SEQUENCE city_id_seq RESTART WITH 1;"
#psql -U "postgres" -d "clarity" -c "DELETE FROM basins;"
#psql -U "postgres" -d "clarity" -c "ALTER SEQUENCE basins_id_seq RESTART WITH 1;"
#psql -U "postgres" -d "clarity" -c "DELETE FROM streams;"
#psql -U "postgres" -d "clarity" -c "ALTER SEQUENCE streams_id_seq RESTART WITH 1;"
