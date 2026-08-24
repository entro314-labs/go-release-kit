# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
