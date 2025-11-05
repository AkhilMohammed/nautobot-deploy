#!/usr/bin/env bash
set -euo pipefail

# Usage:
# ./build_combined_image.sh <image_fullname> <plugins_yaml> <docker_user> <docker_token>
# Example:
# ./build_combined_image.sh docker.io/akhilmohammed/nautobot-combined:latest ansible/inventories/prod/group_vars/nautobot.yml DOCKER_USER DOCKER_TOKEN

COMBINED_IMAGE=${1:?combined image required}
PLUGINS_YAML=${2:?plugins yaml path required}
DOCKER_USER=${3:?docker user required}
DOCKER_TOKEN=${4:?docker token required}

WORKDIR=$(mktemp -d)
echo "Working dir: $WORKDIR"
cd "$WORKDIR"

if ! command -v yq >/dev/null 2>&1; then
  echo "yq not found. Try to install (Linux)..."
  sudo apt-get update && sudo apt-get install -y jq
fi

# Parse plugin repos
if command -v yq >/dev/null 2>&1; then
  PLUGIN_REPOS=($(yq e '.plugins[].repo' "$GITHUB_WORKSPACE/$PLUGINS_YAML"))
  PLUGIN_NAMES=($(yq e '.plugins[].name' "$GITHUB_WORKSPACE/$PLUGINS_YAML"))
else
  PLUGIN_REPOS=($(grep 'repo:' "$GITHUB_WORKSPACE/$PLUGINS_YAML" | awk '{print $2}' | tr -d '"'))
  PLUGIN_NAMES=($(grep 'name:' "$GITHUB_WORKSPACE/$PLUGINS_YAML" | awk -F': ' '{print $2}' | tr -d '"'))
fi

# Clone each plugin repo with GitHub token
for i in "${!PLUGIN_REPOS[@]}"; do
  REPO="${PLUGIN_REPOS[$i]}"
  NAME="${PLUGIN_NAMES[$i]}"
  echo "Cloning ${REPO} -> ${NAME}"
  
  # ✅ using GitHub token for private repo clone
  AUTH_REPO="https://${GITHUB_ACTOR}:${DOCKER_TOKEN}@${REPO#https://}"
  git clone --depth 1 "$AUTH_REPO" "$NAME"
done

# Generate Dockerfile using Docker Hub base / can remain GHCR base if preferred
cat > Dockerfile <<'DOCK'
FROM ghcr.io/nautobot/nautobot:2.2
WORKDIR /opt/nautobot

# copy plugins
DOCK

for d in "${PLUGIN_NAMES[@]}"; do
  echo "COPY ${d} /opt/nautobot/plugins/${d}" >> Dockerfile
done

cat >> Dockerfile <<'DOCK'
RUN set -e; \
    for req in /opt/nautobot/plugins/*/requirements.txt; do \
      if [ -f "$req" ]; then pip install --no-cache-dir -r "$req"; fi; \
    done || true

CMD ["nautobot-server", "start"]
DOCK

# ✅ Login to Docker Hub instead of GHCR
echo "Logging into Docker Hub"
echo "${DOCKER_TOKEN}" | docker login --username "${DOCKER_USER}" --password-stdin

echo "Building ${COMBINED_IMAGE}"
docker build -t "${COMBINED_IMAGE}" .

echo "Pushing ${COMBINED_IMAGE}"
docker push "${COMBINED_IMAGE}"

echo "Done. Cleaning up."
cd /
rm -rf "$WORKDIR"
