#!/usr/bin/env bash
# Install SDKMAN into the current user's home directory from Git Bash.
# Zip archives are read and written with Windows tar.exe. Nothing is written
# under Program Files, and no separate zip program is installed.

set -euo pipefail

WIN_TAR="/c/Windows/System32/tar.exe"
BIN_DIR="${HOME}/.local/bin"
BASHRC="${HOME}/.bashrc"

if [[ ! -f "$WIN_TAR" ]]; then
  echo "Windows tar.exe was not found at C:\\Windows\\System32\\tar.exe." >&2
  echo "That program ships with Windows 10 and later and is what opens the zip archives." >&2
  exit 1
fi

mkdir -p "$BIN_DIR"

cat > "${BIN_DIR}/unzip" << 'EOF'
#!/usr/bin/env bash
# Enough of Info-ZIP unzip for SDKMAN. Archives are read with Windows tar.exe.
set -euo pipefail
WIN_TAR="/c/Windows/System32/tar.exe"
test_only=0
dest=""
archive=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d)
      dest="${2:-}"
      if [[ -z "$dest" ]]; then
        echo "unzip: -d needs a directory" >&2
        exit 1
      fi
      shift 2
      ;;
    -*)
      if [[ "$1" == *t* ]]; then
        test_only=1
      fi
      shift
      ;;
    *)
      archive="$1"
      shift
      ;;
  esac
done
if [[ -z "$archive" ]]; then
  echo "usage: unzip [-t|-qt|-qo|-oq] archive.zip [-d dir]" >&2
  exit 1
fi
if [[ "$test_only" -eq 1 ]]; then
  "$WIN_TAR" -tf "$archive" >/dev/null
  echo "No errors detected in compressed data of ${archive}."
  exit 0
fi
if [[ -n "$dest" ]]; then
  mkdir -p "$dest"
  "$WIN_TAR" -xf "$archive" -C "$dest"
else
  "$WIN_TAR" -xf "$archive"
fi
EOF

cat > "${BIN_DIR}/zip" << 'EOF'
#!/usr/bin/env bash
# Enough of Info-ZIP zip for SDKMAN. Archives are written with Windows tar.exe.
# On windowsx64 the Java and Maven hooks rename the download, so they do not
# call this command. The installer still requires it to be on PATH.
set -euo pipefail
WIN_TAR="/c/Windows/System32/tar.exe"
archive=""
files=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -*)
      shift
      ;;
    *)
      if [[ -z "$archive" ]]; then
        archive="$1"
      else
        files+=("$1")
      fi
      shift
      ;;
  esac
done
if [[ -z "$archive" ]]; then
  echo "usage: zip [-qr] archive.zip [files...]" >&2
  exit 1
fi
if [[ ${#files[@]} -eq 0 ]]; then
  files=(".")
fi
"$WIN_TAR" -a -c -f "$archive" "${files[@]}"
EOF

chmod +x "${BIN_DIR}/unzip" "${BIN_DIR}/zip"

export PATH="${BIN_DIR}:${PATH}"
hash -r

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
printf 'ok\n' > "${work}/note.txt"
(
  cd "$work"
  "${BIN_DIR}/zip" -q note.zip note.txt
)
"${BIN_DIR}/unzip" -qt "${work}/note.zip" >/dev/null
rm -rf "$work"
trap - EXIT
echo "zip and unzip are calling C:\\Windows\\System32\\tar.exe."

touch "$BASHRC"
if ! grep -q '\.local/bin' "$BASHRC"; then
  printf '\n# User commands. unzip and zip here call Windows tar.exe.\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$BASHRC"
  echo "Added \$HOME/.local/bin to ${BASHRC}."
fi

if [[ -f "${HOME}/.sdkman/bin/sdkman-init.sh" ]]; then
  echo "SDKMAN is already installed at ${HOME}/.sdkman."
else
  curl -fsSL "https://get.sdkman.io?rcupdate=true" | bash
fi

echo
echo "Open a new Git Bash window, or run:  source \"\$HOME/.bashrc\""
echo "Then check the install with:         sdk version"
