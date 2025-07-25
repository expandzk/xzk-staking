#!/bin/bash
source .env

target_network=$1
if [ "$target_network" == "ethereum" ]; then
    start_time=$ETHEREUM_START_TIME
    DAO_REGISTRY=0x33C044e4807ed822724F7c473502B00eD3bf7c7f
    PAUSE_ADMIN=0x0000000000000000000000000000000000000000
    XZK_TOKEN=0xe8fC52b1bb3a40fd8889C0f8f75879676310dDf0
    VXZK_TOKEN=0x16aFFA80C65Fd7003d40B24eDb96f77b38dDC96A
    total_factor_365=5500
    total_factor_180=2700
    total_factor_90=1300
    total_factor_flexible=500
elif [ "$target_network" == "sepolia" ]; then
    start_time=$SEPOLIA_START_TIME
    DAO_REGISTRY=0x0bF5B2d61BD12A6Ea08A4DC0ff35223d3A2d5698
    PAUSE_ADMIN=0x0000000000000000000000000000000000000000
    XZK_TOKEN=0x932161e47821c6F5AE69ef329aAC84be1E547e53
    VXZK_TOKEN=0xE662feEF4Bb1f25e5eBb4F9f157d37A921Af1587
    total_factor_365=5500
    total_factor_180=2700
    total_factor_90=1300
    total_factor_flexible=500   
elif [ "$target_network" == "dev" ]; then
    start_time=$SEPOLIA_DEV_START_TIME
    DAO_REGISTRY=0x0bF5B2d61BD12A6Ea08A4DC0ff35223d3A2d5698
    PAUSE_ADMIN=0x0000000000000000000000000000000000000000
    XZK_TOKEN=0x932161e47821c6F5AE69ef329aAC84be1E547e53
    VXZK_TOKEN=0xE662feEF4Bb1f25e5eBb4F9f157d37A921Af1587
    total_factor_3=4
    total_factor_2=3
    total_factor_1=2
    total_factor_dev_flexible=1
else
    echo "Usage: ./verify.sh [dev|sepolia|ethereum]"
    exit 1
fi

if [ -z "$start_time" ]; then
    echo "Error: Start time is not set for network $target_network"
    exit 1
fi

# Check if required environment variables are set
if [ -z "$ETHERSCAN_API_KEY" ]; then
    echo "Error: ETHERSCAN_API_KEY is not set"
    exit 1
fi

