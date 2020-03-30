#!/bin/bash
FOLDER="/home/mario.nunez/data/grid/500m"
SHP=$FOLDER/"laea_etrs_500m.shp"
SQL="laea_etrs_500m/laea_etrs_500m.sql"

#import european laea 500m grid table
psql -U "postgres" -d "clarity" -c "SELECT to_regclass('public.laea_etrs_500m');" > check.out
FOUND=`sed "3q;d" check.out | cut -f 2 -d ' '`
rm check.out
if [ -z $FOUND ];
then
        echo -e "\e[36mCreating laea_etrs_500m table\e[0m"
	#ogr2ogr -sql "SELECT * FROM laea_etrs_500m" "laea_etrs_500m" $SHP
	#shp2pgsql -k -s 3035 -I -d $SHP "laea_etrs_500m" > $SQL
	#psql -d clarity -U postgres -f $SQL
	#rm -r "laea_etrs_500m"
else
        echo -e "\e[33mERROR: laea_etrs_500m table already exists!e[0m"
fi

#create land use grid table
psql -U "postgres" -d "clarity" -c "SELECT to_regclass('public.land_use_grid');" > check.out
FOUND=`sed "3q;d" check.out | cut -f 2 -d ' '`
rm check.out
if [ -z $FOUND ];
then
        echo -e "\e[36mCreating land use grid table\e[0m"
	psql -U "postgres" -d "clarity" -c "CREATE TABLE public.land_use_grid(id serial NOT NULL,cell integer NOT NULL REFERENCES laea_etrs_500m (gid),city integer NOT NULL REFERENCES city (id),water real default 0,roads real default 0,railways real default 0,trees real default 0,vegetation real default 0,agricultural_areas real default 0,built_open_spaces real default 0,sports real default 0,dense_urban_fabric real default 0,medium_urban_fabric real default 0,low_urban_fabric real default 0,public_military_industrial real default 0,streams real DEFAULT 0, basin integer DEFAULT null, mean_altitude DEFAULT null, built_density real DEFAULT null, basin_altitude real DEFAULT null, CONSTRAINT land_use_grid_pkey PRIMARY KEY (id));"
else
        echo -e "\e[33mERROR: land use grid already exists!e[0m"
fi
