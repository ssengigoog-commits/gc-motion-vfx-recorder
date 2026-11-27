
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
  local lines={'GC OBSERVED CONTROL TIMING','Times are seconds relative to take start. Client evidence only; server acceptance unknown.','Flag polling: 0.05s; input response observation: 0.45s. No response does not prove a blocked input.','Numeric/string stun flags remain raw because they may be deadlines.','', 'RESTRICTION WINDOWS'}
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
    if mode~='ANIM' and mode~='VFX' and mode~='INSPECT' and mode~='GAME' then msg('Unknown recording mode');return end
    if recording then
        if recording.kind==mode then stopRecord() else msg('Stop '..recording.kind..' recording first.') end
        return
    end
    if playback and stopPreview then stopPreview() end
    local rig,err=Core.getRig()
    if not rig then msg('Cannot record: '..err,Color3.fromRGB(230,90,90)); return end
    serial=serial+1
    local id=tostring(os.time())..'_'..tostring(serial)
    local t={id=id,kind=mode,name='GC v'..Core.RECORDER_VERSION..' '..(mode=='ANIM' and 'Animation ' or mode=='GAME' and 'Game Recorder ' or mode=='INSPECT' and 'Inspector ' or 'VFX ')..os.date('%H:%M:%S')..' #'..serial,
        created=os.date('!%Y-%m-%dT%H:%M:%SZ'),rigObj=rig,rig=rig.rig,start=os.clock(),frames={},events={},vfx={},
        trackObjs={},trackPresent={},trackList={},keys={},vfxSeen={},vfxPending={},pendingCount=0,vfxSerial=0,
        channels={},metrics={},origin=rig.root.CFrame,groupRoots={},groupCount=0,nextSample=0,nextVFX=0,trackScan=0,lastWalk=nil}
    if mode=='ANIM' or mode=='GAME' then
        t.metrics.HumanoidRootPart={size=Core.vec3(rig.root.Size)}
        for _,j in ipairs(rig.channels) do
            t.channels[#t.channels+1]={parent=j.parent,child=j.child,kind=j.kind,name=j.obj.Name,base0=Core.cft(j.base0),base1=Core.cft(j.base1)}
            local p=rig.char:FindFirstChild(j.child);if p then t.metrics[j.child]={size=Core.vec3(p.Size)}end
        end
        for key,_ in pairs(WATCH) do
            local down=UIS:IsKeyDown(Enum.KeyCode[key]);t.keys[key]=down
            if down then Core.appendEvent(t,'KEY_HELD_AT_START',{key=key},0) end
        end
        local running=UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)
        t.keys.Shift=running
        if running then Core.appendEvent(t,'SHIFT_KEY_HELD_AT_START',{},0) end
        for i=1,3 do local button=Enum.UserInputType['MouseButton'..i];local held=UIS:IsMouseButtonPressed(button);t.keys['Mouse'..i]=held;if held then Core.appendEvent(t,'KEY_HELD_AT_START',{key='Mouse'..i},0)end end
        if moving(t.keys) then Core.appendEvent(t,'WASD_RESUME',{},0) end
        Core.appendEvent(t,'WALK_SPEED',{studsPerSec=r(rig.hum.WalkSpeed)},0)
        Core.scanTracks(t,0)
    end
    if mode=='VFX' or mode=='GAME' then
        local ground=Core.groundPoint(t.origin.Position,rig.char)
        if ground then t.groundReference={height=r(t.origin.Position.Y-ground.Y),point=Core.vec3(ground)}end
        Group.seed(t)
    end
    if mode=='INSPECT' or mode=='GAME' then
        local ok,reason=Core.inspectBegin(t)
        if not ok then Group.finish(t);msg('Cannot inspect: '..reason,Color3.fromRGB(230,90,90));return end
    end
    if mode=='GAME' then
        local ok,reason=Core.gameBegin(t)
        if not ok then Core.inspectFinish(t);Group.finish(t);msg('Cannot start Game Recorder: '..tostring(reason));return end
    end
    recording=t;libraryFilter=mode
    Core.beginCaptureObservers(t)
    if mode=='INSPECT' or mode=='GAME' then Core.inspectPrime(t) end
    if mode=='GAME' then Core.gamePrime(t) end
    if drawLibrary then drawLibrary() end
    if drawDetails then drawDetails() end
    msg('Recording '..mode..' ['..rig.rig..'] — F6 motion / F8 VFX / F3 game / '..CFG.MAX_SECONDS..'s max.',Color3.fromRGB(242,112,109))
end

