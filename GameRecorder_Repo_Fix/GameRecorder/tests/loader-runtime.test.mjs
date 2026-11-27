import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile, mkdtemp, writeFile, unlink, rmdir } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';

const binary = process.env.LUAU_BIN || 'luau';
const available = !spawnSync(binary, ['--help'], {encoding:'utf8'}).error;
const cases = [
 ['GameRecorder folder fallback', "game.HttpGet=function(_,url)if url:find('/GameRecorder/',1,true)then return \"Core.RECORDER_VERSION='7.0.2'\" end error('404 fixture')end;loadstring=function()return function()end end", "assert(#messages==0);assert(prints[1]:find('/GameRecorder/',1,true))"],
 ['success', "loadstring=function()return function()end end", "assert(#messages==0);assert(#prints==1)"],
 ['missing compiler', "loadstring=nil", "assert(messages[1]:find('loadstring unavailable',1,true))"],
 ['compile returns nil', "loadstring=function()return nil,'fixture syntax error' end", "assert(messages[1]:find('Compile failed: fixture syntax error',1,true))"],
 ['compiler throws', "loadstring=function()error('fixture compiler throw')end", "assert(messages[1]:find('Compile failed:',1,true));assert(messages[1]:find('fixture compiler throw',1,true))"],
 ['startup without debug', "debug=nil;loadstring=function()return function()error('fixture startup')end end", "assert(messages[1]:find('Recorder startup failed:',1,true));assert(messages[1]:find('fixture startup',1,true))"],
 ['wrong downloaded body', "game.HttpGet=function()return '404: Not Found'end;loadstring=function()error('must not compile wrong body')end", "assert(messages[1]:find('Download failed:',1,true));assert(messages[1]:find('unexpected response or wrong version',1,true))"],
 ['HTTP failure', "game.HttpGet=function()error('fixture offline')end", "assert(messages[1]:find('Download failed:',1,true));assert(messages[1]:find('fixture offline',1,true))"]
];
for (const [name, setup, verify] of cases) {
 test('actual Luau loader: '+name, {skip:!available}, async()=>{
  const loader=await readFile(new URL('../executor/one_line_loader.lua',import.meta.url),'utf8');
  const header=`local loadstring,debug=loadstring,debug\nlocal messages,prints={},{}\nwarn=function(v)table.insert(messages,tostring(v))end\nprint=function(v)table.insert(prints,tostring(v))end\ngame={HttpGet=function()return "Core.RECORDER_VERSION='7.0.2'"end}\n`;
  const dir=await mkdtemp(path.join(tmpdir(),'gc-loader-'));
  const file=path.join(dir,'fixture.luau');
  try {
   await writeFile(file,header+setup+'\n'+loader+'\n'+verify);
   const result=spawnSync(binary,[file],{encoding:'utf8',timeout:10000});
   assert.ifError(result.error);
   assert.equal(result.status,0,result.stdout+result.stderr);
  } finally {await unlink(file);await rmdir(dir);}
 });
}

