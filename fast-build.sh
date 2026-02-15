#!/bin/bash

# Fast local build using Docker with caching and live file mounting

# Ensure Docker is running
if ! docker info > /dev/null 2>&1;
then
    echo "Error: Docker is not running. Please start Docker Desktop."
    exit 1
fi

echo "Building/Updating Builder Image..."
docker build -t ai-recovery-builder .

echo "Starting Fast Build..."
echo " - Mounting $(pwd)/archiso (Live edits)"
echo " - Mounting $(pwd)/out (Output)"
echo " - Using Docker Volume 'arch-pkg-cache' (Speed boost)"

# Create volume for package cache if it doesn't exist
docker volume create arch-pkg-cache >/dev/null

# Run build
# -v .../archiso:/build/archiso: Overwrites the image's copy with your live local files
# -v arch-pkg-cache:...: Persists downloaded packages between builds
docker run --rm --privileged \
  -v "$(pwd)/archiso:/build/archiso" \
  -v "$(pwd)/out:/out" \
  -v arch-pkg-cache:/var/cache/pacman/pkg \
  ai-recovery-builder

echo "Done."

