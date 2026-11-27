--[[
 GRAND CLOVER MOTION / VFX / GAME RECORDER V7.1.2
 For your own or authorized Roblox client sessions. No remotes or uploads.
 F6 = Motion Start/Stop | F8 = VFX Start/Stop | F7 = Show/Hide
 Motion: evaluated joints, root/jump/camera motion, F/mouse/Space inputs,
 actual velocity and animation-track timing. Playback uses a separate ghost.
 VFX: bounded whole visual hierarchies with parts, meshes, attachments,
 particles, beams, trails, decals and lights. Scripts/welds are excluded.
 Platform limits remain: server-only objects, asset permissions, CSG geometry
 and true Emit(n) counts cannot be recovered. Estimated bursts are labeled.
 F6/F8 standalone takes, F3 synchronized game take; client-observed only.
]]
local Core={} -- shared helpers use one local slot
Core.RECORDER_VERSION='7.1.2'
Core.RECORDER_BUILD='2026-11-27-auto-radius-01'
local Players = game:GetService('Players')
local UIS = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local HttpService = game:GetService('HttpService')
local localPlayer = assert(Players.LocalPlayer, 'Must run on client')
local playerGui = localPlayer:WaitForChild('PlayerGui')
local CFG = {
    FPS=60, VFX_FPS=60, MAX_SECONDS=120, INCLUDE_NPCS=true, INCLUDE_PLAYERS=true, SETTINGS='GC_BAKER_SETTINGS_v7.json', INSPECT_FPS=10, INSPECT_RADIUS=60,
    INSPECT_MAX_ACTORS=32, INSPECT_MAX_TRACKS=12, INSPECT_MAX_JOINTS=18,
    INSPECT_QUERY_PARTS=512, INSPECT_CHOICES=64, INSPECT_MAX_FRAMES=1200, INSPECT_MAX_EVENTS=6000,
    INSPECT_MAX_EFFECT_WATCH=120, INSPECT_MAX_INITIAL_EFFECTS=48,
    GAME_SAMPLE_HZ=5, GAME_MAX_FRAMES=620, GAME_MAX_EVENTS=12000,
    GAME_MAX_VFX_EVENTS=6000, GAME_MAX_MOTION_FRAMES=7200, GAME_MAX_WATCH_CONNECTIONS=220,
    GAME_MAX_INITIAL_OBJECTS=140, GAME_MAX_GLOBAL_SOUNDS=48, GAME_MAX_GUI=32,
    GAME_MAX_HIGHLIGHTS=160, GAME_MAX_HIGHLIGHT_EVENTS=2400, GAME_MAX_HIGHLIGHT_SCAN=420,
    GAME_VFX_FPS=15, GAME_RADIUS=110, VFX_RADIUS=math.huge, PREVIEW_DISTANCE=9, PREVIEW_HEIGHT=4,
    MAX_GROUPS=512, MAX_GROUP_NODES=512, SCAN_BUDGET=48, INDEX_STEP_SECONDS=0.0015, INDEX_HZ=15, MAX_SCAN_NODES=32768, MAX_WATCHED=1024,
    VFX_CONTAINER_NAMES={"Effects","VFX","FX","ClientEffects","WorldFX","Debris"},
    MANIFEST='GC_BAKER_HISTORY_v7.json', PREFIX='GC_BAKER_v7_',
    GUI='GC_MotionVFX_Baker_v7', MAX_VFX_EVENTS=24000,
}
local env = _G
if type(getgenv)=='function' then
    local ok,g=pcall(getgenv)
    if ok and type(g)=='table' then env=g end
end
if type(env.GC_MotionBaker_Shutdown)=='function' then pcall(env.GC_MotionBaker_Shutdown) end

 function Core.safePath(path)
 if type(path)~='string'or path:find('..',1,true)or path:find('[\\/:]')then return false end
 return path==CFG.SETTINGS or path:match('^GC_BAKER_v[4567]_[%w_]+%.json$')~=nil or path:match('^GC_BAKER_v[4567]_[%w_]+%.lua$')~=nil or path:match('^GC_BAKER_HISTORY_v[4567]%.json$')~=nil
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
 function Core.getRig()
    local char=localPlayer.Character
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

local saved={}; local selected=nil; local recording=nil; local playback=nil

-- Only this allowlisted settings file is read/written; captures remain separate.
function Core.actorRoleEnabled(role,settings)
 settings=settings or {includeNPCs=CFG.INCLUDE_NPCS,includePlayers=CFG.INCLUDE_PLAYERS}
 if role=='self' then return true end
 if role=='npc' then return settings.includeNPCs~=false end
 if role=='player' then return settings.includePlayers~=false end
 return false
end
function Core.actorCaptureSettings()
 return {includeNPCs=CFG.INCLUDE_NPCS,includePlayers=CFG.INCLUDE_PLAYERS}
end
function Core.saveRecorderSettings()
 local settings=Core.actorCaptureSettings();settings.fps=CFG.FPS
 env.GC_RecorderSettings=settings
 local ok,raw=pcall(function()return HttpService:JSONEncode(settings)end)
 return ok and Core.safeWrite(CFG.SETTINGS,raw) or false
end
function Core.setActorCaptureSetting(key,enabled)
 if recording then return false,'Stop recording before changing capture subjects.' end
 if type(enabled)~='boolean' or (key~='includeNPCs'and key~='includePlayers')then return false,'Invalid capture setting' end
 if key=='includeNPCs'then CFG.INCLUDE_NPCS=enabled else CFG.INCLUDE_PLAYERS=enabled end
 Core.saveRecorderSettings()
 return true,'Capture subjects updated for the next Game recording.'
end
do
 local settings=env.GC_RecorderSettings
 local raw=Core.safeRead(CFG.SETTINGS)
 if raw then local ok,value=pcall(function()return HttpService:JSONDecode(raw)end);if ok and type(value)=='table'then settings=value end end
 if type(settings)=='table'then
  if type(settings.includeNPCs)=='boolean'then CFG.INCLUDE_NPCS=settings.includeNPCs end
  if type(settings.includePlayers)=='boolean'then CFG.INCLUDE_PLAYERS=settings.includePlayers end
  if settings.fps==30 or settings.fps==60 then CFG.FPS=settings.fps;CFG.VFX_FPS=settings.fps end
 end
