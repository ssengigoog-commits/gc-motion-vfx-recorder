-- UI locals live in a separate function, outside the recording scope.
local function createInterface()
-- ---------- recorder UI ----------
local C={bg=Color3.fromRGB(16,19,26),panel=Color3.fromRGB(30,34,44),
    raised=Color3.fromRGB(43,49,61),line=Color3.fromRGB(70,80,98),
    white=Color3.fromRGB(238,243,250),sub=Color3.fromRGB(155,171,188),
    blue=Color3.fromRGB(70,160,201),red=Color3.fromRGB(202,83,85),green=Color3.fromRGB(58,164,119)}
local old=playerGui:FindFirstChild(CFG.GUI)
if old then old:Destroy() end
local gui=Instance.new('ScreenGui');gui.Name=CFG.GUI;gui.ResetOnSpawn=false;gui.DisplayOrder=10000
 gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.Parent=playerGui
local function mk(class,parent,props)
    local obj=Instance.new(class)
    for k,v in pairs(props or {}) do obj[k]=v end
    obj.Parent=parent;return obj
end
local function rounded(obj)
    mk('UICorner',obj,{CornerRadius=UDim.new(0,7)})
end
local function label(parent,s,pos,size,font,col)
    return mk('TextLabel',parent,{BackgroundTransparency=1,Text=s,Position=pos,Size=size,
        Font=Enum.Font.Gotham,TextSize=font or 13,TextColor3=col or C.white,
        TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center})
end
local function btn(parent,s,pos,size,color,callback)
    local x=mk('TextButton',parent,{Text=s,Position=pos,Size=size,BackgroundColor3=color or C.raised,
        TextColor3=C.white,Font=Enum.Font.GothamBold,TextSize=12,BorderSizePixel=0})
    rounded(x); x.MouseButton1Click:Connect(callback);return x
end
local window=mk('Frame',gui,{Position=UDim2.fromScale(.5,.5),AnchorPoint=Vector2.new(.5,.5),
    Size=UDim2.fromOffset(1050,660),BackgroundColor3=C.bg,BorderSizePixel=0})
rounded(window)
local bar=mk('Frame',window,{Position=UDim2.fromOffset(0,0),Size=UDim2.new(1,0,0,55),
    BackgroundColor3=C.panel,BorderSizePixel=0})
rounded(bar)
local heading=label(bar,'GRAND CLOVER  /  MOTION + VFX BAKER V7',UDim2.fromOffset(16,7),UDim2.fromOffset(750,22),17,C.white)
heading.Font=Enum.Font.GothamBold
label(bar,'R6 + R15  •  evaluated joints, root/jump motion, grouped VFX + meshes',UDim2.fromOffset(17,30),UDim2.fromOffset(760,17),11,C.sub)
btn(bar,'HIDE (F7)',UDim2.new(1,-111,0,11),UDim2.fromOffset(99,32),C.raised,function() window.Visible=false end)
statusLabel=label(window,'Ready — F6 = Animation REC | F8 = VFX REC.',UDim2.fromOffset(16,63),UDim2.fromOffset(505,24),12,C.sub)
local animRecBtn=btn(window,'REC ANIM (F6)',UDim2.new(1,-258,0,62),UDim2.fromOffset(118,37),C.green,function()
    Core.startRecord('ANIM')
end)
local vfxRecBtn=btn(window,'REC VFX (F8)',UDim2.new(1,-132,0,62),UDim2.fromOffset(118,37),C.blue,function()
    Core.startRecord('VFX')
end)
local combinedRecBtn=btn(window,'REC ANIM + VFX (F9)',UDim2.fromOffset(540,62),UDim2.fromOffset(237,37),C.blue,function()Core.startRecord('COMBINED')end)
local elapsedUI=label(window,'0.0 / 30.0 s',UDim2.fromOffset(16,91),UDim2.fromOffset(145,17),11,C.sub)
local liveUI=label(window,'FPS 60  •  Waiting',UDim2.fromOffset(173,91),UDim2.new(1,-200,0,17),11,C.sub)
local left=mk('Frame',window,{Position=UDim2.fromOffset(12,118),Size=UDim2.fromOffset(322,478),BackgroundColor3=C.panel,BorderSizePixel=0})
local right=mk('Frame',window,{Position=UDim2.fromOffset(345,118),Size=UDim2.fromOffset(692,478),BackgroundColor3=C.panel,BorderSizePixel=0})
rounded(left);rounded(right)
local animTab
local vfxTab
local combinedTab
local function setLibraryFilter(mode)
    if recording then msg('Finish recording before changing libraries.');return end
    libraryFilter=mode;selected=nil
    for _,t in ipairs(saved) do
        if (t.kind or 'ANIM')==mode then selected=t.id;break end
    end
    animTab.BackgroundColor3=mode=='ANIM' and C.blue or C.raised
    vfxTab.BackgroundColor3=mode=='VFX' and C.blue or C.raised
    if drawLibrary then drawLibrary() end
    if drawDetails then drawDetails() end
