# NotchNook — release scripts

Two scripts to prepare a NotchNook release for its two distribution channels.
They do **everything except publish**: the standalone script stops before
`git push` on lo-cafe, and the Setapp script stops before the manual portal
upload. "Preparing without deploying."

| Script | Channel | Output |
|---|---|---|
| `release-standalone.sh` | Direct download (lo.cafe + Sparkle) | Signed/notarized zip + regenerated `appcast.xml`, copied into the lo-cafe repo (uncommitted) |
| `release-setapp.sh` | Setapp store | Signed/notarized `.app` + zip in `build/setapp/`, ready for manual upload |

`lib.sh` holds the shared helpers; `.env` holds the secrets.

## Prerequisites

- **Must run on the Mac that has the `Developer ID Application` certificate**
  (Igor's Mac). The scripts check for it and abort with a clear message if it's
  missing. Verify with:
  ```sh
  security find-identity -v -p codesigning | grep "Developer ID Application"
  ```
- Xcode installed, and the project opened at least once so SPM has fetched
  Sparkle (the scripts locate `generate_appcast` inside DerivedData).
- Both repos checked out: `~/Projects/NotchNook` and `~/Projects/lo-cafe`
  (paths are configurable in `.env`).

## Setup

```sh
cd ~/Projects/NotchNook/scripts
cp .env.example .env      # then fill in the real secrets
```

`.env` is gitignored — never commit it. `.env.example` (no secrets) is the
committed template.

## Usage

```sh
# Standalone (Sparkle)
./release-standalone.sh --dry-run            # print every step, run nothing
./release-standalone.sh --until=notarize     # run for real, stop after stapling
./release-standalone.sh                      # full run → updates appcast in lo-cafe
./release-standalone.sh --skip-build         # reuse the last exported .app

# Setapp
./release-setapp.sh --dry-run
./release-setapp.sh                          # full run → artifact in build/setapp/
```

### Flags
- `--dry-run` — print each command instead of executing. Validates paths, cert
  detection, Sparkle tool discovery, and version parsing without building.
- `--until=STEP` — stop after a step. Standalone: `archive, export, notarize,
  package, appcast`. Setapp: `archive, export, notarize, package`.
- `--skip-build` — reuse an existing exported app (skip archive+export).

### Env escape hatch
- `ALLOW_NO_CERT=1` — only for validating pipeline *logic* on a machine that
  lacks the Developer ID cert (turns the hard cert check into a warning). It
  does **not** produce a signable build; never set it for a real run. Example:
  `ALLOW_NO_CERT=1 ./release-standalone.sh --dry-run`.

## Recommended validation sequence (no deploy)

1. `./release-standalone.sh --dry-run` — sanity-check the whole pipeline.
2. `./release-standalone.sh --until=notarize` — prove signing + notarization
   work against the real Apple credentials. Verify with:
   ```sh
   spctl -a -vv --type execute build/standalone/export/NotchNook.app
   xcrun stapler validate build/standalone/export/NotchNook.app
   ```
3. `./release-standalone.sh` — full run. Then confirm the appcast/zip landed in
   lo-cafe **without being committed or pushed**:
   ```sh
   git -C ~/Projects/lo-cafe status public/notchnook-files/
   ```
4. `./release-setapp.sh --dry-run`, then a full run — confirm the notarized
   artifact in `build/setapp/`.

## Publishing (the deploy — do this manually when ready)

- **Standalone:** in `~/Projects/lo-cafe`, optionally add release notes at
  `public/notchnook-files/NotchNook-<version>.html`, then
  `git add public/notchnook-files/ && git commit -m "NN v<version>" && git push`.
  Vercel auto-deploys. Sparkle clients pick up the new `appcast.xml`.
- **Setapp:** log into the Setapp developer portal (Yubikey OTP) and upload the
  artifact from `build/setapp/`.

## Security notes

- Secrets live only in `.env` (gitignored). The decoded `.p8` and the Sparkle
  key are written to mode-600 temp files (or piped via stdin) and shredded on
  exit — never hardcoded.
- ⚠️ The source `~/Desktop/release-instructions.md` holds these secrets in plain
  text, including the **Setapp account password**. Recommend rotating that
  password and moving the secrets off the Desktop into a password manager.
