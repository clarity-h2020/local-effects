#!/bin/bash

. ./env.sh

# create the database table structure 
psql -U ${PGUSER} -h ${PGHOST} -p ${PGPORT} -d ${PGDATABASE} -f ../sql/create-database-model.sql