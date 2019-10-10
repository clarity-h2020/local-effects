#!/bin/bash

#once input layers of a specific city are already generated and loaded into database
#is posible to generate land use grid by providing city name

HEAT_WAVE=("water" "roads" "railways" "trees" "vegetation" "agricultural_areas" "built_up" "built_open_spaces" "dense_urban_fabric" "medium_urban_fabric" "low_urban_fabric" "public_military_industrial")
PLUVIAL_FLOOD=("basins" "streams")

CITY=$(echo "$1" | awk '{print toupper($0)}')

psql -U "postgres" -d "clarity" -c "SELECT * FROM public.city WHERE name='$CITY';" > check.out
HEAT=`grep "$CITY" check.out | cut -f 3 -d '|'`
#PLUVIAL=`grep "$CITY" check.out | cut -f 4 -d '|'`
rm check.out

#if [ $HEAT == 't' ] || [ $PLUVIAL == 't' ];
if [ $HEAT == 't' ];
then
	#get city ID
	psql -U "postgres" -d "clarity" -c "SELECT id from city where name='"$CITY"';" > id.out
	ID=`sed "3q;d" id.out | sed -e 's/^[ \t]*//'`
	rm id.out
	#delete old registers in land use grid table for current city
	psql -U "postgres" -d "clarity" -c "DELETE FROM land_use_grid WHERE city="$ID";"

 	#insert cell references for city boundary (not bbox)
	psql -U "postgres" -d "clarity" -c "INSERT INTO land_use_grid(cell,city) SELECT g.gid,c.id FROM laea_etrs_500m g, city c WHERE ST_Intersects(g.geom,c.boundary) AND c.name='"$CITY"';"

	if [ $HEAT == 't' ];
	then
		echo -e "\e[36mgenerating land use from heat wave data...\e[0m"
		for TYPE in "${HEAT_WAVE[@]}";
		do
			echo "generating" $TYPE "percentages..."
			#this is the old one by using regular geometries and spatial intersections (SLOWER)
			#psql -U "postgres" -d "clarity" -c "update land_use_grid set "$TYPE"=subquery.percentage from (select cells.gid as cell, st_area(St_Union(st_intersection(St_MakeValid(w.geom), cells.geom)))/st_area(cells.geom) as percentage from "$TYPE" w,(select g.gid, g.geom from laea_etrs_500m g, city c where ST_Intersects(g.geom,c.boundary) AND c.name='"$CITY"') as cells where st_Intersects(w.geom, cells.geom) group by cell, cells.geom) as subquery where land_use_grid.cell=subquery.cell;"
			#this is the new one by using grided geometries and regular joins (FASTER)
			psql -U "postgres" -d "clarity" -c "update land_use_grid set "$TYPE"=sq.percentage from (select l.cell as cell,st_area(w.geom)/st_area(g.geom) as percentage from "$TYPE" w, land_use_grid l, laea_etrs_500m g where w.cell=l.cell AND l.cell=g.gid AND l.city="$ID") as sq where sq.cell=land_use_grid.cell;"
		done
	else
		echo -e "\e[33mERROR: heat wave city data not found!\e[0m"
	fi

#	if [ $PLUVIAL == 't' ];
#	then
#       	echo -e "\e[36mgenerating land use from pluvial flood data...\e[0m"
#		for TYPE in "${PLUVIAL_FLOOD[@]}";
#                do
#                        echo "generating" $TYPE "percentages..."
#                        psql -U "postgres" -d "clarity" -c "update land_use_grid set "$TYPE"=subquery.percentage from (select cells.gid as cell, st_area(St_Union(st_intersection(St_MakeValid(w.geom), cells.geom)))/st_area(cells.geom) as percentage from "$TYPE" w,(select g.gid, g.geom from laea_etrs_500m g, city c where ST_Intersects(g.geom,c.boundary) AND c.name='"$CITY"') as cells where st_Intersects(w.geom, cells.geom) group by cell, cells.geom) as subquery where land_use_grid.cell=subquery.cell;"
#                done
#	else
#        	echo -e "\e[33mERROR: pluvial flood city data not found!\e[0m"
#	fi

	echo $CITY "land use grid generation completed!"
else
	echo -e "\e[33mERROR: no data found for "$CITY"\e[0m"
fi
