#!/bin/sh

. /gcti/script/network.sh
. /gcti/script/postgres.sh
. /gcti/script/lca.sh
. /gcti/script/gax.sh

#TODO check mandatory env
#TODO add language pack

#Wait for database
Wait_For_Port "$DB_HOST" "$DB_PORT" "database ($DB_TYPE)"

#Wait for CFG for everythings (be sure that db is ready for more)
Wait_For_Port "$CFG_HOST" "$CFG_PORT" "ConfigServer"

# Start LCA
Genesys_Start_LCA 4999

#Setup GAX if needed
# 1) Create GAX database if needed

if [ "$DB_TYPE" = "postgre" ]; then
  Create_Postgres_Database "$DB_HOST" "$DB_PORT" "$DB_USER" "$DB_PASS" "$GAX_DB_NAME"
fi

# 2) Use API to install from localhost

#Wait for ConfigServer (maybe not needed)
Wait_For_Port "$CFG_HOST" "$CFG_PORT" "ConfigServer"

sleep 3 # wait for 3 sec for config server to be fully op

if [ ! -f /gcti/gax/conf/gax.properties ]; then
  echo "Start-up: GAX configuration starting ..."

  nohup /gcti/gax/gax_startup.sh &

  Wait_For_Port "localhost" "8080" "GAX"

  sleep 3 # wait for 3 sec for gax server to be fully op

  #Login root
  #curl_get 'http://localhost:8080/gax/api/session/login' --cookie-jar /tmp/init-cookie -H 'Content-Type: application/json' --data '{"username":"root","password":"","isPasswordEncrypted":true}'
  cookieFile=$(Genesys_Gax_Login 'localhost:8080' 'root' '')
  echo "Start-up: Using cookie file: '$cookieFile'"

  #Get current user info
  echo "Start-up: Logged as : $(Genesys_Gax_CurrentUser "$cookieFile" localhost:8080)"
  #Get cfg config
  #curl_get 'http://localhost:8080/gax/api/cfg/schema'
  # TODO ConfigServerHost seems undefined
  #/gax/api/system/settings/system
  #/gax/api/options/general
  #/gax/api/system/info

  #Get gax version
  Genesys_Gax_Get "$cookieFile" 'http://localhost:8080/gax/api/version/'
  #Get setup configserver
  Genesys_Gax_Get "$cookieFile" 'http://localhost:8080/gax/api/system/settings/confserver'

  #Login config server #TODO use env
  Genesys_Gax_Post "$cookieFile" 'http://localhost:8080/gax/api/session/logincfg' --data '{"clientApplicationName":"default","confServerAddress":"'$CFG_HOST'","confServerPort":'$CFG_PORT',"username":"default","password":"'$DEFAULT_PASSWORD'"}'

  #Set config server #TODO use env
  Genesys_Gax_Put "$cookieFile" 'http://localhost:8080/gax/api/system/settings/confserver' --data '{"backupHost":"","backupHostPort":2020,"gaxApplication":"","primaryHost":"'$CFG_HOST'","primaryHostPort":'$CFG_PORT'}'

  #Validate
  Genesys_Gax_Get "$cookieFile" 'http://localhost:8080/gax/api/system/settings/confserver'

  #http://localhost:8080/gax/api/cfg/objects?brief=false&filters=subtype=CFGGenesysAdministratorServer+OR+subtype=CFGGenericServer&type=CfgAppPrototype
  #http://localhost:8080/gax/api/system/info
  #http://localhost:8080/gax/api/cfg/objects?type=CfgHost
  #http://localhost:8080/gax/api/cfg/objects?filters=subtype=CF
  # TODO create folder and organize
  # Create configserver host
  cfg_host_cfg=$(Genesys_Gax_CreateIfNotExist $cookieFile localhost:8080 '{"resources":{"resource":[]},"scsdbid":"0","folderid":"103","ostype":"CFGRedHatLinux","name":"'$CFG_HOST'","subtype":"CFGNetworkServer","lcaport":"4999","state":"CFGEnabled","ipaddress":"'$(getent hosts $CFG_HOST | awk '{ print $1 }')'","type":"CfgHost"}')
  echo "CFG Host: $cfg_host_cfg"
  # Create database host
  db_host_cfg=$(Genesys_Gax_CreateIfNotExist $cookieFile localhost:8080 '{"resources":{"resource":[]},"scsdbid":"0","folderid":"103","ostype":"CFGRedHatLinux","name":"'$DB_HOST'","subtype":"CFGNetworkServer","lcaport":"4999","state":"CFGEnabled","ipaddress":"'$(getent hosts $DB_HOST | awk '{ print $1 }')'","type":"CfgHost"}')
  echo "DB Host: $db_host_cfg"
  #Creation local LCA TODO install LCA ?
  gax_host_cfg=$(Genesys_Gax_CreateCurrentHost $cookieFile localhost:8080)
  echo "GAX Host: $gax_host_cfg"

  #If needed
  if Genesys_Gax_CheckObjIfNotExist $cookieFile localhost:8080 CfgApplication "$GAX_CFG_APP"; then
      #Create app template
      gax_template=$(Genesys_Gax_Put "$cookieFile" 'http://localhost:8080/gax/api/asd/action/creategaxtemplate')
      echo "GAX Template: $gax_template"
      #Create application
      gax_app=$(Genesys_Gax_CreateIfNotExist $cookieFile localhost:8080 '{"port":"8080","resources":{"resource":[]},"backupserverdbid":"0","commandline":"./gax_startup.sh","state":"CFGEnabled","appservers":{"conninfo":[]},"appprototypedbid":"'$(echo $gax_template | jq -r '.dbid')'","portinfos":{"portinfo":[{"longfield1":"0","id":"default","port":"8080","longfield4":"0","longfield3":"0","longfield2":"0"}]},"type":"CfgApplication","shutdowntimeout":"90","version":"8.5.260.14","workdirectory":"/gcti/gax","attempts":"1","name":"'$GAX_CFG_APP'","redundancytype":"CFGHTColdStanby","hostdbid":"'$(echo $gax_host_cfg | jq -r '.dbid')'","options":{"property":[{"section":"general","value":"true","key":"auditing"},{"section":"general","value":"default","key":"client_app_name"},{"section":"general","value":"100","key":"default_account_dbid"},{"section":"general","value":"600","key":"inactivity_timeout"},{"section":"general","value":"900","key":"session_timeout"},{"section":"general","value":"1","key":"scs_attempts"},{"section":"general","value":"10","key":"scs_timeout"},{"section":"general","value":"60","key":"scs_warmstandby_timeout"},{"section":"general","value":"1","key":"msgsrv_attempts"},{"section":"general","value":"10","key":"msgsrv_timeout"},{"section":"general","value":"60","key":"msgsrv_warmstandby_timeout"},{"section":"general","value":"false","key":"exclude_mmswitch"},{"section":"arm","value":"announcement","key":"local_announcement_folder"},{"section":"arm","value":"music","key":"local_music_folder"},{"section":"arm","value":"/opt/gax/arm","key":"local_path"},{"section":"arm","value":"/usr/bin/sox","key":"local_sox_path"},{"section":"arm","value":"announcement","key":"target_announcement_folder"},{"section":"arm","value":"music","key":"target_music_folder"},{"section":"arm","value":"/mnt/arm/target","key":"target_path"},{"section":"arm","value":"false","key":"delete_from_db_after_processing"},{"section":"arm","value":"20","key":"max_upload_audio_file_size"},{"section":"asd","value":"./plugin.data/asd/gaxLocalCache","key":"local_ip_cache_dir"},{"section":"asd","value":"./plugin.data/asd/installation/genesys_silent_ini.xml","key":"silent_ini_path"},{"section":"ga","value":"http","key":"ga_protocol"},{"section":"ga","value":"80","key":"ga_port"},{"section":"ga","value":"default","key":"ga_appName"},{"section":"ga","value":"","key":"ga_host"},{"section":"log","value":"","key":"all"},{"section":"log","value":"stdout","key":"standard"},{"section":"log","value":"","key":"trace"},{"section":"log","value":"standard","key":"verbose"},{"section":"opm","value":"false","key":"write_json"},{"section":"security","value":"","key":"host_whitelist"},{"section":"security","value":"false","key":"host_whitelist_enabled"},{"section":"security","value":"true","key":"enable_un_cookie"},{"section":"clog","value":"5000","key":"maxlogs"},{"section":"clog","value":"100","key":"minlogs"},{"section":"com","value":"provisioning_flags","key":"exclude_clone"},{"value":"default","section":"general","key":"client_app_name"}]},"componenttype":"CFGAppComponentUnknown","folderid":"102","isprimary":"CFGTrue","startuptimeout":"90","commandlinearguments":"","subtype":"CFGGenesysAdministratorServer","autorestart":"CFGFalse","timeout":"10"}')
      echo "GAX App: $gax_app"

      #POST /gax/api/asd/action/verifydb {"user":"genesys","host":"database","port":"'$DB_PORT'","dbtype":"postgre","servicename":"GAX","password":"g3n3sys"}
      #echo "Start-up: verifydb"
      db_object='{"user":"'$DB_USER'","host":"'$DB_HOST'","port":"'$DB_PORT'","dbtype":"'$DB_TYPE'","servicename":"'$GAX_DB_NAME'","password":"'$DB_PASS'"}'
      verifydb=$(Genesys_Gax_Post "$cookieFile" 'http://localhost:8080/gax/api/asd/action/verifydb' --data $db_object)
      echo "verifydb: $verifydb"

      #POST /gax/api/asd/action/verifygaxdb {"user":"genesys","host":"database","port":"'$DB_PORT'","dbtype":"postgre","servicename":"GAX","password":"g3n3sys"}
      # {"result":0}
      #echo "Start-up: verifygaxdb"
      verifygaxdb=$(Genesys_Gax_Post "$cookieFile" 'http://localhost:8080/gax/api/asd/action/verifygaxdb' --data $db_object | jq -r '.result')
      echo "verifygaxdb: $verifygaxdb"

      if [ "$verifygaxdb" = "0" ]; then
        echo "Start-up: initialgaxdb"
        #POST /gax/api/asd/action/initialgaxdb  {"user":"genesys","host":"database","port":"'$DB_PORT'","dbtype":"postgre","servicename":"GAX","password":"g3n3sys"}
        initialgaxdb=$(Genesys_Gax_Post "$cookieFile" 'http://localhost:8080/gax/api/asd/action/initialgaxdb' --data $db_object)
        echo "initialgaxdb: $initialgaxdb"
      fi

      #Create DAP template for GAX database
      #POST /gax/api/cfg/objects {"folderid":"101","subtype":"CFGDBServer","name":"DAP_Template_byGAX","state":"CFGEnabled","type":"CfgAppPrototype","version":"8.0.3"}
      dap_template=$(Genesys_Gax_CreateIfNotExist $cookieFile localhost:8080 '{"folderid":"101","subtype":"CFGDBServer","name":"DAP","state":"CFGEnabled","type":"CfgAppPrototype","version":"8.0.3"}')
      echo "DAP Template: $dap_template"
      #
      #Create DAP for GAX database get dbid from previous
      #POST /gax/api/cfg/objects
      dap_gax=$(Genesys_Gax_CreateIfNotExist $cookieFile localhost:8080 '{"port":"'$DB_PORT'","resources":{"resource":[]},"backupserverdbid":"0","commandline":".","state":"CFGEnabled","appservers":{"conninfo":[]},"appprototypedbid":"'$(echo $dap_template | jq -r '.dbid')'","portinfos":{"portinfo":[{"longfield1":"0","id":"default","port":"'$DB_PORT'","longfield4":"0","longfield3":"0","longfield2":"0"}]},"type":"CfgApplication","shutdowntimeout":"90","version":"8.0.3","userproperties":{"property":[{"value":"false","section":"default","key":"JdbcDebug"},{"value":"0","section":"default","key":"QueryTimeout"},{"value":"Main","section":"default","key":"Role"},{"value":"JDBC","section":"default","key":"connection_type"},{"value":"0","section":"default","key":"db-request-timeout"},{"value":"any","section":"default","key":"dbcase"},{"value":"'$DB_TYPE'","section":"default","key":"dbengine"},{"value":"'$GAX_DB_NAME'","section":"default","key":"dbname"},{"value":"","section":"default","key":"dbserver"},{"value":"'$DB_PASS'","section":"default","key":"password"},{"value":"'$DB_USER'","section":"default","key":"username"}]},"workdirectory":".","attempts":"1","name":"DAP_GAX","redundancytype":"CFGHTColdStanby","hostdbid":"'$(echo $db_host_cfg | jq -r '.dbid')'","options":{"property":[{"value":"main","section":"GAX","key":"role"}]},"componenttype":"CFGAppComponentUnknown","folderid":"102","isprimary":"CFGTrue","startuptimeout":"90","commandlinearguments":".","subtype":"CFGDBServer","autorestart":"CFGTrue","timeout":"10"}')

      echo "DAP_GAX: $dap_gax"
      #Mise à jour de GAX app
      #PUT /gax/api/cfg/objects/CfgApplication/104
      #echo "GAX APP ID : $(echo $gax_app | jq -r ' .dbid')"
      #echo "DAP GAX ID : $(echo $dap_gax | jq -r '.dbid')"
      #echo "GAX HOST ID : $(echo $gax_host_cfg | jq -r '.dbid')"
      #echo "GAX TEMPLATE ID : $(echo $gax_template | jq -r '.dbid')"

      #echo "URL : http://localhost:8080/gax/api/cfg/objects/CfgApplication/$(echo $gax_app | jq -r '.dbid')"
      data='{"appservers":{"conninfo":[{"longfield1":"0","id":"default","timoutlocal":"0","longfield4":"0","longfield3":"0","longfield2":"0","appserverdbid":"'$(echo $dap_gax | jq -r '.dbid')'","mode":"CFGTMNoTraceMode","timoutremote":"0"}]},"autorestart":"CFGFalse","type":"CfgApplication","timeout":"10","commandline":"./gax_startup.sh","folderid":"102","subtype":"CFGGenesysAdministratorServer","options":{"property":[{"section":"general","value":"true","key":"auditing"},{"section":"general","value":"default","key":"client_app_name"},{"section":"general","value":"100","key":"default_account_dbid"},{"section":"general","value":"600","key":"inactivity_timeout"},{"section":"general","value":"900","key":"session_timeout"},{"section":"general","value":"1","key":"scs_attempts"},{"section":"general","value":"10","key":"scs_timeout"},{"section":"general","value":"60","key":"scs_warmstandby_timeout"},{"section":"general","value":"1","key":"msgsrv_attempts"},{"section":"general","value":"10","key":"msgsrv_timeout"},{"section":"general","value":"60","key":"msgsrv_warmstandby_timeout"},{"section":"general","value":"false","key":"exclude_mmswitch"},{"section":"arm","value":"announcement","key":"local_announcement_folder"},{"section":"arm","value":"music","key":"local_music_folder"},{"section":"arm","value":"/opt/gax/arm","key":"local_path"},{"section":"arm","value":"/usr/bin/sox","key":"local_sox_path"},{"section":"arm","value":"announcement","key":"target_announcement_folder"},{"section":"arm","value":"music","key":"target_music_folder"},{"section":"arm","value":"/mnt/arm/target","key":"target_path"},{"section":"arm","value":"false","key":"delete_from_db_after_processing"},{"section":"arm","value":"20","key":"max_upload_audio_file_size"},{"section":"asd","value":"./plugin.data/asd/gaxLocalCache","key":"local_ip_cache_dir"},{"section":"asd","value":"./plugin.data/asd/installation/genesys_silent_ini.xml","key":"silent_ini_path"},{"section":"ga","value":"http","key":"ga_protocol"},{"section":"ga","value":"80","key":"ga_port"},{"section":"ga","value":"default","key":"ga_appName"},{"section":"ga","value":"","key":"ga_host"},{"section":"log","value":"","key":"all"},{"section":"log","value":"stdout","key":"standard"},{"section":"log","value":"","key":"trace"},{"section":"log","value":"standard","key":"verbose"},{"section":"opm","value":"false","key":"write_json"},{"section":"security","value":"","key":"host_whitelist"},{"section":"security","value":"false","key":"host_whitelist_enabled"},{"section":"security","value":"true","key":"enable_un_cookie"},{"section":"clog","value":"5000","key":"maxlogs"},{"section":"clog","value":"100","key":"minlogs"},{"section":"com","value":"provisioning_flags","key":"exclude_clone"}]},"state":"CFGEnabled","hostdbid":"'$(echo $gax_host_cfg | jq -r '.dbid')'","attempts":"1","portinfos":{"portinfo":[{"longfield1":"0","longfield2":"0","longfield3":"0","port":"8080","longfield4":"0","id":"default"}]},"workdirectory":"/gcti/gax","startuptype":"CFGSUTAutomatic","isserver":"CFGTrue","resources":{"resource":[]},"startuptimeout":"90","backupserverdbid":"0","version":"8.5.260.14","isprimary":"CFGTrue","redundancytype":"CFGHTColdStanby","shutdowntimeout":"90","componenttype":"CFGAppComponentUnknown","appprototypedbid":"'$(echo $gax_template | jq -r '.dbid')'","port":"8080","dbid":"'$(echo $gax_app | jq -r '.dbid')'","name":"'$GAX_CFG_APP'"}'
      echo "DATA : $data"
      gax_app=$(Genesys_Gax_Put "$cookieFile" "http://localhost:8080/gax/api/cfg/objects/CfgApplication/$(echo $gax_app | jq -r '.dbid')" --data "$data")
      echo "GAX App: $gax_app"

      #echo "DEBUG : application"
      #curl_get 'http://localhost:8080/gax/api/cfg/objects?type=CfgApplication' -b "$cookieFile" --cookie-jar "$cookieFile"
      confserv_app=$(Genesys_Gax_Get "$cookieFile" 'http://localhost:8080/gax/api/cfg/objects?brief=false&name=confserv&type=CfgApplication' | jq -c -r '.[0]')
      echo "CFG App: $confserv_app"
      #echo "EDIT"
      #echo $(echo $confserv_app | jq -r -c '.hostdbid = "'$(echo $cfg_host_cfg | jq -r '.dbid')'"')
      Genesys_Gax_Put "$cookieFile" "http://localhost:8080/gax/api/cfg/objects/CfgApplication/$(echo $confserv_app | jq -r '.dbid')" --data $(echo $confserv_app | jq -r -c '.hostdbid = "'$(echo $cfg_host_cfg | jq -r '.dbid')'"')


      echo "Cleaning a bit"
      Genesys_Gax_Delete "$cookieFile" "http://localhost:8080/gax/api/cfg/objects/CfgApplication/$(Genesys_Gax_Get "$cookieFile" 'http://localhost:8080/gax/api/cfg/objects?brief=false&name=Genesys%20Administrator%20Server&type=CfgApplication' | jq -c -r '.[0].dbid')"
      Genesys_Gax_Delete "$cookieFile" "http://localhost:8080/gax/api/cfg/objects/CfgApplication/$(Genesys_Gax_Get "$cookieFile" 'http://localhost:8080/gax/api/cfg/objects?brief=false&name=Genesys%20Administrator&type=CfgApplication' | jq -c -r '.[0].dbid')"
  fi

  #Set config server with setup app #TODO use env
  Genesys_Gax_Put "$cookieFile" 'http://localhost:8080/gax/api/system/settings/confserver' --data '{"backupHost":"","backupHostPort":2020,"gaxApplication":"'$GAX_DB_NAME'","primaryHost":"'$CFG_HOST'","primaryHostPort":'$CFG_PORT'}'
  #Validate
  Genesys_Gax_Get "$cookieFile" 'http://localhost:8080/gax/api/system/settings/confserver'


  #TODO clear app templates
  #http://localhost:8080/gax/api/cfg/tree/CfgAppPrototype

  #Reload gax (simply kill it)
  pkill java &
fi


sleep 3
echo "Start-up: starting command : $*"
#Run prog in arg
exec $*

#TODO start with -service GAX64 -immediate
#
