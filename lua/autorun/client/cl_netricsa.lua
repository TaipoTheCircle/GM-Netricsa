if CLIENT then
include("cl_netricsa_styles.lua")
include("cl_netricsa_lang.lua")
include("dr_ui_scrollstyle.lua")

surface.CreateFont("NetricsaText", {
    font     = "Arial",
    size     = 16,
    weight   = 500,
    extended = true
})

surface.CreateFont("NetricsaTitle", {
    font     = "Arial",
    size     = 22,
    weight   = 700,
    extended = true
})

surface.CreateFont("NetricsaBig", {
    font     = "Arial",
    size     = 48,
    weight   = 800,
    extended = true
})




local function CreateButton(parent, text)
    local btn = vgui.Create("DButton", parent)
    if text then btn:SetText(text) end

    -- звук при наведении
    btn.OnCursorEntered = function(self)
        surface.PlaySound("netricsa/button_ssm.wav")
        self.HoveredColor = Color(255,255,255)
    end

    btn.OnCursorExited = function(self)
        self.HoveredColor = nil
    end

    -- звук при клике
    local oldClick = btn.DoClick
    btn.DoClick = function(self, ...)
        surface.PlaySound("netricsa/button_ssm_press.wav")
        if oldClick then oldClick(self, ...) end
    end

    -- универсальная отрисовка текста с подсветкой
    btn.Paint = function(self, w, h)
        local style = NetricsaStyle or STYLES.Revolution
        local col = self.HoveredColor or style.color
        draw.SimpleText(self:GetText(), "NetricsaText", w/2, h/2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    return btn
end

local function EnhanceButton(btn)
    if not IsValid(btn) then return end

    -- звук при наведении
    btn.OnCursorEntered = function(self)
        surface.PlaySound("netricsa/button_ssm.wav")
        self._hovered = true
    end

    btn.OnCursorExited = function(self)
        self._hovered = false
    end

    -- оборачиваем DoClick, чтобы всегда играл press
    local oldClick = btn.DoClick
    btn.DoClick = function(self, ...)
        surface.PlaySound("netricsa/button_ssm_press.wav")
        if oldClick then oldClick(self, ...) end
    end

    -- добавляем универсальную подсветку текста (только если нет кастомного Paint)
    if not btn._customPaint then
        local oldPaint = btn.Paint
        btn.Paint = function(self, w, h)
            local style = NetricsaStyle or STYLES.Revolution
            local col = self._hovered and Color(255,255,255) or style.color
            draw.SimpleText(self:GetText(), "NetricsaText", w/2, h/2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            if oldPaint and oldPaint ~= DButton.Paint then
                oldPaint(self, w, h)
            end
        end
    end
end




local function NoBG(p)
    if not IsValid(p) then return end
    if p.SetPaintBackground then p:SetPaintBackground(false) end
    if p.SetDrawBackground then p:SetDrawBackground(false) end
    if p.SetPaintBorderEnabled then p:SetPaintBorderEnabled(false) end
end

-- переменные статистики 
stats_kills = 0
stats_totalEnemies = 0 -- здесь мы храним "живых сейчас", как шлёт сервер
stats_startTime = 0

net.Receive("Netricsa_UpdateStats", function()
    stats_kills        = net.ReadInt(16)
    stats_totalEnemies = net.ReadInt(16)
    stats_startTime    = net.ReadFloat()
end)


    local NetricsaFrame
    local ENEMIES = {}
    local WEAPONS = {}
    local SAVED_MAPS = {}
    local READ_STATUS = { maps = {}, enemies = {}, weapons = {} }
    local showScan = false

    local CONTINUE_FILE = "netricsa_continue_campaign.flag"

    local PROGRESS_FILE = "netricsa_progress.json"

    local continueCampaign = false --  Флаг для перехода по триггеру

net.Receive("Netricsa_ContinueCampaign", function()
    -- пишем простой флаг, который переживёт загрузку новой карты
    file.Write(CONTINUE_FILE, tostring(os.time()))
end)

    local function SaveProgress()
        local data = {
            maps = SAVED_MAPS,
            enemies = ENEMIES,
            weapons = WEAPONS,
            read = READ_STATUS
        }
        file.Write(PROGRESS_FILE, util.TableToJSON(data, true))
    end

    local function LoadProgress()
        if file.Exists(PROGRESS_FILE, "DATA") then
            local raw = file.Read(PROGRESS_FILE, "DATA")
            local data = util.JSONToTable(raw)
            if data then
                SAVED_MAPS = data.maps or {}
                ENEMIES = data.enemies or {}
                WEAPONS = data.weapons or {}
                READ_STATUS = data.read or { maps = {}, enemies = {}, weapons = {} }
            end
        end
    end

local function LoadDescription(name)
    local lang = CurrentLang or "en"
    local path = "lua/netricsa/descriptions/" .. lang .. "/" .. name .. ".lua"
    if file.Exists(path, "GAME") then
        return file.Read(path, "GAME")
    end
    return L("ui","no_data")
end

local function GetEnemyDisplayName(npcClass)
    local lang = CurrentLang or "en"
    local path = "lua/netricsa/descriptions/" .. lang .. "/" .. npcClass .. ".lua"
    if file.Exists(path, "GAME") then
        local content = file.Read(path, "GAME")
        if content and content ~= "" then
            local firstLine = string.match(content, "([^\n\r]+)")
            if firstLine and firstLine ~= "" then
                return firstLine
            end
        end
    end
    return npcClass
end

function utf8.sub(s, i, j)
    local start = utf8.offset(s, i)
    local finish

    if j then
        local offset = utf8.offset(s, j + 1)
        if offset then
            finish = offset - 1
        else
            finish = #s
        end
    else
        finish = utf8.len(s)
    end

    return string.sub(s, start, finish)
end

local function SetAnimatedText(rt, text, step, speed)
    if not IsValid(rt) then return end
    rt:SetText("")
    local c = NetricsaStyle.color or Color(255, 255, 0)
    rt:InsertColorChange(c.r, c.g, c.b, c.a or 255)

    local i = 0
    step = step or 2
    speed = speed or 0.01
    timer.Remove("NetricsaTextAnim")
    timer.Create("NetricsaTextAnim", speed, math.ceil(#text / step), function()
        if not IsValid(rt) then return end

        i = i + step
        local part = utf8.sub(text, i - step, i - 1)
        rt:AppendText(part)

        if i >= utf8.len(text) then
            timer.Remove("NetricsaTextAnim")
        end
    end)
end


local function FitModel(ent, panel)
    if not IsValid(ent) then return end
    local mn, mx = ent:GetRenderBounds()
    local size = math.max(mx.x - mn.x, mx.y - mn.y, mx.z - mn.z)
    if size <= 0 then size = 50 end

    local center = (mn + mx) * 0.5

    -- Чем больше модель, тем дальше отодвигаем камеру
    local dist = math.Clamp(size * 2.5, 150, 5000)

    panel:SetCamPos(center + Vector(dist, dist, dist * 0.6))
    panel:SetLookAt(center)
    panel:SetFOV(40)
end

-- Приведение аргумента таба к "внутреннему" ключу: "maps"/"enemies"/"weapons"/...
-- Нормализует аргумент таба: принимает либо "maps"/"enemies"/"weapons", либо локализованный текст L("tabs",...)
local function TabKeyFromName(name)
    if not name then return nil end
    local s = tostring(name)

    -- если уже внутренний ключ — возвращаем сразу
    if s == "maps" or s == "enemies" or s == "weapons" or s == "tactical" or s == "statistics" then
        return s
    end

    -- соответствие локализованных названий → внутренние ключи
    local mapping = {}
    mapping[L("tabs","strategic")]  = "maps"      -- стратегические данные = карты
    mapping[L("tabs","enemies")]    = "enemies"
    mapping[L("tabs","weapons")]    = "weapons"
    mapping[L("tabs","tactical")]   = "tactical"
    mapping[L("tabs","statistics")] = "statistics"

    if mapping[s] then return mapping[s] end

    -- попытка по "вхождению" (на всякий случай, англ/рус)
    local low = string.lower(s)
    if low:find("map") or low:find("карта") or low:find("стратег") then return "maps" end
    if low:find("enemy") or low:find("враг") or low:find("враги") then return "enemies" end
    if low:find("weapon") or low:find("оруж") then return "weapons" end
    if low:find("tactic") or low:find("тактич") then return "tactical" end
    if low:find("stat") or low:find("стат") then return "statistics" end

    return nil
end

local function GetUnreadCount(tab)
    local key = TabKeyFromName(tab)
    if not key then return 0 end

    local t = (key == "maps" and SAVED_MAPS)
           or (key == "enemies" and ENEMIES)
           or (key == "weapons" and WEAPONS)

    if not t then return 0 end

    -- гарантируем, что READ_STATUS проинициализирован
    READ_STATUS = READ_STATUS or { maps = {}, enemies = {}, weapons = {} }
    local readTab = READ_STATUS[key] or {}

    local unread = 0
    for k, _ in pairs(t) do
        if not readTab[k] then
            unread = unread + 1
        end
    end
    return unread
end

local function OpenFirstUnread(tab, opener)
    local key = TabKeyFromName(tab)
    if not key then return end

    local t = (key == "maps" and SAVED_MAPS)
           or (key == "enemies" and ENEMIES)
           or (key == "weapons" and WEAPONS)

    if not t then return end

    READ_STATUS = READ_STATUS or { maps = {}, enemies = {}, weapons = {} }
    READ_STATUS[key] = READ_STATUS[key] or {}

    -- сначала ищем непрочитанное
    for k, _ in pairs(t) do
        if not READ_STATUS[key][k] then
            opener(k)
            return
        end
    end

    -- иначе — откроем первый из списка (если есть)
    for k, _ in pairs(t) do
        opener(k)
        return
    end
end



    local function OpenNetricsa()
        if IsValid(NetricsaFrame) then
            NetricsaFrame:SetVisible(true)
            return
        end

        NetricsaFrame = vgui.Create("DFrame")
        NetricsaFrame:SetSize(ScrW(), ScrH())
        NetricsaFrame:SetPos(0, 0)
        NetricsaFrame:ShowCloseButton(false)
        NetricsaFrame:SetTitle("")
        NetricsaFrame:MakePopup()

local gridMat = Material(NetricsaStyle.grid or "netricsa/grid.png", "noclamp smooth")
NetricsaFrame.Paint = function(self, w, h)
    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(gridMat)
    surface.DrawTexturedRect(0, 0, w, h)
    local style = NetricsaStyle or STYLES.Revolution
draw.SimpleText("NETRISCA v2.01", "NetricsaTitle", 20, 10, style.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end


local exitBtn = vgui.Create("DButton", NetricsaFrame)
exitBtn:SetText("")
exitBtn:SetSize(40, 40)
exitBtn:SetPos(ScrW() - 50, 10)
exitBtn.DoClick = function() NetricsaFrame:Close() end
exitBtn.Paint = function(self, w, h)
    local style = NetricsaStyle or STYLES.Revolution
    local mat = Material(style.exit or "netricsa/exit_bg.png", "noclamp smooth")
    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(mat)
    surface.DrawTexturedRect(0, 0, w, h)
end


        local leftPanel = vgui.Create("DPanel", NetricsaFrame)
        leftPanel:SetPos(20, 60)
        leftPanel:SetSize(250, ScrH() - 80)
leftPanel.Paint = function(self, w, h)
    surface.SetDrawColor(255, 255, 255, 255)
    local bg = Material(NetricsaStyle.text, "noclamp smooth")
    surface.SetMaterial(bg)
    surface.DrawTexturedRect(0, 0, w, h)
end

local contentPanel = vgui.Create("DPanel", NetricsaFrame)
contentPanel:SetPos(280, 60)
contentPanel:SetSize(ScrW() - 300, ScrH() - 80)

contentPanel.Paint = function(self, w, h)
    local style = NetricsaStyle or STYLES.Revolution
    local bg = Material(style.content or style.text, "noclamp smooth") 
    -- если content не указан → fallback на text

    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(bg)
    surface.DrawTexturedRect(0, 0, w, h)
end


local function SwitchTab(tabName)
    contentPanel:Clear()

    if tabName == L("tabs","tactical") then

        local style = NetricsaStyle or STYLES.Revolution
        local bgMatText = Material(style.text, "noclamp smooth")
        local bgMatTac = Material(style.bg or "netricsa/bg_netricsa.png", "noclamp smooth")

        -- ВЕРХ: можно сделать список (как enemyListPanel)
        local listPanel = vgui.Create("DPanel", contentPanel)
        NoBG(listPanel)
        listPanel:Dock(TOP)
        listPanel:SetTall(200)
        listPanel.Paint = function(self, w, h)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(bgMatText)
            surface.DrawTexturedRect(0, 0, w, h)
            draw.SimpleText("WELCOME TO NETRICSA!", "NetricsaTitle", 20, 10, style.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end

        local scroll = vgui.Create("DScrollPanel", listPanel)
        scroll:Dock(FILL)

        -- НИЗ: слева картинка bg_netricsa, справа описание
        local bottomPanel = vgui.Create("DPanel", contentPanel)
        NoBG(bottomPanel)
        bottomPanel:Dock(FILL)
        bottomPanel:DockMargin(0, 10, 0, 0)

        -- слева bg_netricsa
        local imgPanel = vgui.Create("DPanel", bottomPanel)
        imgPanel:Dock(LEFT)
        imgPanel:SetWide(math.floor(contentPanel:GetWide() * 0.4))
        imgPanel.Paint = function(self, w, h)
            surface.SetDrawColor(255,255,255,255)
            surface.SetMaterial(bgMatTac)
            surface.DrawTexturedRect(0, 0, w, h)
        end

        -- справа текстовое описание
        local textPanel = vgui.Create("DPanel", bottomPanel)
        NoBG(textPanel)
        textPanel:Dock(FILL)
        textPanel:DockMargin(10, 0, 0, 0)
        textPanel.Paint = function(self, w, h)
            surface.SetDrawColor(255,255,255,255)
            surface.SetMaterial(bgMatText)
            surface.DrawTexturedRect(0, 0, w, h)
        end

        local descBox = vgui.Create("RichText", textPanel)
        descBox:Dock(FILL)
        descBox:SetVerticalScrollbarEnabled(true)
        function descBox:PerformLayout()
            self:SetFontInternal("NetricsaText")
            self:SetFGColor(style.color or Color(255,255,0))
        end
        descBox:SetText("Tactical overview will be here...")

        -- читаем текст из файла
        local desc = LoadDescription("infonetricsa") or "No data available."
        SetAnimatedText(descBox, desc, 10, 0.005) -- быстрее печать

    elseif tabName == L("tabs","strategic") then
        local style = NetricsaStyle or (STYLES and STYLES.Revolution) or {
            text = "netricsa/text_bg.png",
            model = "netricsa/model_bg.png",
            color = Color(255,255,0)
        }
        local bgMatText = Material(style.text, "noclamp smooth")

        -- верх: список карт
        local mapListPanel = vgui.Create("DPanel", contentPanel)
        NoBG(mapListPanel)
        mapListPanel:Dock(TOP)
        mapListPanel:SetTall(200)
        mapListPanel.Paint = function(self, w, h)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(bgMatText)
            surface.DrawTexturedRect(0, 0, w, h)
        end

        local mapScroll = vgui.Create("DScrollPanel", mapListPanel)
        mapScroll:Dock(FILL)
        mapScroll:DockMargin(8, 8, 8, 8)

        -- низ: картинка уровня + описание
        local bottomPanel = vgui.Create("DPanel", contentPanel)
        NoBG(bottomPanel)
        bottomPanel:Dock(FILL)
        bottomPanel:DockMargin(0, 10, 0, 0)

        local mapBackground = vgui.Create("DPanel", bottomPanel)
        mapBackground:Dock(LEFT)
        mapBackground:SetWide(math.floor(contentPanel:GetWide() * 0.4))
        mapBackground.Paint = function(self, w, h)
            local mapToShow = bottomPanel.CurrentMap or game.GetMap()
            local levelImagePath = "levels/" .. mapToShow .. ".png"
            if file.Exists("materials/" .. levelImagePath, "GAME") then
                surface.SetDrawColor(255,255,255,255)
                surface.SetMaterial(Material(levelImagePath, "noclamp smooth"))
                surface.DrawTexturedRect(0, 0, w, h)
            else
                surface.SetDrawColor(255,0,0,255)
                surface.DrawRect(0, 0, w, h)
                draw.SimpleText("No Level Image","NetricsaText", w/2, h/2,
                    Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end

        local textPanel = vgui.Create("DPanel", bottomPanel)
        NoBG(textPanel)
        textPanel:Dock(FILL)
        textPanel:DockMargin(10, 0, 0, 0)
        textPanel.Paint = function(self, w, h)
            surface.SetDrawColor(255,255,255,255)
            surface.SetMaterial(bgMatText)
            surface.DrawTexturedRect(0, 0, w, h)
        end

        local descBox = vgui.Create("RichText", textPanel)
        descBox:Dock(FILL)
        descBox:SetVerticalScrollbarEnabled(true)
        function descBox:PerformLayout()
            self:SetFontInternal("NetricsaText")
            self:SetFGColor(style.color or Color(255,255,0))
        end
        descBox:SetText("Выберите карту сверху.")

        -- функция открытия карты
        local function OpenMap(mapName)
            bottomPanel.CurrentMap = mapName
            READ_STATUS.maps[mapName] = true
            SaveProgress()
            local desc = LoadDescription(mapName) or "No data available."
            SetAnimatedText(descBox, desc)
        end

        -- список карт: стиль как у ENEMIES, название — первая строка из descriptions/<map>.lua
        for mapName, _ in pairs(SAVED_MAPS) do
            local displayName = GetEnemyDisplayName(mapName) or mapName

            local btn = vgui.Create("DButton", mapScroll)
            btn:Dock(TOP)
            btn:DockMargin(5, 2, 5, 2)
            btn:SetTall(30)
            btn:SetText("")
            btn.Paint = function(self, w, h)
                local color
                if bottomPanel.CurrentMap == mapName then
                    color = Color(255,255,255)
                elseif READ_STATUS.maps[mapName] then
                    color = Color(150,150,150)
                else
                    color = style.color
                end
                draw.SimpleText(displayName, "NetricsaText", 5, h/2, color,
                    TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            btn.DoClick = function() OpenMap(mapName) end
        end

        -- сразу открываем первую непрочитанную карту или текущую
        OpenFirstUnread("maps", OpenMap)

        -- если список пустой, добавляем текущую карту
if table.IsEmpty(SAVED_MAPS) then
    local currentMap = game.GetMap()
    SAVED_MAPS[currentMap] = true
    SaveProgress()

    local btn = vgui.Create("DButton", mapScroll)
    btn:Dock(TOP)
    btn:DockMargin(5, 2, 5, 2)
    btn:SetTall(30)
    btn:SetText("")
    local displayName = GetEnemyDisplayName(currentMap) or currentMap
    btn.Paint = function(self, w, h)
        draw.SimpleText(displayName, "NetricsaText", 5, h/2, style.color,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    btn.DoClick = function() OpenMap(currentMap) end

    OpenMap(currentMap)
else
    OpenFirstUnread("maps", OpenMap)
end


    elseif tabName == L("tabs","enemies") then
        local bgMatText = Material(NetricsaStyle.text, "noclamp smooth")

        local enemyListPanel = vgui.Create("DPanel", contentPanel)
        NoBG(enemyListPanel)
        enemyListPanel:Dock(TOP)
        enemyListPanel:SetTall(200)
        enemyListPanel.Paint = function(self, w, h)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(bgMatText)
            surface.DrawTexturedRect(0, 0, w, h)
        end

        local enemyScroll = vgui.Create("DScrollPanel", enemyListPanel)
        enemyScroll:Dock(FILL)

        local bottomPanel = vgui.Create("DPanel", contentPanel)
        NoBG(bottomPanel)
        bottomPanel:Dock(FILL)
        bottomPanel:DockMargin(0, 10, 0, 0)

        local modelBackground = vgui.Create("DPanel", bottomPanel)
        modelBackground:Dock(LEFT)
        modelBackground:SetWide(contentPanel:GetWide() * 0.4)
        modelBackground.Paint = function(self, w, h)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(Material(NetricsaStyle.model, "noclamp smooth"))
            surface.DrawTexturedRect(0, 0, w, h)
        end

        local modelPanel = vgui.Create("DModelPanel", modelBackground)
        modelPanel:Dock(FILL)
        modelPanel:SetFOV(40)
        modelPanel:SetCamPos(Vector(100, 0, 60))
        modelPanel:SetLookAt(Vector(0, 0, 40))
        modelPanel.LayoutEntity = function(self, ent)
            if not IsValid(ent) then return end
            ent:SetAngles(Angle(0, RealTime() * 30 % 360, 0))
            self:RunAnimation()
        end

        local textPanel = vgui.Create("DPanel", bottomPanel)
        NoBG(textPanel)
        textPanel:Dock(FILL)
        textPanel:DockMargin(10, 0, 0, 0)
        textPanel.Paint = function(self, w, h)
            surface.SetDrawColor(255,255,255,255)
            surface.SetMaterial(bgMatText)
            surface.DrawTexturedRect(0, 0, w, h)
        end

        local descBox = vgui.Create("RichText", textPanel)
        descBox:Dock(FILL)
        descBox:SetVerticalScrollbarEnabled(true)
        function descBox:PerformLayout()
            self:SetFontInternal("NetricsaText")
            self:SetFGColor(Color(255, 255, 0))
        end
        descBox:SetText(L("ui","select_enemy"))

        local function OpenEnemy(npcClass)
            bottomPanel.CurrentEnemy = npcClass
            READ_STATUS.enemies[npcClass] = true
            SaveProgress()
            local entData = ENEMIES[npcClass]
            modelPanel:SetModel(entData.mdl or "models/props_c17/oildrum001.mdl")
            local ent = modelPanel:GetEntity()
            if IsValid(ent) then
                FitModel(ent, modelPanel)
                ent:SetSkin(entData.skin or 0)
                if entData.bodygroups then
                    for i, bg in ipairs(entData.bodygroups) do
                        ent:SetBodygroup(i-1, bg)
                    end
                end
                local seq = ent:LookupSequence("walk")
                if seq <= 0 then seq = ent:SelectWeightedSequence(ACT_WALK) or 0 end
                if seq > 0 then ent:ResetSequence(seq) end
            end
            local desc = LoadDescription(npcClass) or "No data available."
            SetAnimatedText(descBox, desc)
        end

        for npcClass, data in pairs(ENEMIES) do
            local displayName = GetEnemyDisplayName(npcClass)
            local btn = vgui.Create("DButton", enemyScroll)
            btn:Dock(TOP)
            btn:DockMargin(5, 2, 5, 2)
            btn:SetTall(30)
            btn:SetText("")
            btn.Paint = function(self, w, h)
                local color
                if bottomPanel.CurrentEnemy == npcClass then
                    color = Color(255,255,255)
                elseif READ_STATUS.enemies[npcClass] then
                    color = Color(150,150,150)
                else
                    color = NetricsaStyle.color
                end
                draw.SimpleText(displayName, "NetricsaText", 5, h/2, color,
                    TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            btn.DoClick = function() OpenEnemy(npcClass) end
        end

        OpenFirstUnread(L("tabs","enemies"), OpenEnemy)

        elseif tabName == L("tabs","fractions") then
    local bgMatText = Material(NetricsaStyle.text, "noclamp smooth")

    -- Верх: список фракций
    local fracListPanel = vgui.Create("DPanel", contentPanel)
    NoBG(fracListPanel)
    fracListPanel:Dock(TOP)
    fracListPanel:SetTall(200)
    fracListPanel.Paint = function(self, w, h)
        surface.SetDrawColor(255,255,255,255)
        surface.SetMaterial(bgMatText)
        surface.DrawTexturedRect(0, 0, w, h)
    end

    local fracScroll = vgui.Create("DScrollPanel", fracListPanel)
    fracScroll:Dock(FILL)

    -- Низ: картинка + описание
    local bottomPanel = vgui.Create("DPanel", contentPanel)
    NoBG(bottomPanel)
    bottomPanel:Dock(FILL)
    bottomPanel:DockMargin(0, 10, 0, 0)

    local imgPanel = vgui.Create("DPanel", bottomPanel)
    imgPanel:Dock(LEFT)
    imgPanel:SetWide(contentPanel:GetWide() * 0.4)
    imgPanel.Paint = function(self, w, h)
        local frac = bottomPanel.CurrentFrac
        if frac then
            local imgPath = "ssfractions/" .. frac .. ".png"
            if file.Exists("materials/"..imgPath,"GAME") then
                surface.SetDrawColor(255,255,255,255)
                surface.SetMaterial(Material(imgPath,"noclamp smooth"))
                surface.DrawTexturedRect(0,0,w,h)
            else
                draw.SimpleText("No Image", "NetricsaText", w/2, h/2, Color(255,0,0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
    end

    local textPanel = vgui.Create("DPanel", bottomPanel)
    NoBG(textPanel)
    textPanel:Dock(FILL)
    textPanel:DockMargin(10,0,0,0)
    textPanel.Paint = function(self, w, h)
        surface.SetDrawColor(255,255,255,255)
        surface.SetMaterial(bgMatText)
        surface.DrawTexturedRect(0,0,w,h)
    end

    local descBox = vgui.Create("RichText", textPanel)
    descBox:Dock(FILL)
    descBox:SetVerticalScrollbarEnabled(true)
    function descBox:PerformLayout()
        self:SetFontInternal("NetricsaText")
        self:SetFGColor(NetricsaStyle.color or Color(255,255,0))
    end
    descBox:SetText(L("ui","no_data"))

    -- функция открытия
    local function OpenFraction(name)
        bottomPanel.CurrentFrac = name
        local desc = LoadDescription(name) or "No data available."
        SetAnimatedText(descBox, desc)
    end

    -- перебор файлов descriptions/<lang>/ssfrac_*.lua
    local lang = CurrentLang or "en"
    local files, _ = file.Find("lua/netricsa/descriptions/"..lang.."/ssfrac_*.lua","GAME")
    for _, f in ipairs(files) do
        local fracName = string.StripExtension(f)
        local displayName = GetEnemyDisplayName(fracName) -- первая строка файла
        local btn = vgui.Create("DButton", fracScroll)
        btn:Dock(TOP)
        btn:DockMargin(5,2,5,2)
        btn:SetTall(30)
        btn:SetText("")
        btn.Paint = function(self,w,h)
            draw.SimpleText(displayName or fracName,"NetricsaText",5,h/2,NetricsaStyle.color,TEXT_ALIGN_LEFT,TEXT_ALIGN_CENTER)
        end
        btn.DoClick = function() OpenFraction(fracName) end
    end
            -- открыть первую фракцию по умолчанию
        if files and #files > 0 then
            local firstFrac = string.StripExtension(files[1])
            OpenFraction(firstFrac)
        end

    elseif tabName == L("tabs","weapons") then
        local bgMatText = Material(NetricsaStyle.text, "noclamp smooth")

        local weaponListPanel = vgui.Create("DPanel", contentPanel)
        NoBG(weaponListPanel)
        weaponListPanel:Dock(TOP)
        weaponListPanel:SetTall(200)
        weaponListPanel.Paint = function(self, w, h)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(bgMatText)
            surface.DrawTexturedRect(0, 0, w, h)
        end

        local weaponScroll = vgui.Create("DScrollPanel", weaponListPanel)
        weaponScroll:Dock(FILL)

        local bottomPanel = vgui.Create("DPanel", contentPanel)
        NoBG(bottomPanel)
        bottomPanel:Dock(FILL)
        bottomPanel:DockMargin(0, 10, 0, 0)

        local modelBackground = vgui.Create("DPanel", bottomPanel)
        modelBackground:Dock(LEFT)
        modelBackground:SetWide(contentPanel:GetWide() * 0.4)
        modelBackground.Paint = function(self, w, h)
            surface.SetDrawColor(255,255,255,255)
            surface.SetMaterial(Material(NetricsaStyle.model, "noclamp smooth"))
            surface.DrawTexturedRect(0, 0, w, h)
        end

        local modelPanel = vgui.Create("DModelPanel", modelBackground)
        modelPanel:Dock(FILL)
        modelPanel:SetFOV(40)
        modelPanel:SetCamPos(Vector(100, 0, 60))
        modelPanel:SetLookAt(Vector(0, 0, 40))
        modelPanel.LayoutEntity = function(self, ent)
            if not IsValid(ent) then return end
            ent:SetAngles(Angle(0, RealTime() * 30 % 360, 0))
            self:RunAnimation()
        end

        local textPanel = vgui.Create("DPanel", bottomPanel)
        NoBG(textPanel)
        textPanel:Dock(FILL)
        textPanel:DockMargin(10, 0, 0, 0)
        textPanel.Paint = function(self, w, h)
            surface.SetDrawColor(255,255,255,255)
            surface.SetMaterial(bgMatText)
            surface.DrawTexturedRect(0, 0, w, h)
        end

        local descBox = vgui.Create("RichText", textPanel)
        descBox:Dock(FILL)
        descBox:SetVerticalScrollbarEnabled(true)
        function descBox:PerformLayout()
            self:SetFontInternal("NetricsaText")
            self:SetFGColor(Color(255, 255, 0))
        end
        descBox:SetText("Выберите оружие сверху.")

        local function OpenWeapon(class)
            bottomPanel.CurrentWeapon = class
            READ_STATUS.weapons[class] = true
            SaveProgress()
            local data = WEAPONS[class]
            modelPanel:SetModel(data.mdl or "models/weapons/w_pistol.mdl")
            local ent = modelPanel:GetEntity()
            if IsValid(ent) then
                FitModel(ent, modelPanel)
            end
            local desc = LoadDescription(class) or "No data available."
            SetAnimatedText(descBox, desc)
        end

        for class, data in pairs(WEAPONS) do
            local displayName = GetEnemyDisplayName(class)
            local btn = vgui.Create("DButton", weaponScroll)
            btn:Dock(TOP)
            btn:DockMargin(5, 2, 5, 2)
            btn:SetTall(30)
            btn:SetText("")
            btn.Paint = function(self, w, h)
                local color
                if bottomPanel.CurrentWeapon == class then
                    color = Color(255,255,255)
                elseif READ_STATUS.weapons[class] then
                    color = Color(150,150,150)
                else
                    color = NetricsaStyle.color
                end
                draw.SimpleText(displayName, "NetricsaText", 5, h/2, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            btn.DoClick = function() OpenWeapon(class) end
        end

        OpenFirstUnread(L("tabs","weapons"), OpenWeapon)

    elseif tabName == L("tabs","statistics") then
        local style = NetricsaStyle or STYLES.Revolution
        local bgMatText = Material(style.text, "noclamp smooth")

        -- ВЕРХ: панель с заголовком (имя карты из .lua)
        local headerPanel = vgui.Create("DPanel", contentPanel)
        NoBG(headerPanel)
        headerPanel:Dock(TOP)
        headerPanel:SetTall(200) -- ← было 60
        headerPanel.Paint = function(self, w, h)
            surface.SetDrawColor(255,255,255,255)
            surface.SetMaterial(bgMatText)
            surface.DrawTexturedRect(0, 0, w, h)

            local mapName = game.GetMap()
            local desc = LoadDescription(mapName)
            local firstLine = desc and string.match(desc, "([^\n\r]+)") or mapName
            draw.SimpleText(firstLine, "NetricsaTitle", 20, 10, style.color,
                TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end

        -- НИЗ: слева картинка уровня, справа статистика
        local bottomPanel = vgui.Create("DPanel", contentPanel)
        NoBG(bottomPanel)
        bottomPanel:Dock(FILL)
        bottomPanel:DockMargin(0, 10, 0, 0)

        -- слева картинка карты (40% ширины)
        local mapImagePanel = vgui.Create("DPanel", bottomPanel)
        mapImagePanel:Dock(LEFT)
        mapImagePanel:SetWide(math.floor(contentPanel:GetWide() * 0.4)) 
        mapImagePanel.Paint = function(self, w, h)
            local mapToShow = game.GetMap()
            local levelImagePath = "levels/" .. mapToShow .. ".png"
            if file.Exists("materials/" .. levelImagePath, "GAME") then
                surface.SetDrawColor(255,255,255,255)
                surface.SetMaterial(Material(levelImagePath, "noclamp smooth"))
                surface.DrawTexturedRect(0, 0, w, h)
            else
                surface.SetDrawColor(100,100,100,255)
                surface.DrawRect(0, 0, w, h)
                draw.SimpleText("No Level Image","NetricsaText", w/2, h/2,
                    Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end

        -- справа текст статистики
        local statsPanel = vgui.Create("DPanel", bottomPanel)
        NoBG(statsPanel)
        statsPanel:Dock(FILL)
        statsPanel:DockMargin(10, 0, 0, 0)
        statsPanel.Paint = function(self, w, h)
            surface.SetDrawColor(255,255,255,255)
            surface.SetMaterial(bgMatText)
            surface.DrawTexturedRect(0, 0, w, h)

            -- здесь выводим статистику
            local mapName = game.GetMap()

            local killedEnemies = stats_kills or 0
            local totalEnemies  = stats_totalEnemies or 0
            local killsText = string.format("%s: %d/%d", L("ui","kills"), killedEnemies, totalEnemies)

            local foundSecrets = (stats_secrets or 0)
            local totalSecrets = (stats_secrets_total or 0)
            local secretsText = string.format("%s: %d/%d", L("ui","secrets"), foundSecrets, totalSecrets)

            local playTime = string.ToMinutesSeconds(CurTime() - (stats_startTime or 0))
            local timeText    = L("ui","game_time") .. ": " .. playTime

            -- рисуем текст
            draw.SimpleText("TOTAL", "NetricsaTitle", 20, 20, style.color, TEXT_ALIGN_LEFT)
            draw.SimpleText(killsText, "NetricsaText", 20, 60, style.color, TEXT_ALIGN_LEFT)
            draw.SimpleText(secretsText, "NetricsaText", 20, 90, style.color, TEXT_ALIGN_LEFT)
            draw.SimpleText(timeText, "NetricsaText", 20, 120, style.color, TEXT_ALIGN_LEFT)
        end
    end
end


-- вспомогательные функции
local currentTab = L("tabs","strategic")

local function OpenStatistics()
    SwitchTab(L("tabs","statistics"))
    currentTab = L("tabs","statistics")
end

local function OpenNext(tab)
    if tab == "maps" then
        local keys = table.GetKeys(SAVED_MAPS)
        table.sort(keys)
        local cur = contentPanel.CurrentMap
        local idx = table.KeyFromValue(keys, cur) or 0
        local nextKey = keys[(idx % #keys) + 1]
        for _, btn in pairs(contentPanel:GetChildren()) do
            if btn.DoClick and string.find(tostring(btn.DoClick), nextKey) then
                btn:DoClick()
                break
            end
        end
    elseif tab == L("tabs","enemies") then
        local keys = table.GetKeys(ENEMIES)
        local cur = contentPanel.CurrentEnemy
        local idx = table.KeyFromValue(keys, cur) or 0
        local nextKey = keys[(idx % #keys) + 1]
        for _, btn in pairs(contentPanel:GetChildren()) do
            if btn.DoClick and string.find(tostring(btn.DoClick), nextKey) then
                btn:DoClick()
                break
            end
        end
    elseif tab == L("tabs","weapons") then
        local keys = table.GetKeys(WEAPONS)
        local cur = contentPanel.CurrentWeapon
        local idx = table.KeyFromValue(keys, cur) or 0
        local nextKey = keys[(idx % #keys) + 1]
        for _, btn in pairs(contentPanel:GetChildren()) do
            if btn.DoClick and string.find(tostring(btn.DoClick), nextKey) then
                btn:DoClick()
                break
            end
        end
    end
end

-- ловим нажатия клавиш
hook.Add("Think", "NetricsaHotkeys", function()
    if not IsValid(NetricsaFrame) or not NetricsaFrame:IsVisible() then return end

    if input.WasKeyPressed(KEY_F2) then
        OpenStatistics()
    elseif input.WasKeyPressed(KEY_F3) then
        if currentTab == L("tabs","strategic") then OpenNext("maps")
        elseif currentTab == L("tabs","enemies") then OpenNext(L("tabs","enemies"))
        elseif currentTab == L("tabs","weapons") then OpenNext(L("tabs","weapons"))
        end
    end
end)



     local tabs = {
    L("tabs","tactical"),
    L("tabs","strategic"),
    L("tabs","weapons"),
    L("tabs","enemies"),
    L("tabs","fractions"),
    L("tabs","statistics")
}

for i, name in ipairs(tabs) do
    local btn = CreateButton(leftPanel, name)
    btn:SetText(name)
    btn:SetSize(230,40)
    btn:SetPos(10, (i-1)*45 + 10)
    btn:SetFont("NetricsaText")
    btn.Paint = function(self, w, h)
        self:SetTextColor(NetricsaStyle.color)
        local unread = GetUnreadCount(name) -- уже умеет нормализовать
        if unread > 0 then
            draw.SimpleText("("..unread..")", "NetricsaText", w-10, h/2, Color(255,0,0), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end
    btn.DoClick = function() SwitchTab(name) end
end


        
        -- Кнопка стилей
        local styleBtn = vgui.Create("DButton", leftPanel)
        styleBtn:SetText(L("ui","styles"))
        styleBtn:SetSize(230,40)
        styleBtn:SetPos(10, (#tabs)*45 + 20)
        styleBtn:SetFont("NetricsaText")
        styleBtn:SetTextColor(NetricsaStyle.color)

        styleBtn.Paint = function(self, w, h)
            -- только прозрачный фон (по сути ничего не рисуем)
            surface.SetDrawColor(0, 0, 0, 0)
            surface.DrawRect(0, 0, w, h)

            -- цвет текста остаётся
            self:SetTextColor(NetricsaStyle.color)
        end


        styleBtn.DoClick = function()
            local menu = DermaMenu()
            for name, _ in pairs(STYLES) do
                menu:AddOption(name, function()
                    SetNetricsaStyle(name)

                    -- если интерфейс открыт — пересоздаём его полностью, чтобы все материалы/панели взяли новый стиль
                    if IsValid(NetricsaFrame) then
                        NetricsaFrame:Remove()
                        NetricsaFrame = nil
                        if OpenNetricsa then
                            OpenNetricsa()
                        end
                    end
                end)
            end
            menu:Open()
        end

-- Кнопка выбора языка (внизу)
local langBtn = vgui.Create("DButton", leftPanel)
langBtn:Dock(BOTTOM)
langBtn:DockMargin(10, 10, 10, 10)
langBtn:SetTall(40)
langBtn:SetText(L("ui","language"))
langBtn:SetFont("NetricsaText")
langBtn:SetTextColor(NetricsaStyle.color)

langBtn.Paint = function(self, w, h)
    surface.SetDrawColor(0, 0, 0, 0)
    surface.DrawRect(0, 0, w, h)
    self:SetTextColor(NetricsaStyle.color)
end

langBtn.DoClick = function()
    local menu = DermaMenu()
    for code,_ in pairs(LANGUAGES) do
        menu:AddOption(code:upper(), function()
            CurrentLang = code
            file.Write("netricsa_lang.lua", code)
            surface.PlaySound("netricsa/button_ssm_press.wav")
            if IsValid(NetricsaFrame) then
                NetricsaFrame:Remove()
                NetricsaFrame = nil
                if OpenNetricsa then
                    OpenNetricsa()
                end
            end
        end)
    end
    menu:Open()
end



        SwitchTab(L("tabs","strategic"))
    end

    hook.Add("Think","NetricsaKey",function()
        if input.IsKeyDown(KEY_N) and not vgui.CursorVisible() then
            OpenNetricsa()
        end
    end)

    

    net.Receive("Netricsa_AddEnemy", function()
        local npcClass = net.ReadString()
        local mdl = net.ReadString()
        local skin = net.ReadUInt(8)
        local bgCount = net.ReadUInt(8)
        local bodygroups = {}
        for i=1,bgCount do bodygroups[i] = net.ReadUInt(8) end

        local isNew = not ENEMIES[npcClass] -- проверяем, есть ли уже
        ENEMIES[npcClass] = { mdl = mdl, skin = skin, bodygroups = bodygroups }
        SaveProgress()

        if isNew then
            showScan = true
            timer.Simple(2, function() showScan = false end)
            surface.PlaySound("netricsa/Info.wav")
        end
    end)

net.Receive("Netricsa_AddWeapon", function()
    local class = net.ReadString()
    local mdl = net.ReadString()

    local isNew = not WEAPONS[class]
    WEAPONS[class] = { mdl = mdl }
    SaveProgress()

    if isNew then
        showScan = true
        timer.Simple(2, function() showScan = false end)
        surface.PlaySound("netricsa/Info.wav")
    end
end)

    -- =======================
    -- HUD L("ui","scanning")
    -- =======================
    hook.Add("HUDPaint","NetricsaScanText",function()
        if showScan then
            local alpha = math.abs(math.sin(CurTime()*4))*255
            draw.SimpleText(L("ui","scanning"),"NetricsaBig",ScrW()/2,100,Color(0,255,255,alpha),TEXT_ALIGN_CENTER)
        end
    end)



hook.Add("HUDPaint", "NetricsaMailIcon", function()
    if not NetricsaStyle or not NetricsaStyle.mail then return end

    -- считаем все непрочитанные
    local unread = GetUnreadCount("maps") + GetUnreadCount(L("tabs","enemies")) + GetUnreadCount(L("tabs","weapons"))
    if unread <= 0 then return end

    local iconMat = Material(NetricsaStyle.mail, "noclamp smooth")

    local texW = iconMat and iconMat:Width() or 0
    local texH = iconMat and iconMat:Height() or 0
    if texW <= 0 or texH <= 0 then
        texW, texH = 64, 64
    end

    local maxSize = 160
    local scale = math.min(maxSize / texW, maxSize / texH)
    local drawW, drawH = math.floor(texW * scale), math.floor(texH * scale)

    local x = ScrW() - drawW - 20
    local y = 20

    -- общий альфа для иконки и текста
    local alpha = math.abs(math.sin(CurTime() * 3)) * 255

    -- фон-иконка с миганием
    surface.SetDrawColor(255, 255, 255, alpha)
    surface.SetMaterial(iconMat)
    surface.DrawTexturedRect(x, y, drawW, drawH)

    -- мигающее число (с тем же alpha)
    local cx, cy = x + drawW / 2, y + drawH / 2
    draw.SimpleText(unread, "NetricsaTitle", cx + 1, cy + 1, Color(0, 0, 0, alpha / 2),
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(unread, "NetricsaTitle", cx,     cy,     Color(255, 0, 0, alpha),
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

hook.Add("InitPostEntity", "NetricsaAutoOpen", function()
    timer.Simple(2, function()
        if IsValid(LocalPlayer()) then
            OpenNetricsa()
        end
    end)
end)
end
