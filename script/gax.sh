#!/bin/sh

#Usefull command to work with Genesys GAX

#TODO check deps like curl and jq


#TODO verify that $@ doesn't contain the cookie file ?
function Genesys_Gax_Get {
  local cookie=${1:-'/tmp/init-cookie'}
  echo $(curl -s -b "$cookie" --cookie-jar "$cookie" "$@")
}
function Genesys_Gax_Post {
  local cookie=${1:-'/tmp/init-cookie'}
  echo $(curl -s -b "$cookie" --cookie-jar "$cookie" -H 'Content-Type: application/json' "$@")
}
function Genesys_Gax_Put {
  local cookie=${1:-'/tmp/init-cookie'}
  echo $(curl -s -b "$cookie" --cookie-jar "$cookie" -H 'Content-Type: application/json' -X PUT "$@")
}
function Genesys_Gax_Delete {
  local cookie=${1:-'/tmp/init-cookie'}
  echo $(curl -s -b "$cookie" --cookie-jar "$cookie" -H 'Content-Type: application/json' -X DELETE "$@")
}

function Genesys_Gax_Login {
  local gax_host=${1:-'localhost:8080'}
  local user=${2:-'default'}
  local pass=${3:-'password'}
  local isPasswordEncrypted=${4:-'false'}

  local cookieFile=$(mktemp /tmp/gax-cookie.XXXXXX)

  #echo "http://$gax_host/gax/api/session/login"
  #echo '{"username":"'$user'","password":"'$pass'","isPasswordEncrypted":'$isPasswordEncrypted'}'

  local result=$(curl -s "http://$gax_host/gax/api/session/login" --cookie-jar "$cookieFile" -H 'Content-Type: application/json' --data '{"username":"'$user'","password":"'$pass'","isPasswordEncrypted":'$isPasswordEncrypted'}')

  echo "$cookieFile"
}

function Genesys_Gax_CurrentUser {
  local cookie=${1:-'/tmp/init-cookie'}
  local gax_host=${2:-'localhost:8080'}
  echo $(Genesys_Gax_Get "$cookie" "http://$gax_host/gax/api/user/info")
}

function Wait_For_GAX {
  local gax_host=${1:-'localhost'}
  local port=${2:-'8080'}
  local timer=${3:-'2'}

  echo "Start-up: Waiting GAX to fully ready on $gax_host:$port..."
  while [ ''$(curl -s "http://$gax_host:$port/gax/api/cfg/schema" | jq '.isEnabled') != "true" ]; do
    sleep $timer # wait for 2 second before check again
  done
  echo "Start-up: GAX fully ready"
}

function Genesys_Gax_CreateOrUpdate {
  local cookie=${1:-'/tmp/init-cookie'}
  local gax_host=${2:-'localhost:8080'}
  local data=${3:-''}

  #TODO check data
  local name=$(echo $data | jq -r '.name')
  local type=$(echo $data | jq -r '.type')

  local req=$(Genesys_Gax_Get $cookie "http://$gax_host/gax/api/cfg/objects?brief=false&name=$name&type=$type")
  local nb=$(echo $req | jq -r 'length')
  #echo "Start-up: $name found : $nb"
  if [ "$nb" = "0" ]; then
    echo $(Genesys_Gax_Post "$cookie" "http://$gax_host/gax/api/cfg/objects" --data "$data")
  else
    local app=$(echo $req | jq -c -r '.[0]')
    echo $(Genesys_Gax_Put "$cookie" "http://$gax_host/gax/api/cfg/objects/CfgApplication/$(echo $app | jq -r '.dbid')" --data "$(echo $data | jq -r -c '.dbid = "'$(echo $app | jq -r '.dbid')'"')")
  fi
}

