# Assetto Corsa Dedicated Server with Web Manager

This project provides a fully Dockerized Assetto Corsa Dedicated Server, complete with a lightweight Web UI for management. It is designed to be easily deployed on any Linux VPS or platform like Coolify.

## Features

- **Automated Install**: Downloads the latest AC Server files via SteamCMD.
- **Wine Support**: Runs the Windows-native server executable on Linux transparently.
- **Web Manager**: Simple dashboard to start/restart the server, edit basic configurations (Track, Cars, Password), and view logs.
- **Persistence**: Configurations and mods are stored in volumes/local directories.

## Prerequisites

- Docker
- Docker Compose

## Quick Start

1.  Clone this repository.
2.  Review the configurations in `configs/server_cfg.ini` and `configs/entry_list.ini`.
3.  Start the services:

    ```bash
    docker-compose up -d
    ```

4.  Access the Web UI at `http://<your-ip>:8081`.
5.  The game server will be available on port `9600` (TCP/UDP).

## Configuration

### Server Configuration
The main configuration files are located in the `configs/` directory:
- `server_cfg.ini`: General server settings (ports, name, track, etc).
- `entry_list.ini`: Grid configuration (cars, skins, drivers).

Changes made via the Web UI will update `server_cfg.ini` in the `configs/` folder. A server restart is required for changes to take effect (can be triggered from the Web UI).

### Mods
To add mods (cars or tracks), you can mount them into the container via `docker-compose.yml`.
Note: The server directory structure is `/ac-server/content/tracks` and `/ac-server/content/cars`.
You may need to adjust the volume mounts to add specific mods.

## Ports

| Service | Port | Protocol | Description |
|---|---|---|---|
| AC Game | 9600 | TCP/UDP | Main game traffic |
| AC HTTP | 8082 | TCP | Built-in AC Server HTTP info |
| Web UI | 8081 | TCP | Management Dashboard |

## Troubleshooting

- **Server not showing up**: Ensure ports 9600 TCP/UDP are open on your firewall.
- **SteamCMD errors**: Check internet connectivity. Sometimes SteamCMD fails to update; restarting the container usually fixes it.
- **Logs**: View logs via the Web UI or `docker logs ac-server`.
