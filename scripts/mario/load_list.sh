#!/bin/bash

if [[ $# -eq 0 ]] ;
then
    echo -e "\e[33mERROR: No city list provided!\e[0m"
else
    echo -e "\e[36mINFO: loading cities in "$1" and replace any already in the system.\e[0m"
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

	#BEFORE LOADING DELETE CITY IF EXIST
	source delete_city.sh $CITY
	wait

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

fi
