# Check if .env file exists and source it
if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found. Please create a .env file with required environment variables."
    exit 1
fi

target_network=$1
start_timestamp=0
# Select the network based on the input parameter
if [ "$target_network" == "dev" ]; then
    RPC_URL=$SEPOLIA_ENDPOINT
    PRIVATE_KEY=$SEPOLIA_PRIVATE_KEY
    start_time=$SEPOLIA_DEV_START_TIME
    # Dev environment requires 10 minutes delay
    MIN_DELAY=600
elif [ "$target_network" == "sepolia" ]; then
    RPC_URL=$SEPOLIA_ENDPOINT
    PRIVATE_KEY=$SEPOLIA_PRIVATE_KEY
    start_time=$SEPOLIA_START_TIME
    # Production requires 5 day delay
    MIN_DELAY=432000
elif [ "$target_network" == "ethereum" ]; then
    RPC_URL=$ETHEREUM_ENDPOINT
    PRIVATE_KEY=$ETHEREUM_PRIVATE_KEY
    start_time=$ETHEREUM_START_TIME
    # Production requires 5 day delay
    MIN_DELAY=432000
else
    echo "Usage: ./deploy.sh [dev|sepolia|ethereum]"
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

# Get current UTC timestamp
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS: get current UTC timestamp
    current_time=$(date -u +%s)
else
    # Linux: get current UTC timestamp
    current_time=$(date -u +%s)
fi

# Check if start_timestamp is at least MIN_DELAY seconds later than current UTC time
if [ $start_timestamp -le $((current_time + MIN_DELAY)) ]; then
    if [ "$target_network" == "dev" ]; then
        echo "Error: Start time must be at least 30 minutes later than current UTC time"
    else
        echo "Error: Start time must be at least 1 day later than current UTC time"
    fi
    # Display times in UTC format
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Current UTC time: $(date -u -r $current_time '+%Y-%m-%d %H:%M:%S UTC')"
        echo "Start UTC time: $(date -u -r $start_timestamp '+%Y-%m-%d %H:%M:%S UTC')"
    else
        echo "Current UTC time: $(date -u -d @$current_time '+%Y-%m-%d %H:%M:%S UTC')"
        echo "Start UTC time: $(date -u -d @$start_timestamp '+%Y-%m-%d %H:%M:%S UTC')"
    fi
    echo "Please set a later start time"
    exit 1
fi


# Deploy the contract using Foundry
forge script scripts/deploy/Deploy.${target_network}.s.sol:DeployStaking \
 --sig "run(uint256)" $start_timestamp \
 --rpc-url $RPC_URL \
 --private-key $PRIVATE_KEY \
 --broadcast \
 -vv
