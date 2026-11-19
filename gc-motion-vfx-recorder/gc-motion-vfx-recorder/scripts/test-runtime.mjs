import { readFile, writeFile, mkdtemp, rm } from 'node:fs/promises';
import path from 'node:path';
import { tmpdir } from 'node:os';
import { execFileSync } from 'node:child_process';
import { assemble, root } from './lib.mjs';

const executable = process.argv[2] || process.env.LUAU_BIN;
if (!executable) {
  console.error('Pass a local Luau CLI path: node scripts/test-runtime.mjs /path/to/luau');
  process.exit(2);
}
const { source } = await assemble();
const marker = /\ncreateInterface\(\)\s*$/;
if (!marker.test(source)) throw new Error('UI startup boundary changed');
const prefix = await readFile(path.join(root, 'tests/runtime/engine-stubs.luau'), 'utf8');
const assertions = await readFile(path.join(root, 'tests/runtime/assertions.luau'), 'utf8');
const directory = await mkdtemp(path.join(tmpdir(), 'gc-baker-tests-'));
try {
  const file = path.join(directory, 'test.luau');
  await writeFile(file, prefix + '\n' + source.replace(marker, '\n-- UI invoked by test\n') + '\n' + assertions);
  execFileSync(executable, [file], { stdio: 'inherit' });
} finally {
  if (path.dirname(directory) !== path.resolve(tmpdir()) || !path.basename(directory).startsWith('gc-baker-tests-')) {
    throw new Error('Refusing cleanup outside temporary test directory');
  }
  await rm(directory, { recursive: true, force: true });
}
