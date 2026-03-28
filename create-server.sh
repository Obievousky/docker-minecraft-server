#!/bin/bash

ADJECTIVES="blue red wild dark swift brave calm crazy happy funky"
ANIMALS="platypus narwhal axolotl panda capybara ferret penguin salamander"

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

# Fetch latest stable NeoForge version (no beta/alpha/snapshot)
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

read -p "Max memory (leave empty for 8G): " JAVA_MAX_MEMORY
JAVA_MAX_MEMORY=${JAVA_MAX_MEMORY:-8G}

# Tailscale
read -p "Tailscale auth key: " TS_AUTHKEY

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Creating server: ${SERVER_NAME}-server"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if server already exists
TARGET="./servers/${SERVER_NAME}-server"
if [ -d "$TARGET" ]; then
  echo "ERROR: $TARGET already exists! Choose a different name."
  exit 1
fi

# Create server directory and copy template
mkdir -p ./servers
cp -r ./template "$TARGET"

# Write .env
cat > "$TARGET/.env" <<EOF
NEOFORGE_VERSION=${NEOFORGE_VERSION}
SERVER_NAME=${SERVER_NAME}
JAVA_MIN_MEMORY=${JAVA_MIN_MEMORY}
JAVA_MAX_MEMORY=${JAVA_MAX_MEMORY}
TS_AUTHKEY=${TS_AUTHKEY}
EOF

echo "✓ Server created at $TARGET"

# Check if FileBrowser is running, start it if not
echo ""
if ! docker ps --format '{{.Names}}' | grep -q "filebrowser"; then
  echo "FileBrowser not running, starting it..."
  cd ./filebrowser && docker compose up -d
  cd ..
  echo "✓ FileBrowser started at http://localhost:8080"
else
  echo "✓ FileBrowser already running"
fi

echo ""
echo "Starting server..."
cd "$TARGET" && docker compose up --build