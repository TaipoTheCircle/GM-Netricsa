if CLIENT then

NetricsaCursorMaterial = nil
NetricsaCursorSize = 32

-- 🔹 Функция загрузки курсора
local function LoadNetricsaCursor()
    if not NetricsaStyle or not NetricsaStyle.cursor then 
        NetricsaCursorMaterial = nil
        print("[Netricsa] No cursor defined in current style")
        return
    end
    
    print("[Netricsa] Loading cursor: " .. NetricsaStyle.cursor)
    NetricsaCursorMaterial = Material(NetricsaStyle.cursor, "noclamp smooth")
    
    if not NetricsaCursorMaterial or NetricsaCursorMaterial:IsError() then
        print("[Netricsa] FAILED to load cursor: " .. NetricsaStyle.cursor)
        NetricsaCursorMaterial = nil
    else
        print("[Netricsa] Cursor loaded successfully: " .. 
              NetricsaStyle.cursor .. " (" .. 
              (NetricsaCursorMaterial:Width() or 0) .. "x" .. 
              (NetricsaCursorMaterial:Height() or 0) .. ")")
    end
end

-- 🔹 Рисуем кастомный курсор поверх VGUI
hook.Add("DrawOverlay", "Netricsa_CustomCursor", function()
    if not IsValid(NetricsaFrame) or not NetricsaFrame:IsVisible() then return end
    if not NetricsaCursorMaterial then return end
    if NetricsaCursorMaterial:IsError() then return end
    
    local x, y = input.GetCursorPos()
    local size = NetricsaCursorSize
    local half = size / 2
    
    surface.SetMaterial(NetricsaCursorMaterial)
    surface.SetDrawColor(255, 255, 255, 255)
    surface.DrawTexturedRect(x - half, y - half, size, size)
end)

-- Загружаем при старте
hook.Add("InitPostEntity", "Netricsa_InitCursor", function()
    timer.Simple(2, function()
        LoadNetricsaCursor()
    end)
end)

-- Перезагружаем при смене стиля
local originalSetNetricsaStyle = SetNetricsaStyle
function SetNetricsaStyle(name)
    originalSetNetricsaStyle(name)
    
    timer.Simple(0.1, function()
        LoadNetricsaCursor()
    end)
end

-- Отладка: рисуем большой красный квадрат, чтобы проверить, работает ли DrawOverlay
hook.Add("DrawOverlay", "Netricsa_DebugOverlay", function()
    if not IsValid(NetricsaFrame) or not NetricsaFrame:IsVisible() then return end
    
    -- Красный квадрат в левом верхнем углу - если видите его, значит DrawOverlay работает
    surface.SetDrawColor(255, 0, 0, 255)
    surface.DrawRect(10, 10, 50, 50)
    
    -- Информация о курсоре
    if NetricsaCursorMaterial then
        draw.SimpleText("Cursor LOADED", "NetricsaText", 70, 20, Color(0, 255, 0))
        draw.SimpleText("Size: " .. NetricsaCursorSize, "NetricsaText", 70, 45, Color(0, 255, 0))
    else
        draw.SimpleText("Cursor NOT LOADED", "NetricsaText", 70, 20, Color(255, 0, 0))
    end
end)

if not NetricsaMain then
    NetricsaMain = {}
    print("[Netricsa] NetricsaMain initialized in hooks")
end

net.Receive("Netricsa_AddScoreForNPC", function()
    if not NetricsaData then 
        print("[Netricsa] NetricsaData not ready yet")
        return 
    end
    local npcClass = net.ReadString()
    local score = NetricsaData.GetNPCScore and NetricsaData.GetNPCScore(npcClass) or 100
    
    print("[Netricsa] Adding score for killing " .. npcClass .. ": +" .. score)
    if NetricsaData.AddScore then
        NetricsaData.AddScore(score)
    end
end)

-- 🔹 Проверка, открыт ли интерфейс Netricsa или скрыт HUD
local function IsNetricsaHidden()
    return (IsValid(NetricsaFrame) and NetricsaFrame:IsVisible()) 
           or not GetConVar("cl_drawhud"):GetBool()
end