stopRecord=function()
    local t=recording
    if not t then return end
    recording=nil
    Core.endCaptureObservers()
    local ts=now(t)
    if t.kind=='VFX' or t.kind=='GAME'then
        local budget=0
        for object in pairs(t.vfxPending)do
            if budget>=CFG.SCAN_BUDGET then break end
            Group.add(t,object,ts);t.vfxPending[object]=nil;t.pendingCount-=1;budget+=1
        end
        Group.scan(t,ts);Group.refresh(t,ts)
        if t.pendingCount>0 or (t.captureStats and (not t.captureStats.indexWarm or t.captureStats.watchLimit))then t.truncatedVFX=true end
    end
    Group.finish(t)
    if t.kind=='ANIM' or t.kind=='GAME' then
        if #t.frames==0 then
            if t.kind=='GAME' then Core.inspectFinish(t);Core.gameFinish(t) end
            msg('No animation frames captured. Try again.',Color3.fromRGB(250,110,110));return
        end
        Core.scanTracks(t,ts)
        Core.finishControl(t,ts)
        if t.kind=='GAME' then
            Core.inspectFinish(t)
            Core.gameFinish(t)
        end
        for key,down in pairs(t.keys) do
            if down then Core.appendEvent(t,'KEY_HELD_AT_END',{key=key},ts) end
        end
    elseif t.kind=='INSPECT' then
        Core.inspectFinish(t)
        if not t.inspector or #t.inspector.frames==0 then
            msg('No inspector frames captured. Try again.',Color3.fromRGB(250,110,110));return
        end
    else
        -- Close active effects at end time. This is a preview boundary, not an
        -- authoritative removal time in the source game.
        if #t.vfx==0 then msg('No nearby client-visible VFX captured. Try again near an effect.',Color3.fromRGB(250,110,110));return end
    end
    local last=t.frames[#t.frames]
    local result={version=6,recorderVersion=Core.RECORDER_VERSION,recorderBuild=Core.RECORDER_BUILD,kind=t.kind,name=t.name,rig=t.rig,fps=CFG.FPS,vfxFps=CFG.VFX_FPS,
        duration=r(t.kind=='ANIM' and (last and last.t or ts) or ts),
        frames=t.frames,channels=t.channels,metrics=t.metrics,origin=Core.cft(t.origin),events=t.events,tracks=t.trackList,vfx=t.vfx,
        inspector=t.inspector,game=t.game,
        combinedStreams=t.kind=='GAME' and {'motion','animation','grouped_vfx','selected_actors','client_audio','camera','hud_visibility','replicated_state','highlights','inputs'} or nil,
        stateWindows=t.stateWindows,heldMovementWindows=t.heldMovementWindows,inputObservations=t.inputObservations,inputObservationLimit=t.inputObservationLimit==true,
        controlLegend={pollSeconds=.05,responseWindowSeconds=.45,meaning='Observed client flags/motion/track changes only. Server acceptance and hidden stun rules unknown. Numeric flags retained raw, not interpreted as boolean stun.'},
        effectiveFPS=(#t.frames>1 and r((#t.frames-1)/math.max(t.frames[#t.frames].t-t.frames[1].t,.001))or 0),
        previewUnknownBursts=estimateBurstPreview,worldImageVFX=true,truncatedVFX=t.truncatedVFX==true,captureStats=t.captureStats,groundReference=t.groundReference,previewHeight=CFG.PREVIEW_HEIGHT,
        coordinateSpace="Root/camera relative to fixed take start; body parts relative to sampled root",
        notes={
            t.kind=='GAME' and 'F3 Game Recorder combines motion, grouped VFX, Highlight appearance/properties, and Inspector timestamps in one take.' or 'F6/F8 recordings remain separate.',
            'Client cannot inspect ServerStorage. Effects must be observable in Workspace.',
            'Direct ParticleEmitter:Emit(n) calls are not observable; preview bursts are estimates.',
            'Real timestamps, inputs, root/camera motion and evaluated body parts are preserved.',
            'Ghost preview never changes live character joints or physics.',
            'Asset permissions, server-only content and Emit counts remain platform limits.',
            'R6/R15 cross-rig mapping is approximate.',
        }}
    if t.kind=='GAME' then result.controlReport=Core.controlReport(result) end
    local raw=Core.exportJson(result)
    if not raw then msg('JSON encoding failed.',Color3.fromRGB(250,100,100));return end
    local path=CFG.PREFIX..t.id..'_'..t.kind..'.json'
    local onDisk=Core.safeWrite(path,raw)
    if t.kind=='ANIM' or t.kind=='GAME' then
        -- Control notes also remain embedded in the raw take when file storage lacks TXT support.
        result.controlReport=Core.controlReport(result)
        Core.safeWrite(CFG.PREFIX..t.id..'_CONTROL_NOTES.txt',result.controlReport)
    end
    local meta={id=t.id,kind=t.kind,name=t.name,rig=t.rig,created=t.created,path=path,
        duration=result.duration,nframes=(t.inspector and #t.inspector.frames or #t.frames),nvfx=#t.vfx,tracks=t.trackList,
        saved=onDisk,raw=(not onDisk)and raw or nil,data=(not onDisk)and result or nil}
    table.insert(saved,1,meta);selected=meta.id
    Core.saveHistory()
    if t.kind=='GAME' then
        msg(string.format('V7.1.2 GAME saved: %d motion frames, %d VFX events, %d highlight changes, %d actor samples, %d game samples, %d events%s',
            #t.frames,#t.vfx,#t.game.highlights,#t.inspector.frames,#t.game.frames,#t.events,onDisk and ' (file)' or ' (memory)'),Color3.fromRGB(90,205,150))
    elseif t.kind=='INSPECT' then
        msg(string.format('V6.9 INSPECT saved: %d samples, %d actors, %d events%s',
            #t.inspector.frames,#t.inspector.actors,#t.events,onDisk and ' (file)' or ' (memory)'),Color3.fromRGB(90,205,150))
    elseif t.kind=='ANIM' then
        msg(string.format('V6.9 ANIM saved: %d frames, %d movement events, %d tracks%s',
            #t.frames,#t.events,#t.trackList,onDisk and ' (file)' or ' (memory)'),Color3.fromRGB(90,205,150))
    else
        msg(string.format('V6.9 VFX saved: %d effect events%s. Play VFX to preview 9 studs ahead.',
            #t.vfx,onDisk and ' (file)' or ' (memory)'),Color3.fromRGB(90,205,150))
    end
    if result.truncatedVFX then msg('VFX take reached a capture limit; inspect truncatedVFX and group snapshot flags.',Color3.fromRGB(240,170,80))end
    if drawLibrary then drawLibrary() end
    if drawDetails then drawDetails() end
end
