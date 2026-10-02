import { execSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { zipChannel } from './zip-channel.mjs';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const channelDir = join(root, 'channel');
const zipPath = join(root, 'dist', 'duplex-roku-release.zip');
const buildConfig = join(root, 'lib', 'platform', 'BuildConfig.brs');
const buildLib = `node "${join(root, 'tools', 'build-lib.mjs')}"`;

const original = readFileSync(buildConfig, 'utf8');
const release = original.replace(
  /function DuplexIsDev\(\) as Boolean\s*\n\s*return true\s*\nend function/,
  'function DuplexIsDev() as Boolean\n    return false\nend function',
);

if (release === original) {
  console.error('Could not rewrite DuplexIsDev() in lib/platform/BuildConfig.brs');
  process.exit(1);
}

try {
  writeFileSync(buildConfig, release);
  execSync(buildLib, { stdio: 'inherit' });
  zipChannel(channelDir, zipPath);
  console.log(`\nRelease package: ${zipPath}`);
} finally {
  writeFileSync(buildConfig, original);
  execSync(buildLib, { stdio: 'inherit' });
}
