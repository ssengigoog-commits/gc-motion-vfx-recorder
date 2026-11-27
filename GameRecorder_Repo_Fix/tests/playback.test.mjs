import test from'node:test';import assert from'node:assert/strict';import{readFile,mkdtemp,writeFile,rm}from'node:fs/promises';import{tmpdir}from'node:os';import{fileURLToPath}from'node:url';import path from'node:path';import{spawnSync}from'node:child_process';
const root=process.env.GC_TEST_SOURCE_ROOT||fileURLToPath(new URL('..',import.meta.url));
async function run(body){const src=(await readFile(path.join(root,'src/05-preview.luau'),'utf8')).replace(/\r\n/g,'\n');const dir=await mkdtemp(path.join(tmpdir(),'gc-play-'));try{const f=path.join(dir,'test.luau');await writeFile(f,prefix+src.slice(src.indexOf('stopPreview=function()'))+body);const r=spawnSync(process.env.LUAU_BIN||'luau',[f],{encoding:'utf8',timeout:10000});assert.ifError(r.error);assert.equal(r.status,0,r.stderr)}finally{await rm(dir,{recursive:true,force:true})}}
const prefix=`local Core={}local recording,playback,stopPreview=nil,nil,nil local previewGeneration=0 local selected='take'local saved={}local clock=0 local os={clock=function()return clock end}
local Color3={fromRGB=function()return {}end}local messages={}local msg=function(s)messages[#messages+1]=s end
local mt={}mt.__mul=function(a,b)return setmetatable({x=a.x+b.x,y=a.y+b.y,z=a.z+b.z},mt)end
local CFrame={new=function(x,y,z)return setmetatable({x=x or 0,y=y or 0,z=z or 0},mt)end}
local CFG={PREVIEW_DISTANCE=9}local workspace={}local liveChar={}local rig={char=liveChar,root={Parent=true,CFrame=CFrame.new()}}local localPlayer={Character=liveChar}
local destroyed,ghosts,poses,fx,ground=0,0,0,{},0
local Instance={new=function()return {SetAttribute=function()end,Destroy=function()destroyed+=1 end}end}
Core.getRig=function()return rig end Core.takeFormat=function()return 'test'end
Core.groundOrigin=function(_,origin)ground+=1 return CFrame.new(origin.x,4,origin.z)end
Core.createMotionGhost=function()ghosts+=1 return {}end
Core.previewPose=function(pb)poses+=1 pb.lastPoseTime=pb.elapsed end
Core.runVfxEvent=function(pb,e)fx[#fx+1]={time=pb.elapsed,event=e.t,origin=pb.origin}end Core.moveVfx=function()end
local Group={warmMeshes=function()end,codec={preload=function()end,prepare=function()return {}end,sample=function()end}}
local loadData=function(t)return t.data end
local function select(kind,motion,effects)
 saved={{id='take',kind=kind,data={kind=kind,duration=1,frames=motion and {{t=0,root={}},{t=1,root={}}}or {},vfx=effects and {{t=0,op='group_spawn',snapshot={}},{t=.5,op='group_update'},{t=.8,op='group_remove'}}or {}}}}
end
`;
test('selected playback routes Motion, VFX and GAME without tab-dependent buttons',async()=>run(`for _,c in {{'ANIM',true,false},{'VFX',false,true},{'GAME',true,true}}do
select(c[1],true,true)Core.playSelected(false)assert(playback and playback.anim==c[2]and playback.vfx==c[3],c[1])
end select('ANIM',true,false)Core.playSelection('VFX',false)assert(playback.anim and not playback.vfx)print('ROUTING: ANIM=motion; VFX=effects; GAME=both; selection authoritative')`));
test('GAME uses one clock and origin for simultaneous motion and timestamped VFX',async()=>run(`select('GAME',true,true)Core.playSelected(false)assert(playback.anim and playback.vfx and ground==0 and playback.origin.y==0)
local origin=playback.origin clock=.6 Core.tickPreview()assert(playback.lastPoseTime==.6 and #fx==2 and fx[2].event==.5 and fx[2].time==.6 and fx[2].origin==origin)
clock=.9 Core.tickPreview()assert(#fx==3 and fx[3].event==.8 and playback.lastPoseTime==.9)
clock=1.1 Core.tickPreview()assert(playback==nil and destroyed==1)print('GAME: common elapsed/origin; VFX lifecycle ordered; Stop destroys preview only')`));
test('selected playback handles missing streams, empty takes, loops and active capture',async()=>run(`select('GAME',true,false)Core.playSelected(false)assert(playback.anim and not playback.vfx)
select('GAME',false,true)Core.playSelected(false)assert(not playback.anim and playback.vfx)
select('GAME',false,false)Core.playSelected(false)assert(not playback)
select('INSPECT',false,false)Core.playSelected(false)assert(not playback)
select('GAME',true,true)Core.playSelected(true)clock=1.1 Core.tickPreview()assert(playback and playback.elapsed==0 and playback.lastPoseTime==0 and fx[#fx].event==0)
local old=playback recording={}Core.playSelected(false)assert(playback==old)
print('EDGES: partial streams/empty/legacy handled; both streams loop together; recording blocks Play')`));
test('Library has exactly one selected-recording Play control',async()=>{const s=await readFile(path.join(root,'src/07-interface.luau'),'utf8');assert.doesNotMatch(s,/PLAY MOTION GHOST|PLAY VFX AHEAD/);assert.equal((s.match(/Name='PlaySelectedRecording'/g)||[]).length,1);assert.match(s,/Core.playSelected\(loopOn\)/)});
