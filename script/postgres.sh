#!/bin/sh

#Usefull command to work with Postgres

#TODO check deps like psql

function Create_Postgres_Database {
  local HOST=${1:-'database'}
  local PORT=${2:-'5432'}
  local USER=${3:-'genesys'}
  local PASS=${4:-'g3n3sys'}
  local NAME=${5:-'CFG'}

  echo "Start-up: Configure access for pgsql database"
  export PGHOST="$HOST"
  export PGPORT="$PORT"
  export PGUSER="$USER"
  export PGPASSWORD="$PASS"
  export PGDATABASE="postgres" #Temporary default

  # Wait for PG to be fully ready (nOTWORKING)
  #until psql -v ON_ERROR_STOP=1 -c "select version()" &> /dev/null
  #do
  #    echo "Waiting for database to be fully ready container..."
  #    sleep 2
  #done

  echo "Start-up: Checking pgsql database $NAME existing"
  if psql -lqt | cut -d \| -f 1 | grep -qw "$NAME"; then
    echo "Start-up: Database $NAME already exist -> doing nothing"
  else
    echo "Start-up: Creating Database $NAME"
    psql --echo-all  -c "CREATE DATABASE \"$NAME\";"
  fi

  #Set database at end
  export PGDATABASE="$NAME"
}
