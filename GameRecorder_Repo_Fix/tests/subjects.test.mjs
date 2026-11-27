import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile,mkdtemp,writeFile,unlink,rmdir} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
const bin=process.env.LUAU_BIN||'luau';
const available=!spawnSync(bin,['--help'],{encoding:'utf8'}).error;
async function actualHelpers(){
 const bootstrap=await readFile(new URL('../src/01-bootstrap.luau',import.meta.url),'utf8');
 const motion=await readFile(new URL('../src/02-motion.luau',import.meta.url),'utf8');
 const inspector=await readFile(new URL('../src/03a-inspector.luau',import.meta.url),'utf8');
 const safe=bootstrap.slice(bootstrap.indexOf(' function Core.safePath'),bootstrap.indexOf(' function Core.safeWrite'));
 const settings=motion.slice(motion.indexOf('-- Only this allowlisted settings'),motion.indexOf('local previewGeneration'));
 const plan=inspector.slice(inspector.indexOf('function Core.inspectPlan'),inspector.indexOf('function Core.inspectBegin'));
 return {safe,settings,plan};
}
const cases=[
 ['role toggles are independent and always include self',`for _,n in {true,false}do for _,p in {true,false}do local s={includeNPCs=n,includePlayers=p};assert(Core.actorRoleEnabled('self',s));assert(Core.actorRoleEnabled('npc',s)==n);assert(Core.actorRoleEnabled('player',s)==p);assert(not Core.actorRoleEnabled('unknown',s))end end`],
 ['automatic nearest selection is capped at four including self',`local chosen,mode=Core.inspectPlan(candidates);assert(#chosen==4 and chosen[1].role=='self'and mode=='nearest');assert(chosen[4].label=='npc3')`],
 ['NPC OFF removes NPCs even if previously selected',`CFG.INCLUDE_NPCS=false;candidates[2].selected=true;local chosen=Core.inspectPlan(candidates);for _,a in chosen do assert(a.role~='npc')end;assert(chosen[1].role=='self')`],
 ['players OFF removes other players but not local character',`CFG.INCLUDE_PLAYERS=false;local chosen=Core.inspectPlan(candidates);for _,a in chosen do assert(a.role~='player')end;assert(chosen[1].role=='self')`],
 ['both OFF capture only self',`CFG.INCLUDE_NPCS=false;CFG.INCLUDE_PLAYERS=false;local chosen=Core.inspectPlan(candidates);assert(#chosen==1 and chosen[1].role=='self')`],
 ['manual choices replace automatic fill while keeping self',`candidates[5].selected=true;local chosen,mode=Core.inspectPlan(candidates);assert(mode=='manual'and #chosen==2 and chosen[2].label=='player4')`],
 ['active recordings reject subject changes',`recording={kind='GAME'};local ok=Core.setActorCaptureSetting('includeNPCs',false);assert(not ok and CFG.INCLUDE_NPCS and #writes==0)`],
 ['idle changes persist booleans without arbitrary paths',`local ok=Core.setActorCaptureSetting('includeNPCs',false);assert(ok and not CFG.INCLUDE_NPCS and CFG.INCLUDE_PLAYERS);assert(env.GC_RecorderSettings.includeNPCs==false);assert(writes[1]==CFG.SETTINGS);assert(not Core.setActorCaptureSetting('secret',true));assert(not Core.setActorCaptureSetting('includePlayers','false'))`],
 ['settings file is allowlisted without allowing traversal',`assert(Core.safePath(CFG.SETTINGS));assert(not Core.safePath('../GC_BAKER_SETTINGS_v7.json'));assert(not Core.safePath('x/GC_BAKER_SETTINGS_v7.json'));assert(not Core.safePath('other.json'));assert(not Core.safePath(nil))`]
];
for(const[name,body]of cases)test('actor settings: '+name,{skip:!available},async()=>{
 const{safe,settings,plan}=await actualHelpers();
 const header=`local Core={};local recording=nil;local writes={};local env={};local CFG={INCLUDE_NPCS=true,INCLUDE_PLAYERS=true,FPS=60,VFX_FPS=60,SETTINGS='GC_BAKER_SETTINGS_v7.json',INSPECT_MAX_ACTORS=4};local HttpService={JSONEncode=function(_,v)return 'settings' end};Core.safeRead=function()return nil end;Core.safeWrite=function(p,s)table.insert(writes,p);return true end\n`;
 const actors=`local candidates={{label='self',role='self'}};for i=1,7 do candidates[#candidates+1]={label=(i%2==1 and 'npc'or 'player')..i,role=i%2==1 and 'npc'or 'player',selected=false}end\n`;
 const dir=await mkdtemp(path.join(tmpdir(),'gc-subject-'));const file=path.join(dir,'test.luau');
 try{await writeFile(file,header+safe+settings+plan+actors+body);const r=spawnSync(bin,[file],{encoding:'utf8',timeout:10000});assert.ifError(r.error);assert.equal(r.status,0,r.stdout+r.stderr)}finally{await unlink(file);await rmdir(dir)}
});
