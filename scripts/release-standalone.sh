#!/usr/bin/env bash
#
# release-standalone.sh — prepare a NotchNook standalone (Sparkle) release.
#
# Pipeline: archive → export (Developer ID) → notarize → staple → zip →
# regenerate the Sparkle appcast → copy into the lo-cafe repo.
#
# It STOPS before publishing: it never runs `git push` on lo-cafe. "Preparing
# a release without deploying" = everything up to, but not including, the push.
#
# Usage:
#   ./release-standalone.sh [--dry-run] [--until=STEP] [--skip-build]
#
#   --dry-run       Print every command instead of running it.
#   --until=STEP    Stop after STEP. One of: archive, export, notarize, package,
#                   appcast. (Default: run the whole pipeline.)
#   --skip-build    Reuse an existing build/export/NotchNook.app (skip archive+export).
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
        -h|--help)     sed -n '2,20p' "$0"; exit 0 ;;
        *)             die "Argumento desconhecido: $arg" ;;
    esac
done

# stop_after STEP — exits cleanly if --until matches the step just finished.
stop_after() {
    if [[ -n "$UNTIL" && "$UNTIL" == "$1" ]]; then
        log "Parando após '$1' (--until)."
        exit 0
    fi
}

# ── Pre-flight ────────────────────────────────────────────────────────────────
step "Pré-checagens"
load_env
require_var NOTCHNOOK_REPO; require_var LOCAFE_REPO; require_var APPLE_TEAM_ID
require_var APPCAST_DOWNLOAD_PREFIX; require_var SPARKLE_PRIVATE_KEY
[[ -d "$NOTCHNOOK_REPO" ]] || die "NOTCHNOOK_REPO não existe: $NOTCHNOOK_REPO"
[[ -d "$LOCAFE_REPO" ]]    || die "LOCAFE_REPO não existe: $LOCAFE_REPO"
check_signing_identity
check_sparkle_tools
check_notarytool
read_version "NotchNook" "Release"

BUILD_DIR="$SCRIPT_DIR/build/standalone"
ARCHIVE="$BUILD_DIR/NotchNook.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
APP="$EXPORT_DIR/NotchNook.app"
FILES_DIR="$LOCAFE_REPO/public/notchnook-files"
ZIP_NAME="NotchNook-${APP_VERSION}.zip"

[[ -d "$FILES_DIR" ]] || die "Pasta de arquivos do lo-cafe não existe: $FILES_DIR"

# ── Archive + Export ──────────────────────────────────────────────────────────
if [[ "$SKIP_BUILD" == "1" ]]; then
    warn "--skip-build: reaproveitando $APP"
else
    run rm -rf "$ARCHIVE" "$EXPORT_DIR"
    build_export "NotchNook" "Release" "$ARCHIVE" "$EXPORT_DIR"
    stop_after export
fi
stop_after archive

[[ "$DRY_RUN" == "1" || -d "$APP" ]] || die "App exportado não encontrado em $APP"

# ── Notarize + Staple ───────────────────────────────────────────────────────
notarize_and_staple "$APP" "$BUILD_DIR"
stop_after notarize

# ── Package ─────────────────────────────────────────────────────────────────
step "Empacotar $ZIP_NAME"
ZIP_PATH="$BUILD_DIR/$ZIP_NAME"
run /usr/bin/ditto -c -k --keepParent "$APP" "$ZIP_PATH"
ok "Zip criado: $ZIP_PATH"
stop_after package

# ── Appcast ─────────────────────────────────────────────────────────────────
step "Gerar appcast (Sparkle)"
# Place the zip alongside the existing archives so generate_appcast picks it up,
# computes deltas against older versions, and signs everything with the EdDSA key.
run cp "$ZIP_PATH" "$FILES_DIR/$ZIP_NAME"

# Feed the private key via stdin (--ed-key-file -) so it never touches disk.
if [[ "$DRY_RUN" == "1" ]]; then
    printf "%s  [dry-run]%s echo \$SPARKLE_PRIVATE_KEY | %s --ed-key-file - --download-url-prefix %s %s\n" \
        "$_C_DIM" "$_C_RESET" "$SPARKLE_GENERATE_APPCAST" "$APPCAST_DOWNLOAD_PREFIX" "$FILES_DIR"
else
    printf "%s" "$SPARKLE_PRIVATE_KEY" | "$SPARKLE_GENERATE_APPCAST" \
        --ed-key-file - \
        --download-url-prefix "$APPCAST_DOWNLOAD_PREFIX" \
        "$FILES_DIR"
    ok "appcast.xml regenerado em $FILES_DIR/appcast.xml"
fi
stop_after appcast

# ── Stop before deploy ──────────────────────────────────────────────────────
step "Pronto — SEM deploy"
cat <<EOF

  O build standalone está preparado e o appcast foi atualizado no repo lo-cafe,
  mas NADA foi publicado. Para revisar e publicar você mesmo:

    cd "$LOCAFE_REPO"
    git status
    git add public/notchnook-files/
    git commit -m "NN v${APP_VERSION}"
    git push        # ← isto publica (Vercel faz auto-deploy). Faça quando quiser.

  Lembrete: adicione notas de release em
    $FILES_DIR/NotchNook-${APP_VERSION}.html
  (mesmo padrão de NotchNook-1.5.5.html) e rode este script de novo, ou edite o
  appcast.xml — o Sparkle re-assina ao re-rodar generate_appcast.

EOF

if [[ "$DRY_RUN" != "1" ]]; then
    log "git status do lo-cafe:"
    git -C "$LOCAFE_REPO" status --short -- public/notchnook-files/ | sed 's/^/    /' || true
fi
ok "Concluído."
