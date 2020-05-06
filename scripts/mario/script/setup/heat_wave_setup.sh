#!/bin/bash

#this script is to create all 12 land use final tables where every city corresponding land use information is stored

#layer 1
#Create water final table
psql -U "postgres" -d "clarity" -c "SELECT to_regclass('public.water');" > check.out
FOUND=`sed "3q;d" check.out | cut -f 2 -d ' '`
rm check.out
if [ -z $FOUND ];
then
	echo -e "\e[36mCreating water table\e[0m"
	psql -U "postgres" -d "clarity" -c "DROP SEQUENCE IF EXISTS public.water_id_seq;"
#	psql -U "postgres" -d "clarity" -c "CREATE SEQUENCE public.water_id_seq INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1;"
        psql -U "postgres" -d "clarity" -c "CREATE TABLE public.water(id SERIAL NOT NULL,geom geometry(MultiPolygon,3035),city integer NOT NULL DEFAULT 1 REFERENCES city (id),cell integer NOT NULL REFERENCES laea_etrs_500m (gid),albedo real,emissivity real,transmissivity real,hillshade_building real,hillshade_green_fraction real,building_shadow smallint,vegetation_shadow real,run_off_coefficient real,fua_tunnel real,CONSTRAINT water_pkey PRIMARY KEY (id))"
	psql -U "postgres" -d "clarity" -c "CREATE INDEX water_geom_idx ON water USING GIST(geom);"
else
	echo -e "\e[33mERROR: Water table already exists\e[0m"
fi

#layer 2
#Create roads final table
psql -U "postgres" -d "clarity" -c "SELECT to_regclass('public.roads');" > check.out
FOUND=`sed "3q;d" check.out | cut -f 2 -d ' '`
rm check.out
if [ -z $FOUND ];
then
        echo -e "\e[36mCreating roads table\e[0m"
	psql -U "postgres" -d "clarity" -c "DROP SEQUENCE IF EXISTS public.roads_id_seq;"
#        psql -U "postgres" -d "clarity" -c "CREATE SEQUENCE public.roads_id_seq INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1;"
        psql -U "postgres" -d "clarity" -c "CREATE TABLE public.roads(id serial NOT NULL,geom geometry(MultiPolygon,3035),city integer NOT NULL DEFAULT 1 REFERENCES city (id),cell integer NOT NULL REFERENCES laea_etrs_500m (gid), albedo real, emissivity real, transmissivity real,hillshade_building real,hillshade_green_fraction real,building_shadow smallint,vegetation_shadow real,run_off_coefficient real,fua_tunnel real,CONSTRAINT roads_pkey PRIMARY KEY (id));"
	psql -U "postgres" -d "clarity" -c "CREATE INDEX roads_geom_idx ON roads USING GIST(geom);"
else
        echo -e "\e[33mERROR: Roads table already exists\e[0m"
fi

#layer 3
#Create railways final table
psql -U "postgres" -d "clarity" -c "SELECT to_regclass('public.railways');" > check.out
FOUND=`sed "3q;d" check.out | cut -f 2 -d ' '`
rm check.out
if [ -z $FOUND ];
then
        echo -e "\e[36mCreating railways table\e[0m"
	psql -U "postgres" -d "clarity" -c "DROP SEQUENCE public.railways_seq;"
#        psql -U "postgres" -d "clarity" -c "CREATE SEQUENCE public.railways_id_seq INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1;"
        psql -U "postgres" -d "clarity" -c "CREATE TABLE public.railways(id serial NOT NULL,geom geometry(MultiPolygon,3035),city integer NOT NULL DEFAULT 1 REFERENCES city (id),cell integer NOT NULL REFERENCES laea_etrs_500m (gid), albedo real, emissivity real, transmissivity real, hillshade_building real,hillshade_green_fraction real,building_shadow smallint,vegetation_shadow real,run_off_coefficient real,fua_tunnel real,CONSTRAINT railways_pkey PRIMARY KEY (id));"
	psql -U "postgres" -d "clarity" -c "CREATE INDEX railways_geom_idx ON railways USING GIST(geom);"
else
        echo -e "\e[33mERROR: Railways table already exists\e[0m"
fi


#layer 4
#Create trees final table
psql -U "postgres" -d "clarity" -c "SELECT to_regclass('public.trees');" > check.out
FOUND=`sed "3q;d" check.out | cut -f 2 -d ' '`
rm check.out
if [ -z $FOUND ];
then
        echo -e "\e[36mCreating trees table\e[0m"
	psql -U "postgres" -d "clarity" -c "DROP SEQUENCE IF EXISTS public.trees_id_seq;"
