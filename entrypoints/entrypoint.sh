#!/usr/bin/env bash
set -e

# ensure the users has specified the required environment variables
if [ -z "$NETWORK" ]; then
    echo "Please specify the desired network you want to connect to"
    exit 1
fi

if [ -z "$MONIKER" ]; then
    echo "Please specify the desired moniker for your node"
    exit 1
fi

echo "Fetching configuration for $NETWORK network"

# constants
temporary_bootstrap_file="/tmp/.agrod-bootstrap.json"
bootstrap_url="https://raw.githubusercontent.com/fetchai/networks-$NETWORK/feature/next/bootstrap/boostrap.json"

# download the bootstrap file
curl -sS $bootstrap_url > $temporary_bootstrap_file

# extract the required parameters from the bootstrap file
seed_args=$(cat $temporary_bootstrap_file | jq -r ".args")
chain_id=$(cat $temporary_bootstrap_file | jq -r ".chainid")
rpc_url=$(cat $temporary_bootstrap_file | jq -r ".rpc")

# clean up
rm $temporary_bootstrap_file

echo "Moniker...: $MONIKER"
echo "Network...: $NETWORK"
echo "Chain ID..: $chain_id"
echo "RPC Url...: $rpc_url"
echo "Args......: $seed_args ${ARGS}"

# detect if initial init is required
if [ ! -f ~/.agrod/config/genesis.json ]; then

    # init the chain
    agrod init "$MONIKER" --chain-id "${chain_id}"

    # download the correct genesis file
    curl "$rpc_url/genesis" | jq .result.genesis > ~/.agrod/config/genesis.json

    # ensure configuration if correct
    sed -i 's/allow_duplicate_ip = false/allow_duplicate_ip = true/' ~/.agrod/config/config.toml
fi

# check for user specific configuration
if [ -f "/root/secret-temp-config/config/config.toml" ]; then
   cp -R /root/secret-temp-config/* /root/.agrod/
fi

# run the daemon
exec agrod start ${seed_args} ${ARGS}
