#!/bin/bash
LAYERS=("water" "roads" "railways" "trees" "vegetation" "agricultural_areas" "built_up" "built_open_spaces" "dense_urban_fabric" "medium_urban_fabric" "low_urban_fabric" "public_military_industrial")

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

	#SET CITY TO NOT LOADED INTO THE SYSTEM
	echo  -e "\e[36mTURN "$CITY" DATABASE STATUS TO 'NOT LOADED'\e[0m"
	psql -U "postgres" -d "clarity" -c "UPDATE city SET heat_wave='false', pluvial_flood='false'  WHERE id=$ID;"

	#delete land use grid data
	echo  -e "\e[36mDeleting "$CITY" land use grid data from database...\e[0m"
        psql -U "postgres" -d "clarity" -c "DELETE FROM land_use_grid WHERE city=$ID;"

	#delete auxiliary layers table
	echo  -e "\e[36mDeleting "$CITY" auxiliary layers table...\e[0m"
	psql -U "postgres" -d "clarity" -c "DROP TABLE IF EXISTS "$CITY"_layers9_12 CASCADE;"

	#deleting local files used as inputs for the scripts
	echo -e "\e[36mDeleting "$CITY" local input data files...\e[0m"
	rm -r ./data/$CITY

	#deleting any logs for the city load
	echo -e "\e[36mDeleting "$CITY" logs...\e[0m"
        rm -r ./output/$CITY

else
	echo -e "\e[33mERROR: City name not found.\e[0m"
fi

