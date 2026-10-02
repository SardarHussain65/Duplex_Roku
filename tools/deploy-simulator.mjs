import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execSync } from 'node:child_process';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const zipPath = join(root, 'dist', 'duplex-roku.zip');
const host = process.env.ROKU_HOST ?? '127.0.0.1';
const user = process.env.ROKU_USER ?? 'rokudev';
const password = process.env.ROKU_PASSWORD ?? 'rokudev';

execSync(
  `curl --silent --show-error --digest -u "${user}:${password}" -F "mysubmit=Install" -F "archive=@${zipPath}" "http://${host}/plugin_install"`,
  { stdio: 'inherit' },
);

execSync(`curl --silent -d "" "http://${host}:8060/launch/dev"`, { stdio: 'inherit' });
console.log('\nDuplex sideloaded and launched on BrightScript Simulator.');
