#!/bin/sh

#Usefull command to work with Genesys LCA

#TODO check deps like lca ^^

Genesys_Start_LCA () {
  local port=${1:-'4999'}
  
  echo "Start-up: Starting LCA to launch on port $port..."
  (cd /gcti/lca && echo "standard = stdout" >> lca.cfg && nohup /gcti/lca/lca "$port" &)
}
