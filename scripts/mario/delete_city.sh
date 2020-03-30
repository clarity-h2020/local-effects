#!/bin/bash
LAYERS=("water" "roads" "railways" "trees" "vegetation" "agricultural_areas" "built_up" "built_open_spaces" "sports" "dense_urban_fabric" "medium_urban_fabric" "low_urban_fabric" "public_military_industrial")

if [[ $# -eq 0 ]];
then
    echo -e "\e[33mERROR: No city name provided!\e[0m"
    exit 1
fi
CITY=$(echo "$1" | awk '{print toupper($0)}')
psql -U "postgres" -d "clarity" -c "SELECT id from city where name='"$CITY"';" > id.out
ID=`sed "3q;d" id.out | sed -e 's/^[ \t]*//'`
rm id.out

if [[ ! $ID =~ "(0 rows)" ]];
then
	echo -e "\e[33m"$CITY" database id="$ID"\e[0m"
	for LAYER in "${LAYERS[@]}";
	do
        	echo -e "\e[36mDeleting "$LAYER" auxiliary tables...\e[0m"
	        NAME=$(echo $CITY"_"$LAYER | awk '{print tolower($0)}')
		psql -U "postgres" -d "clarity" -c "DROP TABLE IF EXISTS "$NAME" CASCADE;"
                psql -U "postgres" -d "clarity" -c "DROP SEQUENCE IF EXISTS "$NAME"_seq CASCADE;"
	        psql -U "postgres" -d "clarity" -c "DROP TABLE IF EXISTS "$NAME"_grid CASCADE;"
	        psql -U "postgres" -d "clarity" -c "DROP SEQUENCE IF EXISTS "$NAME"_grid_seq CASCADE;"
	        echo -e "\e[36mDeleting "$CITY" "$LAYER" data in final table...\e[0m"
	        psql -U "postgres" -d "clarity" -c "DELETE FROM $LAYER WHERE city=$ID;"
	done

	#delete streams and basins for city boundary
	#not delete since a basins/stream could be loaded because of a different city?
	echo  -e "\e[36mDeleting strea,s amd basins intersecting "$CITY"\e[0m"
	psql -U "postgres" -d "clarity" -c "delete from basins where ID in (select b.id from basins b, city c where c.id="$ID" and ST_Intersects(b.geom, c.boundary) group by b.id having count(*)=1);"
	psql -U "postgres" -d "clarity" -c "delete from streams where ID in (select b.id from basins b, city c where c.id="$ID" and ST_Intersects(b.geom, c.boundary) group by b.id having count(*)=1);"

	#SET CITY TO NOT LOADED INTO THE SYSTEM
	echo  -e "\e[36mTURN "$CITY" DATABASE STATUS TO 'NOT LOADED'\e[0m"
	#total time is not set to null to recall time it takes aprox.
	psql -U "postgres" -d "clarity" -c "UPDATE city SET heat_wave=null, pluvial_flood=null WHERE id=$ID;"

	#land use grid data of the city
	echo  -e "\e[36mDeleting "$CITY" land use grid data from database...\e[0m"
        #psql -U "postgres" -d "clarity" -c "UPDATE land_use_grid SET water=0,roads=0,railways=0,trees=0,vegetation=0,agricultural_areas=0,sports=0,built_open_spaces=0,dense_urban_fabric=0,medium_urban_fabric=0,low_urban_fabric=0,public_military_industrial=0,built_density=null,mean_altitude=null,streams=0,basin=null,basin_altitude=null WHERE city=$ID;"
	psql -U "postgres" -d "clarity" -c "delete from land_use_grid where city="$ID";"

	#delete auxiliary layers table
	echo  -e "\e[36mDeleting "$CITY" auxiliary layers table...\e[0m"
	psql -U "postgres" -d "clarity" -c "DROP TABLE IF EXISTS "$CITY"_layers9_12 CASCADE;"

	#delete DEM and pluvial floods city tables
	psql -U "postgres" -d "clarity" -c "DROP TABLE dem_"$CITY";"
        psql -U "postgres" -d "clarity" -c "DROP TABLE dem_"$CITY"_bilinear;"
	psql -U "postgres" -d "clarity" -c "DROP TABLE dem_"$CITY"_basins;"
        psql -U "postgres" -d "clarity" -c "DROP TABLE streams_"$CITY";"
        psql -U "postgres" -d "clarity" -c "DROP TABLE basins_"$CITY";"

	#deleting local files used as inputs for the scripts
	echo -e "\e[36mDeleting "$CITY" local input data files...\e[0m"
	rm -r ./data/$CITY

	#deleting any logs for the city load
	echo -e "\e[36mDeleting "$CITY" logs...\e[0m"
        rm -r ./output/$CITY

else
	echo -e "\e[33mERROR: City name not found.\e[0m"
fi

