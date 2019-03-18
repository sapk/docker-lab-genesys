#!/bin/sh

. /gcti/script/lca.sh

# Start LCA
Genesys_Start_LCA 4999

echo "Start-up: starting command : $*"
#Run prog in arg
exec $*