import { build } from './lib.mjs';
const result = await build();
console.log('Built ' + result.manifest.output + ' (' + result.bytes + ' bytes)');
console.log('SHA256 ' + result.hash);
