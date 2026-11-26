# AGENTS.md

- Filled by the projects: their workflow (`.github/workflows/translations.yml` in LiquidBounce and LiquidLauncher) runs `scripts/sync.sh` on every push to the translation folder and on releases, and pushes as `github-actions[bot]` with a `sync: <repo>@<sha>` commit through a deploy key (secret `TRANSLATIONS_DEPLOY_KEY` in each project). Never edit `<project>/` folders by hand.
- `<project>/<version>/` is published as `https://i18n.liquidbounce.net/<project>/<version>/` with an `index.json` (`scripts/build.sh`, run by `publish.yml` on every push). Readers: LiquidLauncher `src-tauri/src/app/translations.rs`, LiquidBounce `lang/PublishedLanguages.kt`. Changing index fields or paths breaks released clients.
- Only the latest release's folder is rewritten (its strings take newer translations while their English is unchanged); once a newer release exists it stays as it was last written.
- Version rules differ: LiquidBounce bumps its version right after a release, so a client whose version has no folder reads `next/`. LiquidLauncher bumps at release; its development builds read `next/` because CI sets `TRANSLATIONS_CHANNEL`.
- Index metadata comes from the folder's `languages.json` (the launcher's; `catalog` points a language at another file). LiquidBounce has none: its files are named by Minecraft code. `projects.json` names each project's English file, which the index leaves out.
- `publish.yml` builds in one job and deploys in another (deploy-pages right after the upload in the same job misses the artifact).
- `i18n.liquidbounce.net` is a proxied CNAME to `ccbluex.github.io` (zone SSL mode Full), so GitHub Pages has no certificate of its own and HTTPS is not enforced there.
