# Assetto Corsa Server Docker Project

This project contains the source code for a Dockerized Assetto Corsa Dedicated Server with a Web Manager.

## Directives

- **Wine**: The server must run using Wine on Linux.
- **SteamCMD**: Used to download the server files (AppID 302550).
- **Web UI**: A separate container managing the server container via Docker Socket.
- **Persistence**: Configs, logs, and mods must be persistent.

## Structure

- `/docker`: Dockerfiles and build scripts.
- `/configs`: Default configuration files.
- `/web`: Source code for the Web UI.
- `docker-compose.yml`: Main orchestration file.
