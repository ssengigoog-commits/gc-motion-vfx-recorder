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
local heading=label(bar,'GRAND CLOVER  /  MOTION + VFX BAKER V7.0.1',UDim2.fromOffset(16,7),UDim2.fromOffset(750,22),17,C.white)
heading.Font=Enum.Font.GothamBold
label(bar,'R6 + R15  •  evaluated joints, root/jump motion, grouped VFX + meshes',UDim2.fromOffset(17,30),UDim2.fromOffset(760,17),11,C.sub)
btn(bar,'HIDE (F7)',UDim2.new(1,-111,0,11),UDim2.fromOffset(99,32),C.raised,function() window.Visible=false end)
statusLabel=label(window,'Ready — F6 = Motion | F8 = VFX | F3 = Game Recorder.',UDim2.fromOffset(16,63),UDim2.new(1,-310,0,24),12,C.sub)
local animRecBtn=btn(window,'REC ANIM (F6)',UDim2.new(1,-258,0,62),UDim2.fromOffset(118,37),C.green,function()
    Core.startRecord('ANIM')
end)
local vfxRecBtn=btn(window,'REC VFX (F8)',UDim2.new(1,-132,0,62),UDim2.fromOffset(118,37),C.blue,function()
    Core.startRecord('VFX')
end)
local elapsedUI=label(window,'0.0 / 120.0 s',UDim2.fromOffset(16,91),UDim2.fromOffset(145,17),11,C.sub)
local liveUI=label(window,'FPS 60  •  Waiting',UDim2.fromOffset(173,91),UDim2.new(1,-200,0,17),11,C.sub)
local left=mk('Frame',window,{Position=UDim2.fromOffset(12,118),Size=UDim2.fromOffset(322,478),BackgroundColor3=C.panel,BorderSizePixel=0})
local right=mk('Frame',window,{Position=UDim2.fromOffset(345,118),Size=UDim2.fromOffset(692,478),BackgroundColor3=C.panel,BorderSizePixel=0})
rounded(left);rounded(right)
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
    if inspectActorBtn then inspectActorBtn.Text=mode=='GAME' and 'CHOOSE ACTORS' or 'SPLIT VFX' end
    if vfxExportBtn then vfxExportBtn.Text=mode=='GAME' and 'VFX STUDIO' or 'VFX JSON' end
    if drawLibrary then drawLibrary() end
    if drawDetails then drawDetails() end
