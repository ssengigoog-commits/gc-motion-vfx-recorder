-- Test-only native UI construction model. This is NOT Roblox gameplay telemetry.
local function signal()
 local s={listeners={}}
 function s:Connect(fn)local c={Connected=true};function c:Disconnect()self.Connected=false end;self.listeners[#self.listeners+1]={fn=fn,connection=c};return c end
 function s:Fire(...)for _,e in ipairs(self.listeners)do if e.connection.Connected then e.fn(...)end end end
 return s
end
local methods={}
local nodes={}
local guiClasses={Frame=true,TextLabel=true,TextButton=true,TextBox=true,ScrollingFrame=true}
local eventNames={MouseButton1Click=true,MouseEnter=true,MouseLeave=true,InputBegan=true,InputEnded=true,InputChanged=true,DescendantAdded=true,DescendantRemoving=true,CharacterAdded=true,PostSimulation=true}
local nodeMeta={}
function nodeMeta.__index(o,key)
 if methods[key]then return methods[key]end
 if o.props[key]~=nil then return o.props[key]end
 if key=='AbsoluteContentSize'then return {X=0,Y=0}end
 if eventNames[key]then o.events[key]=o.events[key]or signal();return o.events[key]end
 for _,child in ipairs(o.children)do if child.Name==key then return child end end
 return nil
end
function nodeMeta.__newindex(o,key,value)
 if key=='Parent'then
  local old=o.props.Parent
  if old then for i,x in ipairs(old.children)do if x==o then table.remove(old.children,i);break end end end
  if value then value.children[#value.children+1]=o end
 end
 o.props[key]=value
end
function methods:GetChildren()return table.clone(self.children)end
function methods:IsA(name)return name==self.ClassName or(name=='GuiObject'and guiClasses[self.ClassName])or false end
function methods:FindFirstChild(name)for _,c in ipairs(self.children)do if c.Name==name then return c end end end
function methods:FindFirstChildOfClass(name)for _,c in ipairs(self.children)do if c.ClassName==name then return c end end end
function methods:WaitForChild(name)return assert(self:FindFirstChild(name),name)end
function methods:GetPropertyChangedSignal(name)self.events[name]=self.events[name]or signal();return self.events[name]end
function methods:Destroy()
 for _,c in ipairs(self:GetChildren())do c:Destroy()end
 for _,s in pairs(self.events)do for _,e in ipairs(s.listeners)do e.connection:Disconnect()end end
 self.Parent=nil;self.props.Destroyed=true
end
local Instance={}
function Instance.new(class)
 local n=setmetatable({props={ClassName=class,Name=class,Visible=true},children={},events={}},nodeMeta)
 nodes[#nodes+1]=n;return n
end
local UDim={new=function(s,o)return {Scale=s,Offset=o}end}
local UDim2={}
function UDim2.new(xs,xo,ys,yo)return {X=UDim.new(xs,xo),Y=UDim.new(ys,yo)}end
function UDim2.fromOffset(x,y)return UDim2.new(0,x,0,y)end
function UDim2.fromScale(x,y)return UDim2.new(x,0,y,0)end
local Vector2={new=function(x,y)return {X=x,Y=y}end}
local Color3={fromRGB=function(r,g,b)return {R=r/255,G=g/255,B=b/255}end}
local ColorSequence={new=function(a,b)return {Keypoints={{Time=0,Value=a},{Time=1,Value=b}}}end}
local Enum=setmetatable({},{__index=function(t,name)
 local family=setmetatable({},{__index=function(f,key)local value=name..'.'..key;rawset(f,key,value);return value end})
 rawset(t,name,family);return family
end})
local workspace=Instance.new('Workspace');workspace.CurrentCamera=Instance.new('Camera');workspace.CurrentCamera.ViewportSize=Vector2.new(1280,800)
local playerGui=Instance.new('PlayerGui')
local UIS=Instance.new('UserInputService');function UIS:GetFocusedTextBox()return nil end
local RunService=Instance.new('RunService')
local replicated=Instance.new('ReplicatedStorage')
local game={GetService=function(_,name)assert(name=='ReplicatedStorage');return replicated end}
local task={defer=function(f)f()end}
local env={};local Core={};local writes={}
local CFG={GUI='GC_MotionVFX_Baker_v7',FPS=60,VFX_FPS=60,MAX_SECONDS=120,INSPECT_MAX_ACTORS=4,
 INSPECT_FPS=10,GAME_VFX_FPS=15,INCLUDE_NPCS=true,INCLUDE_PLAYERS=true,SETTINGS='GC_BAKER_SETTINGS_v7.json'}
local saved,selected,recording,playback={},nil,nil,nil
local libraryFilter='ANIM'
local disposed=false;local connections={};local statusLabel;local drawLibrary,drawDetails
local estimateBurstPreview=true
local localPlayer=Instance.new('Player');localPlayer.Name='PreviewPlayer'
local Group={indexStep=function()end,observe=function()end,worldGui=function()return false end,shutdown=function()end}
local WATCH={}
local function conn(c)connections[#connections+1]=c;return c end
local function msg(s,c)if statusLabel then statusLabel.Text=s end end
local function now(t)return 0 end
local function stopPreview()playback=nil end
local function stopRecord()recording=nil end
local function loadData()return nil end
local HttpService={JSONEncode=function()return 'settings'end}
Core.safeRead=function()return nil end
Core.safeWrite=function(p)writes[#writes+1]=p;return true end
Core.inputName=function(input)return input.name end
Core.startRecord=function(mode)if recording then if recording.kind==mode then recording=nil end else recording={kind=mode}end end
local fixtures={{model={},label='PreviewPlayer',role='self',distance=0,selected=true},
 {model={},label='Training Dummy',role='npc',distance=8,selected=false}}
Core.inspectCandidates=function()local out={}for _,a in ipairs(fixtures)do if Core.actorRoleEnabled(a.role)then out[#out+1]=a end end return out end
Core.inspectToggle=function(model)for _,a in ipairs(fixtures)do if a.model==model then a.selected=not a.selected;return true,'Selection updated'end end end
