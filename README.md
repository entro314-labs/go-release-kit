# go-release-kit

A drop-in release pipeline for Go CLI projects: GoReleaser v2, eight distribution channels, Cosign signing, SBOMs, and GitHub Actions CI — as a set of template files you copy into your repo and fill in.


## Features

- **8 distribution channels**: GitHub Releases, Homebrew Cask, Scoop, Winget, AUR, npm, Docker (GHCR), nfpms (deb/rpm/apk)
- **Cosign signing**: checksums, all artifacts, Docker images
- **SBOM**: SPDX JSON for archives and source
- **Conditional secret guards**: Homebrew/Scoop/Winget/AUR/npm gracefully skip if secrets are absent
- **Post-release verification**: `go install` + `docker pull` after release
- **Snapshot builds in CI**: every PR validates the full release pipeline
- **Conventional commits**: enforced by pre-commit hook, drives changelog groups
- **GOARM64 optimizations**: LSE atomics + hardware crypto in Makefile
- **PGO infrastructure**: ready for profile-guided optimization
- **Version embedding**: 4 ldflags (version, commit, date, builtBy) with clean defaults

## Files included

| File | Purpose |
|---|---|
| `.goreleaser.yaml` | GoReleaser v2 config with all distribution channels |
| `npm/` | `npm i -g` distribution: a launcher plus a staging script driven by `dist/artifacts.json` ([details](npm/README.md)) |
| `.github/workflows/ci.yml` | CI: test, lint, security, build, goreleaser check |
| `.github/workflows/release.yml` | Release: tag-triggered with Cosign signing + post-release verify |
| `Makefile` | Local dev: build, test, lint, release, PGO, universal binary |
| `.pre-commit-config.yaml` | Pre-commit hooks + conventional commit enforcement |
| `.golangci.yml` | Linter config (errcheck, govet, staticcheck, unused) |
| `.yamllint.yaml` | YAML lint rules |
| `Dockerfile.goreleaser` | Runtime-only Docker image for GoReleaser |
| `SECURITY.md` | Security policy template |
| `release.config.json` | release-kit config for tag/changelog automation |

## Quick start

1. Copy the files into your Go project:

   ```sh
   git clone https://github.com/entro314-labs/go-release-kit
   cd go-release-kit
   cp -R .goreleaser.yaml .github .golangci.yml .yamllint.yaml \
         .pre-commit-config.yaml Makefile Dockerfile.goreleaser \
         SECURITY.md release.config.json npm /path/to/your-project/
   ```

2. Replace the placeholders in every copied file:

   | Placeholder | Description | Example |
   |---|---|---|
   | `__PROJECT_NAME__` | Binary/project name | `git-herd` |
   | `__PROJECT_DESCRIPTION__` | One-line description | `A concurrent Git repository management tool` |
   | `__MAIN_PACKAGE__` | Go main package path | `.` or `./cmd/git-herd` |
   | `__MAIN_PACKAGE_SUFFIX__` | Path after module for `go install`, with its leading slash | `` (empty for root) or `/cmd/git-herd` |
   | `__ORG__` | GitHub org/user | `entro314-labs` |

   One-liner (run from your project root, adjust values first):

   ```sh
   grep -rl '__PROJECT_NAME__\|__ORG__\|__MAIN_PACKAGE' --exclude-dir=.git . | xargs perl -pi -e \
     's/__PROJECT_NAME__/git-herd/g; s/__PROJECT_DESCRIPTION__/A concurrent Git repository management tool/g; s/__MAIN_PACKAGE_SUFFIX__/cmd\/git-herd/g; s/__MAIN_PACKAGE__/.\/cmd\/git-herd/g; s/__ORG__/entro314-labs/g'
   ```

3. Add the version variables to your main package (see below).

4. Configure repository secrets for the channels you want (see below). Channels without secrets skip gracefully.

5. Validate: `make release-check` (runs `goreleaser check`) and `make release-snapshot` for a full local dry run.

## Version variables in main.go

Your main package needs these four variables:

```go
var (
    version = "dev"
    commit  = "none"
    date    = "unknown"
    builtBy = "unknown"
)

func buildVersion() string {
    if version == "dev" {
        return "dev (built from source)"
    }
    return fmt.Sprintf("%s (commit: %s, built: %s, by: %s)", version, commit, date, builtBy)
}
```

## Required secrets

| Secret | Required | Purpose |
|---|---|---|
| `GITHUB_TOKEN` | Auto | GitHub release, GHCR push |
| `HOMEBREW_TAP_TOKEN` | Optional | PAT for homebrew-tap repo write |
| `SCOOP_TAP_TOKEN` | Optional | PAT for scoop-bucket repo write |
| `NPM_TOKEN` | Optional | npm **automation** token, for `npm i -g` distribution |
| `WINGET_TOKEN` | Optional | PAT for winget-pkgs fork/PR |
| `AUR_KEY` | Optional | SSH private key for AUR git push |
| `CODECOV_TOKEN` | Optional | Coverage upload |

## Cutting a release

The pipeline is tag-triggered, so something has to decide the version and create the tag.
`make tag` does that with [release-kit](https://github.com/entro314-labs/release-kit):

```sh
npm i -g @entro314labs/release-kit   # once
make tag                             # infer the bump, roll CHANGELOG.md, commit, tag, push
```

It reads the conventional commits since the last tag — `feat:` is a minor, `fix:` a patch,
`!` or a `BREAKING CHANGE:` footer a major — and prints what it inferred and why before doing
anything. A Go module has no version file, so `release.config.json` sets `versionFile: null`
and the version is read from the latest tag.

`make tag` stops at the pushed tag on purpose. Everything after it — building six
distribution channels, Cosign signing, the GitHub release — is this pipeline's job, which is
why `steps` ends at `push` and `publish` is `null`.

### Who writes the release notes

By default **GoReleaser does**, from its `changelog.groups` config in `.goreleaser.yaml`,
and nothing needs to change. release-kit maintains `CHANGELOG.md` in the repository, which
is a different artefact for a different reader.

If you would rather they be the same text, read them off the tag: release-kit writes the
notes into the annotated tag, which is the one thing that reaches the workflow's fresh
checkout (a `notesFile` is written locally after the release commit and never leaves the
machine). A signed tag appends its signature block, so that is stripped first:

```yaml
- name: Read the release notes off the tag
  run: |
    git tag -l --format='%(contents)' "$GITHUB_REF_NAME" \
      | sed '/^-----BEGIN [A-Z ]*SIGNATURE-----$/,$d' > dist-notes.md
- uses: goreleaser/goreleaser-action@v7
  with:
    args: release --clean --release-notes=dist-notes.md
```

`--release-notes` makes GoReleaser skip its own changelog generation. Do not do half of
this: with both enabled, the notes in the GitHub release and the notes in `CHANGELOG.md` are
generated by different code from the same commits, and they drift.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Note that the `__PLACEHOLDER__` tokens are intentional — pull requests should keep them.

## License

[MIT](LICENSE)
