#!/bin/bash

# Let's export the password for 'clarity' database user so it is not asked everytime we use the psql command
export PGPASSWORD='IMHnl8ORQcuNtaujfY0V84BM6TWovROt'

pg_dump -U clarity -h localhost -d claritydb | gzip -9 | split -b 250M - claritydb.pgsql.gz