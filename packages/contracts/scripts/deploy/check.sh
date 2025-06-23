#!/bin/bash
source .env

target_network=$1
is_mainnet=false
if [ "$target_network" == "mainnet" ]; then
    is_mainnet=true
    RPC_URL=$ETHEREUM_ENDPOINT
    PRIVATE_KEY=$ETHEREUM_PRIVATE_KEY
    start_time=$ETHEREUM_START_TIME
else
    is_mainnet=false
    RPC_URL=$SEPOLIA_ENDPOINT
    PRIVATE_KEY=$SEPOLIA_PRIVATE_KEY
    start_time=$SEPOLIA_START_TIME
fi

start_timestamp=0
# Convert UTC datetime to timestamp if provided in format YYYY:MM:DD:HH:MM:SS
if [[ $start_time =~ ^[0-9]{4}:[0-9]{2}:[0-9]{2}:[0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
    # Convert YYYY:MM:DD:HH:MM:SS to YYYY-MM-DD HH:MM:SS format for date command
    formatted_datetime=$(echo $start_time | sed 's/:/ /g' | sed 's/\([0-9]\{4\}\) \([0-9]\{2\}\) \([0-9]\{2\}\) \([0-9]\{2\}\) \([0-9]\{2\}\) \([0-9]\{2\}\)/\1-\2-\3 \4:\5:\6/')
    # Use different date command syntax for macOS vs Linux
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS date command
        start_timestamp=$(date -j -f "%Y-%m-%d %H:%M:%S" "$formatted_datetime" +%s)
    else
        # Linux date command
        start_timestamp=$(date -u -d "$formatted_datetime" +%s)
    fi
    echo "Converted datetime to timestamp: $start_timestamp"
else
    # If not datetime format, assume it's already a timestamp
    start_timestamp=$start_time
fi

forge script scripts/deploy/check.s.sol:CheckStaking \
 --sig "run(bool,uint256)" $is_mainnet $start_timestamp \
 --rpc-url $RPC_URL \
 --private-key $PRIVATE_KEY \
 -v

