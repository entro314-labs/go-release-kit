# npm distribution

`npm i -g __PROJECT_NAME__` for a Go binary. Worth having because it is the one
install path that is already present on a machine that has Node — CI images,
a JS monorepo's toolchain, a developer who has neither Homebrew nor Scoop — and
it needs no tap, no bucket and no review queue.

## How it works

`prepare.mjs` runs after GoReleaser, reads `dist/artifacts.json`, and copies each
binary to `dist/<platform>-<arch>` under Node's names for both. `bin/cli.js` spawns
the one matching the machine it is running on. No postinstall, no download at
install time, no native module.

The manifest is generated from `package.json.tmpl` so the version comes from the
tag rather than being committed and going stale — the same reason nothing else in
this kit stores a version.

## The tradeoff

Every binary ships in one tarball, so the package is roughly the sum of them —
tens of megabytes for a typical Go CLI, downloaded whole whatever platform you
are on.

The alternative is what esbuild and git-cliff do: a thin package with a
per-platform `optionalDependencies` entry, so npm resolves and downloads only the
one binary the machine needs. It is meaningfully better for consumers and
meaningfully more to run: one npm package per platform, published in lockstep on
every release, and a resolution failure mode that is confusing when it happens.

This kit takes the simple one. If your CLI is large or widely installed, the
split-package layout is the upgrade to make, and `prepare.mjs` is where it would
happen.

## Setup

1. Replace the placeholders (the kit's top-level one-liner covers `npm/` too).
   `repository.url` in `package.json.tmpl` has to match the GitHub repository
   exactly, which it does once they are.
2. Register the release workflow as the package's trusted publisher on npmjs.com:
   Packages → the package → Settings → Trusted publishing → GitHub Actions, with
   your organization or user, the repository, `release.yml` as the workflow
   filename, and `npm publish` under allowed actions. The publish then
   authenticates with the release job's OIDC token — the `id-token: write` it
   already has — and no npm credential is stored anywhere. A new configuration
   expires 48 hours after it is created unless it publishes once in that time.
3. `NPM_TOKEN` is the fallback: a granular token with publish access in a
   repository secret, which npm uses when the OIDC exchange fails. The first
   version of a new package goes this way, because the trusted-publisher
   settings belong to a package that already exists; register the publisher
   after it and delete the token. npm removes direct publishing with granular
   tokens in January 2027, so the fallback has a shelf life and the publisher
   registration does not.
4. The publish step runs when `npm/` is in the checkout. Delete the directory
   to drop the channel; the step then notes that it skipped.

Check the package before the first real release:

```sh
node npm/prepare.mjs 0.0.1-test   # after `make release-snapshot`
cd npm && npm pack --dry-run
```
