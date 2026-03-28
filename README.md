# Docker NeoForge Minecraft Server

Dockerized NeoForge Minecraft server with automatic setup, FileBrowser for mod management, and Tailscale for secure private access — no port forwarding needed.

## Dependencies

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/) (v2+)
- [Tailscale](https://tailscale.com/) account with a tailnet set up

## Tailscale setup

Before creating any server you need a Tailscale OAuth client secret.

1. Go to [Tailscale Admin Console](https://login.tailscale.com/admin) → **Settings → OAuth Clients**
2. Click **Generate OAuth client**
3. Enable **Devices** scope with **Read & Write**
4. Under tags, add `tag:minecraft`
5. Click **Generate** and copy the secret — **you only see it once!**

> The secret goes into `TS_AUTHKEY` when running `create-server.sh`

## Folder structure
```
minecraft/
├── create-server.sh       # Setup script
├── filebrowser/           # FileBrowser container
│   ├── docker-compose.yml
│   └── filebrowser.json
└── template/              # Server template
    ├── .env.example
    ├── Dockerfile
    └── docker-compose.yml
```

## Creating a server
```bash
# Make the script executable (the first time it's run)
chmod +x create-server.sh

# Run it
./create-server.sh
```

The script will ask for:

- **Server name** — leave empty for a random fun name (e.g. `funky-capybara`)
- **NeoForge version** — leave empty to use the latest stable
- **Min/Max memory** — defaults to 4G/8G
- **Tailscale auth key** — the OAuth secret from above

It will then create the server folder, write the `.env`, start FileBrowser if not already running, and boot the server.

## Managing Multiple Servers

Just run `./create-server.sh` again with a different name. Each server is fully isolated with its own folder under `servers/` and its own Tailscale node on your tailnet.
```
servers/
├── survival-server/
├── creative-server/
└── funky-capybara-server/
```

## Connecting to a Server

Players need to be on your Tailscale tailnet. Once they are, they connect via:
```
<SERVER_NAME>.your-tailnet.ts.net:25565
```

For example: `survival.your-tailnet.ts.net:25565`

## FileBrowser

FileBrowser starts automatically with the first server and runs at:
```
http://localhost:8080
```

Default login is `admin / admin` — **change it immediately** in Settings → User Management.

From FileBrowser you can upload mods, edit configs, and manage files for all your servers in one place.

## Environment Variables

| Variable | Description | Default |
|---|---|---|
| `NEOFORGE_VERSION` | NeoForge version to install | latest stable |
| `SERVER_NAME` | Server name (used for folder and Tailscale hostname) | random |
| `JAVA_MIN_MEMORY` | JVM minimum heap memory | `4G` |
| `JAVA_MAX_MEMORY` | JVM maximum heap memory | `8G` |
| `TS_AUTHKEY` | Tailscale OAuth client secret | required |

## License

MIT