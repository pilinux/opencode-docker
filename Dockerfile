FROM node:24.21.0-bookworm

ARG OPENCODE_VERSION=latest

# set working directory
WORKDIR /app

# check architecture
RUN uname -m

# install opencode globally
RUN npm i -g "opencode-ai@${OPENCODE_VERSION}" && \
  installed_version_raw="$(opencode --version)" && \
  installed_version="${installed_version_raw#v}" && \
  echo "Installed opencode version: ${installed_version}" && \
  if [ "${OPENCODE_VERSION}" != "latest" ] && [ "${installed_version}" != "${OPENCODE_VERSION}" ]; then \
    echo "Expected opencode version ${OPENCODE_VERSION}, got ${installed_version}" >&2; \
    exit 1; \
  fi

# non-root user (recommended)
# replace the base image's node user so that opencode owns UID/GID 1000
RUN userdel -r node && \
  groupadd -g 1000 opencode && \
  useradd -m -u 1000 -g opencode -s /bin/bash opencode

# create necessary directories and set permissions
RUN mkdir -p /home/opencode/.local/share/opencode/ && \
  mkdir -p /home/opencode/.local/state/opencode && \
  mkdir -p /home/opencode/.config/opencode/ && \
  chown -R opencode:opencode /home/opencode

# the entrypoint starts as root, remaps opencode to PUID/PGID and drops privileges
COPY --chmod=0755 entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["opencode", "serve", "--hostname", "0.0.0.0", "--port", "4096"]

# docker buildx build --platform linux/amd64,linux/arm64 -t ghcr.io/pilinux/opencode:0.0.1 --output type=docker .