#        psql -U "postgres" -d "clarity" -c "CREATE SEQUENCE public.trees_id_seq INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1;"
        psql -U "postgres" -d "clarity" -c "CREATE TABLE public.trees(id serial NOT NULL,geom geometry(MultiPolygon,3035),city integer NOT NULL DEFAULT 1 REFERENCES city (id),cell integer NOT NULL REFERENCES laea_etrs_500m (gid), albedo real, emissivity real, transmissivity real, hillshade_building real,hillshade_green_fraction real,building_shadow smallint,vegetation_shadow real,run_off_coefficient real,fua_tunnel real,CONSTRAINT trees_pkey PRIMARY KEY (id));"
	psql -U "postgres" -d "clarity" -c "CREATE INDEX trees_geom_idx ON trees USING GIST(geom);"
else
        echo -e "\e[33mERROR: trees table already exists\e[0m"
fi


#layer 5
#Create vegetation final table
psql -U "postgres" -d "clarity" -c "SELECT to_regclass('public.vegetation');" > check.out
FOUND=`sed "3q;d" check.out | cut -f 2 -d ' '`
rm check.out
if [ -z $FOUND ];
then
        echo -e "\e[36mCreating vegetation table\e[0m"
	psql -U "postgres" -d "clarity" -c "DROP SEQUENCE IF EXISTS public.vegetation_id_seq;"
#        psql -U "postgres" -d "clarity" -c "CREATE SEQUENCE public.vegetation_id_seq INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1;"
        psql -U "postgres" -d "clarity" -c "CREATE TABLE public.vegetation(id serial NOT NULL,geom geometry(MultiPolygon,3035),city integer NOT NULL DEFAULT 1 REFERENCES city (id),cell integer NOT NULL REFERENCES laea_etrs_500m (gid), albedo real, emissivity real, transmissivity real, hillshade_building real,hillshade_green_fraction real,building_shadow smallint,vegetation_shadow real,run_off_coefficient real,fua_tunnel real,CONSTRAINT vegetation_pkey PRIMARY KEY (id));"
	psql -U "postgres" -d "clarity" -c "CREATE INDEX vegetation_geom_idx ON vegetation USING GIST(geom);"
else
        echo -e "\e[33mERROR: vegetation table already exists\e[0m"
fi


#layer 6
#Create agricultural_areas final table
psql -U "postgres" -d "clarity" -c "SELECT to_regclass('public.agricultural_areas');" > check.out
FOUND=`sed "3q;d" check.out | cut -f 2 -d ' '`
rm check.out
if [ -z $FOUND ];
then
        echo -e "\e[36mCreating agricultural_areas table\e[0m"
	psql -U "postgres" -d "clarity" -c "DROP SEQUENCE IF EXISTS public.agricultural_areas_id_seq;"
#        psql -U "postgres" -d "clarity" -c "CREATE SEQUENCE public.agricultural_areas_id_seq INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1;"
        psql -U "postgres" -d "clarity" -c "CREATE TABLE public.agricultural_areas(id serial NOT NULL,geom geometry(MultiPolygon,3035),city integer NOT NULL DEFAULT 1 REFERENCES city (id),cell integer NOT NULL REFERENCES laea_etrs_500m (gid), albedo real, emissivity real, transmissivity real, hillshade_building real,hillshade_green_fraction real,building_shadow smallint,vegetation_shadow real,run_off_coefficient real,fua_tunnel real,CONSTRAINT agricultural_areas_pkey PRIMARY KEY (id));"
	psql -U "postgres" -d "clarity" -c "CREATE INDEX agricultural_areas_geom_idx ON agricultural_areas USING GIST(geom);"
else
        echo -e "\e[33mERROR: agricultural_areas table already exists\e[0m"
fi


#layer -
#Create built_up final table
psql -U "postgres" -d "clarity" -c "SELECT to_regclass('public.built_up');" > check.out
FOUND=`sed "3q;d" check.out | cut -f 2 -d ' '`
rm check.out
if [ -z $FOUND ];
then
        echo -e "\e[36mCreating built_up table\e[0m"
	psql -U "postgres" -d "clarity" -c "DROP SEQUENCE IF EXISTS public.built_up_id_seq;"
#        psql -U "postgres" -d "clarity" -c "CREATE SEQUENCE public.built_up_id_seq INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1;"
        psql -U "postgres" -d "clarity" -c "CREATE TABLE public.built_up(id serial NOT NULL,geom geometry(MultiPolygon,3035),city integer NOT NULL DEFAULT 1 REFERENCES city (id),cell integer NOT NULL REFERENCES laea_etrs_500m (gid), albedo real, emissivity real, transmissivity real, hillshade_building real,hillshade_green_fraction real,building_shadow smallint,vegetation_shadow real,run_off_coefficient real,fua_tunnel real,CONSTRAINT built_up_pkey PRIMARY KEY (id));"
	psql -U "postgres" -d "clarity" -c "CREATE INDEX built_up_geom_idx ON sports USING GIST(geom);"
