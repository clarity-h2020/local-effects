#!/bin/bash
#INDEX="/home/mario.nunez/script/parameters/pluvial_floods_layers.dat"
BASINS_FOLDER="/home/mario.nunez/data/pluvial_floods/basins"
STREAMS_FOLDER="/home/mario.nunez/data/pluvial_floods/streams"

#Create streams final table - where to put each city data
psql -U "postgres" -d "clarity" -c "SELECT to_regclass('public.streams');" > check.out
FOUND=`sed "3q;d" check.out | cut -f 2 -d ' '`
rm check.out
if [ -z $FOUND ];
then
	echo -e "\e[36mCreating streams table\e[0m"
#	psql -U "postgres" -d "clarity" -c "CREATE SEQUENCE public.streams_id_seq INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1;"
        psql -U "postgres" -d "clarity" -c "CREATE TABLE streams(id serial NOT NULL, stream_typ character varying(254),\"Shape_Leng\" numeric, geom geometry(LineString,3035),city integer, start_height numeric, end_height numeric,CONSTRAINT streams_pkey PRIMARY KEY (id));"
	psql -U "postgres" -d "clarity" -c "CREATE INDEX streams_geom_idx ON streams USING GIST(geom);"

	#loading complete EUROPE STREAMS geometries into database - where to get each city streams
	psql -U "postgres" -d "clarity" -c "SELECT to_regclass('public.streams_europe');" > check.out
	FOUND=`sed "3q;d" check.out | cut -f 2 -d ' '`
	rm check.out
	if [ -z $FOUND ];
	then
		shp2pgsql -k -s 3035 -I $STREAMS_FOLDER/streams.shp "streams_europe" > $STREAMS_FOLDER/streams.sql
		psql -d clarity -U postgres -f $STREAMS_FOLDER/streams.sql
	else
		echo -e "\e[33mERROR: Europe streams table already exists\e[0m"
	fi
else
	echo -e "\e[33mERROR: Streams table already exists\e[0m"
fi

#Create basins final table - where to put each city data
psql -U "postgres" -d "clarity" -c "SELECT to_regclass('public.basins');" > check.out
FOUND=`sed "3q;d" check.out | cut -f 2 -d ' '`
rm check.out
if [ -z $FOUND ];
then
        echo -e "\e[36mCreating basins table\e[0m"
#	psql -U "postgres" -d "clarity" -c "CREATE SEQUENCE public.basins_id_seq INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1;"
	psql -U "postgres" -d "clarity" -c "CREATE TABLE basins(id serial NOT NULL, \"AREA_KM2\" numeric, \"SHAPE_Leng\" numeric, \"SHAPE_Area\" numeric, geom geometry(MultiPolygon,3035), city integer,CONSTRAINT basins_pkey PRIMARY KEY (id));"
	psql -U "postgres" -d "clarity" -c "CREATE INDEX basins_geom_idx ON basins USING GIST(geom);"

	#Loading complete EUROPE BASINS geometries into database - where to get each city basins
	psql -U "postgres" -d "clarity" -c "SELECT to_regclass('public.basins_europe');" > check.out
	FOUND=`sed "3q;d" check.out | cut -f 2 -d ' '`
	rm check.out
	if [ -z $FOUND ];
	then
		shp2pgsql -k -s 3035 -I -W "latin1" $BASINS_FOLDER/basins.shp "basins_europe" > $BASINS_FOLDER/basins.sql
		psql -d clarity -U postgres -f $BASINS_FOLDER/basins.sql
	else
		echo -e "\e[33mERROR: Europe basins table already exists\e[0m"
	fi
else
        echo -e "\e[33mERROR: Basinss table already exists\e[0m"
fi
