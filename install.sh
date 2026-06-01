#!/usr/bin/env sh
set -eu

VERSION="${JO_CLI_VERSION:-latest}"
RELEASE_REPO="jo-inc/jo-cli-releases"
INSTALL_DIR="${JO_INSTALL_DIR:-$HOME/.local/share/jo-cli}"
BIN_DIR="${JO_BIN_DIR:-$HOME/.local/bin}"

if [ "$VERSION" = "latest" ]; then
  DISPLAY_VERSION="latest"
else
  DISPLAY_VERSION="$VERSION"
fi

TARBALL="jo-cli-${VERSION}.tar.gz"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: $1 is required" >&2
    exit 1
  fi
}

need_cmd node
need_cmd curl
need_cmd tar

if command -v shasum >/dev/null 2>&1; then
  SHA256_CMD="shasum -a 256"
elif command -v sha256sum >/dev/null 2>&1; then
  SHA256_CMD="sha256sum"
else
  echo "error: shasum or sha256sum is required" >&2
  exit 1
fi

node -e "const major = Number(process.versions.node.split('.')[0]); if (major < 18) process.exit(1)" || {
  echo "error: Jo CLI requires Node.js 18 or newer" >&2
  exit 1
}

if [ "$VERSION" = "latest" ]; then
  VERSION="$(curl -fsSL "https://api.github.com/repos/$RELEASE_REPO/releases/latest" | node -e "let data=''; process.stdin.on('data', c => data += c); process.stdin.on('end', () => { const release = JSON.parse(data); if (!release.tag_name) process.exit(1); console.log(release.tag_name.replace(/^v/, '')); });")"
  DISPLAY_VERSION="$VERSION"
  TARBALL="jo-cli-${VERSION}.tar.gz"
fi

BASE_URL="https://github.com/$RELEASE_REPO/releases/download/v$VERSION"
URL="$BASE_URL/$TARBALL"
SUMS_URL="$BASE_URL/SHA256SUMS"

TMP_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t jo-cli)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT INT TERM

echo "downloading Jo CLI $DISPLAY_VERSION..."
curl -fsSL "$URL" -o "$TMP_DIR/$TARBALL"
curl -fsSL "$SUMS_URL" -o "$TMP_DIR/SHA256SUMS"

EXPECTED_SHA="$(awk -v file="$TARBALL" '$2 == file || $2 == "dist/" file { print $1; exit }' "$TMP_DIR/SHA256SUMS")"
if [ -z "$EXPECTED_SHA" ]; then
  echo "error: checksum for $TARBALL not found" >&2
  exit 1
fi
ACTUAL_SHA="$(cd "$TMP_DIR" && $SHA256_CMD "$TARBALL" | awk '{ print $1 }')"
if [ "$EXPECTED_SHA" != "$ACTUAL_SHA" ]; then
  echo "error: checksum mismatch for $TARBALL" >&2
  exit 1
fi

if tar -tzf "$TMP_DIR/$TARBALL" | awk '
  $0 == "" { next }
  $0 ~ /^\// { bad = 1 }
  $0 ~ /(^|\/)\.\.($|\/)/ { bad = 1 }
  $0 !~ /^package\// { bad = 1 }
  END { exit bad ? 1 : 0 }
'; then
  :
else
  echo "error: release archive contains unsafe paths" >&2
  exit 1
fi

mkdir -p "$INSTALL_DIR" "$BIN_DIR"
rm -rf "$TMP_DIR/package"
tar -xzf "$TMP_DIR/$TARBALL" -C "$TMP_DIR"

for required in package/bin/jo.js package/src/main.js package/package.json; do
  if [ ! -f "$TMP_DIR/$required" ]; then
    echo "error: release archive missing $required" >&2
    exit 1
  fi
done

rm -rf "$INSTALL_DIR/current"
mkdir -p "$INSTALL_DIR/current"
cp -R "$TMP_DIR/package/"* "$INSTALL_DIR/current/"
chmod +x "$INSTALL_DIR/current/bin/jo.js"
ln -sfn "$INSTALL_DIR/current/bin/jo.js" "$BIN_DIR/jo"

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *)
    echo ""
    echo "add this to your shell profile if jo is not found:"
    echo "  export PATH=\"$BIN_DIR:\$PATH\""
    ;;
esac

echo ""
echo "installed Jo CLI to $INSTALL_DIR/current"
echo "run: jo login"
