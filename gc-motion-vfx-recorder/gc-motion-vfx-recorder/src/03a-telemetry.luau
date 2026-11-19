-- Session telemetry: bounded actor selection, visibility and measured distances.
function Core.hasMotion(kind)return kind=='ANIM' or kind=='COMBINED'end
function Core.hasVFX(kind)return kind=='VFX' or kind=='COMBINED'end
function Core.nearbyParts(position,radius)
 local params=OverlapParams.new();params.MaxParts=CFG.MAX_QUERY_PARTS
 local ok,parts=pcall(workspace.GetPartBoundsInRadius,workspace,position,radius,params)
 return ok and parts or {}
end
function Core.nameAllowed(name)
 local filter=Core.Settings.actorNames
 if filter==''then return true end
 for token in filter:gmatch('[^,]+')do if token:match('^%s*(.-)%s*$'):lower()==name:lower()then return true end end
 return false
end
function Core.selectActors(observer)
 local actors,seen={},{}
 local function add(char,owner,isLocal)
  if not char or seen[char] or char:GetAttribute('GC_BakerPreview')then return end
  seen[char]=true
  if not isLocal and not Core.nameAllowed(owner and owner.Name or char.Name)then return end
  local rig=Core.getRig(char)
  if not rig or (rig.root.Position-observer.root.Position).Magnitude>CFG.ACTOR_RADIUS then return end
  actors[#actors+1]={rig=rig,actor={id=owner and 'player:'..owner.UserId or 'npc:'..char:GetFullName(),
   username=owner and owner.Name or nil,displayName=owner and owner.DisplayName or char.Name,
   name=char.Name,isLocal=isLocal==true,isNPC=owner==nil},
   distance=(rig.root.Position-observer.root.Position).Magnitude}
 end
 if Core.Settings.localActor then add(observer.char,localPlayer,true)end
 if Core.Settings.otherPlayers then for _,p in ipairs(Players:GetPlayers())do if p~=localPlayer then add(p.Character,p,false)end end end
 if Core.Settings.npcs then
  for _,part in ipairs(Core.nearbyParts(observer.root.Position,CFG.ACTOR_RADIUS))do
   local model=part:FindFirstAncestorOfClass('Model')
   while model and model~=workspace do
    if model:FindFirstChildOfClass('Humanoid')then
     if not Players:GetPlayerFromCharacter(model)then add(model,nil,false)end
     break
    end
    model=model:FindFirstAncestorOfClass('Model')
   end
  end
 end
 table.sort(actors,function(a,b)
  if a.actor.isLocal~=b.actor.isLocal then return a.actor.isLocal end
  if math.abs(a.distance-b.distance)>.001 then return a.distance<b.distance end
  return a.actor.id<b.actor.id
 end)
 local limited=#actors>CFG.MAX_ACTORS
 while #actors>CFG.MAX_ACTORS do table.remove(actors)end
 return actors,limited
