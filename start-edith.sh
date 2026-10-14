#!/usr/bin/env bash
# One-command Mac launcher. Downloads the verified EDITH app, prepares it,
# opens the browser, and stops only the server this launcher started.
set -euo pipefail

EDITH_ROOT="${EDITH_INSTALL_ROOT:-$HOME/Library/Application Support/EDITH Core}"
EDITH_NODE_VERSION="24.19.0"
EDITH_APP_SHA="c42e4ec09cd3a64d7d233bd4c6e1f3d3bd142fa6a494556e317eaf70cb6c9597"
EDITH_APP_URL="https://github.com/mw72rnd965-cyber/codex/raw/bf8793101fa4263e3f9c29636d9f378efcde23cf/EDITH-Core.zip"
EDITH_APP="$EDITH_ROOT/versions/$EDITH_APP_SHA/edith-core"
EDITH_APP_PID=""
EDITH_TEMP=""

fail() { printf '\n%s\n' "$1" >&2; exit 1; }
cleanup() {
  if [ -n "$EDITH_APP_PID" ]; then
    kill "$EDITH_APP_PID" 2>/dev/null || true
    wait "$EDITH_APP_PID" 2>/dev/null || true
  fi
  if [ -n "$EDITH_TEMP" ]; then rm -rf "$EDITH_TEMP"; fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

[ "$(uname -s)" = "Darwin" ] || fail "This launcher is for macOS. See the project README for other platforms."
mkdir -p "$EDITH_ROOT/versions" "$EDITH_ROOT/tools" "$EDITH_ROOT/logs"
EDITH_TEMP="$(mktemp -d "$EDITH_ROOT/.launch-XXXXXX")"

# Repeated launches reuse an already running copy and preserve all local files.
if [ -f "$EDITH_ROOT/current-port" ]; then
  EDITH_PREVIOUS_PORT="$(cat "$EDITH_ROOT/current-port")"
  case "$EDITH_PREVIOUS_PORT" in
    ''|*[!0-9]*) ;;
    *)
      if curl --fail --silent --max-time 2 "http://127.0.0.1:$EDITH_PREVIOUS_PORT" --output "$EDITH_TEMP/page.html" 2>/dev/null; then
        if LC_ALL=C grep -Fq 'EDITH · Your intelligence, present' "$EDITH_TEMP/page.html"; then
          printf 'EDITH is already running. Opening your browser.\n'
          open "http://127.0.0.1:$EDITH_PREVIOUS_PORT"
          exit 0
        fi
      fi
      ;;
  esac
fi

printf 'Starting EDITH. First setup can take a few minutes.\n'
# Node is installed locally only if a compatible version is not already present.
if ! command -v node >/dev/null 2>&1 || ! node -e 'process.exit(Number(process.versions.node.split(".")[0]) >= 24 ? 0 : 1)' 2>/dev/null; then
  case "$(uname -m)" in
    arm64) EDITH_ARCH="arm64"; EDITH_NODE_SHA="8294b7aa9b03997481c06babf1e8b270c859358f27da57a11509afe537ac381d" ;;
    x86_64) EDITH_ARCH="x64"; EDITH_NODE_SHA="d1b5e999db158c62fe8f7267a4476b035d8bd93b1a605bac24a3f0dd166e3316" ;;
    *) fail "This Mac's processor is not supported by the launcher." ;;
  esac
  EDITH_NODE_DIR="$EDITH_ROOT/tools/node-v$EDITH_NODE_VERSION-darwin-$EDITH_ARCH"
  if [ ! -x "$EDITH_NODE_DIR/bin/node" ]; then
    printf 'Installing Node.js locally—no administrator access needed.\n'
    EDITH_NODE_FILE="node-v$EDITH_NODE_VERSION-darwin-$EDITH_ARCH.tar.gz"
    curl --fail --location --silent --show-error --retry 2 --connect-timeout 20 --max-time 600 \
      "https://nodejs.org/dist/v$EDITH_NODE_VERSION/$EDITH_NODE_FILE" --output "$EDITH_TEMP/node.tar.gz"
    printf '%s  %s\n' "$EDITH_NODE_SHA" "$EDITH_TEMP/node.tar.gz" | shasum -a 256 -c - >/dev/null || fail "Node.js verification failed. No downloaded runtime was used."
    mkdir "$EDITH_TEMP/node"
    tar -xzf "$EDITH_TEMP/node.tar.gz" -C "$EDITH_TEMP/node"
    mv "$EDITH_TEMP/node/node-v$EDITH_NODE_VERSION-darwin-$EDITH_ARCH" "$EDITH_NODE_DIR"
  fi
  export PATH="$EDITH_NODE_DIR/bin:$PATH"
