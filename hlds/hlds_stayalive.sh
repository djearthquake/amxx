#!/bin/bash

# --- CONFIGURATION ---
SERVER_IP=$(hostname -I | cut -f1 -d' ')   # SPiNX Auto-IP detection
CHECK_INTERVAL=5                           # Check every 5 seconds
BINARY_NAME="hlds_linux"                   # Exact name of your server executable
MAX_STRIKES=3                              # Number of failures before killing process
# ---------------------

echo "[WATCHDOG] Initializing Multi-Port Auto-Scanner..."
echo "[WATCHDOG] Detected Server IP: $SERVER_IP"
echo "[WATCHDOG] Strike threshold set to: $MAX_STRIKES"

# Create associative arrays to track independent failure counters for each port
declare -A FAIL_COUNTS

while true; do
    # AUTO-SCAN: Dynamically find all UDP ports currently held open by hlds_linux
    # It parses lsof output to find numbers after the ':' in the name column
    AUTO_PORTS=$(lsof -i udp -a -c "$BINARY_NAME" -F n 2>/dev/null | grep -o ':[0-9]*' | tr -d ':' | sort -u)

    if [ -z "$AUTO_PORTS" ]; then
        echo "[WATCHDOG] No active HLDS game servers detected on the machine. Waiting..."
        sleep "$CHECK_INTERVAL"
        continue
    fi

    # Loop through every port discovered during the auto-scan pass
    for SERVER_PORT in $AUTO_PORTS; do
        
        # Pull the specific PID managing this exact port wrapper instance
        PID=$(lsof -i udp:"$SERVER_PORT" -t 2>/dev/null)
        
        if [ -z "$PID" ]; then
            continue
        fi

        # Initialize the failure strike count tracker for this port if it is brand new
        if [ -z "${FAIL_COUNTS[$SERVER_PORT]}" ]; then
            FAIL_COUNTS[$SERVER_PORT]=0
        fi

        # Execute the 2-step Valve player database challenge handshake in Python
        PLAYER_DATA=$(python3 -c "
import socket
try:
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.settimeout(1.2)
    server_addr = ('$SERVER_IP', $SERVER_PORT)
    sock.sendto(b'\xff\xff\xff\xff\x55\xff\xff\xff\xff', server_addr)
    res, _ = sock.recvfrom(1400)
    if res[:5] == b'\xff\xff\xff\xff\x41':
        challenge_token = res[5:9]
        sock.sendto(b'\xff\xff\xff\xff\x55' + challenge_token, server_addr)
        player_res, _ = sock.recvfrom(4096)
        if player_res[:5] == b'\xff\xff\xff\xff\x44':
            count = player_res[5]
            print(f'OK|{count}')
        else: print('ERROR')
    else: print('ERROR')
except Exception:
    print('TIMEOUT')
" 2>/dev/null)

        # Parse the Python communication strings safely
        STATUS=$(echo "$PLAYER_DATA" | cut -d'|' -f1)
        P_COUNT=$(echo "$PLAYER_DATA" | cut -d'|' -f2)

        if [ "$STATUS" != "OK" ]; then
            # Increment the strike specific to this isolated port index channel
            FAIL_COUNTS[$SERVER_PORT]=$(( ${FAIL_COUNTS[$SERVER_PORT]} + 1 ))
            echo "[WATCHDOG][PORT $SERVER_PORT] No response! Status: $STATUS (Failure ${FAIL_COUNTS[$SERVER_PORT]}/$MAX_STRIKES)"
            
            # If THIS specific port hits max strikes, drop the hammer on its unique PID
            if [ "${FAIL_COUNTS[$SERVER_PORT]}" -ge "$MAX_STRIKES" ]; then
                echo "[WATCHDOG][PORT $SERVER_PORT] CONFIRMED FROZEN! Target-killing PID $PID..."
                kill -9 "$PID"
                FAIL_COUNTS[$SERVER_PORT]=0
            fi
        else
            # Reset strike tracking metrics for this port channel upon success
            FAIL_COUNTS[$SERVER_PORT]=0
            echo "[WATCHDOG][PORT $SERVER_PORT] Server Healthy | PID: $PID | Players: $P_COUNT"
        fi
    done

    echo "--------------------------------------------------------"
    sleep "$CHECK_INTERVAL"
done
