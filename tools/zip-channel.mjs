import { execSync } from 'node:child_process';
import { mkdirSync, rmSync } from 'node:fs';
import { dirname } from 'node:path';

const REQUIRED = [
  'manifest',
  'source/Main.brs',
  'source/DuplexShared.brs',
  'source/widgets/DuplexKeyboard.brs',
];

const FORBIDDEN = [
  'source/platform/',
  'source/api/',
  'source/services/',
  'source/core/',
];

export function zipChannel(channelDir, zipPath) {
  rmSync(zipPath, { force: true });
  mkdirSync(dirname(zipPath), { recursive: true });

  const excludes = ['*.DS_Store', 'images/category-bg/*']
    .map((pattern) => `-x "${pattern}"`)
    .join(' ');

  execSync(`cd "${channelDir}" && zip -r "${zipPath}" . ${excludes}`, { stdio: 'inherit' });

  const listing = execSync(`unzip -l "${zipPath}"`, { encoding: 'utf8' });
  const missing = REQUIRED.filter((entry) => !listing.includes(entry));
  const leaked = FORBIDDEN.filter((entry) => listing.includes(entry));
  if (missing.length > 0 || leaked.length > 0) {
    const problems = [];
    if (missing.length > 0) problems.push(`missing ${missing.join(', ')}`);
    if (leaked.length > 0) problems.push(`loose modules ${leaked.join(', ')}`);
    throw new Error(`Invalid channel package: ${problems.join('; ')}`);
  }
}
