#!/usr/bin/env bash
# One-command Mac launcher. Downloads the verified EDITH app, prepares it,
# opens the browser, and stops only the server this launcher started.
set -euo pipefail

EDITH_ROOT="${EDITH_INSTALL_ROOT:-$HOME/Library/Application Support/EDITH Core}"
EDITH_NODE_VERSION="24.19.0"
EDITH_RELEASE_URL="https://raw.githubusercontent.com/mw72rnd965-cyber/codex/edith-core-download/edith-release.json"
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
umask 077
mkdir -p "$EDITH_ROOT/versions" "$EDITH_ROOT/tools" "$EDITH_ROOT/logs"
EDITH_TEMP="$(mktemp -d "$EDITH_ROOT/.launch-XXXXXX")"

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

# The repository release manifest points to an immutable, checksummed ZIP.
# This also upgrades an existing demo installation without overwriting its files.
curl --fail --location --silent --show-error --retry 2 --max-time 60 "$EDITH_RELEASE_URL" --output "$EDITH_TEMP/release.json"
node - "$EDITH_TEMP" <<'JS'
const fs=require('node:fs');const dir=process.argv[2];
const release=JSON.parse(fs.readFileSync(dir+'/release.json','utf8'));
if(!/^[a-f0-9]{64}$/.test(release.sha256)||!/^https:\/\/github\.com\/mw72rnd965-cyber\/codex\/raw\/[a-f0-9]{40}\/EDITH-Core\.zip$/.test(release.url))throw Error('Invalid EDITH release manifest');
fs.writeFileSync(dir+'/sha.txt',release.sha256);fs.writeFileSync(dir+'/url.txt',release.url);
JS
EDITH_APP_SHA="$(cat "$EDITH_TEMP/sha.txt")"
EDITH_APP_URL="$(cat "$EDITH_TEMP/url.txt")"
EDITH_APP="$EDITH_ROOT/versions/$EDITH_APP_SHA/edith-core"
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
# Retain existing private preferences across app versions; never print their values.
if [ ! -f "$EDITH_ROOT/.env.local" ]; then
  node - "$EDITH_ROOT" "$EDITH_APP" <<'JS'
const fs=require('node:fs'),path=require('node:path');const root=process.argv[2],app=process.argv[3];
const old=fs.readdirSync(root+'/versions').map(v=>path.join(root,'versions',v,'edith-core','.env.local')).filter(p=>fs.existsSync(p)).sort((a,b)=>fs.statSync(b).mtimeMs-fs.statSync(a).mtimeMs);
fs.copyFileSync(old[0]||app+'/.env.example',root+'/.env.local');fs.chmodSync(root+'/.env.local',0o600);
JS
fi
if [ ! -f .env.local ]; then ln -s "$EDITH_ROOT/.env.local" .env.local; fi

export OLLAMA_BASE_URL="${OLLAMA_BASE_URL:-http://127.0.0.1:11434}"
node -e 'const u=new URL(process.env.OLLAMA_BASE_URL);if(!["http:","https:"].includes(u.protocol)||!["localhost","127.0.0.1","[::1]"].includes(u.hostname)||u.username||u.password||u.pathname!=="/"||u.search||u.hash)throw Error("Use a local Ollama address")'
if ! curl --fail --silent --max-time 2 "$OLLAMA_BASE_URL/api/tags" --output "$EDITH_TEMP/tags.json" 2>/dev/null; then
  printf 'Opening Ollama…\n'
  open -a Ollama || fail "Open the Ollama app once, then run this same EDITH command again."
  EDITH_OLLAMA_READY=0
  for EDITH_ATTEMPT in {1..120}; do
    if curl --fail --silent --max-time 2 "$OLLAMA_BASE_URL/api/tags" --output "$EDITH_TEMP/tags.json" 2>/dev/null; then EDITH_OLLAMA_READY=1; break; fi
    sleep .25
  done
  [ "$EDITH_OLLAMA_READY" = 1 ] || fail "Ollama did not start. Open Ollama and run this command again."
fi
node scripts/setup-ollama.mjs "$EDITH_TEMP/model.txt" "$EDITH_ROOT/ollama-model"
export AI_PROVIDER=ollama
export AI_MODEL="$(cat "$EDITH_TEMP/model.txt")"

# Reuse only a running copy that actually uses the selected local model.
# An older demo copy is left intact; this version uses another free port.
EDITH_RUNNING_SHA=""
if [ -f "$EDITH_ROOT/current-app-sha" ]; then EDITH_RUNNING_SHA="$(cat "$EDITH_ROOT/current-app-sha")"; fi
if [ -f "$EDITH_ROOT/current-port" ] && [ "$EDITH_RUNNING_SHA" = "$EDITH_APP_SHA" ]; then
  EDITH_PREVIOUS_PORT="$(cat "$EDITH_ROOT/current-port")"
  case "$EDITH_PREVIOUS_PORT" in
    ''|*[!0-9]*) ;;
    *)
      if curl --fail --silent --max-time 4 "http://127.0.0.1:$EDITH_PREVIOUS_PORT/api/config" --output "$EDITH_TEMP/current-config.json" 2>/dev/null; then
        if node -e 'const c=require(process.argv[1]);process.exit(c.provider==="ollama"&&c.model===process.env.AI_MODEL&&c.available===true?0:1)' "$EDITH_TEMP/current-config.json"; then
          printf 'EDITH is already connected to Ollama. Opening your browser.\n'
          open "http://127.0.0.1:$EDITH_PREVIOUS_PORT"
          exit 0
        fi
      fi
      ;;
  esac
fi
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
    if node -e 'const c=require(process.argv[1]);process.exit(c.mode==="live"&&c.provider==="ollama"&&c.model===process.env.AI_MODEL&&c.available===true?0:1)' "$EDITH_TEMP/config.json"; then EDITH_READY=1; break; fi
  fi
  kill -0 "$EDITH_APP_PID" 2>/dev/null || break
  sleep .25
done
if [ "$EDITH_READY" != 1 ]; then
  tail -n 30 "$EDITH_ROOT/logs/app.log" >&2
  fail "EDITH did not start. The error is shown above."
fi
printf '%s\n' "$EDITH_PORT" > "$EDITH_ROOT/current-port"
printf '%s\n' "$EDITH_APP_SHA" > "$EDITH_ROOT/current-app-sha"
if ! open "http://127.0.0.1:$EDITH_PORT"; then printf 'Open this in Safari: http://127.0.0.1:%s\n' "$EDITH_PORT"; fi
printf '\nEDITH is ready. Keep this window open. Press Control-C to stop.\n'
set +e
wait "$EDITH_APP_PID"
EDITH_EXIT=$?
set -e
exit "$EDITH_EXIT"
