# Docker NeoForge Minecraft Server

Dockerized NeoForge Minecraft server with automatic setup, built-in FileBrowser for server management, and Tailscale for secure private access — no port forwarding needed.

## How it works

Each server is a self-contained Docker image running NeoForge and FileBrowser together via supervisord. Tailscale runs as a sidecar container, giving each server its own private hostname on your tailnet. No ports are exposed to the public internet.

## Dependencies

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/) (v2+)
- [Tailscale](https://tailscale.com/) account with a tailnet set up

## Tailscale setup

Before creating any server you need a Tailscale OAuth client secret.

1. Go to [Tailscale Admin Console](https://login.tailscale.com/admin) → **Access Controls**
2. Find the `tagOwners` section and add:
```json
"tagOwners": {
  "tag:minecraft": ["autogroup:admin"]
}
```
3. Save, then go to **Settings → OAuth Clients → Generate OAuth Client**
4. Enable **Devices:Core** → Write and **Keys:Auth Keys** → Write
5. Under tags, select `tag:minecraft`
6. Click **Generate** and copy the secret — **you only see it once!**

> The secret goes into `TS_AUTHKEY` when running `create-server.sh`

## First Time Setup
```bash
# Clone the repo
git clone https://github.com/Obievousky/docker-minecraft-server.git
cd docker-minecraft-server

# Make scripts executable
chmod +x create-server.sh
chmod +x delete-server.sh
```

## Folder Structure
```
docker-minecraft-server/
├── create-server.sh       # Server creation script
├── delete-server.sh       # Server deletion script
└── template/              # Server template (don't touch)
    ├── Dockerfile
    ├── docker-compose.yml
    └── supervisord.conf

~/minecraft-servers/       # Created automatically, lives outside the repo
└── your-server
    ├── .env               # Your servers .env
    ├── Dockerfile
    ├── docker-compose.yml
    └── supervisord.conf
```

## Creating a Server
```bash
./create-server.sh
```

The script will ask for:

- **Server name** — leave empty for a random fun name (e.g. `funky-capybara`)
- **NeoForge version** — leave empty to use the latest stable
- **Min memory** — defaults to 4G
- **Max memory** — defaults to 8G
- **Tailscale auth key** — the OAuth secret from above

It will then create the server folder, write the `.env`, build and boot the server.

## Deleting a Server
```bash
./delete-server.sh
```

Lists all available servers and lets you pick one or all to delete. Logs out the Tailscale device, stops and removes all containers, images, volumes, and files. Requires typing `yes` to confirm.

## Managing Multiple Servers

Just run `./create-server.sh` again with a different name. Each server is fully isolated with its own folder under `~/minecraft-servers/` and its own Tailscale node on your tailnet.

## Connecting to a Server

Players need to be on your Tailscale tailnet. Once they are, they connect via:
```
<SERVER_NAME>.your-tailnet.ts.net:25565
```

For example: `survival.your-tailnet.ts.net:25565`

## FileBrowser

Each server has its own FileBrowser instance running at:
```
http://<SERVER_NAME>.your-tailnet.ts.net:8080
```

No login required — accessible only to people on your Tailscale tailnet.

From FileBrowser you can upload mods, edit configs, and manage all server files directly from your browser.

## Environment Variables

| Variable | Description | Default |
|---|---|---|
| `NEOFORGE_VERSION` | NeoForge version to install | latest stable |
| `SERVER_NAME` | Server name (used for folder and Tailscale hostname) | random |
| `JAVA_MIN_MEMORY` | JVM minimum heap memory | `4G` |
| `JAVA_MAX_MEMORY` | JVM maximum heap memory | `8G` |
| `TS_AUTHKEY` | Tailscale OAuth client secret | required |

## Troubleshooting

### Permission denied connecting to Docker socket
If you see `permission denied while trying to connect to the Docker daemon socket`, your user is not in the docker group. Fix it with:
```bash
sudo usermod -aG docker $USER
```

Then log out and back in for the change to take effect.

### Scripts not executable
If you see `permission denied` when running the scripts:
```bash
chmod +x create-server.sh
chmod +x delete-server.sh
```

### Template folder not found
If the script says the template folder is missing, make sure you are running the scripts from inside the `docker-minecraft-server/` folder:
```bash
cd docker-minecraft-server
./create-server.sh
```

### Tailscale auth failed
Make sure you have created the `tag:minecraft` tag in Access Controls **before** generating the OAuth client. The tag must exist first or the auth key will be invalid.

## Acknowledgements

This project was built with the help of [Claude](https://claude.ai)
## License

MIT