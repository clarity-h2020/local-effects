#!/bin/bash
LAYERS=("water" "roads" "railways" "trees" "vegetation" "agricultural_areas" "built_up" "built_open_spaces" "dense_urban_fabric" "medium_urban_fabric" "low_urban_fabric" "public_military_industrial")

if [[ $# -eq 0 ]] ;
then
    echo -e "\e[33mERROR: No city name provided!\e[0m"
    exit 1
fi
CITY=$(echo "$1" | awk '{print toupper($0)}')

for LAYER in "${LAYERS[@]}";
do
	NAME=$(echo $CITY"_"$LAYER | awk '{print tolower($0)}')
	psql -U "postgres" -d "clarity" -c "DROP TABLE IF EXISTS "$NAME"_grid;"
	psql -U "postgres" -d "clarity" -c "DROP SEQUENCE IF EXISTS "$NAME"_grid_seq;"
done
