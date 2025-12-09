#!/bin/bash
set -e

echo "Starting Assetto Corsa Server Container..."

# Update/Install AC Server
echo "Updating AC Server (AppID 302550)..."
${STEAMCMD_DIR}/steamcmd.sh +force_install_dir ${SERVER_DIR} +login anonymous +app_update 302550 validate +quit

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
