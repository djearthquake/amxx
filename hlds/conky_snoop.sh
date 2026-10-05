#!/bin/bash

# --- CONFIGURATION ---
DEFAULT_IP="YOUR_IP"
PORTS=("27030" "27015")  # Add all your ports here

# --- BYPASS USER INPUT FOR CONKY ---
SERVER_IP="$DEFAULT_IP"

if nc -h 2>&1 | grep -q "\-p"; then
    NC_CMD="nc -u -w 2"
else
    NC_CMD="nc -u -w 2 -d"
fi

# --- SINGLE SWEEP EXECUTION ---
echo "\${color orange}HLDS PANEL\${color}"
echo "Last Sweep: $(date '+%H:%M:%S')"
echo "========================================================"

# --- REUSABLE QUERY FUNCTION ---
query_server() {
    local SERVER_PORT="$1"
    
    # --- STEP 1: PADDED A2S_INFO QUERY ---
    BASE_INFO_HEX="ffffffff54536f7572636520456e67696e6520517565727900"
    PADDING_HEX=$(printf '00%.0s' {1..1200})
    INFO_PAYLOAD="${BASE_INFO_HEX}${PADDING_HEX}"

    HEX_INFO=$(printf "$INFO_PAYLOAD" | xxd -r -p | $NC_CMD "$SERVER_IP" "$SERVER_PORT" | xxd -p | tr -d '\n')

    if [ -z "$HEX_INFO" ] || [[ ! "$HEX_INFO" =~ ^ffffffff49 ]]; then
        echo " PORT $SERVER_PORT:  \${color red}[OFFLINE / TIMEOUT]\${color}"
        echo "--------------------------------------------------------"
        return
    fi

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

    echo " SERVER:  $SERVER_NAME ($SERVER_PORT)"
    echo " MAP:     \${color yellow}$CURRENT_MAP\${color}"
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
            
            if [[ "$HEX_PLAYERS" =~ ^ffffffff44 ]]; then
                COUNT_HEX=${HEX_PLAYERS:10:2}
                ACTUAL_COUNT=$((16#$COUNT_HEX))
                
                ROSTER_HEX=${HEX_PLAYERS:12}
                
                for ((i=1; i<=ACTUAL_COUNT; i++)); do
                    if [ -z "$ROSTER_HEX" ]; then break; fi
                    
                    ROSTER_HEX=${ROSTER_HEX:2}
                    P_NAME_HEX="${ROSTER_HEX%%00*}"
                    ROSTER_HEX=${ROSTER_HEX:${#P_NAME_HEX}+2}
                    ROSTER_HEX=${ROSTER_HEX:16}
                    
                    # Contains your crucial dollar sign escaping fix:
                    P_NAME=$(printf "$P_NAME_HEX" | xxd -r -p | tr -cd '\40-\176' | sed 's/\$/\\$/g')
                    
                    if [ -z "$P_NAME" ]; then P_NAME="[Connecting...]"; fi
                    
                    echo "  $i. $P_NAME"
                done
            else
                echo "  [Error processing roster data]"
            fi
        else
            echo "  [Server firewalled roster challenge]"
        fi
    else
        echo "  Roster is currently empty."
    fi
    echo "========================================================"
}

# --- LOOP THROUGH BOTH PORTS ---
for PORT in "${PORTS[@]}"; do
    query_server "$PORT"
done
#LINE TO ADD THIS TO YOUR CONKY
#echo ${execpi 1 /home/whoami/hlds_snoop.sh} >> ~/.config/conky/conky.conf
