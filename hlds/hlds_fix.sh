#!/bin/sh
# Patching Linux hlds on Debian/Ubuntu - Updated 2026
# Fixes 'CXXABI' and 'GCC_7.0.0' missing library errors

# Define your actual HL1 root directory path based on your logs
HL_DIR="$HOME/.local/share/Steam/steamapps/common/Half-Life"
STEAMCMD_DIR="$HOME/.local/share/Steam/steamcmd/linux32"

echo "=== Cleaning up archaic local Valve libraries ==="

# Safely remove the broken local libstdc++ files if they exist
[ -f "$HL_DIR/libstdc++.so.6" ] && rm -v "$HL_DIR/libstdc++.so.6"
[ -f "$STEAMCMD_DIR/libstdc++.so.6" ] && rm -v "$STEAMCMD_DIR/libstdc++.so.6"

# Safely remove the broken local libgcc files if they exist
[ -f "$HL_DIR/libgcc_s.so.1" ] && rm -v "$HL_DIR/libgcc_s.so.1"
[ -f "$STEAMCMD_DIR/libgcc_s.so.1" ] && rm -v "$STEAMCMD_DIR/libgcc_s.so.1"

echo "=== Setting up 32-bit System Library Overrides ==="

# Force Linux to look at your host OS 32-bit library directories first
export LD_LIBRARY_PATH=/usr/lib/i386-linux-gnu:/lib/i386-linux-gnu:$LD_LIBRARY_PATH

# Preload the system's 32-bit libgcc to satisfy modern libstdc++ requirements
export LD_PRELOAD=/lib/i386-linux-gnu/libgcc_s.so.1

echo "=== Patch complete. You can now start hlds_run ==="
