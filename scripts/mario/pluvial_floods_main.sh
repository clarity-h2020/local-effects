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
	psql -U "postgres" -d "clarity" -c "SELECT id FROM city WHERE pluvial_flood is null AND UPPER(name)=UPPER('"$CITY"');" > city.out
        ID=`sed "3q;d" city.out | sed -e 's/^[ \t]*//'`
        rm city.out

        if [[ $ID =~ "(0 rows)" ]];
	then
		echo -e "\e[33mERROR: "$CITY" pluvial flood already loaded into the database!\e[0m"
 		echo -e "\e[33mTry setting up pluvial_flood "$CITY" attribute to NULL\e[0m"
	else
		echo ""
	        echo -e "\e[36m"$CITY" database ID is "$ID
        	START=$(date '+%Y-%m-%d %H:%M:%S')
        	echo "Starting at:" $START
        	echo -e "\e[0m"

		#create city folder
        	mkdir -p $DATA/$CITY
	        DATA=$DATA/$CITY
		mkdir $DATA/ua
		mkdir $DATA/dem

        	#GET CITY BBOX FROM UA
		echo -e "\e[36mLoading pluvial flood Urban Atlas "$CITY" data...\e[0m"
	        ZIP=`ls $UA_FOLDER/*$CITY*`
	        NAME=`echo $ZIP | cut -f 7 -d '/' | cut -f 1 -d '.' | cut -f 1-5 -d '_'`
		CODE=`echo $NAME | cut -f 1 -d '_'`
	        unzip $ZIP -d $DATA/$UA_VERSION
	        cp $DATA/$UA_VERSION/$NAME/Shapefiles/$NAME"_"$UA_VERSION_FILE".shp" $DATA/ua/
	        cp $DATA/$UA_VERSION/$NAME/Shapefiles/$NAME"_"$UA_VERSION_FILE".shx" $DATA/ua/
	        cp $DATA/$UA_VERSION/$NAME/Shapefiles/$NAME"_"$UA_VERSION_FILE".dbf" $DATA/ua/
	        cp $DATA/$UA_VERSION/$NAME/Shapefiles/$NAME"_"$UA_VERSION_FILE".prj" $DATA/ua/
	        rm -r $DATA/$UA_VERSION

		#BASINS
		echo -e "\e[36m...Extract basins...\e[0m"
		#create table insert into cogiendo lo que intersecta
		psql -U "postgres" -d "clarity" -c "CREATE TABLE basins_"$CITY" (gid integer PRIMARY KEY,min_altitude real,geom geometry(MultiPolygon,3035));"
		psql -U "postgres" -d "clarity" -c "CREATE INDEX basins_"$CITY"_idx ON basins_"$CITY" USING GIST(geom);"
		#insert basins overlapping city boundary, even those parts being off-boundary
		psql -U "postgres" -d "clarity" -c "INSERT INTO basins_"$CITY" (SELECT b.gid,null,b.geom FROM basins_europe b, city c WHERE ST_Intersects(b.geom,c.boundary) and c.id="$ID");"

                #BBOX to generate DEM for basins
		EXTENT=`psql -U "postgres" -d "clarity" -c "select ST_Extent(geom) as box from basins_"$CITY" b, city c where c.id="$ID" and ST_Intersects(c.boundary,b.geom);"`
                XMIN=`echo $EXTENT | grep 'BOX' | cut -f 1 -d ',' | cut -f 2 -d '(' | cut -f 1 -d ' '`
		YMIN=`echo $EXTENT | grep 'BOX' | cut -f 1 -d ',' | cut -f 2 -d '(' | cut -f 2 -d ' '`
                XMAX=`echo $EXTENT | grep 'BOX' | cut -f 2 -d ',' | cut -f 1 -d ')' | cut -f 1 -d ' '`
                YMAX=`echo $EXTENT | grep 'BOX' | cut -f 2 -d ',' | cut -f 1 -d ')' | cut -f 2 -d ' '`
                echo -e "\e[36mBBOX BASINS DEM:" $XMIN $YMIN $XMAX $YMAX"\e[0m"
                XMIN=`echo $XMIN | cut -f 1 -d '.'`
                XMIN=$((XMIN-500))
                YMIN=`echo $YMIN | cut -f 1 -d '.'`
                YMIN=$((YMIN-500))
                XMAX=`echo $XMAX | cut -f 1 -d '.'`
                XMAX=$((XMAX+500))
                YMAX=`echo $YMAX | cut -f 1 -d '.'`
                YMAX=$((YMAX+500))

                echo -e "\e[36m...generating DEM for basins of "$CITY"...\e[0m"
                gdal_translate -projwin $XMIN $YMAX $XMAX $YMIN $DEM_FOLDER/eu_dem.vrt $DATA/dem/dem_$CITY"_aux.tif"
                #lowering resolution
                gdalwarp -ts 1456 1236 -r bilinear $DATA/dem/dem_$CITY"_aux.tif" $DATA/dem/dem_$CITY"_basins.tif"
                raster2pgsql -I -C -s 3035 -M $DATA/dem/dem_$CITY"_basins.tif" dem_$CITY"_basins" > $DATA/dem/dem_$CITY"_basins.sql"
                psql -d clarity -U postgres -f $DATA/dem/dem_$CITY"_basins.sql"
                rm $DATA/dem/dem_$CITY"_aux.tif"
                rm $DATA/dem/dem_$CITY"_basins.sql"

		#actualizar tabla basins de la ciudad con el calculo de la altura minima de cada unas de las basins
		psql -U "postgres" -d "clarity" -c "update basins_"$CITY" set min_altitude=sq.minimum FROM (select b.gid as basin,(ST_SummaryStats(ST_Clip(r.rast,b.geom))).min as minimum from dem_"$CITY"_basins r, basins_"$CITY" b) as sq where basins_"$CITY".gid=sq.basin;"

		#VOLCAR SOBRE TABLA GLOBAL Y BORRAR LA TABLA DEL SHAPEFILE DE LA CIUDAD ACTUAL
		echo -e "\e[36m...insert generated basins in final table...\e[0m"
		psql -U "postgres" -d "clarity" -c "insert into basins (id,geom,min_altitude) (select gid,geom,min_altitude from basins_"$CITY_low") on conflict (id) do nothing;"

		#STREAMS
	        echo -e "\e[36m...Extract streams...\e[0m"
		#create table streams
		psql -U "postgres" -d "clarity" -c "CREATE TABLE streams_"$CITY"(gid integer PRIMARY KEY,start_height numeric,end_height numeric,geom geometry(LineString,3035),city integer);"
		psql -U "postgres" -d "clarity" -c "CREATE INDEX streams_"$CITY"_idx ON streams_"$CITY" USING GIST(geom);"
		#insert streams overlapping city boundary, all streams, even those streams parts being off-boundary
		psql -U "postgres" -d "clarity" -c "INSERT INTO streams_"$CITY" (SELECT s.gid,null,null,ST_LineMerge(s.geom) FROM streams_europe s, city c WHERE ST_Intersects(s.geom,c.boundary) and c.name='"$CITY"');"

		#get bbox from streams and from city boundary (union of both) in database to calculate DEM AREA TO BE LOADED INTO DATABASE
		XMIN=`psql -U "postgres" -d "clarity" -c "select ST_Extent(ST_Union(s.extent::geometry,b.extent::geometry)) as extent from (SELECT ST_Extent(geom) as extent FROM streams_"$CITY_low") as s,(SELECT ST_Extent(boundary) as extent FROM city WHERE name='"$CITY"') as b;" | grep 'BOX' | cut -f 1 -d ',' | cut -f 2 -d '(' | cut -f 1 -d ' '`
		YMIN=`psql -U "postgres" -d "clarity" -c "select ST_Extent(ST_Union(s.extent::geometry,b.extent::geometry)) as extent from (SELECT ST_Extent(geom) as extent FROM streams_"$CITY_low") as s,(SELECT ST_Extent(boundary) as extent FROM city WHERE name='"$CITY"') as b;" | grep 'BOX' | cut -f 1 -d ',' | cut -f 2 -d '(' | cut -f 2 -d ' '`
		XMAX=`psql -U "postgres" -d "clarity" -c "select ST_Extent(ST_Union(s.extent::geometry,b.extent::geometry)) as extent from (SELECT ST_Extent(geom) as extent FROM streams_"$CITY_low") as s,(SELECT ST_Extent(boundary) as extent FROM city WHERE name='"$CITY"') as b;" | grep 'BOX' | cut -f 2 -d ',' | cut -f 1 -d ')' | cut -f 1 -d ' '`
		YMAX=`psql -U "postgres" -d "clarity" -c "select ST_Extent(ST_Union(s.extent::geometry,b.extent::geometry)) as extent from (SELECT ST_Extent(geom) as extent FROM streams_"$CITY_low") as s,(SELECT ST_Extent(boundary) as extent FROM city WHERE name='"$CITY"') as b;" | grep 'BOX' | cut -f 2 -d ',' | cut -f 1 -d ')' | cut -f 2 -d ' '`
		echo -e "\e[36mBBOX BOUNDARY FOR STREAMS:" $XMIN $YMIN $XMAX $YMAX"\e[0m"
		XMIN=`echo $XMIN | cut -f 1 -d '.'`
		XMIN=$((XMIN-500))
		YMIN=`echo $YMIN | cut -f 1 -d '.'`
		YMIN=$((YMIN-500))
		XMAX=`echo $XMAX | cut -f 1 -d '.'`
		XMAX=$((XMAX+500))
		YMAX=`echo $YMAX | cut -f 1 -d '.'`
		YMAX=$((YMAX+500))

		#DEM for streams
                echo -e "\e[36m...Generating DEM for streams...\e[0m"
                gdal_translate -projwin $XMIN $YMAX $XMAX $YMIN $DEM_FOLDER/eu_dem.vrt $DATA/dem/dem_$CITY.tif
                raster2pgsql -I -C -s 3035 -M $DATA/dem/dem_$CITY.tif dem_$CITY > dem_$CITY.sql
                psql -d clarity -U postgres -f dem_$CITY.sql
                rm dem_$CITY.sql

		#Calculate ends height with DEM
                echo -e "\e[36m...getting streams ends height...\e[0m"
		psql -U "postgres" -d "clarity" -c "UPDATE streams_"$CITY" SET start_height=ST_Value(rast, ST_StartPoint(geom),false) FROM dem_"$CITY" WHERE ST_Intersects(geom,ST_Envelope(rast));"
		psql -U "postgres" -d "clarity" -c "UPDATE streams_"$CITY" SET end_height=ST_Value(rast, ST_EndPoint(geom),false) FROM dem_"$CITY" WHERE ST_Intersects(geom,ST_Envelope(rast));"

		#VOLCAR SOBRE TABLA GLOBAL Y BORRAR LA TABLA DEL SHAPEFILE DE LA CIUDAD ACTUAL
		echo -e "\e[36m...insert generated streams in final table...\e[0m"
		psql -U "postgres" -d "clarity" -c "insert into streams (id,geom,start_height,end_height) (select gid,geom,start_height,end_height from streams_"$CITY_low") on conflict (id) do nothing;"

		#DETERMINE GRID CELL MEAN ALTITUDE
		echo -e "\e[36m...generating DEM bilinear for city cell mean altitude...\e[0m"
		gdalwarp -ts 1456 1236 -r bilinear $DATA/dem/dem_$CITY.tif $DATA/dem/dem_$CITY"_bilinear.tif"
		raster2pgsql -I -C -s 3035 -M $DATA/dem/dem_$CITY"_bilinear.tif" dem_$CITY"_bilinear" > $DATA/dem/dem_$CITY"_bilinear.sql"
		psql -d clarity -U postgres -f $DATA/dem/dem_$CITY"_bilinear.sql"

		echo -e "\e[36m...calculating cell mean altitude for "$CITY"...\e[0m"
		psql -U "postgres" -d "clarity" -c "UPDATE land_use_grid SET mean_altitude=sq.mean FROM (SELECT g.gid,(ST_SummaryStats(ST_Clip(r.rast, g.geom))).mean FROM dem_"$CITY"_bilinear r, land_use_grid lug, laea_etrs_500m g WHERE lug.city="$ID" AND lug.cell=g.gid) as sq WHERE sq.gid=land_use_grid.cell;"

		#streams count per cell
		echo -e "\e[36m...counting number of streams per city cell...\e[0m"
		psql -U "postgres" -d "clarity" -c "UPDATE land_use_grid SET streams=0 WHERE city="$ID";"
		psql -U "postgres" -d "clarity" -c "UPDATE land_use_grid SET streams=sq.value FROM (SELECT l.cell, count(*) AS value FROM laea_etrs_500m g,land_use_grid l, streams_"$CITY" s WHERE l.city="$ID" AND l.cell=g.gid AND ST_Intersects(g.geom,s.geom) GROUP BY l.cell) AS sq WHERE land_use_grid.cell=sq.cell;"

		#Basins altitude calculation cell mean altitude minus basin (highest overlapping area with cell) minimum altitude
		echo -e "\e[36m...Determine corresponding basin for each cell...\e[0m"
		psql -U "postgres" -d "clarity" -c "WITH test AS (SELECT l.cell,b.id AS basin, MAX(ST_Area(ST_Intersection(b.geom,g.geom))/ST_Area(g.geom)) AS percentage FROM laea_etrs_500m g, land_use_grid l, basins b WHERE l.city="$ID" AND l.cell=g.gid AND ST_Intersects(g.geom,b.geom) GROUP BY l.cell,b.id ORDER BY l.cell) UPDATE land_use_grid SET basin=s.basin FROM (SELECT t.cell,t.basin,t.percentage FROM test t JOIN (SELECT test.cell, max(percentage) AS percentage FROM test GROUP BY cell order by cell) j ON t.percentage=j.percentage AND t.cell=j.cell AND t.percentage>0) as s WHERE land_use_grid.cell=s.cell;"
		echo -e "\e[36m...calculating basins altitude...\e[0m"
		psql -U "postgres" -d "clarity" -c "UPDATE land_use_grid SET basin_altitude=sq.minimum FROM (SELECT l.cell,l.mean_altitude-b.min_altitude as minimum FROM land_use_grid l, basins b WHERE l.city="$ID" AND l.basin=b.id) AS sq WHERE land_use_grid.cell=sq.cell;"

		#cleaning database
		echo -e "\e[36m...cleaning database tables for "$CITY"... DEM, streams and basins...\e[0m"
		psql -U "postgres" -d "clarity" -c "DROP TABLE dem_"$CITY";"
		psql -U "postgres" -d "clarity" -c "DROP TABLE dem_"$CITY"_bilinear;"
		psql -U "postgres" -d "clarity" -c "DROP TABLE dem_"$CITY"_basins;"
		psql -U "postgres" -d "clarity" -c "DROP TABLE streams_"$CITY";"
		psql -U "postgres" -d "clarity" -c "DROP TABLE basins_"$CITY";"
		rm -r data/$CITY/dem

		echo ""
                END=$(date '+%Y-%m-%d %H:%M:%S')
                echo -e "\e[36mEnding at:" $END
                echo -e "\e[0m"
		echo -e "\e[36mGeneration completed for "$CITY"\e[0m"
		TIME=`date -u -d @$(($(date -d "$END" '+%s') - $(date -d "$START" '+%s'))) '+%T'`
                psql -U "postgres" -d "clarity" -c "UPDATE city SET pluvial_flood='"$TIME"' WHERE ID="$ID";"
	fi
else
	echo -e "\e[33mERROR: No data avaiable in the file system for "$CITY"!\e[0m"
	echo -e "\e[33mUnable to generate input layers for pluvial floods local effects.\e[0m"
fi

