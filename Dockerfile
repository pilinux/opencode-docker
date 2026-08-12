FROM node:24.15.0-bookworm

ARG OPENCODE_VERSION=latest

WORKDIR /app

RUN uname -m

RUN npm i -g "opencode-ai@${OPENCODE_VERSION}" && \
  installed_version_raw="$(opencode --version)" && \
  installed_version="${installed_version_raw#v}" && \
  echo "Installed opencode version: ${installed_version}" && \
  if [ "${OPENCODE_VERSION}" != "latest" ] && [ "${installed_version}" != "${OPENCODE_VERSION}" ]; then \
    echo "Expected opencode version ${OPENCODE_VERSION}, got ${installed_version}" >&2; \
    exit 1; \
  fi

RUN adduser --disabled-password opencode

RUN mkdir -p /home/opencode/.local/share/opencode/ && \
  mkdir -p /home/opencode/.local/state/opencode && \
  mkdir -p /home/opencode/.config/opencode/ && \
  chown -R opencode:opencode /home/opencode

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["opencode", "serve", "--hostname", "0.0.0.0", "--port", "4096"]