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
	psql -U "postgres" -d "clarity" -c "SELECT id FROM city WHERE heat_wave is null AND pluvial_flood is null AND id="$ID";" > city.out
	ID=`sed "3q;d" city.out | sed -e 's/^[ \t]*//'`
	rm city.out

	if [[ ! $ID =~ "(0 rows)" ]];
	then
		echo ""
        	echo -e "\e[36m"$CITY" database ID is "$ID
		#START_TOTAL=$(date '+%Y-%m-%d %H:%M:%S')
		START_TOTAL=$(date +%s)
		#echo "Starting at:" $START_TOTAL
		echo "Starting at:" $(date '+%Y-%m-%d %H:%M:%S')
		echo -e "\e[0m"

		mkdir -p ./output/$CITY

		echo "Loading heat wave layers..."
        	source heat_waves_main.sh $CITY > output/$CITY/heat_wave.out 2>&1
        	wait
        	echo $CITY "heat wave layers have been generated!"
		echo $(date '+%Y-%m-%d %H:%M:%S')

		echo "Loading pluvial flood layers..."
	       	source pluvial_floods_main.sh $CITY > output/$CITY/pluvial_floods.out 2>&1
        	wait
        	echo $CITY "pluvial flood layers have been generated!"

		echo ""
		#END_TOTAL=$(date '+%Y-%m-%d %H:%M:%S')
		#echo -e "\e[36mEnding at:" $END_TOTAL
		END_TOTAL=$(date +%s)
		echo -e "\e[36mEnding at:" $(date '+%Y-%m-%d %H:%M:%S')
		echo -e "\e[0m"

        	#DELETE CITY LOGS
##        	rm -r output/$CITY

	        #DELETE CITY DATA
        	rm -r data/$CITY

		#TIME_TOTAL=`date -u -d @$(($(date -d "$END_TOTAL" '+%s') - $(date -d "$START_TOTAL" '+%s'))) '+%T'`
		TIME_TOTAL=`echo $((END_TOTAL-START_TOTAL)) | awk '{printf "%d:%02d:%02d", $1/3600, ($1/60)%60, $1%60}'`
		psql -U "postgres" -d "clarity" -c "UPDATE city SET total='"$TIME_TOTAL"' WHERE ID="$ID";"
	else
		echo -e "\e[33mERROR:" $CITY "is already in the system!\e[0m"
	fi
else
	echo -e "\e[33mERROR:" $CITY "not found in the system!\e[0m"
fi
