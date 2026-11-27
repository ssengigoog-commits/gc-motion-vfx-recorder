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
label(capture,'F3 Game: motion + VFX · actors within 60 studs',UDim2.fromOffset(6,486),UDim2.fromOffset(492,56),15,C.sub).TextWrapped=true
local subjects=card(capture,'CaptureSubjects',UDim2.fromOffset(522,-3),UDim2.fromOffset(350,318))
label(subjects,'Game capture subjects',UDim2.fromOffset(18,12),UDim2.fromOffset(314,32),24).Font=Enum.Font.GothamBold
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
label(subjects,'F3 Game only · includes VFX',UDim2.fromOffset(18,166),UDim2.fromOffset(314,29),17,C.sub)
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
local playButton=btn(right,'PLAY',UDim2.fromOffset(11,350),UDim2.fromOffset(368,32),C.blue,function() Core.playSelected(loopOn) end)
playButton.Name='PlaySelectedRecording'
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
