#!/bin/bash

#once input layers of a specific city are already generated and loaded into database
#is posible to generate land use grid by providing city name

HEAT_WAVE=("water" "roads" "railways" "trees" "vegetation" "agricultural_areas" "built_up" "built_open_spaces" "dense_urban_fabric" "medium_urban_fabric" "low_urban_fabric" "public_military_industrial")
PLUVIAL_FLOOD=("basins" "streams")

CITY=$(echo "$1" | awk '{print toupper($0)}')

psql -U "postgres" -d "clarity" -c "SELECT * FROM public.city WHERE name='$CITY';" > check.out
HEAT=`grep "$CITY" check.out | cut -f 3 -d '|'`
PLUVIAL=`grep "$CITY" check.out | cut -f 4 -d '|'`
rm check.out

if [ $HEAT == 't' ] || [ $PLUVIAL == 't' ];
then
	#insert cell references for city bbox
	#psql -U "postgres" -d "clarity" -c "INSERT INTO land_use_grid(cell) SELECT gid FROM laea_etrs_500m g, city c WHERE ST_Intersects(g.geom,c.bbox) AND c.name='"$CITY"';"
	#this is now done on heat_wave_main, before input layers generation

	if [ $HEAT == 't' ];
	then
		echo -e "\e[36mgenerating land use from heat wave data...\e[0m"
		for TYPE in "${HEAT_WAVE[@]}";
		do
			echo "generating" $TYPE "percentages..."
			psql -U "postgres" -d "clarity" -c "update land_use_grid set "$TYPE"=subquery.percentage from (select cells.gid as cell, st_area(St_Union(st_intersection(St_MakeValid(w.geom), cells.geom)))/st_area(cells.geom) as percentage from "$TYPE" w,(select g.gid, g.geom from laea_etrs_500m g, city c where ST_Intersects(g.geom,c.bbox) AND c.name='"$CITY"') as cells where st_Intersects(w.geom, cells.geom) group by cell, cells.geom) as subquery where land_use_grid.cell=subquery.cell;"
		done
	else
		echo -e "\e[33mERROR: heat wave city data not found!\e[0m"
	fi

	if [ $PLUVIAL == 't' ];
	then
        	echo -e "\e[36mgenerating land use from pluvial flood data...\e[0m"
		for TYPE in "${PLUVIAL_FLOOD[@]}";
                do
                        echo "generating" $TYPE "percentages..."
                        psql -U "postgres" -d "clarity" -c "update land_use_grid set "$TYPE"=subquery.percentage from (select cells.gid as cell, st_area(St_Union(st_intersection(St_MakeValid(w.geom), cells.geom)))/st_area(cells.geom) as percentage from "$TYPE" w,(select g.gid, g.geom from laea_etrs_500m g, city c where ST_Intersects(g.geom,c.bbox) AND c.name='"$CITY"') as cells where st_Intersects(w.geom, cells.geom) group by cell, cells.geom) as subquery where land_use_grid.cell=subquery.cell;"
                done
	else
        	echo -e "\e[33mERROR: pluvial flood city data not found!\e[0m"
	fi

else
	echo -e "\e[33mERROR: no data found for "$CITY"\e[0m"
fi
