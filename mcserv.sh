#!/bin/bash

# Configuration
GIT_REPO_URL="https://github.com/lsaray/minecraft-server-local"
LOCK_FILE="lock.txt"
MINECRAFT_CMD="/var/lib/flatpak/app/org.fn2006.PollyMC/x86_64/master/2a02c3bcc57776fafc3205908f51f65f1e818f8d3ff672265d8ab43267374b04/files/jdk/8/jre/bin/java -Xmx4096M -Xms1024M -jar forge-1.16.5-36.2.34.jar nogui"

# Pull the latest files
git fetch
git reset --hard origin/master
if [ $? -ne 0 ]; then
    echo "Error: Failed to pull from Git repository."
    read -p "Press Enter to exit..."
    exit 1
fi

# Check lock file
if [ ! -f "$LOCK_FILE" ]; then
    echo "0" > "$LOCK_FILE"
    git add "$LOCK_FILE"
    git commit -m "Initialize lock file"
    git push --force origin master
fi

LOCK=$(cat "$LOCK_FILE")
if [ "$LOCK" -eq 1 ]; then
    echo "Error: Server is already locked by another host."
    read -p "Press Enter to exit..."
    exit 1
fi

# Acquire lock
echo "1" > "$LOCK_FILE"
git add "$LOCK_FILE"
git commit -m "Acquire server lock"
git push --force origin master
if [ $? -ne 0 ]; then
    echo "Error: Failed to acquire lock."
    read -p "Press Enter to exit..."
    exit 1
fi

# Start Minecraft server in the foreground
$MINECRAFT_CMD

# On script exit (Ctrl+C or normal exit), release lock and push
cleanup() {
    echo "Releasing lock and shutting down..."
    echo "0" > "$LOCK_FILE"
    git add "$LOCK_FILE"
    git add *
    git commit -m "Release server lock"
    git push --force origin master
    exit 0
}

# Trap SIGINT (Ctrl+C) and SIGTERM (kill)
trap cleanup SIGINT SIGTERM EXIT

# Wait for Minecraft server to exit
wait
