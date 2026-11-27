import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile,mkdtemp,writeFile,rm}from'node:fs/promises';
import {tmpdir}from'node:os';
import path from'node:path';
import {spawnSync}from'node:child_process';
import {fileURLToPath}from'node:url';
const root=process.env.GC_TEST_SOURCE_ROOT||fileURLToPath(new URL('..',import.meta.url));
const bin=process.env.LUAU_BIN||'luau';
async function source(name){return (await readFile(path.join(root,'src',name),'utf8')).replace(/\r\n/g,'\n')}
async function run(code){const dir=await mkdtemp(path.join(tmpdir(),'gc-idle-'));try{const file=path.join(dir,'test.luau');await writeFile(file,code);const r=spawnSync(bin,[file],{encoding:'utf8',timeout:10000});assert.ifError(r.error);assert.equal(r.status,0,r.stdout+r.stderr)}finally{await rm(dir,{recursive:true,force:true})}}
function between(s,a,b){assert.ok(s.includes(a),`missing ${a}`);return s.slice(s.indexOf(a),s.indexOf(b,s.indexOf(a)))}
const indexHeader=`local registry,watches={},{};local watched=0;local sweep=nil;local warm=false;local nextCleanup=0
local recording=nil;local lookups=0;local visits=0;local M={};local roots={}
for i=1,1000 do roots[i]={Parent=true,GetChildren=function()return {}end}end
local workspace={GetChildren=function()lookups+=1 return roots end};local playerGui={GetChildren=function()return {}end}
local CFG={SCAN_BUDGET=48,INDEX_STEP_SECONDS=.0015};local own=function()return false end
M.observe=function()visits+=1 end
`;
test('performance: 600 idle index calls traverse zero world objects',async()=>{const s=await source('03-vfx-groups.luau');await run(indexHeader+between(s,' function M.indexStep()',' function M.warmMeshes')+`for i=1,600 do M.indexStep()end assert(lookups==0 and visits==0,'IDLE WORLD SCAN: '..visits..' objects; '..lookups..' root reads') print('IDLE: 0 objects / 600 ticks')`)});
test('performance: GAME indexing is bounded and resumes incrementally',async()=>{const s=await source('03-vfx-groups.luau');await run(indexHeader+between(s,' function M.indexStep()',' function M.warmMeshes')+`recording={kind='GAME'} M.indexStep()assert(visits<=48)for i=1,80 do M.indexStep()end assert(visits==1000 and warm)recording=nil local old=visits for i=1,600 do M.indexStep()end assert(visits==old)print('INDEX: <=48 per slice, GAME discovery complete, idle frozen')`)});
test('performance: history startup reads metadata, not 1000 take files',async()=>{const s=await source('02-motion.luau');await run(`local Core={}local saved={}local history={takes={}}local takeReads=0 local manifestReads=0
for i=1,1000 do history.takes[i]={id=tostring(i),path='take'..i}end
Core.safePath=function()return true end Core.safeRead=function(p)if p:find('HISTORY')then manifestReads+=1 return '{}'end takeReads+=1 return '{}'end
local decode=function()return history end
`+between(s,' function Core.loadHistory()','Core.loadHistory()\nloadData=')+`Core.loadHistory()assert(#saved==1000 and manifestReads==4)assert(takeReads==0,'EAGER TAKE READS: '..takeReads)print('HISTORY: 1000 entries, 0 take-file reads')`)});
test('performance: all world lifecycle observers are capture-only and detachable',async()=>{const s=await source('07-interface.luau');const code=between(s,'local captureConnections={}','local nextUIRefresh=0');await run(`local Core={} local Group={}local recording=nil local active=0 local seen=0
local function signal()local callbacks={}return {Connect=function(_,f)local c={live=true};callbacks[c]=f;active+=1;function c:Disconnect()if self.live then self.live=false active-=1 end end return c end,Fire=function(_,o)for c,f in callbacks do if c.live then f(o)end end end}end
local workspace={DescendantAdded=signal(),DescendantRemoving=signal()}local playerGui={DescendantAdded=signal(),DescendantRemoving=signal()}local replicated={DescendantAdded=signal(),DescendantRemoving=signal()}
local game={GetService=function()return replicated end};local now=function()return 0 end
Group.observe=function()seen+=1 end;Group.removing=function()seen+=1 end;Group.worldGui=function()return false end
Core.gameObserveInstance=function()end;Core.inspectEffect=function()end;Core.gameHighlightObserve=function()end
`+code+`assert(active==0)
local obj={IsA=function()return false end}
for _,kind in {'ANIM','VFX','GAME','INSPECT'}do
 recording={kind=kind};Core.beginCaptureObservers(recording)
 local expected=kind=='ANIM'and 0 or kind=='GAME'and 6 or kind=='VFX'and 4 or 2
 assert(active==expected,kind..': '..active)
 Core.endCaptureObservers()recording=nil local n=seen workspace.DescendantAdded:Fire(obj)assert(active==0 and seen==n)
end
for i=1,30 do recording={kind='GAME'}Core.beginCaptureObservers(recording)Core.endCaptureObservers()end
assert(active==0)print('OBSERVERS: idle0; motion0; VFX4; GAME6; Inspector2; 30cycles leak0')`)});
test('performance: Stop releases pooled-property watchers and index references',async()=>{const s=await source('03-vfx-groups.luau');await run(`local M={}local disconnected=0 local watches={}local registry={old=true}local watched=3 local warm=true local sweep={}local nextCleanup=99
for i=1,3 do watches[i]={Disconnect=function()disconnected+=1 end}end
`+between(s,' function M.finish(t)',' return M\n')+`M.finish({groupRoots={}})assert(disconnected==3 and next(watches)==nil and next(registry)==nil and watched==0 and not warm and sweep==nil)print('STOP: property watchers3->0; index cleared')`)});
test('performance: no hidden take decoding and no retained disk-backed recording payload',async()=>{const ui=await source('07-interface.luau');const c=await source('04-capture.luau');assert.match(ui,/drawDetails=function\(\)\s+if UI.activePage~='Library'then return end/);assert.match(c,/data=\(not onDisk\)and result or nil/);assert.match(c,/recording=nil\s+Core.endCaptureObservers\(\)/);assert.match(ui,/if not gui.Enabled or not window.Visible then return end/)});
