#!/bin/bash

# Let's export the password for 'clarity' database user so it is not asked everytime we use the psql command
export PGPASSWORD='IMHnl8ORQcuNtaujfY0V84BM6TWovROt'

cat claritydb.pgsql.gz* | gunzip | psql -U clarity -h localhost -d claritydb