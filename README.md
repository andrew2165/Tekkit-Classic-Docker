# Tekkit Classic Docker Server
A containerized Tekkit Classic Minecraft server.

## Quick Start

```bash
git clone https://github.com/andrew2165/Tekkit-Classic-Docker
cd Tekkit-Classic-Docker
docker compose up -d
```

The server will be available at `localhost:25565`.

## View Logs

```bash
docker compose logs -f
```

## Configuration (Optional)

Create a `.env` file to customize settings:

```bash
cp .env.example .env
# Edit .env with your preferred settings
docker compose up -d
```

### Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `JAVA_MEMORY` | `2G` | Java heap size |
| `SERVER_PORT` | `25565` | Server port |
| `MAX_PLAYERS` | `20` | Maximum players |
| `MOTD` | `Tekkit Classic Server` | Server description |
| `DIFFICULTY` | `1` | 0=Peaceful, 1=Easy, 2=Normal, 3=Hard |

## Management

### Restart Server
```bash
docker compose restart
```

### Stop Server
```bash
docker compose down
```

### Access Console
```bash
docker compose exec tekkit mc-console
```

### Give Op Permissions
```bash
docker compose exec tekkit mc-op <username>
```

## Data Persistence

All server data is automatically saved in a Docker volume:
- All server files: `tekkit-server-data`

This includes worlds, configuration files, mods, and logs.

To completely remove all data:
```bash
docker compose down -v
```

## License

MIT License
