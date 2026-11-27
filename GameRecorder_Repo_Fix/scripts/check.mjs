import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { assemble, root, withinRoot } from './lib.mjs';

const result = await assemble();
const dist = await readFile(withinRoot(root, result.manifest.output), 'utf8');
if (dist !== result.source) throw new Error('dist is stale. Run node scripts/build.mjs');
const checksum = await readFile(withinRoot(root, result.manifest.output) + '.sha256', 'utf8');
if (checksum.trim() !== result.hash + '  ' + path.basename(result.manifest.output)) {
  throw new Error('Release checksum does not match');
}
const status = JSON.parse(await readFile(path.join(root, 'release-status.json'), 'utf8'));
if (status.stage === 'baseline-packaging') {
  const baseline = JSON.parse(await readFile(path.join(root, 'baseline.json'), 'utf8'));
  if (result.hash !== baseline.sha256Normalized) throw new Error('Baseline source changed unexpectedly');
}
console.log('PASS: manifest, source order, generated release and checksum');
console.log('Release stage: ' + status.stage);
console.log('This check does not run Roblox or measure game performance.');