end
local previewGeneration=0
local estimateBurstPreview=true -- Preview-only estimates are labeled; source Emit() counts remain unknown.
local serial=0; local connections={}; local disposed=false; local statusLabel=nil
local libraryFilter='ANIM' -- independent ANIM/VFX recording lists
local setStatus,drawLibrary,drawDetails,stopPreview,stopRecord,loadData
local function conn(c) connections[#connections+1]=c; return c end
local function msg(s,c)
    if statusLabel then statusLabel.Text=s; statusLabel.TextColor3=c or Color3.fromRGB(170,183,195) end
    print('[GC Baker V6] '..s)
end
 function Core.exportJson(x) local ok,v=pcall(HttpService.JSONEncode,HttpService,x); return ok and v or nil end
local function decode(x) local ok,v=pcall(HttpService.JSONDecode,HttpService,x); return ok and v or nil end
 function Core.saveHistory()
    local out={version=6,takes={}}
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
    if type(take.id)=='string'and not seen[take.id]and Core.safePath(take.path)then
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
    -- Keep at most one disk-backed decoded take. Unsaved takes stay in memory.
    for _,other in ipairs(saved) do if other~=t and other.saved then other.data=nil end end
    local d=decode(s); if d and (d.version==6 or d.version==5 or d.version==4) then t.data=d; return d end
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
    if (t.kind=='INSPECT' or t.kind=='GAME') and t.inspector and
        #t.events >= (t.kind=='GAME' and CFG.GAME_MAX_EVENTS or CFG.INSPECT_MAX_EVENTS) then
        t.inspector.truncated=true;t.inspector.dropped+=1
        if t.game then t.game.truncated=true end
        return
    end
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
   t.controlState=state;t.nextControlPoll=ts+.05
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
    if t.keys.Shift and moving(t.keys) then
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


local Group=(function()


local Codec={}
local MESHES={}
local meshCount=0
local VISUAL={Model=true,Folder=true,Part=true,MeshPart=true,WedgePart=true,CornerWedgePart=true,UnionOperation=true,Attachment=true,Smoke=true,Fire=true,Sparkles=true,SpecialMesh=true,BlockMesh=true,CylinderMesh=true,ParticleEmitter=true,Beam=true,Trail=true,Decal=true,Texture=true,SurfaceAppearance=true,PointLight=true,SpotLight=true,SurfaceLight=true,SurfaceGui=true,BillboardGui=true,Frame=true,CanvasGroup=true,ImageLabel=true,ImageButton=true,UICorner=true,UIStroke=true,UIGradient=true,UIAspectRatioConstraint=true,UIScale=true}
local function cfv(v)return v and CFrame.new(table.unpack(v)) or CFrame.identity end
local ENUM_TYPES={Material='Material',MeshType='MeshType',Face='NormalId',EmissionDirection='NormalId',Orientation='ParticleOrientation',ShapeInOut='ParticleEmitterShapeInOut',ShapeStyle='ParticleEmitterShapeStyle',FlipbookLayout='ParticleFlipbookLayout',FlipbookMode='ParticleFlipbookMode',TextureMode='TextureMode',AlphaMode='AlphaMode',SizingMode='SurfaceGuiSizingMode',ScaleType='ScaleType',ResampleMode='ResamplerMode',ZIndexBehavior='ZIndexBehavior',SizeConstraint='SizeConstraint',AutomaticSize='AutomaticSize',BorderMode='BorderMode',ApplyStrokeMode='ApplyStrokeMode',LineJoinMode='LineJoinMode',AspectType='AspectType',DominantAxis='DominantAxis'}
local function enumValue(value,property,className)
 local a=value.v or {};local family=a[1]or a['1'];local name=a[2]or a['2']
 if not family then family=property=='Shape'and (className=='ParticleEmitter'and 'ParticleEmitterShape'or 'PartType')or ENUM_TYPES[property]end
 if type(family)~='string'or type(name)~='string'then return nil end
 local ok,item=pcall(function()return Enum[family][name]end);return ok and item or nil
end
local function val(v,property,className)
 if type(v)~='table' or not v.k then return v end
 local a=v.v
 if v.k=='CFrame'then return cfv(a)
 elseif v.k=='Vector2'then return Vector2.new(a[1],a[2])
 elseif v.k=='Vector3'then return Vector3.new(a[1],a[2],a[3])
 elseif v.k=='UDim'then return UDim.new(a[1],a[2])
 elseif v.k=='UDim2'then return UDim2.new(a[1],a[2],a[3],a[4])
 elseif v.k=='Rect'then return Rect.new(a[1],a[2],a[3],a[4])
 elseif v.k=='Color3'then return Color3.new(a[1],a[2],a[3])
 elseif v.k=='NumberRange'then return NumberRange.new(a[1],a[2])
 elseif v.k=='NumberSequence'then local r={};for _,x in ipairs(a)do r[#r+1]=NumberSequenceKeypoint.new(x[1],x[2],x[3])end;return NumberSequence.new(r)
 elseif v.k=='ColorSequence'then local r={};for _,x in ipairs(a)do r[#r+1]=ColorSequenceKeypoint.new(x[1],Color3.new(table.unpack(x[2])))end;return ColorSequence.new(r)
 elseif v.k=='Enum'then return enumValue(v,property,className)end
end
local function mesh(n)
 local id=n.props and n.props.MeshId
 if type(id)~='string'or id==''then return nil end
 if MESHES[id]==nil then
  if meshCount>=512 then MESHES[id]=false;return nil end
  meshCount+=1;MESHES[id]=false
  local ok,m=pcall(function()return game:GetService('AssetService'):CreateMeshPartAsync(Content.fromUri(id),{CollisionFidelity=Enum.CollisionFidelity.Box,RenderFidelity=Enum.RenderFidelity.Automatic})end)
  if ok then MESHES[id]=m end
 end
 return MESHES[id]or nil
end

function Codec.clearCache()
 for _,mesh in pairs(MESHES)do if mesh then mesh:Destroy()end end
 MESHES={};meshCount=0
end
function Codec.rememberMesh(object)
 local id=object.MeshId
 if type(id)~='string'or id==''or MESHES[id]or meshCount>=512 then return end
 local ok,copy=pcall(function()return object:Clone()end)
 if ok and copy then copy:ClearAllChildren();MESHES[id]=copy;meshCount+=1 end
end
function Codec.burst(h,guess,only)
 for _,object in pairs(only or h.nodes)do
  if object:IsA('ParticleEmitter')and (not object.Enabled or object.Rate==0)then
   local authored=tonumber(object:GetAttribute('EmitCount'))or tonumber(object:GetAttribute('EmitAmount'))
   if authored or guess then
    local n=authored or 12
    object:SetAttribute('GC_EstimatedBurst',not authored)
    object:SetAttribute('GC_EmissionSource',authored and 'AuthoredCountHint' or 'Guessed')
    pcall(function()object:Emit(math.clamp(math.floor(n),0,200))end)
   end
  end
 end
end
function Codec.retire(h)
 if not h or not h.folder then return end
 -- Preserve at least a rendered frame for observed sub-frame burst snapshots.
 -- Timing metadata remains untouched; this is an explicitly estimated preview.
 local delay=math.max(0,1/30-(os.clock()-(h.createdAt or 0)))
 if delay>0 then task.delay(delay,function()if h.folder then h.folder:Destroy()end end)
 else h.folder:Destroy()end
end

function Codec.preload(snapshot)
 for _,n in ipairs(snapshot.nodes or {})do if n.class=='MeshPart'then mesh(n)end end
end
local function make(n)
 if not VISUAL[n.class]then return nil end
 if n.class=='MeshPart'then
  local m=mesh(n);if m then return m:Clone()end
  local p=Instance.new('Part');p:SetAttribute('GC_MissingMesh',n.props and n.props.MeshId or 'Unavailable');p.Color=Color3.fromRGB(240,150,50);return p
 elseif n.class=='UnionOperation'then
  local p=Instance.new('Part');p:SetAttribute('GC_MissingGeometry','CSG cannot be reconstructed from observable properties');return p
 end
 local ok,o=pcall(Instance.new,n.class);return ok and o or nil
end
local function props(o,p,inactive)
 for k,v in pairs(p or {})do
  if k~='MeshId'and (k~='CFrame'or o:IsA('Attachment'))and k~='Parent'and k~='Enabled'then
   pcall(function()o[k]=val(v,k,o.ClassName)end)
  end
 end
 if o:IsA('BasePart')then o.Anchored=true;o.CanCollide=false;o.CanTouch=false;o.CanQuery=false end
 if o:IsA('ParticleEmitter')or o:IsA('Beam')or o:IsA('Trail')or o:IsA('Light')or o:IsA('Smoke')or o:IsA('Fire')or o:IsA('Sparkles')or o:IsA('SurfaceGui')or o:IsA('BillboardGui')or o:IsA('UIGradient')or o:IsA('UIStroke')then
  if inactive then o.Enabled=false elseif p.Enabled~=nil then o.Enabled=p.Enabled end
 end
end
function Codec.create(snapshot,origin,inactive,parent)
 local h={folder=Instance.new('Model'),nodes={},origin=origin,inactive=inactive,defs={},errors={},createdAt=os.clock()}
 h.folder.Name=snapshot.name or 'RecordedVFX'
 -- Build a single parent/child hierarchy; never include scripts or external welds.
 for _,n in ipairs(snapshot.nodes or {})do
  local o=make(n)
  if o then h.nodes[n.id]=o;h.defs[n.id]=n;o.Name=n.name or n.class;props(o,n.props,inactive)
  else h.errors[#h.errors+1]='Unsupported node '..tostring(n.class)end
 end
 for _,n in ipairs(snapshot.nodes or {})do
  local o=h.nodes[n.id]
  if o then
   local p=h.nodes[n.parent]or h.folder
   if o:IsA('Attachment')and not (p:IsA('BasePart')or p:IsA('Attachment'))then
    local anchor=Instance.new('Part');anchor.Name='GC_ExternalAttachmentAnchor';anchor.Size=Vector3.new(.1,.1,.1);anchor.Transparency=1;anchor.Anchored=true;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false;anchor.CFrame=origin;anchor.Parent=h.folder;p=anchor
   end
   o.Parent=p
   if o:IsA('BasePart')and n.cf then o.CFrame=origin*cfv(n.cf)
   elseif o:IsA('Attachment')then o.CFrame=val(n.props and n.props.CFrame)or CFrame.identity end
   for k,v in pairs(n.attrs or {})do pcall(function()o:SetAttribute(k,val(v))end)end
  end
 end
 for _,n in ipairs(snapshot.nodes or {})do local o=h.nodes[n.id];if o then for k,id in pairs(n.refs or {})do if h.nodes[id]then pcall(function()o[k]=h.nodes[id]end)end end end end
 h.folder.Parent=parent
 return h
end
-- Structure snapshots with source identity keep live particles/trails intact.
function Codec.sync(h,snapshot,origin,inactive,parent)
 if not h or not snapshot.stableNodes then
  if h and h.folder then h.folder:Destroy()end
  local fresh=Codec.create(snapshot,origin,inactive,parent)
  return fresh,fresh.nodes
 end
 local byKey={}
 for id,definition in pairs(h.defs)do
  local object=h.nodes[id]
  if object and definition.captureKey then byKey[definition.captureKey]={object=object,class=definition.class}end
 end
 local oldNodes=h.nodes;local nodes,defs,added,kept={},{},{},{}
 for _,n in ipairs(snapshot.nodes or {})do
  local prior=n.captureKey and byKey[n.captureKey]
  local object=prior and prior.class==n.class and prior.object or nil
  if not object then object=make(n);if object then added[n.id]=object end end
  if object then
   nodes[n.id]=object;defs[n.id]=n;kept[object]=true
   object.Name=n.name or n.class;props(object,n.props,inactive)
  else h.errors[#h.errors+1]='Unsupported node '..tostring(n.class)end
 end
 -- Move retained descendants before deleting removed ancestors.
 for _,n in ipairs(snapshot.nodes or {})do
  local object=nodes[n.id]
  if object then
   local holder=nodes[n.parent]or h.folder
   if object:IsA('Attachment')and not(holder:IsA('BasePart')or holder:IsA('Attachment'))then
    local anchor=object.Parent
    if not anchor or anchor.Name~='GC_ExternalAttachmentAnchor'or not anchor:IsDescendantOf(h.folder)then
     anchor=Instance.new('Part');anchor.Name='GC_ExternalAttachmentAnchor';anchor.Size=Vector3.new(.1,.1,.1);anchor.Transparency=1;anchor.Anchored=true;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false;anchor.CFrame=origin;anchor.Parent=h.folder
    end
    holder=anchor
   end
   object.Parent=holder
   if object:IsA('BasePart')and n.cf then object.CFrame=origin*cfv(n.cf)
   elseif object:IsA('Attachment')then object.CFrame=val(n.props and n.props.CFrame)or CFrame.identity end
   for k,v in pairs(n.attrs or {})do pcall(function()object:SetAttribute(k,val(v))end)end
  end
 end
 for _,object in pairs(oldNodes)do if not kept[object]then object:Destroy()end end
 for _,n in ipairs(snapshot.nodes or {})do
  local object=nodes[n.id]
  if object then for k,id in pairs(n.refs or {})do pcall(function()object[k]=nodes[id]end)end end
 end
 h.nodes=nodes;h.defs=defs;h.origin=origin;h.inactive=inactive;h.folder.Name=snapshot.name or 'RecordedVFX'
 return h,added
end
function Codec.update(h,delta)
 local o=h.nodes[delta.id];if not o then return end
 if delta.remove then o:Destroy();h.nodes[delta.id]=nil;return end
 if delta.parent then o.Parent=h.nodes[delta.parent]or h.folder end
 if delta.name then o.Name=delta.name end
 if delta.props then props(o,delta.props,h.inactive)end
 if delta.cf and o:IsA('BasePart')then o.CFrame=h.origin*cfv(delta.cf)end
 if delta.attachmentCF and o:IsA('Attachment')then o.CFrame=cfv(delta.attachmentCF)end
 if delta.refs then for k,id in pairs(delta.refs)do pcall(function()o[k]=h.nodes[id]end)end end
end

-- Smooth only sampled transforms/continuous properties; spawn, removal and toggles remain discrete.
function Codec.prepare(events)
 local prepared,active={},{}
 local allowed={Size=true,Scale=true,Offset=true,Transparency=true,Width0=true,Width1=true,CurveSize0=true,CurveSize1=true,TextureLength=true,Brightness=true,Range=true,CFrame=true,Position=true,AnchorPoint=true,Rotation=true,ImageTransparency=true,BackgroundTransparency=true,GroupTransparency=true,ImageColor3=true,BackgroundColor3=true,GroupColor3=true}
 local function add(epoch,id,property,value,time)
  if not value then return end
  local kind=type(value)=='number'and 'number' or (type(value)=='table'and value.k)
  if kind~='number'and kind~='Vector3'and kind~='CFrame'and kind~='UDim2'and kind~='Vector2'and kind~='Color3'then return end
  local key=tostring(id)..'/'..property;local channel=epoch.channels[key]
  if not channel then channel={id=id,property=property,kind=kind,keys={}};epoch.channels[key]=channel end
  local last=channel.keys[#channel.keys]
  local point={t=time,value=value}
  if last and last.t==time then channel.keys[#channel.keys]=point else channel.keys[#channel.keys+1]=point end
 end
 for _,event in ipairs(events or {})do
  if event.op=='group_spawn'then
   local epoch={channels={}};prepared[event]=epoch;active[event.id]=epoch
   for _,node in ipairs(event.snapshot.nodes or {})do
    if node.cf then add(epoch,node.id,'@world',{k='CFrame',v=node.cf},event.t)end
    for property,value in pairs(node.props or {})do if allowed[property]then add(epoch,node.id,property,value,event.t)end end
   end
  elseif event.op=='group_update'and active[event.id]then
   local epoch=active[event.id]
   for _,delta in ipairs(event.changes or {})do
    if delta.cf then add(epoch,delta.id,'@world',{k='CFrame',v=delta.cf},event.t)end
    if delta.attachmentCF then add(epoch,delta.id,'CFrame',{k='CFrame',v=delta.attachmentCF},event.t)end
    for property,value in pairs(delta.props or {})do if allowed[property]then add(epoch,delta.id,property,value,event.t)end end
   end
  elseif event.op=='group_remove'then active[event.id]=nil end
 end
 return prepared
end
function Codec.sample(h,time)
 if not h.curves then return end
 for _,channel in pairs(h.curves.channels)do
  local object=h.nodes[channel.id];local keys=channel.keys
  if object and #keys>1 and time>=keys[1].t then
   local low,high=1,#keys
   while low<high do local middle=math.floor((low+high+1)/2);if keys[middle].t<=time then low=middle else high=middle-1 end end
   local a,b=keys[low],keys[math.min(low+1,#keys)]
   local x=b.t>a.t and math.clamp((time-a.t)/(b.t-a.t),0,1)or 0
   local value
   if channel.kind=='number'then value=a.value+(b.value-a.value)*x
   else value=val(a.value):Lerp(val(b.value),x)end
   if channel.property=='@world'then object.CFrame=h.origin*value
   else pcall(function()object[channel.property]=value end)end
  end
 end
end

 local M={codec=Codec}
 local PART_PROPS={'Size','Color','Material','MaterialVariant','Transparency','Reflectance','CastShadow','LocalTransparencyModifier'}
 local EXTRA={Part={'Shape'},MeshPart={'MeshId','TextureID','DoubleSided'},SpecialMesh={'MeshId','TextureId','MeshType','Scale','Offset','VertexColor'},BlockMesh={'Scale','Offset','VertexColor'},CylinderMesh={'Scale','Offset','VertexColor'},Attachment={'CFrame','Visible'},Decal={'Texture','Transparency','Color3','Face','ZIndex'},Texture={'Texture','Transparency','Color3','Face','ZIndex','StudsPerTileU','StudsPerTileV','OffsetStudsU','OffsetStudsV'},SurfaceAppearance={'ColorMap','NormalMap','RoughnessMap','MetalnessMap','AlphaMode','Color'},PointLight={'Brightness','Color','Range','Shadows','Enabled'},SpotLight={'Brightness','Color','Range','Shadows','Enabled','Angle','Face'},SurfaceLight={'Brightness','Color','Range','Shadows','Enabled','Angle','Face'},Smoke={'Color','Opacity','RiseVelocity','Size','TimeScale','Enabled'},Fire={'Color','SecondaryColor','Heat','Size','TimeScale','Enabled'},Sparkles={'SparkleColor','TimeScale','Enabled'},SurfaceGui={'Enabled','Face','CanvasSize','SizingMode','PixelsPerStud','AlwaysOnTop','LightInfluence','Brightness','ClipsDescendants','ZIndexBehavior','ZOffset','MaxDistance'},BillboardGui={'Enabled','Size','SizeOffset','StudsOffset','StudsOffsetWorldSpace','ExtentsOffset','ExtentsOffsetWorldSpace','AlwaysOnTop','LightInfluence','Brightness','MaxDistance','ClipsDescendants','ZIndexBehavior'},Frame={'Position','Size','AnchorPoint','Rotation','ZIndex','Visible','BackgroundColor3','BackgroundTransparency','BorderColor3','BorderSizePixel','BorderMode','ClipsDescendants','SizeConstraint','AutomaticSize','LayoutOrder'},CanvasGroup={'Position','Size','AnchorPoint','Rotation','ZIndex','Visible','BackgroundColor3','BackgroundTransparency','BorderColor3','BorderSizePixel','BorderMode','ClipsDescendants','SizeConstraint','AutomaticSize','LayoutOrder','GroupColor3','GroupTransparency'},ImageLabel={'Position','Size','AnchorPoint','Rotation','ZIndex','Visible','BackgroundColor3','BackgroundTransparency','BorderColor3','BorderSizePixel','BorderMode','ClipsDescendants','SizeConstraint','AutomaticSize','LayoutOrder','Image','ImageColor3','ImageTransparency','ImageRectOffset','ImageRectSize','ScaleType','SliceCenter','SliceScale','TileSize','ResampleMode'},ImageButton={'Position','Size','AnchorPoint','Rotation','ZIndex','Visible','BackgroundColor3','BackgroundTransparency','BorderColor3','BorderSizePixel','BorderMode','ClipsDescendants','SizeConstraint','AutomaticSize','LayoutOrder','Image','ImageColor3','ImageTransparency','ImageRectOffset','ImageRectSize','ScaleType','SliceCenter','SliceScale','TileSize','ResampleMode','AutoButtonColor'},UICorner={'CornerRadius'},UIStroke={'ApplyStrokeMode','Color','Enabled','LineJoinMode','Thickness','Transparency'},UIGradient={'Color','Transparency','Offset','Rotation','Enabled'},UIAspectRatioConstraint={'AspectRatio','AspectType','DominantAxis'},UIScale={'Scale'}}
 local BUCKET={Effects=true,VFX=true,FX=true,ClientEffects=true,WorldFX=true,Debris=true,Map=true,World=true,MapFolder=true}
 local function equal(a,b)
  if type(a)~=type(b)then return false end
  if type(a)~='table'then return a==b end
  for k,v in pairs(a)do if not equal(v,b[k])then return false end end
  for k in pairs(b)do if a[k]==nil then return false end end
  return true
 end
 local function copyValue(v)
  if type(v)~='table'then return v end
  local out={};for k,x in pairs(v)do out[k]=copyValue(x)end;return out
 end
 local function readProps(o)
  local ret={};local names={}
  if o:IsA('BasePart')then for _,n in ipairs(PART_PROPS)do names[#names+1]=n end end
  for _,n in ipairs(PROPERTIES[o.ClassName]or EXTRA[o.ClassName]or {})do names[#names+1]=n end
  for _,n in ipairs(names)do local ok,v=pcall(function()return o[n]end);if ok then local p=pack(v);if p~=nil then ret[n]=p end end end
  return ret
 end
 local function characterModel(o)
  return o:IsA('Model')and (o:FindFirstChildOfClass('Humanoid')~=nil or o:FindFirstChildOfClass('AnimationController')~=nil or (o:FindFirstChild('Head')~=nil and (o:FindFirstChild('Torso')~=nil or o:FindFirstChild('UpperTorso')~=nil)))
 end

 local BODY={HumanoidRootPart=true,Head=true,Torso=true,UpperTorso=true,LowerTorso=true,
 ['Left Arm']=true,['Right Arm']=true,['Left Leg']=true,['Right Leg']=true,
 LeftUpperArm=true,LeftLowerArm=true,LeftHand=true,RightUpperArm=true,RightLowerArm=true,RightHand=true,
 LeftUpperLeg=true,LeftLowerLeg=true,LeftFoot=true,RightUpperLeg=true,RightLowerLeg=true,RightFoot=true}
 local function own(o)
  local n=o
  while n and n~=workspace do
   if n:GetAttribute('GC_BakerPreview')==true or n.Name=='GC_CLIENT_VFX_PREVIEW' or n.Name=='GC_TakePreview' then return true end
   n=n.Parent
  end
  return false
 end
 local function worldGui(o)
  local n=o
  while n and n~=workspace do
   if n:IsA('SurfaceGui')or n:IsA('BillboardGui')then return n end
   n=n.Parent
  end
 end
 M.worldGui=worldGui
 local function guiHost(gui)
  local a=gui and gui.Adornee
  if a and a:IsA('BasePart')then return a end
  return gui and gui:FindFirstAncestorWhichIsA('BasePart')or nil
 end
 local function bodyPart(o)
  return o:IsA('BasePart')and o.Parent and characterModel(o.Parent)and BODY[o.Name]==true
 end
 local function anchor(o)
  local gui=worldGui(o)
  if gui then local host=guiHost(gui);return host and host.CFrame end
  if o:IsA('Model')or o:IsA('Folder')then local part=o:FindFirstChildWhichIsA('BasePart',true);return part and part.CFrame end
  if o:IsA('BasePart')then return o.CFrame end
  if o:IsA('Attachment')then return o.WorldCFrame end
  local p=o.Parent
  if p and p:IsA('Attachment')then return p.WorldCFrame end
  if p and p:IsA('BasePart')then return p.CFrame end
  if o:IsA('Beam')or o:IsA('Trail')then local a=o.Attachment0 or o.Attachment1;return a and a.WorldCFrame end
  local p0=o:FindFirstAncestorOfClass('BasePart');return p0 and p0.CFrame
 end
 local function hint(o)
  local n=o
  while n and n~=workspace do
   if characterModel(n)then break end
   local name=n.Name:lower()
   if BUCKET[n.Name]and n.Name~='Map'and n.Name~='World'and n.Name~='MapFolder'then return true end
   for _,word in ipairs({'vfx','effect','particle','impact','burst','uppercut','cloud','slam','blockbreak','shockwave','slash','kickwind','spark','smoke','cero','flare','fallback','ringsfx','bringerlight','windslash'})do
    if name:find(word,1,true)then return true end
   end
   n=n.Parent
  end
  return false
 end
 local function sceneGeometry(o)
  if not o or not o:IsA('BasePart')or bodyPart(o)or(o.Parent and characterModel(o.Parent))then return false end
  if hint(o)then return false end
  local n=o.Parent
  while n and n~=workspace do
   if n.Name=='Map'or n.Name=='World'or n.Name=='MapFolder'then return true end
   n=n.Parent
  end
  return o.CanCollide==true
 end
 local function hasEffect(o)
  if o:IsA('ImageLabel')or o:IsA('ImageButton')then return worldGui(o)~=nil end
  for _,class in ipairs({'ParticleEmitter','Beam','Trail','Smoke','Fire','Sparkles'})do
   if o:FindFirstChildWhichIsA(class,true)then return true end
  end
  local gui=worldGui(o)or o:FindFirstChildWhichIsA('SurfaceGui',true)or o:FindFirstChildWhichIsA('BillboardGui',true)
  return gui~=nil and(gui:FindFirstChildWhichIsA('ImageLabel',true)~=nil or gui:FindFirstChildWhichIsA('ImageButton',true)~=nil)
 end
 local function inWorld(o)
  if o:IsDescendantOf(workspace)then return true end
  local gui=worldGui(o);local host=gui and guiHost(gui)
  return host~=nil and host:IsDescendantOf(workspace)
 end
 function M.eligible(o)
  if own(o)then return false end
  local root=M.root(o)
  if not root then return false end
  local gui=worldGui(o)
  if gui and sceneGeometry(guiHost(gui))and not hint(gui)then return false end
  -- Fresh/streamed geometry is not evidence of a visual effect.
  return Core.isVfx(o)or hasEffect(root)or hint(root)
 end
 -- Baseline templates are watched, not recorded, until they become active.
 -- A world index contains pooled/hidden effects and is not itself a VFX event.
 function M.active(o)
  if own(o)then return false end
  if o:IsA('ParticleEmitter')then return o.Enabled and o.Rate>0 end
  if o:IsA('Beam')then return o.Enabled and o.Attachment0~=nil and o.Attachment1~=nil end
  if o:IsA('Trail')then return o.Enabled and o.Attachment0~=nil and o.Attachment1~=nil end -- pre-record trail history remains unavailable
  if o:IsA('Light')then return false end -- scene lighting is not a new effect event
  if o:IsA('Smoke')or o:IsA('Fire')or o:IsA('Sparkles')then return o.Enabled end
  local gui=worldGui(o)
  if gui and gui.Enabled then
   local image=(o:IsA('ImageLabel')or o:IsA('ImageButton'))and o or gui:FindFirstChildWhichIsA('ImageLabel',true)or gui:FindFirstChildWhichIsA('ImageButton',true)
   if image and image.ImageTransparency<1 and image.Visible then
    local n=image.Parent
    while n and n~=gui do if n:IsA('GuiObject')and not n.Visible then return false end;n=n.Parent end
    return true
   end
  end
  return false
 end
 function M.candidate(o)
  return Core.isVfx(o)or o:IsA('BasePart')or o:IsA('Attachment')or o:IsA('SpecialMesh')or o:IsA('Decal')or o:IsA('Texture')or o:IsA('Light')or(VISUAL[o.ClassName]and worldGui(o)~=nil)
 end
 function M.prefab(part)
  local chosen=nil;local n=part.Parent
  while n and n~=workspace and n~=workspace.Terrain do
   if BUCKET[n.Name]or characterModel(n)or n:IsA('Accessory')or n:IsA('Tool')then break end
   if n:IsA('BasePart')then chosen=n
   elseif (n:IsA('Model')or n:IsA('Folder'))and hint(n)then chosen=n end
   n=n.Parent
  end
  return chosen or part
 end
 function M.root(o,t)
  local gui=worldGui(o)
  if gui then
   local host=guiHost(gui)
   if host and gui:IsDescendantOf(host)and not sceneGeometry(host)and not bodyPart(host)and not host:FindFirstAncestorOfClass('Accessory')and not host:FindFirstAncestorOfClass('Tool')then return M.prefab(host)end
   return gui
  end
  -- Preserve a prefab's mesh assembly; common world/effect buckets remain boundaries.
  -- Character/gear bodies are only anchors, never captured visual hierarchies.
  if o:IsA('BasePart')then return not bodyPart(o)and not sceneGeometry(o)and M.prefab(o)or nil end
  local attachment=nil
  local n=o.Parent
  while n and n~=workspace and n~=workspace.Terrain do
   if n:IsA('Attachment')then attachment=attachment or n end
   if n:IsA('BasePart')then
    if bodyPart(n)or sceneGeometry(n)or n:FindFirstAncestorOfClass('Accessory')or n:FindFirstAncestorOfClass('Tool')then return attachment or o end
    return M.prefab(n)
   end
   if characterModel(n)then return attachment or o end
   n=n.Parent
  end
  return attachment or o
 end
 local function inRange(o,t)
  if own(o)then return false end
  local frame=anchor(o)
  if not frame and (o:IsA('Model')or o:IsA('Folder'))then local part=o:FindFirstChildWhichIsA('BasePart',true);frame=part and part.CFrame end
  return frame~=nil and (frame.Position-t.rigObj.root.Position).Magnitude<=(t.kind=='GAME' and CFG.GAME_RADIUS or CFG.VFX_RADIUS)
 end
 local function identity(entry,o,role)
  entry.identities=entry.identities or {};entry.identitySerial=entry.identitySerial or 0
  local roles=entry.identities[o]
  if not roles then roles={};entry.identities[o]=roles end
  role=role or 'node'
  if not roles[role]then entry.identitySerial+=1;roles[role]=tostring(entry.identitySerial)end
  return roles[role]
 end
 local function carrierHost(o)
  local gui=worldGui(o)
  if gui then return guiHost(gui)end
  return o.Parent and o.Parent:IsA('BasePart')and o.Parent or nil
 end
 local function node(entry,o,parent)
  entry.serial+=1
  local n={id=entry.serial,captureKey=identity(entry,o),parent=parent or 0,class=o.ClassName,name=o.Name,props=readProps(o),attrs={}}
  if o:IsA('BasePart')then n.cf=Core.cft(entry.origin:ToObjectSpace(o.CFrame))end
  if o:IsA('MeshPart')then Codec.rememberMesh(o)end
  if o:IsA('Attachment')and (not parent or parent==0)then n.props.CFrame=pack(entry.origin:ToObjectSpace(o.WorldCFrame))end
  for k,v in pairs(o:GetAttributes())do local pv=pack(v);if pv~=nil then n.attrs[k]=pv end end
  entry.map[o]=n.id;entry.records[n.id]={object=o,node=n,dirty=false}
  local ok,c=pcall(function()return o.Changed:Connect(function(property)local r=entry.records[n.id];if r and not (o:IsA('BasePart')and property=='CFrame')then r.dirty=true end end)end)
  if ok then entry.connections[#entry.connections+1]=c end
  return n
 end
 local function snapshot(entry)
  local nodes={};local queue={{entry.root,0}};local i=1
  if Core.isVfx(entry.root)or entry.root:IsA('Light')or entry.root:IsA('Decal')or entry.root:IsA('Texture')or worldGui(entry.root)then
   local frame=anchor(entry.root)
   if frame then
    entry.serial+=1;local id=entry.serial
    local host=carrierHost(entry.root)
     local carrier={id=id,captureKey=identity(entry,entry.root,'carrier'),parent=0,class='Part',name='EffectAnchor',props={Size=pack(host and host.Size or Vector3.new(.1,.1,.1)),Shape=host and host:IsA('Part')and pack(host.Shape)or nil,Transparency=1},cf=Core.cft(entry.origin:ToObjectSpace(frame))}
     if host then entry.map[host]=id end
    nodes[#nodes+1]=carrier;entry.records[id]={object=entry.root,node=carrier,proxy=true,carrier=true,sizeProxy=host}
    queue={{entry.root,id}}
   end
  end
  while i<=#queue and #nodes<CFG.MAX_GROUP_NODES do
   local o,parent=queue[i][1],queue[i][2];i+=1
   if VISUAL[o.ClassName]then
    local n=node(entry,o,parent);nodes[#nodes+1]=n
    for _,c in ipairs(o:GetChildren())do if VISUAL[c.ClassName]and not characterModel(c)and not bodyPart(c)then queue[#queue+1]={c,n.id}end end
   end
  end
  entry.truncated=i<=#queue
  -- Beams/trails sometimes target an attachment outside their own model.
  -- Capture endpoint proxies without importing the character or map around it.
  local originalCount=#nodes
  for ni=1,originalCount do
   local n=nodes[ni]
   local obj=entry.records[n.id].object
   if obj:IsA('Beam')or obj:IsA('Trail')then
    n.refs={}
    for _,prop in ipairs({'Attachment0','Attachment1'})do
     local a=obj[prop]
     if a then
      if not entry.map[a]and #nodes+2<=CFG.MAX_GROUP_NODES then
       entry.serial+=1;local partId=entry.serial
       local proxy={id=partId,captureKey=identity(entry,a,'endpointPart'),parent=0,class='Part',name='External_'..prop,props={Size=pack(Vector3.new(.1,.1,.1)),Transparency=1},cf=Core.cft(entry.origin:ToObjectSpace(a.WorldCFrame))}
       nodes[#nodes+1]=proxy;entry.records[partId]={object=a,node=proxy,proxy=true}
       entry.serial+=1;local aid=entry.serial
       nodes[#nodes+1]={id=aid,captureKey=identity(entry,a,'endpointAttachment'),parent=partId,class='Attachment',name=a.Name,props={CFrame=pack(CFrame.identity)}}
       entry.map[a]=aid
      end
      n.refs[prop]=entry.map[a]
     end
    end
   elseif obj:IsA('SurfaceGui')or obj:IsA('BillboardGui')then
    local a=guiHost(obj)
    if a then
     if not entry.map[a]and #nodes+1<=CFG.MAX_GROUP_NODES then
      entry.serial+=1;local id=entry.serial
      local proxy={id=id,captureKey=identity(entry,a,'adornee'),parent=0,class='Part',name='External_Adornee',props={Size=pack(a.Size),Transparency=1},cf=Core.cft(entry.origin:ToObjectSpace(a.CFrame))}
      nodes[#nodes+1]=proxy;entry.records[id]={object=a,node=proxy,proxy=true,sizeProxy=a};entry.map[a]=id
     end
     if entry.map[a]then n.refs={Adornee=entry.map[a]}else entry.truncated=true end
    end
   end
  end
  local frame=anchor(entry.root);local floor=frame and Core.groundPoint and Core.groundPoint(frame.Position,nil)
  return {stableNodes=true,name=entry.root.Name,path=entry.root:GetFullName(),nodes=copyValue(nodes),anchor=frame and Core.cft(entry.origin:ToObjectSpace(frame))or nil,truncated=entry.truncated,groundOffset=floor and r(frame.Position.Y-floor.Y)or nil}
 end

 local function rebuild(t,e,ts)
  for _,c in ipairs(e.connections)do c:Disconnect()end
  local replacement={root=e.root,id=e.id,origin=e.origin,map={},records={},serial=0,connections={},structureDirty=false,identities=e.identities,identitySerial=e.identitySerial}
  t.groupRoots[e.root]=replacement
  local snap=snapshot(replacement)
  if snap.truncated then t.truncatedVFX=true end
  t.vfx[#t.vfx+1]={t=r(ts),op='group_spawn',id=e.id,kind='VFXGroup',snapshot=snap,path=snap.path,replace=true}
  replacement.connections[#replacement.connections+1]=e.root.DescendantAdded:Connect(function()replacement.structureDirty=true end)
  replacement.connections[#replacement.connections+1]=e.root.DescendantRemoving:Connect(function()replacement.structureDirty=true end)
  return replacement
 end
 function M.add(t,o,ts)
  if not o or not o.Parent or not inWorld(o)or not M.candidate(o)or not M.eligible(o)or not inRange(o,t)then return end
  if bodyPart(o)then return end
  if o:IsA('BasePart')and (o:FindFirstAncestorOfClass('Accessory')or o:FindFirstAncestorOfClass('Tool'))then return end
  local root=M.root(o,t)
  if not root or root==workspace or root==t.rigObj.char then return end
  t.fresh=t.fresh or {};t.touched=t.touched or {}
  if not Core.isVfx(o)and not hasEffect(root)and not hint(root)then return end
  local entry=t.groupRoots[root]
  if entry then if not entry.map[o]then entry.structureDirty=true end;return end
  if t.groupCount>=CFG.MAX_GROUPS or #t.vfx>=(t.gameVFXLimit or CFG.MAX_VFX_EVENTS) then t.truncatedVFX=true;t.droppedVFX=(t.droppedVFX or 0)+1;return end
  t.vfxSerial+=1;t.groupCount+=1
  entry={root=root,id=t.vfxSerial,origin=t.origin,map={},records={},serial=0,connections={},structureDirty=false}
  t.groupRoots[root]=entry
  local snap=snapshot(entry)
  if snap.truncated then t.truncatedVFX=true end
  t.vfx[#t.vfx+1]={t=r(ts),op='group_spawn',id=entry.id,kind='VFXGroup',snapshot=snap,path=snap.path}
  entry.connections[#entry.connections+1]=root.DescendantAdded:Connect(function()entry.structureDirty=true end)
  entry.connections[#entry.connections+1]=root.DescendantRemoving:Connect(function()entry.structureDirty=true end)
 end
 function M.refresh(t,ts)
  if t.captureStats then
   local stats=t.captureStats;stats.samples=(stats.samples or 0)+1
   stats.maxSampleGap=math.max(stats.maxSampleGap or 0,t.lastVFXRefresh and math.max(0,ts-t.lastVFXRefresh)or 0)
   if ts>0 then stats.sampleHz=r(stats.samples/ts)end;t.lastVFXRefresh=ts
  end
  for root,e in pairs(t.groupRoots)do
   if #t.vfx>=(t.gameVFXLimit or CFG.MAX_VFX_EVENTS) then t.truncatedVFX=true;break end
   if not root.Parent or not inWorld(root)then
    t.vfx[#t.vfx+1]={t=r(ts),op='group_remove',id=e.id}
    for _,c in ipairs(e.connections)do c:Disconnect()end;t.groupRoots[root]=nil;t.groupCount=math.max(0,t.groupCount-1)
   elseif e.structureDirty then
    rebuild(t,e,ts)
   else
    local changes={}
    for id,rec in pairs(e.records)do
     local obj,n=rec.object,rec.node
     if obj and obj.Parent then
      local change={id=id};local dirty=false
      if rec.proxy then
       local frame=rec.carrier and anchor(obj)or (obj:IsA('BasePart')and obj.CFrame or obj.WorldCFrame)
       local a=frame and Core.cft(e.origin:ToObjectSpace(frame))or n.cf
       if not equal(a,n.cf)then change.cf=a;n.cf=a;dirty=true end
       if rec.carrier then rec.sizeProxy=carrierHost(obj)end
       if rec.sizeProxy and rec.sizeProxy.Parent then
        local size=pack(rec.sizeProxy.Size)
        if not equal(size,n.props.Size)then change.props={Size=size};n.props.Size=size;dirty=true end
        local shape=rec.sizeProxy:IsA('Part')and pack(rec.sizeProxy.Shape)or nil
        if shape and not equal(shape,n.props.Shape)then change.props=change.props or {};change.props.Shape=shape;n.props.Shape=shape;dirty=true end
       end
      elseif obj:IsA('BasePart')then
       local a=Core.cft(e.origin:ToObjectSpace(obj.CFrame))
       if not equal(a,n.cf)then change.cf=a;n.cf=a;dirty=true end
      elseif obj:IsA('Attachment')and n.parent==0 then
       local a=Core.cft(e.origin:ToObjectSpace(obj.WorldCFrame))
       if not equal(a,n.props.CFrame.v)then change.attachmentCF=a;n.props.CFrame={k='CFrame',v=a};dirty=true end
      end
      if rec.dirty and not rec.proxy then
       local parent=e.map[obj.Parent]or 0
       if parent~=n.parent then change.parent=parent;n.parent=parent;dirty=true end
       if obj.Name~=n.name then change.name=obj.Name;n.name=obj.Name;dirty=true end
       if obj:IsA('Beam')or obj:IsA('Trail')then
        local refs={Attachment0=e.map[obj.Attachment0]or 0,Attachment1=e.map[obj.Attachment1]or 0}
        if (obj.Attachment0 and refs.Attachment0==0)or (obj.Attachment1 and refs.Attachment1==0)then e.structureDirty=true
        elseif not equal(refs,n.refs)then change.refs=refs;n.refs=refs;dirty=true end
       end
       if obj:IsA('SurfaceGui')or obj:IsA('BillboardGui')then
        local a=guiHost(obj);local id=a and e.map[a]
        if a and not id then e.structureDirty=true elseif id then local refs={Adornee=id};if not equal(refs,n.refs)then change.refs=refs;n.refs=refs;dirty=true end end
       end
       local p=readProps(obj);local changed={}
       if obj:IsA('Attachment')and n.parent==0 then p.CFrame=n.props.CFrame end
       for k,v in pairs(p)do if not equal(v,n.props[k])then changed[k]=v end end
       if next(changed)then change.props=changed;n.props=p;dirty=true end
       rec.dirty=false
      end
      if dirty then changes[#changes+1]=change end
     end
    end
    if #changes>0 then t.vfx[#t.vfx+1]={t=r(ts),op='group_update',id=e.id,changes=changes}end
   end
  end
 end

 -- Bounded warm index; no physics queries, local-owner filter, or named-folder cutoff.
 local registry=setmetatable({},{__mode='k'})
 local watches={};local watched=0;local sweep=nil;local warm=false;local nextCleanup=0
 function M.notify(o,fresh)
  if not o or own(o)or not M.eligible(o)then return end
  local t=recording
  if not t or (t.kind~='VFX' and t.kind~='GAME')then return end
  local root=M.root(o,t);if root and t.groupRoots[root]then return end -- captured nodes have their own change/structure observers
  t.fresh=t.fresh or {};t.touched=t.touched or {}
  if fresh then t.fresh[o]=true else t.touched[o]=true end
  if not (fresh and o:IsA('BasePart'))and (t.immediateUsed or 0)<32 then
   t.immediateUsed=(t.immediateUsed or 0)+1;M.add(t,o,now(t))
  elseif not t.vfxPending[o]then
   if t.pendingCount<CFG.MAX_SCAN_NODES then t.vfxPending[o]=true;t.pendingCount+=1 else t.truncatedVFX=true end
  end
 end
 local WATCH_PROPS={Parent=true,Name=true,CFrame=true,Adornee=true,Attachment0=true,Attachment1=true}
 for _,property in ipairs(PART_PROPS)do WATCH_PROPS[property]=true end
 for _,properties in pairs(EXTRA)do for _,property in ipairs(properties)do WATCH_PROPS[property]=true end end
 for _,properties in pairs(PROPERTIES)do for _,property in ipairs(properties)do WATCH_PROPS[property]=true end end
 function M.observe(o,fresh)
  if not recording or (recording.kind~='VFX' and recording.kind~='GAME')then return end
  if not o or not M.candidate(o)or own(o)or bodyPart(o)then return end
  local eligible=M.eligible(o)
  if not registry[o]and(eligible or o:IsA('MeshPart'))then
   registry[o]=true
   if recording and (recording.kind=='VFX' or recording.kind=='GAME')and M.active(o)then M.add(recording,o,now(recording))end
  end
  -- An indexed mesh can become eligible when its emitter/GUI is parented later.
  -- Size/Scale/Offset-only pooled effects must trigger admission before sampling.
  local priority=Core.isVfx(o)or worldGui(o)or o:IsA('Attachment')or o:IsA('Light')
  if eligible and not watches[o]and watched<(priority and CFG.MAX_WATCHED or math.floor(CFG.MAX_WATCHED/2))then
   watches[o]=o.Changed:Connect(function(prop)if WATCH_PROPS[prop]then M.notify(o,false)end end)
   watched+=1
  end
  if Core.isVfx(o)or worldGui(o)then local host=M.root(o,nil);if host and host~=o then M.observe(host,false)end end
  if fresh then M.notify(o,true)end
 end
 function M.indexStep()
  if not recording or (recording.kind~='VFX' and recording.kind~='GAME')then return end
  local deadline=os.clock()+CFG.INDEX_STEP_SECONDS
  if not warm and not sweep then
   local roots=workspace:GetChildren()
   for _,o in ipairs(playerGui:GetChildren())do if o:IsA('SurfaceGui')or o:IsA('BillboardGui')or o:IsA('Folder')then roots[#roots+1]=o end end
   sweep={{items=roots,i=1}}
  end
  local used=0
  while sweep and #sweep>0 and used<CFG.SCAN_BUDGET and os.clock()<deadline do
   local top=sweep[#sweep];local o=top.items[top.i]
   if not o then table.remove(sweep)
   else
    top.i+=1;used+=1
    if o.Parent and not own(o)then
     M.observe(o,false)
     local children=o:GetChildren()
     if #children>0 then sweep[#sweep+1]={items=children,i=1}end
    end
   end
  end
  if sweep and #sweep==0 then sweep=nil;warm=true end
  if os.clock()>=nextCleanup then
   nextCleanup=os.clock()+1
   for o,c in pairs(watches)do if not o.Parent then c:Disconnect();watches[o]=nil;watched-=1;registry[o]=nil end end
  end
 end
 function M.warmMeshes(events)
  local wanted={}
  for _,event in ipairs(events or {})do if event.snapshot then for _,node in ipairs(event.snapshot.nodes or {})do if node.class=='MeshPart'and node.props and type(node.props.MeshId)=='string'and node.props.MeshId~=''then wanted[node.props.MeshId]=true end end end end
  for object in pairs(registry)do if object.Parent and object:IsA('MeshPart')and wanted[object.MeshId]then Codec.rememberMesh(object)end end
 end
 function M.seed(t)
  t.fresh={};t.touched={};t.seedObjects={};t.scanIndex=1;t.immediateUsed=0
  for o in pairs(registry)do if M.eligible(o)then t.seedObjects[#t.seedObjects+1]=o end end
  t.captureStats={indexWarm=warm,indexed=#t.seedObjects,watchCount=watched,watchLimit=watched>=CFG.MAX_WATCHED,baselineMode='active-components-only'}
 end
 function M.scan(t,ts)
  local used=0;t.immediateUsed=0
  while t.scanIndex<=#t.seedObjects and used<CFG.SCAN_BUDGET do
   local o=t.seedObjects[t.scanIndex];t.scanIndex+=1;used+=1
   if o.Parent and M.active(o)then M.add(t,o,ts)end
  end
  t.captureStats.indexWarm=warm;t.captureStats.dropped=t.droppedVFX or 0
 end
 function M.removing(o)
  local t=recording
  if t and (t.kind=='VFX' or t.kind=='GAME')and M.candidate(o)and not own(o)then
   t.fresh[o]=true;M.add(t,o,now(t))
   local root=M.root(o,t);local entry=root and t.groupRoots[root]
   -- Flush a just-added child while DescendantRemoving still exposes its properties.
   if entry and entry.structureDirty then entry=rebuild(t,entry,now(t))end
   entry=t.groupRoots[o]
   if entry then
    if #t.vfx<(t.gameVFXLimit or CFG.MAX_VFX_EVENTS)then
     t.vfx[#t.vfx+1]={t=now(t),op='group_remove',id=entry.id}
    else t.truncatedVFX=true end
    for _,c in ipairs(entry.connections)do c:Disconnect()end
    t.groupRoots[o]=nil;t.groupCount=math.max(0,t.groupCount-1)
   end
  end
 end
 function M.shutdown()
  for _,c in pairs(watches)do c:Disconnect()end
  watches={};registry={};sweep=nil;watched=0;Codec.clearCache()
 end
 function M.finish(t)
  for _,e in pairs(t.groupRoots or {})do for _,c in ipairs(e.connections)do c:Disconnect()end end
  -- No property watchers, world index, or traversal stack survive Stop.
  for _,c in pairs(watches)do c:Disconnect()end
  watches={};registry=setmetatable({},{__mode='k'});sweep=nil;warm=false;watched=0;nextCleanup=0
 end
 return M
end)()
-- Combat Inspector v6.9: additive, client-observed actor/timeline captures.
-- No injection, server script access, source reading, remotes, or player control.
-- The existing motion, grouped VFX, replay, and Studio export code is unchanged.
local Inspector={}
local inspectIDs=setmetatable({},{__mode='k'})
local inspectIDCounter=0

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
function Core.inspectCandidates()
    local selfChar=localPlayer.Character
    local selfRoot=selfChar and selfChar:FindFirstChild('HumanoidRootPart')
    local listed,seen={},{}
    local function offer(model)
        if not model or seen[model] then return end
        seen[model]=true
        local candidate=modelData(model)
        if not candidate or not Core.actorRoleEnabled(candidate.role)then return end
        local distance=selfRoot and (candidate.root.Position-selfRoot.Position).Magnitude or 0
        if candidate.role~='self' and distance>CFG.INSPECT_RADIUS then return end
        candidate.distance=r(distance)
        listed[#listed+1]=candidate
    end
    offer(selfChar)
    if CFG.INCLUDE_PLAYERS then for _,player in ipairs(Players:GetPlayers())do offer(player.Character)end end
    Core.lastActorQueryLimited=false
    if selfRoot and CFG.INCLUDE_NPCS then
        local params=OverlapParams.new()
        params.MaxParts=CFG.INSPECT_QUERY_PARTS
        local ok,parts=pcall(function()
            return workspace:GetPartBoundsInRadius(selfRoot.Position,CFG.INSPECT_RADIUS,params)
        end)
        if ok then
            Core.lastActorQueryLimited=#parts>=CFG.INSPECT_QUERY_PARTS
            for _,part in ipairs(parts)do
                local model=part:FindFirstAncestorOfClass('Model')
                -- An accessory or weapon may be nested in another Model.
                for _=1,3 do
                    if not model then break end
                    if model:FindFirstChildOfClass('Humanoid') then offer(model);break end
                    local parent=model.Parent
                    model=(parent and parent:IsA('Model')) and parent or (parent and parent:FindFirstAncestorOfClass('Model'))
                end
            end
        end
    end
    table.sort(listed,function(a,b)
        if a.role=='self'or b.role=='self'then return a.role=='self'and b.role~='self'end
        if a.distance==b.distance then return a.label<b.label end
        return a.distance<b.distance
    end)
    while #listed>CFG.INSPECT_CHOICES do table.remove(listed)end
    return listed
end
-- Automatic radius-only selection. No manual actor overrides.
function Core.inspectPlan(candidates)
 candidates=candidates or Core.inspectCandidates()
 local chosen,eligible={},{}
 for _,a in ipairs(candidates)do
  if Core.actorRoleEnabled(a.role)and(a.role=='self'or(a.distance or 0)<=CFG.INSPECT_RADIUS)then
   eligible[#eligible+1]=a
  end
 end
 table.sort(eligible,function(a,b)
  if a.role=='self'or b.role=='self'then return a.role=='self'and b.role~='self'end
  return (a.distance or 0)<(b.distance or 0)
 end)
 for _,a in ipairs(eligible)do if #chosen>=CFG.INSPECT_MAX_ACTORS then break end chosen[#chosen+1]=a end
 return chosen,'automatic-radius',#eligible>CFG.INSPECT_MAX_ACTORS
end
function Core.inspectBegin(t)
    local chosen,selectionMode=Core.inspectPlan()
    if #chosen==0 then return false,'No player/NPC available' end
    t.inspector={sampleHz=CFG.INSPECT_FPS,radius=CFG.INSPECT_RADIUS,
        actors={},frames={},truncated=false,dropped=0,settings=Core.actorCaptureSettings(),selectionMode=selectionMode,
        caveat='Client-visible observations only; reported stun flags may be deadlines or ambiguous; no server acceptance or hidden code.'}
    t.inspectActors={}
    t.inspectConnections={}
    t.inspectWatched=setmetatable({},{__mode='k'})
    t.inspectActorCache={};t.inspectActiveIDs={}
    Core.inspectRefresh(t,0)
    t.nextInspect=0
    return true
end
function Core.inspectAddActor(t,a)
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
        local entry={identity=a,metadata=metadata,animator=animator,
            channels=channelList,lastState=nil,lastTrack=nil,alive=true}
        t.inspectActorCache[a.model]=entry
        return entry
end
function Core.inspectRefresh(t,ts)
 local chosen,_,limited=Core.inspectPlan()
 t.inspector.actorLimitReached=limited
 t.inspector.queryPartLimitReached=Core.lastActorQueryLimited==true
 t.inspectActors={};t.inspectActiveIDs={}
 for _,a in ipairs(chosen)do
  local entry=t.inspectActorCache[a.model]
  if not entry then entry=Core.inspectAddActor(t,a)end
  if entry then
   t.inspectActors[#t.inspectActors+1]=entry;t.inspectActiveIDs[a.id]=true
   if t.game and Core.gameWatchActor then Core.gameWatchActor(t,entry)end
   if not entry.wasInRadius then Core.appendEvent(t,'ACTOR_ENTER_RADIUS',{actor=a.label,id=a.id,role=a.role},ts)end
   entry.wasInRadius=true
  end
 end
 for model,entry in pairs(t.inspectActorCache)do
  if not t.inspectActiveIDs[entry.identity.id]and entry.wasInRadius then
   Core.appendEvent(t,'ACTOR_LEAVE_RADIUS',{actor=entry.identity.label,id=entry.identity.id},ts);entry.wasInRadius=false
  end
  if not model.Parent then t.inspectActorCache[model]=nil end
 end
 t.nextActorRefresh=ts+1
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
    if ts>=(t.nextActorRefresh or 0)then Core.inspectRefresh(t,ts)end
    local sample={t=r(ts),actors={}}
    for _,entry in ipairs(t.inspectActors or {})do
        local a=entry.identity
        if not a.model.Parent or not a.hum.Parent or not a.root.Parent or(a.role~='self'and(a.root.Position-t.rigObj.root.Position).Magnitude>CFG.INSPECT_RADIUS)then
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
    if not t or (t.kind~='INSPECT' and t.kind~='GAME') or not t.inspector then return end
    if #t.events>=(t.kind=='GAME' and CFG.GAME_MAX_EVENTS or CFG.INSPECT_MAX_EVENTS) then t.inspector.truncated=true;t.inspector.dropped+=1;return end
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
    t.inspectActors=nil;t.inspectActorCache=nil;t.inspectActiveIDs=nil -- Runtime Instances MUST NOT be saved into JSON.
end
-- Game Recorder v7.1.2: F3 coordinates original motion, grouped VFX, highlights, selected
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

local GROUP_CODEC_SOURCE=[====[
local Codec={}
local MESHES={}
local meshCount=0
local VISUAL={Model=true,Folder=true,Part=true,MeshPart=true,WedgePart=true,CornerWedgePart=true,UnionOperation=true,Attachment=true,Smoke=true,Fire=true,Sparkles=true,SpecialMesh=true,BlockMesh=true,CylinderMesh=true,ParticleEmitter=true,Beam=true,Trail=true,Decal=true,Texture=true,SurfaceAppearance=true,PointLight=true,SpotLight=true,SurfaceLight=true,SurfaceGui=true,BillboardGui=true,Frame=true,CanvasGroup=true,ImageLabel=true,ImageButton=true,UICorner=true,UIStroke=true,UIGradient=true,UIAspectRatioConstraint=true,UIScale=true}
local function cfv(v)return v and CFrame.new(table.unpack(v)) or CFrame.identity end
local ENUM_TYPES={Material='Material',MeshType='MeshType',Face='NormalId',EmissionDirection='NormalId',Orientation='ParticleOrientation',ShapeInOut='ParticleEmitterShapeInOut',ShapeStyle='ParticleEmitterShapeStyle',FlipbookLayout='ParticleFlipbookLayout',FlipbookMode='ParticleFlipbookMode',TextureMode='TextureMode',AlphaMode='AlphaMode',SizingMode='SurfaceGuiSizingMode',ScaleType='ScaleType',ResampleMode='ResamplerMode',ZIndexBehavior='ZIndexBehavior',SizeConstraint='SizeConstraint',AutomaticSize='AutomaticSize',BorderMode='BorderMode',ApplyStrokeMode='ApplyStrokeMode',LineJoinMode='LineJoinMode',AspectType='AspectType',DominantAxis='DominantAxis'}
local function enumValue(value,property,className)
 local a=value.v or {};local family=a[1]or a['1'];local name=a[2]or a['2']
 if not family then family=property=='Shape'and (className=='ParticleEmitter'and 'ParticleEmitterShape'or 'PartType')or ENUM_TYPES[property]end
 if type(family)~='string'or type(name)~='string'then return nil end
 local ok,item=pcall(function()return Enum[family][name]end);return ok and item or nil
end
local function val(v,property,className)
 if type(v)~='table' or not v.k then return v end
 local a=v.v
 if v.k=='CFrame'then return cfv(a)
 elseif v.k=='Vector2'then return Vector2.new(a[1],a[2])
 elseif v.k=='Vector3'then return Vector3.new(a[1],a[2],a[3])
 elseif v.k=='UDim'then return UDim.new(a[1],a[2])
 elseif v.k=='UDim2'then return UDim2.new(a[1],a[2],a[3],a[4])
 elseif v.k=='Rect'then return Rect.new(a[1],a[2],a[3],a[4])
 elseif v.k=='Color3'then return Color3.new(a[1],a[2],a[3])
 elseif v.k=='NumberRange'then return NumberRange.new(a[1],a[2])
 elseif v.k=='NumberSequence'then local r={};for _,x in ipairs(a)do r[#r+1]=NumberSequenceKeypoint.new(x[1],x[2],x[3])end;return NumberSequence.new(r)
 elseif v.k=='ColorSequence'then local r={};for _,x in ipairs(a)do r[#r+1]=ColorSequenceKeypoint.new(x[1],Color3.new(table.unpack(x[2])))end;return ColorSequence.new(r)
 elseif v.k=='Enum'then return enumValue(v,property,className)end
end
local function mesh(n)
 local id=n.props and n.props.MeshId
 if type(id)~='string'or id==''then return nil end
 if MESHES[id]==nil then
  if meshCount>=512 then MESHES[id]=false;return nil end
  meshCount+=1;MESHES[id]=false
  local ok,m=pcall(function()return game:GetService('AssetService'):CreateMeshPartAsync(Content.fromUri(id),{CollisionFidelity=Enum.CollisionFidelity.Box,RenderFidelity=Enum.RenderFidelity.Automatic})end)
  if ok then MESHES[id]=m end
 end
 return MESHES[id]or nil
end

function Codec.clearCache()
 for _,mesh in pairs(MESHES)do if mesh then mesh:Destroy()end end
 MESHES={};meshCount=0
end
function Codec.rememberMesh(object)
 local id=object.MeshId
 if type(id)~='string'or id==''or MESHES[id]or meshCount>=512 then return end
 local ok,copy=pcall(function()return object:Clone()end)
 if ok and copy then copy:ClearAllChildren();MESHES[id]=copy;meshCount+=1 end
end
function Codec.burst(h,guess,only)
 for _,object in pairs(only or h.nodes)do
  if object:IsA('ParticleEmitter')and (not object.Enabled or object.Rate==0)then
   local authored=tonumber(object:GetAttribute('EmitCount'))or tonumber(object:GetAttribute('EmitAmount'))
   if authored or guess then
    local n=authored or 12
    object:SetAttribute('GC_EstimatedBurst',not authored)
    object:SetAttribute('GC_EmissionSource',authored and 'AuthoredCountHint' or 'Guessed')
    pcall(function()object:Emit(math.clamp(math.floor(n),0,200))end)
   end
  end
 end
end
function Codec.retire(h)
 if not h or not h.folder then return end
 -- Preserve at least a rendered frame for observed sub-frame burst snapshots.
 -- Timing metadata remains untouched; this is an explicitly estimated preview.
 local delay=math.max(0,1/30-(os.clock()-(h.createdAt or 0)))
 if delay>0 then task.delay(delay,function()if h.folder then h.folder:Destroy()end end)
 else h.folder:Destroy()end
end

function Codec.preload(snapshot)
 for _,n in ipairs(snapshot.nodes or {})do if n.class=='MeshPart'then mesh(n)end end
end
local function make(n)
 if not VISUAL[n.class]then return nil end
 if n.class=='MeshPart'then
  local m=mesh(n);if m then return m:Clone()end
  local p=Instance.new('Part');p:SetAttribute('GC_MissingMesh',n.props and n.props.MeshId or 'Unavailable');p.Color=Color3.fromRGB(240,150,50);return p
 elseif n.class=='UnionOperation'then
  local p=Instance.new('Part');p:SetAttribute('GC_MissingGeometry','CSG cannot be reconstructed from observable properties');return p
 end
 local ok,o=pcall(Instance.new,n.class);return ok and o or nil
end
local function props(o,p,inactive)
 for k,v in pairs(p or {})do
  if k~='MeshId'and (k~='CFrame'or o:IsA('Attachment'))and k~='Parent'and k~='Enabled'then
   pcall(function()o[k]=val(v,k,o.ClassName)end)
  end
 end
 if o:IsA('BasePart')then o.Anchored=true;o.CanCollide=false;o.CanTouch=false;o.CanQuery=false end
 if o:IsA('ParticleEmitter')or o:IsA('Beam')or o:IsA('Trail')or o:IsA('Light')or o:IsA('Smoke')or o:IsA('Fire')or o:IsA('Sparkles')or o:IsA('SurfaceGui')or o:IsA('BillboardGui')or o:IsA('UIGradient')or o:IsA('UIStroke')then
  if inactive then o.Enabled=false elseif p.Enabled~=nil then o.Enabled=p.Enabled end
 end
end
function Codec.create(snapshot,origin,inactive,parent)
 local h={folder=Instance.new('Model'),nodes={},origin=origin,inactive=inactive,defs={},errors={},createdAt=os.clock()}
 h.folder.Name=snapshot.name or 'RecordedVFX'
 -- Build a single parent/child hierarchy; never include scripts or external welds.
 for _,n in ipairs(snapshot.nodes or {})do
  local o=make(n)
  if o then h.nodes[n.id]=o;h.defs[n.id]=n;o.Name=n.name or n.class;props(o,n.props,inactive)
  else h.errors[#h.errors+1]='Unsupported node '..tostring(n.class)end
 end
 for _,n in ipairs(snapshot.nodes or {})do
  local o=h.nodes[n.id]
  if o then
   local p=h.nodes[n.parent]or h.folder
   if o:IsA('Attachment')and not (p:IsA('BasePart')or p:IsA('Attachment'))then
    local anchor=Instance.new('Part');anchor.Name='GC_ExternalAttachmentAnchor';anchor.Size=Vector3.new(.1,.1,.1);anchor.Transparency=1;anchor.Anchored=true;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false;anchor.CFrame=origin;anchor.Parent=h.folder;p=anchor
   end
   o.Parent=p
   if o:IsA('BasePart')and n.cf then o.CFrame=origin*cfv(n.cf)
   elseif o:IsA('Attachment')then o.CFrame=val(n.props and n.props.CFrame)or CFrame.identity end
   for k,v in pairs(n.attrs or {})do pcall(function()o:SetAttribute(k,val(v))end)end
  end
 end
 for _,n in ipairs(snapshot.nodes or {})do local o=h.nodes[n.id];if o then for k,id in pairs(n.refs or {})do if h.nodes[id]then pcall(function()o[k]=h.nodes[id]end)end end end end
 h.folder.Parent=parent
 return h
end
-- Structure snapshots with source identity keep live particles/trails intact.
function Codec.sync(h,snapshot,origin,inactive,parent)
 if not h or not snapshot.stableNodes then
  if h and h.folder then h.folder:Destroy()end
  local fresh=Codec.create(snapshot,origin,inactive,parent)
  return fresh,fresh.nodes
 end
 local byKey={}
 for id,definition in pairs(h.defs)do
  local object=h.nodes[id]
  if object and definition.captureKey then byKey[definition.captureKey]={object=object,class=definition.class}end
 end
 local oldNodes=h.nodes;local nodes,defs,added,kept={},{},{},{}
 for _,n in ipairs(snapshot.nodes or {})do
  local prior=n.captureKey and byKey[n.captureKey]
  local object=prior and prior.class==n.class and prior.object or nil
  if not object then object=make(n);if object then added[n.id]=object end end
  if object then
   nodes[n.id]=object;defs[n.id]=n;kept[object]=true
   object.Name=n.name or n.class;props(object,n.props,inactive)
  else h.errors[#h.errors+1]='Unsupported node '..tostring(n.class)end
 end
 -- Move retained descendants before deleting removed ancestors.
 for _,n in ipairs(snapshot.nodes or {})do
  local object=nodes[n.id]
  if object then
   local holder=nodes[n.parent]or h.folder
   if object:IsA('Attachment')and not(holder:IsA('BasePart')or holder:IsA('Attachment'))then
    local anchor=object.Parent
    if not anchor or anchor.Name~='GC_ExternalAttachmentAnchor'or not anchor:IsDescendantOf(h.folder)then
     anchor=Instance.new('Part');anchor.Name='GC_ExternalAttachmentAnchor';anchor.Size=Vector3.new(.1,.1,.1);anchor.Transparency=1;anchor.Anchored=true;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false;anchor.CFrame=origin;anchor.Parent=h.folder
    end
    holder=anchor
   end
   object.Parent=holder
   if object:IsA('BasePart')and n.cf then object.CFrame=origin*cfv(n.cf)
   elseif object:IsA('Attachment')then object.CFrame=val(n.props and n.props.CFrame)or CFrame.identity end
   for k,v in pairs(n.attrs or {})do pcall(function()object:SetAttribute(k,val(v))end)end
  end
 end
 for _,object in pairs(oldNodes)do if not kept[object]then object:Destroy()end end
 for _,n in ipairs(snapshot.nodes or {})do
  local object=nodes[n.id]
  if object then for k,id in pairs(n.refs or {})do pcall(function()object[k]=nodes[id]end)end end
 end
 h.nodes=nodes;h.defs=defs;h.origin=origin;h.inactive=inactive;h.folder.Name=snapshot.name or 'RecordedVFX'
 return h,added
end
function Codec.update(h,delta)
 local o=h.nodes[delta.id];if not o then return end
 if delta.remove then o:Destroy();h.nodes[delta.id]=nil;return end
 if delta.parent then o.Parent=h.nodes[delta.parent]or h.folder end
 if delta.name then o.Name=delta.name end
 if delta.props then props(o,delta.props,h.inactive)end
 if delta.cf and o:IsA('BasePart')then o.CFrame=h.origin*cfv(delta.cf)end
 if delta.attachmentCF and o:IsA('Attachment')then o.CFrame=cfv(delta.attachmentCF)end
 if delta.refs then for k,id in pairs(delta.refs)do pcall(function()o[k]=h.nodes[id]end)end end
end
-- Smooth only sampled transforms/continuous properties; spawn, removal and toggles remain discrete.
function Codec.prepare(events)
 local prepared,active={},{}
 local allowed={Size=true,Scale=true,Offset=true,Transparency=true,Width0=true,Width1=true,CurveSize0=true,CurveSize1=true,TextureLength=true,Brightness=true,Range=true,CFrame=true,Position=true,AnchorPoint=true,Rotation=true,ImageTransparency=true,BackgroundTransparency=true,GroupTransparency=true,ImageColor3=true,BackgroundColor3=true,GroupColor3=true}
 local function add(epoch,id,property,value,time)
  if not value then return end
  local kind=type(value)=='number'and 'number' or (type(value)=='table'and value.k)
  if kind~='number'and kind~='Vector3'and kind~='CFrame'and kind~='UDim2'and kind~='Vector2'and kind~='Color3'then return end
  local key=tostring(id)..'/'..property;local channel=epoch.channels[key]
  if not channel then channel={id=id,property=property,kind=kind,keys={}};epoch.channels[key]=channel end
  local last=channel.keys[#channel.keys]
  local point={t=time,value=value}
  if last and last.t==time then channel.keys[#channel.keys]=point else channel.keys[#channel.keys+1]=point end
 end
 for _,event in ipairs(events or {})do
  if event.op=='group_spawn'then
   local epoch={channels={}};prepared[event]=epoch;active[event.id]=epoch
   for _,node in ipairs(event.snapshot.nodes or {})do
    if node.cf then add(epoch,node.id,'@world',{k='CFrame',v=node.cf},event.t)end
    for property,value in pairs(node.props or {})do if allowed[property]then add(epoch,node.id,property,value,event.t)end end
   end
  elseif event.op=='group_update'and active[event.id]then
   local epoch=active[event.id]
   for _,delta in ipairs(event.changes or {})do
    if delta.cf then add(epoch,delta.id,'@world',{k='CFrame',v=delta.cf},event.t)end
    if delta.attachmentCF then add(epoch,delta.id,'CFrame',{k='CFrame',v=delta.attachmentCF},event.t)end
    for property,value in pairs(delta.props or {})do if allowed[property]then add(epoch,delta.id,property,value,event.t)end end
   end
  elseif event.op=='group_remove'then active[event.id]=nil end
 end
 return prepared
end
function Codec.sample(h,time)
 if not h.curves then return end
 for _,channel in pairs(h.curves.channels)do
  local object=h.nodes[channel.id];local keys=channel.keys
  if object and #keys>1 and time>=keys[1].t then
   local low,high=1,#keys
   while low<high do local middle=math.floor((low+high+1)/2);if keys[middle].t<=time then low=middle else high=middle-1 end end
   local a,b=keys[low],keys[math.min(low+1,#keys)]
   local x=b.t>a.t and math.clamp((time-a.t)/(b.t-a.t),0,1)or 0
   local value
   if channel.kind=='number'then value=a.value+(b.value-a.value)*x
   else value=val(a.value):Lerp(val(b.value),x)end
   if channel.property=='@world'then object.CFrame=h.origin*value
   else pcall(function()object[channel.property]=value end)end
  end
 end
end

]====]
local GROUP_REPLAY_SOURCE=[====[
local RunService=game:GetService('RunService')
local Http=game:GetService('HttpService')


local Codec={}
local MESHES={}
local meshCount=0
local VISUAL={Model=true,Folder=true,Part=true,MeshPart=true,WedgePart=true,CornerWedgePart=true,UnionOperation=true,Attachment=true,Smoke=true,Fire=true,Sparkles=true,SpecialMesh=true,BlockMesh=true,CylinderMesh=true,ParticleEmitter=true,Beam=true,Trail=true,Decal=true,Texture=true,SurfaceAppearance=true,PointLight=true,SpotLight=true,SurfaceLight=true,SurfaceGui=true,BillboardGui=true,Frame=true,CanvasGroup=true,ImageLabel=true,ImageButton=true,UICorner=true,UIStroke=true,UIGradient=true,UIAspectRatioConstraint=true,UIScale=true}
local function cfv(v)return v and CFrame.new(table.unpack(v)) or CFrame.identity end
local ENUM_TYPES={Material='Material',MeshType='MeshType',Face='NormalId',EmissionDirection='NormalId',Orientation='ParticleOrientation',ShapeInOut='ParticleEmitterShapeInOut',ShapeStyle='ParticleEmitterShapeStyle',FlipbookLayout='ParticleFlipbookLayout',FlipbookMode='ParticleFlipbookMode',TextureMode='TextureMode',AlphaMode='AlphaMode',SizingMode='SurfaceGuiSizingMode',ScaleType='ScaleType',ResampleMode='ResamplerMode',ZIndexBehavior='ZIndexBehavior',SizeConstraint='SizeConstraint',AutomaticSize='AutomaticSize',BorderMode='BorderMode',ApplyStrokeMode='ApplyStrokeMode',LineJoinMode='LineJoinMode',AspectType='AspectType',DominantAxis='DominantAxis'}
local function enumValue(value,property,className)
 local a=value.v or {};local family=a[1]or a['1'];local name=a[2]or a['2']
 if not family then family=property=='Shape'and (className=='ParticleEmitter'and 'ParticleEmitterShape'or 'PartType')or ENUM_TYPES[property]end
 if type(family)~='string'or type(name)~='string'then return nil end
 local ok,item=pcall(function()return Enum[family][name]end);return ok and item or nil
end
local function val(v,property,className)
 if type(v)~='table' or not v.k then return v end
 local a=v.v
 if v.k=='CFrame'then return cfv(a)
 elseif v.k=='Vector2'then return Vector2.new(a[1],a[2])
 elseif v.k=='Vector3'then return Vector3.new(a[1],a[2],a[3])
 elseif v.k=='UDim'then return UDim.new(a[1],a[2])
 elseif v.k=='UDim2'then return UDim2.new(a[1],a[2],a[3],a[4])
 elseif v.k=='Rect'then return Rect.new(a[1],a[2],a[3],a[4])
 elseif v.k=='Color3'then return Color3.new(a[1],a[2],a[3])
 elseif v.k=='NumberRange'then return NumberRange.new(a[1],a[2])
 elseif v.k=='NumberSequence'then local r={};for _,x in ipairs(a)do r[#r+1]=NumberSequenceKeypoint.new(x[1],x[2],x[3])end;return NumberSequence.new(r)
 elseif v.k=='ColorSequence'then local r={};for _,x in ipairs(a)do r[#r+1]=ColorSequenceKeypoint.new(x[1],Color3.new(table.unpack(x[2])))end;return ColorSequence.new(r)
 elseif v.k=='Enum'then return enumValue(v,property,className)end
end
local function mesh(n)
 local id=n.props and n.props.MeshId
 if type(id)~='string'or id==''then return nil end
 if MESHES[id]==nil then
  if meshCount>=512 then MESHES[id]=false;return nil end
  meshCount+=1;MESHES[id]=false
  local ok,m=pcall(function()return game:GetService('AssetService'):CreateMeshPartAsync(Content.fromUri(id),{CollisionFidelity=Enum.CollisionFidelity.Box,RenderFidelity=Enum.RenderFidelity.Automatic})end)
  if ok then MESHES[id]=m end
 end
 return MESHES[id]or nil
end

function Codec.clearCache()
 for _,mesh in pairs(MESHES)do if mesh then mesh:Destroy()end end
 MESHES={};meshCount=0
end
function Codec.rememberMesh(object)
 local id=object.MeshId
 if type(id)~='string'or id==''or MESHES[id]or meshCount>=512 then return end
 local ok,copy=pcall(function()return object:Clone()end)
 if ok and copy then copy:ClearAllChildren();MESHES[id]=copy;meshCount+=1 end
end
function Codec.burst(h,guess,only)
 for _,object in pairs(only or h.nodes)do
  if object:IsA('ParticleEmitter')and (not object.Enabled or object.Rate==0)then
   local authored=tonumber(object:GetAttribute('EmitCount'))or tonumber(object:GetAttribute('EmitAmount'))
   if authored or guess then
    local n=authored or 12
    object:SetAttribute('GC_EstimatedBurst',not authored)
    object:SetAttribute('GC_EmissionSource',authored and 'AuthoredCountHint' or 'Guessed')
    pcall(function()object:Emit(math.clamp(math.floor(n),0,200))end)
   end
  end
 end
end
function Codec.retire(h)
 if not h or not h.folder then return end
 -- Preserve at least a rendered frame for observed sub-frame burst snapshots.
 -- Timing metadata remains untouched; this is an explicitly estimated preview.
 local delay=math.max(0,1/30-(os.clock()-(h.createdAt or 0)))
 if delay>0 then task.delay(delay,function()if h.folder then h.folder:Destroy()end end)
 else h.folder:Destroy()end
end

function Codec.preload(snapshot)
 for _,n in ipairs(snapshot.nodes or {})do if n.class=='MeshPart'then mesh(n)end end
end
local function make(n)
 if not VISUAL[n.class]then return nil end
 if n.class=='MeshPart'then
  local m=mesh(n);if m then return m:Clone()end
  local p=Instance.new('Part');p:SetAttribute('GC_MissingMesh',n.props and n.props.MeshId or 'Unavailable');p.Color=Color3.fromRGB(240,150,50);return p
 elseif n.class=='UnionOperation'then
  local p=Instance.new('Part');p:SetAttribute('GC_MissingGeometry','CSG cannot be reconstructed from observable properties');return p
 end
 local ok,o=pcall(Instance.new,n.class);return ok and o or nil
end
local function props(o,p,inactive)
 for k,v in pairs(p or {})do
  if k~='MeshId'and (k~='CFrame'or o:IsA('Attachment'))and k~='Parent'and k~='Enabled'then
   pcall(function()o[k]=val(v,k,o.ClassName)end)
  end
 end
 if o:IsA('BasePart')then o.Anchored=true;o.CanCollide=false;o.CanTouch=false;o.CanQuery=false end
 if o:IsA('ParticleEmitter')or o:IsA('Beam')or o:IsA('Trail')or o:IsA('Light')or o:IsA('Smoke')or o:IsA('Fire')or o:IsA('Sparkles')or o:IsA('SurfaceGui')or o:IsA('BillboardGui')or o:IsA('UIGradient')or o:IsA('UIStroke')then
  if inactive then o.Enabled=false elseif p.Enabled~=nil then o.Enabled=p.Enabled end
 end
end
function Codec.create(snapshot,origin,inactive,parent)
 local h={folder=Instance.new('Model'),nodes={},origin=origin,inactive=inactive,defs={},errors={},createdAt=os.clock()}
 h.folder.Name=snapshot.name or 'RecordedVFX'
 -- Build a single parent/child hierarchy; never include scripts or external welds.
 for _,n in ipairs(snapshot.nodes or {})do
  local o=make(n)
  if o then h.nodes[n.id]=o;h.defs[n.id]=n;o.Name=n.name or n.class;props(o,n.props,inactive)
  else h.errors[#h.errors+1]='Unsupported node '..tostring(n.class)end
 end
 for _,n in ipairs(snapshot.nodes or {})do
  local o=h.nodes[n.id]
  if o then
   local p=h.nodes[n.parent]or h.folder
   if o:IsA('Attachment')and not (p:IsA('BasePart')or p:IsA('Attachment'))then
    local anchor=Instance.new('Part');anchor.Name='GC_ExternalAttachmentAnchor';anchor.Size=Vector3.new(.1,.1,.1);anchor.Transparency=1;anchor.Anchored=true;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false;anchor.CFrame=origin;anchor.Parent=h.folder;p=anchor
   end
   o.Parent=p
   if o:IsA('BasePart')and n.cf then o.CFrame=origin*cfv(n.cf)
   elseif o:IsA('Attachment')then o.CFrame=val(n.props and n.props.CFrame)or CFrame.identity end
   for k,v in pairs(n.attrs or {})do pcall(function()o:SetAttribute(k,val(v))end)end
  end
 end
 for _,n in ipairs(snapshot.nodes or {})do local o=h.nodes[n.id];if o then for k,id in pairs(n.refs or {})do if h.nodes[id]then pcall(function()o[k]=h.nodes[id]end)end end end end
 h.folder.Parent=parent
 return h
end
-- Structure snapshots with source identity keep live particles/trails intact.
function Codec.sync(h,snapshot,origin,inactive,parent)
 if not h or not snapshot.stableNodes then
  if h and h.folder then h.folder:Destroy()end
  local fresh=Codec.create(snapshot,origin,inactive,parent)
  return fresh,fresh.nodes
 end
 local byKey={}
 for id,definition in pairs(h.defs)do
  local object=h.nodes[id]
  if object and definition.captureKey then byKey[definition.captureKey]={object=object,class=definition.class}end
 end
 local oldNodes=h.nodes;local nodes,defs,added,kept={},{},{},{}
 for _,n in ipairs(snapshot.nodes or {})do
  local prior=n.captureKey and byKey[n.captureKey]
  local object=prior and prior.class==n.class and prior.object or nil
  if not object then object=make(n);if object then added[n.id]=object end end
  if object then
   nodes[n.id]=object;defs[n.id]=n;kept[object]=true
   object.Name=n.name or n.class;props(object,n.props,inactive)
  else h.errors[#h.errors+1]='Unsupported node '..tostring(n.class)end
 end
 -- Move retained descendants before deleting removed ancestors.
 for _,n in ipairs(snapshot.nodes or {})do
  local object=nodes[n.id]
  if object then
   local holder=nodes[n.parent]or h.folder
   if object:IsA('Attachment')and not(holder:IsA('BasePart')or holder:IsA('Attachment'))then
    local anchor=object.Parent
    if not anchor or anchor.Name~='GC_ExternalAttachmentAnchor'or not anchor:IsDescendantOf(h.folder)then
     anchor=Instance.new('Part');anchor.Name='GC_ExternalAttachmentAnchor';anchor.Size=Vector3.new(.1,.1,.1);anchor.Transparency=1;anchor.Anchored=true;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false;anchor.CFrame=origin;anchor.Parent=h.folder
    end
    holder=anchor
   end
   object.Parent=holder
   if object:IsA('BasePart')and n.cf then object.CFrame=origin*cfv(n.cf)
   elseif object:IsA('Attachment')then object.CFrame=val(n.props and n.props.CFrame)or CFrame.identity end
   for k,v in pairs(n.attrs or {})do pcall(function()object:SetAttribute(k,val(v))end)end
  end
 end
 for _,object in pairs(oldNodes)do if not kept[object]then object:Destroy()end end
 for _,n in ipairs(snapshot.nodes or {})do
  local object=nodes[n.id]
  if object then for k,id in pairs(n.refs or {})do pcall(function()object[k]=nodes[id]end)end end
 end
 h.nodes=nodes;h.defs=defs;h.origin=origin;h.inactive=inactive;h.folder.Name=snapshot.name or 'RecordedVFX'
 return h,added
end
function Codec.update(h,delta)
 local o=h.nodes[delta.id];if not o then return end
 if delta.remove then o:Destroy();h.nodes[delta.id]=nil;return end
 if delta.parent then o.Parent=h.nodes[delta.parent]or h.folder end
 if delta.name then o.Name=delta.name end
 if delta.props then props(o,delta.props,h.inactive)end
 if delta.cf and o:IsA('BasePart')then o.CFrame=h.origin*cfv(delta.cf)end
 if delta.attachmentCF and o:IsA('Attachment')then o.CFrame=cfv(delta.attachmentCF)end
 if delta.refs then for k,id in pairs(delta.refs)do pcall(function()o[k]=h.nodes[id]end)end end
end

-- Smooth only sampled transforms/continuous properties; spawn, removal and toggles remain discrete.
function Codec.prepare(events)
 local prepared,active={},{}
 local allowed={Size=true,Scale=true,Offset=true,Transparency=true,Width0=true,Width1=true,CurveSize0=true,CurveSize1=true,TextureLength=true,Brightness=true,Range=true,CFrame=true,Position=true,AnchorPoint=true,Rotation=true,ImageTransparency=true,BackgroundTransparency=true,GroupTransparency=true,ImageColor3=true,BackgroundColor3=true,GroupColor3=true}
 local function add(epoch,id,property,value,time)
  if not value then return end
  local kind=type(value)=='number'and 'number' or (type(value)=='table'and value.k)
  if kind~='number'and kind~='Vector3'and kind~='CFrame'and kind~='UDim2'and kind~='Vector2'and kind~='Color3'then return end
  local key=tostring(id)..'/'..property;local channel=epoch.channels[key]
  if not channel then channel={id=id,property=property,kind=kind,keys={}};epoch.channels[key]=channel end
  local last=channel.keys[#channel.keys]
  local point={t=time,value=value}
  if last and last.t==time then channel.keys[#channel.keys]=point else channel.keys[#channel.keys+1]=point end
 end
 for _,event in ipairs(events or {})do
  if event.op=='group_spawn'then
   local epoch={channels={}};prepared[event]=epoch;active[event.id]=epoch
   for _,node in ipairs(event.snapshot.nodes or {})do
    if node.cf then add(epoch,node.id,'@world',{k='CFrame',v=node.cf},event.t)end
    for property,value in pairs(node.props or {})do if allowed[property]then add(epoch,node.id,property,value,event.t)end end
   end
  elseif event.op=='group_update'and active[event.id]then
   local epoch=active[event.id]
   for _,delta in ipairs(event.changes or {})do
    if delta.cf then add(epoch,delta.id,'@world',{k='CFrame',v=delta.cf},event.t)end
    if delta.attachmentCF then add(epoch,delta.id,'CFrame',{k='CFrame',v=delta.attachmentCF},event.t)end
    for property,value in pairs(delta.props or {})do if allowed[property]then add(epoch,delta.id,property,value,event.t)end end
   end
  elseif event.op=='group_remove'then active[event.id]=nil end
 end
 return prepared
end
function Codec.sample(h,time)
 if not h.curves then return end
 for _,channel in pairs(h.curves.channels)do
  local object=h.nodes[channel.id];local keys=channel.keys
  if object and #keys>1 and time>=keys[1].t then
   local low,high=1,#keys
   while low<high do local middle=math.floor((low+high+1)/2);if keys[middle].t<=time then low=middle else high=middle-1 end end
   local a,b=keys[low],keys[math.min(low+1,#keys)]
   local x=b.t>a.t and math.clamp((time-a.t)/(b.t-a.t),0,1)or 0
   local value
   if channel.kind=='number'then value=a.value+(b.value-a.value)*x
   else value=val(a.value):Lerp(val(b.value),x)end
   if channel.property=='@world'then object.CFrame=h.origin*value
   else pcall(function()object[channel.property]=value end)end
  end
 end
end

local M={}
local function cf(a)return a and CFrame.new(table.unpack(a))or CFrame.identity end
function M.Start(origin,lift)
 assert(RunService:IsStudio(),'This preview is for Studio authoring only')
 assert(typeof(origin)=='CFrame','Pass the desired recording-root CFrame')
 local chunks={};for _,v in ipairs(script.Parent:GetChildren())do if v:IsA('StringValue')and v.Name:match('^FULL_TAKE_')then chunks[#chunks+1]=v end end
 table.sort(chunks,function(a,b)return a.Name<b.Name end)
 local strings={};for _,v in ipairs(chunks)do strings[#strings+1]=v.Value end
 local data=Http:JSONDecode(table.concat(strings))
 if data.kind=='VFX'then
  local height=tonumber(lift)or tonumber(data.previewHeight)or 4
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.IgnoreWater=true;params.RespectCanCollide=true
  local player=game:GetService('Players').LocalPlayer;params.FilterDescendantsInstances=player and player.Character and {player.Character}or {}
  local floor=workspace:Raycast(origin.Position+Vector3.new(0,8,0),Vector3.new(0,-2048,0),params)
  if floor and floor.Normal.Y>.2 then
   local p=origin.Position;origin=CFrame.new(p.X,floor.Position.Y+(data.groundReference and data.groundReference.height or 3)+height,p.Z)*origin.Rotation
  else origin=origin*CFrame.new(0,height,0)end
 end
 if M.active then M.active.Stop()end
 local folder=Instance.new('Folder');folder.Name='GC_TakePreview';folder.Parent=workspace
 local parts,effects={},{};local renderCurves=Codec.prepare(data.vfx or {})
 local connection;local alive=true
 local handle={}
 local function stop()if not alive then return end;alive=false;if connection then connection:Disconnect()end;folder:Destroy();if M.active==handle then M.active=nil end end
 if data.kind=='ANIM'then
  for _,c in ipairs(data.channels or {})do
   local p=Instance.new('Part');p.Name=c.child;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
   local size=data.metrics and data.metrics[c.child]and data.metrics[c.child].size
   p.Size=size and Vector3.new(table.unpack(size))or Vector3.new(1,2,1);p.Color=Color3.fromRGB(180,195,210);p.Parent=folder;parts[c.child]=p
  end
 else
  for _,e in ipairs(data.vfx or {})do if e.op=='group_spawn'then Codec.preload(e.snapshot)end end
 end
 local begun=os.clock();local eventIndex=1;local frameIndex=1
 local function tick()
  local age=math.min(os.clock()-begun,data.duration or 0)
  if data.kind=='ANIM'then
   local frames=data.frames
   while frameIndex<#frames-1 and frames[frameIndex+1].t<age do frameIndex+=1 end
   local a,b=frames[frameIndex],frames[math.min(frameIndex+1,#frames)]
   local x=b.t>a.t and math.clamp((age-a.t)/(b.t-a.t),0,1)or 0
   local root=origin*cf(a.root):Lerp(cf(b.root),x)
   for name,p in pairs(parts)do
    if a.parts and b.parts and a.parts[name]and b.parts[name]then p.CFrame=root*cf(a.parts[name]):Lerp(cf(b.parts[name]),x)end
   end
  else
   while eventIndex<=#(data.vfx or {})and data.vfx[eventIndex].t<=age do
    local e=data.vfx[eventIndex];local h=effects[e.id]
    if e.op=='group_spawn'then
     local added
     if e.replace and e.snapshot.stableNodes and h then h,added=Codec.sync(h,e.snapshot,origin,false,folder)
     else if h then h.folder:Destroy()end;h=Codec.create(e.snapshot,origin,false,folder)end
     effects[e.id]=h;h.curves=renderCurves[e]
     if not e.replace or added then Codec.burst(h,data.previewUnknownBursts==true,added)end
    elseif e.op=='group_update'and h then for _,d in ipairs(e.changes or {})do Codec.update(h,d)end
    elseif e.op=='group_remove'and h then Codec.retire(h);effects[e.id]=nil end
    eventIndex+=1
   end
   for _,effect in pairs(effects)do Codec.sample(effect,age)end
  end
  if age>=(data.duration or 0)and connection then connection:Disconnect();connection=nil end
 end
 handle.Model=folder;handle.Stop=stop;M.active=handle
 tick();if (data.duration or 0)>0 then connection=RunService.Heartbeat:Connect(tick)end
 return handle
end
return M
]====]

 function Core.studioGroupedImporter(data)
 local exportData=table.clone(data);exportData.previewUnknownBursts=estimateBurstPreview==true
 local raw=Core.exportJson(exportData);if not raw then return nil end
 local eq='====';while raw:find(']'..eq..']',1,true)do eq=eq..'='end
 local head="-- V6 GROUPED VISUAL IMPORT: run only in an authorized Studio place, Edit mode.\nassert(not game:GetService('RunService'):IsRunning(),'Stop Play before importing')\nlocal data=game:GetService('HttpService'):JSONDecode(["..eq.."["..raw.."]"..eq.."] )\n"
 local tail=[==[
local RS=game:GetService('ReplicatedStorage')
local owner=Instance.new('Folder');owner.Name='GC_GroupedVFX_'..tostring(data.name or 'Take'):gsub('[^%w_]','_');owner.Parent=RS
local chunks=game:GetService('HttpService'):JSONEncode(data)
for i=1,#chunks,120000 do local s=Instance.new('StringValue');s.Name=string.format('FULL_TAKE_%04d',math.floor((i-1)/120000)+1);s.Value=chunks:sub(i,i+119999);s.Parent=owner end
local latest={};for _,e in ipairs(data.vfx or {})do if e.op=='group_spawn'then latest[e.id]=e end end
local count=0
for id,e in pairs(latest)do
 Codec.preload(e.snapshot)
 local h=Codec.create(e.snapshot,CFrame.identity,true,owner);h.folder.Name=string.format('Group_%03d_%s',id,e.snapshot.name or 'Effect')
 h.folder:SetAttribute('SourcePath',e.path or '');h.folder:SetAttribute('RecordedTime',e.t);h.folder:SetAttribute('Truncated',e.snapshot.truncated==true)
 count+=1;if count%4==0 then task.wait()end
end
owner:SetAttribute('GroupedVFXVersion',6)
owner:SetAttribute('RootMotionInFullTake',true)
print('V6: '..count..' whole VFX hierarchies imported. Templates are disabled; FULL_TAKE chunks retain the timed replay, inputs, camera and jump/root data.')
print('MissingMesh / MissingGeometry attributes identify assets not recoverable through normal permissions; scripts and character welds are excluded.')
]==]
 local moduleLine="\nlocal replay=Instance.new('ModuleScript');replay.Name='TakePreview';replay.Source="..string.format('%q',GROUP_REPLAY_SOURCE)..";replay.Parent=owner\nprint('Preview in Studio Play: require(the imported folder.TakePreview).Start(rootCFrame)')\n"
 return head..GROUP_CODEC_SOURCE..tail..moduleLine
end

 function Core.studioImporter(data,target)
    local raw=Core.exportJson(data)
    if not raw then return nil end
    local eq='='
    while string.find(raw,']'..eq..']',1,true) do eq=eq..'=' end
    local prefix=[=[
-- GRAND CLOVER | V6 Studio Command Bar Importer
-- Paste in Roblox Studio's COMMAND BAR while NOT in Play mode.
-- Result: KeyframeSequence in ServerStorage, observed client VFX in ReplicatedStorage.
assert(not game:GetService('RunService'):IsRunning(),'Stop Play before importing')
local HttpService=game:GetService('HttpService')
local ServerStorage=game:GetService('ServerStorage')
local ReplicatedStorage=game:GetService('ReplicatedStorage')
local data=HttpService:JSONDecode(]=]
    local suffix=[=[)
local TARGET=]=]..string.format('%q',target)..[=[
assert((data.version==4 or data.version==5 or data.version==6) and (data.kind==nil or data.kind=='ANIM') and type(data.frames)=='table' and #data.frames>0,'Invalid GC animation recording')
local source=data.rig
local targetParts={
  R6={{'HumanoidRootPart','Torso'},{'Torso','Head'},{'Torso','Right Arm'},
      {'Torso','Left Arm'},{'Torso','Right Leg'},{'Torso','Left Leg'}},
  R15={{'HumanoidRootPart','LowerTorso'},{'LowerTorso','UpperTorso'},
       {'UpperTorso','Head'},
       {'UpperTorso','LeftUpperArm'},{'LeftUpperArm','LeftLowerArm'},{'LeftLowerArm','LeftHand'},
       {'UpperTorso','RightUpperArm'},{'RightUpperArm','RightLowerArm'},{'RightLowerArm','RightHand'},
       {'LowerTorso','LeftUpperLeg'},{'LeftUpperLeg','LeftLowerLeg'},{'LeftLowerLeg','LeftFoot'},
       {'LowerTorso','RightUpperLeg'},{'RightUpperLeg','RightLowerLeg'},{'RightLowerLeg','RightFoot'}},
}
local function cf(v)
  if not v then return CFrame.new() end
  return CFrame.new(table.unpack(v))
end
local function sampleAt(t)
  local frames=data.frames
  if t<=frames[1].t then return frames[1],frames[1],0 end
  if t>=frames[#frames].t then return frames[#frames],frames[#frames],0 end
  local lo,hi=1,#frames
  while hi-lo>1 do
    local m=math.floor((lo+hi)/2)
    if frames[m].t<=t then lo=m else hi=m end
  end
  local a,b=frames[lo],frames[hi]
  local alpha=(t-a.t)/(b.t-a.t)
  return a,b,alpha
end
local channelIndex={}
for i,c in ipairs(data.channels) do channelIndex[c.child]=i end
local function sourcePose(frame,name)
  local i=channelIndex[name]
  return i and cf(frame.joints[i]) or CFrame.new()
end
local function mapped(frame,name)
  if source==TARGET then return sourcePose(frame,name) end
  if source=='R6' then
    local keys={LowerTorso='Torso',LeftUpperArm='Left Arm',RightUpperArm='Right Arm',
      LeftUpperLeg='Left Leg',RightUpperLeg='Right Leg',Head='Head'}
    return sourcePose(frame,keys[name] or name)
  end
  local keys={['Left Arm']='LeftUpperArm',['Right Arm']='RightUpperArm',
    ['Left Leg']='LeftUpperLeg',['Right Leg']='RightUpperLeg',Head='Head'}
  if name=='Torso' then return sourcePose(frame,'LowerTorso')*sourcePose(frame,'UpperTorso') end
  return sourcePose(frame,keys[name] or name)
end
local function poseAt(t,child)
  local a,b,alpha=sampleAt(t)
  return mapped(a,child):Lerp(mapped(b,child),alpha)
end
local KFS=Instance.new('KeyframeSequence')
KFS.Name='GC_Baked_'..TARGET..'_'..tostring(data.name)
KFS.Priority=Enum.AnimationPriority.Action
KFS.Loop=false
KFS:SetAttribute('SourceRig',source)
KFS:SetAttribute('TargetRig',TARGET)
KFS:SetAttribute('CrossRigApproximate',source~=TARGET)
KFS:SetAttribute('RecordingDuration',data.duration)
KFS:SetAttribute('RootMotionStoredSeparately',true)
KFS:SetAttribute('RootMotionSource','Full recorded data in TIMELINE_*; do not add vertical displacement to Torso twice')
KFS:SetAttribute('GCMotionBakerVersion',6)
-- Event times are added to the keyframe times so markers don't shift to frame edges.
local timestamps={}; local at={}
local function addTime(t)
  local tick=math.floor(math.max(0,t)*100000+0.5)
  if not at[tick] then at[tick]={};timestamps[#timestamps+1]=tick end
  return at[tick]
end
for _,fr in ipairs(data.frames) do addTime(fr.t) end
for _,ev in ipairs(data.events or {}) do
  local bucket=addTime(ev.t);bucket[#bucket+1]={type='motion',e=ev}
end
for _,ev in ipairs(data.vfx or {}) do
  local bucket=addTime(ev.t);bucket[#bucket+1]={type='vfx',e=ev}
end
table.sort(timestamps)
local shortened=0
for n,tick in ipairs(timestamps) do
  local time=tick/100000
  local k=Instance.new('Keyframe');k.Name=string.format('GC_%05d',n);k.Time=time
  local poses={};local roots={}
  for _,link in ipairs(targetParts[TARGET]) do
    local parent,child=link[1],link[2]
    local p=Instance.new('Pose');p.Name=child;p.CFrame=poseAt(time,child)
    p.EasingStyle=Enum.PoseEasingStyle.Linear;p.Weight=1
    poses[child]=p
  end
  for _,link in ipairs(targetParts[TARGET]) do
    local parent,child=link[1],link[2]
    if poses[parent] then poses[child].Parent=poses[parent]
    else
      if not roots[parent] then
        local root=Instance.new('Pose');root.Name=parent
        root.CFrame=CFrame.new();root.Parent=k;roots[parent]=root
      end
      poses[child].Parent=roots[parent]
    end
  end
  for _,entry in ipairs(at[tick]) do
    local ev=entry.e
    local marker=Instance.new('KeyframeMarker')
    marker.Name=(entry.type=='vfx' and 'VFX_'..ev.op or ev.type)
    marker.Value=HttpService:JSONEncode(ev)
    k:AddMarker(marker)
  end
  KFS:AddKeyframe(k)
end
KFS.Parent=ServerStorage

-- Preserve full raw client timeline and basic VFX templates without claiming
-- that exact burst counts, ServerStorage sources or original 3-D meshes were recovered.
local group=Instance.new('Folder');group.Name='GC_Recorded_VFX_'..tostring(data.name)
group.Parent=ReplicatedStorage
local meta=Instance.new('StringValue');meta.Name='INFO'
meta.Value='Client-observed VFX only. Direct :Emit() calls and ServerStorage source are invisible.'
meta.Parent=group
local json=HttpService:JSONEncode(data)
for i=1,#json,120000 do
  local s=Instance.new('StringValue')
  s.Name=string.format('TIMELINE_%04d',math.floor((i-1)/120000)+1)
  s.Value=json:sub(i,i+119999);s.Parent=group
end
local function readProp(v)
  if type(v)~='table' or not v.k then return v end
  local a=v.v
  if v.k=='Color3' then return Color3.new(a[1],a[2],a[3]) end
  if v.k=='Vector2' then return Vector2.new(a[1],a[2]) end
  if v.k=='Vector3' then return Vector3.new(a[1],a[2],a[3]) end
  if v.k=='NumberRange' then return NumberRange.new(a[1],a[2]) end
  if v.k=='NumberSequence' then
    local p={};for _,x in ipairs(a) do p[#p+1]=NumberSequenceKeypoint.new(x[1],x[2],x[3]) end
    return NumberSequence.new(p)
  end
  if v.k=='ColorSequence' then
    local p={};for _,x in ipairs(a) do
      p[#p+1]=ColorSequenceKeypoint.new(x[1],Color3.new(x[2][1],x[2][2],x[2][3])) end
    return ColorSequence.new(p)
  end
  if v.k=='Enum' then local en=Enum[a[1]];return en and en[a[2]] or nil end
end
local count=0
for _,ev in ipairs(data.vfx or {}) do
  if ev.op=='spawn' and (ev.kind=='ParticleEmitter' or ev.kind=='Beam' or ev.kind=='Trail') then
    local part=Instance.new('Part')
    part.Name=string.format('VFX_%03d_%s',ev.id,ev.kind)
    part.Size=Vector3.new(.15,.15,.15);part.Transparency=1;part.Anchored=true
    part.CanCollide=false;part.CanTouch=false;part.CanQuery=false
    part:SetAttribute('RecordedSpawnTime',ev.t)
    part:SetAttribute('SourceFullName',ev.path or '?')
    -- Store the origin at the first recorded attachment, and preserve its second endpoint.
    if ev.cf and ev.cf[1] then part.CFrame=cf(ev.cf[1]) end
    local a0=Instance.new('Attachment');a0.Name='A0';a0.Parent=part
    local a1=Instance.new('Attachment');a1.Name='A1';a1.Parent=part
    if ev.cf and ev.cf[2] and ev.cf[1] then
      a1.CFrame=cf(ev.cf[1]):ToObjectSpace(cf(ev.cf[2]))
    end
    local fx=Instance.new(ev.kind)
    if fx:IsA('ParticleEmitter') then fx.Enabled=false;fx.Parent=a0
    else fx.Attachment0=a0;fx.Attachment1=a1;fx.Parent=part end
    for k,v in pairs(ev.props or {}) do
      local val=readProp(v)
      if val~=nil and k~='Enabled' then pcall(function() fx[k]=val end) end
    end
    fx.Enabled=false -- templates must not emit by themselves
    part.Parent=group;count=count+1
  end
end
pcall(function() game:GetService('Selection'):Set({KFS}) end)
print('GC V6: '..KFS.Name..' in ServerStorage; '..count..' VFX templates in ReplicatedStorage')
print('SOURCE: '..source..'  TARGET: '..TARGET..(source~=TARGET and ' (APPROXIMATE REMAP)' or ' (native rig)'))
print('Speed + WASD + track timeline stored in VFX folder TIMELINE_* and event markers.')
print('Animation keyframes have recorded timestamps; humanoid movement and particle emissions are not baked into animation.')
]=]
    local exported=prefix..'['..eq..'['..raw..']'..eq..']'..suffix
    if data.version==6 then exported=exported..'\n'..Core.studioGroupedImporter(data) end
    return exported
end

-- Export a VFX-only take to real, inert Studio preview templates.
-- These are snapshots of CLIENT-OBSERVABLE effects, not ServerStorage originals.
 function Core.studioVfxImporter(data)
    if data.version==6 then return Core.studioGroupedImporter(data)end
    local raw=Core.exportJson(data)
    if not raw then return nil end
    local eq='='
    while string.find(raw,']'..eq..']',1,true) do eq=eq..'=' end
    local head=[=[
-- GRAND CLOVER V5 | VFX-ONLY STUDIO IMPORTER
-- Run in Studio Command Bar, NOT in a running game.
-- Creates inert templates + raw timeline in ReplicatedStorage.
local HttpService=game:GetService('HttpService')
local ReplicatedStorage=game:GetService('ReplicatedStorage')
local d=HttpService:JSONDecode(]=]
    local tail=[=[)
assert(d.kind=='VFX' and type(d.vfx)=='table','This is not a VFX-only recording')
local folder=Instance.new('Folder')
folder.Name='GC_VFX_Take_'..tostring(d.name or 'Unnamed'):gsub('[^%w_]','_')
folder.Parent=ReplicatedStorage
local warn=Instance.new('StringValue');warn.Name='READ_ME';warn.Parent=folder
warn.Value='CLIENT-VISIBLE EFFECT SNAPSHOTS ONLY. No hidden Emit counts, server scripts, or ServerStorage templates.'
local function cf(v) return v and CFrame.new(table.unpack(v)) or CFrame.new() end
local function prop(v)
    if type(v)~='table' or not v.k then return v end
    local a=v.v
    if v.k=='Color3' then return Color3.new(a[1],a[2],a[3]) end
    if v.k=='Vector2' then return Vector2.new(a[1],a[2]) end
    if v.k=='Vector3' then return Vector3.new(a[1],a[2],a[3]) end
    if v.k=='NumberRange' then return NumberRange.new(a[1],a[2]) end
    if v.k=='NumberSequence' then
        local k={};for _,x in ipairs(a) do k[#k+1]=NumberSequenceKeypoint.new(x[1],x[2],x[3]) end
        return NumberSequence.new(k)
    end
    if v.k=='ColorSequence' then
        local k={};for _,x in ipairs(a) do
            k[#k+1]=ColorSequenceKeypoint.new(x[1],Color3.new(x[2][1],x[2][2],x[2][3]))
        end
        return ColorSequence.new(k)
    end
    if v.k=='Enum' then local en=Enum[a[1]];return en and en[a[2]] end
end
local count=0
for _,e in ipairs(d.vfx) do
    if e.op=='spawn' and (e.kind=='ParticleEmitter' or e.kind=='Beam' or e.kind=='Trail') then
        local part=Instance.new('Part')
        part.Name=string.format('VFX_%03d_%s',e.id or 0,e.kind)
        part.Anchored=true;part.Transparency=1;part.Size=Vector3.new(.1,.1,.1)
        part.CanCollide=false;part.CanTouch=false;part.CanQuery=false
        if e.cf and e.cf[1] then part.CFrame=cf(e.cf[1]) end
        part:SetAttribute('RecordTime',e.t or 0)
        part:SetAttribute('OriginalPath',e.path or '')
        local a0=Instance.new('Attachment');a0.Name='A0';a0.Parent=part
        local a1=Instance.new('Attachment');a1.Name='A1';a1.Parent=part
        if e.cf and e.cf[1] and e.cf[2] then
            a1.CFrame=cf(e.cf[1]):ToObjectSpace(cf(e.cf[2]))
        end
        local fx=Instance.new(e.kind)
        if fx:IsA('ParticleEmitter') then fx.Parent=a0
        else fx.Attachment0=a0;fx.Attachment1=a1;fx.Parent=part end
        for k,v in pairs(e.props or {}) do
            if k~='Enabled' then
                local value=prop(v)
                if value~=nil then pcall(function() fx[k]=value end) end
            end
        end
        fx.Enabled=false
        part.Parent=folder;count=count+1
    end
end
local json=HttpService:JSONEncode(d)
for i=1,#json,120000 do
    local x=Instance.new('StringValue');x.Name=string.format('TIMELINE_%04d',math.floor((i-1)/120000)+1)
    x.Value=json:sub(i,i+119999);x.Parent=folder
end
print('GC V5 VFX: '..count..' effect snapshots imported into ReplicatedStorage/'..folder.Name)
print('Effect snapshots are disabled; use the TIMELINE_* JSON to author your gameplay replay.')
]=]
    return head..'['..eq..'['..raw..']'..eq..']'..tail
end

-- ImageGen reference: ui-reference.png. Native controls; no uploaded image asset.
local function createInterface()
local C={bg=Color3.fromRGB(18,23,29),panel=Color3.fromRGB(27,34,42),
 raised=Color3.fromRGB(37,46,56),line=Color3.fromRGB(83,97,111),
 white=Color3.fromRGB(241,245,249),sub=Color3.fromRGB(161,175,190),
 blue=Color3.fromRGB(0,196,148),red=Color3.fromRGB(221,96,106),green=Color3.fromRGB(0,196,148)}
local UI={activePage='Capture',captureMode='GAME',nav={},pages={},toggles={},modeButtons={}}
local closeRecorder
local old=playerGui:FindFirstChild(CFG.GUI)
if old then old:Destroy()end
local gui=Instance.new('ScreenGui');gui.Name=CFG.GUI;gui.ResetOnSpawn=false;gui.DisplayOrder=10000
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.Parent=playerGui
local function mk(class,parent,props)
 local obj=Instance.new(class);for k,v in pairs(props or {})do obj[k]=v end
 obj.Parent=parent;return obj
end
local function rounded(obj)mk('UICorner',obj,{CornerRadius=UDim.new(0,9)})end
local function outline(obj)mk('UIStroke',obj,{Color=C.line,Thickness=1.3,Transparency=.08})end
local function label(parent,s,pos,size,font,col)
 return mk('TextLabel',parent,{BackgroundTransparency=1,Text=s,Position=pos,Size=size,
 Font=Enum.Font.Gotham,TextSize=font or 14,TextColor3=col or C.white,
 TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center})
end
local function btn(parent,s,pos,size,color,callback)
 local x=mk('TextButton',parent,{Text=s,Position=pos,Size=size,BackgroundColor3=color or C.raised,
 TextColor3=C.white,Font=Enum.Font.GothamBold,TextSize=13,BorderSizePixel=0})
 rounded(x);x.MouseButton1Click:Connect(callback);return x
end
local function card(parent,name,pos,size)
 local x=mk('Frame',parent,{Name=name,Position=pos,Size=size,BackgroundColor3=C.panel,BorderSizePixel=0})
 rounded(x);outline(x);return x
end
-- Small native vector-like glyphs; no emoji/font fallback or remote icon assets.
local function icon(parent,kind,x,y,scale,color)
 scale=scale or 1;color=color or C.white
 local root=mk('Frame',parent,{Name='Icon_'..kind,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(36*scale,36*scale),BackgroundTransparency=1})
 local function rect(px,py,w,h,fill,radius,stroke)
  local f=mk('Frame',root,{Position=UDim2.fromOffset(px*scale,py*scale),Size=UDim2.fromOffset(w*scale,h*scale),BackgroundColor3=fill or color,BackgroundTransparency=fill==false and 1 or 0,BorderSizePixel=0})
  if radius then mk('UICorner',f,{CornerRadius=UDim.new(0,radius*scale)})end
  if stroke then mk('UIStroke',f,{Color=color,Thickness=stroke*scale})end
  return f
 end
 local function line(x1,y1,x2,y2,thickness)
  local dx,dy=x2-x1,y2-y1
  local f=mk('Frame',root,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset((x1+x2)*scale/2,(y1+y2)*scale/2),Size=UDim2.fromOffset(math.sqrt(dx*dx+dy*dy)*scale,(thickness or 2.5)*scale),Rotation=math.deg(math.atan2(dy,dx)),BackgroundColor3=color,BorderSizePixel=0})
  mk('UICorner',f,{CornerRadius=UDim.new(1,0)});return f
 end
 if kind=='camera'then
  rect(2,9,22,19,false,3,2.4);line(24,14,33,9);line(33,9,33,28);line(33,28,24,23)
 elseif kind=='film'then
  rect(4,3,27,29,false,2,2.4);line(10,4,10,31,2);line(25,4,25,31,2)
  for _,yy in {9,17,25}do rect(4,yy,6,3,color,1);rect(25,yy,6,3,color,1)end
 elseif kind=='gear'then
  for i=0,7 do local a=math.rad(i*45);local f=rect(16+math.sin(a)*14,15+math.cos(a)*14,5,7,color,1);f.AnchorPoint=Vector2.new(.5,.5);f.Rotation=-i*45 end
  rect(6,5,25,25,false,12,2.8);rect(13,12,11,11,false,6,2.2)
 elseif kind=='gamepad'then
  rect(3,11,30,20,false,8,2.6);line(8,26,5,32,3);line(28,26,31,32,3)
  line(8,20,16,20,2.8);line(12,16,12,24,2.8);rect(23,16,3,3,color,2);rect(27,20,3,3,color,2)
 elseif kind=='runner'then
  rect(22,1,8,8,color,4);line(18,12,14,23,5);line(18,13,26,20,3.6);line(26,20,32,17,3.6)
  line(18,12,10,15,3.6);line(10,15,6,22,3.6);line(14,23,24,27,4.2);line(24,27,19,34,4.2);line(14,23,8,29,4.2);line(8,29,2,26,4.2)
 elseif kind=='sparkles'then
  for _,v in {{21,11,18},{8,26,12},{30,29,8}}do local a,b,size=v[1],v[2],v[3];line(a,b-size/2,a,b+size/2,3);line(a-size/2,b,a+size/2,b,3);local diamond=rect(a-3,b-3,6,6,color,1);diamond.Rotation=45 end
 elseif kind=='play'then
  for i=0,15 do local yy=4+i*1.75;local width=(i<8 and i+1 or 16-i)*2;rect(8,yy,width,2.3,color,1)end
 elseif kind=='person'then
  rect(13,3,10,10,color,5);rect(7,17,22,12,color,6);line(7,28,29,28,2)
 elseif kind=='robot'then
  rect(5,10,26,20,color,5);rect(16,3,4,6,color,2);rect(14,1,8,4,color,2)
  rect(10,16,5,5,C.panel,2);rect(22,16,5,5,C.panel,2);rect(14,25,9,2,C.panel,1)
 elseif kind=='actors'then
  rect(8,3,9,9,false,5,2.2);rect(19,5,8,8,false,4,2.2);rect(2,17,22,13,false,6,2.2);rect(23,19,9,11,false,4,2.2)
 end
 return root
end
local function softGradient(object)
 mk('UIGradient',object,{Rotation=105,Color=ColorSequence.new(Color3.fromRGB(255,255,255),Color3.fromRGB(210,219,229))})
end
local function divider(parent,x,y,w)
 return mk('Frame',parent,{Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,1),BackgroundColor3=C.line,BorderSizePixel=0})
end

local window=mk('Frame',gui,{Name='RecorderWindow',Position=UDim2.fromScale(.5,.5),AnchorPoint=Vector2.new(.5,.5),
 Size=UDim2.fromOffset(1120,720),BackgroundColor3=C.bg,BorderSizePixel=0})
rounded(window);outline(window);softGradient(window)
local uiScale=mk('UIScale',window,{Scale=1})
UI.scale=uiScale
local viewportConnection
local function fitViewport()
 local camera=workspace.CurrentCamera;local v=camera and camera.ViewportSize or Vector2.new(1280,800)
 uiScale.Scale=math.min(1,math.max(1,v.X-24)/1120,math.max(1,v.Y-24)/720)
end
local function watchViewport()
 if viewportConnection then viewportConnection:Disconnect()end
 local camera=workspace.CurrentCamera
 if camera then viewportConnection=camera:GetPropertyChangedSignal('ViewportSize'):Connect(fitViewport);conn(viewportConnection)end
 fitViewport()
end
conn(workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(watchViewport));watchViewport()
local bar=mk('Frame',window,{Name='Header',Size=UDim2.new(1,0,0,65),BackgroundColor3=C.panel,BorderSizePixel=0})
rounded(bar);softGradient(bar);divider(bar,0,64,1120)
for i=0,3 do local leaf=mk('Frame',bar,{Position=UDim2.fromOffset(27+(i%2)*17,17+math.floor(i/2)*18),Size=UDim2.fromOffset(15,16),BackgroundColor3=C.green,BorderSizePixel=0});mk('UICorner',leaf,{CornerRadius=UDim.new(0,7)})end
label(bar,'GRAND CLOVER',UDim2.fromOffset(76,17),UDim2.fromOffset(186,34),22).Font=Enum.Font.GothamBold
mk('Frame',bar,{Position=UDim2.fromOffset(267,20),Size=UDim2.fromOffset(1,29),BackgroundColor3=C.line,BorderSizePixel=0})
label(bar,'Recorder',UDim2.fromOffset(290,13),UDim2.fromOffset(230,40),30).Font=Enum.Font.GothamBold
UI.dot=mk('Frame',bar,{Position=UDim2.fromOffset(860,24),Size=UDim2.fromOffset(16,16),BackgroundColor3=C.green,BorderSizePixel=0});mk('UICorner',UI.dot,{CornerRadius=UDim.new(1,0)})
UI.badge=label(bar,'Ready',UDim2.fromOffset(888,17),UDim2.fromOffset(96,32),21,C.white)
mk('Frame',bar,{Position=UDim2.fromOffset(980,20),Size=UDim2.fromOffset(1,29),BackgroundColor3=C.line,BorderSizePixel=0})
UI.hide=btn(bar,'−',UDim2.new(1,-112,0,13),UDim2.fromOffset(42,40),C.raised,function()window.Visible=false end);UI.hide.Name='HideRecorder';UI.hide.TextSize=28;outline(UI.hide)
UI.close=btn(bar,'×',UDim2.new(1,-60,0,13),UDim2.fromOffset(42,40),C.raised,function()if closeRecorder then closeRecorder()end end);UI.close.Name='CloseRecorder';UI.close.TextSize=29;outline(UI.close)
local side=mk('Frame',window,{Name='Navigation',Position=UDim2.fromOffset(0,65),Size=UDim2.new(0,207,1,-121),BackgroundColor3=C.bg,BorderSizePixel=0})
mk('Frame',window,{Position=UDim2.fromOffset(207,65),Size=UDim2.new(0,1,1,-121),BackgroundColor3=C.line,BorderSizePixel=0})
for i,name in ipairs({'Capture','Library','Settings'})do
 local b=btn(side,'',UDim2.fromOffset(8,27+(i-1)*59),UDim2.fromOffset(192,56),C.bg,function()UI.navigate(name)end)
 b.Name='Nav'..name;UI.nav[name]=b
 icon(b,({'camera','film','gear'})[i],20,12,.85)
 label(b,name,UDim2.fromOffset(60,10),UDim2.fromOffset(128,36),21).Font=Enum.Font.GothamBold
 local accent=mk('Frame',b,{Name='ActiveAccent',Position=UDim2.fromOffset(0,2),Size=UDim2.fromOffset(5,52),BackgroundColor3=C.green,BorderSizePixel=0});rounded(accent)
 local page=mk('Frame',window,{Name=name..'Page',Position=UDim2.fromOffset(name=='Capture'and 232 or 223,88),Size=UDim2.fromOffset(name=='Capture'and 872 or 881,560),BackgroundTransparency=1,Visible=name=='Capture'})
 UI.pages[name]=page
end
local footer=mk('Frame',window,{Name='Footer',Position=UDim2.fromOffset(0,664),Size=UDim2.fromOffset(1120,56),BackgroundColor3=C.panel,BorderSizePixel=0});softGradient(footer);divider(footer,0,0,1120)
local f7=card(footer,'F7Badge',UDim2.fromOffset(26,12),UDim2.fromOffset(43,32));label(f7,'F7',UDim2.fromOffset(0,0),UDim2.fromOffset(43,32),18).TextXAlignment=Enum.TextXAlignment.Center
label(footer,'Show / hide',UDim2.fromOffset(80,11),UDim2.fromOffset(138,34),18)
mk('Frame',footer,{Position=UDim2.fromOffset(214,12),Size=UDim2.fromOffset(1,30),BackgroundColor3=C.line,BorderSizePixel=0})
statusLabel=label(footer,'Saved takes stay on this device',UDim2.fromOffset(258,11),UDim2.fromOffset(836,34),17,C.white)
statusLabel.Name='StatusMessage';statusLabel.TextTruncate=Enum.TextTruncate.AtEnd
local capture=UI.pages.Capture
label(capture,'Record a session',UDim2.fromOffset(6,0),UDim2.fromOffset(510,44),36).Font=Enum.Font.GothamBold
label(capture,'Motion, effects and actor state on one timeline',UDim2.fromOffset(6,50),UDim2.fromOffset(510,30),18,C.sub)
local modes={{'GAME','Game','F3','gamepad'},{'ANIM','Motion','F6','runner'},{'VFX','VFX','F8','sparkles'}}
for i,entry in ipairs(modes)do
 local mode=entry[1]
 local b=btn(capture,'',UDim2.fromOffset((i-1)*174,106),UDim2.fromOffset(160,121),C.panel,function()
  if recording then msg('Stop recording before changing mode.');return end
  UI.captureMode=mode;UI.refreshModes()
 end)
 b.Name='Mode'..mode;outline(b);softGradient(b);UI.modeButtons[mode]=b
 icon(b,entry[4],61,20,1.05)
 label(b,entry[2],UDim2.fromOffset(22,76),UDim2.fromOffset(79,32),21).Font=Enum.Font.GothamBold
 local key=mk('Frame',b,{Position=UDim2.fromOffset(100,78),Size=UDim2.fromOffset(38,29),BackgroundColor3=C.raised,BorderSizePixel=0});rounded(key)
 local text=label(key,entry[3],UDim2.fromOffset(0,0),UDim2.fromOffset(38,29),16);text.TextXAlignment=Enum.TextXAlignment.Center
end
function UI.refreshModes()
 local active=recording and recording.kind or UI.captureMode
 for mode,b in pairs(UI.modeButtons)do b.BackgroundColor3=mode==active and Color3.fromRGB(11,75,62)or C.panel;local stroke=b:FindFirstChildOfClass('UIStroke');if stroke then stroke.Color=mode==active and C.green or C.line;stroke.Thickness=mode==active and 2.3 or 1.5 end end
end
local elapsedUI=label(capture,'00:00',UDim2.fromOffset(0,244),UDim2.fromOffset(508,112),96)
elapsedUI.Name='ElapsedTime';elapsedUI.TextXAlignment=Enum.TextXAlignment.Center;elapsedUI.Font=Enum.Font.GothamBold
local limit=label(capture,tostring(CFG.MAX_SECONDS)..' second limit',UDim2.fromOffset(0,356),UDim2.fromOffset(508,36),23,C.sub)
limit.TextXAlignment=Enum.TextXAlignment.Center
local progress=mk('Frame',capture,{Visible=false,Position=UDim2.fromOffset(0,372),Size=UDim2.fromOffset(552,4),BackgroundColor3=C.raised,BorderSizePixel=0})
UI.progress=mk('Frame',progress,{Size=UDim2.fromScale(0,1),BackgroundColor3=C.green,BorderSizePixel=0})
UI.record=btn(capture,'',UDim2.fromOffset(6,410),UDim2.fromOffset(492,62),C.green,function()
 Core.startRecord(recording and recording.kind or UI.captureMode)
end);UI.record.Name='StartStopRecording';softGradient(UI.record)
UI.playIcon=icon(UI.record,'play',132,15,.85)
UI.stopIcon=mk('Frame',UI.record,{Visible=false,Position=UDim2.fromOffset(140,22),Size=UDim2.fromOffset(18,18),BackgroundColor3=C.white,BorderSizePixel=0})
UI.recordLabel=label(UI.record,'Start recording',UDim2.fromOffset(176,0),UDim2.fromOffset(296,62),26);UI.recordLabel.Font=Enum.Font.GothamBold
label(capture,'Automatic capture within 60 studs · filters in Settings',UDim2.fromOffset(6,486),UDim2.fromOffset(492,56),15,C.sub).TextWrapped=true
local subjects=card(capture,'CaptureSubjects',UDim2.fromOffset(522,-3),UDim2.fromOffset(350,318))
label(subjects,'Capture subjects',UDim2.fromOffset(18,12),UDim2.fromOffset(314,32),24).Font=Enum.Font.GothamBold
label(subjects,'Your character is always included',UDim2.fromOffset(18,45),UDim2.fromOffset(314,25),17,C.sub)
local function actorToggle(parent,key,title,y)
 label(parent,title,UDim2.fromOffset(18,y),UDim2.fromOffset(parent.Size.X.Offset-110,36),22).Font=Enum.Font.GothamBold
 local b=btn(parent,'',UDim2.fromOffset(parent.Size.X.Offset-74,y+2),UDim2.fromOffset(54,29),C.green,function()
  local settings=Core.actorCaptureSettings();local ok,description=Core.setActorCaptureSetting(key,not settings[key]);msg(description)
  if ok then UI.refreshToggles();UI.refreshSubjects(); end
 end)
 b.Name=key=='includeNPCs'and 'IncludeNPCsToggle'or 'IncludePlayersToggle';b.TextSize=1;b.TextTransparency=1
 local knob=mk('Frame',b,{Name='Knob',Position=UDim2.fromOffset(29,3),Size=UDim2.fromOffset(23,23),BackgroundColor3=C.white,BorderSizePixel=0});rounded(knob)
 UI.toggles[#UI.toggles+1]={key=key,button=b,knob=knob}
end
actorToggle(subjects,'includePlayers','Record players',80)
actorToggle(subjects,'includeNPCs','Record NPCs',128)
label(subjects,'Applies to the next Game recording',UDim2.fromOffset(18,166),UDim2.fromOffset(314,29),17,C.sub)
divider(subjects,18,120,314);divider(subjects,18,200,314)
UI.subjectIcon1=icon(subjects,'person',18,215,.8)
UI.subjectIcon2=icon(subjects,'robot',18,247,.8,C.sub)
UI.subjectPlayerIcon2=icon(subjects,'person',18,247,.8,C.sub);UI.subjectPlayerIcon2.Visible=false
UI.subjectSummary=label(subjects,'You  ·  Local player',UDim2.fromOffset(60,216),UDim2.fromOffset(272,66),18,C.white);UI.subjectSummary.LineHeight=1.4
UI.subjectSummary.TextWrapped=false;UI.subjectSummary.TextYAlignment=Enum.TextYAlignment.Top
UI.subjectCount=label(subjects,'Automatic · 60 studs',UDim2.fromOffset(18,282),UDim2.fromOffset(314,26),17,C.sub)
local quality=card(capture,'CaptureQuality',UDim2.fromOffset(522,336),UDim2.fromOffset(350,177))
label(quality,'Capture quality',UDim2.fromOffset(18,13),UDim2.fromOffset(314,30),24).Font=Enum.Font.GothamBold
for i,item in ipairs({{'Motion','30 Hz'},{'Effects','15 Hz'},{'Actors',tostring(CFG.INSPECT_FPS)..' Hz'}})do
 label(quality,item[1],UDim2.fromOffset(18,54+(i-1)*38),UDim2.fromOffset(195,30),20).Font=Enum.Font.GothamBold
 if i<3 then divider(quality,18,91+(i-1)*38,314)end
 local value=label(quality,item[2],UDim2.fromOffset(238,54+(i-1)*38),UDim2.fromOffset(94,30),20,C.white);value.TextXAlignment=Enum.TextXAlignment.Right
 UI['quality'..i]=value
end
local settings=UI.pages.Settings
label(settings,'Settings',UDim2.fromOffset(0,0),UDim2.fromOffset(912,40),29).Font=Enum.Font.GothamBold
label(settings,'Capture only the actor types you need.',UDim2.fromOffset(0,44),UDim2.fromOffset(912,25),14,C.sub)
local actorSettings=card(settings,'ActorSettings',UDim2.fromOffset(0,92),UDim2.fromOffset(406,244))
label(actorSettings,'Game recording subjects',UDim2.fromOffset(18,12),UDim2.fromOffset(384,30),19).Font=Enum.Font.GothamBold
label(actorSettings,'Self + enabled actors within 60 studs (max32).',UDim2.fromOffset(18,47),UDim2.fromOffset(384,24),12,C.sub)
actorToggle(actorSettings,'includePlayers','Record players',86);actorToggle(actorSettings,'includeNPCs','Record NPCs',139)
label(actorSettings,'Actor motion, animation and combat-state tracks.',UDim2.fromOffset(18,192),UDim2.fromOffset(384,30),12,C.sub).TextWrapped=true
UI.settingsQuality=card(settings,'QualitySettings',UDim2.fromOffset(426,92),UDim2.fromOffset(454,244))
label(UI.settingsQuality,'Capture rate',UDim2.fromOffset(18,12),UDim2.fromOffset(418,30),19).Font=Enum.Font.GothamBold
label(UI.settingsQuality,'Motion / VFX standalone modes',UDim2.fromOffset(18,48),UDim2.fromOffset(418,24),13,C.sub)
label(UI.settingsQuality,'Game mode stays bounded: motion ≤30 Hz, effects 15 Hz, actors 10 Hz.',UDim2.fromOffset(18,132),UDim2.fromOffset(418,68),13,C.sub).TextWrapped=true
local storage=card(settings,'LocalSettings',UDim2.fromOffset(0,358),UDim2.fromOffset(880,156))
label(storage,'Local storage & selection',UDim2.fromOffset(18,12),UDim2.fromOffset(844,30),19).Font=Enum.Font.GothamBold
label(storage,'Settings persist locally when file access is available. Otherwise they persist for this client session.\nEnabled NPCs/players within 60 studs are captured automatically during recording. Nearby world VFX remain a separate capture stream.',UDim2.fromOffset(18,49),UDim2.fromOffset(844,82),14,C.sub).TextWrapped=true
function UI.refreshToggles()
 local options=Core.actorCaptureSettings()
 for _,row in ipairs(UI.toggles)do local enabled=options[row.key];row.button.BackgroundColor3=enabled and C.green or C.raised;row.button.Text=enabled and ' ON'or 'OFF ';row.button.TextXAlignment=enabled and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right;row.knob.Position=UDim2.fromOffset(enabled and 29 or 2,3)end
end
function UI.refreshSubjects()
 local options=Core.actorCaptureSettings()
 UI.subjectSummary.Text='You  ·  Local player\nAutomatic capture in 60 studs'
 UI.subjectCount.Text='Players '..(options.includePlayers and 'ON'or 'OFF')..'  ·  NPCs '..(options.includeNPCs and 'ON'or 'OFF')
 UI.subjectIcon2.Visible=options.includeNPCs;UI.subjectPlayerIcon2.Visible=not options.includeNPCs and options.includePlayers
end
function UI.navigate(name)
 UI.activePage=name
  if UI.copyModal then UI.copyModal.Visible=false end
 for key,page in pairs(UI.pages)do page.Visible=key==name;UI.nav[key].BackgroundColor3=key==name and Color3.fromRGB(11,75,62)or C.bg;UI.nav[key].ActiveAccent.Visible=key==name end
 if name=='Capture'then UI.refreshSubjects()end
 if name=='Library'and drawLibrary then drawLibrary();drawDetails()end
end
local library=UI.pages.Library
label(library,'Recording library',UDim2.fromOffset(0,0),UDim2.fromOffset(912,34),25).Font=Enum.Font.GothamBold
local left=card(library,'TakeList',UDim2.fromOffset(0,44),UDim2.fromOffset(234,510))
local right=card(library,'TakeDetails',UDim2.fromOffset(250,44),UDim2.fromOffset(630,510))

local liveUI=label(capture,'Ready',UDim2.fromOffset(0,548),UDim2.fromOffset(872,18),11,C.sub)
local animTab
local vfxTab
local inspectTab
local inspectActorBtn
local vfxExportBtn
local function setLibraryFilter(mode)
    if recording then msg('Finish recording before changing libraries.');return end
    libraryFilter=mode;selected=nil
    for _,t in ipairs(saved) do
        if (t.kind or 'ANIM')==mode then selected=t.id;break end
    end
    animTab.BackgroundColor3=mode=='ANIM' and C.blue or C.raised
    vfxTab.BackgroundColor3=mode=='VFX' and C.blue or C.raised
    inspectTab.BackgroundColor3=mode=='GAME' and C.blue or C.raised
    if inspectActorBtn then inspectActorBtn.Text=mode=='GAME' and '60 STUD AUTO' or 'SPLIT VFX' end
    if vfxExportBtn then vfxExportBtn.Text=mode=='GAME' and 'VFX STUDIO' or 'VFX JSON' end
    if drawLibrary then drawLibrary() end
    if drawDetails then drawDetails() end
end
animTab=btn(left,'Motion',UDim2.fromOffset(11,8),UDim2.fromOffset(64,26),C.blue,function() setLibraryFilter('ANIM') end)
vfxTab=btn(left,'VFX',UDim2.fromOffset(83,8),UDim2.fromOffset(64,26),C.raised,function() setLibraryFilter('VFX') end)
inspectTab=btn(left,'Game',UDim2.fromOffset(155,8),UDim2.fromOffset(68,26),C.raised,function() setLibraryFilter('GAME') end)
local search=mk('TextBox',left,{Position=UDim2.fromOffset(11,38),Size=UDim2.fromOffset(212,35),
    Text='',PlaceholderText='Search take / animation ID...',ClearTextOnFocus=false,
    TextColor3=C.white,PlaceholderColor3=C.sub,TextSize=13,Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left,BackgroundColor3=C.raised,BorderSizePixel=0})
rounded(search)
local takeScroll=mk('ScrollingFrame',left,{Position=UDim2.fromOffset(8,82),Size=UDim2.new(1,-16,1,-92),
    BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=5,CanvasSize=UDim2.fromOffset(0,0)})
local takeLayout=mk('UIListLayout',takeScroll,{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder})
local nameUI=label(right,'Select a take',UDim2.fromOffset(11,8),UDim2.new(1,-23,0,23),15)
nameUI.Font=Enum.Font.GothamBold
local metaUI=label(right,'View tracks, timing, speed and VFX.',UDim2.fromOffset(11,31),UDim2.new(1,-22,0,31),12,C.sub)
metaUI.TextWrapped=true
local idsHeader=label(right,'ANIMATION IDs',UDim2.fromOffset(12,69),UDim2.fromOffset(220,18),12,C.blue)
idsHeader.Font=Enum.Font.GothamBold
label(right,'EVENT TIMELINE (time in seconds)',UDim2.fromOffset(246,69),UDim2.fromOffset(382,18),12,C.blue).Font=Enum.Font.GothamBold
local ids=mk('ScrollingFrame',right,{Position=UDim2.fromOffset(9,91),Size=UDim2.fromOffset(220,210),
    BackgroundColor3=C.raised,BorderSizePixel=0,ScrollBarThickness=4,CanvasSize=UDim2.fromOffset(0,0)})
local timeline=mk('ScrollingFrame',right,{Position=UDim2.fromOffset(246,91),Size=UDim2.fromOffset(370,210),
    BackgroundColor3=C.raised,BorderSizePixel=0,ScrollBarThickness=4,CanvasSize=UDim2.fromOffset(0,0)})
rounded(ids);rounded(timeline)
local idLayout=mk('UIListLayout',ids,{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.LayoutOrder})
local timelineLayout=mk('UIListLayout',timeline,{Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder})
local loopOn=false
local loopBtn
local selectedTarget='R6'
local rigBtn
rigBtn=btn(right,'TARGET: R6',UDim2.fromOffset(11,311),UDim2.fromOffset(190,31),C.raised,function()
    selectedTarget=selectedTarget=='R6' and 'R15' or 'R6'
    rigBtn.Text='TARGET: '..selectedTarget
end)
loopBtn=btn(right,'LOOP: OFF',UDim2.fromOffset(211,311),UDim2.fromOffset(190,31),C.raised,function()
    loopOn=not loopOn
    loopBtn.Text='LOOP: '..(loopOn and 'ON' or 'OFF')
    loopBtn.BackgroundColor3=loopOn and C.blue or C.raised
end)
local burstBtn
burstBtn=btn(right,'BURST EST: ON',UDim2.fromOffset(411,311),UDim2.fromOffset(205,31),C.blue,function()
    estimateBurstPreview=not estimateBurstPreview
    burstBtn.Text='BURST EST: '..(estimateBurstPreview and 'ON' or 'OFF')
    burstBtn.BackgroundColor3=estimateBurstPreview and C.blue or C.raised
    msg('Estimated bursts are '..(estimateBurstPreview and 'ON: preview 12 particles (not an exact capture).' or 'OFF: Emit()-only effects might be invisible.'))
end)
-- Optional quality selector for long (up-to-two-minute) recordings.
local qualityBtn
qualityBtn=btn(right,'RATE: 60 FPS',UDim2.fromOffset(450,311),UDim2.fromOffset(230,31),C.raised,function()
    if recording or playback then msg('Stop recording/playback before changing FPS.');return end
    local newRate=CFG.FPS==60 and 30 or 60
    CFG.FPS=newRate;CFG.VFX_FPS=newRate;Core.saveRecorderSettings()
    qualityBtn.Text='RATE: '..newRate..' FPS'
    msg('Capture rate set to '..newRate..' FPS. F3 uses up to 30Hz motion, 15Hz VFX and '..CFG.INSPECT_FPS..'Hz actors.')
end)
qualityBtn.Parent=UI.settingsQuality;qualityBtn.Position=UDim2.fromOffset(18,84);qualityBtn.Size=UDim2.fromOffset(418,36)
qualityBtn.Text='RATE: '..CFG.FPS..' FPS'
local function getSelectedTake()
    for _,t in ipairs(saved) do if t.id==selected then return t end end
    return nil
end
local copyBox=mk('Frame',window,{Name='ManualExport',Visible=false,Position=UDim2.fromScale(.5,.5),AnchorPoint=Vector2.new(.5,.5),
    Size=UDim2.fromOffset(820,540),BackgroundColor3=C.bg,BorderSizePixel=0,Active=true,ZIndex=30})
rounded(copyBox);UI.copyModal=copyBox
label(copyBox,'MANUAL EXPORT — CTRL+A THEN CTRL+C',UDim2.fromOffset(12,10),UDim2.fromOffset(710,25),14)
btn(copyBox,'CLOSE',UDim2.new(1,-100,0,8),UDim2.fromOffset(90,30),C.red,function() copyBox.Visible=false end)
local bigText=mk('TextBox',copyBox,{Text='',MultiLine=true,ClearTextOnFocus=false,
    Position=UDim2.fromOffset(11,49),Size=UDim2.new(1,-22,1,-60),
    TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,
    Font=Enum.Font.Code,TextSize=11,TextColor3=C.white,BackgroundColor3=C.panel,
    BorderSizePixel=0,TextEditable=true})
local function presentExport(content,fileName)
    if not content then msg('Export unavailable.');return end
    local savedExport=Core.safeWrite(fileName,content)
    if Core.safeCopy(content) then
        msg((savedExport and 'Saved '..fileName..' and copied to clipboard.' or 'Copied to clipboard.'),C.green)
    elseif savedExport then
        msg('Saved '..fileName..' (clipboard unavailable).',C.green)
    else
        -- Roblox text boxes may truncate very large exports; warn rather than silently mislead.
        local limited=content:sub(1,50000)
        bigText.Text=limited
        copyBox.Visible=true
        msg('No file/clipboard API. Showing '..#limited..' of '..#content..' characters; large exports may be incomplete.',C.red)
    end
end
local function exportTake(kind)
    if recording then msg('Stop recording before exporting.');return end
    local t=getSelectedTake()
    if not t then msg('Select a recording first.');return end
    local d=loadData(t)
    if not d then msg('Cannot load selected recording.');return end
    local s,filename
    if kind=='studio' and t.kind=='INSPECT' then
        msg('Inspector takes export as RAW JSON, not Studio animation/VFX.',C.sub);return
    end
    if kind=='studio' and ((t.kind or 'ANIM')=='ANIM' or t.kind=='GAME') then
        s=Core.studioImporter(d,selectedTarget)
        filename=CFG.PREFIX..t.id..'_STUDIO_'..selectedTarget..'.lua'
    elseif (kind=='studio' or kind=='studio-vfx') and ((t.kind or 'ANIM')=='VFX' or t.kind=='GAME') then
        s=Core.studioVfxImporter(d)
        filename=CFG.PREFIX..t.id..'_VFX_STUDIO.lua'
    elseif kind=='vfx' then
        s=Core.exportJson({version=6,name=d.name,duration=d.duration,vfx=d.vfx,
            caveat='Client-observed only; Emit(n) calls and ServerStorage are invisible'})
        filename=CFG.PREFIX..t.id..'_VFX.json'
    else
        s=Core.exportJson(d)
        filename=CFG.PREFIX..t.id..'_RAW.json'
    end
    if kind=='studio' and (t.kind or 'ANIM')=='VFX' then
        msg('Grouped Studio importer: complete hierarchies, full data and Studio TakePreview module.',C.blue)
    end
    presentExport(s,filename)
end
btn(right,'PLAY MOTION GHOST',UDim2.fromOffset(11,350),UDim2.fromOffset(180,32),C.blue,function() Core.playSelection('ANIM',loopOn) end)
btn(right,'PLAY VFX AHEAD',UDim2.fromOffset(199,350),UDim2.fromOffset(180,32),C.blue,function() Core.playSelection('VFX',loopOn) end)
btn(right,'STOP',UDim2.fromOffset(387,350),UDim2.fromOffset(80,32),C.red,function() stopPreview() end)
btn(right,'COPY RAW',UDim2.fromOffset(11,394),UDim2.fromOffset(112,35),C.raised,function() exportTake('raw') end)
vfxExportBtn=btn(right,'VFX JSON',UDim2.fromOffset(131,394),UDim2.fromOffset(112,35),C.raised,function()
    if libraryFilter=='GAME' then exportTake('studio-vfx') else exportTake('vfx') end
end)
btn(right,'EXPORT STUDIO',UDim2.fromOffset(251,394),UDim2.fromOffset(220,35),C.green,function() exportTake('studio') end)
inspectActorBtn=btn(right,'SPLIT VFX',UDim2.fromOffset(479,394),UDim2.fromOffset(137,35),C.blue,function()
    if recording then msg('Finish recording first.');return end
    if libraryFilter=='GAME' then msg('Automatic 60-stud capture; player/NPC filters are in Settings.');return end
    local take=getSelectedTake();if take then Core.splitVfx(take)end
end)
btn(right,'REC GAME F3',UDim2.fromOffset(475,350),UDim2.fromOffset(141,32),C.green,function()
    Core.startRecord('GAME')
end)
local caution=label(right,'Client observations only. Burst estimates are labeled; unavailable assets are marked.',
    UDim2.fromOffset(12,439),UDim2.new(1,-20,0,31),11,C.sub)
caution.TextWrapped=true
-- Common footer is owned by the new navigation shell.

local function clearGuiRows(container)
    for _,x in ipairs(container:GetChildren()) do if x:IsA('GuiObject') then x:Destroy() end end
end
local function rowText(scroll,s,i,h,col)
    local x=label(scroll,s,UDim2.fromOffset(0,0),UDim2.new(1,-10,0,h),11,col or C.white)
    x.LayoutOrder=i;x.TextXAlignment=Enum.TextXAlignment.Left;x.TextTruncate=Enum.TextTruncate.AtEnd
    return x
end
local function deleteTake(id)
    for i,t in ipairs(saved) do
        if t.id==id then
            if playback and playback.data==t.data then stopPreview() end
            if t.saved then Core.safeDelete(t.path) end
            table.remove(saved,i)
            if selected==id then selected=nil end
            Core.saveHistory();msg('Take removed from recorder history. Game assets are unchanged.')
            drawLibrary();drawDetails();return
        end
    end
end

drawLibrary=function()
    if UI.activePage~='Library'then return end -- do not build hidden take rows at startup
    clearGuiRows(takeScroll)
    local q=search.Text:lower();local i=0
    for _,t in ipairs(saved) do
        if ((t.kind or 'ANIM')==libraryFilter or (libraryFilter=='GAME' and t.kind=='INSPECT')) then
        local phrase=(t.name..' '..t.rig..' '..t.created):lower()
        for _,tr in ipairs(t.tracks or {}) do phrase=phrase..' '..tostring(tr.id or '')..' '..tostring(tr.name or '') end
        if q=='' or string.find(phrase:lower(),q,1,true) then
            i=i+1
            local row=mk('Frame',takeScroll,{Size=UDim2.new(1,-4,0,60),LayoutOrder=i,
                BackgroundColor3=selected==t.id and Color3.fromRGB(38,80,98) or C.raised,BorderSizePixel=0})
            rounded(row)
            local namebtn=btn(row,t.name..' ['..t.rig..']',UDim2.fromOffset(4,5),UDim2.new(1,-81,0,28),row.BackgroundColor3,function()
                selected=t.id;drawLibrary();drawDetails()
            end)
            namebtn.TextXAlignment=Enum.TextXAlignment.Left;namebtn.TextTruncate=Enum.TextTruncate.AtEnd
            label(row,((t.kind or 'ANIM')=='VFX' and string.format('%d VFX events | %.2fs',t.nvfx or 0,t.duration or 0)
                or ((t.kind=='INSPECT' or t.kind=='GAME') and string.format('%d actor samples | %.2fs',t.nframes or 0,t.duration or 0)
                or string.format('%d frames | %.2fs',t.nframes or 0,t.duration or 0))),
                UDim2.fromOffset(12,37),UDim2.new(1,-80,0,16),10,C.sub)
            btn(row,'DELETE',UDim2.new(1,-76,0,15),UDim2.fromOffset(70,31),C.red,function() deleteTake(t.id) end)
        end
        end -- matching library filter
    end
    if i==0 then label(takeScroll,'No recordings yet. Start a capture to see it here.',UDim2.fromOffset(4,8),UDim2.new(1,-16,0,66),13,C.sub).TextWrapped=true end
    takeScroll.CanvasSize=UDim2.fromOffset(0,i*67)
end
local function viewEvent(e)
    local parts={string.format('%.4fs',e.t or 0),e.type or '?'}
    if e.key then parts[#parts+1]=e.key end
    if e.actor then parts[#parts+1]='ACTOR '..e.actor end
    if e.name then parts[#parts+1]=e.name end
    if e.state then parts[#parts+1]=e.state end
    if e.reasons and #e.reasons>0 then parts[#parts+1]=table.concat(e.reasons,','):sub(1,60) end
    if e.summary then parts[#parts+1]=e.summary end
    if e.id then parts[#parts+1]='#'..e.id end
    if e.speed~=nil then parts[#parts+1]='x'..tostring(e.speed) end
    if e.studsPerSec then parts[#parts+1]=tostring(e.studsPerSec)..' studs/s' end
    if e.actualSpeed then parts[#parts+1]=tostring(e.actualSpeed)..' studs/s' end
    return table.concat(parts,'  |  ')
end

drawDetails=function()
    if UI.activePage~='Library'then return end -- do not read take files behind Capture/Settings
    clearGuiRows(ids);clearGuiRows(timeline)
    local t=getSelectedTake()
    if not t then
        nameUI.Text='Select a '..libraryFilter..' recording';metaUI.Text='Animation, VFX and Inspector takes have separate libraries.'
        return
    end
    local d=loadData(t)
    nameUI.Text=t.name..'  ['..t.rig..']  |  '..Core.takeFormat(d)
    idsHeader.Text=(t.kind=='VFX' and 'VFX SOURCES' or ((t.kind=='INSPECT' or t.kind=='GAME') and 'OBSERVED ACTORS' or 'ANIMATION IDs'))
    metaUI.Text=string.format('%.3f seconds | %d pose frames | %d movement events | %d VFX events',
        t.duration or 0,t.nframes or 0,d and #(d.events or {}) or 0,t.nvfx or 0)
    if d and d.inspector then
        metaUI.Text=string.format('%.2fs | %d motion | %d VFX | %d actor samples | %d events%s',
            t.duration or 0,#(d.frames or {}),#(d.vfx or {}),#(d.inspector.frames or {}),#(d.events or {}),
            (d.inspector.truncated or (d.game and d.game.truncated) or d.truncatedVFX) and ' | CAPTURE LIMIT' or '')
    end
    local q=search.Text:lower();local n=0
    for _,tr in ipairs(t.tracks or {}) do
        local s=(tr.id or '?')..'  '..(tr.name or '')
        if q=='' or string.find(s:lower(),q,1,true) then
            n=n+1
            rowText(ids,s,n,21,C.blue)
            n=n+1
            rowText(ids,string.format('speed %.2fx | first %.3fs | last %.3fs',tr.speed or 1,tr.first or 0,tr.last or 0),n,19,C.sub)
        end
    end
    if d and d.inspector then
        for _,a in ipairs(d.inspector.actors or {})do
            n+=1;rowText(ids,a.label..'  ['..a.role..']',n,21,C.blue)
            n+=1;rowText(ids,tostring(a.rig)..' | '..#(a.joints or {})..' joints',n,19,C.sub)
        end
    end
    if ((t.kind or 'ANIM')=='VFX' or t.kind=='GAME') and d then
        for _,ev in ipairs(d.vfx or {}) do
            if ev.op=='spawn' or ev.op=='group_spawn' then
                local text=string.format('%s #%s',ev.kind or 'Effect',ev.id or '?')
                n=n+1;rowText(ids,text,n,21,C.blue)
                n=n+1;rowText(ids,tostring(ev.path or ''):sub(-72),n,19,C.sub)
            end
        end
    end
    ids.CanvasSize=UDim2.fromOffset(0,n*23)
    local j=0
    if d then
        local combined={}
        for _,ev in ipairs(d.events or {}) do
            combined[#combined+1]={t=ev.t or 0,fx=false,e=ev}
        end
        for _,ev in ipairs(d.vfx or {}) do
            combined[#combined+1]={t=ev.t or 0,fx=true,e=ev}
        end
        table.sort(combined,function(a,b) return a.t<b.t end)
        for _,x in ipairs(combined) do
            if j>=1200 then break end
            j=j+1
            if x.fx then
                local fx=x.e
                rowText(timeline,string.format('%.4fs | VFX_%s | %s #%s',
                    fx.t or 0,fx.op or '?',fx.kind or 'effect',fx.id or '?'),j,20,C.blue)
            else
                local ev=x.e
                rowText(timeline,viewEvent(ev),j,20,
                    ev.type=='WASD_STOP' and C.red or
                    ev.type=='WASD_RESUME' and C.green or C.white)
            end
        end
    end
    timeline.CanvasSize=UDim2.fromOffset(0,j*23)
end
conn(search:GetPropertyChangedSignal('Text'):Connect(function() drawLibrary();drawDetails() end))
conn(takeLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
    takeScroll.CanvasSize=UDim2.fromOffset(0,takeLayout.AbsoluteContentSize.Y+6)
end))
conn(idLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
    ids.CanvasSize=UDim2.fromOffset(0,idLayout.AbsoluteContentSize.Y+6)
end))
conn(timelineLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
    timeline.CanvasSize=UDim2.fromOffset(0,timelineLayout.AbsoluteContentSize.Y+6)
end))

local dragging,dragStart,startPosition=false,nil,nil
conn(bar.InputBegan:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
        dragging=true;dragStart=inp.Position;startPosition=window.Position
    end
end))
conn(UIS.InputChanged:Connect(function(inp)
    if dragging and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
        local shift=inp.Position-dragStart
        window.Position=UDim2.new(startPosition.X.Scale,startPosition.X.Offset+shift.X,
            startPosition.Y.Scale,startPosition.Y.Offset+shift.Y)
    end
end))
conn(UIS.InputEnded:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragging=false end
end))
conn(UIS.InputBegan:Connect(function(inp,processed)
    if disposed then return end
    local key=Core.inputName(inp)
    if key=='F7'and not UIS:GetFocusedTextBox()then window.Visible=not window.Visible;if not window.Visible then copyBox.Visible=false end;return end
    if UIS:GetFocusedTextBox()then return end
    if key=='F6'and not processed then Core.startRecord('ANIM')
    elseif key=='F8'and not processed then Core.startRecord('VFX')
    elseif key=='F3'and not processed then Core.startRecord('GAME')
    elseif recording and recording.kind=='GAME' then
        if key~='Unknown' then
            if WATCH[key] or key:match('^Mouse[123]$') then
                Core.inputUpdate(recording,key,true,now(recording),processed)
            else
                Core.appendEvent(recording,'INPUT_DOWN',{key=key,processed=processed},now(recording))
            end
            if key=='LeftShift' or key=='RightShift' then
                Core.inputUpdate(recording,'Shift',true,now(recording),processed)
            end
        end
    elseif recording and recording.kind=='INSPECT' and (WATCH[key] or key:match('^Mouse[123]$')) then
        Core.appendEvent(recording,'INPUT_DOWN',{key=key,processed=processed},now(recording))
    elseif recording and recording.kind=='ANIM'and (WATCH[key]or key:match('^Mouse[123]$'))then
        Core.inputUpdate(recording,key,true,now(recording),processed)
        if key=='LeftShift'or key=='RightShift'then Core.inputUpdate(recording,'Shift',true,now(recording),processed)end
    end
end))
conn(UIS.InputEnded:Connect(function(inp,processed)
    if disposed or not recording then return end
    local key=Core.inputName(inp)
    if recording.kind=='GAME' then
        if key~='Unknown' then
            if WATCH[key] or key:match('^Mouse[123]$') then
                Core.inputUpdate(recording,key,false,now(recording),processed)
            else
                Core.appendEvent(recording,'INPUT_UP',{key=key,processed=processed},now(recording))
            end
        end
        if key=='LeftShift' or key=='RightShift' then
            local held=UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)
            Core.inputUpdate(recording,'Shift',held,now(recording),processed)
        end
        return
    end
    if recording.kind=='INSPECT' then
        if WATCH[key] or key:match('^Mouse[123]$') then
            Core.appendEvent(recording,'INPUT_UP',{key=key,processed=processed},now(recording))
        end
        return
    end
    if recording.kind~='ANIM' then return end
    if WATCH[key]or key:match('^Mouse[123]$')then Core.inputUpdate(recording,key,false,now(recording),processed)end
    if key=='LeftShift'or key=='RightShift'then
        local held=UIS:IsKeyDown(Enum.KeyCode.LeftShift)or UIS:IsKeyDown(Enum.KeyCode.RightShift)
        Core.inputUpdate(recording,'Shift',held,now(recording),processed)
    end
end))
-- Capture-only observers. Loading the UI never subscribes to world churn.
local captureConnections={}
function Core.endCaptureObservers()
 for _,c in ipairs(captureConnections)do c:Disconnect()end
 table.clear(captureConnections)
end
function Core.beginCaptureObservers(t)
 Core.endCaptureObservers()
 if t.kind=='ANIM'then return end
 local function watch(c)captureConnections[#captureConnections+1]=c end
watch(workspace.DescendantAdded:Connect(function(obj)
    if t.kind=='VFX' or t.kind=='GAME'then Group.observe(obj,true)end
    if recording and recording.kind=='GAME' then Core.gameObserveInstance(recording,obj,'add','Workspace') end
    if recording and (recording.kind=='INSPECT' or recording.kind=='GAME') then Core.inspectEffect(obj,now(recording),'add') end
end))
watch(workspace.DescendantRemoving:Connect(function(obj)
    if recording and recording.kind=='GAME' then Core.gameObserveInstance(recording,obj,'remove','Workspace') end
    if recording and (recording.kind=='INSPECT' or recording.kind=='GAME') then Core.inspectEffect(obj,now(recording),'remove') end
    if t.kind=='VFX' or t.kind=='GAME'then Group.removing(obj)end
end))
if t.kind=='GAME' then
watch(game:GetService('ReplicatedStorage').DescendantAdded:Connect(function(obj)
    if recording and recording.kind=='GAME' then Core.gameObserveInstance(recording,obj,'add','ReplicatedStorage') end
end))
watch(game:GetService('ReplicatedStorage').DescendantRemoving:Connect(function(obj)
    if recording and recording.kind=='GAME' then Core.gameObserveInstance(recording,obj,'remove','ReplicatedStorage') end
end))
end
if t.kind=='VFX' or t.kind=='GAME' then
watch(playerGui.DescendantAdded:Connect(function(obj)
    if Group.worldGui(obj)then Group.observe(obj,true)end
    if recording and recording.kind=='GAME' and obj:IsA('Highlight')then
        Core.gameHighlightObserve(recording,obj,'add')
    end
end))
watch(playerGui.DescendantRemoving:Connect(function(obj)
    if Group.worldGui(obj)then Group.removing(obj)end
    if recording and recording.kind=='GAME' and obj:IsA('Highlight')then
        Core.gameHighlightObserve(recording,obj,'remove')
    end
end))
end
end
local nextUIRefresh=0
local nextIndexStep=0
conn(RunService.PostSimulation:Connect(function()
    if disposed then return end
    -- Index only during effect capture, at a bounded rate and per-step budget.
    if recording and (recording.kind=='VFX' or recording.kind=='GAME')and os.clock()>=nextIndexStep then
        nextIndexStep=os.clock()+1/CFG.INDEX_HZ
        Group.indexStep()
    end
    if recording then
        local t=recording
        local ts=now(t)
        if localPlayer.Character~=t.rigObj.char or not t.rigObj.root.Parent then stopRecord();return end
        if t.kind=='INSPECT' or t.kind=='GAME' then
            if ts>=t.nextInspect then
                Core.inspectSample(t,ts)
                t.nextInspect=(math.floor(ts*CFG.INSPECT_FPS)+1)/CFG.INSPECT_FPS
            end
        end
        if t.kind=='ANIM' or t.kind=='GAME' then
            -- GAME defaults to 30Hz motion to leave budget for VFX + multi-actor capture.
            local motionRate=t.kind=='GAME' and math.min(CFG.FPS,30) or CFG.FPS
            if ts>=t.trackScan then
                Core.scanTracks(t,ts);t.trackScan=ts+(1/motionRate)
            end
            if ts>=t.nextSample then
                if #t.frames>=(t.kind=='GAME' and CFG.GAME_MAX_MOTION_FRAMES or CFG.MAX_SECONDS*CFG.FPS+10) then
                    if t.game then t.game.truncated=true end
                elseif not Core.sampleMotion(t,ts) then stopRecord();return end
                t.nextSample=(math.floor(ts*motionRate)+1)/motionRate
            end
        end
        if (t.kind=='VFX' or t.kind=='GAME') and ts>=t.nextVFX then
            local budget=0
            for obj in pairs(t.vfxPending)do
                if budget>=CFG.SCAN_BUDGET then break end
                Core.vfxAdd(t,obj,ts);t.vfxPending[obj]=nil;t.pendingCount-=1;budget+=1
            end
            Core.vfxRefresh(t,ts)
            local vfxRate=t.kind=='GAME' and CFG.GAME_VFX_FPS or CFG.VFX_FPS
            t.nextVFX=(math.floor(ts*vfxRate)+1)/vfxRate
        end
        if t.kind=='GAME' and ts>=t.nextGame then
            Core.gameSample(t,ts)
            t.nextGame=(math.floor(ts*CFG.GAME_SAMPLE_HZ)+1)/CFG.GAME_SAMPLE_HZ
        end
        -- Status labels are updated below at 8 Hz; capture samples are not throttled here.
        if ts>=CFG.MAX_SECONDS then stopRecord() end
    end
    if playback then Core.tickPreview() end -- preview keeps the simulation-step cadence
    if not gui.Enabled or not window.Visible then return end
    if os.clock()<nextUIRefresh then return end
    nextUIRefresh=os.clock()+.12
    local seconds=recording and now(recording)or 0
    elapsedUI.Text=string.format('%02d:%02d',math.floor(seconds/60),math.floor(seconds%60))
    UI.progress.Size=UDim2.fromScale(math.clamp(seconds/CFG.MAX_SECONDS,0,1),1)
    UI.badge.Text=recording and 'Recording'or 'Ready'
    UI.dot.BackgroundColor3=recording and C.red or C.green
    UI.recordLabel.Text=recording and 'Stop recording'or 'Start recording'
    UI.playIcon.Visible=not recording;UI.stopIcon.Visible=recording~=nil
    UI.record.BackgroundColor3=recording and C.red or C.green
    UI.refreshModes()
    local mode=recording and recording.kind or UI.captureMode
    UI.quality1.Text=(mode=='GAME'and math.min(CFG.FPS,30)or CFG.FPS)..' Hz'
    UI.quality2.Text=(mode=='GAME'and CFG.GAME_VFX_FPS or CFG.VFX_FPS)..' Hz'
    if recording then
        local t=recording
        if t.kind=='GAME' then
            liveUI.Text=string.format('GAME: %d motion | %d VFX | %d actors | %d events%s',
                #t.frames,#t.vfx,#t.inspector.frames,#t.events,
                (t.truncatedVFX or t.inspector.truncated or (t.game and t.game.truncated)) and ' | LIMIT' or '')
        elseif t.kind=='INSPECT' then
            liveUI.Text=string.format('INSPECT: %d samples | %d actors | %d events%s',
                #t.inspector.frames,#t.inspector.actors,#t.events,t.inspector.truncated and ' | LIMIT' or '')
        elseif t.kind=='ANIM' then
            liveUI.Text=string.format('ANIM: %d frames | %d tracks',#t.frames,#t.trackList)
        else
            liveUI.Text=string.format('VFX: %d events | %d active | %s%s',#t.vfx,t.groupCount or 0,
                t.captureStats and t.captureStats.indexWarm and 'indexed' or 'warming index',
                t.truncatedVFX and ' | LIMIT: capture incomplete' or '')
        end
    else
        liveUI.Text=''
    end
    animTab.BackgroundColor3=libraryFilter=='ANIM' and C.blue or C.raised
    vfxTab.BackgroundColor3=libraryFilter=='VFX' and C.blue or C.raised
    inspectTab.BackgroundColor3=libraryFilter=='GAME' and C.blue or C.raised
end))

local function shutdown()
    if disposed then return end
    if recording then stopRecord() end
    if playback then stopPreview() end
    disposed=true
    for _,c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    Core.endCaptureObservers()
    Group.shutdown()
    gui:Destroy()
end
closeRecorder=shutdown
env.GC_MotionBaker_Shutdown=shutdown
if #saved>0 then
    for _,take in ipairs(saved) do
        if (take.kind or 'ANIM')==libraryFilter then selected=take.id;selectedTarget=take.rig;break end
    end
    rigBtn.Text='TARGET: '..selectedTarget
end
UI.refreshToggles();UI.refreshModes();UI.navigate('Capture')
drawLibrary();drawDetails()
-- F3 = Game Recorder, F6 = Motion, F8 = VFX; exact shortcuts remain unchanged.
msg('Saved takes stay on this device')

end -- createInterface
createInterface()
