#!/bin/bash

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVERS_DIR="/home/$USER/minecraft-servers"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  NeoForge Server Deletion"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# List available servers
SERVERS=()
while IFS= read -r -d '' dir; do
  SERVERS+=("$(basename "$dir")")
done < <(find "$SERVERS_DIR" -maxdepth 1 -name "*-server" -type d -print0 2>/dev/null)

if [ ${#SERVERS[@]} -eq 0 ]; then
  echo "  No servers found!"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
fi

echo "  Available servers:"
echo ""
for i in "${!SERVERS[@]}"; do
  echo "  $((i+1))) ${SERVERS[$i]}"
done
echo ""
echo "  a) All servers"
echo "  e) Exit"
echo ""
read -p "  Choose: " CHOICE

# Exit
if [ "$CHOICE" = "e" ]; then
  echo "  Exiting."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
fi

# Build list of servers to delete
TO_DELETE=()

if [ "$CHOICE" = "a" ]; then
  TO_DELETE=("${SERVERS[@]}")
elif [[ "$CHOICE" =~ ^[0-9]+$ ]] && [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le "${#SERVERS[@]}" ]; then
  TO_DELETE=("${SERVERS[$((CHOICE-1))]}")
else
  echo "  ERROR: Invalid choice."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 1
fi

# Confirm
echo ""
echo "  The following servers will be permanently deleted:"
for SERVER in "${TO_DELETE[@]}"; do
  echo "    - $SERVER"
done
echo ""
read -p "  Are you sure? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
  echo "  Aborted."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
fi

# Delete
echo ""
for SERVER in "${TO_DELETE[@]}"; do
  TARGET="$SERVERS_DIR/$SERVER"
  SERVER_NAME="${SERVER%-server}"

  echo "  Deleting $SERVER..."

TS_CONTAINER="tailscale-${SERVER_NAME}"

if docker ps --format '{{.Names}}' | grep -q "^${TS_CONTAINER}$"; then
  echo "  Removing Tailscale device..."

  success=false
  for i in {1..3}; do
    if docker exec "$TS_CONTAINER" tailscale logout >/dev/null 2>&1; then
      success=true
      break
    fi
    sleep 1
  done

  if [ "$success" = true ]; then
    echo "  ✓ Tailscale device removed!"
  else
    echo "  WARNING: Failed to remove Tailscale device. It may still appear in your tailnet dashboard."
  fi

  sleep 2
fi

  # Stop and remove containers, images and volumes
  cd "$TARGET" && docker compose down --rmi all --volumes 2>/dev/null

  # Go back before deleting folder
  cd "$SERVERS_DIR"
  rm -rf "$TARGET"

  echo "  ✓ $SERVER deleted!"
  echo ""
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✓ Done!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"