else
        echo -e "\e[33mERROR: sports table already exists\e[0m"
fi


#layer 7
#Create built_open_spaces final table
psql -U "postgres" -d "clarity" -c "SELECT to_regclass('public.built_open_spaces');" > check.out
FOUND=`sed "3q;d" check.out | cut -f 2 -d ' '`
rm check.out
if [ -z $FOUND ];
then
        echo -e "\e[36mCreating built_open_spaces table\e[0m"
	psql -U "postgres" -d "clarity" -c "DROP SEQUENCE IF EXISTS public.built_open_spaces_id_seq;"
#        psql -U "postgres" -d "clarity" -c "CREATE SEQUENCE public.built_open_spaces_id_seq INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1;"
        psql -U "postgres" -d "clarity" -c "CREATE TABLE public.built_open_spaces(id serial NOT NULL,geom geometry(MultiPolygon,3035),city integer NOT NULL DEFAULT 1 REFERENCES city (id),cell integer NOT NULL REFERENCES laea_etrs_500m (gid),albedo real, emissivity real, transmissivity real, hillshade_building real,hillshade_green_fraction real,building_shadow smallint,vegetation_shadow real,run_off_coefficient real,fua_tunnel real,CONSTRAINT built_open_spaces_pkey PRIMARY KEY (id));"
	psql -U "postgres" -d "clarity" -c "CREATE INDEX built_open_spaces_geom_idx ON built_open_spaces USING GIST(geom);"
else
        echo -e "\e[33mERROR: built_open_spaces table already exists\e[0m"
fi


#layer 8
#Create sports final table
psql -U "postgres" -d "clarity" -c "SELECT to_regclass('public.sports');" > check.out
FOUND=`sed "3q;d" check.out | cut -f 2 -d ' '`
rm check.out
if [ -z $FOUND ];
then
        echo -e "\e[36mCreating sports table\e[0m"
        psql -U "postgres" -d "clarity" -c "DROP SEQUENCE IF EXISTS public.sports_id_seq;"
#        psql -U "postgres" -d "clarity" -c "CREATE SEQUENCE public.sports_id_seq INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1;"
        psql -U "postgres" -d "clarity" -c "CREATE TABLE public.sports(id serial NOT NULL,geom geometry(MultiPolygon,3035),city integer NOT NULL DEFAULT 1 REFERENCES city (id),cell integer NOT NULL REFERENCES laea_etrs_500m (gid), albedo real DEFAULT 0.21, emissivity real, transmissivity real, hillshade_building real,hillshade_green_fraction real,building_shadow smallint,vegetation_shadow real,run_off_coefficient real,fua_tunnel real,CONSTRAINT sports_pkey PRIMARY KEY (id));"
        psql -U "postgres" -d "clarity" -c "CREATE INDEX sports_geom_idx ON sports USING GIST(geom);"
else
        echo -e "\e[33mERROR: sports table already exists\e[0m"
fi


#layer 9
#Create dense_urban_fabric final table
psql -U "postgres" -d "clarity" -c "SELECT to_regclass('public.dense_urban_fabric');" > check.out
FOUND=`sed "3q;d" check.out | cut -f 2 -d ' '`
rm check.out
if [ -z $FOUND ];
then
        echo -e "\e[36mCreating dense_urban_fabric table\e[0m"
	psql -U "postgres" -d "clarity" -c "DROP SEQUENCE IF EXISTS public.dense_urban_fabric_id_seq;"
#        psql -U "postgres" -d "clarity" -c "CREATE SEQUENCE public.dense_urban_fabric_id_seq INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1;"
        psql -U "postgres" -d "clarity" -c "CREATE TABLE public.dense_urban_fabric(id serial NOT NULL,geom geometry(MultiPolygon,3035),city integer NOT NULL DEFAULT 1 REFERENCES city (id),cell integer NOT NULL REFERENCES laea_etrs_500m (gid), albedo real, emissivity real, transmissivity real, hillshade_building real,hillshade_green_fraction real,building_shadow smallint,vegetation_shadow real,run_off_coefficient real,fua_tunnel real,CONSTRAINT dense_urban_fabric_pkey PRIMARY KEY (id));"
	psql -U "postgres" -d "clarity" -c "CREATE INDEX dense_urban_fabric_geom_idx ON dense_urban_fabric USING GIST(geom);"
