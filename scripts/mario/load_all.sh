#!/bin/bash
CITIES=()

#INSPECT DATABASE TO GET CITIES WITH HEAT_WAVE NOT CURRENTLY GENERATED
psql -U "postgres" -d "clarity" -c "SELECT id,name FROM city WHERE heat_wave='false' AND pluvial_flood='false' ORDER BY id;" > cities.out

SIZE=`wc cities.out | awk '{print $1}'`
COUNTER=1
while read -r INPUT;
do
	if [[ $COUNTER -gt 2 ]] && [[ $COUNTER -lt $(($SIZE-1)) ]]
	then
		INPUT=${INPUT/ | /#}
		LINES+=($INPUT)
	fi
	COUNTER=$((COUNTER+1))
done < cities.out
rm ./cities.out

COUNTER=$((COUNTER-5))

#PROCESSING EACH CITY
for LINE in ${LINES[*]}
do
	ID=`echo $LINE | cut -f 1 -d '#'`
        CITY=`echo $LINE | cut -f 2 -d '#'`
       	CITY=`echo $CITY | tr -s ' ' | tr ' ' '_'`

        echo ""
	echo -e "\e[7mRemaining cities:" $COUNTER"\e[0m"
#	mkdir -p ./output/$CITY

        echo ""
        echo -e "\e[36m### "$CITY" - "$ID" ###"
#       date
#	echo ""

	source load_city.sh $CITY
	wait

#        source heat_waves_main.sh $CITY > output/$CITY/heat_wave.out 2>&1
#        wait
#        echo -e "\e[0mheat wave layers have been generated!"
#        source pluvial_floods_main.sh $CITY > output/$CITY/pluvial_floods.out 2>&1
#        wait
#        echo -e "\e[0mpluvial flood layers have been generated!"
#        source land_use_grid.sh $CITY > output/$CITY/land_use_grid.out 2>&1
#        wait
#        echo -e "\e[0mland use grid has been generated!"

	#DELETE CITY LOGS
#	rm -r output/$CITY

        #DELETE CITY DATA
#	rm -r data/$CITY

#	echo -e "\e[36m"
#	date
        echo -e "### END ###\e[0m"

	COUNTER=$((COUNTER-1))
done
echo ""
echo -e "\e[7m--- END ---\e[0m"
