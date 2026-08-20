#!/usr/bin/env node
/**
 * Stage the binaries GoReleaser just built into the npm package, and set its version.
 *
 * Reads `dist/artifacts.json` rather than globbing `dist/` — GoReleaser's directory layout
 * (`<id>_<goos>_<goarch>_<variant>`) is an implementation detail that has changed between
 * releases, while the manifest is a documented output. Every binary is copied to
 * `npm/dist/<platform>-<arch>` using Node's names for both, which is what the launcher
 * asks for at runtime.
 *
 *   node npm/prepare.mjs <version>
 */
import { copyFileSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const here = dirname(fileURLToPath(import.meta.url))
const version = process.argv[2]?.replace(/^v/, '')
if (!version) {
  console.error('usage: node npm/prepare.mjs <version>')
  process.exit(1)
}

/** GoReleaser's names for a platform, and Node's. */
const PLATFORMS = { linux: 'linux', darwin: 'darwin', windows: 'win32' }
const ARCHS = { amd64: 'x64', arm64: 'arm64', '386': 'ia32' }

const artifacts = JSON.parse(readFileSync(join(here, '../dist/artifacts.json'), 'utf8'))
const staging = join(here, 'dist')
rmSync(staging, { recursive: true, force: true })
mkdirSync(staging, { recursive: true })

let staged = 0
for (const artifact of artifacts) {
  if (artifact.type !== 'Binary' && artifact.type !== 'UniversalBinary') continue
  const platform = PLATFORMS[artifact.goos]
  if (!platform) continue

  // A universal macOS binary carries both architectures, and `replace: true` means the
  // per-arch ones are gone. It has to be staged under each name the launcher may ask for.
  const archs =
    artifact.type === 'UniversalBinary' ? ['x64', 'arm64'] : [ARCHS[artifact.goarch]].filter(Boolean)

  for (const arch of archs) {
    const target = join(staging, `${platform}-${arch}${platform === 'win32' ? '.exe' : ''}`)
    copyFileSync(artifact.path, target)
    staged += 1
    console.log(`staged ${artifact.goos}/${artifact.goarch} -> ${platform}-${arch}`)
  }
}

if (!staged) {
  console.error('no binaries found in dist/artifacts.json — did GoReleaser run?')
  process.exit(1)
}

const manifest = JSON.parse(readFileSync(join(here, 'package.json.tmpl'), 'utf8'))
manifest.version = version
writeFileSync(join(here, 'package.json'), `${JSON.stringify(manifest, null, 2)}\n`)
console.log(`wrote npm/package.json at ${version} with ${staged} binaries`)
