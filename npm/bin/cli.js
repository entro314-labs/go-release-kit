#!/usr/bin/env node
/**
 * Run the platform binary that shipped inside this package.
 *
 * The package carries every supported binary rather than resolving an optional
 * per-platform dependency, so an install needs no network beyond npm itself and works
 * behind a registry mirror. The cost is tarball size — see npm/README.md.
 */
const { spawn } = require('node:child_process')
const { existsSync } = require('node:fs')
const { join } = require('node:path')

const extension = process.platform === 'win32' ? '.exe' : ''
const binary = join(__dirname, '..', 'dist', `${process.platform}-${process.arch}${extension}`)

if (!existsSync(binary)) {
  console.error(
    `__PROJECT_NAME__ does not ship a binary for ${process.platform}-${process.arch}.\n` +
      'Install it another way: https://github.com/__ORG__/__PROJECT_NAME__#install',
  )
  process.exit(1)
}

// stdio: 'inherit' so the CLI owns the terminal exactly as the binary would on its own —
// colours, prompts and pipes all behave as if node were not in the middle.
const child = spawn(binary, process.argv.slice(2), { stdio: 'inherit' })
child.on('error', (error) => {
  console.error(`failed to run __PROJECT_NAME__: ${error.message}`)
  process.exit(1)
})
// A signal death has no exit code; report it the way a shell does.
child.on('close', (code, signal) => process.exit(signal ? 128 + (signal === 'SIGINT' ? 2 : 15) : code))
