#!/bin/bash

# --- CONFIGURATION ---
SERVER_IP=$(hostname -I | cut -f1 -d' ' | head -n 1)   # Your primary host IP
CHECK_INTERVAL=20                           # Check every 20 seconds
BINARY_NAME="hlds_linux"                   # Server executable name
MAX_STRIKES=20                              # Failures before warning/killing
LOG_FILE="/tmp/hlds_watchdog.log"          # Path to log file

# SAFE MODE CONTROL: 
# Set to true to ONLY log problems without killing. Set to false to enable killing.
SAFE_MODE=false
# ---------------------

log_message() {
    echo "$(date '+[%Y-%m-%d %H:%M:%S]') $1" | tee -a "$LOG_FILE"
}

# Initial scan to see what is online right now
INITIAL_PORTS=$(lsof -nP -i udp -a -c "$BINARY_NAME" -F n 2>/dev/null | grep -o ':[0-9]*' | tr -d ':' | sort -u | tr '\n' ' ')

# Startup verification log showing identified ports
log_message "[WATCHDOG] Started. Monitoring IP: $SERVER_IP | Safe Mode: $SAFE_MODE | Active Ports Noticed: [ ${INITIAL_PORTS:-None} ]"

declare -A FAIL_COUNTS

while true; do
    AUTO_PORTS=$(lsof -nP -i udp -a -c "$BINARY_NAME" -F n 2>/dev/null | grep -o ':[0-9]*' | tr -d ':' | sort -u)

    # SHORT-CIRCUIT SAFETY: If no ports are active anywhere, sleep and skip completely.
    # This prevents lsof from listing global processes when maps change or servers go down.
    if [ -z "$AUTO_PORTS" ]; then
        # Reset tracking memory safely since nothing is online
        for TRACKED_PORT in "${!FAIL_COUNTS[@]}"; do
            FAIL_COUNTS[$TRACKED_PORT]=0
        done
        sleep "$CHECK_INTERVAL"
        continue
    fi

    # --- SAFE PORT RESET LOGIC ---
    # Reset counters for ports that have dropped offline or changed maps cleanly
    for TRACKED_PORT in "${!FAIL_COUNTS[@]}"; do
        if ! echo "$AUTO_PORTS" | grep -qw "$TRACKED_PORT"; then
            FAIL_COUNTS[$TRACKED_PORT]=0
        fi
    done
    # ------------------------------

    for SERVER_PORT in $AUTO_PORTS; do
        # CRITICAL PROTECTION: Double check SERVER_PORT is a valid number before hitting lsof
        if ! [[ "$SERVER_PORT" =~ ^[0-9]+$ ]]; then
            continue
        fi

        PID=$(lsof -nP -i udp:"$SERVER_PORT" -t 2>/dev/null | head -n 1)
        
        # CRITICAL PROTECTION: If PID is empty, 0, or matches this script's PID, skip it!
        if [ -z "$PID" ] || [ "$PID" -eq 0 ] || [ "$PID" -eq "$$" ]; then
            continue
        fi

        if [ -z "${FAIL_COUNTS[$SERVER_PORT]}" ]; then
            FAIL_COUNTS[$SERVER_PORT]=0
        fi

        PULSE_STATUS=$(python3 -c "
import socket
import sys

try:
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.settimeout(1.5)
    server_addr = ('$SERVER_IP', $SERVER_PORT)
    
    sock.sendto(b'\xff\xff\xff\xff\x54Source Engine Query\x00', server_addr)
    res, _ = sock.recvfrom(1024)
    
    if res.startswith(b'\xff\xff\xff\xff'):
        print('ALIVE')
        sys.exit(0)
    print('MALFORMED')
except Exception:
    print('TIMEOUT')
" 2>/dev/null)

        if [ "$PULSE_STATUS" = "ALIVE" ]; then
            FAIL_COUNTS[$SERVER_PORT]=0
        else
            FAIL_COUNTS[$SERVER_PORT]=$(( ${FAIL_COUNTS[$SERVER_PORT]} + 1 ))
            log_message "[PORT $SERVER_PORT] FAILED! Status: $PULSE_STATUS (Strike ${FAIL_COUNTS[$SERVER_PORT]}/$MAX_STRIKES)"
            
            if [ "${FAIL_COUNTS[$SERVER_PORT]}" -ge "$MAX_STRIKES" ]; then
                if [ "$SAFE_MODE" = true ]; then
                    log_message "[PORT $SERVER_PORT] DEADLOCK SUSPECTED! PID $PID is unresponsive. (Skipping kill due to Safe Mode)"
                else
                    log_message "[PORT $SERVER_PORT] DEADLOCK DETECTED! Terminating frozen PID $PID..."
                    kill -9 "$PID"
                fi
                FAIL_COUNTS[$SERVER_PORT]=0
            fi
        fi
    done

    sleep "$CHECK_INTERVAL"
done