# Convert UTC datetime to timestamp if provided in format YYYY:MM:DD:HH:MM:SS
if [[ $start_time =~ ^[0-9]{4}:[0-9]{2}:[0-9]{2}:[0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
    # Convert YYYY:MM:DD:HH:MM:SS to YYYY-MM-DD HH:MM:SS format for date command
    formatted_datetime=$(echo $start_time | sed 's/:/ /g' | sed 's/\([0-9]\{4\}\) \([0-9]\{2\}\) \([0-9]\{2\}\) \([0-9]\{2\}\) \([0-9]\{2\}\) \([0-9]\{2\}\)/\1-\2-\3 \4:\5:\6/')
    
    echo "Converting UTC datetime: $start_time to timestamp..."
    echo "Formatted datetime: $formatted_datetime"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        start_timestamp=$(date -j -u -f "%Y-%m-%d %H:%M:%S" "$formatted_datetime" +%s)
        if [ $? -ne 0 ]; then
            echo "Error: Failed to convert datetime to timestamp on macOS"
            exit 1
        fi
    else
        start_timestamp=$(date -u -d "$formatted_datetime" +%s)
        if [ $? -ne 0 ]; then
            echo "Error: Failed to convert datetime to timestamp on Linux"
            exit 1
        fi
    fi
    echo "Converted UTC datetime to timestamp: $start_timestamp"
else
    echo "Error: Start time is not in the correct format"
    exit 1
fi

function verify_contract() {
    local token_address=$1
    local token_name=$2
    local symbol=$3
    local period=$4
    local total_factor=$5
    local contract=$6
    
    # Debug output
    echo "Verifying contract: $contract"
    echo "Token address: $token_address"
    echo "Token name: $token_name"
    echo "Symbol: $symbol"
    echo "Period: $period"
    echo "Total factor: $total_factor"
    echo "Start timestamp: $start_timestamp"
    
    if [ "$target_network" == "ethereum" ]; then
        chain_id=1
    else
        chain_id=11155111
    fi

    forge verify-contract --chain-id $chain_id -e $ETHERSCAN_API_KEY \
            --constructor-args $(cast abi-encode "constructor(address,address,address,string,string,uint256,uint256,uint256)" $DAO_REGISTRY $PAUSE_ADMIN $token_address "$token_name" "$symbol" $period $total_factor $start_timestamp) \
            $contract \
            XzkStaking --watch
}

if [ "$target_network" == "ethereum" ]; then
    verify_contract $XZK_TOKEN "Staking XZK 365 days" "sXZK-365d" 31536000 $total_factor_365 $ethereum_sXZK_365d 
    verify_contract $VXZK_TOKEN "Staking VXZK 365 days" "sVXZK-365d" 31536000 $total_factor_365 $ethereum_sVXZK_365d 
    verify_contract $XZK_TOKEN "Staking XZK 180 days" "sXZK-180d" 15552000 $total_factor_180 $ethereum_sXZK_180d
    verify_contract $VXZK_TOKEN "Staking VXZK 180 days" "sVXZK-180d" 15552000 $total_factor_180 $ethereum_sVXZK_180d
    verify_contract $XZK_TOKEN "Staking XZK 90 days" "sXZK-90d" 7776000 $total_factor_90 $ethereum_sXZK_90d
    verify_contract $VXZK_TOKEN "Staking VXZK 90 days" "sVXZK-90d" 7776000 $total_factor_90 $ethereum_sVXZK_90d
    verify_contract $XZK_TOKEN "Staking XZK Flexible" "sXZK-Flex" 0 $total_factor_flexible $ethereum_sXZK_Flex
    verify_contract $VXZK_TOKEN "Staking VXZK Flexible" "sVXZK-Flex" 0 $total_factor_flexible $ethereum_sVXZK_Flex
elif [ "$target_network" == "sepolia" ]; then
    verify_contract $XZK_TOKEN "Staking XZK 365 days" "sXZK-365d" 31536000 $total_factor_365 $sepolia_sXZK_365d
    verify_contract $VXZK_TOKEN "Staking VXZK 365 days" "sVXZK-365d" 31536000 $total_factor_365 $sepolia_sVXZK_365d
    verify_contract $XZK_TOKEN "Staking XZK 180 days" "sXZK-180d" 15552000 $total_factor_180 $sepolia_sXZK_180d
    verify_contract $VXZK_TOKEN "Staking VXZK 180 days" "sVXZK-180d" 15552000 $total_factor_180 $sepolia_sVXZK_180d
    verify_contract $XZK_TOKEN "Staking XZK 90 days" "sXZK-90d" 7776000 $total_factor_90 $sepolia_sXZK_90d
    verify_contract $VXZK_TOKEN "Staking VXZK 90 days" "sVXZK-90d" 7776000 $total_factor_90 $sepolia_sVXZK_90d
    verify_contract $XZK_TOKEN "Staking XZK Flexible" "sXZK-Flex" 0 $total_factor_flexible $sepolia_sXZK_Flex
    verify_contract $VXZK_TOKEN "Staking VXZK Flexible" "sVXZK-Flex" 0 $total_factor_flexible $sepolia_sVXZK_Flex
elif [ "$target_network" == "dev" ]; then
    verify_contract $XZK_TOKEN "Staking XZK 3" "sXZK-3" 3600 $total_factor_3 $sepolia_dev_sXZK_3
    verify_contract $VXZK_TOKEN "Staking VXZK 3" "sVXZK-3" 3600 $total_factor_3 $sepolia_dev_sVXZK_3
    verify_contract $XZK_TOKEN "Staking XZK 2" "sXZK-2" 1800 $total_factor_2 $sepolia_dev_sXZK_2
    verify_contract $VXZK_TOKEN "Staking VXZK 2" "sVXZK-2" 1800 $total_factor_2 $sepolia_dev_sVXZK_2
    verify_contract $XZK_TOKEN "Staking XZK 1" "sXZK-1" 600 $total_factor_1 $sepolia_dev_sXZK_1
    verify_contract $VXZK_TOKEN "Staking VXZK 1" "sVXZK-1" 600 $total_factor_1 $sepolia_dev_sVXZK_1
    verify_contract $XZK_TOKEN "Staking XZK Flexible" "sXZK-Flex" 0 $total_factor_dev_flexible $sepolia_dev_sXZK_Flex
    verify_contract $VXZK_TOKEN "Staking VXZK Flexible" "sVXZK-Flex" 0 $total_factor_dev_flexible $sepolia_dev_sVXZK_Flex
fi
