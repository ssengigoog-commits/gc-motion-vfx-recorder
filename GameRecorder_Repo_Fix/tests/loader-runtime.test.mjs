import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile,mkdtemp,writeFile,unlink,rmdir}from'node:fs/promises';
import {tmpdir}from'node:os';
import path from'node:path';
import {spawnSync}from'node:child_process';
const bin=process.env.LUAU_BIN||'luau';
const available=!spawnSync(bin,['--help'],{encoding:'utf8'}).error;
const cases=[
 ['canonical folder URL','',true,null],
 ['no debug dependency','debug=nil',true,null],
 ['missing compiler','loadstring=nil',false,'loadstring unavailable'],
 ['nil compile result',"loadstring=function()return nil,'fixture syntax' end",false,'fixture syntax'],
 ['compiler throws',"loadstring=function()error('fixture compiler')end",false,'fixture compiler'],
 ['startup error',"loadstring=function()return function()error('fixture startup')end end",false,'fixture startup'],
 ['wrong download',"game.HttpGet=function()return '404: Not Found'end",false,'Wrong or missing recorder download'],
 ['old release rejected',"game.HttpGet=function()return \"Core.RECORDER_VERSION='7.0.2'\"end",false,'Wrong or missing recorder download'],
 ['HTTP failure',"game.HttpGet=function()error('fixture offline')end",false,'fixture offline']
];
for(const[name,setup,success,marker]of cases)test('five-line loader: '+name,{skip:!available},async()=>{
 const loader=await readFile(new URL('../LOADER.txt',import.meta.url),'utf8');
 const header=`local called=false
local seen
local debug=debug
local game={HttpGet=function(_,url)seen=url;return "Core.RECORDER_VERSION='7.1.1'"end}
local loadstring=function()return function()called=true end end
`;
 const verify=success?`assert(ok,tostring(err));assert(called);assert(seen:find('/GameRecorder_Repo_Fix/dist/GC_MotionVFX_Baker_v7_1_1.luau',1,true))`:`assert(not ok);assert(tostring(err):find(${JSON.stringify(marker)},1,true),tostring(err))`;
 const dir=await mkdtemp(path.join(tmpdir(),'gc-five-'));const file=path.join(dir,'test.luau');
 try{
  await writeFile(file,header+setup+'\nlocal ok,err=pcall(function()\n'+loader+'\nend)\n'+verify);
  const r=spawnSync(bin,[file],{encoding:'utf8',timeout:10000});assert.ifError(r.error);assert.equal(r.status,0,r.stdout+r.stderr);
 }finally{await unlink(file);await rmdir(dir)}
});
