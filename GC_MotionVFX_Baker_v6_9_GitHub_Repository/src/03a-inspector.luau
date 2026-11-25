-- Combat Inspector v6.9: additive, client-observed actor/timeline captures.
-- No injection, server script access, source reading, remotes, or player control.
-- The existing motion, grouped VFX, replay, and Studio export code is unchanged.
local Inspector={}
local inspectIDs=setmetatable({},{__mode='k'})
local inspectIDCounter=0
local inspectSelected=setmetatable({},{__mode='k'})

local function actorID(model)
    if not inspectIDs[model] then
        inspectIDCounter+=1
        inspectIDs[model]='actor-'..tostring(inspectIDCounter)
    end
    return inspectIDs[model]
end
local function modelData(model)
    if not model or not model.Parent then return nil end
    local hum=model:FindFirstChildOfClass('Humanoid')
    local root=model:FindFirstChild('HumanoidRootPart') or model.PrimaryPart
    if not hum or not root or not root:IsA('BasePart') then return nil end
    local player=Players:GetPlayerFromCharacter(model)
    return {model=model,hum=hum,root=root,id=actorID(model),
        label=player and player.Name or model.Name,
        role=player and (player==localPlayer and 'self' or 'player') or 'npc',
        userId=player and player.UserId or nil}
end
local function selectedCount()
    local n=0;for model,yes in pairs(inspectSelected)do
        if yes and modelData(model)then n+=1 end
    end
    return n
