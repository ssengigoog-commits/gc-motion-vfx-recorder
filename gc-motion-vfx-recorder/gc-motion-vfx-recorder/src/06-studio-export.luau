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
 if data.kind=='VFX'then origin=origin*CFrame.new(0,tonumber(lift)or tonumber(data.previewHeight)or 4,0)end
 if M.active then M.active.Stop()end
 local folder=Instance.new('Folder');folder.Name='GC_TakePreview';folder:SetAttribute('GC_BakerPreview',true);folder.Parent=workspace
 local actors,effects={},{};local renderCurves=Codec.prepare(data.vfx or {})
 local connection;local alive=true;local handle={}
 local function stop()if not alive then return end;alive=false;if connection then connection:Disconnect()end;folder:Destroy();if M.active==handle then M.active=nil end end
 if data.kind=='ANIM'or data.kind=='COMBINED'then
  local list={data};for _,a in ipairs(data.actors or {})do list[#list+1]=a end
  for _,a in ipairs(list)do if #(a.frames or {})>0 then
   local model=Instance.new('Model');model.Name=a.actor and(a.actor.username or a.actor.name)or 'RecordedActor';model.Parent=folder
   local parts={}
   local names={'HumanoidRootPart'};for _,c in ipairs(a.channels or {})do names[#names+1]=c.child end
   for _,name in ipairs(names)do if not parts[name]then
    local p=Instance.new('Part');p.Name=name;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
    local size=a.metrics and a.metrics[name]and a.metrics[name].size
    p.Size=size and Vector3.new(table.unpack(size))or Vector3.new(1,2,1);p.Color=Color3.fromRGB(180,195,210)
    p.Transparency=name=='HumanoidRootPart'and 1 or 0;p.Parent=model;parts[name]=p
   end end
   local tag=Instance.new('BillboardGui');tag.Adornee=parts.Head or parts.HumanoidRootPart;tag.Size=UDim2.fromOffset(240,36);tag.StudsOffset=Vector3.new(0,2.5,0);tag.AlwaysOnTop=true;tag.Parent=model
   local text=Instance.new('TextLabel');text.Size=UDim2.fromScale(1,1);text.BackgroundTransparency=1;text.Text=model.Name;text.TextSize=14;text.TextColor3=Color3.new(1,1,1);text.TextStrokeTransparency=.25;text.Parent=tag
   local events={};for _,event in ipairs(a.events or {})do if event.type=='VISIBILITY'then events[#events+1]=event end end
   table.sort(events,function(x,y)return x.t<y.t end)
   actors[#actors+1]={data=a,parts=parts,index=1,visibilityEvents=events,visibilityIndex=1}
  end end
 end
 for _,e in ipairs(data.vfx or {})do if e.op=='group_spawn'then Codec.preload(e.snapshot)end end
 local begun=os.clock();local eventIndex=1
 local function tick()
  local age=math.min(os.clock()-begun,data.duration or 0)
  for _,actor in ipairs(actors)do
   local frames=actor.data.frames;local index=actor.index
   while index<#frames-1 and frames[index+1].t<age do index+=1 end;actor.index=index
   local a,b=frames[index],frames[math.min(index+1,#frames)]
   local x=b.t>a.t and math.clamp((age-a.t)/(b.t-a.t),0,1)or 0
   if b.distance and b.distance.discontinuity then x=age>=b.t and 1 or 0 end
   local root=origin*cf(a.root):Lerp(cf(b.root),x)
   actor.parts.HumanoidRootPart.CFrame=root
   while actor.visibilityIndex<=#actor.visibilityEvents and actor.visibilityEvents[actor.visibilityIndex].t<=age do actor.visibility=actor.visibilityEvents[actor.visibilityIndex];actor.visibilityIndex+=1 end
   for name,p in pairs(actor.parts)do if name~='HumanoidRootPart'then
    if a.parts and b.parts and a.parts[name]and b.parts[name]then p.CFrame=root*cf(a.parts[name]):Lerp(cf(b.parts[name]),x)end
    local visibleFrame=age>=b.t and b or a
    local visibility=actor.visibility or visibleFrame.visibility
    if visibility then p.Transparency=visibility.parts[name]or(visibility.hidden and 1 or 0)end
   end end
  end
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
assert((data.version==4 or data.version==5 or data.version==6 or data.version==7) and (data.kind==nil or data.kind=='ANIM') and type(data.frames)=='table' and #data.frames>0,'Invalid GC animation recording')
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
    if (data.version==6 or data.version==7)and not data.sceneSubtake then exported=exported..'\n'..Core.studioGroupedImporter(data) end
    return exported
end

-- Export a VFX-only take to real, inert Studio preview templates.
-- These are snapshots of CLIENT-OBSERVABLE effects, not ServerStorage originals.
 function Core.studioVfxImporter(data)
    if data.version==6 or data.version==7 then return Core.studioGroupedImporter(data)end
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


-- Scene export retains each actor's keyframes and the synchronized VFX raw timeline.
function Core.studioSceneImporter(data,target)
 local chunks={'-- GC v7 scene import. Run only in Studio Edit mode.'}
 local actors={data};for _,actor in ipairs(data.actors or {})do actors[#actors+1]=actor end
 for index,actor in ipairs(actors)do
  if #(actor.frames or {})>0 then
   local piece=table.clone(data)
   for _,key in ipairs({'frames','channels','metrics','events','tracks','rig','actor','distance'})do piece[key]=actor[key]end
   piece.actors=nil;piece.vfx={};piece.kind='ANIM';piece.sceneSubtake=true
   local identity=actor.actor or {}
   piece.name=(data.name or 'Scene')..' / '..(identity.username or identity.name or ('Actor '..index))
   chunks[#chunks+1]='do\n'..Core.studioImporter(piece,target)..'\nend'
  end
 end
 if data.version==7 then chunks[#chunks+1]='do\n'..Core.studioGroupedImporter(data)..'\nend'
 elseif #(data.vfx or {})>0 then chunks[#chunks+1]='do\n'..Core.studioVfxImporter(data)..'\nend'end
 return table.concat(chunks,'\n')
end
