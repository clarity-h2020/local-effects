#!/bin/sh

set -e

# Perform all actions as $POSTGRES_USER
export PGUSER="$POSTGRES_USER"

# Create the 'template_postgis' template db
"${psql[@]}" <<- 'EOSQL'
CREATE DATABASE template_postgis;
UPDATE pg_database SET datistemplate = TRUE WHERE datname = 'template_postgis';
EOSQL

# Load PostGIS into both template_database and $POSTGRES_DB
for DB in template_postgis "$POSTGRES_DB"; do
	echo "Loading PostGIS extensions into $DB"
	"${psql[@]}" --dbname="$DB" <<-'EOSQL'
		CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
		CREATE EXTENSION IF NOT EXISTS postgis;
        CREATE EXTENSION IF NOT EXISTS postgis_raster;
		CREATE EXTENSION IF NOT EXISTS postgis_sfcgal;
		CREATE EXTENSION IF NOT EXISTS postgis_topology;
		CREATE EXTENSION IF NOT EXISTS address_standardizer;		
		CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder;
		CREATE EXTENSION IF NOT EXISTS pgrouting;
		CREATE EXTENSION IF NOT EXISTS btree_gist;
		CREATE EXTENSION IF NOT EXISTS btree_gin;
		CREATE EXTENSION IF NOT EXISTS ogr_fdw;
		CREATE EXTENSION IF NOT EXISTS postgres_fdw;
		CREATE EXTENSION IF NOT EXISTS unit;
		CREATE EXTENSION IF NOT EXISTS hstore;
		CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
		CREATE EXTENSION IF NOT EXISTS intarray;
		CREATE EXTENSION IF NOT EXISTS hypopg;
		CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
		--CREATE EXTENSION IF NOT EXISTS pg_qualstats;
		--CREATE EXTENSION IF NOT EXISTS pg_stat_kcache;
		--CREATE EXTENSION IF NOT EXISTS pg_wait_sampling;

		--SELECT powa_qualstats_register();
		--SELECT powa_kcache_register();
		--SELECT powa_wait_sampling_register();	
EOSQL
done
