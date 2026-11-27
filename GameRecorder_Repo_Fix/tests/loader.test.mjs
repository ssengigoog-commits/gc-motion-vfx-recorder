import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile}from'node:fs/promises';
test('one short loader has exactly five lines and guards nil compilation',async()=>{
 const s=await readFile(new URL('../LOADER.txt',import.meta.url),'utf8');
 assert.equal(s.trim().split('\n').length,5);
 assert.ok(s.includes('GameRecorder_Repo_Fix/dist/'));
 assert.ok(s.includes('assert(type(run)=="function"'));
 assert.ok(s.includes("Core.RECORDER_VERSION='7.1.0'"));
});
