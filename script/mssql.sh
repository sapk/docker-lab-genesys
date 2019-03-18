#!/bin/sh

#Usefull command to work with Mssql

#TODO check deps like mssql

function Create_Mssql_Database {
  local HOST=${1:-'database'}
  local PORT=${2:-'1433'}
  local USER=${3:-'sa'}
  local PASS=${4:-'demo@g3n3sys'}
  local NAME=${5:-'CFG'}

  echo "Start-up: Configure access for mssql database"

  echo "Start-up: Checking mssql database $NAME existing"
  local testDB=$(sqlcmd -S "$HOST,$PORT" -U "$USER" -P "$PASS" -Q "IF DB_ID('$NAME') IS NOT NULL print 'db exists'")
  echo "Start-up: $testDB"
  if [ "$testDB" = "db exists" ]; then
    echo "Start-up: Database $NAME already exist -> doing nothing"
  else
    echo "Start-up: Creating Database $NAME"
    sqlcmd -S "$HOST,$PORT" -U "$USER" -P "$PASS" -Q "CREATE DATABASE \"$NAME\";"
  fi
}