end
function Core.inspectCandidates()
    local selfChar=localPlayer.Character
    local selfRoot=selfChar and selfChar:FindFirstChild('HumanoidRootPart')
    local listed,seen={},{}
    local function offer(model)
        if not model or seen[model] then return end
        seen[model]=true
        local candidate=modelData(model)
        if not candidate then return end
        local distance=selfRoot and (candidate.root.Position-selfRoot.Position).Magnitude or 0
        if candidate.role~='self' and distance>CFG.INSPECT_RADIUS then return end
        candidate.distance=r(distance)
        candidate.selected=inspectSelected[model]==true
        listed[#listed+1]=candidate
    end
    offer(selfChar)
    for _,player in ipairs(Players:GetPlayers())do offer(player.Character) end
    if selfRoot then
        local params=OverlapParams.new()
        params.MaxParts=CFG.INSPECT_QUERY_PARTS
        local ok,parts=pcall(function()
            return workspace:GetPartBoundsInRadius(selfRoot.Position,CFG.INSPECT_RADIUS,params)
        end)
        if ok then
            for _,part in ipairs(parts)do
                local model=part:FindFirstAncestorOfClass('Model')
                -- An accessory or weapon may be nested in another Model.
                for _=1,3 do
                    if not model then break end
                    if model:FindFirstChildOfClass('Humanoid') then offer(model);break end
                    local parent=model.Parent
                    model=(parent and parent:IsA('Model')) and parent or (parent and parent:FindFirstAncestorOfClass('Model'))
                end
                if #listed>=CFG.INSPECT_CHOICES then break end
            end
        end
    end
    table.sort(listed,function(a,b)
        if a.role=='self' then return true end
        if b.role=='self' then return false end
        if a.distance==b.distance then return a.label<b.label end
        return a.distance<b.distance
    end)
    while #listed>CFG.INSPECT_CHOICES do table.remove(listed)end
    return listed
end
function Core.inspectToggle(model)
    local a=modelData(model)
    if not a then return false,'Actor no longer available' end
    if inspectSelected[model]then inspectSelected[model]=nil;return true,'Removed '..a.label end
    if selectedCount()>=CFG.INSPECT_MAX_ACTORS then return false,'Limit: '..CFG.INSPECT_MAX_ACTORS..' actors' end
    inspectSelected[model]=true;return true,'Selected '..a.label
end
function Core.inspectSelectedCount()return selectedCount()end
function Core.inspectBegin(t)
    local chosen={}
    for _,candidate in ipairs(Core.inspectCandidates())do
        if candidate.selected then chosen[#chosen+1]=candidate end
    end
    if #chosen==0 then
        local self=modelData(localPlayer.Character)
        if self then chosen[1]=self end
    end
    if #chosen==0 then return false,'No player/NPC available' end
    t.inspector={sampleHz=CFG.INSPECT_FPS,radius=CFG.INSPECT_RADIUS,
        actors={},frames={},truncated=false,dropped=0,
        caveat='Client-visible observations only; reported stun flags may be deadlines or ambiguous; no server acceptance or hidden code.'}
    t.inspectActors={}
    t.inspectConnections={}
    t.inspectWatched=setmetatable({},{__mode='k'})
    for _,a in ipairs(chosen)do
        local animator=a.hum:FindFirstChildOfClass('Animator')
        local channelList={}
        local ok,objects=pcall(function()return a.model:GetDescendants()end)
        if ok then
            for _,object in ipairs(objects)do
                if #channelList>=CFG.INSPECT_MAX_JOINTS then break end
                if object:IsA('Motor6D') or object:IsA('AnimationConstraint')then
                    local joint=Core.jointData(object,a.model)
                    if joint then channelList[#channelList+1]=joint end
                end
            end
        end
        local metadata={id=a.id,label=a.label,role=a.role,userId=a.userId,rig=tostring(a.hum.RigType),
            joints={}}
        for _,joint in ipairs(channelList)do metadata.joints[#metadata.joints+1]={name=joint.obj.Name,parent=joint.parent,child=joint.child,kind=joint.kind}end
        t.inspector.actors[#t.inspector.actors+1]=metadata
        t.inspectActors[#t.inspectActors+1]={identity=a,metadata=metadata,animator=animator,
            channels=channelList,lastState=nil,lastTrack=nil,alive=true}
        Core.appendEvent(t,'ACTOR_SELECTED',{actor=a.label,role=a.role,id=a.id},0)
    end
    t.nextInspect=0
    return true
end
local function compactTracks(animator)
    local list={}
    if not animator then return list end
    local ok,tracks=pcall(function()return animator:GetPlayingAnimationTracks()end)
    if not ok then return list end
    for _,track in ipairs(tracks)do
        if #list>=CFG.INSPECT_MAX_TRACKS then break end
        local anim=track.Animation
        list[#list+1]={id=anim and anim.AnimationId or '',
            time=r(track.TimePosition or 0),speed=r(track.Speed or 0),
            weight=r(track.WeightCurrent or 0),priority=tostring(track.Priority)}
    end
    return list
end
function Core.inspectSample(t,ts)
    if not t.inspector or #t.inspector.frames>=CFG.INSPECT_MAX_FRAMES then
        if t.inspector then t.inspector.truncated=true;t.inspector.dropped+=1 end
        return
    end
    local sample={t=r(ts),actors={}}
    for _,entry in ipairs(t.inspectActors or {})do
        local a=entry.identity
        if not a.model.Parent or not a.hum.Parent or not a.root.Parent then
            if entry.alive then
                Core.appendEvent(t,'ACTOR_LOST',{actor=a.label,id=a.id},ts)
                entry.alive=false
            end
        else
            if not entry.alive then Core.appendEvent(t,'ACTOR_RETURNED',{actor=a.label,id=a.id},ts);entry.alive=true end
            local state=a.hum:GetState().Name
            local s={id=a.id,pos=Core.vec3(a.root.Position),vel=Core.vec3(a.root.AssemblyLinearVelocity),
                state=state,health=r(a.hum.Health),walkSpeed=r(a.hum.WalkSpeed),
                tracks=compactTracks(entry.animator),joints={}}
            for _,j in ipairs(entry.channels)do
                local p0,p1
                if j.kind=='Motor6D' then p0,p1=j.obj.Part0,j.obj.Part1
                else
                    local a0,a1=j.obj.Attachment0,j.obj.Attachment1
                    p0,p1=a0 and a0.Parent,a1 and a1.Parent
                end
                if p0 and p1 and p0:IsA('BasePart') and p1:IsA('BasePart') then
                    -- Evaluated limb pose, not private Motor6D.Transform.
                    s.joints[#s.joints+1]=Core.cft(p0.CFrame:ToObjectSpace(p1.CFrame))
                end
            end
            if t.nextInspectStatus==nil or ts>=t.nextInspectStatus then
                local ok,control=pcall(Core.controlSnapshot,{char=a.model,hum=a.hum})
                if ok and control then
                    s.combat={flags=control.flags,reasons=control.reasons,restricted=control.restricted,
                        stunReported=control.stunReported,humanoidState=control.humanoidState}
                    local sig=Core.controlSignature(control)
                    if sig~=entry.lastState then
                        entry.lastState=sig
                        Core.appendEvent(t,'COMBAT_STATE_CHANGE',{
                            actor=a.label,id=a.id,state=state,reasons=control.reasons,
                            reportedStun=control.stunReported,flags=control.flags},ts)
                    end
                end
            end
            local signature={}
            for _,tr in ipairs(s.tracks)do signature[#signature+1]=tr.id..':'..tr.speed end
            table.sort(signature)
            local sig=table.concat(signature,'|')
            if sig~=entry.lastTrack then
                entry.lastTrack=sig
                Core.appendEvent(t,'ACTOR_TRACK_CHANGE',{actor=a.label,id=a.id,tracks=s.tracks},ts)
            end
            sample.actors[#sample.actors+1]=s
        end
    end
    t.nextInspectStatus=ts+.2
    t.inspector.frames[#t.inspector.frames+1]=sample
end
function Core.inspectEffect(obj,ts,action)
    local t=recording
    if not t or t.kind~='INSPECT' or not t.inspector then return end
    if #t.events>=CFG.INSPECT_MAX_EVENTS then t.inspector.truncated=true;t.inspector.dropped+=1;return end
    if not (Core.isVfx(obj) or obj:IsA('Sound') or obj:IsA('Highlight') or obj:IsA('PointLight') or obj:IsA('SpotLight')) then return end
    local pos,owner=obj,nil
    for _=1,8 do
        if not pos then break end
        if pos:IsA('BasePart')then break end
        if pos:IsA('Attachment')then
            local ok,wp=pcall(function()return pos.WorldPosition end)
            if ok then
                local origin=t.rigObj.root and t.rigObj.root.Position or t.origin.Position
                if (wp-origin).Magnitude>CFG.INSPECT_RADIUS then return end
            end
        end
        pos=pos.Parent
    end
    local origin=t.rigObj.root and t.rigObj.root.Position or t.origin.Position
    if pos and pos:IsA('BasePart')and (pos.Position-origin).Magnitude>CFG.INSPECT_RADIUS then return end
    if not pos or not pos:IsA('BasePart')then return end
    local ok,path=pcall(function()return obj:GetFullName()end)
    local data={name=tostring(obj.Name):sub(1,100),class=obj.ClassName,
        path=ok and tostring(path):sub(1,230) or obj.Name,source='client-visible'}
    if obj:IsA('ParticleEmitter') then
        data.texture=obj.Texture;data.rate=obj.Rate;data.enabled=obj.Enabled
    elseif obj:IsA('Sound')then
        data.soundId=obj.SoundId;data.playing=obj.Playing;data.volume=obj.Volume
    elseif obj:IsA('Beam')or obj:IsA('Trail')then
        data.texture=obj.Texture;data.enabled=obj.Enabled
    end
    Core.appendEvent(t,action=='remove' and 'EFFECT_REMOVED' or
        (action=='initial' and 'EFFECT_INITIAL' or 'EFFECT_ADDED'),data,ts)
    if action~='remove' and not t.inspectWatched[obj] and
        #t.inspectConnections<CFG.INSPECT_MAX_EFFECT_WATCH then
        local changed=obj.Changed:Connect(function(property)
            if property=='Enabled' or property=='Playing' or property=='Rate' or
                property=='Volume' or property=='PlaybackSpeed' then
                local value
                local okValue,v=pcall(function()return obj[property]end)
                if okValue and (type(v)=='boolean' or type(v)=='number')then value=v end
                Core.appendEvent(t,'EFFECT_PROPERTY',{name=data.name,class=data.class,
                    path=data.path,property=property,value=value},now(t))
            end
        end)
        t.inspectWatched[obj]=changed
        t.inspectConnections[#t.inspectConnections+1]=changed
    end
end
function Core.inspectPrime(t)
    -- Initial capture only for explicitly chosen actor hierarchies, capped.
    for _,entry in ipairs(t.inspectActors or {})do
        local ok,items=pcall(function()return entry.identity.model:GetDescendants()end)
        if ok then
            local budget=0
            for _,obj in ipairs(items)do
                if Core.isVfx(obj) or obj:IsA('Sound') or obj:IsA('Highlight')then
                    Core.inspectEffect(obj,0,'initial')
                    budget+=1
                    if budget>=CFG.INSPECT_MAX_INITIAL_EFFECTS then break end
                end
            end
        end
    end
end
function Core.inspectFinish(t)
    for _,conn in ipairs(t.inspectConnections or {})do pcall(function()conn:Disconnect()end)end
    t.inspectConnections=nil;t.inspectWatched=nil
    t.inspectActors=nil -- Runtime Instances MUST NOT be saved into JSON.
end
