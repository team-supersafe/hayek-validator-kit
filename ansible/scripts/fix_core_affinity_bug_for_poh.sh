#!/bin/bash
set -x

# wait to load the binary
#sleep 120

MAX_WAIT=3600  # seconds (1 hour)
SLEEP_INTERVAL=10
ELAPSED=0

# main pid of solana-validator
solana_pid=$(pgrep -f "^agave-validator --identity")
if [ -z "$solana_pid" ]; then
    logger "set_affinity: solana_validator_404"
    exit 1
fi

# Wait for solPohTickProd thread to appear
while true; do
    thread_pid=$(ps -T -p $solana_pid -o spid,comm | grep 'solPohTickProd' | awk '{print $1}')
    if [ -n "$thread_pid" ]; then
        break
    fi
    if [ $ELAPSED -ge $MAX_WAIT ]; then
        logger "set_affinity: solPohTickProd_timeout"
        exit 2
    fi
    sleep $SLEEP_INTERVAL
    ELAPSED=$((ELAPSED + SLEEP_INTERVAL))
done

current_affinity=$(taskset -cp $thread_pid 2>&1 | awk '{print $NF}')
if [ "$current_affinity" == "2" ]; then
    logger "set_affinity: solPohTickProd_already_set"
    exit 0
else
    # set poh to cpu2
    sudo taskset -cp 2 $thread_pid
    logger "set_affinity: set_done"
    exit 0
fi
