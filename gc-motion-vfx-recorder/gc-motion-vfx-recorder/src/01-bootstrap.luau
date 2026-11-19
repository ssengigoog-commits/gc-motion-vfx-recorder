--[[
 GRAND CLOVER MOTION / GROUPED VFX RECORDER V7.0
 For your own or authorized Roblox client sessions. No remotes or uploads.
 F6 = Motion Start/Stop | F8 = VFX Start/Stop | F7 = Show/Hide
 Motion: evaluated joints, root/jump/camera motion, F/mouse/Space inputs,
 actual velocity and animation-track timing. Playback uses a separate ghost.
 VFX: bounded whole visual hierarchies with parts, meshes, attachments,
 particles, beams, trails, decals and lights. Scripts/welds are excluded.
 Platform limits remain: server-only objects, asset permissions, CSG geometry
 and true Emit(n) counts cannot be recovered. Estimated bursts are labeled.
 Synchronized ANIM+VFX, selected actors, visibility and measured stud intervals. Bounded capture; no idle scene index.
]]
local Core={} -- shared helpers use one local slot
Core.RECORDER_VERSION='7.0'
Core.RECORDER_BUILD='2026-11-19-session-telemetry-01'
local Players = game:GetService('Players')
local UIS = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local HttpService = game:GetService('HttpService')
local localPlayer = assert(Players.LocalPlayer, 'Must run on client')
local playerGui = localPlayer:WaitForChild('PlayerGui')
local CFG = {
    FPS=30, VFX_FPS=20, UI_HZ=5, MAX_SECONDS=30, VFX_RADIUS=80, PREVIEW_DISTANCE=9, PREVIEW_HEIGHT=4,
    MAX_GROUPS=96, MAX_GROUP_NODES=192, SCAN_BUDGET=96, MAX_SCAN_NODES=4096, MAX_WATCHED=768,
    MAX_ACTORS=4, ACTOR_RADIUS=60, MAX_QUERY_PARTS=256, MAX_TOTAL_FRAMES=7200, MAX_MOTION_EVENTS=8000, INDEX_SECONDS=.0015,
    VFX_CONTAINER_NAMES={"Effects","VFX","FX","ClientEffects","WorldFX","Debris"},
    MANIFEST='GC_BAKER_HISTORY_v7.json', PREFIX='GC_BAKER_v7_',
    GUI='GC_MotionVFX_Baker_v7', MAX_VFX_EVENTS=12000,
}
Core.Settings={localActor=true,npcs=false,otherPlayers=false,actorNames=''}
local env = _G
if type(getgenv)=='function' then
    local ok,g=pcall(getgenv)
    if ok and type(g)=='table' then env=g end
end
if type(env.GC_MotionBaker_Shutdown)=='function' then pcall(env.GC_MotionBaker_Shutdown) end

 function Core.safePath(path)
 if type(path)~='string'or path:find('..',1,true)or path:find('[\\/:]')then return false end
 return path:match('^GC_BAKER_v[4567]_[%w_]+%.json$')~=nil or path:match('^GC_BAKER_v[4567]_[%w_]+%.lua$')~=nil or path:match('^GC_BAKER_v[4567]_[%w_]+%.txt$')~=nil or path:match('^GC_BAKER_HISTORY_v[4567]%.json$')~=nil
end
 function Core.safeWrite(path,s) return Core.safePath(path)and type(writefile)=='function' and pcall(writefile,path,s) or false end
 function Core.safeRead(path)
    if not Core.safePath(path)or type(readfile)~='function' then return nil end
    local ok,s=pcall(readfile,path); return ok and type(s)=='string' and s or nil
end
 function Core.safeDelete(path) return Core.safePath(path)and type(delfile)=='function' and pcall(delfile,path) or false end
 function Core.safeCopy(s)
    local fn=(type(setclipboard)=='function' and setclipboard) or (type(toclipboard)=='function' and toclipboard)
    return fn and pcall(fn,s) or false
end
local function r(n) return math.floor(n*1000000+0.5)/1000000 end
 function Core.cft(c) local v={c:GetComponents()}; for i=1,#v do v[i]=r(v[i]) end; return v end
 function Core.cff(v) if type(v)~='table' or #v~=12 then return CFrame.new() end; return CFrame.new(table.unpack(v)) end
 function Core.vec3(v) return {r(v.X),r(v.Y),r(v.Z)} end
 function Core.rgb(v) return {r(v.R),r(v.G),r(v.B)} end
 function Core.toVec3(a) return Vector3.new(a[1],a[2],a[3]) end
 function Core.fromRGB(a) return Color3.new(a[1],a[2],a[3]) end
