import test from 'node:test';
import assert from 'node:assert/strict';
import{readFile,mkdtemp,writeFile,rm}from'node:fs/promises';
import{fileURLToPath}from'node:url';import{tmpdir}from'node:os';import path from'node:path';import{spawnSync}from'node:child_process';
const root=process.env.GC_TEST_SOURCE_ROOT||fileURLToPath(new URL('..',import.meta.url));
const read=async n=>(await readFile(path.join(root,'src',n),'utf8')).replace(/\r\n/g,'\n');
function section(s,a,b){assert.ok(s.includes(a),'missing '+a);return s.slice(s.indexOf(a),s.indexOf(b,s.indexOf(a)))}
async function run(s){const dir=await mkdtemp(path.join(tmpdir(),'gc-auto-'));try{const f=path.join(dir,'test.luau');await writeFile(f,s);const r=spawnSync(process.env.LUAU_BIN||'luau',[f],{encoding:'utf8',timeout:10000});assert.ifError(r.error);assert.equal(r.status,0,r.stderr)}finally{await rm(dir,{recursive:true,force:true})}}
const prefix=`local Core={}local CFG={INSPECT_RADIUS=60,INSPECT_MAX_ACTORS=32,INCLUDE_NPCS=true,INCLUDE_PLAYERS=true}
Core.actorRoleEnabled=function(role)return role=='self'or(role=='npc'and CFG.INCLUDE_NPCS)or(role=='player'and CFG.INCLUDE_PLAYERS)end
`;
test('automatic capture: inclusive60-stud boundary and independent type filters',async()=>{const s=await read('03a-inspector.luau');await run(prefix+section(s,'function Core.inspectPlan','function Core.inspectBegin')+`local list={{role='self',distance=0},{role='npc',distance=59.99},{role='player',distance=60},{role='npc',distance=60.01,selected=true}}
local a,mode=Core.inspectPlan(list)assert(#a==3 and mode=='automatic-radius','radius/legacy selection wrong')
CFG.INCLUDE_PLAYERS=false assert(#Core.inspectPlan(list)==2)
CFG.INCLUDE_NPCS=false assert(#Core.inspectPlan(list)==1)
CFG.INCLUDE_PLAYERS=true a=Core.inspectPlan(list)assert(#a==2 and a[2].role=='player')
print('AUTO: 60 included; 60.01 excluded; Settings independent')`)});
test('automatic capture: crowd budget is explicit and preserves local character',async()=>{const s=await read('03a-inspector.luau');await run(prefix+section(s,'function Core.inspectPlan','function Core.inspectBegin')+`local list={}for i=1,40 do list[i]={role='npc',distance=i}end list[41]={role='self',distance=0}
local a,mode,limited=Core.inspectPlan(list)assert(#a==32 and a[1].role=='self'and limited)assert(a[32].distance==31)print('AUTO: nearest32 incl self; overflow flagged')`)});
test('automatic capture: entry/exit/re-entry refreshes without duplicate actor setup',async()=>{const s=await read('03a-inspector.luau');await run(prefix+section(s,'function Core.inspectPlan','function Core.inspectBegin')+section(s,'function Core.inspectRefresh','local function compactTracks')+`local events={}local added=0
Core.appendEvent=function(_,kind,payload)events[#events+1]=kind end
Core.inspectAddActor=function(t,a)added+=1 local entry={identity=a}t.inspectActorCache[a.model]=entry return entry end
local self={id='me',role='self',distance=0,model={Parent=true},label='me'}local npc={id='npc',role='npc',distance=20,model={Parent=true},label='npc'}
Core.inspectCandidates=function()return {self,npc}end
local t={kind='GAME',inspector={},inspectActorCache={}}Core.inspectRefresh(t,0)assert(added==2 and #t.inspectActors==2 and t.nextActorRefresh==1)
npc.distance=61 Core.inspectRefresh(t,1)assert(#t.inspectActors==1 and not t.inspectActiveIDs.npc and events[3]=='ACTOR_LEAVE_RADIUS')
npc.distance=60 Core.inspectRefresh(t,2)assert(#t.inspectActors==2 and added==2 and events[4]=='ACTOR_ENTER_RADIUS')
print('AUTO: enters/exits/reenters; setup2 exactly; 1Hz discovery')`)});
test('automatic capture: picker removed and radius discovery never runs from idle UI',async()=>{const ui=await read('07-interface.luau');const b=await read('01-bootstrap.luau');assert.doesNotMatch(ui,/ChooseActors|ActorPicker|actorsBox|openActorPicker/);assert.match(b,/INSPECT_RADIUS=60/);assert.match(ui,/'Record players'/);assert.match(ui,/'Record NPCs'/);assert.doesNotMatch(section(ui,'function UI.refreshSubjects','function UI.navigate'),/inspectPlan|inspectCandidates/);const c=await read('04-capture.luau');assert.match(c,/if mode=='INSPECT' or mode=='GAME' then/)});
