local saved={}; local selected=nil; local recording=nil; local playback=nil
local previewGeneration=0
local estimateBurstPreview=true -- Preview-only estimates are labeled; source Emit() counts remain unknown.
local serial=0; local connections={}; local disposed=false; local statusLabel=nil
local libraryFilter='ANIM' -- independent ANIM/VFX recording lists
local setStatus,drawLibrary,drawDetails,stopPreview,stopRecord,loadData
local function conn(c) connections[#connections+1]=c; return c end
local function msg(s,c)
    if statusLabel then statusLabel.Text=s; statusLabel.TextColor3=c or Color3.fromRGB(170,183,195) end
    print('[GC Baker V7] '..s)
end
 function Core.exportJson(x) local ok,v=pcall(HttpService.JSONEncode,HttpService,x); return ok and v or nil end
local function decode(x) local ok,v=pcall(HttpService.JSONDecode,HttpService,x); return ok and v or nil end
 function Core.saveHistory()
    local out={version=7,takes={}}
    for _,t in ipairs(saved) do
        if t.saved then out.takes[#out.takes+1]={id=t.id,name=t.name,created=t.created,rig=t.rig,
            duration=t.duration,nframes=t.nframes,nvfx=t.nvfx,kind=t.kind or 'ANIM',tracks=t.tracks,
            path=t.path,saved=true} end
    end
    local str=Core.exportJson(out); if str then Core.safeWrite(CFG.MANIFEST,str) end
end
 function Core.loadHistory()
 local seen={}
 for _,version in ipairs({7,6,5,4})do
  local text=Core.safeRead('GC_BAKER_HISTORY_v'..version..'.json')
  local history=text and decode(text)
  if history and type(history.takes)=='table'then
   for _,take in ipairs(history.takes)do
    if type(take.id)=='string'and not seen[take.id]and Core.safePath(take.path)and Core.safeRead(take.path)then
     take.kind=take.kind or 'ANIM';saved[#saved+1]=take;seen[take.id]=true
    end
   end
  end
 end
end
Core.loadHistory()
loadData=function(t)
    if not t then return nil end
    if t.data then return t.data end
    local s=(t.path and Core.safeRead(t.path)) or t.raw
    if not s then return nil end
    local d=decode(s); if d and (d.version==7 or d.version==6 or d.version==5 or d.version==4) then t.data=d; return d end
    return nil
end

local KEYS={W=true,A=true,S=true,D=true}
local WATCH={One=true,Two=true,Three=true,Four=true,Five=true,Six=true,Seven=true,Eight=true,Nine=true,Zero=true,W=true,A=true,S=true,D=true,F=true,R=true,Q=true,E=true,T=true,G=true,C=true,X=true,Z=true,V=true,B=true,Space=true,LeftShift=true,RightShift=true,LeftControl=true,RightControl=true,LeftAlt=true,RightAlt=true,Tab=true}
 function Core.inputName(inp)
 if inp.UserInputType==Enum.UserInputType.MouseButton1 then return 'Mouse1' end
 if inp.UserInputType==Enum.UserInputType.MouseButton2 then return 'Mouse2' end
 if inp.UserInputType==Enum.UserInputType.MouseButton3 then return 'Mouse3' end
 return inp.KeyCode.Name
end
local function now(t) return r(math.max(0,os.clock()-t.start)) end
 function Core.appendEvent(t,kind,values,ts)
    if not t then return end
    if #t.events>=CFG.MAX_MOTION_EVENTS then t.eventsLimited=true;return end
    local e={t=r(ts or now(t)),type=kind}
    if values then for k,v in pairs(values) do e[k]=v end end
    t.events[#t.events+1]=e
end
local function moving(keys)
    for k,v in pairs(keys) do if v and KEYS[k] then return true end end
    return false
end
 function Core.activeTrackTimes(t)
  local out={};for track in pairs(t.trackPresent or {})do
   local info=t.trackObjs[track]
   if info then out[#out+1]={id=info.id,name=info.name,time=r(track.TimePosition or 0),speed=r(track.Speed or 0)}end
  end
  return out
 end
-- Observational control timeline. No server acceptance or hidden stun rules are inferred.
 function Core.controlSnapshot(rig)
  local state={flags={},reasons={},stunReported=false,walkSpeed=r(rig.hum.WalkSpeed),
   jumpPower=rig.hum.JumpPower,jumpHeight=rig.hum.JumpHeight,platformStand=rig.hum.PlatformStand==true,
   sit=rig.hum.Sit==true,humanoidState=rig.hum:GetState().Name}
  local function relevant(name)
   local n=name:lower():gsub('[^a-z]','')
   return n:find('stun',1,true)or n=='nomove'or n=='movementlocked'or n=='actionlocked'or n=='frozen'or n=='freeze'or n=='blocking'or n=='block'or n=='attacking'or n=='busy'or n=='canmove'or n=='canattack'
  end
  local function add(path,name,value,marker)
   if not relevant(name)then return end
   if type(value)~='string'and type(value)~='number'and type(value)~='boolean'then return end
   state.flags[path..'.'..name]=value
   local n=name:lower():gsub('[^a-z]','')
   -- Numeric/string values are retained raw: they may be timestamps, not booleans.
   local active=value==true or marker==true
   if active and (n:find('stun',1,true)or n=='nomove'or n=='movementlocked'or n=='actionlocked'or n=='frozen'or n=='freeze')then
    state.reasons[#state.reasons+1]=path..'.'..name
    if n:find('stun',1,true)then state.stunReported=true end
   elseif value==false and (n=='canmove'or n=='canattack')then state.reasons[#state.reasons+1]=path..'.'..name..'=false' end
  end
  for _,pair in ipairs({{rig.char,'Character'},{rig.hum,'Humanoid'}})do
   local owner,path=pair[1],pair[2]
   for name,value in pairs(owner:GetAttributes())do add(path,name,value,false)end
   local count=0
   for _,child in ipairs(owner:GetChildren())do
    if count>=64 then break end;count+=1
    if relevant(child.Name)then
     if child:IsA('ValueBase')then add(path,child.Name,child.Value,false)
     else add(path,child.Name,true,true)end
    end
    if child.Name=='States'or child.Name=='Status'or child.Name=='Statuses'or child.Name=='CombatState'or child.Name=='Effects'then
     local n=0;for _,flag in ipairs(child:GetChildren())do
      if n>=64 then break end;n+=1
      if flag:IsA('ValueBase')then add(path..'.'..child.Name,flag.Name,flag.Value,false)
      else add(path..'.'..child.Name,flag.Name,true,true)end
     end
    end
   end
  end
  if state.walkSpeed<=.05 then state.reasons[#state.reasons+1]='WalkSpeed near zero' end
  if state.platformStand then state.reasons[#state.reasons+1]='PlatformStand' end
  table.sort(state.reasons);state.restricted=#state.reasons>0
  return state
 end
 function Core.controlSignature(state)
  local fields={tostring(state.walkSpeed),tostring(state.platformStand),tostring(state.sit),state.humanoidState,table.concat(state.reasons,';')}
  local names={};for key in pairs(state.flags)do names[#names+1]=key end;table.sort(names)
  for _,key in ipairs(names)do fields[#fields+1]=key..'='..tostring(state.flags[key])end
  return table.concat(fields,'|')
 end
 function Core.observeControl(t,sample,ts,force)
  if force or not t.nextControlPoll or ts>=t.nextControlPoll then
   local state=Core.controlSnapshot(t.rigObj);local signature=Core.controlSignature(state)
   if signature~=t.controlSignature then
    t.stateWindows=t.stateWindows or {}
    if t.openStateWindow then
     t.openStateWindow.finish=r(ts);t.openStateWindow.duration=r(ts-t.openStateWindow.start);t.openStateWindow.animationEndTimes=Core.activeTrackTimes(t)
     t.stateWindows[#t.stateWindows+1]=t.openStateWindow;t.openStateWindow=nil
    end
    if state.restricted then t.openStateWindow={start=r(ts),kind=state.stunReported and 'reported_stun' or 'observed_restriction',reasons=state.reasons,animationTimes=Core.activeTrackTimes(t)}end
    Core.appendEvent(t,'CONTROL_STATE',{state=state,summary=state.restricted and table.concat(state.reasons,', ')or 'No client restriction observed'},ts)
    t.controlSignature=signature
   end
   t.controlState=state;t.nextControlPoll=ts+.1
  end
  if sample then sample.control=t.controlState end
  return t.controlState
 end
 function Core.noteInputAttempt(t,key,ts,processed)
  if key=='Shift'then return end -- synthetic duplicate of physical Shift key
  local state=Core.observeControl(t,nil,ts,true)
  t.inputObservations=t.inputObservations or {};t.pendingInputs=t.pendingInputs or {}
  if #t.inputObservations+#t.pendingInputs>=512 then t.inputObservationLimit=true;return end
  local present={};for track in pairs(t.trackPresent or {})do local info=t.trackObjs[track];if info then present[info.id]=true end end
  local held={};for name,down in pairs(t.keys or {})do if down and name~='Shift'then held[#held+1]=name end end;table.sort(held)
  t.pendingInputs[#t.pendingInputs+1]={key=key,heldKeys=held,start=r(ts),deadline=ts+.45,processed=processed==true,
   stateAtInput=state,baselineTracks=present,evidence={},restrictionThroughout=state.restricted,serverAccepted='unknown'}
 end
 function Core.checkInputAttempts(t,sample,ts,finish)
  for i=#(t.pendingInputs or {}),1,-1 do
   local attempt=t.pendingInputs[i];local evidence=attempt.evidence
   local state=t.controlState
   if not state or not state.restricted then attempt.restrictionThroughout=false end
   if sample then
    if KEYS[attempt.key]and (sample.measuredMove or sample.move or 0)>.5 then evidence.movementWhileInput=true end
    if attempt.key=='Space'and (sample.locomotion=='Jumping'or (sample.velocity and sample.velocity[2]>2))then evidence.upwardMotion=true end
    if attempt.key=='F'and state then for name,value in pairs(state.flags)do if value==true and (name:lower():match('%.blocking$')or name:lower():match('%.block$'))then if attempt.stateAtInput.flags[name]~=true then evidence.reportedBlocking=true else attempt.blockingAlreadyActive=true end end end end
    for _,track in ipairs(sample.tracks or {})do if not attempt.baselineTracks[track.id]then evidence.animationChange=true end end
    if next(evidence)and not attempt.firstResponse then attempt.firstResponse=r(ts)end
   end
   if finish or ts>=attempt.deadline then
    attempt.finish=r(ts);attempt.observationSeconds=r(ts-attempt.start);attempt.incompleteWindow=ts<attempt.deadline
    attempt.status=next(evidence)and 'response_observed' or (attempt.restrictionThroughout and 'restriction_observed_no_response' or 'unknown_no_response')
    attempt.baselineTracks=nil;attempt.deadline=nil
    if attempt.firstResponse then attempt.responseDelay=r(attempt.firstResponse-attempt.start)end
    t.inputObservations[#t.inputObservations+1]=attempt
    Core.appendEvent(t,'INPUT_OBSERVATION',{key=attempt.key,status=attempt.status,inputTime=attempt.start,responseDelay=attempt.responseDelay,summary=attempt.status..' (server acceptance unknown)'},ts)
    table.remove(t.pendingInputs,i)
   end
  end
 end
 function Core.observeHeldMovement(t,sample,ts)
  local held={};for _,key in ipairs({'W','A','S','D'})do if t.keys and t.keys[key]then held[#held+1]=key end end
  local key=table.concat(held,'+');local speed=sample and (sample.measuredMove or sample.move or 0)or 0
  local status=key==''and 'none' or (speed>.5 and 'movement_observed_while_held' or (t.controlState and t.controlState.restricted and 'restriction_observed_while_held' or 'no_movement_observed_while_held'))
  local signature=key..'|'..status
  if signature~=t.heldMovementSignature then
   t.heldMovementWindows=t.heldMovementWindows or {}
   if t.openHeldMovement then t.openHeldMovement.finish=r(ts);t.openHeldMovement.duration=r(ts-t.openHeldMovement.start);t.heldMovementWindows[#t.heldMovementWindows+1]=t.openHeldMovement;t.openHeldMovement=nil end
   if key~=''then t.openHeldMovement={start=r(ts),keys=key,status=status,animationTimes=Core.activeTrackTimes(t)}end
   if key~=''then Core.appendEvent(t,'HELD_MOVEMENT_OBSERVATION',{key=key,summary=status,actualSpeed=speed},ts)end
   t.heldMovementSignature=signature
  end
 end
 function Core.finishControl(t,ts)
  Core.checkInputAttempts(t,nil,ts,true)
  if t.openHeldMovement then t.openHeldMovement.finish=r(ts);t.openHeldMovement.duration=r(ts-t.openHeldMovement.start);t.openHeldMovement.openAtTakeEnd=true;t.heldMovementWindows=t.heldMovementWindows or {};t.heldMovementWindows[#t.heldMovementWindows+1]=t.openHeldMovement;t.openHeldMovement=nil end
  if t.openStateWindow then
   t.openStateWindow.finish=r(ts);t.openStateWindow.duration=r(ts-t.openStateWindow.start);t.openStateWindow.animationEndTimes=Core.activeTrackTimes(t);t.openStateWindow.openAtTakeEnd=true
   t.stateWindows=t.stateWindows or {};t.stateWindows[#t.stateWindows+1]=t.openStateWindow;t.openStateWindow=nil
  end
 end

 function Core.inputUpdate(t,name,down,ts,processed)
    if t.keys[name]==down then return end
    local wasMoving=moving(t.keys)
    t.keys[name]=down
    Core.appendEvent(t,down and 'KEY_DOWN' or 'KEY_UP',{key=name,processed=processed==true},ts)
    if down then Core.noteInputAttempt(t,name,ts,processed)end
    local isMoving=moving(t.keys)
    if wasMoving~=isMoving then
        Core.appendEvent(t,isMoving and 'WASD_RESUME' or 'WASD_STOP',{},ts)
    end
end
 function Core.trackInfo(t,track,ts)
    local anim; pcall(function() anim=track.Animation end)
    local id=anim and tostring(anim.AnimationId):match('(%d+)') or nil
    if not id then return end
    local label=(anim and anim.Name) or 'Unknown'
    local info=t.trackObjs[track]
    if not info then
        info={id=id,name=label,priority=tostring(track.Priority),first=ts,last=ts,
            speed=r(track.Speed),length=r(track.Length),looped=track.Looped}
        t.trackObjs[track]=info
        t.trackList[#t.trackList+1]=info
        Core.appendEvent(t,'TRACK_START',{id=id,speed=info.speed,name=label},ts)
    elseif t.trackPresent[track]==nil then
        Core.appendEvent(t,'TRACK_START',{id=id,speed=r(track.Speed),name=label,restarted=true},ts)
    end
    info.last=ts
    local speed=track.Speed
    if math.abs(speed-info.speed)>0.001 then
        info.speed=r(speed)
        Core.appendEvent(t,'ANIM_SPEED',{id=id,speed=r(speed),timePosition=r(track.TimePosition)},ts)
    end
    if t.trackPresent[track]==nil then t.trackPresent[track]=true end
    t.trackPresent[track]=true
end
 function Core.scanTracks(t,ts)
    local ok,active=pcall(function() return t.rigObj.animator:GetPlayingAnimationTracks() end)
    if not ok then return end
    local present={}
    for _,track in ipairs(active) do
        present[track]=true
        pcall(Core.trackInfo,t,track,ts)
    end
    for track,_ in pairs(t.trackPresent) do
        if not present[track] then
            local info=t.trackObjs[track]
            if info then Core.appendEvent(t,'TRACK_STOP',{id=info.id},ts) end
            t.trackPresent[track]=nil
        end
    end
end
 function Core.sampleMotion(t,ts)
    local rig=t.rigObj
    local vel=rig.root.AssemblyLinearVelocity
    local camera=workspace.CurrentCamera
    local sample={t=ts,joints={},parts={},pivots={},walk=r(rig.hum.WalkSpeed),move=r(Vector3.new(vel.X,0,vel.Z).Magnitude),
        velocity=Core.vec3(vel),root=Core.cft(t.origin:ToObjectSpace(rig.root.CFrame)),
        moveDirection=Core.vec3(rig.hum.MoveDirection),moveLocal=Core.vec3(rig.root.CFrame:VectorToObjectSpace(rig.hum.MoveDirection)),
        locomotion=rig.hum:GetState().Name,floor=rig.hum.FloorMaterial.Name,jump=rig.hum.Jump,autoRotate=rig.hum.AutoRotate,
        camera=camera and Core.cft(t.origin:ToObjectSpace(camera.CFrame))or nil,
        mouseBehavior=UIS.MouseBehavior.Name,tracks={}}
    for _,j in ipairs(rig.channels) do
        local obj=j.obj; if not obj or not obj.Parent then return false end
        local c0,c1
        if j.kind=='AnimationConstraint' then
            local a,b=obj.Attachment0,obj.Attachment1
            if not a or not b then return false end
            c0,c1=a.CFrame,b.CFrame
        else c0,c1=obj.C0,obj.C1 end
        local p0,p1
        if j.kind=='AnimationConstraint'then p0,p1=obj.Attachment0.Parent,obj.Attachment1.Parent
        else p0,p1=obj.Part0,obj.Part1 end
        if not p0 or not p1 then return false end
        local pose=j.base0:Inverse()*p0.CFrame:ToObjectSpace(p1.CFrame)*j.base1
        sample.joints[#sample.joints+1]=Core.cft(pose)
        sample.parts[j.child]=Core.cft(rig.root.CFrame:ToObjectSpace(p1.CFrame))
        sample.pivots[j.child]=Core.cft(rig.root.CFrame:ToObjectSpace(p1.CFrame*c1))
    end
    local ok,playing=pcall(function() return rig.animator:GetPlayingAnimationTracks() end)
    if ok then
        for _,track in ipairs(playing) do
            local info=t.trackObjs[track]
            if info then sample.tracks[#sample.tracks+1]={id=info.id,speed=r(track.Speed),time=r(track.TimePosition),weight=r(track.WeightCurrent)} end
        end
    end
    if t.lastSampleTime and ts>t.lastSampleTime then
        local delta=(rig.root.Position-t.lastSamplePosition)/(ts-t.lastSampleTime)
        sample.measuredVelocity=Core.vec3(delta)
        sample.measuredMove=r(Vector3.new(delta.X,0,delta.Z).Magnitude)
        if ts-t.lastSampleTime>2.5/CFG.FPS then Core.appendEvent(t,'SAMPLE_GAP',{seconds=r(ts-t.lastSampleTime)},ts)end
    end
    t.lastSampleTime=ts;t.lastSamplePosition=rig.root.Position
    Core.observeControl(t,sample,ts,false);Core.checkInputAttempts(t,sample,ts,false);Core.observeHeldMovement(t,sample,ts)
    sample.visibility=Core.visibility(t,ts)
    sample.distance=Core.distanceStep(t,rig.root.Position,ts,Core.actionLabel(t,sample.visibility))
    t.frames[#t.frames+1]=sample
    if not t.lastWalk or math.abs(sample.walk-t.lastWalk)>0.05 then
        Core.appendEvent(t,'WALK_SPEED',{studsPerSec=sample.walk},ts); t.lastWalk=sample.walk
    end
    local movingActual=sample.move>0.5
    if t.lastActualMove==nil or movingActual~=t.lastActualMove then
        Core.appendEvent(t,movingActual and 'MOVE_START' or 'MOVE_STOP',{actualSpeed=sample.move},ts)
        t.lastActualMove=movingActual
    end
    local bucket=math.floor(sample.move*2+0.5)/2
    if bucket~=t.lastVelocityBucket then
        Core.appendEvent(t,'ACTUAL_SPEED',{studsPerSec=sample.move},ts)
        t.lastVelocityBucket=bucket
    end
    -- Do not call this an authoritative sprint state: it is measured speed
    -- WHILE Shift is held and WASD is down, even if the game ignores Shift.
    if t.actor and t.actor.isLocal and t.keys.Shift and moving(t.keys) then
        if bucket~=t.lastShiftBucket then
            Core.appendEvent(t,'SHIFT_HELD_SPEED',{
                studsPerSec=sample.move,walkSpeedSetting=sample.walk},ts)
            t.lastShiftBucket=bucket
        end
    else
        t.lastShiftBucket=nil
    end
    return true
end

