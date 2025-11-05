#!/usr/bin/env bash
set -euo pipefail

# Usage:
# ./build_combined_image.sh <combined_image_fullname> <plugins_yaml> <ghcr_user> <ghcr_token>
# Example:
# ./build_combined_image.sh ghcr.io/AkhilMohammed/nautobot-combined:latest ansible/inventories/prod/group_vars/nautobot.yml AKHIL_USER GHCR_TOKEN

COMBINED_IMAGE=${1:?combined image required}
PLUGINS_YAML=${2:?plugins yaml path required}
GHCR_USER=${3:?ghcr user required}
GHCR_TOKEN=${4:?ghcr token required}

WORKDIR=$(mktemp -d)
echo "Working dir: $WORKDIR"
cd "$WORKDIR"

# install yq if not present (for local dev we assume yq exists in runner)
if ! command -v yq >/dev/null 2>&1; then
  echo "yq not found. Try to install (Linux)..."
  sudo apt-get update && sudo apt-get install -y jq
  # fallback parsing with grep if yq unavailable - but recommended to have yq in CI
fi

# Parse plugin repos (supports yq; fallback to grep)
if command -v yq >/dev/null 2>&1; then
  PLUGIN_REPOS=($(yq e '.plugins[].repo' "$GITHUB_WORKSPACE/$PLUGINS_YAML"))
  PLUGIN_NAMES=($(yq e '.plugins[].name' "$GITHUB_WORKSPACE/$PLUGINS_YAML"))
else
  # fallback - crude parsing (requires well-formed yaml)
  PLUGIN_REPOS=($(grep 'repo:' "$GITHUB_WORKSPACE/$PLUGINS_YAML" | awk '{print $2}' | tr -d '"'))
  PLUGIN_NAMES=($(grep 'name:' "$GITHUB_WORKSPACE/$PLUGINS_YAML" | awk -F': ' '{print $2}' | tr -d '"'))
fi

# Clone each plugin repo into folder
for i in "${!PLUGIN_REPOS[@]}"; do
  REPO="${PLUGIN_REPOS[$i]}"
  NAME="${PLUGIN_NAMES[$i]}"
  echo "Cloning ${REPO} -> ${NAME}"
  AUTH_REPO="https://${GITHUB_ACTOR}:${GHCR_TOKEN}@${REPO#https://}"
    echo "Cloning ${REPO} -> ${NAME}"
    git clone --depth 1 "$AUTH_REPO" "$NAME"

done

# Create Dockerfile that starts FROM base Nautobot image and copies all plugin folders
cat > Dockerfile <<'DOCK'
# Combined Nautobot image - built in CI
FROM ghcr.io/nautobot/nautobot:2.2
WORKDIR /opt/nautobot

# copy plugins
DOCK

# Append COPY statements for each plugin
for d in "${PLUGIN_NAMES[@]}"; do
  echo "COPY ${d} /opt/nautobot/plugins/${d}" >> Dockerfile
done

# Optional: install plugin requirements if present
cat >> Dockerfile <<'DOCK'
# Try installing any requirements found in plugin directories (non-fatal)
RUN set -e; \
    for req in /opt/nautobot/plugins/*/requirements.txt; do \
      if [ -f "$req" ]; then pip install --no-cache-dir -r "$req"; fi; \
    done || true

# Final command
CMD ["nautobot-server", "start"]
DOCK

# Build and push
echo "Logging into GHCR"
echo "${GHCR_TOKEN}" | docker login ghcr.io -u "${GHCR_USER}" --password-stdin

echo "Building ${COMBINED_IMAGE}"
docker build -t "${COMBINED_IMAGE}" .

echo "Pushing ${COMBINED_IMAGE}"
docker push "${COMBINED_IMAGE}"

echo "Done. Cleaning up."
cd /
rm -rf "$WORKDIR"
