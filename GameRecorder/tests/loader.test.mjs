import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
test('loader has guarded stages and matching single-line copy', async()=>{
 const loader=await readFile(new URL('../executor/one_line_loader.lua',import.meta.url),'utf8');
 const flat=await readFile(new URL('../ONE_LINE_EXECUTOR_LOADER.txt',import.meta.url),'utf8');
 assert.equal(flat.trim(),loader.trim().split('\n').map(x=>x.trim()).join(' '));
 for(const marker of ['Download failed','Compile failed','Recorder startup failed','loadstring unavailable','gc-motion-vfx-recorder/','unexpected response or wrong version']) assert.ok(loader.includes(marker));
});
