#!/bin/sh

. /gcti/script/lca.sh

# Start LCA
Genesys_Start_LCA 4999

#Wait_For_Port "$DB_HOST" "$DB_PORT" "database ($DB_TYPE)"
#TODO setup host in GAX when ready
#TODO edit
cp /run/secrets/license.dat /gcti/flexlm/license.dat
MAC_ADDRESS=$(cat /sys/class/net/eth0/address)
sed -i "1s/.*/SERVER flexlm ${MAC_ADDRESS//:} 7260/" /gcti/flexlm/license.dat
sed -i "2s/.*/DAEMON genesys.d .\//" /gcti/flexlm/license.dat

head /gcti/flexlm/license.dat

exec $*