-- HUD отрисовка (Score, Mail, Scan Text)
hook.Add("HUDPaint", "NetricsaScoreIcon", function()
    if IsNetricsaHidden() then return end
    if not NetricsaData or not NetricsaStyle or not NetricsaStyle.score then return end
    
    local totalScore = NetricsaData.GetTotalScore and NetricsaData.GetTotalScore() or 0
    
    local iconMat = Material(NetricsaStyle.score, "noclamp smooth")
    
    local texW = iconMat and iconMat:Width() or 0
    local texH = iconMat and iconMat:Height() or 0
    if texW <= 0 or texH <= 0 then
        texW, texH = 64, 64
    end
    
    local maxSize = 160
    local scale = math.min(maxSize / texW, maxSize / texH)
    local drawW, drawH = math.floor(texW * scale), math.floor(texH * scale)
    
    local x = 20
    local y = 20
    
    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(iconMat)
    surface.DrawTexturedRect(x, y, drawW, drawH)
    
    local cx, cy = x + drawW / 2, y + drawH / 2
    local scoreText = tostring(totalScore)
    
    draw.SimpleText(scoreText, "NetricsaTitle", cx + 1, cy + 1, 
        Color(0, 0, 0, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(scoreText, "NetricsaTitle", cx, cy, 
        NetricsaStyle.color or Color(255, 255, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

hook.Add("HUDPaint","NetricsaScanText",function()
    if IsNetricsaHidden() then return end
    if not NetricsaData then return end
    if NetricsaData.showScan then
        local alpha = math.abs(math.sin(CurTime()*4))*255
        local style = NetricsaStyle or STYLES.Revolution
        local scanColor = Color(style.color.r, style.color.g, style.color.b, alpha)
        
        draw.SimpleText(L("ui","scanning"), "NetricsaBig", ScrW()/2, 170, 
            scanColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end)

hook.Add("HUDPaint", "NetricsaMailIcon", function()
    if IsNetricsaHidden() then return end
    if not NetricsaData or not NetricsaStyle or not NetricsaStyle.mail then return end

    local unread = 0
    if NetricsaData.GetUnreadCount then
        unread = NetricsaData.GetUnreadCount("maps") + NetricsaData.GetUnreadCount(L("tabs","enemies")) + NetricsaData.GetUnreadCount(L("tabs","weapons"))
    end
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

    local alpha = math.abs(math.sin(CurTime() * 3)) * 255

    surface.SetDrawColor(255, 255, 255, alpha)
    surface.SetMaterial(iconMat)
    surface.DrawTexturedRect(x, y, drawW, drawH)

    local cx, cy = x + drawW / 2, y + drawH / 2
    draw.SimpleText(unread, "NetricsaTitle", cx + 1, cy + 1, Color(0, 0, 0, alpha / 2),
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(unread, "NetricsaTitle", cx, cy, Color(255, 0, 0, alpha),
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

hook.Add("InitPostEntity", "NetricsaAutoOpen", function()
    timer.Simple(2, function()
        if not IsValid(LocalPlayer()) then return end
        if not NetricsaData then return end

        timer.Simple(0.2, function()
            local cvar = GetConVar("netricsa_auto_open")
            local shouldOpen = (not cvar) or cvar:GetBool()

            local unread = 0
            if NetricsaData.GetUnreadCount then
                unread = NetricsaData.GetUnreadCount("maps") + NetricsaData.GetUnreadCount(L("tabs","enemies")) + NetricsaData.GetUnreadCount(L("tabs","weapons"))
            end

            if shouldOpen and unread > 0 and NetricsaMain and NetricsaMain.OpenNetricsa then
                print("[Netricsa] Auto-opening interface after InitPostEntity (unread: " .. unread .. ")")
                NetricsaMain.OpenNetricsa()
            elseif unread == 0 then
                print("[Netricsa] Skipping auto-open: no new notifications")
            end
        end)
    end)
end)

local SamVoicePlayed = false

hook.Add("OnNetricsaClosed", "SAM_MAP_VOICES_ClientTrigger", function()
    if SamVoicePlayed then
        print("[Sam Map Voices] Звук уже был воспроизведён ранее - пропуск.")
        return
    end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    SamVoicePlayed = true
    RunConsoleCommand("sam_play_map_voice")

    print("[Sam Map Voices] Клиент запросил воспроизведение звука при закрытии Нетриксы")
end)

hook.Add("InitPostEntity", "SAM_MAP_VOICES_ResetAfterMapChange", function()
    SamVoicePlayed = false
    print("[Sam Map Voices] Флаг воспроизведения сброшен (новая карта)")
end)

-- Автоматическое добавление звуков для всех кнопок Netricsa
hook.Add("OnButtonCreated", "Netricsa_AutoAddSounds", function(btn)
    if not IsValid(btn) then return end
    
    local checkParent = btn
    while IsValid(checkParent) do
        if checkParent == NetricsaFrame then
            if not btn._hasNetricsaSounds then
                btn._hasNetricsaSounds = true
                
                local oldEnter = btn.OnCursorEntered
                btn.OnCursorEntered = function(self, ...)
                    surface.PlaySound("netricsa/button_ssm.wav")
                    if oldEnter then oldEnter(self, ...) end
                end
                
                local oldClick = btn.DoClick
                btn.DoClick = function(self, ...)
                    surface.PlaySound("netricsa/button_ssm_press.wav")
                    if oldClick then oldClick(self, ...) end
                end
            end
            break
        end
        checkParent = checkParent:GetParent()
    end
end)

end