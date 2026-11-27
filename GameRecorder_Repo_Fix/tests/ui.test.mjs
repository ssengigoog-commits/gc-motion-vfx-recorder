import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile,mkdtemp,writeFile,unlink,rmdir} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
const bin=process.env.LUAU_BIN||'luau';
const available=!spawnSync(bin,['--help'],{encoding:'utf8'}).error;
test('native UI construction, navigation, toggles, modes, actor picker, F7, resize and cleanup',{skip:!available},async()=>{
 const read=rel=>readFile(new URL(rel,import.meta.url),'utf8');
 const motion=await read('../src/02-motion.luau');
 const inspector=await read('../src/03a-inspector.luau');
 const helpers=motion.slice(motion.indexOf('-- Only this allowlisted settings'),motion.indexOf('local previewGeneration'));
 const plan=inspector.slice(inspector.indexOf('function Core.inspectPlan'),inspector.indexOf('function Core.inspectBegin'));
 const source=await read('./fixtures/ui-prefix.luau')+helpers+plan+await read('../src/07-interface.luau')+await read('./fixtures/ui-suffix.luau');
 const dir=await mkdtemp(path.join(tmpdir(),'gc-ui-'));const file=path.join(dir,'ui.luau');
 try{
  await writeFile(file,source);const result=spawnSync(bin,[file],{encoding:'utf8',timeout:10000,maxBuffer:4*1024*1024});
  assert.ifError(result.error);assert.equal(result.status,0,result.stderr);
  const state=JSON.parse(result.stdout);assert.equal(state.mockedUI,true);assert.equal(state.checksPassed,true);
 }finally{await unlink(file);await rmdir(dir)}
});
