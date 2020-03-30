#!/bin/bash

if [[ $# -eq 0 ]] ;
then
    echo -e "\e[36mINFO: loading ALL cities no currently in the system.\e[0m"
    #INSPECT DATABASE TO GET CITIES WITH HEAT_WAVE AND PLUVIAL FLOODS NOT CURRENTLY GENERATED
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
else
    echo -e "\e[36mINFO: loading cities in "$1".\e[0m"
    COUNTER=1
    while read -r INPUT;
    do
	#if line is commented with '#' ignore the city
	if [[ "$INPUT" != \#* ]];
	then
		LINES+=($INPUT)
	        COUNTER=$((COUNTER+1))
	fi
    done < $1
fi


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
