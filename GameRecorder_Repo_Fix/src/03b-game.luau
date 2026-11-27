-- Game Recorder v7.1.5: F3 coordinates original motion, grouped VFX, highlights, selected
-- actor Inspector, camera, HUD visibility, audio, and replicated state changes.
-- All data is client-observed. It does not read script source, closures or remotes.
local GameRec={}
local GameLighting=game:GetService('Lighting')
local GameSoundService=game:GetService('SoundService')
local function gameValue(value)
    local t=typeof(value)
    if t=='string' then return value:sub(1,140) end
    if t=='number' or t=='boolean' then return value end
    if t=='Vector3' then return Core.vec3(value) end
    if t=='Color3' then return Core.rgb(value) end
    if t=='EnumItem' then return tostring(value) end
    return nil
end
local function shortPath(obj)
    local ok,path=pcall(function()return obj:GetFullName()end)
    return ok and tostring(path):sub(1,220) or tostring(obj.Name):sub(1,120)
end
local function addGameEvent(t,kind,payload,ts)
    if not t.game then return end
    if payload and payload.actorId and t.inspectActiveIDs and not t.inspectActiveIDs[payload.actorId]then return end
    Core.appendEvent(t,kind,payload,ts or r(math.max(0,os.clock()-t.start)))
end
local function watchGameConnection(t,conn)
    if #t.gameConns<CFG.GAME_MAX_WATCH_CONNECTIONS then
        t.gameConns[#t.gameConns+1]=conn
        return true
    end
    conn:Disconnect()
    t.game.droppedWatches+=1
    return false
end
local function watchAttributes(t,obj,ownerId)
    if not obj or not obj.Parent then return end
    if t.gameWatched[obj] then return end
    t.gameWatched[obj]=true
    watchGameConnection(t,obj.AttributeChanged:Connect(function(name)
        local value=gameValue(obj:GetAttribute(name))
        if value~=nil then
            addGameEvent(t,'GAME_ATTRIBUTE_CHANGED',{actorId=ownerId,path=shortPath(obj),attribute=tostring(name):sub(1,90),value=value})
        end
    end))
end
local function watchValue(t,obj,ownerId)
    if not obj:IsA('ValueBase') or t.gameWatched[obj] then return end
    t.gameWatched[obj]=true
    local function snapshot()
        local ok,val=pcall(function()return obj.Value end)
        return ok and gameValue(val) or nil
    end
    local initial=snapshot()
    if initial~=nil then
        addGameEvent(t,'GAME_REPLICATED_VALUE',{actorId=ownerId,path=shortPath(obj),name=tostring(obj.Name):sub(1,90),value=initial})
    end
    watchGameConnection(t,obj.Changed:Connect(function()
        local val=snapshot()
        if val~=nil then
            addGameEvent(t,'GAME_VALUE_CHANGED',{actorId=ownerId,path=shortPath(obj),name=tostring(obj.Name):sub(1,90),value=val})
        end
    end))
end
local function watchSound(t,obj)
    if not obj:IsA('Sound') or t.gameWatched[obj] then return end
    t.gameWatched[obj]=true
    local path=shortPath(obj)
    local id=obj.SoundId
    local function soundEvent(event)
        addGameEvent(t,event,{path=path,soundId=id,volume=r(obj.Volume),playbackSpeed=r(obj.PlaybackSpeed),timePosition=r(obj.TimePosition)})
    end
    if obj.IsPlaying then soundEvent('GAME_SOUND_PLAYING_INITIAL') end
    watchGameConnection(t,obj.Played:Connect(function()soundEvent('GAME_SOUND_PLAY')end))
    watchGameConnection(t,obj.Ended:Connect(function()soundEvent('GAME_SOUND_END')end))
    watchGameConnection(t,obj.Stopped:Connect(function()soundEvent('GAME_SOUND_STOP')end))
end
-- Highlights have their own F3 stream. Grouped VFX excludes Highlight objects,
-- and generic instance-added events do not capture their visual appearance.
local HIGHLIGHT_PROPERTIES={Enabled=true,FillColor=true,FillTransparency=true,
    OutlineColor=true,OutlineTransparency=true,DepthMode=true,Adornee=true}
local function highlightTarget(obj)
    local ok,target=pcall(function()return obj.Adornee end)
    if ok and target then return target end
    return obj.Parent
end
local function highlightOwner(t,obj)
    local target=highlightTarget(obj)
    for _,entry in ipairs(t.inspectActors or {})do
        local model=entry.identity.model
        if obj:IsDescendantOf(model) or (target and (target==model or target:IsDescendantOf(model)))then
            return entry.identity.id
        end
    end
    return nil
end
local function highlightInRange(t,obj)
    local target=highlightTarget(obj)
    if not target then return false end
    if highlightOwner(t,obj) then return true end
    -- Highlight.Adornee can point at a model or part while the Highlight itself
    -- resides in PlayerGui/ReplicatedStorage; use the effective target, not the parent.
    local part=nil
    local current=target
    for _=1,9 do
        if current:IsA('BasePart')then part=current;break end
        if current:IsA('Model')then
            part=current.PrimaryPart or current:FindFirstChildWhichIsA('BasePart',true)
            if part then break end
        end
        current=current.Parent
        if not current then break end
    end
    return part~=nil and part:IsDescendantOf(workspace) and
        (part.Position-t.rigObj.root.Position).Magnitude<=CFG.GAME_RADIUS
end
local function highlightData(t,obj,id)
    local target=highlightTarget(obj)
    local ok,depth=pcall(function()return obj.DepthMode.Name end)
    return {id=id,name=tostring(obj.Name):sub(1,90),path=shortPath(obj),
        actorId=highlightOwner(t,obj),adorneePath=target and shortPath(target) or nil,
        adorneeClass=target and target.ClassName or nil,
        adorneeExplicit=obj.Adornee~=nil,
        enabled=obj.Enabled,fillColor=Core.rgb(obj.FillColor),
        fillTransparency=r(obj.FillTransparency),outlineColor=Core.rgb(obj.OutlineColor),
        outlineTransparency=r(obj.OutlineTransparency),
        depthMode=ok and depth or tostring(obj.DepthMode)}
end
local function recordHighlight(t,obj,state,op,prop)
    if #t.game.highlights>=CFG.GAME_MAX_HIGHLIGHT_EVENTS then
        t.game.droppedHighlightEvents+=1;t.game.truncatedHighlights=true
        return
    end
    local ts=r(math.max(0,os.clock()-t.start))
    local payload=highlightData(t,obj,state.id)
    payload.t=ts;payload.op=op
    if prop then payload.property=prop end
    t.game.highlights[#t.game.highlights+1]=payload
    addGameEvent(t,'GAME_HIGHLIGHT_'..string.upper(op),payload,ts)
end
function Core.gameHighlightObserve(t,obj,action)
    if not t or not t.game or not obj or not obj:IsA('Highlight') then return end
    local state=t.gameHighlightTracked[obj]
    if action=='remove' then
        if state and state.active then
            recordHighlight(t,obj,state,'remove')
            state.active=false
        end
        return
    end
    if not state then
        if t.game.highlightCount>=CFG.GAME_MAX_HIGHLIGHTS then
            t.game.droppedHighlights+=1;t.game.truncatedHighlights=true
            return
        end
        t.game.highlightCount+=1
        state={id='highlight-'..tostring(t.game.highlightCount),active=false}
        t.gameHighlightTracked[obj]=state
        local highlightWatch=obj.Changed:Connect(function(prop)
            if not HIGHLIGHT_PROPERTIES[prop] then return end
            local current=t.gameHighlightTracked and t.gameHighlightTracked[obj]
            if not current then return end
            local relevant=highlightInRange(t,obj)
            if current.active and not relevant then
                recordHighlight(t,obj,current,'remove','out_of_range')
                current.active=false
            elseif not current.active and relevant then
                current.active=true
                recordHighlight(t,obj,current,'add',prop)
            elseif relevant then
                recordHighlight(t,obj,current,'changed',prop)
            end
        end)
        -- Keep Highlight watchers separate from ValueBase/audio observers, so
        -- crowded combat scenes don't consume the entire Highlight budget.
        if #t.gameHighlightConns<CFG.GAME_MAX_HIGHLIGHTS then
            t.gameHighlightConns[#t.gameHighlightConns+1]=highlightWatch
        else
            highlightWatch:Disconnect()
            t.game.droppedHighlightWatches+=1
        end
    end
    if not state.active and highlightInRange(t,obj) then
        state.active=true
        recordHighlight(t,obj,state,action=='initial' and 'initial' or 'add')
    end
end
local function primeHighlights(t)
    -- Budgeted discovery: selected models, PlayerGui, and nearby part hierarchies.
    -- No unconditional workspace:GetDescendants() traversal.
    local examined=0
    local visited=setmetatable({},{__mode='k'})
    local function offer(obj)
        if examined>=CFG.GAME_MAX_HIGHLIGHT_SCAN or visited[obj]then return end
        visited[obj]=true;examined+=1
        if obj:IsA('Highlight')then Core.gameHighlightObserve(t,obj,'initial')end
    end
    for _,entry in ipairs(t.inspectActors or {})do
        for _,obj in ipairs(entry.identity.model:GetDescendants())do
            if obj:IsA('Highlight')then offer(obj)end
            if examined>=CFG.GAME_MAX_HIGHLIGHT_SCAN then break end
        end
    end
    for _,obj in ipairs(playerGui:GetDescendants())do
        if obj:IsA('Highlight')then offer(obj)end
        if examined>=CFG.GAME_MAX_HIGHLIGHT_SCAN then break end
    end
    -- A Highlight may be parented to a nearby part, its Model, or an Effects folder.
    local params=OverlapParams.new();params.MaxParts=220
    local ok,parts=pcall(function()
        return workspace:GetPartBoundsInRadius(t.rigObj.root.Position,CFG.GAME_RADIUS,params)
    end)
    if ok then
        for _,part in ipairs(parts)do
            local current=part
            for _=1,4 do
                if not current or current==workspace then break end
                for _,child in ipairs(current:GetChildren())do
                    if child:IsA('Highlight')then offer(child) end
                end
                current=current.Parent
            end
            if examined>=CFG.GAME_MAX_HIGHLIGHT_SCAN then break end
        end
    end
    for _,obj in ipairs(workspace:GetChildren())do
        if obj:IsA('Highlight')then offer(obj)end
        -- Pools often keep Highlights under Workspace.Effects/Highlights.
        -- Only visit a couple of levels of known FX containers, not the map.
        local label=obj.Name:lower()
        if label=='effects' or label=='vfx' or label=='highlights' or label=='fx' or label=='clienteffects' then
            for _,child in ipairs(obj:GetChildren())do
                if child:IsA('Highlight')then offer(child)end
                if child:IsA('Folder') or child:IsA('Model')then
                    for _,nested in ipairs(child:GetChildren())do
                        if nested:IsA('Highlight')then offer(nested)end
                    end
                end
                if examined>=CFG.GAME_MAX_HIGHLIGHT_SCAN then break end
            end
        end
        if examined>=CFG.GAME_MAX_HIGHLIGHT_SCAN then break end
    end
    t.game.highlightScanCount=examined
end
local function relevantGameNode(obj)
    return obj:IsA('Sound') or obj:IsA('Animation') or obj:IsA('ValueBase')
        or Core.isVfx(obj) or obj:IsA('Beam') or obj:IsA('Trail')
        or obj:IsA('Highlight') or obj:IsA('RemoteEvent') or obj:IsA('RemoteFunction')
end
function Core.gameObserveInstance(t,obj,action,area)
    if not t or not t.game or not obj or not relevantGameNode(obj) then return end
    if obj:IsA('Highlight') then Core.gameHighlightObserve(t,obj,action) end
    local ownerId=nil
    for _,entry in ipairs(t.inspectActors or {})do
        if obj:IsDescendantOf(entry.identity.model) then ownerId=entry.identity.id;break end
    end
    -- Workspace discoveries are limited to the local scene or selected actor models.
    -- ReplicatedStorage is name/class metadata only (no remote calls or payloads).
    if area~='ReplicatedStorage' and not ownerId then
        local carrier=obj
        local located=false
        for _=1,9 do
            if not carrier then break end
            if carrier:IsA('BasePart') then
                located=(carrier.Position-t.rigObj.root.Position).Magnitude<=CFG.GAME_RADIUS
                break
            end
            if carrier:IsA('Attachment') then
                local ok,pos=pcall(function()return carrier.WorldPosition end)
                if ok then located=(pos-t.rigObj.root.Position).Magnitude<=CFG.GAME_RADIUS;break end
            end
            carrier=carrier.Parent
        end
        if not located then return end
    end
    -- Data about client-visible runtime objects, not source or internal execution.
    addGameEvent(t,action=='remove' and 'GAME_INSTANCE_REMOVED' or 'GAME_INSTANCE_ADDED',{
        area=area or 'Workspace',actorId=ownerId,path=shortPath(obj),class=obj.ClassName,name=tostring(obj.Name):sub(1,100)
    })
    if action=='remove' then return end
    if obj:IsA('Sound')then watchSound(t,obj)end
    if ownerId and obj:IsA('ValueBase')then watchValue(t,obj,ownerId)end
end
local function uiSummary()
    local entries={}
    local children=playerGui:GetChildren()
    for _,obj in ipairs(children)do
        if #entries>=CFG.GAME_MAX_GUI then break end
        if obj:IsA('ScreenGui') and obj.Name~=CFG.GUI then
            entries[#entries+1]={name=tostring(obj.Name):sub(1,80),enabled=obj.Enabled,displayOrder=obj.DisplayOrder}
        end
    end
    table.sort(entries,function(a,b)return a.name<b.name end)
    -- Never capture text from chat boxes, DMs, passwords or user-entered UI.
    return entries
end
function Core.gameWatchActor(t,entry)
 if entry.gameWatchReady then return end
 entry.gameWatchReady=true
 local watched=0
        local a=entry.identity
        watchAttributes(t,a.model,a.id)
        watchAttributes(t,a.hum,a.id)
        watchAttributes(t,a.root,a.id)
        watchGameConnection(t,a.hum.StateChanged:Connect(function(old,new)
            addGameEvent(t,'GAME_ACTOR_HUMANOID_STATE',{actorId=a.id,old=tostring(old),new=tostring(new)})
        end))
        if entry.animator then
            watchGameConnection(t,entry.animator.AnimationPlayed:Connect(function(track)
                local ok,anim=pcall(function()return track.Animation end)
                addGameEvent(t,'GAME_ANIMATION_PLAYED',{actorId=a.id,animationId=ok and anim and anim.AnimationId or nil,
                    speed=r(track.Speed),priority=tostring(track.Priority)})
            end))
        end
        local ok,desc=pcall(function()return a.model:GetDescendants()end)
        if ok then
            for _,obj in ipairs(desc)do
                if watched>=CFG.GAME_MAX_INITIAL_OBJECTS then break end
                if obj:IsA('ValueBase')then watchValue(t,obj,a.id);watched+=1
                elseif obj:IsA('Sound')then watchSound(t,obj);watched+=1 end
            end
        end
end
function Core.gameBegin(t)
    t.game={captureHz=CFG.GAME_SAMPLE_HZ,frames={},maxFrames=CFG.GAME_MAX_FRAMES,
        maxEvents=CFG.GAME_MAX_EVENTS,maxVfxEvents=CFG.GAME_MAX_VFX_EVENTS,
        highlights={},highlightCount=0,droppedHighlights=0,droppedHighlightEvents=0,
        droppedHighlightWatches=0,
        maxHighlights=CFG.GAME_MAX_HIGHLIGHTS,maxHighlightEvents=CFG.GAME_MAX_HIGHLIGHT_EVENTS,
        truncatedHighlights=false,droppedWatches=0,truncated=false,
        placeId=game.PlaceId,gameId=game.GameId,
        caveat='Only client-visible state is observed. Does not reveal server scripts, local script internals, private closures, remote payloads, or authoritative combat decisions.'}
    t.gameConns={};t.gameWatched=setmetatable({},{__mode='k'})
    t.gameHighlightTracked=setmetatable({},{__mode='k'})
    t.gameHighlightConns={}
    t.nextGame=0;t.gameVFXLimit=CFG.GAME_MAX_VFX_EVENTS
    for _,entry in ipairs(t.inspectActors or {})do Core.gameWatchActor(t,entry)end
    -- Sounds placed in SoundService are audible to the client yet don't have an actor parent.
    local n=0
    for _,obj in ipairs(GameSoundService:GetDescendants())do
        if n>=CFG.GAME_MAX_GLOBAL_SOUNDS then break end
        if obj:IsA('Sound')then watchSound(t,obj);n+=1 end
    end
    return true
end
function Core.gamePrime(t)
    -- F3-specific Highlight state, including effects that predate recording.
    primeHighlights(t)
    -- The regular world index may still be warming. Seed effects on chosen
    -- actors immediately, without doing a new whole-world recursive scan.
    local added=0
    for _,entry in ipairs(t.inspectActors or {})do
        local ok,desc=pcall(function()return entry.identity.model:GetDescendants()end)
        if ok then
            for _,obj in ipairs(desc)do
                if added>=CFG.GAME_MAX_INITIAL_OBJECTS then break end
                if Core.isVfx(obj) or obj:IsA('Beam') or obj:IsA('Trail')then
                    Group.observe(obj,true)
                    added+=1
                end
            end
        end
    end
    Core.gameSample(t,0)
end
function Core.gameSample(t,ts)
    if not t.game then return end
    if #t.game.frames>=CFG.GAME_MAX_FRAMES then t.game.truncated=true;return end
    local cam=workspace.CurrentCamera
    local frame={t=r(ts),screenGuis=uiSummary(),gravity=r(workspace.Gravity),
        lighting={clockTime=r(GameLighting.ClockTime),brightness=r(GameLighting.Brightness),fogEnd=r(GameLighting.FogEnd)}}
    if cam then
        frame.camera={cframe=Core.cft(cam.CFrame),fov=r(cam.FieldOfView),type=tostring(cam.CameraType),
            subject=cam.CameraSubject and tostring(cam.CameraSubject.Name):sub(1,80) or nil}
    end
    local root=t.rigObj.root
    if root and root.Parent then
        frame.self={position=Core.vec3(root.Position),velocity=Core.vec3(root.AssemblyLinearVelocity),
            look=Core.vec3(root.CFrame.LookVector),health=r(t.rigObj.hum.Health),walkSpeed=r(t.rigObj.hum.WalkSpeed)}
    end
    local status={}
    for _,entry in ipairs(t.inspectActors or {})do
        local a=entry.identity
        if a.model.Parent and a.hum.Parent then
            local ok,state=pcall(Core.controlSnapshot,{char=a.model,hum=a.hum})
            if ok and state then
                status[#status+1]={id=a.id,reportedStun=state.stunReported,restricted=state.restricted,
                    flags=state.flags,reasons=state.reasons,humanoidState=state.humanoidState}
            end
        end
    end
    frame.combat=status
    t.game.frames[#t.game.frames+1]=frame
end
function Core.gameFinish(t)
    for _,conn in ipairs(t.gameConns or {})do pcall(function()conn:Disconnect()end)end
    for _,conn in ipairs(t.gameHighlightConns or {})do pcall(function()conn:Disconnect()end)end
    t.gameConns=nil;t.gameWatched=nil;t.gameHighlightTracked=nil;t.gameHighlightConns=nil
    if t.game then
        t.game.frameCount=#t.game.frames
        t.game.highlightEventCount=#t.game.highlights
    end
end
