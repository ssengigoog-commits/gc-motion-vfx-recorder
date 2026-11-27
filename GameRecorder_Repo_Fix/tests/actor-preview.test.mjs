import test from'node:test';import assert from'node:assert/strict';import{readFile,mkdtemp,writeFile,rm}from'node:fs/promises';import{tmpdir}from'node:os';import{fileURLToPath}from'node:url';import path from'node:path';import{spawnSync}from'node:child_process';
const root=process.env.GC_TEST_SOURCE_ROOT||fileURLToPath(new URL('..',import.meta.url));
const read=async n=>(await readFile(path.join(root,'src',n),'utf8')).replace(/\r\n/g,'\n');
async function run(body){const s=await read('05-preview.luau');const code=s.slice(s.indexOf(' function Core.createMotionGhost'),s.indexOf(' function Core.vfxAnchor'));const dir=await mkdtemp(path.join(tmpdir(),'gc-actor-'));try{const f=path.join(dir,'test.luau');await writeFile(f,prefix+code+body);const r=spawnSync(process.env.LUAU_BIN||'luau',[f],{encoding:'utf8',timeout:10000});assert.ifError(r.error);assert.equal(r.status,0,r.stderr)}finally{await rm(dir,{recursive:true,force:true})}}
const prefix=`local Core={}local mt={}mt.__index=mt
local function cf(x,y,z)return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},mt)end
local CFrame={new=cf};function mt.__mul(a,b)return cf(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
function mt:Inverse()return cf(-self.X,-self.Y,-self.Z)end function mt:ToObjectSpace(b)return self:Inverse()*b end
function mt:Lerp(b,t)return cf(self.X+(b.X-self.X)*t,self.Y+(b.Y-self.Y)*t,self.Z+(b.Z-self.Z)*t)end
function mt:GetComponents()return self.X,self.Y,self.Z,1,0,0,0,1,0,0,0,1 end
Core.cft=function(c)return {c:GetComponents()}end Core.cff=function(v)if not v then return cf()end return cf(v[1],v[2],v[3])end
local Vector3={new=function(x,y,z)return {X=x,Y=y,Z=z}end};Core.toVec3=function(v)return Vector3.new(v[1],v[2],v[3])end
local Color3={fromRGB=function(...)return {...}end};local UDim2={fromOffset=function(...)return {...}end,fromScale=function(...)return {...}end}
local Enum={Material={SmoothPlastic='smooth',Neon='neon'},PartType={Ball='ball'},Font={GothamBold='bold'}}
local Instance={new=function(class)local props={}local obj={children={},ClassName=class};return setmetatable(obj,{__index=function(_,k)return props[k]end,__newindex=function(o,k,v)props[k]=v if k=='Parent'and v then table.insert(v.children,o)end end})end}
local folder=Instance.new('Folder')
Core.retargetPose=function()return cf()end
local function pose(x,y,z)return Core.cft(cf(x,y,z))end
local channels={}for _,n in {'Torso','Head','Right Arm','Left Arm','Right Leg','Left Leg'}do channels[#channels+1]={parent='HumanoidRootPart',child=n}end
local function actor(id,x)local parts={}for _,c in channels do parts[c.child]=pose(0,c.child=='Head'and 1.5 or 0,0)end return {id=id,root=pose(x,0,0),parts=parts}end
`;
test('actor ghosts have opaque complete R6 bodies and recorded names overhead',async()=>run(`local g=Core.createMotionGhost({rig='R6',channels=channels,actor={username='MyUser'}},folder)
for _,n in {'Torso','Head','Right Arm','Left Arm','Right Leg','Left Leg'}do assert(g.parts[n]and g.parts[n].Transparency==0,n)end
assert(g.parts.HumanoidRootPart.Transparency==1 and g.nameTag.Adornee==g.parts.Head)
assert(g.nameTag.children[1].Text=='MyUser'and g.nameTag.AlwaysOnTop)
local n=Core.createMotionGhost({rig='R6',channels=channels,actor={label='TrainingDummy',role='npc'}},folder)
assert(n.nameTag.children[1].Text=='TrainingDummy')print('VISIBLE: six opaque R6 limbs; hidden root only; self username and NPC label overhead')`));
test('GAME renders recorded NPC stream, skips duplicate self, interpolates and hides/reuses on exit',async()=>run(`local d={origin=pose(1000,0,0),inspector={actors={{id='me',role='self',label='MyUser',rig='R6',joints=channels},{id='npc',role='npc',label='TrainingDummy',rig='R6',joints=channels}},frames={{t=0,actors={actor('me',0),actor('npc',10)}},{t=1,actors={actor('npc',20)}},{t=2,actors={}},{t=3,actors={actor('npc',30)}}}}}
local pb={data=d,folder=folder,origin=cf(100,0,0),elapsed=.5}
Core.previewActorGhosts(pb)local g=assert(pb.actorGhosts.npc)assert(not pb.actorGhosts.me)assert(g.parts.HumanoidRootPart.CFrame.X==115 and g.parts.Head.CFrame.Y==1.5)
assert(g.parts.Head.Transparency==0 and g.nameTag.children[1].Text=='TrainingDummy')
pb.elapsed=2 Core.previewActorGhosts(pb)assert(g.parts.Head.Transparency==1 and not g.nameTag.Enabled)
pb.elapsed=3 Core.previewActorGhosts(pb)assert(pb.actorGhosts.npc==g and g.parts.Head.Transparency==0 and g.nameTag.Enabled)
print('GAME NPC: visible named ghost; interpolation115; no duplicate self; exit hides; reentry reuses')`));
test('legacy actor positions and available joint hierarchy are reconstructed, not discarded',async()=>run(`local meta={joints={{parent='HumanoidRootPart',child='Torso'},{parent='Torso',child='Head'}}}
local f=Core.actorGhostFrame({origin=pose(1000,0,0)},meta,{pos={1100,0,0},joints={pose(0,0,0),pose(0,1.5,0)}},.4)
assert(f.root[1]==100 and f.parts.Head[2]==1.5 and f.t==.4)print('LEGACY: world position rebased; available relative joints retained; missing facing remains approximate')`));
test('capture persists local identity, actor root facing, limb poses and body dimensions',async()=>{const c=await read('04-capture.luau');const a=await read('03a-inspector.luau');assert.match(c,/actor=\{username=localPlayer.Name,userId=localPlayer.UserId/);assert.match(c,/actor=t.actor,frames=t.frames/);assert.match(a,/root=Core.cft\(t.origin:ToObjectSpace\(a.root.CFrame\)\)/);assert.match(a,/s.parts\[j.child\]=Core.cft\(a.root.CFrame:ToObjectSpace\(p1.CFrame\)\)/);assert.match(a,/metadata.metrics\[joint.child\]/)});
