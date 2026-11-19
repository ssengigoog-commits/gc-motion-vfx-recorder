-- Offline, translation-only Roblox stubs. Not a Studio physics/visual test.
local passed=0
local function check(ok,label)assert(ok,label);passed+=1;print('PASS '..label)end
local V={};V.__index=function(v,k)if k=='Magnitude'then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z)end;return V[k]end
V.__add=function(a,b)return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
V.__sub=function(a,b)return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
V.__div=function(a,b)return Vector3.new(a.X/b,a.Y/b,a.Z/b)end
local CV={};CV.__index=function(v,k)if k=='Position'then return Vector3.new(v.X,v.Y,v.Z)end;return CV[k]end;CV.__mul=function(a,b)return CFrame.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
function CV:GetComponents()return self.X,self.Y,self.Z,1,0,0,0,1,0,0,0,1 end
function CV:Inverse()return CFrame.new(-self.X,-self.Y,-self.Z)end
function CV:ToObjectSpace(b)return self:Inverse()*b end
function CV:VectorToObjectSpace(b)return b end
function CV:Lerp(b,t)return CFrame.new(self.X+(b.X-self.X)*t,self.Y+(b.Y-self.Y)*t,self.Z+(b.Z-self.Z)*t)end
Vector3={new=function(x,y,z)return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},V)end}
CFrame={new=function(x,y,z)return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},CV)end};CFrame.identity=CFrame.new()
Color3={new=function(r,g,b)return {R=r,G=g,B=b}end,fromRGB=function(r,g,b)return {R=r/255,G=g/255,B=b/255}end}
Enum=setmetatable({},{__index=function(t,k)local v=setmetatable({},{__index=function(_,n)return n end});rawset(t,k,v);return v end})
Content={fromUri=function(x)return x end}
local function signal()local s={callbacks={}};function s:Connect(f)local c={active=true};self.callbacks[#self.callbacks+1]={c,f};function c:Disconnect()self.active=false end;return c end;function s:Fire(...)for _,v in ipairs(self.callbacks)do if v[1].active then v[2](...)end end end;return s end
local methods={}
local partClass={Part=true,MeshPart=true,UnionOperation=true,WedgePart=true,CornerWedgePart=true}
function methods:IsA(k)return self.ClassName==k or (k=='BasePart'and partClass[self.ClassName])or(k=='Light'and self.ClassName:find('Light')~=nil)or k=='Instance'end
function methods:GetChildren()local r={};for _,c in ipairs(self._kids)do if c.Parent==self then r[#r+1]=c end end;return r end
function methods:FindFirstChild(n)for _,c in ipairs(self:GetChildren())do if c.Name==n then return c end end end
function methods:FindFirstChildOfClass(k)for _,c in ipairs(self:GetChildren())do if c:IsA(k)then return c end end end
function methods:FindFirstChildWhichIsA(k,recursive)for _,c in ipairs(self:GetChildren())do if c:IsA(k)then return c end;if recursive then local x=c:FindFirstChildWhichIsA(k,true);if x then return x end end end end
function methods:FindFirstAncestorOfClass(k)local p=self.Parent;while p do if p:IsA(k)then return p end;p=p.Parent end end
function methods:IsDescendantOf(o)local p=self.Parent;while p do if p==o then return true end;p=p.Parent end;return false end
function methods:GetFullName()return self.Parent and self.Parent:GetFullName()..'.'..self.Name or self.Name end
function methods:SetAttribute(k,v)self._attrs[k]=v end
function methods:GetAttribute(k)return self._attrs[k]end
function methods:GetAttributes()return table.clone(self._attrs)end
function methods:Destroy()self.Parent=nil;self._dead=true end
function methods:Clone()local o=Instance.new(self.ClassName);for k,v in pairs(self._props)do if k~='Parent'and k~='Changed'and k~='DescendantAdded'and k~='DescendantRemoving'then o[k]=v end end;return o end
local IM={__index=function(o,k)
 if methods[k]then return methods[k]end
 if k=='Position'then return Vector3.new(o.CFrame.X,o.CFrame.Y,o.CFrame.Z)end
 if k=='WorldCFrame'then return o.Parent and o.Parent.CFrame*o.CFrame or o.CFrame end
 if k=='WorldPosition'then local c=o.WorldCFrame;return Vector3.new(c.X,c.Y,c.Z)end
 return o._props[k]
end,__newindex=function(o,k,v)
 if k:sub(1,1)=='_'then rawset(o,k,v);return end
 local old=o._props[k];o._props[k]=v
 if k=='Parent'and old~=v and v then v._kids[#v._kids+1]=o end
 if o._props.Changed then o._props.Changed:Fire(k)end
 if o._signals and o._signals[k]then o._signals[k]:Fire()end
end}
Instance={new=function(class)
 local o=setmetatable({_props={},_attrs={},_kids={}},IM)
 o.ClassName=class;o.Name=class;o.Changed=signal();o.DescendantAdded=signal();o.DescendantRemoving=signal()
 o.CFrame=CFrame.new();o.Size=Vector3.new(1,1,1);o.Enabled=true;o.Rate=20;o.Transparency=0
 return o
end}
local loads=0
local asset={CreateMeshPartAsync=function(_,id)loads+=1;if id=='denied'then error('permission denied')end;return Instance.new('MeshPart')end}
game={GetService=function(_,name)if name=='AssetService'then return asset end;error(name)end}
workspace=Instance.new('Model');workspace.Name='Workspace';workspace.Terrain=Instance.new('Model');workspace.Terrain.Parent=workspace
local function typeof(x)if getmetatable(x)==CV then return 'CFrame'elseif getmetatable(x)==V then return 'Vector3'elseif type(x)=='table'and x.R then return 'Color3'else return type(x)end end



-- Minimal offline engine doubles. Geometry/animation rendering is not simulated.
local Test={clock=0,queryCount=0,passed=0,json={},queryParts={}}
local os=table.clone(os);os.clock=function()return Test.clock end
function methods:WaitForChild(name)return self:FindFirstChild(name)end
function methods:GetDescendants()
 local out={};local function walk(p)for _,c in ipairs(p:GetChildren())do out[#out+1]=c;walk(c)end end;walk(self);return out
end
function methods:GetPropertyChangedSignal(name)
 self._signals=self._signals or {};if not self._signals[name]then self._signals[name]=signal()end;return self._signals[name]
end
function methods:FindFirstAncestorWhichIsA(name)return self:FindFirstAncestorOfClass(name)end
function methods:Emit(count)self._emitted=count end
UDim2={fromOffset=function(x,y)return {x,y}end,fromScale=function(x,y)return {x,y}end}
UDim={new=function(a,b)return {a,b}end}
OverlapParams={new=function()return {}end}
RaycastParams={new=function()return {}end}
task={wait=function()end,spawn=function(f,...)f(...)end}
warn=function(...)print('WARN',...)end
function Test.check(ok,label)assert(ok,label);Test.passed+=1;print('PASS '..label)end
function Test.near(a,b)return math.abs(a-b)<.0001 end
function Test.rig(name,x)
 local char=Instance.new('Model');char.Name=name;char.Parent=workspace
 local hum=Instance.new('Humanoid');hum.Name='Humanoid';hum.Health=100;hum.WalkSpeed=16;hum.JumpPower=50;hum.JumpHeight=7
 hum.RigType=Enum.HumanoidRigType.R6;hum.MoveDirection=Vector3.new();hum.FloorMaterial={Name='Grass'}
 function hum:GetState()return {Name='Running'}end;hum.Parent=char
 local anim=Instance.new('Animator');anim.Name='Animator';anim._tracks={}
 function anim:GetPlayingAnimationTracks()return self._tracks end;anim.Parent=hum
 local root=Instance.new('Part');root.Name='HumanoidRootPart';root.CFrame=CFrame.new(x or 0,0,0);root.AssemblyLinearVelocity=Vector3.new();root.LocalTransparencyModifier=0;root.Parent=char
 for _,name in ipairs({'Torso','Head','Right Arm','Left Arm','Right Leg','Left Leg'})do
  local p=Instance.new('Part');p.Name=name;p.CFrame=root.CFrame;p.LocalTransparencyModifier=0;p.Parent=char
  local j=Instance.new('Motor6D');j.Name=name;j.Part0=root;j.Part1=p;j.C0=CFrame.new();j.C1=CFrame.new();j.Parent=root
 end
 return char
end
Test.selfChar=Test.rig('SelfCharacter',0)
Test.npcA=Test.rig('NPC_A',10);Test.npcB=Test.rig('NPC_B',20)
Test.otherChar=Test.rig('OtherCharacter',15)
Test.player=Instance.new('Player');Test.player.Name='MyUsername';Test.player.UserId=11;Test.player.DisplayName='My Display';Test.player.Character=Test.selfChar
Test.other=Instance.new('Player');Test.other.Name='OtherUsername';Test.other.UserId=22;Test.other.DisplayName='Other Display';Test.other.Character=Test.otherChar
local pg=Instance.new('PlayerGui');pg.Name='PlayerGui';pg.Parent=Test.player
local players={LocalPlayer=Test.player}
function players:GetPlayers()return {Test.player,Test.other}end
function players:GetPlayerFromCharacter(c)if c==Test.selfChar then return Test.player elseif c==Test.otherChar then return Test.other end end
local uis={MouseBehavior={Name='Default'}}
function uis:IsKeyDown()return false end
function uis:IsMouseButtonPressed()return false end
function uis:GetFocusedTextBox()return nil end
local run={PostSimulation=signal(),RenderStepped=signal()}
local http={}
function http:JSONEncode(value)local key='TEST_JSON_'..(#Test.json+1);Test.json[#Test.json+1]=value;Test.json[key]=value;return key end
function http:JSONDecode(key)return Test.json[key]end
local services={Players=players,UserInputService=uis,RunService=run,HttpService=http,AssetService=asset}
game.GetService=function(_,name)return assert(services[name],name)end
function workspace:Raycast()return nil end
function workspace:GetPartBoundsInRadius(position,radius,params)
 Test.queryCount+=1;local out={}
 for _,p in ipairs(Test.queryParts)do if p.Parent and (p.Position-position).Magnitude<=radius then out[#out+1]=p;if #out>=(params.MaxParts or 999)then break end end end
 return out
end
for _,c in ipairs({Test.selfChar,Test.npcA,Test.npcB,Test.otherChar})do Test.queryParts[#Test.queryParts+1]=c:FindFirstChild('HumanoidRootPart')end


-- UI/event doubles for the integration smoke test.
Vector2={new=function(x,y)return {X=x,Y=y}end}
UDim2.new=function(...)return {...}end
local originalNew=Instance.new
Instance.new=function(class)
 local o=originalNew(class)
 for _,name in ipairs({'MouseButton1Click','FocusLost','InputBegan','InputEnded'})do o[name]=signal()end
 o.AbsoluteContentSize=Vector2.new(0,0)
 return o
end
uis.InputBegan=signal();uis.InputEnded=signal();uis.InputChanged=signal()
function run:IsRunning()return false end
function run:IsStudio()return true end
services.ServerStorage=Instance.new('Folder');services.ServerStorage.Name='ServerStorage'
services.ReplicatedStorage=Instance.new('Folder');services.ReplicatedStorage.Name='ReplicatedStorage'
services.RunService=run

Test.env={}
getgenv=function()return Test.env end

function methods:AddMarker(marker)marker.Parent=self end
function methods:AddKeyframe(frame)frame.Parent=self end
function methods:AddPose(pose)pose.Parent=self end
