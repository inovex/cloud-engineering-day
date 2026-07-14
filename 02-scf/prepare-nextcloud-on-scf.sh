#!/bin/bash
set -euo pipefail

NEXTCLOUD_VERSION="34.0.1"

# Check for required tools
missing=()
for c in curl unzip cf; do command -v "$c" >/dev/null || missing+=("$c"); done
((${#missing[@]})) && {
  echo "Error: missing tools: ${missing[*]} on PATH ($PATH)"
  exit 1
}

# Download and extract official pre-built Nextcloud
if [ ! -d "htdocs" ]; then
  echo "Downloading Nextcloud v${NEXTCLOUD_VERSION}..."
  curl -L -o nextcloud.zip "https://download.nextcloud.com/server/releases/nextcloud-${NEXTCLOUD_VERSION}.zip"

  echo "Extracting Nextcloud..."
  unzip -q nextcloud.zip
  mv nextcloud htdocs
  rm nextcloud.zip
fi

# Copy minimal config (sets trusted_domains to '*' so CF's hostname is accepted)
echo "Copying configuration file..."
# cp config.php htdocs/config/config.php

echo "=========================================================="
echo "Nextcloud workspace is ready!"
echo "Run 'cf push' to deploy!"
echo "=========================================================="
