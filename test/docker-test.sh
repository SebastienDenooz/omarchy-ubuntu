#!/bin/bash
# Runs the kit inside a fresh Ubuntu container as an unprivileged sudo user (IMAGE= to change the release).
#   test/docker-test.sh            create the container and run ./install.sh
#   test/docker-test.sh --resume   re-run ./install.sh in the existing container (completed steps skipped)
#   test/docker-test.sh --shell    open a shell in the container
#   test/docker-test.sh --rm       remove the container
# Downloads are cached in a named volume so re-runs are faster.
set -euo pipefail
KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAME=${NAME:-omarchy-ubuntu-test}
IMAGE=${IMAGE:-ubuntu:26.04}
USER_NAME=tester

case "${1:-}" in
  --rm) docker rm -f "$NAME" >/dev/null 2>&1 && echo "removed $NAME"; exit 0 ;;
  --shell) exec docker exec -it -u "$USER_NAME" -w "/home/$USER_NAME/omarchy-ubuntu" "$NAME" bash -l ;;
esac

if ! docker inspect "$NAME" >/dev/null 2>&1; then
  echo "==> creating container $NAME from $IMAGE"
  docker run -d --name "$NAME" -v omarchy-ubuntu-apt-cache:/var/cache/apt/archives -e DEBIAN_FRONTEND=noninteractive "$IMAGE" sleep infinity >/dev/null
  docker exec "$NAME" bash -ec '
    apt-get update -qq
    apt-get install -y -qq --no-install-recommends sudo git curl ca-certificates locales gnupg tzdata >/dev/null
    locale-gen en_US.UTF-8 >/dev/null
    useradd -m -s /bin/bash '"$USER_NAME"'
    echo "'"$USER_NAME"' ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/'"$USER_NAME"'
    chmod 440 /etc/sudoers.d/'"$USER_NAME"''
fi

echo "==> copying the kit (scripts, overrides, hypr, themed, docs)"
docker exec "$NAME" rm -rf "/home/$USER_NAME/omarchy-ubuntu.new"
docker exec "$NAME" mkdir -p "/home/$USER_NAME/omarchy-ubuntu.new"
tar -C "$KIT_DIR" --exclude=dl --exclude=build --exclude=logs --exclude=backups --exclude=.git -cf - . | docker exec -i "$NAME" tar -C "/home/$USER_NAME/omarchy-ubuntu.new" -xf -
docker exec "$NAME" bash -ec '
  d=/home/'"$USER_NAME"'/omarchy-ubuntu
  mkdir -p "$d"
  for k in dl build logs backups; do [[ -d $d/$k ]] && mv "$d/$k" "$d.new/$k"; done
  rm -rf "$d"; mv "$d.new" "$d"; chown -R '"$USER_NAME"': "$d"'

echo "==> running ./install.sh as $USER_NAME (log: docker logs / logs/ in the container)"
args=()
for a in "$@"; do [[ $a == --resume ]] || args+=("$a"); done
docker exec -u "$USER_NAME" -w "/home/$USER_NAME/omarchy-ubuntu" -e LANG=en_US.UTF-8 -e HOME="/home/$USER_NAME" -e ONLY="${ONLY:-}" "$NAME" bash -lc "./install.sh ${args[*]}"
