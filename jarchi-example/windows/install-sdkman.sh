#!/usr/bin/env bash
# Install SDKMAN into the current user's home directory from Git Bash.
# Zip archives are read and written with Windows tar.exe. Nothing is written
# under Program Files, and no separate zip program is installed.
#
# The two SDKMAN zip files are saved with a browser into sdkman-download/.
# This script does not download them.

set -euo pipefail

WIN_TAR="/c/Windows/System32/tar.exe"
BIN_DIR="${HOME}/.local/bin"
BASHRC="${HOME}/.bashrc"
# $0 is /usr/bin/bash under Git Bash, so dirname of it is /usr/bin.
# BASH_SOURCE is the script file that was started.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOWNLOAD_DIR="${SCRIPT_DIR}/sdkman-download"
SDKMAN_DIR="${HOME}/.sdkman"

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

# The browser download lands in sdkman-download/. Arguments override that folder.
cli_zip="${1:-}"
native_zip="${2:-}"
candidates_file="${3:-}"
if [[ -z "$cli_zip" && -d "$DOWNLOAD_DIR" ]]; then
  shopt -s nullglob
  cli_zips=("${DOWNLOAD_DIR}"/sdkman-cli-[0-9]*.zip)
  native_zips=("${DOWNLOAD_DIR}"/sdkman-cli-native-*-windows-msvc.zip)
  shopt -u nullglob
  cli_zip="${cli_zips[0]:-}"
  native_zip="${native_zips[0]:-}"
  if [[ -z "$candidates_file" && -f "${DOWNLOAD_DIR}/candidates.txt" ]]; then
    candidates_file="${DOWNLOAD_DIR}/candidates.txt"
  fi
fi

if [[ -f "${SDKMAN_DIR}/bin/sdkman-init.sh" ]]; then
  echo "SDKMAN is already installed at ${SDKMAN_DIR}."
  if [[ -n "$candidates_file" && -f "$candidates_file" ]]; then
    mkdir -p "${SDKMAN_DIR}/var"
    cp "$candidates_file" "${SDKMAN_DIR}/var/candidates"
    echo "Wrote ${SDKMAN_DIR}/var/candidates."
  else
    echo "Save https://api.sdkman.io/2/candidates/all as ${DOWNLOAD_DIR}/candidates.txt and run ./install-sdkman.sh again."
  fi
elif [[ ! -f "$cli_zip" || ! -f "$native_zip" ]]; then
  echo "Save these two zip files with your browser into:" >&2
  echo "  ${DOWNLOAD_DIR}" >&2
  echo >&2
  echo "  https://github.com/sdkman/sdkman-cli/releases/download/5.24.0/sdkman-cli-5.24.0.zip" >&2
  echo "  https://github.com/sdkman/sdkman-cli-native/releases/download/v0.8.0/sdkman-cli-native-0.8.0-x86_64-pc-windows-msvc.zip" >&2
  echo >&2
  echo "Also save https://api.sdkman.io/2/candidates/all as candidates.txt in that same folder." >&2
  echo "Then run ./install-sdkman.sh again." >&2
  exit 1
else
  stage="$(mktemp -d)"
  "${BIN_DIR}/unzip" -qo "$cli_zip" -d "$stage"
  "${BIN_DIR}/unzip" -qo "$native_zip" -d "$stage"

  shopt -s nullglob
  cli_dir=""
  native_dir=""
  for dir in "$stage"/sdkman-*; do
    base="$(basename "$dir")"
    if [[ "$base" == sdkman-cli-native-* ]]; then
      native_dir="$dir"
    elif [[ "$base" == sdkman-* ]]; then
      cli_dir="$dir"
    fi
  done
  shopt -u nullglob
  if [[ -z "$cli_dir" || -z "$native_dir" ]]; then
    echo "The zip files do not contain the sdkman-cli and sdkman-cli-native folders." >&2
    rm -rf "$stage"
    exit 1
  fi

  mkdir -p \
    "${SDKMAN_DIR}/tmp" \
    "${SDKMAN_DIR}/ext" \
    "${SDKMAN_DIR}/etc" \
    "${SDKMAN_DIR}/var" \
    "${SDKMAN_DIR}/candidates"
  cp -R "${cli_dir}/." "${SDKMAN_DIR}/"
  cp -R "${native_dir}/." "${SDKMAN_DIR}/"
  rm -rf "$stage"

  cli_version="$(basename "$cli_dir")"
  cli_version="${cli_version#sdkman-}"
  native_version="$(basename "$native_dir")"
  native_version="${native_version#sdkman-cli-native-}"
  native_version="${native_version%%-*}"
  printf '%s\n' "$cli_version" > "${SDKMAN_DIR}/var/version"
  printf '%s\n' "$native_version" > "${SDKMAN_DIR}/var/version_native"

  machine="$(uname -m)"
  case "$(uname -s)" in
    MSYS*|MINGW*)
      if [[ "$machine" == "x86_64" ]]; then
        printf '%s\n' "windowsx64" > "${SDKMAN_DIR}/var/platform"
      else
        printf '%s\n' "exotic" > "${SDKMAN_DIR}/var/platform"
      fi
      ;;
    *)
      printf '%s\n' "exotic" > "${SDKMAN_DIR}/var/platform"
      ;;
  esac

  if [[ ! -f "${SDKMAN_DIR}/etc/config" ]]; then
    cat > "${SDKMAN_DIR}/etc/config" << 'EOF'
sdkman_auto_answer=false
sdkman_auto_complete=true
sdkman_auto_env=false
sdkman_beta_channel=false
sdkman_checksum_enable=true
sdkman_colour_enable=true
sdkman_curl_connect_timeout=7
sdkman_curl_max_time=10
sdkman_debug_mode=false
sdkman_healthcheck_enable=true
sdkman_insecure_ssl=false
sdkman_native_enable=true
sdkman_selfupdate_feature=true
EOF
  fi

  if [[ -n "$candidates_file" && -f "$candidates_file" ]]; then
    cp "$candidates_file" "${SDKMAN_DIR}/var/candidates"
  else
    echo "candidates.txt was not in sdkman-download. sdk list needs that file or a later call to api.sdkman.io."
  fi

  if ! grep -q 'sdkman-init.sh' "$BASHRC"; then
    cat >> "$BASHRC" << 'EOF'

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
EOF
    echo "Added SDKMAN startup to ${BASHRC}."
  fi
  echo "Installed SDKMAN ${cli_version} (native ${native_version}) at ${SDKMAN_DIR}."
fi

echo
echo "Open a new Git Bash window, or run:  source \"\$HOME/.bashrc\""
echo "Then check the install with:         sdk version"