fi
node -e 'if(Number(process.versions.node.split(".")[0]) < 24) throw Error("Node.js 24+ required")'
command -v npm >/dev/null 2>&1 || fail "This Node.js installation has no npm. Install Node.js with npm, then run this launcher again."

if [ ! -d "$EDITH_APP" ]; then
  printf 'Downloading EDITH…\n'
  curl --fail --location --silent --show-error --retry 2 --connect-timeout 20 --max-time 180 \
    "$EDITH_APP_URL" --output "$EDITH_TEMP/EDITH-Core.zip"
  printf '%s  %s\n' "$EDITH_APP_SHA" "$EDITH_TEMP/EDITH-Core.zip" | shasum -a 256 -c - >/dev/null || fail "EDITH verification failed. No downloaded application was used."
  mkdir "$EDITH_TEMP/app"
  unzip -q "$EDITH_TEMP/EDITH-Core.zip" -d "$EDITH_TEMP/app"
  [ -f "$EDITH_TEMP/app/edith-core/package-lock.json" ] || fail "The EDITH package is incomplete."
  # Move the verified extraction into its own version, without overwriting edits.
  mv "$EDITH_TEMP/app" "$EDITH_ROOT/versions/$EDITH_APP_SHA"
fi
cd "$EDITH_APP"
if [ ! -f .env.local ]; then cp .env.example .env.local; fi
EDITH_SIGNATURE="$(shasum -a 256 package-lock.json | awk '{print $1}')-$(node --version)"
EDITH_INSTALLED_SIGNATURE=""
if [ -f .edith-setup-signature ]; then EDITH_INSTALLED_SIGNATURE="$(cat .edith-setup-signature)"; fi
if [ "$EDITH_SIGNATURE" != "$EDITH_INSTALLED_SIGNATURE" ] || [ ! -f node_modules/next/dist/bin/next ] || [ ! -f .next/BUILD_ID ]; then
  printf 'Preparing EDITH. Please keep this window open…\n'
  if ! npm ci --cache "$EDITH_ROOT/npm-cache" --no-audit --no-fund > "$EDITH_ROOT/logs/setup.log" 2>&1; then
    tail -n 30 "$EDITH_ROOT/logs/setup.log" >&2
    fail "Dependency setup failed. Run the same launcher again after checking your Internet connection."
  fi
  if ! npm run build >> "$EDITH_ROOT/logs/setup.log" 2>&1; then
    tail -n 30 "$EDITH_ROOT/logs/setup.log" >&2
    fail "EDITH could not build. The details are shown above."
  fi
  printf '%s\n' "$EDITH_SIGNATURE" > .edith-setup-signature
fi

# Find a free loopback port instead of making the user resolve port conflicts.
EDITH_PORT="$(node --input-type=module <<'JS'
import net from 'node:net';
function probe(port) {
  if (port > 3020) { console.error('No free EDITH port was found.'); process.exit(1); }
  const server=net.createServer();
  server.once('error',error=>{if(error.code==='EADDRINUSE')probe(port+1);else{console.error('Cannot start the local server.');process.exit(1);}});
  server.listen(port,'127.0.0.1',()=>server.close(()=>console.log(port)));
}
probe(3001);
JS
)"
node node_modules/next/dist/bin/next start --hostname 127.0.0.1 --port "$EDITH_PORT" > "$EDITH_ROOT/logs/app.log" 2>&1 &
EDITH_APP_PID=$!
EDITH_READY=0
for EDITH_ATTEMPT in {1..80}; do
  if curl --fail --silent --max-time 2 "http://127.0.0.1:$EDITH_PORT/api/config" --output "$EDITH_TEMP/config.json" 2>/dev/null; then
    if node -e 'const c=require(process.argv[1]);process.exit(["demo","live"].includes(c.mode)&&typeof c.speech==="boolean"&&typeof c.transcription==="boolean"?0:1)' "$EDITH_TEMP/config.json"; then EDITH_READY=1; break; fi
  fi
  kill -0 "$EDITH_APP_PID" 2>/dev/null || break
  sleep .25
done
if [ "$EDITH_READY" != 1 ]; then
  tail -n 30 "$EDITH_ROOT/logs/app.log" >&2
  fail "EDITH did not start. The error is shown above."
fi
printf '%s\n' "$EDITH_PORT" > "$EDITH_ROOT/current-port"
if ! open "http://127.0.0.1:$EDITH_PORT"; then printf 'Open this in Safari: http://127.0.0.1:%s\n' "$EDITH_PORT"; fi
printf '\nEDITH is ready. Keep this window open. Press Control-C to stop.\n'
set +e
wait "$EDITH_APP_PID"
EDITH_EXIT=$?
set -e
exit "$EDITH_EXIT"
