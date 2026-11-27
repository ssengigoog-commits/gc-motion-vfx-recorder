local function find(parent,name)
 if parent.Name==name then return parent end
 for _,c in ipairs(parent:GetChildren())do local result=find(c,name);if result then return result end end
end
local root=assert(find(playerGui,'RecorderWindow'))
RunService.PostSimulation:Fire()
assert(find(root,'Navigation').Size.X.Offset==207,'reference sidebar width regressed')
assert(find(root,'ElapsedTime').TextSize==96,'reference timer hierarchy regressed')
assert(find(root,'Header').Size.Y.Offset==65,'reference header height regressed')
for _,name in {'camera','film','gear','gamepad','runner','sparkles','play','actors'}do assert(find(root,'Icon_'..name),'missing reference glyph '..name)end
local function click(name,parent)local b=assert(find(parent or root,name),name);b.MouseButton1Click:Fire();return b end
local function copyValue(v)
 if type(v)~='table'then return v end
 local t={};for k,x in pairs(v)do if type(x)~='function'then t[k]=copyValue(x)end end;return t
end
local function dump(o)
 local props={};for k,v in pairs(o.props)do if k~='Parent'and type(v)~='function'then props[k]=copyValue(v)end end
 local children={};for _,c in ipairs(o:GetChildren())do children[#children+1]=dump(c)end
 return {props=props,children=children}
end
local capture=dump(root)
assert(find(root,'CapturePage').Visible and not find(root,'LibraryPage').Visible)
click('NavSettings');assert(find(root,'SettingsPage').Visible and not find(root,'CapturePage').Visible)
local settings=dump(root)
click('IncludeNPCsToggle',find(root,'SettingsPage'));assert(not CFG.INCLUDE_NPCS and CFG.INCLUDE_PLAYERS)
assert(find(find(root,'CapturePage'),'IncludeNPCsToggle').Text=='OFF ')
click('NavCapture');click('StartStopRecording');assert(recording.kind=='GAME')
click('IncludePlayersToggle',find(root,'CapturePage'));assert(CFG.INCLUDE_PLAYERS)
click('StartStopRecording');assert(recording==nil)
click('ModeANIM');click('StartStopRecording');assert(recording.kind=='ANIM');click('StartStopRecording')
click('ChooseActors');assert(find(root,'ActorPicker').Visible)
click('NavLibrary');assert(find(root,'LibraryPage').Visible)
assert(find(playerGui,'RecorderWindow')==root,'page change rebuilt/reverted the theme')
local library=dump(root)
UIS.InputBegan:Fire({name='F7'},false);assert(not root.Visible)
UIS.InputBegan:Fire({name='F7'},false);assert(root.Visible)
for _,size in ipairs({{1920,1080},{1280,720},{1024,576},{800,600}})do
 workspace.CurrentCamera.ViewportSize=Vector2.new(size[1],size[2]);workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Fire()
 local scale=find(root,'UIScale').Scale;assert(1120*scale<=size[1]-23 and 720*scale<=size[2]-23)
end
click('CloseRecorder');assert(disposed and root.Destroyed)
for _,c in ipairs(connections)do assert(not c.Connected)end
local function json(v)
 if v==nil then return 'null'end
 if type(v)=='string'then return '"'..v:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t')..'"'end
 if type(v)=='number'or type(v)=='boolean'then return tostring(v)end
 local parts={};local array=#v>0
 if array then for _,x in ipairs(v)do parts[#parts+1]=json(x)end;return '['..table.concat(parts,',')..']'end
 for k,x in pairs(v)do parts[#parts+1]=json(tostring(k))..':'..json(x)end
 return '{'..table.concat(parts,',')..'}'
end
print(json({mockedUI=true,checksPassed=true,capture=capture,settings=settings,library=library}))
