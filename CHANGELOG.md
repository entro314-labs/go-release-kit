# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- `Dockerfile.goreleaser` now builds on `gcr.io/distroless/static-debian13:nonroot` instead of `debian:trixie-slim`, matching the kit's `CGO_ENABLED=0` builds: 67 MiB down to 1.5 MiB, and no shell or package manager in the shipped image. The `git` package went with it — nothing in the kit needed it at run time. A tool that execs `git`/`ssh`, or anyone who wants a debug shell, has the `debian:trixie-slim` recipe in a comment at the top of the file. The `chmod +x` and `groupadd`/`useradd` layers are gone too: `COPY --chmod=0755` and a numeric `USER 65532:65532` (which is what Kubernetes `runAsNonRoot` and compose `user:` can actually verify) do the same work without a layer.

### Fixed

- Signing never worked in any mode: `signs` ran goreleaser's default `gpg` (no key on the runner), `docker_signs` looked for a `cosign.key` nothing provides, and both read `COSIGN_PWD` without a guard so every snapshot failed before signing began. Signing is now keyless cosign over the workflow's OIDC identity; `COSIGN_PWD` is gone, snapshot runs pass `--skip=sign`, and `SECURITY.md` shows the matching `verify-blob` command.
- The macOS universal binary never built: the `universal_binaries` entry named no `ids`, so goreleaser looked for a build called `<name>-universal` and shipped two per-arch archives instead.
- A prerelease tag (`v1.2.0-beta.1`) was published as stable everywhere but GitHub: `latest` on npm and GHCR, and a Homebrew/Scoop/Winget/AUR update. Those channels now skip prereleases and npm publishes under the channel's dist-tag.
- release-kit's own `chore(release): vX` commit appeared under Other Changes in every release; the changelog filters now exclude the scoped forms of `chore`, `style`, `test` and `ci`.
- `__MAIN_PACKAGE_SUFFIX__` was pasted after a slash in the verify job and omitted from the release footer, so an empty suffix produced `github.com/org/repo/@v1` and a `cmd/x` layout advertised an install command that installs nothing. The placeholder now carries its own leading slash and is used identically in both places.
- A manual `workflow_dispatch` ignored its `tag` input and ran goreleaser against the branch HEAD; the tag is now checked out and used throughout.
- The `notesFile` handoff documented for `--release-notes` cannot reach the workflow's fresh checkout (the file is written locally after the release commit); the README now reads the notes off the annotated tag instead.
- `make install-tools` installed golangci-lint v1 against the v2 config; `detect-secrets` pointed at a `.secrets.baseline` the kit does not ship.
- `release.config.json` omitted the `version` step. Harmless while nothing in the tree carries the version (goreleaser injects it with `-ldflags`), but a consumer adding `versionFiles` for a `version.go` would have had release-kit refuse every bump as "version step not selected". The step is in the list; it is a no-op when there is nothing to write.

### Removed

- The CI `docker` job and the `docker-build`/`docker-run` Makefile targets, which built a multi-stage `Dockerfile` the kit does not contain (only the runtime-only `Dockerfile.goreleaser` exists) and so failed on every run.

## [1.0.0] - 2026-08-24

### Added

- Initial release of the template kit: GoReleaser v2 config with six distribution channels (GitHub Releases, Homebrew Cask, Winget, AUR, Docker/GHCR, nfpms), Cosign signing, and SPDX SBOMs
- CI workflow: cross-platform tests, golangci-lint, security scanning, build verification, GoReleaser snapshot on every PR
- Release workflow: tag-triggered with Cosign signing and post-release `go install` + `docker pull` verification
- Makefile with cross-platform builds, PGO support, macOS universal binary, and GOARM64 optimizations
- Pre-commit hooks with conventional commit enforcement, and a CI `commit-lint` job running the same hook against the pull request title — the one subject no local hook sees, and the one a squash merge turns into the commit the changelog is grouped from
- golangci-lint and yamllint configs, runtime-only GoReleaser Dockerfile, security policy template
- Project documentation: README, LICENSE (MIT), CONTRIBUTING, CODE_OF_CONDUCT

[Unreleased]: https://github.com/entro314-labs/go-release-kit/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/entro314-labs/go-release-kit/releases/tag/v1.0.0
