#!/bin/bash

# Let's export the password for 'clarity' database user so it is not asked everytime we use the psql command
export PGUSER='clarity'
export PGPASSWORD='IMHnl8ORQcuNtaujfY0V84BM6TWovROt'
export PGDATABASE='claritydb'
export PGHOST='localhost'
export PGPORT='5432'

export DATA_ROOT='/data/clarity-data'