function Genesys_Gax_GetObj {
  local cookie=${1:-'/tmp/init-cookie'}
  local gax_host=${2:-'localhost:8080'}
  local type=${3:-'CfgApplication'}
  local name=${4:-'GAX'}

  local req=$(Genesys_Gax_Get $cookie "http://$gax_host/gax/api/cfg/objects?brief=false&name=$name&type=$type")
  local nb=$(echo $req | jq -r 'length')
  #echo "Start-up: $name found : $nb"
  if [ "$nb" = "0" ]; then
    echo '{}'
  else
    echo $req | jq -c -r '.[0]'
  fi
}

function Genesys_Gax_CheckObjIfNotExist {
  local cookie=${1:-'/tmp/init-cookie'}
  local gax_host=${2:-'localhost:8080'}
  local type=${3:-'CfgApplication'}
  local name=${4:-'GAX'}

  local req=$(Genesys_Gax_Get $cookie "http://$gax_host/gax/api/cfg/objects?brief=false&name=$name&type=$type")
  local nb=$(echo $req | jq -r 'length')
  #echo "Start-up: $name found : $nb"
  if [ "$nb" = "0" ]; then
    return 0
  else
    return 1
  fi
}

function Genesys_Gax_CreateIfNotExist {
  local cookie=${1:-'/tmp/init-cookie'}
  local gax_host=${2:-'localhost:8080'}
  local data=${3:-''}

  #TODO check data
  local name=$(echo $data | jq -r '.name')
  local type=$(echo $data | jq -r '.type')

  local req=$(Genesys_Gax_Get $cookie "http://$gax_host/gax/api/cfg/objects?brief=false&name=$name&type=$type")
  local nb=$(echo $req | jq -r 'length')
  #echo "Start-up: $name found : $nb"
  if [ "$nb" = "0" ]; then
    echo $(Genesys_Gax_Post "$cookie" "http://$gax_host/gax/api/cfg/objects" --data "$data")
  else
    echo $(echo $req | jq -c -r '.[0]')
  fi
}

function Genesys_Gax_CreateCurrentHost {
  local cookie=${1:-'/tmp/init-cookie'}
  local gax_host=${2:-'localhost:8080'}
  #TODO use Genesys_Gax_CreateIfNotExist
  #echo '{"resources":{"resource":[]},"scsdbid":"0","folderid":"103","ostype":"CFGRedHatLinux","name":"'$(hostname)'","subtype":"CFGNetworkServer","lcaport":"4999","state":"CFGEnabled","ipaddress":"'$(getent hosts $(hostname) | tail -n 1 | awk '{ print $1 }')'","type":"CfgHost"}'
  echo $(Genesys_Gax_CreateIfNotExist "$cookie" "$gax_host" '{"resources":{"resource":[]},"scsdbid":"0","folderid":"103","ostype":"CFGRedHatLinux","name":"'$(hostname)'","subtype":"CFGNetworkServer","lcaport":"4999","state":"CFGEnabled","ipaddress":"'$(getent hosts $(hostname) | tail -n 1 | awk '{ print $1 }')'","type":"CfgHost"}')
  #echo $(Genesys_Gax_CreateOrUpdate "$cookie" "$gax_host" '{"resources":{"resource":[]},"scsdbid":"0","folderid":"103","ostype":"CFGRedHatLinux","name":"'$(hostname)'","subtype":"CFGNetworkServer","lcaport":"4999","state":"CFGEnabled","ipaddress":"'$(getent hosts $(hostname) | tail -n 1 | awk '{ print $1 }')'","type":"CfgHost"}')
}


