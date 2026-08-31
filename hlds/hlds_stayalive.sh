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

        # IMPROVED: Robust Valve player challenge handshake
        PLAYER_DATA=$(python3 -c "
import socket
import sys

try:
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.settimeout(1.5)
    server_addr = ('$SERVER_IP', $SERVER_PORT)
    
    # Step 1: Send A2S_PLAYER request with dummy challenge (-1)
    sock.sendto(b'\xff\xff\xff\xff\x55\xff\xff\xff\xff', server_addr)
    res, _ = sock.recvfrom(1400)
    
    # Expecting A2S_SERVERCOMMAND (0x41) challenge response
    if res.startswith(b'\xff\xff\xff\xff\x41'):
        challenge_token = res[5:9]
        
        # Step 2: Send A2S_PLAYER request with the real token
        sock.sendto(b'\xff\xff\xff\xff\x55' + challenge_token, server_addr)
        player_res, _ = sock.recvfrom(65535)
        
        # Expecting A2S_PLAYER response (0x44)
        if player_res.startswith(b'\xff\xff\xff\xff\x44') and len(player_res) >= 6:
            count = player_res[5]
            print(f'OK|{count}')
            sys.exit(0)

    print('ERROR|0')
except Exception:
    print('TIMEOUT|0')
" 2>/dev/null)

        # Parse the Python communication strings safely
        STATUS=$(echo "$PLAYER_DATA" | cut -d'|' -f1)
        P_COUNT=$(echo "$PLAYER_DATA" | cut -d'|' -f2)

        if [ "$STATUS" = "OK" ]; then
            # Reset strike tracking metrics for this port channel upon success
            FAIL_COUNTS[$SERVER_PORT]=0
            echo "[WATCHDOG][PORT $SERVER_PORT] Server Healthy | PID: $PID | Players: $P_COUNT"
        else
            # Increment the strike specific to this isolated port index channel
            FAIL_COUNTS[$SERVER_PORT]=$(( ${FAIL_COUNTS[$SERVER_PORT]} + 1 ))
            echo "[WATCHDOG][PORT $SERVER_PORT] No response! Status: $STATUS (Failure ${FAIL_COUNTS[$SERVER_PORT]}/$MAX_STRIKES)"
            
            # If THIS specific port hits max strikes, drop the hammer on its unique PID
            if [ "${FAIL_COUNTS[$SERVER_PORT]}" -ge "$MAX_STRIKES" ]; then
                echo "[WATCHDOG][PORT $SERVER_PORT] CONFIRMED FROZEN! Target-killing PID $PID..."
                kill -9 "$PID"
                FAIL_COUNTS[$SERVER_PORT]=0
            fi
        fi
    done

    echo "--------------------------------------------------------"
    sleep "$CHECK_INTERVAL"
done