else
        echo -e "\e[33mERROR: dense_urban_fabric table already exists\e[0m"
fi


#layer 10
#Create medium_urban_fabric final table
psql -U "postgres" -d "clarity" -c "SELECT to_regclass('public.medium_urban_fabric');" > check.out
FOUND=`sed "3q;d" check.out | cut -f 2 -d ' '`
rm check.out
if [ -z $FOUND ];
then
        echo -e "\e[36mCreating medium_urban_fabric table\e[0m"
	psql -U "postgres" -d "clarity" -c "DROP SEQUENCE IF EXISTS public.medium_urban_fabric_id_seq;"
#        psql -U "postgres" -d "clarity" -c "CREATE SEQUENCE public.medium_urban_fabric_id_seq INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1;"
        psql -U "postgres" -d "clarity" -c "CREATE TABLE public.medium_urban_fabric(id serial NOT NULL,geom geometry(MultiPolygon,3035),city integer NOT NULL DEFAULT 1 REFERENCES city (id),cell integer NOT NULL REFERENCES laea_etrs_500m (gid), albedo real, emissivity real, transmissivity real,hillshade_building real,hillshade_green_fraction real,building_shadow smallint,vegetation_shadow real,run_off_coefficient real,fua_tunnel real,CONSTRAINT medium_urban_fabric_pkey PRIMARY KEY (id));"
	psql -U "postgres" -d "clarity" -c "CREATE INDEX medium_urban_fabric_geom_idx ON medium_urban_fabric USING GIST(geom);"
else
        echo -e "\e[33mERROR: medium_urban_fabric table already exists\e[0m"
fi


#layer 11
#Create low_urban_fabric final table
psql -U "postgres" -d "clarity" -c "SELECT to_regclass('public.low_urban_fabric');" > check.out
FOUND=`sed "3q;d" check.out | cut -f 2 -d ' '`
rm check.out
if [ -z $FOUND ];
then
        echo -e "\e[36mCreating low_urban_fabric table\e[0m"
	psql -U "postgres" -d "clarity" -c "DROP SEQUENCE IF EXISTS public.low_urban_fabric_id_seq;"
#        psql -U "postgres" -d "clarity" -c "CREATE SEQUENCE public.low_urban_fabric_id_seq INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1;"
        psql -U "postgres" -d "clarity" -c "CREATE TABLE public.low_urban_fabric(id serial NOT NULL,geom geometry(MultiPolygon,3035),city integer NOT NULL DEFAULT 1 REFERENCES city (id),cell integer NOT NULL REFERENCES laea_etrs_500m (gid), albedo real, emissivity real, transmissivity real, hillshade_building real,hillshade_green_fraction real,building_shadow smallint,vegetation_shadow real,run_off_coefficient real,fua_tunnel real,CONSTRAINT low_urban_fabric_pkey PRIMARY KEY (id));"
	psql -U "postgres" -d "clarity" -c "CREATE INDEX low_urban_fabric_geom_idx ON low_urban_fabric USING GIST(geom);"
else
        echo -e "\e[33mERROR: low_urban_fabric table already exists\e[0m"
fi


#layer 12
#Create public_military_industrial final table
psql -U "postgres" -d "clarity" -c "SELECT to_regclass('public.public_military_industrial');" > check.out
FOUND=`sed "3q;d" check.out | cut -f 2 -d ' '`
rm check.out
if [ -z $FOUND ];
then
        echo -e "\e[36mCreating public_military_industrial table\e[0m"
	psql -U "postgres" -d "clarity" -c "DROP SEQUENCE IF EXISTS public.public_military_industrial_id_seq;"
#        psql -U "postgres" -d "clarity" -c "CREATE SEQUENCE public.public_military_industrial_id_seq INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 9223372036854775807 CACHE 1;"
        psql -U "postgres" -d "clarity" -c "CREATE TABLE public.public_military_industrial(id serial NOT NULL,geom geometry(MultiPolygon,3035),city integer NOT NULL DEFAULT 1 REFERENCES city (id),cell integer NOT NULL REFERENCES laea_etrs_500m (gid), albedo real, emissivity real, transmissivity real, hillshade_building real,hillshade_green_fraction real,building_shadow smallint,vegetation_shadow real,run_off_coefficient real,fua_tunnel real,CONSTRAINT public_military_industrial_pkey PRIMARY KEY (id));"
	psql -U "postgres" -d "clarity" -c "CREATE INDEX public_military_industrial_geom_idx ON public_military_industrial USING GIST(geom);"
else
        echo -e "\e[33mERROR: public_military_industrial table already exists\e[0m"
fi
