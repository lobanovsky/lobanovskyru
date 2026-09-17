# Repository Guidelines

## Structure

Astro static site. Pages: `src/pages/`; styles: `src/styles/`; static resources: `public/`. Docker build uses Node.js 24 and npm lockfile; Caddy serves the output behind the server's existing Traefik. `basket.lobanovsky.ru` remains on Tilda until a separate migration.

## Commands

- Development: `docker compose -f compose.dev.yaml up --build` (localhost:4321).
- Build and content tests: `docker build -t lobanovskyru:check .`.
- HTTP smoke tests: `bash scripts/smoke-test.sh lobanovskyru:check`.
- Deployment failure/rollback tests: `bash scripts/deploy.test.sh`.
- Without Docker: Node.js 24, `npm ci`, `npm run build`, `npm test`.
- Validate shell changes with `bash -n scripts/*.sh`; run `git diff --check`.

Use two-space indentation in Astro/JS/YAML and the existing shell style. No formatter/linter is configured; avoid unrelated formatting.

## Deployment

GitHub Actions builds and tests PRs. Main also publishes to Docker Hub and deploys by image digest when `DEPLOY_ENABLED=true`. Production secrets belong to GitHub environment `production`. Server details and rollback: `docs/deployment.md`. Never replace the shared Traefik configuration or disturb other Compose projects. Production network: `housekpr-network`.

## Security and changes

Never commit or print credentials. `private/` and `.env*` are ignored; Docker context uses an allowlist. SSH must verify known_hosts. Keep changes focused, use imperative commit subjects, and include validation in change summaries. Test deployment failure and rollback behavior without production credentials.

Keep Traefik disabled for this site until DNS is verified. `routing.env` is persistent server state, default `TRAEFIK_ENABLED=false`. Avoid production ACME requests during testing; use isolated staging if issuance tests are needed. Never delete the shared ACME store.
