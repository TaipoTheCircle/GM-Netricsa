if CLIENT then

    if not NetricsaMain then
        NetricsaMain = {}
        print("[Netricsa] NetricsaMain initialized in hooks")
    end
    
        net.Receive("Netricsa_AddScoreForNPC", function()
        local npcClass = net.ReadString()
        local score = NetricsaData.GetNPCScore(npcClass)
        
        print("[Netricsa] Adding score for killing " .. npcClass .. ": +" .. score)
        NetricsaData.AddScore(score)
        
        -- Воспроизводим звук получения очков (опционально)
        surface.PlaySound("")
    end)

    net.Receive("Netricsa_AddEnemy", function()
        local npcClass = net.ReadString()
        local mdl = net.ReadString()
        local skin = net.ReadUInt(8)
        local bgCount = net.ReadUInt(8)
        local bodygroups = {}
        for i=1,bgCount do bodygroups[i] = net.ReadUInt(8) end

        print("[Netricsa Client] Received AddEnemy: " .. npcClass)
        local isNew = not NetricsaData.ENEMIES[npcClass] -- проверяем, есть ли уже
        NetricsaData.ENEMIES[npcClass] = { mdl = mdl, skin = skin, bodygroups = bodygroups }
        NetricsaData.SaveProgress()

        if isNew then
            print("[Netricsa Client] New enemy discovered: " .. npcClass)
            NetricsaData.showScan = true
            timer.Simple(2, function() NetricsaData.showScan = false end)
            surface.PlaySound("netricsa/Info.wav")
        end
    end)

    net.Receive("Netricsa_AddWeapon", function()
        local class = net.ReadString()
        local mdl = net.ReadString()

        print("[Netricsa Client] Received AddWeapon: " .. class)
        local isNew = not NetricsaData.WEAPONS[class]
        NetricsaData.WEAPONS[class] = { mdl = mdl }
        NetricsaData.SaveProgress()

        if isNew then
            print("[Netricsa Client] New weapon discovered: " .. class)
            NetricsaData.showScan = true
            timer.Simple(2, function() NetricsaData.showScan = false end)
            surface.PlaySound("netricsa/Info.wav")
        end
    end)

    -- =======================
    -- HUD L("ui","scanning")
    -- =======================

 hook.Add("HUDPaint", "NetricsaScoreIcon", function()
        if not NetricsaStyle or not NetricsaStyle.score then return end
        
        local totalScore = NetricsaData.GetTotalScore() or 0
        
        local iconMat = Material(NetricsaStyle.score, "noclamp smooth")
        
        local texW = iconMat and iconMat:Width() or 0
        local texH = iconMat and iconMat:Height() or 0
        if texW <= 0 or texH <= 0 then
            texW, texH = 64, 64
        end
        
        local maxSize = 160
        local scale = math.min(maxSize / texW, maxSize / texH)
        local drawW, drawH = math.floor(texW * scale), math.floor(texH * scale)
        
        -- Отображаем слева сверху
        local x = 20
        local y = 20
        
        -- Иконка очков (без мигания, всегда видна если есть очки)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(iconMat)
        surface.DrawTexturedRect(x, y, drawW, drawH)
        
        -- Число очков (даже если 0)
        local cx, cy = x + drawW / 2, y + drawH / 2
        local scoreText = tostring(totalScore)
        
        -- Черная тень
        draw.SimpleText(scoreText, "NetricsaTitle", cx + 1, cy + 1, 
            Color(0, 0, 0, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        -- Основной текст (желтый как цвет стиля)
        draw.SimpleText(scoreText, "NetricsaTitle", cx, cy, 
            NetricsaStyle.color or Color(255, 255, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end)

    hook.Add("HUDPaint","NetricsaScanText",function()
        if NetricsaData.showScan then
            local alpha = math.abs(math.sin(CurTime()*4))*255
            draw.SimpleText(L("ui","scanning"),"NetricsaBig",ScrW()/2,100,Color(0,255,255,alpha),TEXT_ALIGN_CENTER)
        end
    end)

    hook.Add("HUDPaint", "NetricsaMailIcon", function()
        if not NetricsaStyle or not NetricsaStyle.mail then return end

        -- считаем все непрочитанные
        local unread = NetricsaData.GetUnreadCount("maps") + NetricsaData.GetUnreadCount(L("tabs","enemies")) + NetricsaData.GetUnreadCount(L("tabs","weapons"))
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
            if not IsValid(LocalPlayer()) then return end

            -- ждём, пока все client convars загрузятся
            timer.Simple(0.2, function()
                local cvar = GetConVar("netricsa_auto_open")

                -- если конвар отсутствует — считаем, что включено по умолчанию
                local shouldOpen = (not cvar) or cvar:GetBool()

                -- проверяем наличие новых уведомлений (непрочитанных элементов)
                local unread = NetricsaData.GetUnreadCount("maps") + NetricsaData.GetUnreadCount(L("tabs","enemies")) + NetricsaData.GetUnreadCount(L("tabs","weapons"))

                if shouldOpen and unread > 0 then
                    print("[Netricsa] Auto-opening interface after InitPostEntity (unread: " .. unread .. ")")
                    NetricsaMain.OpenNetricsa()
                elseif unread == 0 then
                    print("[Netricsa] Skipping auto-open: no new notifications")
                end
            end)
        end)
    end)

    if CLIENT then
        local SamVoicePlayed = false  -- флаг, чтобы не повторялся звук

        hook.Add("OnNetricsaClosed", "SAM_MAP_VOICES_ClientTrigger", function()
            if SamVoicePlayed then
                print("[Sam Map Voices] Звук уже был воспроизведён ранее — пропуск.")
                return
            end

            local ply = LocalPlayer()
            if not IsValid(ply) then return end

            SamVoicePlayed = true  -- помечаем, что уже проиграли звук
            RunConsoleCommand("sam_play_map_voice")

            print("[Sam Map Voices] Клиент запросил воспроизведение звука при закрытии Нетриксы")
        end)

        -- сброс флага при загрузке новой карты
        hook.Add("InitPostEntity", "SAM_MAP_VOICES_ResetAfterMapChange", function()
            SamVoicePlayed = false
            print("[Sam Map Voices] Флаг воспроизведения сброшен (новая карта)")
        end)
    end
end