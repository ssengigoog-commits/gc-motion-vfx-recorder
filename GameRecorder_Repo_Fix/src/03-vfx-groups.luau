
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
