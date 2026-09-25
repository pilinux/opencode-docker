#!/bin/sh
set -e

PUID="${PUID:-1000}"
PGID="${PGID:-1000}"

# opencode reads its config and state from here, whether started as root or via --user
export HOME=/home/opencode

if [ "$(id -u)" = "0" ]; then
    for id in "${PUID}" "${PGID}"; do
        case "${id}" in
            '' | *[!0-9]* | 0?*)
                echo "entrypoint: PUID/PGID must be plain numeric ids, got PUID='${PUID}' PGID='${PGID}'" >&2
                exit 1
                ;;
        esac
    done
    if [ "${PUID}" -eq 0 ] || [ "${PGID}" -eq 0 ]; then
        echo "entrypoint: refusing to run opencode as root (PUID/PGID must not be 0)" >&2
        exit 1
    fi

    # remap only when needed, so a read-only root filesystem keeps working
    if [ "$(id -g opencode)" != "${PGID}" ]; then
        groupmod -o -g "${PGID}" opencode
    fi
    if [ "$(id -u opencode)" != "${PUID}" ]; then
        usermod -o -u "${PUID}" opencode
    fi

    # fix ownership only when something is off, instead of a full chown on every start
    if [ -n "$(find /home/opencode/.config /home/opencode/.local \( ! -user "${PUID}" -o ! -group "${PGID}" \) -print -quit)" ]; then
        chown -R "${PUID}:${PGID}" /home/opencode/.config /home/opencode/.local
    fi
    if [ "$(stat -c %u:%g /home/opencode)" != "${PUID}:${PGID}" ]; then
        chown "${PUID}:${PGID}" /home/opencode
    fi

    export USER=opencode LOGNAME=opencode
    exec setpriv --reuid "${PUID}" --regid "${PGID}" --clear-groups "$@"
fi

exec "$@"
