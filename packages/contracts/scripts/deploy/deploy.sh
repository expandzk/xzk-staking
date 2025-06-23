# Check if .env file exists and source it
if [ -f .env ]; then
    source .env
else
    echo "Warning: .env file not found. Creating empty environment variables."
    # Set empty values for environment variables
    export SEPOLIA_ENDPOINT=""
    export SEPOLIA_PRIVATE_KEY=""
    export ETHEREUM_ENDPOINT=""
    export ETHEREUM_PRIVATE_KEY=""
fi

target_network=$1
isMainnet=false
start_timestamp=0
# Select the network based on the input parameter
if [ "$target_network" == "sepolia" ]; then
    RPC_URL=$SEPOLIA_ENDPOINT
    PRIVATE_KEY=$SEPOLIA_PRIVATE_KEY
    isMainnet=false
    start_time=$SEPOLIA_START_TIME
elif [ "$target_network" == "ethereum" ]; then
    RPC_URL=$ETHEREUM_ENDPOINT
    PRIVATE_KEY=$ETHEREUM_PRIVATE_KEY
    isMainnet=true
    start_time=$ETHEREUM_START_TIME
else
    echo "Usage: ./deploy.sh [sepolia|ethereum]"
    exit 1
fi

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

# Get current timestamp
current_time=$(date +%s)

# Check if start_timestamp is at least 5 minutes (300 seconds) later than current time
if [ $start_timestamp -le $((current_time + 300)) ]; then
    echo "Error: Start time must be at least 5 minutes later than current time"
    # Display times in readable format
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Current time: $(date -r $current_time '+%Y-%m-%d %H:%M:%S')"
        echo "Start time: $(date -r $start_timestamp '+%Y-%m-%d %H:%M:%S')"
    else
        echo "Current time: $(date -u -d @$current_time '+%Y-%m-%d %H:%M:%S UTC')"
        echo "Start time: $(date -u -d @$start_timestamp '+%Y-%m-%d %H:%M:%S UTC')"
    fi
    echo "Please set a later start time"
    exit 1
fi


# Deploy the contract using Foundry
forge script scripts/deploy/Deploy.s.sol:DeployStaking \
 --sig "run(bool,uint256)" $isMainnet $start_timestamp \
 --rpc-url $RPC_URL \
 --private-key $PRIVATE_KEY \
 --broadcast \
 -vv