end
function Core.initActor(t,rig,identity)
 t.rigObj=rig;t.rig=rig.rig;t.actor=identity
 t.frames=t.frames or {};t.events=t.events or {};t.trackObjs={};t.trackPresent={};t.trackList={};t.keys=t.keys or {}
 t.channels={};t.metrics={HumanoidRootPart={size=Core.vec3(rig.root.Size)}};t.visibilityParts={}
 for _,j in ipairs(rig.channels)do
  t.channels[#t.channels+1]={parent=j.parent,child=j.child,kind=j.kind,name=j.obj.Name,base0=Core.cft(j.base0),base1=Core.cft(j.base1)}
  local part=rig.char:FindFirstChild(j.child)
  if part and part:IsA('BasePart')then t.metrics[j.child]={size=Core.vec3(part.Size)};t.visibilityParts[#t.visibilityParts+1]=part end
 end
 t.distance={path3D=0,pathHorizontal=0,displacement=0,displacementHorizontal=0,discontinuityStuds=0,segments={},gaps=0}
end
function Core.visibility(t,ts)
 local parts,count,hidden={},0,0
 for _,p in ipairs(t.visibilityParts)do if p.Parent then
  local alpha=math.clamp(1-(1-p.Transparency)*(1-p.LocalTransparencyModifier),0,1)
  parts[p.Name]=r(alpha);count+=1;if alpha>=.98 then hidden+=1 end
 end end
 local state={hidden=count>0 and hidden==count,parts=parts,visibleParts=count-hidden}
 local signature=tostring(state.hidden)
 for _,p in ipairs(t.visibilityParts)do signature..='|'..p.Name..':'..tostring(parts[p.Name])end
 if signature~=t.visibilitySignature then
  Core.appendEvent(t,'VISIBILITY',{hidden=state.hidden,parts=parts,summary=state.hidden and 'Character invisible' or 'Character visible / partially visible'},ts)
  t.visibilitySignature=signature;t.lastVisibility=state
 end
 return t.lastVisibility or state
end
function Core.listenVisibility(actor,session)
 actor.visibilityConnections={}
 local function changed()
  if recording==session and not actor.lost then Core.visibility(actor,now(actor))end
 end
 for _,part in ipairs(actor.visibilityParts)do
  for _,property in ipairs({'Transparency','LocalTransparencyModifier'})do
   actor.visibilityConnections[#actor.visibilityConnections+1]=part:GetPropertyChangedSignal(property):Connect(changed)
  end
 end
end
function Core.finishVisibility(actor)
 for _,connection in ipairs(actor.visibilityConnections or {})do connection:Disconnect()end
 actor.visibilityConnections=nil
end
function Core.actionLabel(t,visibility)
 local names={}
 for key,value in pairs(t.rigObj.char:GetAttributes())do
  if value==true then
   local n=key:lower()
   if n:find('fallback',1,true)then names.fallback=true
   elseif n:find('flashstep',1,true)then names.flashstep=true
   elseif n:find('uppercut',1,true)then names.uppercut=true
   elseif n:find('dash',1,true)then names.dash=true end
  end
 end
 for _,track in ipairs(t.trackList)do
  if (t.trackPresent and next(t.trackPresent)) and track.last and now(t)-track.last<.15 then
   local n=(track.name or ''):lower()
   if n:find('fallback',1,true)then names.fallback=true end
  end
 end
 if visibility.hidden then names.hidden=true end
 local ordered={};for name in pairs(names)do ordered[#ordered+1]=name end;table.sort(ordered)
 return #ordered>0 and table.concat(ordered,'+') or 'ordinary_motion'
end
function Core.distanceStep(t,position,ts,label)
 local d=t.distance
 if not d.first then d.first=position;d.previous=position;d.previousTime=ts end
 local delta=position-d.previous;local length=delta.Magnitude
 local horizontal=Vector3.new(delta.X,0,delta.Z).Magnitude
 local dt=ts-d.previousTime
 local gap=dt>.25
 local discontinuity=length>math.max(40,dt*400)
 if gap then d.gaps+=1 end
 if discontinuity then
  d.discontinuityStuds+=length
  Core.appendEvent(t,'POSITION_DISCONTINUITY',{studs=r(length),seconds=r(dt),summary='Large sampled jump excluded from ordinary path totals'},ts)
 else d.path3D+=length;d.pathHorizontal+=horizontal end
 local segment=d.open
 if not segment or segment.label~=label then
  if segment then
   segment.finish=r(ts);segment.duration=r(ts-segment.start);segment.endPosition=Core.vec3(d.previous)
   d.segments[#d.segments+1]=segment
   Core.appendEvent(t,'DISTANCE_SEGMENT',{summary=segment.label,studs=r(segment.path3D),horizontalStuds=r(segment.pathHorizontal),start=segment.start,finish=segment.finish},ts)
  end
  segment={label=label,start=r(ts),path3D=0,pathHorizontal=0,startPosition=Core.vec3(d.previous),sampleGaps=0,discontinuities=0};d.open=segment
 end
 if discontinuity then segment.discontinuities+=1 else segment.path3D+=length;segment.pathHorizontal+=horizontal end
 if gap then segment.sampleGaps+=1 end
 d.displacement=(position-d.first).Magnitude
 local offset=position-d.first;d.displacementHorizontal=Vector3.new(offset.X,0,offset.Z).Magnitude
 d.previous=position;d.previousTime=ts
 return {path3D=r(d.path3D),pathHorizontal=r(d.pathHorizontal),displacement=r(d.displacement),
  displacementHorizontal=r(d.displacementHorizontal),step=r(length),sampleGap=gap,discontinuity=discontinuity,action=label}
end
function Core.finishDistance(t,ts)
 local d=t.distance;if not d then return end
 if d.open then
  local x=d.open;x.finish=r(ts);x.duration=r(ts-x.start);x.endPosition=Core.vec3(d.previous)
  d.segments[#d.segments+1]=x;d.open=nil
  Core.appendEvent(t,'DISTANCE_SEGMENT',{summary=x.label,studs=r(x.path3D),horizontalStuds=r(x.pathHorizontal),start=x.start,finish=x.finish},ts)
 end
end
function Core.actorResult(t)
 local d=t.distance or {}
 return {actor=t.actor,rig=t.rig,frames=t.frames,channels=t.channels,metrics=t.metrics,events=t.events,tracks=t.trackList,
  eventsLimited=t.eventsLimited==true,stateWindows=t.stateWindows,heldMovementWindows=t.heldMovementWindows,inputObservations=t.inputObservations,
  inputSource=t.actor and t.actor.isLocal and 'local keyboard/mouse' or 'not observable for other actors',
  distance={path3D=r(d.path3D or 0),pathHorizontal=r(d.pathHorizontal or 0),displacement=r(d.displacement or 0),
   displacementHorizontal=r(d.displacementHorizontal or 0),discontinuityStuds=r(d.discontinuityStuds or 0),segments=d.segments or {},sampleGaps=d.gaps or 0}}
end
function Core.sampleActors(t,ts)
 local frames=0;local present=0
 for _,actor in ipairs(t.allActors or {})do
  local rig=actor.rigObj
  if rig.char.Parent and rig.root.Parent and rig.hum.Parent then
   present+=1
   if not actor.lost then
    Core.scanTracks(actor,ts)
    if not Core.sampleMotion(actor,ts)then actor.lost=true;Core.appendEvent(actor,'ACTOR_LOST',{summary='Rig joints changed; remaining actors continue'},ts)end
   end
  elseif not actor.lost then actor.lost=true;Core.appendEvent(actor,'ACTOR_LOST',{summary='Actor removed/streamed out; no invisible motion invented'},ts)end
  frames+=#actor.frames
 end
 if frames>=CFG.MAX_TOTAL_FRAMES then t.motionLimited=true end
 return present
end
function Core.previewVisibility(pb,frame)
 local visibility=frame.visibility
 if pb.visibilityEvents and pb.elapsed then
  local index=pb.visibilityIndex or 1
  if pb.lastVisibilityAge and pb.elapsed<pb.lastVisibilityAge then index=1;pb.eventVisibility=nil end
  while index<=#pb.visibilityEvents and pb.visibilityEvents[index].t<=pb.elapsed do
   pb.eventVisibility=pb.visibilityEvents[index];index+=1
  end
  pb.visibilityIndex=index;pb.lastVisibilityAge=pb.elapsed
  visibility=pb.eventVisibility or visibility
 end
 if not visibility then return end
 for name,part in pairs(pb.ghost.parts)do
  if name~='HumanoidRootPart'then part.Transparency=visibility.parts[name] or (visibility.hidden and 1 or .15)end
 end
 if visibility.hidden then for _,marker in pairs(pb.ghost.markers)do marker.Transparency=1 end end
end
