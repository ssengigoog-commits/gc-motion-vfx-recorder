import test from 'node:test';
import assert from 'node:assert/strict';
import path from 'node:path';
import { tmpdir } from 'node:os';
import { mkdtemp, mkdir, readFile, writeFile, rm } from 'node:fs/promises';
import { assemble, build, root, sha256, withinRoot } from '../scripts/lib.mjs';

test('path resolver rejects escapes and Windows separators', () => {
  assert.throws(() => withinRoot(root, '../outside'));
  assert.throws(() => withinRoot(root, 'src\\escape'));
  assert.equal(withinRoot(root, 'src/example.luau'), path.join(root, 'src', 'example.luau'));
});

test('distribution contains only the current release and matching checksum', async () => {
 const {readdir}=await import('node:fs/promises');
 const {manifest,source}=await assemble();
 const files=await readdir(path.join(root,'dist'));
 assert.deepEqual(files.sort(),[path.basename(manifest.output),path.basename(manifest.output)+'.sha256'].sort());
 assert.equal(await readFile(path.join(root,manifest.output),'utf8'),source);
});

test('build preserves source order and rejects duplicates', async () => {
  const dir = await mkdtemp(path.join(tmpdir(), 'gc-recorder-test-'));
  try {
    await mkdir(path.join(dir, 'src'));
    await writeFile(path.join(dir, 'src/a.luau'), 'local a = 1\r\n');
    await writeFile(path.join(dir, 'src/b.luau'), 'return a\n');
    const manifest = { schema: 1, sources: [{ path: 'src/a.luau' }, { path: 'src/b.luau' }], output: 'dist/test.luau' };
    await writeFile(path.join(dir, 'build-manifest.json'), JSON.stringify(manifest));
    const result = await build(dir);
    assert.equal(result.source, 'local a = 1\nreturn a\n');
    assert.equal(await readFile(result.output, 'utf8'), result.source);
    assert.equal(result.hash, sha256(result.source));
    manifest.sources.push({ path: 'src/a.luau' });
    await writeFile(path.join(dir, 'build-manifest.json'), JSON.stringify(manifest));
    await assert.rejects(() => assemble(dir), /duplicate/);
    manifest.sources = [{ path: '../outside.luau' }];
    await writeFile(path.join(dir, 'build-manifest.json'), JSON.stringify(manifest));
    await assert.rejects(() => assemble(dir), /Invalid/);
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
});
