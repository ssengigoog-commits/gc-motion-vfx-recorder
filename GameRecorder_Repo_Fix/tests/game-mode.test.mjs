import test from'node:test';import assert from'node:assert/strict';import{readFile,mkdtemp,writeFile,rm}from'node:fs/promises';import{fileURLToPath}from'node:url';import{tmpdir}from'node:os';import path from'node:path';import{spawnSync}from'node:child_process';
const root=process.env.GC_TEST_SOURCE_ROOT||fileURLToPath(new URL('..',import.meta.url));
const read=async n=>(await readFile(path.join(root,'src',n),'utf8')).replace(/\r\n/g,'\n');
function section(s,a,b){assert.ok(s.includes(a),'missing '+a);return s.slice(s.indexOf(a),s.indexOf(b,s.indexOf(a)))}
async function run(s){const d=await mkdtemp(path.join(tmpdir(),'gc-game-only-'));try{const f=path.join(d,'test.luau');await writeFile(f,s);const r=spawnSync(process.env.LUAU_BIN||'luau',[f],{encoding:'utf8',timeout:10000});assert.ifError(r.error);assert.equal(r.status,0,r.stderr)}finally{await rm(d,{recursive:true,force:true})}}
test('F3 scope: player/NPC toggles never enable other actors or world discovery in other modes',async()=>{const s=await read('03a-inspector.luau');await run(`local Core={}local CFG={INSPECT_RADIUS=60,INSPECT_MAX_ACTORS=32}local npcs,players=true,true local queries=0
Core.actorRoleEnabled=function(role)return role=='self'or(role=='npc'and npcs)or(role=='player'and players)end
local localPlayer={Character={}}local me={role='self',distance=0}local modelData=function()return me end
Core.inspectCandidates=function()queries+=1 return {me,{role='npc',distance=5},{role='player',distance=8}}end
`+section(s,'function Core.inspectPlan(','function Core.inspectBegin(')+`for _,n in {true,false}do for _,p in {true,false}do
npcs=n;players=p;local a=Core.inspectPlanForTake({kind='GAME'})assert(#a==1+(n and 1 or 0)+(p and 1 or 0))
for _,kind in {'ANIM','VFX','INSPECT'}do local q=queries local a,mode=Core.inspectPlanForTake({kind=kind})assert(#a==1 and a[1]==me and mode=='self-only'and queries==q)end
end end print('MODE SCOPE: all4 toggle combinations; F3 only; other modes self-only and zero nearby queries')`)});
test('F3 integration: actual start/stop retains VFX stream even with both actor toggles OFF',async()=>{const s=await read('04-capture.luau');await run(`local localPlayer={Name='FixturePlayer',UserId=123};local Core={RECORDER_VERSION='test'}local Group={}local recording,playback,stopPreview,drawLibrary,drawDetails=nil,nil,nil,nil,nil local stopRecord local serial=0 local libraryFilter local saved={}local selected local estimateBurstPreview=true
local CFG={MAX_SECONDS=120,FPS=60,VFX_FPS=60,SCAN_BUDGET=48,PREFIX='take'}local r=function(x)return x end local now=function()return 1 end local msg=function()end local moving=function()return false end
local WATCH={}local Enum={KeyCode={LeftShift=1,RightShift=2},UserInputType={MouseButton1=1,MouseButton2=2,MouseButton3=3}}
local UIS={IsKeyDown=function()return false end,IsMouseButtonPressed=function()return false end}local Color3={fromRGB=function()return {}end}
local rig={rig='R6',root={CFrame={},Position={}},hum={WalkSpeed=12},channels={},char={}}
Core.getRig=function()return rig end Core.vec3=function()return {}end Core.cft=function()return {}end Core.groundPoint=function()return nil end Core.appendEvent=function()end Core.scanTracks=function()end Core.finishControl=function()end
local seeded,finished,observers=0,0,0
Group.seed=function()seeded+=1 end Group.scan=function()end Group.refresh=function()end Group.finish=function()finished+=1 end
Core.inspectBegin=function(t)t.inspector={frames={},actors={{role='self'}}}return true end Core.inspectPrime=function()end Core.inspectFinish=function()end
Core.gameBegin=function(t)t.game={frames={},highlights={}}return true end Core.gameFinish=function()end
Core.gamePrime=function(t)t.vfx[1]={t=0,op='group_spawn',id=1,snapshot={nodes={}}}end
Core.beginCaptureObservers=function()observers+=1 end Core.endCaptureObservers=function()observers-=1 end
Core.controlReport=function()return 'control' end Core.exportJson=function()return '{}'end Core.safeWrite=function()return false end Core.saveHistory=function()end
`+s.slice(s.indexOf(' function Core.startRecord'))+`Core.startRecord('GAME')assert(recording and seeded==1 and observers==1 and #recording.vfx==1)
recording.frames[1]={t=1}stopRecord()local data=saved[1].data assert(data.kind=='GAME'and #data.vfx==1 and data.vfx[1].op=='group_spawn')
local has=false for _,v in data.combinedStreams do if v=='grouped_vfx'then has=true end end assert(has and observers==0 and finished==1)
print('GAME VFX: start seeds effects; saved GAME payload includes group_spawn and grouped_vfx stream; Stop disconnects')`)});
