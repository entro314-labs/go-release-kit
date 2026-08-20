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
2. Add an `NPM_TOKEN` repository secret — an npm **automation** token, which is
   not subject to the two-hour session expiry a `npm login` gets.
3. Without that secret the publish step skips with a warning, like every other
   optional channel here.

Check the package before the first real release:

```sh
node npm/prepare.mjs 0.0.1-test   # after `make release-snapshot`
cd npm && npm pack --dry-run
```
