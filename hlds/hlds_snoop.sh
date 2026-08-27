#!/bin/bash

# --- CONFIGURATION ---
DEFAULT_IP="127.0.0.1"
DEFAULT_PORT="27015"
LOOP_INTERVAL=4  # Time to pause between sweeps (in seconds)

# --- USER INPUT ---
read -p "Enter Server IP [Default: $DEFAULT_IP]: " SERVER_IP
SERVER_IP=${SERVER_IP:-$DEFAULT_IP}

read -p "Enter Server Port [Default: $DEFAULT_PORT]: " SERVER_PORT
SERVER_PORT=${SERVER_PORT:-$DEFAULT_PORT}

if nc -h 2>&1 | grep -q "\-p"; then
    NC_CMD="nc -u -w 2"
else
    NC_CMD="nc -u -w 2 -d"
fi

echo "--------------------------------------------------------"
echo " Monitoring $SERVER_IP:$SERVER_PORT. Press ANY KEY to exit."
echo "--------------------------------------------------------"

while true; do
    clear
    echo "========================================================"
    echo " WATCHDOG SNOOP PANEL - [Press ANY KEY to Stop Tracking]"
    echo "========================================================"
    echo " Last Sweep: $(date '+%H:%M:%S')"
    echo "--------------------------------------------------------"

    # --- STEP 1: PADDED A2S_INFO QUERY ---
    BASE_INFO_HEX="ffffffff54536f7572636520456e67696e6520517565727900"
    PADDING_HEX=$(printf '00%.0s' {1..1200})
    INFO_PAYLOAD="${BASE_INFO_HEX}${PADDING_HEX}"
    
    HEX_INFO=$(printf "$INFO_PAYLOAD" | xxd -r -p | $NC_CMD "$SERVER_IP" "$SERVER_PORT" | xxd -p | tr -d '\n')

    if [ -z "$HEX_INFO" ] || [[ ! "$HEX_INFO" =~ ^ffffffff49 ]]; then
        echo " STATUS:  [OFFLINE / TIMEOUT / REFUSED]"
        echo "--------------------------------------------------------"
    else
        DATA_HEX=${HEX_INFO:10}
        DATA_HEX=${DATA_HEX:2} # Skip Protocol Byte
        
        NAME_HEX="${DATA_HEX%%00*}"; DATA_HEX=${DATA_HEX:${#NAME_HEX}+2}
        MAP_HEX="${DATA_HEX%%00*}";  DATA_HEX=${DATA_HEX:${#MAP_HEX}+2}
        FLD_HEX="${DATA_HEX%%00*}";  DATA_HEX=${DATA_HEX:${#FLD_HEX}+2}
        GME_HEX="${DATA_HEX%%00*}";  DATA_HEX=${DATA_HEX:${#GME_HEX}+2}
        
        DATA_HEX=${DATA_HEX:4} # Skip Steam ID AppID
        PLAYERS_HEX=${DATA_HEX:0:2}
        MAX_PLAYERS_HEX=${DATA_HEX:2:2}
        
        PLAYERS=$((16#$PLAYERS_HEX))
        MAX_PLAYERS=$((16#$MAX_PLAYERS_HEX))
        
        SERVER_NAME=$(printf "$NAME_HEX" | xxd -r -p)
        CURRENT_MAP=$(printf "$MAP_HEX" | xxd -r -p)

        echo " SERVER:  $SERVER_NAME"
        echo " MAP:     $CURRENT_MAP"
        echo " SLOTS:   $PLAYERS / $MAX_PLAYERS Online"
        echo "--------------------------------------------------------"

        # --- STEP 2: PLAYER NAME RESOLUTION ---
        if [ "$PLAYERS" -gt 0 ]; then
            echo " ACTIVE PLAYER ROSTER:"
            
            REQ_CHALLENGE="ffffffff55ffffffff"
            CHALLENGE_PAYLOAD="${REQ_CHALLENGE}${PADDING_HEX}"
            HEX_CHALLENGE=$(printf "$CHALLENGE_PAYLOAD" | xxd -r -p | $NC_CMD "$SERVER_IP" "$SERVER_PORT" | xxd -p | tr -d '\n')
            
            if [[ "$HEX_CHALLENGE" =~ ^ffffffff41 ]]; then
                TOKEN_HEX=${HEX_CHALLENGE:10:8}
                PLAYER_PAYLOAD="ffffffff55${TOKEN_HEX}${PADDING_HEX}"
                HEX_PLAYERS=$(printf "$PLAYER_PAYLOAD" | xxd -r -p | $NC_CMD "$SERVER_IP" "$SERVER_PORT" | xxd -p | tr -d '\n')
                
                # A2S_PLAYER response header is ffffffff44 (5 bytes / 10 hex chars)
                if [[ "$HEX_PLAYERS" =~ ^ffffffff44 ]]; then
                    # The 6th byte (hex chars 10-11) is the number of players returned
                    COUNT_HEX=${HEX_PLAYERS:10:2}
                    ACTUAL_COUNT=$((16#$COUNT_HEX))
                    
                    # Cut down to raw roster data starting at hex char index 12
                    ROSTER_HEX=${HEX_PLAYERS:12}
                    
                    # Secure binary parsing engine
                    for ((i=1; i<=ACTUAL_COUNT; i++)); do
                        if [ -z "$ROSTER_HEX" ]; then break; fi
                        
                        # 1. Skip Player Index Byte (2 hex chars)
                        ROSTER_HEX=${ROSTER_HEX:2}
                        
                        # 2. Isolate Name block up to null delimiter '00'
                        P_NAME_HEX="${ROSTER_HEX%%00*}"
                        
                        # Advance payload index past the name string + its null terminator
                        ROSTER_HEX=${ROSTER_HEX:${#P_NAME_HEX}+2}
                        
                        # 3. Skip Player Score (4 bytes) + Connection Duration (4 bytes) = 8 bytes (16 hex chars)
                        ROSTER_HEX=${ROSTER_HEX:16}
                        
                        # Convert hex string safely to clean readable ASCII text
                        P_NAME=$(printf "$P_NAME_HEX" | xxd -r -p | tr -cd '\40-\176')
                        
                        # If a name contains purely unprintable values, label it as connecting
                        if [ -z "$P_NAME" ]; then P_NAME="[Connecting...]"; fi
                        
                        echo "  $i. $P_NAME"
                    done
                else
                    echo "  [Error processing roster data matrix]"
                fi
            else
                echo "  [Server firewalled roster challenge handshake]"
            fi
        else
            echo "  Roster is currently empty."
        fi
        echo "--------------------------------------------------------"
    fi

    # --- NON-BLOCKING KEYBOARD INTERCEPT CANCEL KEY ---
    if read -s -n 1 -t $LOOP_INTERVAL; then
        echo "Exiting Panel. Monitoring Stopped."
        break
    fi
done
