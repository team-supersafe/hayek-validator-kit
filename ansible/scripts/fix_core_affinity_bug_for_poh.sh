#!/bin/bash

# Configuration
MAX_WAIT=3600  # 1 hour
SLEEP_INTERVAL=10
POH_THREAD_NAME="solPohTickProd"
TARGET_CORE=2

echo "--- PoH CPU Affinity Management ---"

# Find main agave-validator process
solana_pid=$(pgrep -f "agave-validator.*--identity")
if [ -z "$solana_pid" ]; then
    echo "Error: agave-validator process not found."
    logger "set_affinity: solana_validator_404"
    exit 1
fi

echo "Found agave-validator (PID: $solana_pid). Waiting for thread '$POH_THREAD_NAME'..."

ELAPSED=0
while true; do
    thread_pid=$(ps -T -p "$solana_pid" -o spid,comm | grep "$POH_THREAD_NAME" | awk '{print $1}')
    
    if [ -n "$thread_pid" ]; then
        echo "Found thread '$POH_THREAD_NAME' with SPID: $thread_pid"
        break
    fi

    if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
        echo "Error: Timeout waiting for $POH_THREAD_NAME after $MAX_WAIT seconds."
        logger "set_affinity: solPohTickProd_timeout"
        exit 2
    fi

    # Provide a status update every 60 seconds
    if [ $((ELAPSED % 60)) -eq 0 ] && [ "$ELAPSED" -ne 0 ]; then
        echo "Still waiting... ($ELAPSED seconds elapsed)"
    fi

    sleep "$SLEEP_INTERVAL"
    ELAPSED=$((ELAPSED + SLEEP_INTERVAL))
done

# Check and set affinity
current_affinity=$(taskset -cp "$thread_pid" | awk '{print $NF}')
affinity_tokens=$(echo "$current_affinity" | tr ',' ' ')
core_in_affinity=0

# Helper function to check if a value is numeric
is_numeric() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

for token in $affinity_tokens; do
    if [[ "$token" == *-* ]]; then
        start=${token%-*}
        end=${token#*-}
        if is_numeric "$start" && is_numeric "$end"; then
            if [ "$TARGET_CORE" -ge "$start" ] && [ "$TARGET_CORE" -le "$end" ]; then
                core_in_affinity=1
                break
            fi
        fi
    else
        if is_numeric "$token"; then
            if [ "$TARGET_CORE" -eq "$token" ]; then
                core_in_affinity=1
                break
            fi
        fi
    fi
done
if [ "$core_in_affinity" -eq 1 ]; then
    echo "Affinity for $POH_THREAD_NAME already set to include core $TARGET_CORE."
    logger "set_affinity: solPohTickProd_already_set"
    exit 0
else
    echo "Current affinity for $POH_THREAD_NAME: $current_affinity. Changing to core $TARGET_CORE..."
    if sudo -u sol taskset -cp "$TARGET_CORE" "$thread_pid" > /dev/null; then
        echo "Successfully set affinity to core $TARGET_CORE."
        logger "set_affinity: set_done"
        exit 0
    else
        echo "Error: Failed to set CPU affinity."
        logger "set_affinity: set_failed"
        exit 3
    fi
fi
