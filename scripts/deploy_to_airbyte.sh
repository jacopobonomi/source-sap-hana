#!/usr/bin/env bash
# Builds the connector image and loads it onto a self-hosted Airbyte server over SSH,
# without pushing it to any public registry.
#
#   scripts/deploy_to_airbyte.sh <ssh-target> [ssh-key]
#   scripts/deploy_to_airbyte.sh root@airbyte.example.com ~/.ssh/airbyte_key
#
# Works with both Airbyte deployments:
#   * abctl (Kubernetes-in-Docker): the image is imported into the kind node's containerd
#   * docker compose (older installs): the image is loaded into the host's Docker
# Then register it in the UI: Settings -> Sources -> + New connector -> Add a new Docker connector,
# image "jacopobonomi/source-sap-hana", tag = VERSION below.
set -euo pipefail

TARGET="${1:?usage: $0 <ssh-target> [ssh-key]}"
KEY="${2:-}"
VERSION="$(sed -n 's/^version = "\(.*\)"/\1/p' "$(dirname "$0")/../pyproject.toml")"
IMAGE="jacopobonomi/source-sap-hana:${VERSION}"
SSH=(ssh -o ConnectTimeout=15)
[[ -n "$KEY" ]] && SSH+=(-i "$KEY")

ARCH="$("${SSH[@]}" "$TARGET" "uname -m")"
case "$ARCH" in
  x86_64 | amd64) PLATFORM=linux/amd64 ;;
  aarch64 | arm64) PLATFORM=linux/arm64 ;;
  *) echo "unsupported server architecture: $ARCH" >&2; exit 1 ;;
esac

echo "==> Building ${IMAGE} for ${PLATFORM} (server is ${ARCH})"
docker build --platform "$PLATFORM" -t "$IMAGE" "$(dirname "$0")/.."

echo "==> Detecting Airbyte deployment on ${TARGET}"
NODE="$("${SSH[@]}" "$TARGET" "docker ps --format '{{.Names}}' | grep -m1 -- '-control-plane$' || true")"

if [[ -n "$NODE" ]]; then
  echo "==> abctl/kind node '${NODE}': importing into containerd (k8s.io namespace)"
  docker save "$IMAGE" | gzip | "${SSH[@]}" "$TARGET" "gunzip | docker exec -i ${NODE} ctr --namespace=k8s.io images import -"
  "${SSH[@]}" "$TARGET" "docker exec ${NODE} ctr --namespace=k8s.io images ls | grep -q 'source-sap-hana:${VERSION}'"
else
  echo "==> No kind node found: loading into the host Docker daemon"
  docker save "$IMAGE" | gzip | "${SSH[@]}" "$TARGET" "gunzip | docker load"
fi

echo "==> Done. In Airbyte add a custom Docker connector: ${IMAGE%:*} / ${VERSION}"
echo "    (abctl pulls with imagePullPolicy IfNotPresent, so the preloaded image is used as-is)"
