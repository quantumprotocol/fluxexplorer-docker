#!/usr/bin/env bash
#color codes
RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE="\\033[38;5;27m"
SEA="\\033[38;5;49m"
GREEN='\033[1;32m'
CYAN='\033[1;36m'
NC='\033[0m'

#emoji codes
CHECK_MARK="${GREEN}\xE2\x9C\x94${NC}"
X_MARK="${RED}\xE2\x9C\x96${NC}"
PIN="${RED}\xF0\x9F\x93\x8C${NC}"
CLOCK="${GREEN}\xE2\x8C\x9B${NC}"
ARROW="${SEA}\xE2\x96\xB6${NC}"
BOOK="${RED}\xF0\x9F\x93\x8B${NC}"
HOT="${ORANGE}\xF0\x9F\x94\xA5${NC}"
WORNING="${RED}\xF0\x9F\x9A\xA8${NC}"

BOOTSTRAP_ZIP='https://fluxnodeservice.com/flux_explorer_bootstrap.tar.gz'
BOOTSTRAP_ZIPFILE='flux_explorer_bootstrap.tar.gz'

function tar_file_unpack()
{
    echo -e "${ARROW} ${YELLOW}Unpacking bootstrap archive file...${NC}"
    pv $1 | tar -zx -C $2
}


if [[ ! -d /root/bitcore-node/bin ]]; then

echo -e "${ARROW} ${YELLOW}Installing dependencies...${NC}"
curl -sL https://deb.nodesource.com/setup_8.x | bash - > /dev/null 2>&1
apt-get install -y nodejs build-essential libzmq3-dev npm git > /dev/null 2>&1

#bitcore-node
cd /root/
bash flux-fetch-params.sh > /dev/null 2>&1 && sleep 2
echo -e "${ARROW} ${YELLOW}Installing bitcore-node...${NC}"
git clone https://github.com/runonflux/bitcore-node > /dev/null 2>&1
cd bitcore-node
npm install > /dev/null 2>&1
cd bin
chmod +x bitcore-node
./bitcore-node create mynode > /dev/null 2>&1
cd mynode
rm bitcore-node.json
echo -e "${ARROW} ${YELLOW}Creating bitcore-node config file...${NC}"
cat << EOF > bitcore-node.json
{
  "network": "livenet",
  "port": 3001,
  "services": [
    "bitcoind",
    "insight-api",
    "insight-ui",
    "web"
  ],
  "messageLog": "",
  "servicesConfig": {
      "web": {
      "disablePolling": false,
      "enableSocketRPC": false
    },
    "bitcoind": {
      "sendTxLog": "./data/pushtx.log",
      "spawn": {
        "datadir": "./data",
        "exec": "fluxd",
        "rpcqueue": 1000,
        "rpcport": 16124,
        "zmqpubrawtx": "tcp://127.0.0.1:28332",
        "zmqpubhashblock": "tcp://127.0.0.1:28332"
      }
    },
    "insight-api": {
        "routePrefix": "api",
                 "db": {
                   "host": "fluxmongodb_explorerflux",
                   "port": "27017",
                   "database": "flux-api-livenet",
                   "user": "",
                   "password": ""
          },
          "disableRateLimiter": true
    },
    "insight-ui": {
        "apiPrefix": "api",
        "routePrefix": ""
    }
  }
}
EOF

cp /usr/local/bin/fluxd /root/bitcore-node/bin/fluxd
chmod +x /root/bitcore-node/bin/fluxd
cd data
echo -e "${ARROW} ${YELLOW}Creating flux daemon config file...${NC}"
cat << EOF > flux.conf
server=1
whitelist=127.0.0.1
txindex=1
addressindex=1
timestampindex=1
spentindex=1
insightexplorer=1
experimentalfeatures=1
zmqpubrawtx=tcp://127.0.0.1:28332
zmqpubhashblock=tcp://127.0.0.1:28332
rpcport=16124
rpcallowip=127.0.0.1
rpcuser=flux
rpcpassword=myfluxpassword
uacomment=bitcore
mempoolexpiry=24
rpcworkqueue=1100
maxmempool=2000
dbcache=1000
maxtxfee=1.0
dbmaxfilesize=64
showmetrics=0
addnode=explorer.flux.zelcore.io
addnode=explorer.runonflux.io
addnode=explorer.zelcash.online
addnode=blockbook.runonflux.io
addnode=185.225.232.141:16125
addnode=95.216.124.220:16125
addnode=209.145.55.52:16125
addnode=78.113.97.147:16125
addnode=209.145.49.181:16125
EOF

if [[ "$BOOTSTRAP" == "1" ]]; then

  DB_HIGHT=$(curl -s -m 10 https://fluxnodeservice.com/flux_explorer_bootstrap.json | jq -r '.block_height')
  if [[ "$DB_HIGHT" == "" ]]; then
      DB_HIGHT=$(curl -s -m 10 https://fluxnodeservice.com/flux_explorer_bootstrap.json | jq -r '.block_height')
  fi

  if [[ "$DB_HIGHT" != "" ]]; then
    echo -e
    echo -e "${ARROW} ${CYAN}Flux daemon bootstrap height: ${GREEN}$DB_HIGHT${NC}"
    echo -e "${ARROW} ${YELLOW}Downloading File: ${GREEN}$BOOTSTRAP_ZIP ${NC}"
    wget --tries 5 -O $BOOTSTRAP_ZIPFILE $BOOTSTRAP_ZIP -q --no-verbose --show-progress --progress=dot:giga > /dev/null 2>&1
    tar_file_unpack "/root/bitcore-node/bin/mynode/data/$BOOTSTRAP_ZIPFILE" "/root/bitcore-node/bin/mynode/data"
    rm -rf /root/bitcore-node/bin/mynode/data/$BOOTSTRAP_ZIPFILE
    sleep 2
  fi

fi

cd /root/bitcore-node/bin/mynode/node_modules
echo -e "${ARROW} ${YELLOW}Installing insight-api && insight-ui...${NC}"
git clone https://github.com/runonflux/insight-api > /dev/null 2>&1
git clone https://github.com/runonflux/insight-ui > /dev/null 2>&1
cd insight-api
npm install > /dev/null 2>&1
cd ..
cd insight-ui
npm install > /dev/null 2>&1
fi

cd /root/bitcore-node/bin/mynode
while true; do
echo -e "${ARROW} ${YELLOW}Starting flux insight explorer...${NC}"
echo -e
../bitcore-node start
sleep 60
done
