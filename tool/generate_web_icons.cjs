// Mechanical resizing of the existing brand asset; native icons stay untouched.
const {execFileSync} = require('node:child_process');
const {resolve} = require('node:path');
const source = resolve(__dirname, '../assets/Logo/LOGO_SQUARE.png');
const outputs = [
  ['favicon.png', 32], ['icons/Icon-192.png', 192], ['icons/Icon-512.png', 512],
  ['icons/Icon-maskable-192.png', 192], ['icons/Icon-maskable-512.png', 512],
];
if (process.platform !== 'darwin') throw new Error('Generator ikon ini memerlukan sips bawaan macOS.');
for (const [name, size] of outputs) {
  execFileSync('/usr/bin/sips', ['-z', String(size), String(size), source, '--out', resolve(__dirname, '../web', name)], {stdio: 'ignore'});
}
console.log('Generated 5 NALARA web icons from the existing logo.');
