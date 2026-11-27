



 function Core.takeFormat(data)
 if not data then return 'UNLOADED'end
 if type(data.recorderVersion)=='string'then return 'RECORDER '..data.recorderVersion end
 for _,event in ipairs(data.vfx or {})do if event.snapshot and event.snapshot.stableNodes then return 'OLDER TAKE: v6.7 format'end end
 return 'OLDER TAKE: recorder version unstamped'
 end
 function Core.copyRecorded(value)
  if type(value)~='table'then return value end
  local copy={};for key,item in pairs(value)do copy[key]=Core.copyRecorded(item)end;return copy
 end
 function Core.rebaseEvent(event,offset,startTime)
  local copy=Core.copyRecorded(event);copy.t=r((copy.t or 0)-startTime)
  local function shift(frame)
   if type(frame)=='table'and #frame==12 then frame[1]-=offset.X;frame[2]-=offset.Y;frame[3]-=offset.Z end
  end
  if copy.snapshot then
   shift(copy.snapshot.anchor)
   for _,node in ipairs(copy.snapshot.nodes or {})do
    shift(node.cf)
    if node.class=='Attachment'and node.parent==0 and node.props and node.props.CFrame then shift(node.props.CFrame.v)end
   end
  end
  for _,change in ipairs(copy.changes or {})do
   shift(change.cf);shift(change.attachmentCF)
   if change.attachmentCF and change.props and change.props.CFrame then shift(change.props.CFrame.v)end
  end
  return copy
 end
 function Core.splitVfx(t)
  local data=loadData(t)
  if not data or data.kind~='VFX'then msg('Select a VFX recording.');return end
  local ids,seen={},{}
  for _,event in ipairs(data.vfx or {})do if event.op=='group_spawn'and not seen[event.id]then seen[event.id]=event;ids[#ids+1]=event.id end end
  local count=0
  for _,id in ipairs(ids)do
   local part=table.clone(data);part.vfx={};part.frames={};part.events={};part.tracks={}
   part.name=(seen[id].snapshot.name or 'Effect')..' / group '..id
   part.parentTake=t.id;part.sourceGroup=id
   local first=seen[id];local node=first.snapshot.nodes and first.snapshot.nodes[1]
   local frame=first.snapshot.anchor or (node and (node.cf or (node.class=='Attachment'and node.props and node.props.CFrame and node.props.CFrame.v)))
   local offset=Core.cff(frame).Position
   local startTime=first.t or 0
   part.sourceStartTime=startTime;part.duration=math.max(0,(data.duration or 0)-startTime)
   part.origin=Core.cft(Core.cff(data.origin)*CFrame.new(offset))
   part.groundReference={height=first.snapshot.groundOffset or ((data.groundReference and data.groundReference.height or 3)+offset.Y)}
   for _,event in ipairs(data.vfx)do if event.id==id then part.vfx[#part.vfx+1]=Core.rebaseEvent(event,offset,startTime)end end
   local tid=t.id..'_G'..id;local exists=false
   for _,old in ipairs(saved)do if old.id==tid then exists=true;break end end
   if not exists then
    local path=CFG.PREFIX..tid..'_VFX.json';local raw=Core.exportJson(part)
    local written=raw and Core.safeWrite(path,raw)or false
    saved[#saved+1]={id=tid,name=part.name,kind='VFX',rig=t.rig,created=t.created,duration=part.duration,nframes=0,nvfx=#part.vfx,tracks={},path=path,saved=written,data=part,raw=not written and raw or nil}
    count+=1
   end
   if count%4==0 then task.wait()end
  end
  Core.saveHistory();if drawLibrary then drawLibrary()end
  msg(tostring(count)..' separate part/attachment recordings added. Original bundle kept.')
 end
 function Core.retargetPose(data,frame,part)
    local by={}
    for i,c in ipairs(data.channels) do by[c.child]=frame.joints[i] end
    local direct=by[part]
    if direct then return Core.cff(direct) end
    if data.rig=='R6' then
        local mapping={LowerTorso='Torso',RightUpperArm='Right Arm',LeftUpperArm='Left Arm',
            RightUpperLeg='Right Leg',LeftUpperLeg='Left Leg'}
        if mapping[part] then return Core.cff(by[mapping[part]]) end
    else
        local mapping={['Right Arm']='RightUpperArm',['Left Arm']='LeftUpperArm',
            ['Right Leg']='RightUpperLeg',['Left Leg']='LeftUpperLeg'}
        if mapping[part] then return Core.cff(by[mapping[part]]) end
        if part=='Torso' then return Core.cff(by.LowerTorso)*Core.cff(by.UpperTorso) end
    end
    return CFrame.new()
end
 function Core.createMotionGhost(data,folder)
 local model=Instance.new('Model');model.Name='RecordedMotionGhost';model.Parent=folder
 local parts,markers={},{}
 local names={'HumanoidRootPart'}
 for _,c in ipairs(data.channels or {})do names[#names+1]=c.child end
 for _,name in ipairs(names)do
  if not parts[name]then
   local p=Instance.new('Part');p.Name=name;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
   local meta=data.metrics and data.metrics[name]
   p.Size=meta and Core.toVec3(meta.size)or (name=='Head'and Vector3.new(2,1,1)or Vector3.new(1,2,1))
   p.Color=Color3.fromRGB(175,190,205);if name:find('Leg')or name:find('Foot')then p.Color=Color3.fromRGB(90,125,160)end
   p.Material=Enum.Material.SmoothPlastic;p.Transparency=name=='HumanoidRootPart'and 1 or .15;p.Parent=model;parts[name]=p
   if name~='HumanoidRootPart'then local j=Instance.new('Part');j.Name='Joint_'..name;j.Shape=Enum.PartType.Ball;j.Size=Vector3.new(.14,.14,.14);j.Anchored=true;j.CanCollide=false;j.CanTouch=false;j.CanQuery=false;j.Color=Color3.fromRGB(80,255,130);j.Material=Enum.Material.Neon;j.Parent=model;markers[name]=j end
  end
 end
 return {model=model,parts=parts,markers=markers}
end
 function Core.previewPose(pb)
 if not pb.anim or not pb.ghost then return end
 local frames=pb.data.frames;if #frames==0 then return end
 local t=pb.elapsed;local i=pb.frameIndex or 1
 while i<#frames-1 and frames[i+1].t<t do i+=1 end
 while i>1 and frames[i].t>t do i-=1 end
 pb.frameIndex=i
 local a,b=frames[i],frames[math.min(i+1,#frames)]
 local alpha=b.t>a.t and math.clamp((t-a.t)/(b.t-a.t),0,1)or 0
 local root=pb.origin*Core.cff(a.root):Lerp(Core.cff(b.root),alpha)
 pb.ghost.parts.HumanoidRootPart.CFrame=root
 for _,c in ipairs(pb.data.channels or {})do
  local part=pb.ghost.parts[c.child]
  local pa=a.parts and a.parts[c.child];local qb=b.parts and b.parts[c.child]
  if part and pa and qb then part.CFrame=root*Core.cff(pa):Lerp(Core.cff(qb),alpha)
  elseif part then
   local parent=pb.ghost.parts[c.parent]
   if parent and c.base0 and c.base1 then
    local da=Core.retargetPose(pb.data,a,c.child);local db=Core.retargetPose(pb.data,b,c.child)
    part.CFrame=parent.CFrame*Core.cff(c.base0)*da:Lerp(db,alpha)*Core.cff(c.base1):Inverse()
   else part.CFrame=root end
  end
  local marker=pb.ghost.markers[c.child]
  local ja=a.pivots and a.pivots[c.child];local jb=b.pivots and b.pivots[c.child]
  if marker then marker.Transparency=ja and jb and 0 or 1;if ja and jb then marker.CFrame=root*Core.cff(ja):Lerp(Core.cff(jb),alpha)end end
 end
end
 function Core.vfxAnchor(pb,relative)
    local part=Instance.new('Part'); part.Name='GC_VFX_PreviewAnchor'
    part.Size=Vector3.new(.1,.1,.1);part.Transparency=1;part.Anchored=true
    part.CanCollide=false;part.CanTouch=false;part.CanQuery=false
    part.CFrame=pb.origin*Core.cff(relative)
    part.Parent=pb.folder
    local attachment=Instance.new('Attachment');attachment.Parent=part
    return part,attachment
end
 function Core.createLocalEffect(pb,event)
    local kind=event.kind
    if not PROPERTIES[kind] then return end
    local frames=event.cf or {}
    if #frames==0 then return end
    local p0,a0=Core.vfxAnchor(pb,frames[1]); local pieces={p0}
    local obj=Instance.new(kind)
    if kind=='ParticleEmitter' then
        obj.Enabled=false
        obj.Parent=a0
    else
        local p1,a1=Core.vfxAnchor(pb,frames[2] or frames[1]);pieces[#pieces+1]=p1
        obj.Attachment0=a0;obj.Attachment1=a1;obj.Parent=p0
    end
    Core.applyProps(obj,event.props)
    -- Optional VISUAL ESTIMATE only, never written back as a recorded source event.
    if estimateBurstPreview and kind=='ParticleEmitter' and (not obj.Enabled or obj.Rate==0)then
        pcall(function() obj:Emit(12) end)
    end
    pb.effects[event.id]={obj=obj,parts=pieces,cf=frames}
end
 function Core.runVfxEvent(pb,e)
    local active=pb.effects[e.id]
    if e.op=='group_spawn'then
        local h,added
        if e.replace and e.snapshot.stableNodes and active and active.folder then h,added=Group.codec.sync(active,e.snapshot,pb.origin,false,pb.folder)
        else
         if active then if active.folder then active.folder:Destroy()else for _,p in ipairs(active.parts or {})do p:Destroy()end end end
         h=Group.codec.create(e.snapshot,pb.origin,false,pb.folder)
        end
        pb.effects[e.id]=h;h.curves=pb.renderCurves and pb.renderCurves[e]
        if #h.errors>0 then msg(tostring(#h.errors)..' geometry items unavailable; placeholders marked.',Color3.fromRGB(240,170,80))end
        if not e.replace or added then Group.codec.burst(h,estimateBurstPreview,added)end
        return
    elseif e.op=='group_update'then
        if active then for _,delta in ipairs(e.changes or {})do Group.codec.update(active,delta)end end;return
    elseif e.op=='group_remove'then
        if active and active.folder then Group.codec.retire(active)end;pb.effects[e.id]=nil;return
    end
    if e.op=='spawn' then
        if active then for _,p in ipairs(active.parts) do p:Destroy() end end
        Core.createLocalEffect(pb,e)
    elseif e.op=='remove' then
        if active then for _,p in ipairs(active.parts) do p:Destroy() end end
        pb.effects[e.id]=nil
    elseif active then
        if e.op=='props' then
            Core.applyProps(active.obj,e.props)
            if estimateBurstPreview and active.obj:IsA('ParticleEmitter') and (not active.obj.Enabled or active.obj.Rate==0)
                and e.props.Enabled==true then
                pcall(function() active.obj:Emit(12) end)
            end
        elseif e.op=='move' then active.cf=e.cf end
    end
end
 function Core.moveVfx(pb)
    if not pb.vfx then return end
    for _,x in pairs(pb.effects) do
        for i,part in ipairs(x.parts or {}) do
            local rel=x.cf and x.cf[i]
            if rel and part and part.Parent then
                part.CFrame=pb.origin*Core.cff(rel)
            end
        end
    end
end
stopPreview=function()
    previewGeneration+=1
    local pb=playback
    if not pb then return end
    playback=nil
    if pb.folder then pb.folder:Destroy() end
    -- Destroy only the preview folder; live joints are untouched.
    msg('Local preview stopped.',Color3.fromRGB(180,185,195))
end
 function Core.playSelection(kind,looped)
    if recording then msg('Stop recording before playback.');return end
    stopPreview()
    local generation=previewGeneration
    local t=nil
    for _,x in ipairs(saved) do if x.id==selected then t=x break end end
    if not t then msg('Select a take first.',Color3.fromRGB(242,130,130));return end
    local data=loadData(t)
    if not data then msg('Cannot load take from executor storage.',Color3.fromRGB(242,130,130));return end
    if (t.kind or data.kind or 'ANIM')~=kind and (t.kind or data.kind)~='GAME' then
        msg('Select a '..kind..' or GAME recording in its library tab.',Color3.fromRGB(242,130,130));return
    end
    if kind=='ANIM' and #(data.frames or {})==0 then
        msg('Animation take contains no pose frames.',Color3.fromRGB(242,130,130));return
    end
    if kind=='VFX' and #(data.vfx or {})==0 then
        msg('VFX take has no client-visible events.',Color3.fromRGB(242,130,130));return
    end
    local rig,err=Core.getRig()
    if not rig then msg(err,Color3.fromRGB(242,130,130));return end
    if kind=='ANIM'and not data.frames[1].root then msg('Legacy take has no root trace; jump height cannot be recovered.',Color3.fromRGB(240,170,80))end
    if kind=='VFX'then
        msg('Preparing grouped meshes through normal asset access...')
        Group.warmMeshes(data.vfx)
        for _,e in ipairs(data.vfx or {})do if e.op=='group_spawn'then Group.codec.preload(e.snapshot);if generation~=previewGeneration or recording then return end end end
    end
    local folder=Instance.new('Folder');folder.Name='GC_CLIENT_VFX_PREVIEW';folder.Parent=workspace
    -- VFX stays at a fixed location IN FRONT of the local character. It does
    -- not move with the character after playback begins.
    local origin=rig.root.CFrame*CFrame.new(0,0,-CFG.PREVIEW_DISTANCE)
    if kind=='VFX'then origin=Core.groundOrigin(data,origin,rig.char)end
    folder:SetAttribute('GC_BakerPreview',true)
    playback={data=data,rig=rig,anim=(kind=='ANIM'),vfx=(kind=='VFX'),
        start=os.clock(),elapsed=0,frameIndex=1,eventIndex=1,loop=looped,
        folder=folder,effects={},origin=origin,renderCurves=kind=='VFX'and Group.codec.prepare(data.vfx)or nil}
    if kind=='ANIM' then
        playback.ghost=Core.createMotionGhost(data,folder)
        msg('Playing separate motion ghost '..(looped and '(LOOP)'or '(ONCE)')..'.',Color3.fromRGB(100,210,155))
        -- Apply first pose immediately rather than waiting for next frame.
        Core.previewPose(playback)
    else
        msg('V6.8 preview | '..Core.takeFormat(data)..' | 9 studs ahead + 4 studs lift '..(looped and '(LOOP)' or '(ONCE)')..'.',Color3.fromRGB(100,210,155))
    end
end

 function Core.tickPreview()
    local pb=playback
    if not pb then return end
    if localPlayer.Character~=pb.rig.char or not pb.rig.root.Parent then stopPreview();return end
    local duration=pb.data.duration or (pb.data.frames[#pb.data.frames] and pb.data.frames[#pb.data.frames].t) or 0
    if duration<=0 then stopPreview();return end
    pb.elapsed=os.clock()-pb.start
    if pb.elapsed>duration then
        if not pb.loop then stopPreview();return end
        pb.start=os.clock();pb.elapsed=0;pb.frameIndex=1;pb.eventIndex=1
        for _,x in pairs(pb.effects)do if x.folder then x.folder:Destroy()else for _,p in ipairs(x.parts or {})do p:Destroy()end end end
        pb.effects={}
    end
    if pb.vfx then
        while pb.eventIndex<=#(pb.data.vfx or {}) and pb.data.vfx[pb.eventIndex].t<=pb.elapsed do
            Core.runVfxEvent(pb,pb.data.vfx[pb.eventIndex]);pb.eventIndex=pb.eventIndex+1
        end
        Core.moveVfx(pb)
        for _,effect in pairs(pb.effects)do if effect.nodes then Group.codec.sample(effect,pb.elapsed)end end
    end
    if pb.anim then Core.previewPose(pb) end
end

