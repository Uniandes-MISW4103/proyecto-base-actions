#!/bin/sh
# Entry point of the MISW4103 runner image. Runs the command:
#  - as the owner of /work (the repository mounted from the host), so the files it creates belong
#    to the student on Linux; uid 1000 (node) when the owner is root, as Docker Desktop reports;
#  - inside a virtual display (Cypress, Kraken and headed browsers need one);
#  - on linux/arm64, with Debian's Chromium for Puppeteer (Chrome for Testing has no build for it).
set -eu

uid=$(stat -c %u /work)
gid=$(stat -c %g /work)
if [ "$uid" = 0 ]; then uid=1000 gid=1000; fi

if [ "$(id -u)" = 0 ]; then
  # New volumes (node_modules of each module, caches) are created owned by root.
  for dir in /home/node /home/node/.npm /home/node/.cache /work/node_modules /work/*/*/node_modules; do
    if [ -d "$dir" ] && [ "$(stat -c %u "$dir")" != "$uid" ]; then chown "$uid:$gid" "$dir"; fi
  done
  set -- setpriv --reuid="$uid" --regid="$gid" --clear-groups "$@"
fi

if [ "$(uname -m)" = aarch64 ]; then
  export PUPPETEER_SKIP_DOWNLOAD=true PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
fi

# Xvfb is started here instead of with xvfb-run, which never starts the command when it is the
# container's first process (docker run without --init, GitHub Actions containers).
Xvfb :99 -screen 0 1280x1024x24 -nolisten tcp >/dev/null 2>&1 &
for _ in $(seq 50); do [ -S /tmp/.X11-unix/X99 ] && break; sleep 0.1; done
export DISPLAY=:99 HOME=/home/node
exec "$@"