end
animTab=btn(left,'ANIM',UDim2.fromOffset(11,8),UDim2.fromOffset(95,26),C.blue,function() setLibraryFilter('ANIM') end)
vfxTab=btn(left,'VFX',UDim2.fromOffset(112,8),UDim2.fromOffset(95,26),C.raised,function() setLibraryFilter('VFX') end)
inspectTab=btn(left,'GAME',UDim2.fromOffset(213,8),UDim2.fromOffset(97,26),C.raised,function() setLibraryFilter('GAME') end)
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
-- Optional quality selector for long (up-to-two-minute) recordings.
local qualityBtn
qualityBtn=btn(right,'RATE: 60 FPS',UDim2.fromOffset(450,311),UDim2.fromOffset(230,31),C.raised,function()
    if recording or playback then msg('Stop recording/playback before changing FPS.');return end
    local newRate=CFG.FPS==60 and 30 or 60
    CFG.FPS=newRate;CFG.VFX_FPS=newRate
    qualityBtn.Text='RATE: '..newRate..' FPS'
    msg('Capture rate set to '..newRate..' FPS. F3 uses up to 30Hz motion, 15Hz VFX and '..CFG.INSPECT_FPS..'Hz actors.')
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
-- Opt-in actor picker; local player is the fallback if none selected.
local actorsBox=mk('Frame',gui,{Visible=false,Position=UDim2.fromScale(.5,.5),
    AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(620,490),
    BackgroundColor3=C.bg,BorderSizePixel=0,ZIndex=20})
rounded(actorsBox)
label(actorsBox,'GAME RECORDER  /  ACTOR PICKER',UDim2.fromOffset(16,12),UDim2.fromOffset(440,25),16,C.white)
local actorMessage=label(actorsBox,'Choose up to '..CFG.INSPECT_MAX_ACTORS..' actors for F3 game capture.',
    UDim2.fromOffset(16,39),UDim2.fromOffset(580,25),12,C.sub)
local actorList=mk('ScrollingFrame',actorsBox,{Position=UDim2.fromOffset(12,77),
    Size=UDim2.fromOffset(596,350),BackgroundColor3=C.panel,BorderSizePixel=0,
    ScrollBarThickness=6,CanvasSize=UDim2.fromOffset(0,0),ZIndex=21})
local actorLayout=mk('UIListLayout',actorList,{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder})
local function redrawActors()
    for _,child in ipairs(actorList:GetChildren())do if child:IsA('GuiObject')then child:Destroy() end end
    local actors=Core.inspectCandidates()
    for i,a in ipairs(actors)do
        local text=(a.selected and '[X] ' or '[ ] ')..a.label..'  /  '..a.role..'  /  '..math.floor(a.distance)..' studs'
        local target=a.model
        local b=btn(actorList,text,UDim2.fromOffset(0,0),UDim2.new(1,-12,0,34),a.selected and C.blue or C.raised,function()
            local _,description=Core.inspectToggle(target)
            actorMessage.Text=description
            redrawActors()
        end)
        b.LayoutOrder=i;b.TextXAlignment=Enum.TextXAlignment.Left;b.ZIndex=22
    end
    actorList.CanvasSize=UDim2.fromOffset(0,#actors*40)
    if #actors==0 then actorMessage.Text='No nearby actors found. Try closer to an NPC.' end
end
openActorPicker=function() redrawActors();actorsBox.Visible=true end
btn(actorsBox,'REFRESH',UDim2.fromOffset(320,444),UDim2.fromOffset(130,32),C.raised,function()redrawActors()end).ZIndex=22
btn(actorsBox,'DONE',UDim2.fromOffset(466,444),UDim2.fromOffset(140,32),C.green,function()actorsBox.Visible=false end).ZIndex=22

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
btn(right,'PLAY MOTION GHOST',UDim2.fromOffset(11,350),UDim2.fromOffset(200,32),C.blue,function() Core.playSelection('ANIM',loopOn) end)
btn(right,'PLAY VFX AHEAD',UDim2.fromOffset(219,350),UDim2.fromOffset(200,32),C.blue,function() Core.playSelection('VFX',loopOn) end)
btn(right,'STOP',UDim2.fromOffset(427,350),UDim2.fromOffset(105,32),C.red,function() stopPreview() end)
btn(right,'COPY RAW',UDim2.fromOffset(11,394),UDim2.fromOffset(128,35),C.raised,function() exportTake('raw') end)
vfxExportBtn=btn(right,'VFX JSON',UDim2.fromOffset(147,394),UDim2.fromOffset(128,35),C.raised,function()
    if libraryFilter=='GAME' then exportTake('studio-vfx') else exportTake('vfx') end
end)
btn(right,'EXPORT STUDIO',UDim2.fromOffset(283,394),UDim2.fromOffset(249,35),C.green,function() exportTake('studio') end)
local openActorPicker -- assigned after the modal is constructed
inspectActorBtn=btn(right,'SPLIT VFX',UDim2.fromOffset(540,394),UDim2.fromOffset(140,35),C.blue,function()
    if recording then msg('Finish recording first.');return end
    if libraryFilter=='GAME' then if openActorPicker then openActorPicker() end;return end
    local take=getSelectedTake();if take then Core.splitVfx(take)end
end)
btn(right,'REC GAME F3',UDim2.fromOffset(540,350),UDim2.fromOffset(140,32),C.green,function()
    Core.startRecord('GAME')
end)
local caution=label(right,'Effect-only capture; burst estimates are labeled. World-image VFX supported; unavailable assets are marked.',
    UDim2.fromOffset(12,439),UDim2.new(1,-20,0,31),11,C.sub)
caution.TextWrapped=true
label(window,'F6 = motion  •  F8 = VFX  •  F3 = full game recorder  •  F7 = UI  •  120s max  •  Client observations only',
    UDim2.fromOffset(15,608),UDim2.new(1,-25,0,24),12,C.sub)

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
    if key=='F7'and not UIS:GetFocusedTextBox()then window.Visible=not window.Visible;if not window.Visible then copyBox.Visible=false;actorsBox.Visible=false end;return end
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
conn(workspace.DescendantAdded:Connect(function(obj)
    Group.observe(obj,true)
    if recording and recording.kind=='GAME' then Core.gameObserveInstance(recording,obj,'add','Workspace') end
    if recording and (recording.kind=='INSPECT' or recording.kind=='GAME') then Core.inspectEffect(obj,now(recording),'add') end
end))
conn(workspace.DescendantRemoving:Connect(function(obj)
    if recording and recording.kind=='GAME' then Core.gameObserveInstance(recording,obj,'remove','Workspace') end
    if recording and (recording.kind=='INSPECT' or recording.kind=='GAME') then Core.inspectEffect(obj,now(recording),'remove') end
    Group.removing(obj)
end))
conn(game:GetService('ReplicatedStorage').DescendantAdded:Connect(function(obj)
    if recording and recording.kind=='GAME' then Core.gameObserveInstance(recording,obj,'add','ReplicatedStorage') end
end))
conn(game:GetService('ReplicatedStorage').DescendantRemoving:Connect(function(obj)
    if recording and recording.kind=='GAME' then Core.gameObserveInstance(recording,obj,'remove','ReplicatedStorage') end
end))
conn(playerGui.DescendantAdded:Connect(function(obj)
    if Group.worldGui(obj)then Group.observe(obj,true)end
    if recording and recording.kind=='GAME' and obj:IsA('Highlight')then
        Core.gameHighlightObserve(recording,obj,'add')
    end
end))
conn(playerGui.DescendantRemoving:Connect(function(obj)
    if Group.worldGui(obj)then Group.removing(obj)end
    if recording and recording.kind=='GAME' and obj:IsA('Highlight')then
        Core.gameHighlightObserve(recording,obj,'remove')
    end
end))
local nextUIRefresh=0
conn(RunService.PostSimulation:Connect(function()
    if disposed then return end
    -- Keep original VFX warm-up during idle and VFX takes; pause it during
    -- motion/inspector capture to avoid competing with high-rate sampling.
    if not recording or recording.kind=='VFX' then Group.indexStep() end
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
    if os.clock()<nextUIRefresh then return end
    nextUIRefresh=os.clock()+.12
    elapsedUI.Text=recording and string.format('%.2f / %.1fs',now(recording),CFG.MAX_SECONDS)
        or string.format('0.0 / %.0f s',CFG.MAX_SECONDS)
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
        liveUI.Text='Ready  •  Rate '..CFG.FPS..' FPS'
    end
    animRecBtn.Text=(recording and recording.kind=='ANIM') and 'STOP ANIM (F6)' or 'REC ANIM (F6)'
    animRecBtn.BackgroundColor3=(recording and recording.kind=='ANIM') and C.red or C.green
    vfxRecBtn.Text=(recording and recording.kind=='VFX') and 'STOP VFX (F8)' or 'REC VFX (F8)'
    vfxRecBtn.BackgroundColor3=(recording and recording.kind=='VFX') and C.red or C.blue
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
msg('Grand Clover Baker V7.0.1 loaded. F6=Motion, F8=VFX, F3=Game Recorder; 120s max. Client-observed only.')

end -- createInterface
createInterface()
