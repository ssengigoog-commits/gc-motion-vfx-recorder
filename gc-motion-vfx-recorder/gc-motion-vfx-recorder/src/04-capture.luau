
 function Core.vfxAdd(t,obj,ts)Group.add(t,obj,ts)end
 function Core.vfxRefresh(t,ts)Group.scan(t,ts);Group.refresh(t,ts)end

 function Core.groundPoint(position,char)
  local params=RaycastParams.new()
  params.FilterType=Enum.RaycastFilterType.Exclude
  local ignored=char and {char}or {}
  params.IgnoreWater=true;params.RespectCanCollide=true
  for _=1,4 do
   params.FilterDescendantsInstances=ignored
   local result=workspace:Raycast(position+Vector3.new(0,8,0),Vector3.new(0,-2048,0),params)
   if not result then return nil end
   local model=result.Instance and result.Instance:FindFirstAncestorOfClass('Model')
   if model and model:FindFirstChildOfClass('Humanoid')then ignored[#ignored+1]=model
   elseif result.Normal.Y>.2 then return result.Position
   else return nil end
  end
 end
 function Core.groundOrigin(data,origin,char)
  local source=data.groundReference
  local height=source and tonumber(source.height)or 3
  local point=Core.groundPoint(origin.Position,char)
  if not point then return origin*CFrame.new(0,CFG.PREVIEW_HEIGHT,0)end
  local p=origin.Position
  return CFrame.new(p.X,point.Y+height+CFG.PREVIEW_HEIGHT,p.Z)*origin.Rotation
 end
 function Core.controlReport(data)
  local lines={'GC OBSERVED CONTROL TIMING','Times are seconds relative to take start. Client evidence only; server acceptance unknown.','Flag polling: 0.10s; input response observation: 0.45s. No response does not prove a blocked input.','Numeric/string stun flags remain raw because they may be deadlines.','', 'RESTRICTION WINDOWS'}
  for _,window in ipairs(data.stateWindows or {})do
   lines[#lines+1]=string.format('%.3f - %.3fs | %s | %s',window.start,window.finish,window.kind,table.concat(window.reasons,', '))
   for _,track in ipairs(window.animationTimes or {})do lines[#lines+1]=string.format('  Start: animation %s %s at %.3fs (%.2fx)',track.id,track.name or '',track.time,track.speed)end
   for _,track in ipairs(window.animationEndTimes or {})do lines[#lines+1]=string.format('  End: animation %s %s at %.3fs (%.2fx)',track.id,track.name or '',track.time,track.speed)end
  end
  lines[#lines+1]='';lines[#lines+1]='HELD MOVEMENT WINDOWS'
  for _,window in ipairs(data.heldMovementWindows or {})do lines[#lines+1]=string.format('%.3f - %.3fs | %s | %s',window.start,window.finish,window.keys,window.status)end
  lines[#lines+1]='';lines[#lines+1]='KEY / INPUT OBSERVATIONS'
  local ordered=table.clone(data.inputObservations or {});table.sort(ordered,function(a,b)return a.start<b.start end)
  for _,attempt in ipairs(ordered)do
   local evidence={};for name in pairs(attempt.evidence or {})do evidence[#evidence+1]=name end;table.sort(evidence)
   lines[#lines+1]=string.format('%.3fs | %s | %s | %s%s',attempt.start,(attempt.heldKeys and #attempt.heldKeys>0)and table.concat(attempt.heldKeys,'+')or attempt.key,attempt.status,table.concat(evidence,', '),attempt.responseDelay and string.format(' | response after %.3fs',attempt.responseDelay)or '')
  end
  return table.concat(lines,'\n')
 end
 function Core.startRecord(mode)
    mode=mode or 'ANIM'
    if recording then
        if recording.kind==mode then stopRecord()else msg('Stop '..recording.kind..' recording first.')end
        return
    end
    if playback and stopPreview then stopPreview()end
    local observer,err=Core.getRig()
    if not observer then msg('Cannot record: '..err,Color3.fromRGB(230,90,90));return end
    local actors,limited
    if Core.hasMotion(mode)then
     actors,limited=Core.selectActors(observer)
     if #actors==0 then msg('No selected actors in range. Check SETTINGS.');return end
    else actors={{rig=observer,actor={id='player:'..localPlayer.UserId,username=localPlayer.Name,name=observer.char.Name,isLocal=true}}}end
    serial+=1
    local id=tostring(os.time())..'_'..tostring(serial)
    local t={id=id,kind=mode,name='GC v'..Core.RECORDER_VERSION..' '..mode..' '..os.date('%H:%M:%S')..' #'..serial,
        created=os.date('!%Y-%m-%dT%H:%M:%SZ'),start=os.clock(),frames={},events={},vfx={},keys={},
        vfxSeen={},vfxPending={},pendingCount=0,vfxSerial=0,origin=observer.root.CFrame,
        groupRoots={},groupCount=0,nextSample=0,nextVFX=0,trackScan=0,actorsLimited=limited==true}
    Core.initActor(t,actors[1].rig,actors[1].actor)
    t.allActors={t}
    if Core.hasMotion(mode)then
     for index=2,#actors do
      local actor={start=t.start,origin=t.origin}
      Core.initActor(actor,actors[index].rig,actors[index].actor)
      t.allActors[#t.allActors+1]=actor
     end
     if t.actor.isLocal then
      for key in pairs(WATCH)do
       local down=UIS:IsKeyDown(Enum.KeyCode[key]);t.keys[key]=down
       if down then Core.appendEvent(t,'KEY_HELD_AT_START',{key=key},0)end
      end
      t.keys.Shift=UIS:IsKeyDown(Enum.KeyCode.LeftShift)or UIS:IsKeyDown(Enum.KeyCode.RightShift)
      for i=1,3 do
       local held=UIS:IsMouseButtonPressed(Enum.UserInputType['MouseButton'..i]);t.keys['Mouse'..i]=held
       if held then Core.appendEvent(t,'KEY_HELD_AT_START',{key='Mouse'..i},0)end
      end
     end
     Core.sampleActors(t,0)
    end
    recording=t
    if Core.hasMotion(mode)then for _,actor in ipairs(t.allActors)do Core.listenVisibility(actor,t)end end
    if Core.hasVFX(mode)then
     local ground=Core.groundPoint(t.origin.Position,observer.char)
     if ground then t.groundReference={height=r(t.origin.Position.Y-ground.Y),point=Core.vec3(ground)}end
     Group.seed(t)
    end
    libraryFilter=mode
    if drawLibrary then drawLibrary()end
    if drawDetails then drawDetails()end
    msg('Recording '..mode..' | '..#t.allActors..' actor(s) | F9 combined | '..CFG.MAX_SECONDS..'s max.',Color3.fromRGB(242,112,109))
end

stopRecord=function()
    local t=recording
    if not t then return end
    recording=nil
    for _,actor in ipairs(t.allActors or {})do Core.finishVisibility(actor)end
    local ts=now(t)
    if Core.hasVFX(t.kind)then
        local budget=0
        for object in pairs(t.vfxPending)do
            if budget>=CFG.SCAN_BUDGET then break end
            Group.add(t,object,ts);t.vfxPending[object]=nil;t.pendingCount-=1;budget+=1
        end
        Group.scan(t,ts);Group.refresh(t,ts)
        if t.pendingCount>0 or (t.captureStats and (not t.captureStats.indexWarm or t.captureStats.watchLimit))then t.truncatedVFX=true end
    end
    Group.finish(t)
    if Core.hasMotion(t.kind) then
        local total=0;for _,actor in ipairs(t.allActors)do total+=#actor.frames;Core.finishControl(actor,ts);Core.finishDistance(actor,ts)end
        if total==0 then msg('No animation frames captured. Try again.',Color3.fromRGB(250,110,110));return end
        Core.scanTracks(t,ts)
        -- Every actor was finalized above.
        for key,down in pairs(t.keys) do
            if down then Core.appendEvent(t,'KEY_HELD_AT_END',{key=key},ts) end
        end
    else
        -- Close active effects at end time. This is a preview boundary, not an
        -- authoritative removal time in the source game.
        if #t.vfx==0 then msg('No nearby client-visible VFX captured. Try again near an effect.',Color3.fromRGB(250,110,110));return end
    end
    local last=t.frames[#t.frames]
    local result={version=7,recorderVersion=Core.RECORDER_VERSION,recorderBuild=Core.RECORDER_BUILD,kind=t.kind,name=t.name,rig=t.rig,fps=CFG.FPS,vfxFps=CFG.VFX_FPS,
        duration=r(ts),
        frames=t.frames,channels=t.channels,metrics=t.metrics,origin=Core.cft(t.origin),events=t.events,tracks=t.trackList,vfx=t.vfx,
        stateWindows=t.stateWindows,heldMovementWindows=t.heldMovementWindows,inputObservations=t.inputObservations,inputObservationLimit=t.inputObservationLimit==true,
        controlLegend={pollSeconds=.1,responseWindowSeconds=.45,meaning='Observed client flags/motion/track changes only. Server acceptance and hidden stun rules unknown. Numeric flags retained raw, not interpreted as boolean stun.'},
        effectiveFPS=(#t.frames>1 and r((#t.frames-1)/math.max(t.frames[#t.frames].t-t.frames[1].t,.001))or 0),
        previewUnknownBursts=estimateBurstPreview,worldImageVFX=true,truncatedVFX=t.truncatedVFX==true,captureStats=t.captureStats,groundReference=t.groundReference,previewHeight=CFG.PREVIEW_HEIGHT,
        coordinateSpace="Root/camera relative to fixed take start; body parts relative to sampled root",
        notes={
            'COMBINED mode records actors and VFX against the same session clock.',
            'Visibility and distance are sampled client observations; hidden motion is retained.',
            'Capture is bounded; radius, sampling gaps and limits are reported.',
            'Client cannot inspect ServerStorage. Effects must be observable in Workspace.',
            'Direct ParticleEmitter:Emit(n) calls are not observable; preview bursts are estimates.',
            'Real timestamps, inputs, root/camera motion and evaluated body parts are preserved.',
            'Ghost preview never changes live character joints or physics.',
            'Asset permissions, server-only content and Emit counts remain platform limits.',
            'R6/R15 cross-rig mapping is approximate.',
        }}
    local primary=Core.actorResult(t)
    result.actor=t.actor;result.distance=primary.distance;result.eventsLimited=t.eventsLimited==true;result.actors={}
    for index=2,#t.allActors do result.actors[#result.actors+1]=Core.actorResult(t.allActors[index])end
    result.captureSettings={localActor=Core.Settings.localActor,npcs=Core.Settings.npcs,otherPlayers=Core.Settings.otherPlayers,actorNames=Core.Settings.actorNames,motionFPS=CFG.FPS,vfxFPS=CFG.VFX_FPS,maxActors=CFG.MAX_ACTORS,vfxRadius=CFG.VFX_RADIUS}
    result.actorsLimited=t.actorsLimited;result.motionLimited=t.motionLimited==true;result.recorderTickMaxMs=r(t.maxRecorderTickMs or 0)
    local raw=Core.exportJson(result)
    if not raw then msg('JSON encoding failed.',Color3.fromRGB(250,100,100));return end
    local path=CFG.PREFIX..t.id..'_'..t.kind..'.json'
    local onDisk=Core.safeWrite(path,raw)
    if Core.hasMotion(t.kind)then Core.safeWrite(CFG.PREFIX..t.id..'_CONTROL_NOTES.txt',Core.controlReport(result))end
    local meta={id=t.id,kind=t.kind,name=t.name,rig=t.rig,created=t.created,path=path,
        duration=result.duration,nframes=#t.frames,nvfx=#t.vfx,tracks=t.trackList,
        saved=onDisk,raw=(not onDisk)and raw or nil,data=result}
    table.insert(saved,1,meta);selected=meta.id
    Core.saveHistory()
    if Core.hasMotion(t.kind) then
        msg(string.format('V7 ANIM saved: %d frames, %d movement events, %d tracks%s',
            #t.frames,#t.events,#t.trackList,onDisk and ' (file)' or ' (memory)'),Color3.fromRGB(90,205,150))
    else
        msg(string.format('V7 VFX saved: %d effect events%s. Play VFX to preview 9 studs ahead.',
            #t.vfx,onDisk and ' (file)' or ' (memory)'),Color3.fromRGB(90,205,150))
    end
    if result.truncatedVFX then msg('VFX take reached a capture limit; inspect truncatedVFX and group snapshot flags.',Color3.fromRGB(240,170,80))end
    if drawLibrary then drawLibrary() end
    if drawDetails then drawDetails() end
end
