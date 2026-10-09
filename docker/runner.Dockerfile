# MISW4103 runner: Linux image that runs every course module (Cypress, Playwright, Puppeteer, Kraken,
# BackstopJS, PixelMatch, ResembleJS, monkey and ripper) the same way on any computer and in GitHub
# Actions. It has the operating system, Node.js, the system libraries of the tools, Debian's
# Chromium and a virtual display; it has no course code, no node_modules and no tool browsers (each
# repository installs them from its own lockfile, in volumes).
#
# Published to ghcr.io/uniandes-misw4103/misw4103-runner by .github/workflows/publish-runner.yml.
# Build locally: docker build -t misw4103-runner:node24 -f docker/runner.Dockerfile docker
ARG NODE_MAJOR=24
# Debian 13: Cypress on arm64 requires Debian >= 13 (its native addon needs GLIBCXX_3.4.32).
FROM node:${NODE_MAJOR}-trixie

LABEL org.opencontainers.image.source="https://github.com/Uniandes-MISW4103/proyecto-base-actions" \
      org.opencontainers.image.description="Runner de los módulos de pruebas del curso MISW4103" \
      org.opencontainers.image.licenses="MIT"

# Playwright release used only to install Chromium's system libraries (install-deps).
ARG PLAYWRIGHT_VERSION=1.63.0

# Package groups:
#  - rsync: used by scripts/install-module.sh
#  - xvfb, xauth: virtual display for headed browsers (Cypress, Kraken)
#  - libgtk-3-0t64 … libxtst6: Cypress Linux prerequisites (Debian 13 / Ubuntu 24.04 names)
#  - build-essential … librsvg2-dev: building node-canvas (ResembleJS)
#  - chromium: Puppeteer/BackstopJS on linux-arm64 (no Chrome for Testing build) and Kraken
# Debian package versions are not pinned on purpose: the base image tag pins the distribution.
# hadolint ignore=DL3008
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      rsync xvfb xauth \
      libgtk-3-0t64 libgbm-dev libnotify-dev libnss3 libxss1 libasound2t64 libxtst6 \
      build-essential python3 pkg-config libcairo2-dev libpango1.0-dev libjpeg-dev libgif-dev librsvg2-dev \
      chromium fonts-liberation \
 && npx --yes "playwright@${PLAYWRIGHT_VERSION}" install-deps chromium \
 && rm -rf /var/lib/apt/lists/* /root/.npm

# Repositories are mounted from the host and owned by another uid; allow git to read them.
RUN git config --system --add safe.directory '*'

# Caches of npm and of the tools' browsers (Cypress, Playwright, Puppeteer); volumes mounted there
# start with the node user's ownership.
RUN mkdir -p /home/node/.npm /home/node/.cache /work \
 && chown -R node:node /home/node /work

COPY --chmod=755 entrypoint.sh /usr/local/bin/misw4103-entrypoint

ENV CHROME_PATH=/usr/bin/chromium \
    PW_TEST_HTML_REPORT_OPEN=never

# The entrypoint starts as root only to fix the ownership of the mounted volumes, then runs the
# command as the owner of /work (see entrypoint.sh).
WORKDIR /work
ENTRYPOINT ["misw4103-entrypoint"]
CMD ["bash"]
