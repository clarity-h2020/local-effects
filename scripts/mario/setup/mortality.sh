#!/bin/bash

#create table in database for mortality data
#psql -U "postgres" -d "clarity" -c "DROP TABLE mortality IF EXISTS;"
psql -U "postgres" -d "clarity" -c "CREATE TABLE mortality (code varchar(7),name varchar(32),deaths integer,population integer,rate numeric(31,30),CONSTRAINT mortality_pkey PRIMARY KEY (code)) );"

#remove headers 1st line from csv file
sed '1d' moratality.csv > moratality_no_headers.csv

#import data into mortality table from csv file
psql -h localhost -d clarity -U postgres -c "copy mortality from STDIN with (format csv, delimiter ';', null '' )" < ./mortality_no_headers.csv

#add CITY column to later once a city is inserted into city table, set FK with city table ID
#no FK constraint will be set
psql -U "postgres" -d "clarity" -c "ALTER TABLE mortality ADD COLUMN city TYPE integer"

#update mortality with city ID
psql -U "postgres" -d "clarity" -c "UPDATE mortality m SET city=c.id FROM city c WHERE substring(m.code,1,5)=c.code and m.name is not null;"




#############################
###THIS CODE IS NOT TESTED###
#############################

#THIS NEXT LINES ARE FOR REMOVAL OF INITIALLY LOADED CITIES WITH ALL DATA SOURCES (above) IN THE SYSTEM WHICH HAVE NOT MORTALITY DATA!

#alter table city add new columns: rate, deaths, population (to import from mortality table)
psql -U "postgres" -d "clarity" -c "ALTER TABLE mortality ADD COLUMN deaths integer, ADD COLUMN population integer, ADD COLUMN rate numeric(31,30);"

#retrieve each city in the database
psql -U "postgres" -d "clarity" -c "SELECT code FROM city;" > cities.out

CODES=()
SIZE=`wc cities.out | awk '{print $1}'`
COUNTER=1
while read -r INPUT;
do
        if [[ $COUNTER -gt 2 ]] && [[ $COUNTER -lt $(($SIZE-1)) ]]
        then
                INPUT=${INPUT/ | /#}
                CODES+=($INPUT)
        fi
        COUNTER=$((COUNTER+1))
done < cities.out
rm ./cities.out

COUNTER=$((COUNTER-5))

#PROCESSING EACH RETRIEVED CITY
for CODE in ${CODES[*]}
do
        #checking if city has mortality rate value
        psql -U "postgres" -d "clarity" -c "SELECT rate FROM mortality WHERE code=('"$CODE"');" > rate.out
        FOUND=`sed "3q;d" rate.out | cut -f 2 -d ' '`
        rm rate.out
###warning check string when no value is returned for comparison!!!
        if [ $FOUND != 't' ];
        then
                #city has mortality data, so take deaths,rate,population into city
                psql -U "postgres" -d "clarity" -c "UPDATE city c SET deaths=m.death, population=m.population, rate=m.rate FROM mortality m WHERE c.code=('"$CODE"') AND m.code=c.code;"
        else
                #city does not have mortality data, so delete city
                psql -U "postgres" -d "clarity" -c "DELETE FROM city where code=('"$CODE"');"
        fi
done
##psql -U "postgres" -d "clarity" -c "DROP TABLE mortality;"
#be sure to not publish mortality layer in geoserver and publish only city but not using custom sql query
echo "Cities check ends."


