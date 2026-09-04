#!/bin/bash

# --- CONFIGURATION ---
SERVER_IP=$(hostname -I | cut -f1 -d' ')   # SPiNX Auto-IP detection
CHECK_INTERVAL=15                           # Check every 15 seconds
BINARY_NAME="hlds_linux"                   # Exact name of your server executable
MAX_STRIKES=5                              # Number of failures before killing process
# ---------------------

echo "[WATCHDOG] Initializing Multi-Port Auto-Scanner..."
echo "[WATCHDOG] Detected Server IP: $SERVER_IP"
echo "[WATCHDOG] Strike threshold set to: $MAX_STRIKES"

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
        PID=$(lsof -i udp:"$SERVER_PORT" -t 2>/dev/null | head -n 1)
        
        if [ -z "$PID" ]; then
            continue
        fi

        # Initialize the failure strike count tracker for this port if it is brand new
        if [ -z "${FAIL_COUNTS[$SERVER_PORT]}" ]; then
            FAIL_COUNTS[$SERVER_PORT]=0
        fi

        # FIXED: Handles the mandatory 0x41 (A) challenge reflection layer for A2S_INFO
        PLAYER_DATA=$(python3 -c "
import socket
import sys

try:
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.settimeout(2.5)
    server_addr = ('$SERVER_IP', $SERVER_PORT)
    
    # Step 1: Send initial A2S_INFO payload
    query_packet = b'\xff\xff\xff\xff\x54Source Engine Query\x00'
    sock.sendto(query_packet, server_addr)
    res, _ = sock.recvfrom(2048)
    
    # Case A: Server responds with an Anti-DDoS Challenge (0x41 / 'A')
    if res.startswith(b'\xff\xff\xff\xff\x41'):
        challenge_token = res[5:9]
        # Resend initial query with the explicit token appended
        sock.sendto(query_packet + challenge_token, server_addr)
        res, _ = sock.recvfrom(2048)
        
    # Case B: Direct or authenticated response (0x49 / 'I')
    if res.startswith(b'\xff\xff\xff\xff\x49'):
        # Byte index 6 contains player count in the GoldSource payload format
        p_count = res[6] if len(res) > 6 else 0
        print(f'OK|{p_count}')
        sys.exit(0)
        
    print('ERROR|0')
except Exception:
    print('TIMEOUT|0')
" 2>/dev/null)

        # Sanitize string output
        CLEAN_DATA=$(echo "$PLAYER_DATA" | tr -d '\r' | tr -d '\n')
        STATUS=$(echo "$CLEAN_DATA" | cut -d'|' -f1)
        P_COUNT=$(echo "$CLEAN_DATA" | cut -d'|' -f2)

        if [ "$STATUS" = "OK" ]; then
            FAIL_COUNTS[$SERVER_PORT]=0
            echo "[WATCHDOG][PORT $SERVER_PORT] Server Healthy | PID: $PID | Players: $P_COUNT"
        else
            FAIL_COUNTS[$SERVER_PORT]=$(( ${FAIL_COUNTS[$SERVER_PORT]} + 1 ))
            echo "[WATCHDOG][PORT $SERVER_PORT] Bad Pulse! Status: $STATUS (Strike ${FAIL_COUNTS[$SERVER_PORT]}/$MAX_STRIKES)"
            
            if [ "${FAIL_COUNTS[$SERVER_PORT]}" -ge "$MAX_STRIKES" ]; then
                echo "[WATCHDOG][PORT $SERVER_PORT] PROCESS DEADLOCK DETECTED! Terminating PID $PID..."
                kill -9 "$PID"
                FAIL_COUNTS[$SERVER_PORT]=0
            fi
        fi
    done

    echo "--------------------------------------------------------"
    sleep "$CHECK_INTERVAL"
done
