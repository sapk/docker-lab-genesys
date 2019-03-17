#!/bin/sh

#Usefull command to work with network

#TODO check deps like curl and netcat

#Ex : Wait_For_Port localhost 2020 "database ($DB_TYPE)"
function Wait_For_Port {
  local host=${1:-'localhost'}
  local port=${2:-'8080'}
  local appname=${3:-''}
  local timer=${4:-'0.5'}

  echo "Start-up: Waiting $appname to launch on $host:$port..."
  while ! nc -z $host $port; do
    sleep $timer # wait for 1/2 of the second before check again
  done
  echo "Start-up: $appname launched"
}
