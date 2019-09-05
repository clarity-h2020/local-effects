#!/bin/bash
#NOTE: Execute the script like this: bash ./script.sh, otherwise some commands may not work, e.g., source, <<<, etc.


source ./env.sh

# create the database table structure 
psql -U ${PGUSER} -h ${PGHOST} -p ${PGPORT} -d ${PGDATABASE} -f ../sql/create-database-model.sql