import { execSync } from 'node:child_process';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { zipChannel } from './zip-channel.mjs';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const channelDir = join(root, 'channel');
const zipPath = join(root, 'dist', 'duplex-roku.zip');

execSync(`node "${join(root, 'tools', 'build-lib.mjs')}"`, { stdio: 'inherit' });
zipChannel(channelDir, zipPath);

console.log(`\nPackaged: ${zipPath}`);
