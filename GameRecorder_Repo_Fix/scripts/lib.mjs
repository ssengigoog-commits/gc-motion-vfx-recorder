import { readFile, mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';

export const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
export const sha256 = value => createHash('sha256').update(value).digest('hex');

export function withinRoot(base, relative) {
  if (typeof relative !== 'string' || !relative || relative.includes('\\') || path.isAbsolute(relative)) {
    throw new Error('Expected a relative forward-slash path');
  }
  const target = path.resolve(base, relative);
  const rel = path.relative(base, target);
  if (rel === '..' || rel.startsWith('..' + path.sep) || path.isAbsolute(rel)) {
    throw new Error('Path escapes repository');
  }
  return target;
}

export async function assemble(base = root) {
  const manifest = JSON.parse(await readFile(path.join(base, 'build-manifest.json'), 'utf8'));
  if (manifest.schema !== 1 || !Array.isArray(manifest.sources) || !manifest.sources.length) {
    throw new Error('Invalid build manifest');
  }
  const seen = new Set();
  const parts = [];
  for (const entry of manifest.sources) {
    if (typeof entry.path !== 'string' || !/^src\/[\w.-]+\.luau$/.test(entry.path) || seen.has(entry.path)) {
      throw new Error('Invalid or duplicate source entry');
    }
    seen.add(entry.path);
    const text = (await readFile(withinRoot(base, entry.path), 'utf8')).replace(/\r\n/g, '\n');
    parts.push(text);
  }
  const source = parts.join('');
  return { manifest, source, hash: sha256(source), bytes: Buffer.byteLength(source) };
}

export async function build(base = root) {
  const result = await assemble(base);
  const output = withinRoot(base, result.manifest.output);
  if (!result.manifest.output.startsWith('dist/') || !result.manifest.output.endsWith('.luau')) {
    throw new Error('Output must be a dist/*.luau file');
  }
  await mkdir(path.dirname(output), { recursive: true });
  await writeFile(output, result.source, 'utf8');
  await writeFile(output + '.sha256', result.hash + '  ' + path.basename(output) + '\n', 'utf8');
  return { ...result, output };
}
