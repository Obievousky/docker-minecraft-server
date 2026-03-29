#!/bin/bash

ADJECTIVES="blue red wild dark swift brave calm crazy happy funky"
ANIMALS="platypus narwhal axolotl panda capybara ferret penguin salamander"

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVERS_DIR="/home/$USER/minecraft-servers"
FILEBROWSER_DIR="$BASE_DIR/filebrowser"
TEMPLATE_DIR="$BASE_DIR/template"

# Check template exists
if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "ERROR: Template folder not found at $TEMPLATE_DIR"
  echo "Make sure you're running this script from the correct directory."
  exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  NeoForge Server Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Server name
read -p "Server name (leave empty for random): " SERVER_NAME
if [ -z "$SERVER_NAME" ]; then
  ADJ=$(echo $ADJECTIVES | tr ' ' '\n' | shuf -n1)
  ANIMAL=$(echo $ANIMALS | tr ' ' '\n' | shuf -n1)
  SERVER_NAME="${ADJ}-${ANIMAL}"
  echo "Generated server name: $SERVER_NAME"
fi

# Fetch latest stable NeoForge version
echo ""
echo "Fetching latest NeoForge version..."
LATEST_VERSION=$(curl -s "https://maven.neoforged.net/api/maven/versions/releases/net/neoforged/neoforge" \
  | tr ',' '\n' \
  | grep -o '"[0-9]*\.[0-9]*\.[0-9]*"' \
  | tr -d '"' \
  | tail -1)

read -p "NeoForge version (leave empty for latest: ${LATEST_VERSION:-unavailable}): " NEOFORGE_VERSION

if [ -z "$NEOFORGE_VERSION" ] && [ -z "$LATEST_VERSION" ]; then
  read -p "Could not fetch latest, please enter a version: " NEOFORGE_VERSION
  if [ -z "$NEOFORGE_VERSION" ]; then
    echo "ERROR: NeoForge version is required!"
    exit 1
  fi
fi

NEOFORGE_VERSION=${NEOFORGE_VERSION:-$LATEST_VERSION}

# Memory
read -p "Min memory (leave empty for 4G): " JAVA_MIN_MEMORY
JAVA_MIN_MEMORY=${JAVA_MIN_MEMORY:-4G}
[[ $JAVA_MIN_MEMORY =~ [MG]$ ]] || JAVA_MIN_MEMORY="${JAVA_MIN_MEMORY}G"

read -p "Max memory (leave empty for 8G): " JAVA_MAX_MEMORY
JAVA_MAX_MEMORY=${JAVA_MAX_MEMORY:-8G}
[[ $JAVA_MAX_MEMORY =~ [MG]$ ]] || JAVA_MAX_MEMORY="${JAVA_MAX_MEMORY}G"

# Tailscale
read -p "Tailscale auth key: " TS_AUTHKEY

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Creating server: ${SERVER_NAME}-server"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create servers directory if it doesn't exist
mkdir -p "$SERVERS_DIR"

# Check if server already exists
TARGET="$SERVERS_DIR/${SERVER_NAME}-server"
if [ -d "$TARGET" ]; then
  echo "ERROR: $TARGET already exists! Choose a different name."
  exit 1
fi

# Copy template
cp -r "$TEMPLATE_DIR" "$TARGET"

# Write .env
cat > "$TARGET/.env" <<EOF
NEOFORGE_VERSION=${NEOFORGE_VERSION}
SERVER_NAME=${SERVER_NAME}
JAVA_MIN_MEMORY=${JAVA_MIN_MEMORY}
JAVA_MAX_MEMORY=${JAVA_MAX_MEMORY}
TS_AUTHKEY=${TS_AUTHKEY}
EOF

echo "✓ Server created at $TARGET"

# Start the server
echo ""
echo "Starting server..."
cd "$TARGET" && docker compose up --build -d
echo "✓ Server started!"

# Start or restart FileBrowser
echo ""
if ! docker ps --format '{{.Names}}' | grep -q "^filebrowser$"; then
  echo "Starting FileBrowser..."
  cd "$FILEBROWSER_DIR" && docker compose up -d
  echo "Waiting for FileBrowser to initialize..."
  sleep 5
else
  echo "Restarting FileBrowser to detect new server..."
  cd "$FILEBROWSER_DIR" && docker compose restart
  sleep 3
fi

# Grab password from logs if first boot
FB_PASSWORD=$(docker logs filebrowser 2>&1 | grep -o 'password: [^ ]*' | tail -1 | cut -d' ' -f2)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✓ Setup complete!"
echo ""
echo "  Server:      ${SERVER_NAME}-server"
echo "  NeoForge:    ${NEOFORGE_VERSION}"
echo "  Connect via: ${SERVER_NAME}.your-tailnet.ts.net:25565"
echo ""
echo "  FileBrowser: http://localhost:8080"
echo "  FB User:     admin"
if [ -n "$FB_PASSWORD" ]; then
  echo "  FB Password: $FB_PASSWORD"
else
  echo "  FB Password: admin (change it immediately!)"
fi
echo ""
read -p "  [a] Attach to server console  [e] Exit: " CHOICE
if [ "$CHOICE" = "a" ]; then
  docker attach "$SERVER_NAME"
else
  echo "  Exiting. Server is running in the background!"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"