local function pack(v)
    local tp=typeof(v)
    if tp=='CFrame' then return {k='CFrame',v=Core.cft(v)} end
    if tp=='Color3' then return {k='Color3',v=Core.rgb(v)} end
    if tp=='Vector2' then return {k='Vector2',v={r(v.X),r(v.Y)}} end
    if tp=='Vector3' then return {k='Vector3',v=Core.vec3(v)} end
    if tp=='UDim'then return {k='UDim',v={r(v.Scale),r(v.Offset)}}end
    if tp=='UDim2'then return {k='UDim2',v={r(v.X.Scale),r(v.X.Offset),r(v.Y.Scale),r(v.Y.Offset)}}end
    if tp=='Rect'then return {k='Rect',v={r(v.Min.X),r(v.Min.Y),r(v.Max.X),r(v.Max.Y)}}end
    if tp=='NumberRange' then return {k='NumberRange',v={r(v.Min),r(v.Max)}} end
    if tp=='NumberSequence' then
        local a={}; for _,x in ipairs(v.Keypoints) do a[#a+1]={r(x.Time),r(x.Value),r(x.Envelope)} end
        return {k='NumberSequence',v=a}
    end
    if tp=='ColorSequence' then
        local a={}; for _,x in ipairs(v.Keypoints) do a[#a+1]={r(x.Time),Core.rgb(x.Value)} end
        return {k='ColorSequence',v=a}
    end
    if tp=='EnumItem' then return {k='Enum',v={tostring(v.EnumType):gsub('^Enum%.',''),v.Name}} end
    if tp=='number'then return v==v and math.abs(v)<math.huge and v or nil end
    if tp=='boolean'or tp=='string'then return v end
    return nil
end
Core.ENUM_TYPES={Material='Material',MeshType='MeshType',Face='NormalId',EmissionDirection='NormalId',Orientation='ParticleOrientation',ShapeInOut='ParticleEmitterShapeInOut',ShapeStyle='ParticleEmitterShapeStyle',FlipbookLayout='ParticleFlipbookLayout',FlipbookMode='ParticleFlipbookMode',TextureMode='TextureMode',AlphaMode='AlphaMode',SizingMode='SurfaceGuiSizingMode',ScaleType='ScaleType',ResampleMode='ResamplerMode',ZIndexBehavior='ZIndexBehavior',SizeConstraint='SizeConstraint',AutomaticSize='AutomaticSize',BorderMode='BorderMode',ApplyStrokeMode='ApplyStrokeMode',LineJoinMode='LineJoinMode',AspectType='AspectType',DominantAxis='DominantAxis'}
 function Core.enumValue(value,property,className)
 local a=value.v or {};local family=a[1]or a['1'];local name=a[2]or a['2']
 if not family then family=property=='Shape'and (className=='ParticleEmitter'and 'ParticleEmitterShape'or 'PartType')or Core.ENUM_TYPES[property]end
 if type(family)~='string'or type(name)~='string'then return nil end
 local ok,item=pcall(function()return Enum[family][name]end);return ok and item or nil
end
 function Core.unpackProperty(v,property,className)
    if type(v)~='table' or type(v.k)~='string' then return v end
    local a=v.v
    if v.k=='CFrame' then return Core.cff(a) end
    if v.k=='Color3' then return Core.fromRGB(a) end
    if v.k=='Vector2' then return Vector2.new(a[1],a[2]) end
    if v.k=='Vector3' then return Core.toVec3(a) end
    if v.k=='UDim'then return UDim.new(a[1],a[2])end
    if v.k=='UDim2'then return UDim2.new(a[1],a[2],a[3],a[4])end
    if v.k=='Rect'then return Rect.new(a[1],a[2],a[3],a[4])end
    if v.k=='NumberRange' then return NumberRange.new(a[1],a[2]) end
    if v.k=='NumberSequence' then
        local k={}; for _,x in ipairs(a) do k[#k+1]=NumberSequenceKeypoint.new(x[1],x[2],x[3]) end
        return NumberSequence.new(k)
    end
    if v.k=='ColorSequence' then
        local k={}; for _,x in ipairs(a) do k[#k+1]=ColorSequenceKeypoint.new(x[1],Core.fromRGB(x[2])) end
        return ColorSequence.new(k)
    end
    if v.k=='Enum'then return Core.enumValue(v,property,className)end
    return nil
end
local PROPERTIES = {
    ParticleEmitter={'Texture','Enabled','Rate','Lifetime','Speed','Drag','Acceleration','SpreadAngle','EmissionDirection',
        'Rotation','RotSpeed','Color','Transparency','Size','LightEmission','LightInfluence','Orientation',
        'ZOffset','VelocityInheritance','LockedToPart','TimeScale','Shape','ShapeInOut','ShapeStyle','Squash',
        'FlipbookLayout','FlipbookMode','FlipbookFramerate','FlipbookBlendFrames','FlipbookStartRandom','ShapePartial','Brightness'},
    Beam={'Texture','TextureLength','TextureMode','Segments','Width0','Width1','CurveSize0','CurveSize1',
        'Color','Transparency','LightEmission','LightInfluence','FaceCamera','ZOffset','Brightness','Enabled'},
    Trail={'Texture','TextureLength','TextureMode','Lifetime','MinLength','Color','Transparency','WidthScale',
        'LightEmission','LightInfluence','FaceCamera','Brightness','Enabled'},
}
 function Core.isVfx(obj) return obj:IsA('ParticleEmitter') or obj:IsA('Beam') or obj:IsA('Trail') or obj:IsA('Smoke') or obj:IsA('Fire') or obj:IsA('Sparkles') end
 function Core.getProps(obj)
    local ret={}; for _,p in ipairs(PROPERTIES[obj.ClassName] or {}) do
        local ok,val=pcall(function() return obj[p] end)
        if ok then local out=pack(val); if out~=nil then ret[p]=out end end
    end
    return ret
end
 function Core.applyProps(obj,props)
    for k,v in pairs(props or {}) do
        local unpacked=Core.unpackProperty(v,k,obj.ClassName)
        if unpacked~=nil then pcall(function() obj[k]=unpacked end) end
    end
end
 function Core.effectFrames(obj)
    if obj:IsA('ParticleEmitter') then
        local parent=obj.Parent
        if parent and parent:IsA('Attachment') then return {parent.WorldCFrame} end
        if parent and parent:IsA('BasePart') then return {parent.CFrame} end
    elseif obj:IsA('Beam') or obj:IsA('Trail') then
        local a0,a1=obj.Attachment0,obj.Attachment1
        if a0 and a1 then return {a0.WorldCFrame,a1.WorldCFrame} end
    end
    return nil
end
 function Core.effectRelative(obj,rootCF)
    local parts=Core.effectFrames(obj); if not parts then return nil end
    local rel={}; for _,cf in ipairs(parts) do rel[#rel+1]=Core.cft(rootCF:ToObjectSpace(cf)) end
    return rel
end
local KNOWN_RIG={
    R6={'Torso','Head','Right Arm','Left Arm','Right Leg','Left Leg'},
    R15={'LowerTorso','UpperTorso','Head',
        'LeftUpperArm','LeftLowerArm','LeftHand','RightUpperArm','RightLowerArm','RightHand',
        'LeftUpperLeg','LeftLowerLeg','LeftFoot','RightUpperLeg','RightLowerLeg','RightFoot'},
}
 function Core.jointData(obj,char)
    local p0,p1,b0,b1,kind
    if obj:IsA('AnimationConstraint') then
        local a,b=obj.Attachment0,obj.Attachment1
        if not a or not b then return nil end
        p0,p1,b0,b1=a.Parent,b.Parent,a.CFrame,b.CFrame; kind='AnimationConstraint'
    elseif obj:IsA('Motor6D') then
        p0,p1,b0,b1=obj.Part0,obj.Part1,obj.C0,obj.C1; kind='Motor6D'
    else return nil end
    if not p0 or not p1 or not p0:IsA('BasePart') or not p1:IsA('BasePart')
        or not p0:IsDescendantOf(char) or not p1:IsDescendantOf(char) then return nil end
    return {obj=obj,parent=p0.Name,child=p1.Name,base0=b0,base1=b1,kind=kind}
end
 function Core.getRig(char)
    char=char or localPlayer.Character
    if not char then return nil,'Character not spawned' end
    local hum=char:FindFirstChildOfClass('Humanoid')
    if not hum then return nil,'Humanoid not found' end
    local animator=hum:FindFirstChildOfClass('Animator')
    if not animator then return nil,'Animator not found' end
    local root=char:FindFirstChild('HumanoidRootPart')
    if not root then return nil,'HumanoidRootPart not found' end
    local rig=(char:FindFirstChild('Torso')and char:FindFirstChild('Right Arm'))and 'R6' or (hum.RigType==Enum.HumanoidRigType.R15 and 'R15' or 'R6')
    local chosen={}
    for _,obj in ipairs(char:GetDescendants()) do
        if obj:IsA('Motor6D') or obj:IsA('AnimationConstraint') then
            local j=Core.jointData(obj,char)
            if j and (not chosen[j.child] or j.kind=='AnimationConstraint') then chosen[j.child]=j end
        end
    end
    local channels={}
    for _,name in ipairs(KNOWN_RIG[rig]) do if chosen[name] then channels[#channels+1]=chosen[name] end end
    if #channels<(rig=='R15' and 6 or 3) then return nil,'Insufficient R6/R15 joints' end
    return {char=char,hum=hum,root=root,animator=animator,rig=rig,channels=channels}
end

