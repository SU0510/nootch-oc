#!/usr/bin/env bash
#
# release-setapp.sh — prepare a NotchNook Setapp release.
#
# Pipeline: archive (Release Setapp / SETAPP_BUILD) → export (Developer ID) →
# notarize → staple → zip. Leaves the notarized artifact in build/setapp/ ready
# for MANUAL upload to the Setapp developer portal.
#
# It does NOT upload: the Setapp portal login needs the Yubikey OTP and has no
# CLI, so publishing stays a manual step. This script only prepares the artifact.
#
# Usage:
#   ./release-setapp.sh [--dry-run] [--until=STEP] [--skip-build]
#       --dry-run      Print commands instead of running them.
#       --until=STEP   Stop after: archive, export, notarize, package.
#       --skip-build   Reuse an existing build/setapp/export/NotchNook.app.
#
# Must run on a machine with the "Developer ID Application" cert (Igor's Mac).

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

# ── Args ────────────────────────────────────────────────────────────────────
UNTIL=""
SKIP_BUILD=0
for arg in "$@"; do
    case "$arg" in
        --dry-run)     DRY_RUN=1 ;;
        --until=*)     UNTIL="${arg#*=}" ;;
        --skip-build)  SKIP_BUILD=1 ;;
        -h|--help)     sed -n '2,18p' "$0"; exit 0 ;;
        *)             die "Argumento desconhecido: $arg" ;;
    esac
done

stop_after() {
    if [[ -n "$UNTIL" && "$UNTIL" == "$1" ]]; then
        log "Parando após '$1' (--until)."
        exit 0
    fi
}

# ── Pre-flight ────────────────────────────────────────────────────────────────
step "Pré-checagens"
load_env
require_var NOTCHNOOK_REPO; require_var APPLE_TEAM_ID
[[ -d "$NOTCHNOOK_REPO" ]] || die "NOTCHNOOK_REPO não existe: $NOTCHNOOK_REPO"
check_signing_identity
check_notarytool
read_version "NotchNook Setapp" "Release Setapp"

BUILD_DIR="$SCRIPT_DIR/build/setapp"
ARCHIVE="$BUILD_DIR/NotchNook.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
APP="$EXPORT_DIR/NotchNook.app"
ZIP_PATH="$BUILD_DIR/NotchNook-Setapp-${APP_VERSION}.zip"

# ── Archive + Export ──────────────────────────────────────────────────────────
# The "Release Setapp" config carries SETAPP_BUILD in its compilation conditions
# and uses InfoSetapp.plist; the scheme name has a space.
if [[ "$SKIP_BUILD" == "1" ]]; then
    warn "--skip-build: reaproveitando $APP"
else
    run rm -rf "$ARCHIVE" "$EXPORT_DIR"
    build_export "NotchNook Setapp" "Release Setapp" "$ARCHIVE" "$EXPORT_DIR"
    stop_after export
fi
stop_after archive

[[ "$DRY_RUN" == "1" || -d "$APP" ]] || die "App exportado não encontrado em $APP"

# ── Notarize + Staple ───────────────────────────────────────────────────────
notarize_and_staple "$APP" "$BUILD_DIR"
stop_after notarize

# ── Package ─────────────────────────────────────────────────────────────────
step "Empacotar artefato Setapp"
run /usr/bin/ditto -c -k --keepParent "$APP" "$ZIP_PATH"
ok "Artefato: $ZIP_PATH"
stop_after package

# ── Stop before upload ──────────────────────────────────────────────────────
step "Pronto — SEM upload"
cat <<EOF

  O build Setapp está assinado, notarizado e empacotado:

    App: $APP
    Zip: $ZIP_PATH

  O upload é MANUAL (o portal Setapp exige o OTP do Yubikey e não tem CLI):
    1. Login em https://developer.setapp.com  (conta admin@lo.fi + OTP do Yubikey)
    2. NotchNook → nova versão ${APP_VERSION} (build ${BUILD_NUMBER})
    3. Suba o .app/zip notarizado acima e siga o fluxo de revisão do Setapp.

EOF
ok "Concluído."
