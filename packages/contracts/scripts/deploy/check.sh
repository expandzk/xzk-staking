#!/bin/bash
source .env

target_network=$1
is_mainnet=false
is_dev=false
if [ "$target_network" == "ethereum" ]; then
    RPC_URL=$ETHEREUM_ENDPOINT
    PRIVATE_KEY=$ETHEREUM_PRIVATE_KEY
    is_mainnet=true
    is_dev=false
    start_time=$ETHEREUM_START_TIME
elif [ "$target_network" == "sepolia" ]; then
    RPC_URL=$SEPOLIA_ENDPOINT
    PRIVATE_KEY=$SEPOLIA_PRIVATE_KEY
    is_mainnet=false
    is_dev=false
    start_time=$SEPOLIA_START_TIME
elif [ "$target_network" == "dev" ]; then
    RPC_URL=$SEPOLIA_ENDPOINT
    PRIVATE_KEY=$SEPOLIA_PRIVATE_KEY
    is_mainnet=false
    is_dev=true
    start_time=$SEPOLIA_DEV_START_TIME
else
    echo "Usage: ./check.sh [dev|sepolia|ethereum]"
    exit 1
fi

if [ -z "$start_time" ]; then
    echo "Error: Start time is not set for network $target_network"
    exit 1
fi

# Convert UTC datetime to timestamp if provided in format YYYY:MM:DD:HH:MM:SS
if [[ $start_time =~ ^[0-9]{4}:[0-9]{2}:[0-9]{2}:[0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
    # Convert YYYY:MM:DD:HH:MM:SS to YYYY-MM-DD HH:MM:SS format for date command
    formatted_datetime=$(echo $start_time | sed 's/:/ /g' | sed 's/\([0-9]\{4\}\) \([0-9]\{2\}\) \([0-9]\{2\}\) \([0-9]\{2\}\) \([0-9]\{2\}\) \([0-9]\{2\}\)/\1-\2-\3 \4:\5:\6/')
    
    echo "Converting UTC datetime: $start_time to timestamp..."
    echo "Formatted datetime: $formatted_datetime"
    
    # Use different date command syntax for macOS vs Linux
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS date command - explicitly use UTC
        start_timestamp=$(date -j -u -f "%Y-%m-%d %H:%M:%S" "$formatted_datetime" +%s)
        if [ $? -ne 0 ]; then
            echo "Error: Failed to convert datetime to timestamp on macOS"
            exit 1
        fi
    else
        # Linux date command - explicitly use UTC
        start_timestamp=$(date -u -d "$formatted_datetime" +%s)
        if [ $? -ne 0 ]; then
            echo "Error: Failed to convert datetime to timestamp on Linux"
            exit 1
        fi
    fi
    echo "Converted UTC datetime to timestamp: $start_timestamp"
else
    echo "Error: Invalid start_time format: $start_time"
    echo "Expected format: YYYY:MM:DD:HH:MM:SS (UTC)"
    exit 1
fi

forge script scripts/deploy/check.s.sol:CheckStaking \
 --sig "run(bool,bool,uint256)" $is_mainnet $is_dev $start_timestamp \
 --rpc-url $RPC_URL \
 --private-key $PRIVATE_KEY \
 -vv

