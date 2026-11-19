Test.check(Core.RECORDER_VERSION=='7.0','v7 version is exposed')
Test.check(Core.safePath('GC_BAKER_v7_123_RAW.json')and Core.safePath('GC_BAKER_v7_123_CONTROL_NOTES.txt'),'new file names accepted')
Test.check(not Core.safePath('../secret.json'),'file paths remain bounded')
Test.check(Core.hasMotion('COMBINED')and Core.hasVFX('COMBINED'),'combined mode owns motion and VFX')
local idleQueries=Test.queryCount
for _=1,100 do Group.indexStep()end
Test.check(Test.queryCount==idleQueries,'idle index performs no spatial queries')
Test.check(#workspace.DescendantAdded.callbacks==0,'no global scene watcher installed at load')
local observer=assert(Core.getRig())
local chosen=Core.selectActors(observer)
Test.check(#chosen==1 and chosen[1].actor.username=='MyUsername','default actor is local player username')
Core.Settings.npcs=true;Core.Settings.otherPlayers=true
chosen=Core.selectActors(observer)
Test.check(#chosen==4,'NPC/player switches admit nearby actors')
Core.Settings.actorNames='NPC_B, OtherUsername'
chosen=Core.selectActors(observer)
Test.check(#chosen==3,'comma-separated exact name filter preserves self and chosen actors')
Core.Settings.localActor=false
chosen=Core.selectActors(observer)
Test.check(#chosen==2 and not chosen[1].actor.isLocal,'local actor switch can be off')
Core.Settings.localActor=true;Core.Settings.actorNames=''
local oldMax=CFG.MAX_ACTORS;CFG.MAX_ACTORS=2
local limited;chosen,limited=Core.selectActors(observer)
Test.check(#chosen==2 and limited,'actor cap is reported')
CFG.MAX_ACTORS=oldMax
Core.startRecord('ANIM')
local t=recording
Test.check(t and #t.allActors==4,'motion session retains independent actor states')
Test.check(#workspace.DescendantAdded.callbacks==0,'motion-only recording installs no VFX discovery')
Test.check(t.allActors[2].start==t.start and t.allActors[2].origin==t.origin,'actors share the session clock and coordinate frame')
Test.check(t.allActors[2].actor.isLocal==false and next(t.allActors[2].keys)==nil,'other actor input is not invented')
local root=t.rigObj.root
root.CFrame=CFrame.new(6,0,0);Test.clock=.1;Core.sampleActors(t,.1)
Test.check(Test.near(t.distance.path3D,6),'6-stud movement counted')
for _,p in ipairs(t.visibilityParts)do p.LocalTransparencyModifier=1 end
t.rigObj.char:SetAttribute('FlashstepHidden',true)
root.CFrame=CFrame.new(10,0,0);Test.clock=.2;Core.sampleActors(t,.2)
Test.check(t.frames[#t.frames].visibility.hidden,'invisibility captured from effective part transparency')
Test.check(Test.near(t.distance.path3D,10)and #t.frames==3,'root and joint recording continues during invisibility')
for _,p in ipairs(t.visibilityParts)do p.LocalTransparencyModifier=0 end
t.rigObj.char:SetAttribute('FlashstepHidden',false);t.rigObj.char:SetAttribute('InFallback',true)
root.CFrame=CFrame.new(13,0,0);Test.clock=.3;Core.sampleActors(t,.3)
Test.check(not t.frames[#t.frames].visibility.hidden,'reappearance recorded')
Test.check(t.frames[#t.frames].distance.action=='fallback','fallback interval classified from observed flag')
root.CFrame=CFrame.new(13,4,0);Test.clock=.4;Core.sampleActors(t,.4)
Test.check(Test.near(t.distance.path3D,17)and Test.near(t.distance.pathHorizontal,13),'vertical and horizontal distance kept separate')
root.CFrame=CFrame.new(113,4,0);Test.clock=.5;Core.sampleActors(t,.5)
Test.check(Test.near(t.distance.path3D,17)and Test.near(t.distance.discontinuityStuds,100),'large position discontinuity excluded and labeled')
Test.clock=1;Core.sampleActors(t,1)
Test.check(t.frames[#t.frames].distance.sampleGap,'sample gap marked')
t.allActors[2].rigObj.char.Parent=nil
Core.sampleActors(t,1.1)
Test.check(t.allActors[2].lost and not t.lost,'one lost actor does not terminate remaining actors')
local folder=Instance.new('Folder');folder.Parent=workspace
local ghost=Core.createMotionGhost(Core.actorResult(t),folder)
Test.check(ghost.model:FindFirstChild('ActorName')~=nil,'ghost has persistent identity label')
Core.previewVisibility({ghost=ghost},{visibility={hidden=true,parts={}}})
Test.check(ghost.parts.Torso.Transparency==1,'ghost body visibility replays hidden state')
Core.previewVisibility({ghost=ghost},{visibility={hidden=false,parts={Torso=0}}})
Test.check(ghost.parts.Torso.Transparency==0,'ghost body reappears')
stopRecord()
local result=saved[1].data
Test.check(result.version==7 and #result.actors==3 and result.actor.username=='MyUsername','multi-actor JSON keeps primary identity and extras')
Test.check(result.distance.segments[#result.distance.segments].finish~=nil,'distance intervals close on stop')
local imported=Core.studioSceneImporter(result,'R6')
Test.check(type(imported)=='string'and #Test.json>=5,'scene exporter includes other actors')
local effects=Instance.new('Folder');effects.Name='Effects';effects.Parent=workspace
local function effect(name,x)
 local model=Instance.new('Model');model.Name=name;model.Parent=effects
 local part=Instance.new('Part');part.Name='Smoke';part.CanCollide=false;part.CFrame=CFrame.new(x,0,0);part.Parent=model
 local em=Instance.new('ParticleEmitter');em.Name='Puffs';em.Texture='test';em.Parent=part
 return model,part,em
end
local fx1,p1,em1=effect('UppercutEffect',2)
local fx2,p2,em2=effect('FallbackEffect',8)
Test.queryParts[#Test.queryParts+1]=p1;Test.queryParts[#Test.queryParts+1]=p2
Core.Settings.npcs=false;Core.Settings.otherPlayers=false
root.CFrame=CFrame.new()
Core.startRecord('COMBINED');t=recording
for _=1,12 do Group.indexStep()end
Test.check(t and Core.hasVFX(t.kind)and #t.frames>0,'combined session captures initial motion')
Test.check(t.groupCount==2,'simultaneous effect assemblies stay separate')
local anchors={}
for _,event in ipairs(t.vfx)do if event.op=='group_spawn'then anchors[#anchors+1]=event.snapshot.anchor[1]end end
table.sort(anchors)
Test.check(anchors[1]==2 and anchors[2]==8,'effect offsets preserve shared session origin')
local function activeSignals(s)local n=0;for _,v in ipairs(s.callbacks)do if v[1].active then n+=1 end end;return n end
Test.check(activeSignals(workspace.DescendantAdded)==1,'combined capture owns one scene-add listener')
Test.clock=1.2;Core.sampleActors(t,now(t));p1.Size=Vector3.new(3,3,3);Group.refresh(t,now(t))
Test.check(#t.vfx>2,'effect property changes retained')
stopRecord()
Test.check(activeSignals(workspace.DescendantAdded)==0,'stop disconnects scene discovery')
local beforeCount=#saved[1].data.vfx
p1.Size=Vector3.new(7,7,7)
Test.check(#saved[1].data.vfx==beforeCount,'stopped take receives no property changes')
local q=Test.queryCount;for _=1,100 do Group.indexStep()end
Test.check(q==Test.queryCount,'after stop index remains idle')
Test.check(saved[1].data.kind=='COMBINED'and #saved[1].data.frames>0 and #saved[1].data.vfx>0,'saved combined JSON retains both timelines')
print('TOTAL PASS '..Test.passed)


-- Edge cases use the real telemetry helpers with deterministic paths.
local edge={start=Test.clock,origin=CFrame.new()}
Core.initActor(edge,assert(Core.getRig(Test.selfChar)),{username='MyUsername',isLocal=true})
local eroot=edge.rigObj.root;eroot.CFrame=CFrame.new()
Core.distanceStep(edge,eroot.Position,0,'ordinary_motion')
for _,p in ipairs(edge.visibilityParts)do p.Transparency=1;p.LocalTransparencyModifier=0 end
local vis=Core.visibility(edge,0)
Test.check(vis.hidden,'initially invisible actor is detected')
Core.distanceStep(edge,Vector3.new(4,0,0),.1,'hidden')
for _,p in ipairs(edge.visibilityParts)do p.Transparency=0 end
Core.visibility(edge,.2)
for _,p in ipairs(edge.visibilityParts)do p.Transparency=1 end
Core.visibility(edge,.3)
for _,p in ipairs(edge.visibilityParts)do p.Transparency=0 end
Core.visibility(edge,.4)
local toggles=0;for _,event in ipairs(edge.events)do if event.type=='VISIBILITY'then toggles+=1 end end
Test.check(toggles==4,'repeated hide/reveal cycles remain distinct')
Core.distanceStep(edge,Vector3.new(4,0,0),.2,'ordinary_motion')
Core.finishDistance(edge,.2)
Test.check(Test.near(edge.distance.segments[2].path3D,4),'hidden interval retains its own stud total')
for _,p in ipairs(edge.visibilityParts)do p.Transparency=.5;p.LocalTransparencyModifier=.5 end
Test.check(Test.near(Core.visibility(edge,.5).parts.Torso,.75),'effective transparency composes base and local modifier')
local edgeGhost=Core.createMotionGhost(Core.actorResult(edge),folder)
local title=edgeGhost.model:FindFirstChild('ActorName'):GetChildren()[1]
Test.check(title.Text:find('MyUsername',1,true)~=nil,'preview label uses recorded username')
Core.Settings.localActor=false;Core.Settings.npcs=true;Core.Settings.actorNames='NPC_B'
Core.startRecord('ANIM')
Test.check(recording and recording.actor.name=='NPC_B'and not recording.actor.isLocal,'NPC can be primary when local recording disabled')
stopRecord()
Core.Settings.localActor=true;Core.Settings.npcs=false;Core.Settings.actorNames=''
local hiddenSample={root=Core.cft(CFrame.new()),parts={},joints={},pivots={},visibility={hidden=true,parts={}}}
local visibleSample={root=Core.cft(CFrame.new()),parts={},joints={},pivots={},visibility={hidden=false,parts={Torso=0}}}
local preview={anim=true,ghost=edgeGhost,origin=CFrame.new(),elapsed=.15,data={frames={table.clone(hiddenSample),table.clone(visibleSample)},channels={}}}
preview.data.frames[1].t=0;preview.data.frames[2].t=.1
Core.previewPose(preview)
Test.check(edgeGhost.parts.Torso.Transparency==0,'visible final frame applies without lingering hidden state')
print('EDGE TOTAL PASS '..Test.passed)

-- Exercise the installed UI callbacks and scheduler, not a rewritten copy.
createInterface()
local function button(text)
 for _,object in ipairs(pg:GetDescendants())do if object:IsA('TextButton')and object.Text==text then return object end end
 error('Missing button '..text)
end
Test.check(button('REC ANIM + VFX (F9)')~=nil,'combined record button exists')
Test.check(button('SETTINGS')~=nil,'settings button exists')
button('SETTINGS').MouseButton1Click:Fire()
button('Record nearby NPC animations: OFF').MouseButton1Click:Fire()
Test.check(Core.Settings.npcs,'NPC switch changes actual capture setting')
button('Record nearby NPC animations: ON').MouseButton1Click:Fire()
button('DONE').MouseButton1Click:Fire()
uis.InputBegan:Fire({UserInputType='Keyboard',KeyCode={Name='F9'}},false)
Test.check(recording and recording.kind=='COMBINED','F9 starts synchronized capture')
local part=recording.visibilityParts[1]
local beforeEvents=#recording.events
part.LocalTransparencyModifier=1;part.LocalTransparencyModifier=0
Test.check(#recording.events>beforeEvents,'visibility transitions recorded between pose samples')
local eventPreview={ghost=edgeGhost,elapsed=.015,visibilityEvents={{t=.01,hidden=true,parts={}},{t=.02,hidden=false,parts={Torso=0}}}}
Core.previewVisibility(eventPreview,{})
Test.check(edgeGhost.parts.Torso.Transparency==1,'between-sample hide event replays')
eventPreview.elapsed=.03;Core.previewVisibility(eventPreview,{})
Test.check(edgeGhost.parts.Torso.Transparency==0,'between-sample reveal event replays')
Test.clock+=.1;run.PostSimulation:Fire()
Test.check(#recording.frames>=2,'installed scheduler samples motion')
uis.InputBegan:Fire({UserInputType='Keyboard',KeyCode={Name='F9'}},false)
Test.check(recording==nil,'F9 stops synchronized capture')
Test.check(activeSignals(part:GetPropertyChangedSignal('LocalTransparencyModifier'))==0,'stop disconnects actor visibility observers')
local encodedScene=Core.studioSceneImporter(saved[1].data,'R6')
local loader,errorText=loadstring(encodedScene)
Test.check(loader~=nil,'generated scene importer parses as Luau')
local ok,err=pcall(loader)
Test.check(ok,'generated v7 scene importer executes against engine doubles: '..tostring(err))
Test.check(#services.ServerStorage:GetChildren()>0,'scene importer creates actor animation sequences')
env.GC_MotionBaker_Shutdown()
Test.check(activeSignals(workspace.DescendantAdded)==0,'UI shutdown leaves no scene listeners')
print('FINAL TOTAL PASS '..Test.passed)
