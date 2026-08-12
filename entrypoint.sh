#!/bin/sh
set -e

PUID="${PUID:-1000}"
PGID="${PGID:-1000}"

if [ "$(id -u)" = "0" ]; then
    usermod -o -u "${PUID}" opencode
    groupmod -o -g "${PGID}" opencode

    chown -R "${PUID}:${PGID}" /home/opencode/.config /home/opencode/.local
    chown "${PUID}:${PGID}" /home/opencode

    export HOME=/home/opencode
    exec setpriv --reuid "${PUID}" --regid "${PGID}" --clear-groups "$@"
fi

exec "$@"