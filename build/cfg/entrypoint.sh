#!/bin/sh

. /gcti/script/network.sh
. /gcti/script/lca.sh

# Start LCA
Genesys_Start_LCA 4999

Wait_For_Port "$DB_HOST" "$DB_PORT" "database ($DB_TYPE)"

#TODO remove blocking timer
sleep 3

if [ "$DB_TYPE" = "postgre" ]; then
  . /gcti/script/postgres.sh
  Create_Postgres_Database "$DB_HOST" "$DB_PORT" "$DB_USER" "$DB_PASS" "$CFG_DB_NAME"

  echo "Start-up: Checking pgsql database $CFG_DB_NAME for table 'cfg_locale'"
  if psql -c "SELECT to_regclass('cfg_locale');" | grep cfg_locale; then
    echo "Start-up: Database $CFG_DB_NAME already init -> doing nothing"
  else
    echo "Start-up: Init Database $CFG_DB_NAME"
    psql --single-transaction --echo-all --file=/gcti/cfg/sql_scripts/postgre/init_multi_postgre.sql
    psql --single-transaction --echo-all --file=/gcti/cfg/sql_scripts/postgre/CfgLocale_postgre.sql
    ENC_PASS=$(echo -n "$DEFAULT_PASSWORD" | md5sum | awk '{ print $1 }')
    #echo "Start-up: Init Default password: '$DEFAULT_PASSWORD' '${ENC_PASS^^}'"
    psql -c "UPDATE cfg_person SET password='${ENC_PASS^^}' , salted_string=NULL WHERE dbid=100;"
  fi
fi
if [ "$DB_TYPE" = "mssql" ]; then
  . /gcti/script/mssql.sh
  Create_Mssql_Database "$DB_HOST" "$DB_PORT" "$DB_USER" "$DB_PASS" "$CFG_DB_NAME"

fi
#TODO use confserv -preparedb and set config file
#TODO allow other name via -s params
#TODO support others database engine
#TODO support multi-lang ?

#TODO check for a configured file fir .config file ?
#Change lang support
#sed -i 's/langid = 1033/#langid = 1033/' /gcti/cfg/confserv.conf
#TODO Change DB config

sed -i 's/Password=default/Password='$DEFAULT_PASSWORD'/g' /gcti/cfg/confserv.conf
#Run prog in arg
exec $*