function Genesys_Gax_PushTemplateIfNeeded {
  local cookie=${1:-'/tmp/init-cookie'}
  local gax_host=${2:-'localhost:8080'}
  local file=${3:-''}

  local tmpl=$(Genesys_Gax_ParseAPD $cookie $gax_host $file.apd)
  #echo "tmpl : $tmpl"

  if Genesys_Gax_CheckObjIfNotExist $cookie $gax_host CfgAppPrototype "$(echo $tmpl | jq -r '.name')"; then

    #Default prototype folder #TODO ?
    #echo "tmpl : $tmpl"
    local tmpl=$(echo $tmpl | jq -r -c '.folderid = 101')
    #echo "tmpl : $tmpl"
    local template=$(Genesys_Gax_Post $cookie "http://$gax_host/gax/api/cfg/objects" --data "$tmpl" )
    #echo "Template : $template"

    #TODO make work metadata
    local meta=$(Genesys_Gax_ParseMetadata $cookie $gax_host $file.xml)
    #echo "Meta : $meta"
    #local meta=$(echo "$meta" | jq -r -c '.folderid = 101')
    #echo "Meta : $meta"
    local template_id=$(echo "$template" | jq -r '.dbid')
    #echo "Template ID : $template_id"
    meta=$(echo $meta | jq -r -c ".cfgDBid = $template_id" )
    #echo "Meta : $meta"
    local metadata=$(Genesys_Gax_Post $cookie "http://$gax_host/gax/api/cfg/appmetadata" --data "$meta")
    #echo "Metadata : $metadata"
    #echo $template
  fi
  #else
  echo $(Genesys_Gax_GetObj $cookie $gax_host CfgAppPrototype "$(echo $tmpl | jq -r '.name')")
  #fi
}

function Genesys_Gax_ParseMetadata {
  local cookie=${1:-'/tmp/init-cookie'}
  local gax_host=${2:-'localhost:8080'}
  local file=${3:-''}

  local script=$(Genesys_Gax_Get $cookie -F mpcontent=@$file "http://$gax_host/gax/api/cfg/option/CfgAppPrototype/import/xml/null?callback=callback")
  local json=$(echo $script | sed 's/<script>callback("//g' | sed 's/")<\/script>//g' | sed 's/\\"/"/g' | sed 's/\\\"/\\\\\"/g' |	jq 'del(.["type", "subtype", "version", "folderid"])')

  echo $json
}

function Genesys_Gax_ParseAPD {
  local cookie=${1:-'/tmp/init-cookie'}
  local gax_host=${2:-'localhost:8080'}
  local file=${3:-''}

  local script=$(Genesys_Gax_Get $cookie -F mpcontent=@$file "http://$gax_host/gax/api/cfg/option/CfgAppPrototype/import/apd?callback=callback")
  local json=$(echo $script | sed 's/<script>callback("//g' | sed 's/")<\/script>//g' | sed 's/\\"/"/g' | sed 's/\\\"/\\\\\"/g')

  echo $json
}

function Genesys_Gax_AddLink {
  local cookie=${1:-'/tmp/init-cookie'}
  local gax_host=${2:-'localhost:8080'}
  local name=${3:-'GAX'}
  local remote=${4:-'SolutionControlServer'}
  local remote_port_id=${5:-'default'}
  local timoutlocal=${6:-'10'}
  local timoutremote=${7:-'10'}

  local app=$(Genesys_Gax_Get $cookie "http://$gax_host/gax/api/cfg/objects?brief=false&name=$name&type=CfgApplication" | jq -c -r '.[0]')
  local remote_app=$(Genesys_Gax_Get $cookie "http://$gax_host/gax/api/cfg/objects?brief=false&name=$remote&type=CfgApplication" | jq -c -r '.[0]')
  #TODO check apps

  local app=$(echo $app | jq -r -c '.appservers.conninfo += [{"id":"'$remote_port_id'","connprotocol":"","appparams":"","timoutlocal":'$timoutlocal',"transportparams":"","appserverdbid":"'$(echo $remote_app | jq -r '.dbid')'","timoutremote":'$timoutremote',"mode":"CFGTMBoth"}]' )

  echo $(Genesys_Gax_Put "$cookie" "http://$gax_host/gax/api/cfg/objects/CfgApplication/$(echo $app | jq -r '.dbid')" --data "$app")
}
