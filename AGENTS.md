# Repository Guidelines

## Project Status & Structure

This workspace is currently empty: no source code, assets, tests, build configuration, or Git metadata exists. No language or framework has been established. Update this guide as implementation choices become concrete.

When introducing the initial implementation, keep the layout predictable. Prefer `src/` for application code, `tests/` for tests, `assets/` for static resources, and `docs/` for supporting documentation, unless the chosen framework prescribes another structure. Create directories only when needed. Add a root `README.md` describing the project and setup process.

## Build, Test, and Development Commands

No installation, development, build, or test commands are configured yet. Do not assume that commands such as `npm test` or `make build` work.

When adding tooling, document the exact commands in `README.md`, including prerequisites, dependency installation, local startup, production builds, and tests. Commit the appropriate dependency lockfile and specify required runtime versions.

## Coding Style & Naming Conventions

Adopt the selected language’s standard formatter and linter, and commit their configuration. Until then, match the surrounding file’s indentation and avoid mixing tabs and spaces. Use descriptive names and consistent casing within each module. Keep changes focused; separate unrelated formatting from functional edits.

## Testing Guidelines

No testing framework or coverage threshold is configured. Introduce tests alongside the first testable behavior, using the selected framework’s naming conventions. Cover expected behavior, boundary cases, and relevant failures. Document how to run the complete suite and individual tests without requiring production credentials.

## Commit & Pull Request Guidelines

No Git history is available to establish existing commit conventions. Use concise, imperative commit subjects, such as `Add initial application structure`.

Pull requests should explain the purpose, summarize changes, and list validation performed or explain why it was unavailable. Link related issues when applicable and include screenshots for visible interface changes.

## Security & Configuration

Keep secrets and local configuration out of version control. Provide placeholder values in an example configuration file, and ignore dependency directories and generated build output once tooling is selected.
