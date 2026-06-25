# NotchNook 1.6.0 — status da release

**Data:** 2026-06-24 · **Versão:** 1.6.0 (build 42) · **Branch:** `dev-1.6-scratch`

As duas frentes foram **preparadas, assinadas e notarizadas**, mas **NADA foi
publicado ainda** (sem `git push` no lo-cafe, sem upload no Setapp). Falta só o
passo de lançamento, abaixo.

---

## ✅ O que está pronto

### Código (repo NotchNook)
Commitado e pushado em `origin/dev-1.6-scratch`:
- Tela de changelog 1.6.0 (vídeos dos widgets Timer/To-do, janela rolável/limitada
  à tela, decorações fixas no fundo).
- Fix do widget Timer (remoção do `defaultLabel` morto — bug do label "eu").
- Scripts de release (`scripts/`).
- Ajuste fino do Liquid Glass do timer (WIP do Igor: `NativeGlassPill.swift` +
  `LiveActivitiesGeneralSettingsTabView.swift`).

### Standalone (Sparkle) — no repo lo-cafe, NÃO commitado
- `public/notchnook-files/NotchNook-1.6.0.zip` — app assinado (Developer ID) e
  notarizado pela Apple.
- 5 deltas de update incremental (`NotchNook42-*.delta`).
- `appcast.xml` regenerado e assinado (EdDSA).
- `NotchNook-1.6.0.html` (release notes, embutidas no appcast — confirmado).

### Setapp — no Mac do Igor
- `scripts/build/setapp/NotchNook-Setapp-1.6.0.zip` — assinado + notarizado,
  pronto para upload manual.

---

## 🚀 Para LANÇAR (isto SIM publica)

### 1. Standalone — no Mac do Igor
```sh
cd ~/Desktop/projects/lo-cafe
git add public/notchnook-files/
git commit -m "NN v1.6.0"
git push          # Vercel faz auto-deploy → usuários recebem via Sparkle
```

### 2. Setapp — upload manual
- Login em https://developer.setapp.com (conta admin@lo.fi + OTP da Yubikey).
- NotchNook → nova versão 1.6.0 (build 42).
- Subir `scripts/build/setapp/NotchNook-Setapp-1.6.0.zip` e seguir a revisão.

### 3. Código — abrir PR (opcional)
A branch `dev-1.6-scratch` está pushada; abrir PR para `main` quando quiser.

---

## 🔁 Como reproduzir os builds (próximas releases)

Tudo roda no Mac que tem o certificado **Developer ID Application: LO CAFE LTDA**
(atualmente o Mac do Igor / `kinark`). Os scripts auto-detectam os caminhos dos
repos. Ver `scripts/README.md` para detalhes e flags.

```sh
cd ~/Desktop/projects/notchnook/scripts
./release-standalone.sh --dry-run        # confere
./release-standalone.sh                  # build → sign → notarize → appcast (sem push)
./release-setapp.sh                      # idem para Setapp (sem upload)
```

### Setup de assinatura feito nesta máquina (não repetir se já estiver ok)
O certificado de distribuição foi importado num keychain dedicado de build para
evitar a senha desconhecida do keychain de login:
```sh
security create-keychain -p buildpass ~/Library/Keychains/nnbuild.keychain-db
security unlock-keychain -p buildpass ~/Library/Keychains/nnbuild.keychain-db
security import ~/Downloads/lo.cafe-dev-id-application-keystore.p12 \
  -k ~/Library/Keychains/nnbuild.keychain-db -T /usr/bin/codesign -T /usr/bin/security
security set-key-partition-list -S apple-tool:,apple: -k buildpass \
  ~/Library/Keychains/nnbuild.keychain-db
security list-keychains -d user -s ~/Library/Keychains/nnbuild.keychain-db \
  ~/Library/Keychains/login.keychain-db
```

---

## ⚠️ Pendências de segurança (recomendado tratar)

1. **Senha do `.p12`** (`lo.cafe-dev-id-application-keystore.p12`) apareceu em uma
   captura de tela durante o setup — re-exportar o certificado com senha nova e
   atualizar o 1Password.
2. **Segredos em texto puro** em `~/Desktop/release-instructions.md` (inclui a
   senha da conta Setapp) — mover para o 1Password e apagar do Desktop.
3. **Arquivos temporários** criados no processo, dá para apagar:
   - Sua máquina: `~/Desktop/notchnook-env.txt`, `~/Desktop/NotchNook-1.6.0.html`.
   - Mac do Igor: `~/Downloads/Igor Personal.p12` (era do Compressor, não serve),
     `~/Downloads/lo.cafe-dev-id-application-keystore.p12`, `~/Downloads/dryrun*.txt`,
     `~/Downloads/build-*.txt`, `~/Downloads/setapp.txt`.
4. O `.env` (`scripts/.env`) contém segredos e é **gitignored** — confirmado que
   não está versionado. Manter assim.
