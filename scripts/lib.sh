#!/usr/bin/env bash
#
# lib.sh — shared helpers for the NotchNook release scripts.
#
# Sourced by release-standalone.sh and release-setapp.sh. Provides logging,
# .env loading, dry-run plumbing, and all the pre-flight checks (signing
# identity, Sparkle tools, notarytool, version parsing).
#
# Nothing here runs on its own; it only defines functions + globals.

set -euo pipefail

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

if [[ -t 1 ]]; then
    _C_BLUE=$'\033[0;34m'; _C_GREEN=$'\033[0;32m'; _C_YELLOW=$'\033[0;33m'
    _C_RED=$'\033[0;31m'; _C_DIM=$'\033[2m'; _C_RESET=$'\033[0m'
else
    _C_BLUE=""; _C_GREEN=""; _C_YELLOW=""; _C_RED=""; _C_DIM=""; _C_RESET=""
fi

log()   { printf "%s==>%s %s\n" "$_C_BLUE"  "$_C_RESET" "$*"; }
ok()    { printf "%s  ✓%s %s\n" "$_C_GREEN" "$_C_RESET" "$*"; }
warn()  { printf "%s  !%s %s\n" "$_C_YELLOW" "$_C_RESET" "$*" >&2; }
die()   { printf "%s  ✗ %s%s\n" "$_C_RED" "$*" "$_C_RESET" >&2; exit 1; }
step()  { printf "\n%s━━ %s ━━%s\n" "$_C_BLUE" "$*" "$_C_RESET"; }

# ---------------------------------------------------------------------------
# Dry-run
#
# DRY_RUN=1 makes run() print the command instead of executing it. Use run()
# for every state-changing command so --dry-run covers the whole pipeline.
# ---------------------------------------------------------------------------

DRY_RUN="${DRY_RUN:-0}"

run() {
    if [[ "$DRY_RUN" == "1" ]]; then
        # %q quotes each arg so args with spaces (scheme/config names) read as a
        # single token instead of looking like two separate arguments.
        printf "%s  [dry-run]%s" "$_C_DIM" "$_C_RESET"
        printf " %q" "$@"
        printf "\n"
    else
        "$@"
    fi
}

# Like run(), but for shell pipelines/redirections passed as a single string.
run_sh() {
    if [[ "$DRY_RUN" == "1" ]]; then
        printf "%s  [dry-run]%s %s\n" "$_C_DIM" "$_C_RESET" "$1"
    else
        bash -c "$1"
    fi
}

# ---------------------------------------------------------------------------
# .env loading
# ---------------------------------------------------------------------------

# Load scripts/.env (next to the scripts). Exports every KEY=VALUE. $HOME and
# other vars inside values are expanded because we `source` it.
load_env() {
    local env_file="${1:-$SCRIPT_DIR/.env}"
    [[ -f "$env_file" ]] || die ".env não encontrado em $env_file — copie .env.example para .env e preencha."
    set -a
    # shellcheck disable=SC1090
    source "$env_file"
    set +a
    ok ".env carregado de $env_file"

    # Derive repo paths from the script's own location so the scripts work on any
    # machine without hardcoding paths (this Mac uses ~/Projects, Igor's uses
    # ~/Desktop/projects). The .env may still override these explicitly.
    : "${NOTCHNOOK_REPO:=$(cd "$SCRIPT_DIR/.." && pwd)}"
    : "${LOCAFE_REPO:=$(cd "$NOTCHNOOK_REPO/.." && pwd)/lo-cafe}"
    export NOTCHNOOK_REPO LOCAFE_REPO
    ok "NOTCHNOOK_REPO=$NOTCHNOOK_REPO"
    ok "LOCAFE_REPO=$LOCAFE_REPO"
}

require_var() {
    local name="$1"
    [[ -n "${!name:-}" ]] || die "Variável obrigatória ausente no .env: $name"
}

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------

