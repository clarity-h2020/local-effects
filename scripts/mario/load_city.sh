#!/bin/bash

if [[ $# -eq 0 ]];
then
    echo -e "\e[33mERROR: No city name provided!\e[0m"
    exit 1
fi

#check if city exists in the system, retrieve corresponding ID for that city name
CITY=$(echo "$1" | awk '{print toupper($0)}')
psql -U "postgres" -d "clarity" -c "SELECT id from city where name='"$CITY"';" > id.out
ID=`sed "3q;d" id.out | sed -e 's/^[ \t]*//'`
rm id.out

if [[ ! $ID =~ "(0 rows)" ]];
then
	#check if city has not heat wave and pluvial flood already generated
	psql -U "postgres" -d "clarity" -c "SELECT id FROM city WHERE heat_wave='false' OR pluvial_flood='false' AND name='"$CITY"';" > city.out
	ID=`sed "3q;d" city.out | sed -e 's/^[ \t]*//'`
	rm city.out

	if [[ ! $ID =~ "(0 rows)" ]];
	then
		echo ""
#        	echo -e "\e[36m"$CITY" database ID is "$ID
		echo "Starting at:"
		date
		echo -e "\e[0m"

		mkdir -p ./output/$CITY

		echo "Loading heat wave layers..."
        	source heat_waves_main.sh $CITY > output/$CITY/heat_wave.out 2>&1
        	wait
        	echo $CITY "heat wave layers have been generated!"

		echo "Loading pluvial flood layers..."
	       	source pluvial_floods_main.sh $CITY > output/$CITY/pluvial_floods.out 2>&1
        	wait
        	echo $CITY "pluvial flood layers have been generated!"

        	echo "Loading land use grid..."
		source land_use_grid.sh $CITY > output/$CITY/land_use_grid.out 2>&1
        	wait
        	echo $CITY "land use grid has been generated!"

		echo ""
		echo -e "\e[36mEnding at:"
		date
		echo -e "\e[0m"

        	#DELETE CITY LOGS
        	rm -r output/$CITY

	        #DELETE CITY DATA
        	rm -r data/$CITY
	else
		echo -e "\e[33mERROR:" $CITY "is already in the system!\e[0m"
	fi
else
	echo -e "\e[33mERROR:" $CITY "not found in the system!\e[0m"
fi
