#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  bash scripts/ipa_obfuscator/build_obfuscated_ipa.sh \
    -P <project_dir> \
    -s <scheme> \
    [-c <configuration>] \
    [-w <workspace_name>] \
    [-t <team_id>] \
    -p <export_options_plist> \
    -C <p12_path> \
    -W <p12_password_plaintext> \
    -F <mobileprovision_path> \
    [-m <export_method>] \
    [-a <archive_path>] \
    [-e <export_path>] \
    [-S <seed>] \
    [-A]

Options:
  -P  iOS project directory (contains .xcworkspace or .xcodeproj)
  -s  Xcode scheme
  -c  Build configuration (default: Release)
  -w  Workspace filename, e.g. MyApp.xcworkspace (optional auto-discovery)
  -t  Team ID (optional; used for logging/validation)
  -p  exportOptions.plist path
  -C  .p12 certificate path
  -W  .p12 password (plaintext argument)
  -F  .mobileprovision path
  -m  Export method: app-store/ad-hoc/development/enterprise (optional)
  -a  Archive output path (default: /tmp/<scheme>_obf.xcarchive)
  -e  IPA export directory (default: /tmp/<scheme>_ipa)
  -S  Seed for obfuscator (optional)
  -A  Enable aggressive random strategy
USAGE
}

PROJECT_DIR=""
SCHEME=""
CONFIGURATION="Release"
WORKSPACE_NAME=""
TEAM_ID=""
EXPORT_OPTIONS_PLIST=""
P12_PATH=""
P12_PASSWORD=""
MOBILEPROVISION_PATH=""
EXPORT_METHOD=""
ARCHIVE_PATH=""
EXPORT_PATH=""
SEED=""
AGGRESSIVE=0

while getopts ":P:s:c:w:t:p:C:W:F:m:a:e:S:Ah" opt; do
  case "$opt" in
    P) PROJECT_DIR="$OPTARG" ;;
    s) SCHEME="$OPTARG" ;;
    c) CONFIGURATION="$OPTARG" ;;
    w) WORKSPACE_NAME="$OPTARG" ;;
    t) TEAM_ID="$OPTARG" ;;
    p) EXPORT_OPTIONS_PLIST="$OPTARG" ;;
    C) P12_PATH="$OPTARG" ;;
    W) P12_PASSWORD="$OPTARG" ;;
    F) MOBILEPROVISION_PATH="$OPTARG" ;;
    m) EXPORT_METHOD="$OPTARG" ;;
    a) ARCHIVE_PATH="$OPTARG" ;;
    e) EXPORT_PATH="$OPTARG" ;;
    S) SEED="$OPTARG" ;;
    A) AGGRESSIVE=1 ;;
    h) usage; exit 0 ;;
    :) echo "[!] Option -$OPTARG requires an argument."; usage; exit 2 ;;
    \?) echo "[!] Unknown option: -$OPTARG"; usage; exit 2 ;;
  esac
done

require_file() {
  local path="$1"
  local label="$2"
  if [[ ! -f "$path" ]]; then
    echo "[!] $label not found: $path"
    exit 2
  fi
}

if [[ -z "$PROJECT_DIR" || -z "$SCHEME" || -z "$EXPORT_OPTIONS_PLIST" || -z "$P12_PATH" || -z "$P12_PASSWORD" || -z "$MOBILEPROVISION_PATH" ]]; then
  echo "[!] Missing required options."
  usage
  exit 2
fi

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "[!] Project directory not found: $PROJECT_DIR"
  exit 2
fi

require_file "$EXPORT_OPTIONS_PLIST" "exportOptions.plist"
require_file "$P12_PATH" "P12 certificate"
require_file "$MOBILEPROVISION_PATH" "Provisioning profile"

if [[ -n "$TEAM_ID" ]]; then
  echo "[i] Team ID: $TEAM_ID"
fi
if [[ -n "$EXPORT_METHOD" ]]; then
  echo "[i] Export method (declared): $EXPORT_METHOD"
fi

WORKSPACE_ARG=()
if [[ -n "$WORKSPACE_NAME" ]]; then
  WORKSPACE_ARG=(--workspace "$WORKSPACE_NAME")
else
  detected_workspace="$(find "$PROJECT_DIR" -maxdepth 1 -name '*.xcworkspace' -type d | head -n 1 || true)"
  if [[ -n "$detected_workspace" ]]; then
    WORKSPACE_ARG=(--workspace "$(basename "$detected_workspace")")
    echo "[i] Auto-detected workspace: $(basename "$detected_workspace")"
  fi
fi

if [[ -z "$ARCHIVE_PATH" ]]; then
  ARCHIVE_PATH="/tmp/${SCHEME}_obf.xcarchive"
fi
if [[ -z "$EXPORT_PATH" ]]; then
  EXPORT_PATH="/tmp/${SCHEME}_ipa"
fi

install_identity() {
  local keychain
  keychain="$HOME/Library/Keychains/login.keychain-db"
  echo "[+] Importing certificate into keychain"
  security import "$P12_PATH" -k "$keychain" -P "$P12_PASSWORD" -T /usr/bin/codesign -T /usr/bin/security >/dev/null

  echo "[+] Installing provisioning profile"
  local profiles_dir uuid tmp_plist
  profiles_dir="$HOME/Library/MobileDevice/Provisioning Profiles"
  mkdir -p "$profiles_dir"

  uuid=""
  tmp_plist="$(mktemp -t obf_profile_XXXXXX.plist)"
  if security cms -D -i "$MOBILEPROVISION_PATH" >"$tmp_plist" 2>/dev/null; then
    uuid="$(/usr/libexec/PlistBuddy -c 'Print UUID' "$tmp_plist" 2>/dev/null || true)"
  fi
  rm -f "$tmp_plist"

  if [[ -z "$uuid" ]]; then
    uuid="$(uuidgen)"
    echo "[!] Warning: failed to parse provisioning profile UUID, fallback to random name: $uuid"
  fi

  cp -f "$MOBILEPROVISION_PATH" "$profiles_dir/$uuid.mobileprovision"
  echo "[i] Profile UUID: $uuid"
}

install_identity

cmd=(python3 obfuscate.py
  "$PROJECT_DIR"
  --platform ios
  --project-mode
  --build-target ipa
  --scheme "$SCHEME"
  --configuration "$CONFIGURATION"
  --archive-path "$ARCHIVE_PATH"
  --export-path "$EXPORT_PATH"
  --export-options-plist "$EXPORT_OPTIONS_PLIST"
)

if [[ ${#WORKSPACE_ARG[@]} -gt 0 ]]; then
  cmd+=("${WORKSPACE_ARG[@]}")
fi
if [[ -n "$SEED" ]]; then
  cmd+=(--seed "$SEED")
fi
if [[ "$AGGRESSIVE" -eq 1 ]]; then
  cmd+=(--aggressive)
fi

echo "[+] Running obfuscation IPA build"
printf '    %q ' "${cmd[@]}"
echo
"${cmd[@]}"

echo "[+] Done"
echo "[i] Archive: $ARCHIVE_PATH"
echo "[i] Export dir: $EXPORT_PATH"
