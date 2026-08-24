# Contributing to go-release-kit

Thanks for your interest in improving this template. Contributions of all kinds are welcome — fixes, new distribution channels, workflow hardening, and documentation.

## Ground rules

- **Keep the placeholders.** Files in this repo are templates. Tokens like `__PROJECT_NAME__`, `__ORG__`, and `__MAIN_PACKAGE__` are intentional and must survive your change. Never submit a PR with them replaced by real values.
- **Stay drop-in.** A change should work for any Go CLI project that follows the documented conventions (version variables in `main`, conventional commits, tag-triggered releases). Project-specific behavior belongs behind a documented placeholder or an optional secret guard.
- **Degrade gracefully.** Optional channels (Homebrew, Winget, AUR, Cosign) must skip cleanly when their secret is absent, matching the existing `skip_upload`/`disable` guard pattern.

## Making changes

1. Fork and branch from `main`.
2. Make your change.
3. Validate what you touched:

   ```sh
   yamllint -c .yamllint.yaml .          # YAML files
   goreleaser check                       # .goreleaser.yaml (expect placeholder-related warnings only)
   actionlint                             # workflows, if you have it installed
   pre-commit run --all-files             # everything the hooks cover
   ```

   For substantive `.goreleaser.yaml` or workflow changes, the real test is copying the kit into a scratch Go project, replacing the placeholders, and running `goreleaser release --snapshot --clean`.
4. Update `README.md` if you added, removed, or renamed a file, placeholder, or secret.
5. Add a line to `CHANGELOG.md` under `Unreleased` for user-facing changes.

## Commit messages

Use [Conventional Commits](https://www.conventionalcommits.org/) — the same convention the template enforces on its consumers:

```
feat: add snapcraft channel with secret guard
fix: correct winget PR branch template
docs: clarify AUR_KEY format
```

The `conventional-pre-commit` hook checks these locally, and the CI workflow's
`commit-lint` job runs the same hook against the pull request title. That title
is what a squash merge turns into the commit GoReleaser groups into the
changelog, and no local hook ever sees it.

## Reporting issues

Open a GitHub issue with the file involved, what you expected, and what happened — ideally with the GoReleaser or Actions log excerpt. For security issues, follow [SECURITY.md](SECURITY.md) instead of opening a public issue.