end
animTab=btn(left,'ANIM',UDim2.fromOffset(11,8),UDim2.fromOffset(95,26),C.blue,function() setLibraryFilter('ANIM') end)
vfxTab=btn(left,'VFX',UDim2.fromOffset(111,8),UDim2.fromOffset(95,26),C.raised,function() setLibraryFilter('VFX') end)
combinedTab=btn(left,'BOTH',UDim2.fromOffset(211,8),UDim2.fromOffset(95,26),C.raised,function()setLibraryFilter('COMBINED')end)
local search=mk('TextBox',left,{Position=UDim2.fromOffset(11,38),Size=UDim2.fromOffset(300,35),
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
local idsHeader=label(right,'ANIMATION IDs',UDim2.fromOffset(12,69),UDim2.fromOffset(230,18),12,C.blue)
idsHeader.Font=Enum.Font.GothamBold
label(right,'EVENT TIMELINE (time in seconds)',UDim2.fromOffset(282,69),UDim2.fromOffset(390,18),12,C.blue).Font=Enum.Font.GothamBold
local ids=mk('ScrollingFrame',right,{Position=UDim2.fromOffset(9,91),Size=UDim2.fromOffset(263,210),
    BackgroundColor3=C.raised,BorderSizePixel=0,ScrollBarThickness=4,CanvasSize=UDim2.fromOffset(0,0)})
local timeline=mk('ScrollingFrame',right,{Position=UDim2.fromOffset(282,91),Size=UDim2.fromOffset(398,210),
    BackgroundColor3=C.raised,BorderSizePixel=0,ScrollBarThickness=4,CanvasSize=UDim2.fromOffset(0,0)})
rounded(ids);rounded(timeline)
local idLayout=mk('UIListLayout',ids,{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.LayoutOrder})
local timelineLayout=mk('UIListLayout',timeline,{Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder})
local loopOn=false
local loopBtn
local selectedTarget='R6'
local rigBtn
rigBtn=btn(right,'TARGET: R6',UDim2.fromOffset(11,311),UDim2.fromOffset(130,31),C.raised,function()
    selectedTarget=selectedTarget=='R6' and 'R15' or 'R6'
    rigBtn.Text='TARGET: '..selectedTarget
end)
loopBtn=btn(right,'LOOP: OFF',UDim2.fromOffset(151,311),UDim2.fromOffset(128,31),C.raised,function()
    loopOn=not loopOn
    loopBtn.Text='LOOP: '..(loopOn and 'ON' or 'OFF')
    loopBtn.BackgroundColor3=loopOn and C.blue or C.raised
end)
local burstBtn
burstBtn=btn(right,'BURST EST: ON',UDim2.fromOffset(289,311),UDim2.fromOffset(152,31),C.blue,function()
    estimateBurstPreview=not estimateBurstPreview
    burstBtn.Text='BURST EST: '..(estimateBurstPreview and 'ON' or 'OFF')
    burstBtn.BackgroundColor3=estimateBurstPreview and C.blue or C.raised
    msg('Estimated bursts are '..(estimateBurstPreview and 'ON: preview 12 particles (not an exact capture).' or 'OFF: Emit()-only effects might be invisible.'))
end)
local function getSelectedTake()
    for _,t in ipairs(saved) do if t.id==selected then return t end end
    return nil
end
local copyBox=mk('Frame',gui,{Visible=false,Position=UDim2.fromScale(.5,.5),AnchorPoint=Vector2.new(.5,.5),
    Size=UDim2.fromOffset(820,540),BackgroundColor3=C.bg,BorderSizePixel=0})
rounded(copyBox)
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
    if kind=='studio' and Core.hasMotion(t.kind or 'ANIM')then
        s=Core.studioSceneImporter(d,selectedTarget)
        filename=CFG.PREFIX..t.id..'_STUDIO_'..selectedTarget..'.lua'
    elseif kind=='studio' and (t.kind or 'ANIM')=='VFX' then
        s=Core.studioVfxImporter(d)
        filename=CFG.PREFIX..t.id..'_VFX_STUDIO.lua'
    elseif kind=='vfx' then
        s=Core.exportJson({version=7,name=d.name,duration=d.duration,vfx=d.vfx,
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
btn(right,'PLAY MOTION / BOTH',UDim2.fromOffset(11,350),UDim2.fromOffset(200,32),C.blue,function() Core.playSelection('ANIM',loopOn) end)
btn(right,'PLAY VFX AHEAD',UDim2.fromOffset(219,350),UDim2.fromOffset(200,32),C.blue,function() Core.playSelection('VFX',loopOn) end)
btn(right,'STOP',UDim2.fromOffset(427,350),UDim2.fromOffset(105,32),C.red,function() stopPreview() end)
btn(right,'COPY RAW',UDim2.fromOffset(11,394),UDim2.fromOffset(128,35),C.raised,function() exportTake('raw') end)
btn(right,'COPY VFX JSON',UDim2.fromOffset(147,394),UDim2.fromOffset(128,35),C.raised,function() exportTake('vfx') end)
btn(right,'EXPORT STUDIO',UDim2.fromOffset(283,394),UDim2.fromOffset(249,35),C.green,function() exportTake('studio') end)
btn(right,'SPLIT VFX',UDim2.fromOffset(540,394),UDim2.fromOffset(140,35),C.blue,function()
 if recording then msg('Stop recording before splitting.');return end
 local take=getSelectedTake();if take then Core.splitVfx(take)end
end)
local caution=label(right,'Effect-only capture; burst estimates are labeled. World-image VFX supported; unavailable assets are marked.',
    UDim2.fromOffset(12,439),UDim2.new(1,-20,0,31),11,C.sub)
caution.TextWrapped=true
label(window,'F6 motion  •  F8 VFX  •  F9 synchronized take  •  F7 UI  •  SETTINGS selects actors/rates',
    UDim2.fromOffset(15,608),UDim2.fromOffset(865,24),12,C.sub)

-- Capture settings are applied between takes. The recorder never controls actors.
local settingsPanel=mk('Frame',window,{Visible=false,Position=UDim2.fromOffset(20,118),Size=UDim2.fromOffset(1010,478),BackgroundColor3=C.bg,BorderSizePixel=0,ZIndex=10})
local function settingLabel(text,y)
 local x=label(settingsPanel,text,UDim2.fromOffset(20,y),UDim2.fromOffset(960,26),13,C.white);x.ZIndex=11;return x
end
settingLabel('RECORDING SETTINGS — maximum '..CFG.MAX_SECONDS..'s per take',12)
local function toggleSetting(key,title,y)
 local button
 button=btn(settingsPanel,title..': '..(Core.Settings[key]and 'ON'or 'OFF'),UDim2.fromOffset(20,y),UDim2.fromOffset(310,34),C.raised,function()
  if recording then msg('Stop recording before changing settings.');return end
  Core.Settings[key]=not Core.Settings[key];button.Text=title..': '..(Core.Settings[key]and 'ON'or 'OFF')
  button.BackgroundColor3=Core.Settings[key]and C.green or C.raised
 end);button.ZIndex=11
end
toggleSetting('localActor','Record my animation',54)
toggleSetting('npcs','Record nearby NPC animations',96)
toggleSetting('otherPlayers','Record other player animations',138)
settingLabel('Actor names/usernames (comma-separated). Blank = nearest enabled actors, within radius and actor cap.',185)
local names=mk('TextBox',settingsPanel,{Text=Core.Settings.actorNames,ClearTextOnFocus=false,PlaceholderText='NPC model name, OtherUsername',Position=UDim2.fromOffset(20,220),Size=UDim2.fromOffset(940,34),Font=Enum.Font.Gotham,TextSize=13,TextColor3=C.white,BackgroundColor3=C.raised,BorderSizePixel=0,ZIndex=11})
names.FocusLost:Connect(function()if not recording then Core.Settings.actorNames=names.Text end end)
local rate=btn(settingsPanel,'Sampling: 30Hz motion / 20Hz VFX',UDim2.fromOffset(350,54),UDim2.fromOffset(400,34),C.raised,function()
 if recording then return end
 CFG.FPS=CFG.FPS==30 and 60 or 30;CFG.VFX_FPS=CFG.FPS==60 and 30 or 20
end);rate.ZIndex=11
rate.MouseButton1Click:Connect(function()rate.Text=string.format('Sampling: %dHz motion / %dHz VFX',CFG.FPS,CFG.VFX_FPS)end)
local radius=btn(settingsPanel,'VFX radius: 80 studs',UDim2.fromOffset(350,96),UDim2.fromOffset(400,34),C.raised,function()
 if recording then return end
 CFG.VFX_RADIUS=CFG.VFX_RADIUS==80 and 120 or (CFG.VFX_RADIUS==120 and 40 or 80)
end);radius.ZIndex=11
radius.MouseButton1Click:Connect(function()radius.Text='VFX radius: '..CFG.VFX_RADIUS..' studs'end)
settingLabel('Up to 4 actors within 60 studs, selected once when recording starts. Other actors\' keys are not observable.',275)
settingLabel('Studs = sampled 3D / horizontal path and displacement. Large jumps and sampling gaps are labeled.',312)
settingLabel('Visibility changes are recorded while root/joint capture continues. Preview labels remain visible.',349)
local close=btn(settingsPanel,'DONE',UDim2.fromOffset(20,405),UDim2.fromOffset(180,36),C.blue,function()Core.Settings.actorNames=names.Text;settingsPanel.Visible=false end);close.ZIndex=11
btn(window,'SETTINGS',UDim2.fromOffset(905,610),UDim2.fromOffset(130,30),C.raised,function()
 if recording then msg('Stop recording before changing settings.');return end
 settingsPanel.Visible=not settingsPanel.Visible
end)

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
    clearGuiRows(takeScroll)
    local q=search.Text:lower();local i=0
    for _,t in ipairs(saved) do
        if (t.kind or 'ANIM')==libraryFilter then
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
                or string.format('%d frames | %.2fs',t.nframes or 0,t.duration or 0)),
                UDim2.fromOffset(12,37),UDim2.new(1,-80,0,16),10,C.sub)
            btn(row,'DELETE',UDim2.new(1,-76,0,15),UDim2.fromOffset(70,31),C.red,function() deleteTake(t.id) end)
        end
        end -- matching library filter
    end
    takeScroll.CanvasSize=UDim2.fromOffset(0,i*67)
end
local function viewEvent(e)
    local parts={string.format('%.4fs',e.t or 0),e.type or '?'}
    if e.key then parts[#parts+1]=e.key end
    if e.summary then parts[#parts+1]=e.summary end
    if e.id then parts[#parts+1]='#'..e.id end
    if e.speed~=nil then parts[#parts+1]='x'..tostring(e.speed) end
    if e.studsPerSec then parts[#parts+1]=tostring(e.studsPerSec)..' studs/s' end
    if e.actualSpeed then parts[#parts+1]=tostring(e.actualSpeed)..' studs/s' end
    if e.studs then parts[#parts+1]=tostring(e.studs)..' studs' end
    if e.actorName then parts[#parts+1]=e.actorName end
    return table.concat(parts,'  |  ')
end

drawDetails=function()
    clearGuiRows(ids);clearGuiRows(timeline)
    local t=getSelectedTake()
    if not t then
        nameUI.Text='Select a '..libraryFilter..' recording';metaUI.Text='Choose ANIM, VFX or BOTH. SETTINGS selects actors and sampling rates.'
        return
    end
    local d=loadData(t)
    nameUI.Text=t.name..'  ['..t.rig..']  |  '..Core.takeFormat(d)
    idsHeader.Text=(t.kind=='VFX' and 'VFX SOURCES' or 'ANIMATION IDs')
    metaUI.Text=string.format('%.3f seconds | %d pose frames | %d movement events | %d VFX events',
        t.duration or 0,t.nframes or 0,d and #(d.events or {}) or 0,t.nvfx or 0)
    if d and d.distance then metaUI.Text..=string.format(' | %.2f studs | %d actor(s)',d.distance.path3D or 0,1+#(d.actors or {}))end
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
    if (t.kind or 'ANIM')=='VFX' and d then
        for _,ev in ipairs(d.vfx or {}) do
            if ev.op=='spawn' or ev.op=='group_spawn' then
                local text=string.format('%s #%s',ev.kind or 'Effect',ev.id or '?')
                n=n+1;rowText(ids,text,n,21,C.blue)
                n=n+1;rowText(ids,tostring(ev.path or ''):sub(-72),n,19,C.sub)
            end
        end
    end
    for _,actor in ipairs(d and d.actors or {})do
        n+=1;rowText(ids,(actor.actor and (actor.actor.username or actor.actor.name)or 'Other actor')..string.format(' | %.2f studs',actor.distance and actor.distance.path3D or 0),n,23,C.green)
        for _,tr in ipairs(actor.tracks or {})do n+=1;rowText(ids,(tr.id or '?')..' '..(tr.name or ''),n,21,C.sub)end
    end
    ids.CanvasSize=UDim2.fromOffset(0,n*23)
    local j=0
    if d then
        local combined={}
        for _,ev in ipairs(d.events or {}) do
            combined[#combined+1]={t=ev.t or 0,fx=false,e=ev}
        end
        for _,actor in ipairs(d.actors or {})do
            for _,ev in ipairs(actor.events or {})do local copy=table.clone(ev);copy.actorName=actor.actor and (actor.actor.username or actor.actor.name)or 'Other actor';combined[#combined+1]={t=copy.t or 0,fx=false,e=copy}end
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
    elseif key=='F9'and not processed then Core.startRecord('COMBINED')
    elseif recording and Core.hasMotion(recording.kind)and recording.actor.isLocal and (WATCH[key]or key:match('^Mouse[123]$'))then
        Core.inputUpdate(recording,key,true,now(recording),processed)
        if key=='LeftShift'or key=='RightShift'then Core.inputUpdate(recording,'Shift',true,now(recording),processed)end
    end
end))
conn(UIS.InputEnded:Connect(function(inp,processed)
    if disposed or not recording or not Core.hasMotion(recording.kind)or not recording.actor.isLocal then return end
    local key=Core.inputName(inp)
    if WATCH[key]or key:match('^Mouse[123]$')then Core.inputUpdate(recording,key,false,now(recording),processed)end
    if key=='LeftShift'or key=='RightShift'then
        local held=UIS:IsKeyDown(Enum.KeyCode.LeftShift)or UIS:IsKeyDown(Enum.KeyCode.RightShift)
        Core.inputUpdate(recording,'Shift',held,now(recording),processed)
    end
end))
-- Frame callbacks do no scene discovery while idle. UI refresh is limited to 5Hz.
local nextUI=0
conn(RunService.PostSimulation:Connect(function()
    if disposed then return end
    local tickStart=os.clock()
    local t=recording
    if t then
        local ts=now(t)
        if Core.hasVFX(t.kind)then Group.indexStep()end
        if Core.hasMotion(t.kind)and ts>=t.nextSample then
            local present=Core.sampleActors(t,ts)
            t.nextSample=(math.floor(ts*CFG.FPS)+1)/CFG.FPS
            if present==0 or t.motionLimited then stopRecord();t=nil end
        end
        if t and Core.hasVFX(t.kind)and ts>=t.nextVFX then
            local budget=0
            for obj in pairs(t.vfxPending)do
                if budget>=CFG.SCAN_BUDGET then break end
                Core.vfxAdd(t,obj,ts);t.vfxPending[obj]=nil;t.pendingCount-=1;budget+=1
            end
            Core.vfxRefresh(t,ts)
            t.nextVFX=(math.floor(ts*CFG.VFX_FPS)+1)/CFG.VFX_FPS
        end
        if t then
            t.maxRecorderTickMs=math.max(t.maxRecorderTickMs or 0,(os.clock()-tickStart)*1000)
            if ts>=CFG.MAX_SECONDS then stopRecord();t=nil end
        end
    end
    if playback then Core.tickPreview()end
    if os.clock()<nextUI then return end
    nextUI=os.clock()+1/CFG.UI_HZ
    t=recording
    elapsedUI.Text=t and string.format('%.2f / %.1fs',now(t),CFG.MAX_SECONDS)or 'Ready'
    if t then
        local count=0;for _,actor in ipairs(t.allActors or {})do count+=#actor.frames end
        liveUI.Text=string.format('%s | %d actor(s) | %d frames | %d VFX | peak %.1fms%s',
            t.kind,#t.allActors,count,#t.vfx,t.maxRecorderTickMs or 0,t.truncatedVFX and ' | INCOMPLETE VFX' or '')
    else liveUI.Text=string.format('Motion %dHz | VFX %dHz | idle scene watchers: 0',CFG.FPS,CFG.VFX_FPS)end
    animRecBtn.Text=(t and t.kind=='ANIM')and 'STOP ANIM (F6)'or 'REC ANIM (F6)'
    animRecBtn.BackgroundColor3=(t and t.kind=='ANIM')and C.red or C.green
    vfxRecBtn.Text=(t and t.kind=='VFX')and 'STOP VFX (F8)'or 'REC VFX (F8)'
    vfxRecBtn.BackgroundColor3=(t and t.kind=='VFX')and C.red or C.blue
    combinedRecBtn.Text=(t and t.kind=='COMBINED')and 'STOP BOTH (F9)'or 'REC ANIM + VFX (F9)'
    animTab.BackgroundColor3=libraryFilter=='ANIM'and C.blue or C.raised
    vfxTab.BackgroundColor3=libraryFilter=='VFX'and C.blue or C.raised
    combinedTab.BackgroundColor3=libraryFilter=='COMBINED'and C.blue or C.raised
end))

local function shutdown()
    if disposed then return end
    if recording then stopRecord() end
    if playback then stopPreview() end
    disposed=true
    for _,c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    Group.shutdown()
    gui:Destroy()
end
env.GC_MotionBaker_Shutdown=shutdown
if #saved>0 then
    for _,take in ipairs(saved) do
        if (take.kind or 'ANIM')==libraryFilter then selected=take.id;selectedTarget=take.rig;break end
    end
    rigBtn.Text='TARGET: '..selectedTarget
end
drawLibrary();drawDetails()
msg('Grand Clover Motion+VFX Baker V7 loaded. F6=Motion; F8=VFX; F9=Both; F7=UI; SETTINGS=Actors/rates. Client-only.')

end -- createInterface
createInterface()