# Resolve the Developer ID Application identity. If CODESIGN_IDENTITY is set to
# a full SHA-1 or exact name it's used as-is; otherwise we auto-detect the first
# "Developer ID Application" identity in the keychain. Sets CODESIGN_IDENTITY.
check_signing_identity() {
    local found
    found="$(security find-identity -v -p codesigning 2>/dev/null | grep "Developer ID Application" || true)"
    if [[ -z "$found" ]]; then
        # Escape hatch for validating the pipeline logic on a machine without the
        # cert (e.g. dry-runs). NEVER set this for a real signing run.
        if [[ "${ALLOW_NO_CERT:-0}" == "1" ]]; then
            warn "ALLOW_NO_CERT=1 — seguindo sem cert (apenas validação; NÃO produz build assinável)."
            CODESIGN_IDENTITY="Developer ID Application"
            return 0
        fi
        die "Nenhum certificado 'Developer ID Application' no keychain.
       Este script precisa rodar na máquina que tem o cert de distribuição (Mac do Igor).
       Verifique com: security find-identity -v -p codesigning"
    fi
    # If the user pinned an exact identity, trust it; else use the detected one.
    if [[ "${CODESIGN_IDENTITY:-Developer ID Application}" == "Developer ID Application" ]]; then
        # Extract the quoted identity name from the first matching line.
        CODESIGN_IDENTITY="$(printf "%s\n" "$found" | head -1 | sed -E 's/^[[:space:]]*[0-9]+\)[[:space:]]+[0-9A-F]+[[:space:]]+"([^"]+)"$/\1/')"
    fi
    ok "Identidade de assinatura: $CODESIGN_IDENTITY"
}

# Locate Sparkle's generate_appcast / sign_update inside DerivedData. Sets
# SPARKLE_GENERATE_APPCAST and SPARKLE_SIGN_UPDATE.
check_sparkle_tools() {
    SPARKLE_GENERATE_APPCAST="$(find "$HOME/Library/Developer/Xcode/DerivedData" \
        -path "*artifacts/sparkle/Sparkle/bin/generate_appcast" 2>/dev/null | head -1)"
    SPARKLE_SIGN_UPDATE="$(find "$HOME/Library/Developer/Xcode/DerivedData" \
        -path "*artifacts/sparkle/Sparkle/bin/sign_update" 2>/dev/null | head -1)"
    [[ -x "$SPARKLE_GENERATE_APPCAST" ]] || die "generate_appcast não encontrado. Abra o projeto no Xcode uma vez para o SPM baixar o Sparkle."
    ok "Sparkle generate_appcast: $SPARKLE_GENERATE_APPCAST"
}

check_notarytool() {
    xcrun --find notarytool >/dev/null 2>&1 || die "notarytool não encontrado (precisa de Xcode 13+ com Command Line Tools)."
    ok "notarytool disponível"
}

# Read the authoritative MARKETING_VERSION / CURRENT_PROJECT_VERSION for a given
# scheme+configuration via xcodebuild. A plain grep of project.pbxproj is wrong
# here — the file has multiple targets (the Tests target carries 1.0/1), so we
# ask xcodebuild to resolve the value for the actual app build.
# Args: <scheme> <configuration>. Sets APP_VERSION and BUILD_NUMBER.
read_version() {
    local scheme="$1" config="$2"
    local settings
    settings="$(xcodebuild -project "$NOTCHNOOK_REPO/NotchNook.xcodeproj" \
        -scheme "$scheme" -configuration "$config" -showBuildSettings 2>/dev/null)" \
        || die "xcodebuild -showBuildSettings falhou para scheme '$scheme' / config '$config'."
    APP_VERSION="$(printf "%s\n" "$settings"  | awk -F' = ' '/ MARKETING_VERSION = /{print $2; exit}')"
    BUILD_NUMBER="$(printf "%s\n" "$settings" | awk -F' = ' '/ CURRENT_PROJECT_VERSION = /{print $2; exit}')"
    [[ -n "$APP_VERSION" && -n "$BUILD_NUMBER" ]] || die "Não consegui ler versão/build via xcodebuild."
    ok "Versão: $APP_VERSION (build $BUILD_NUMBER)"
}

# ---------------------------------------------------------------------------
# Secret material → temp files (mode 600), wiped on exit.
# ---------------------------------------------------------------------------

# Tracks temp files created from secrets so the EXIT trap can shred them.
_SECRET_TMPFILES=()

cleanup_secrets() {
    local f
    for f in "${_SECRET_TMPFILES[@]:-}"; do
        [[ -f "$f" ]] && rm -f "$f"
    done
}
trap cleanup_secrets EXIT

# Decode the base64 App Store Connect .p8 into a temp file. Echoes the path.
# notarytool requires the key file to end in .p8, so we create the temp file
# then rename it (mktemp + a fixed suffix in one step isn't portable on macOS).
write_p8_tempfile() {
    require_var APPLE_API_KEY_P8_BASE64
    local base tmp
    base="$(mktemp -t nn_apikey)"
    tmp="${base}.p8"
    mv "$base" "$tmp"
    chmod 600 "$tmp"
    printf "%s" "$APPLE_API_KEY_P8_BASE64" | base64 --decode > "$tmp"
    _SECRET_TMPFILES+=("$tmp")
    printf "%s" "$tmp"
}

# ---------------------------------------------------------------------------
# Notarization helpers (shared by both pipelines)
# ---------------------------------------------------------------------------

# notarize_and_staple <app_path> <workdir>
# Zips the .app, submits to notarytool (waits), then staples the .app.
notarize_and_staple() {
    local app="$1" workdir="$2"
    local notarize_zip="$workdir/notarize.zip"

    step "Notarizar"
    require_var APPLE_API_KEY_ID; require_var APPLE_API_ISSUER_ID
    local p8; p8="$(write_p8_tempfile)"

    run /usr/bin/ditto -c -k --keepParent "$app" "$notarize_zip"
    run xcrun notarytool submit "$notarize_zip" \
        --key "$p8" \
        --key-id "$APPLE_API_KEY_ID" \
        --issuer "$APPLE_API_ISSUER_ID" \
        --wait
    run rm -f "$notarize_zip"
    ok "Notarização concluída"

    step "Staple"
    run xcrun stapler staple "$app"
    if [[ "$DRY_RUN" != "1" ]]; then
        xcrun stapler validate "$app" && ok "Staple validado"
        spctl -a -vv --type execute "$app" 2>&1 | sed 's/^/    /' || warn "spctl reportou problema — confira acima"
    fi
}

# build_export <scheme> <configuration> <archive_path> <export_dir>
# Archives and exports a Developer ID-signed .app. Echoes nothing; the exported
# app lands at <export_dir>/NotchNook.app.
build_export() {
    local scheme="$1" config="$2" archive="$3" export_dir="$4"

    step "Archive ($scheme / $config)"
    run xcodebuild archive \
        -project "$NOTCHNOOK_REPO/NotchNook.xcodeproj" \
        -scheme "$scheme" \
        -configuration "$config" \
        -archivePath "$archive" \
        DEVELOPMENT_TEAM="$APPLE_TEAM_ID" \
        CODE_SIGN_IDENTITY="$CODESIGN_IDENTITY" \
        CODE_SIGN_STYLE=Manual \
        -allowProvisioningUpdates

    step "Export (developer-id)"
    local opts="$export_dir/ExportOptions.plist"
    run mkdir -p "$export_dir"
    write_export_options "$opts"
    run xcodebuild -exportArchive \
        -archivePath "$archive" \
        -exportPath "$export_dir" \
        -exportOptionsPlist "$opts"
}

# write_export_options <path> — generates the Developer ID ExportOptions.plist.
write_export_options() {
    local path="$1"
    if [[ "$DRY_RUN" == "1" ]]; then
        printf "%s  [dry-run]%s escreveria ExportOptions.plist em %s\n" "$_C_DIM" "$_C_RESET" "$path"
        return
    fi
    cat > "$path" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>${APPLE_TEAM_ID}</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>Developer ID Application</string>
</dict>
</plist>
PLIST
}
