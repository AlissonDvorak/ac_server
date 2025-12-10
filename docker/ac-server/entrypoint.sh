#!/bin/bash
set -e

echo "Starting Assetto Corsa Server Container..."

# Update/Install AC Server
echo "Updating AC Server (AppID 302550)..."

if [ -z "$STEAM_USERNAME" ]; then
    echo "Using anonymous login..."
    STEAM_LOGIN="+login anonymous"
else
    echo "Using provided Steam credentials..."
    STEAM_LOGIN="+login ${STEAM_USERNAME} ${STEAM_PASSWORD}"
fi

${STEAMCMD_DIR}/steamcmd.sh +@sSteamCmdForcePlatformType windows +force_install_dir ${SERVER_DIR} $STEAM_LOGIN +app_update 302550 validate +quit

# Ensure config directories exist in the server folder
mkdir -p ${SERVER_DIR}/cfg
mkdir -p ${SERVER_DIR}/content/cars
mkdir -p ${SERVER_DIR}/content/tracks

# Link or copy configs from volume if they exist
# We assume the volume is mounted at /data/configs
if [ -d "/data/configs" ]; then
    echo "Syncing configurations..."
    cp /data/configs/*.ini ${SERVER_DIR}/cfg/
fi

# Validate Server Config (Prevent Panic loop)
CFG_FILE="${SERVER_DIR}/cfg/server_cfg.ini"
if [ -f "$CFG_FILE" ]; then
    # Check for empty TRACK
    if grep -q "^TRACK=$" "$CFG_FILE" || ! grep -q "^TRACK=" "$CFG_FILE"; then
        echo "WARNING: TRACK is missing or empty in server_cfg.ini. Setting default to 'magione'."
        if grep -q "^TRACK=" "$CFG_FILE"; then
            sed -i 's/^TRACK=.*$/TRACK=magione/' "$CFG_FILE"
        else
            # Append if missing (simple approach, might be out of section but usually works if section exists)
            # Better to rely on sed if key exists. If not, we might be in trouble if [SERVER] header is missing.
            # Assuming [SERVER] exists.
            sed -i '/\[SERVER\]/a TRACK=magione' "$CFG_FILE"
        fi
    fi

    # Check for empty CARS
    if grep -q "^CARS=$" "$CFG_FILE" || ! grep -q "^CARS=" "$CFG_FILE"; then
        echo "WARNING: CARS is missing or empty in server_cfg.ini. Setting default."
        DEFAULT_CAR="abarth500"
        if grep -q "^CARS=" "$CFG_FILE"; then
            sed -i "s/^CARS=.*$/CARS=$DEFAULT_CAR/" "$CFG_FILE"
        else
            sed -i "/\[SERVER\]/a CARS=$DEFAULT_CAR" "$CFG_FILE"
        fi
    fi
else
    echo "ERROR: server_cfg.ini not found!"
fi

# Check for WEATHER_0 (Fix UpdateWeather panic)
if [ -f "$CFG_FILE" ] && ! grep -q "\[WEATHER_0\]" "$CFG_FILE"; then
    echo "WARNING: WEATHER_0 missing in server_cfg.ini. Appending default weather."
    cat <<EOF >> "$CFG_FILE"

[WEATHER_0]
GRAPHICS=3_clear
BASE_TEMPERATURE_AMBIENT=26
BASE_TEMPERATURE_ROAD=11
VARIATION_AMBIENT=1
VARIATION_ROAD=1
EOF
fi

# Handle Mods
# We expect mods to be mounted at /data/mods
# Structure: /data/mods/cars/[car_name] and /data/mods/tracks/[track_name]
if [ -d "/data/mods/cars" ]; then
    echo "Installing Car Mods..."
    # Copy recursively or symlink. Symlink is faster but might have permission issues if crossing filesystems, though usually fine in Docker.
    # However, AC Server might not follow symlinks correctly? It usually does.
    # Let's copy to be safe, or just symlink top level directories.
    for d in /data/mods/cars/*; do
        if [ -d "$d" ]; then
            dirname=$(basename "$d")
            # Remove existing if present to allow updates
            rm -rf "${SERVER_DIR}/content/cars/${dirname}"
            ln -s "$d" "${SERVER_DIR}/content/cars/${dirname}"
            echo "Linked car mod: $dirname"
        fi
    done
fi

if [ -d "/data/mods/tracks" ]; then
    echo "Installing Track Mods..."
    for d in /data/mods/tracks/*; do
        if [ -d "$d" ]; then
            dirname=$(basename "$d")
            rm -rf "${SERVER_DIR}/content/tracks/${dirname}"
            ln -s "$d" "${SERVER_DIR}/content/tracks/${dirname}"
            echo "Linked track mod: $dirname"
        fi
    done
fi


# We might want to link logs to the volume so they persist and are accessible
mkdir -p ${SERVER_DIR}/logs

# Run the server with Wine
echo "Starting acServer.exe..."

# Start Xvfb in background
Xvfb :0 -screen 0 1024x768x16 &
export DISPLAY=:0

# Wait for Xvfb
sleep 2

# Run server
wine ${SERVER_DIR}/acServer.exe
