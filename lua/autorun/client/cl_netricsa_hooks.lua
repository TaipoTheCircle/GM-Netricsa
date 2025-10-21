if CLIENT then
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

                if shouldOpen then
                    print("[Netricsa] Auto-opening interface after InitPostEntity")
                    NetricsaMain.OpenNetricsa()
                end
            end)
        end)
    end)
end