if CLIENT then
    local function SwitchTab(tabName)
        print("[Netricsa] SwitchTab called with:", tabName)
        local contentPanel = NetricsaMain.contentPanel or _G.NetricsaContentPanel
        print("[Netricsa] contentPanel:", contentPanel and "valid" or "nil")
        if not contentPanel then
            print("[Netricsa] ERROR: contentPanel is nil!")
            return
        end
        print("[Netricsa] Clearing contentPanel")
        contentPanel:Clear()

        if tabName == L("tabs","tactical") then
            print("[Netricsa] Creating tactical tab content")

            local style = NetricsaStyle or STYLES.Revolution
            local bgMatText = Material(style.text, "noclamp smooth")
            local bgMatTac = Material(style.bg or "netricsa/bg_netricsa.png", "noclamp smooth")

            -- ВЕРХ: можно сделать список (как enemyListPanel)
            local listPanel = vgui.Create("DPanel", contentPanel)
            NetricsaUtils.NoBG(listPanel)
            listPanel:Dock(TOP)
            listPanel:SetTall(200)
            local upMat = Material(NetricsaStyle.up or "netricsa/up_bg.png", "noclamp smooth")
            listPanel.Paint = function(self, w, h)
                surface.SetDrawColor(255, 255, 255, 255)
                surface.SetMaterial(upMat)
                surface.DrawTexturedRect(0, 0, w, h)
                draw.SimpleText("WELCOME TO NETRICSA!", "NetricsaTitle", 20, 10, style.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end

            local scroll = vgui.Create("DScrollPanel", listPanel)
            scroll:Dock(FILL)

            -- НИЗ: слева картинка bg_netricsa, справа описание
            local bottomPanel = vgui.Create("DPanel", contentPanel)
            NetricsaUtils.NoBG(bottomPanel)
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
            NetricsaUtils.NoBG(textPanel)
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
            local desc = NetricsaData.LoadDescription("infonetricsa") or "No data available."
            NetricsaUtils.SetAnimatedText(descBox, desc, 10, 0.005) -- быстрее печать

        elseif tabName == L("tabs","strategic") then
            print("[Netricsa] Creating strategic tab content")
            local style = NetricsaStyle or (STYLES and STYLES.Revolution) or {
                text = "netricsa/text_bg.png",
                model = "netricsa/model_bg.png",
                color = Color(255,255,0)
            }
            local bgMatText = Material(style.text, "noclamp smooth")

            -- верх: список карт
            local mapListPanel = vgui.Create("DPanel", contentPanel)
            NetricsaUtils.NoBG(mapListPanel)
            mapListPanel:Dock(TOP)
            mapListPanel:SetTall(200)
            local upMat = Material(NetricsaStyle.up or "netricsa/up_bg.png", "noclamp smooth")
            mapListPanel.Paint = function(self, w, h)
                surface.SetDrawColor(255, 255, 255, 255)
                surface.SetMaterial(upMat)
                surface.DrawTexturedRect(0, 0, w, h)
            end

            local mapScroll = vgui.Create("DScrollPanel", mapListPanel)
            mapScroll:Dock(FILL)
            mapScroll:DockMargin(8, 8, 8, 8)

            -- низ: картинка уровня + описание
            local bottomPanel = vgui.Create("DPanel", contentPanel)
            NetricsaUtils.NoBG(bottomPanel)
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
            NetricsaUtils.NoBG(textPanel)
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
                NetricsaData.READ_STATUS.maps[mapName] = true
                NetricsaData.SaveProgress()
                local desc = NetricsaData.LoadDescription(mapName) or "No data available."
                NetricsaUtils.SetAnimatedText(descBox, desc)
            end

            -- список карт: стиль как у ENEMIES, название — первая строка из descriptions/<map>.lua
            for mapName, _ in pairs(NetricsaData.SAVED_MAPS) do
                local displayName = NetricsaData.GetEnemyDisplayName(mapName) or mapName

                local btn = vgui.Create("DButton", mapScroll)
                btn:Dock(TOP)
                btn:DockMargin(5, 2, 5, 2)
                btn:SetTall(30)
                btn:SetText("")
                btn.Paint = function(self, w, h)
                    local color
                    if bottomPanel.CurrentMap == mapName then
                        color = Color(255,255,255)
                    elseif NetricsaData.READ_STATUS.maps[mapName] then
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
            NetricsaData.OpenFirstUnread("maps", OpenMap)

            -- если список пустой, добавляем текущую карту
            if table.IsEmpty(NetricsaData.SAVED_MAPS) then
                local currentMap = game.GetMap()
                NetricsaData.SAVED_MAPS[currentMap] = true
                NetricsaData.SaveProgress()

                local btn = vgui.Create("DButton", mapScroll)
                btn:Dock(TOP)
                btn:DockMargin(5, 2, 5, 2)
                btn:SetTall(30)
                btn:SetText("")
                local displayName = NetricsaData.GetEnemyDisplayName(currentMap) or currentMap
                btn.Paint = function(self, w, h)
                    draw.SimpleText(displayName, "NetricsaText", 5, h/2, style.color,
                        TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
                btn.DoClick = function() OpenMap(currentMap) end

                OpenMap(currentMap)
            else
                NetricsaData.OpenFirstUnread("maps", OpenMap)
            end

        elseif tabName == L("tabs","enemies") then
            local bgMatText = Material(NetricsaStyle.text, "noclamp smooth")

            local enemyListPanel = vgui.Create("DPanel", contentPanel)
            NetricsaUtils.NoBG(enemyListPanel)
            enemyListPanel:Dock(TOP)
            enemyListPanel:SetTall(200)
            local upMat = Material(NetricsaStyle.up or "netricsa/up_bg.png", "noclamp smooth")
            enemyListPanel.Paint = function(self, w, h)
                surface.SetDrawColor(255, 255, 255, 255)
                surface.SetMaterial(upMat)
                surface.DrawTexturedRect(0, 0, w, h)
            end

            local enemyScroll = vgui.Create("DScrollPanel", enemyListPanel)
            enemyScroll:Dock(FILL)

            local bottomPanel = vgui.Create("DPanel", contentPanel)
            NetricsaUtils.NoBG(bottomPanel)
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
            NetricsaUtils.NoBG(textPanel)
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
                NetricsaData.READ_STATUS.enemies[npcClass] = true
                NetricsaData.SaveProgress()
                local entData = NetricsaData.ENEMIES[npcClass]
                modelPanel:SetModel(entData.mdl or "models/props_c17/oildrum001.mdl")
                local ent = modelPanel:GetEntity()
                if IsValid(ent) then
                    NetricsaUtils.FitModel(ent, modelPanel)
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
                local desc = NetricsaData.LoadDescription(npcClass) or "No data available."
                NetricsaUtils.SetAnimatedText(descBox, desc)
            end

            for npcClass, data in pairs(NetricsaData.ENEMIES) do
                local displayName = NetricsaData.GetEnemyDisplayName(npcClass)
                local btn = vgui.Create("DButton", enemyScroll)
                btn:Dock(TOP)
                btn:DockMargin(5, 2, 5, 2)
                btn:SetTall(30)
                btn:SetText("")
                btn.Paint = function(self, w, h)
                    local color
                    if bottomPanel.CurrentEnemy == npcClass then
                        color = Color(255,255,255)
                    elseif NetricsaData.READ_STATUS.enemies[npcClass] then
                        color = Color(150,150,150)
                    else
                        color = NetricsaStyle.color
                    end
                    draw.SimpleText(displayName, "NetricsaText", 5, h/2, color,
                        TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
                btn.DoClick = function() OpenEnemy(npcClass) end
            end

            NetricsaData.OpenFirstUnread(L("tabs","enemies"), OpenEnemy)

        elseif tabName == L("tabs","fractions") then
            local bgMatText = Material(NetricsaStyle.text, "noclamp smooth")

            -- Верх: список фракций
            local fracListPanel = vgui.Create("DPanel", contentPanel)
            NetricsaUtils.NoBG(fracListPanel)
            fracListPanel:Dock(TOP)
            fracListPanel:SetTall(200)
            local upMat = Material(NetricsaStyle.up or "netricsa/up_bg.png", "noclamp smooth")
            fracListPanel.Paint = function(self, w, h)
                surface.SetDrawColor(255,255,255,255)
                surface.SetMaterial(upMat)
                surface.DrawTexturedRect(0, 0, w, h)
            end

            local fracScroll = vgui.Create("DScrollPanel", fracListPanel)
            fracScroll:Dock(FILL)

            -- Низ: картинка + описание
            local bottomPanel = vgui.Create("DPanel", contentPanel)
            NetricsaUtils.NoBG(bottomPanel)
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
            NetricsaUtils.NoBG(textPanel)
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
                local desc = NetricsaData.LoadDescription(name) or "No data available."
                NetricsaUtils.SetAnimatedText(descBox, desc)
            end

            -- перебор файлов descriptions/<lang>/ssfrac_*.lua
            local lang = CurrentLang or "en"
            local files, _ = file.Find("lua/netricsa/descriptions/"..lang.."/ssfrac_*.lua","GAME")
            for _, f in ipairs(files) do
                local fracName = string.StripExtension(f)
                local displayName = NetricsaData.GetEnemyDisplayName(fracName) -- первая строка файла
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
            NetricsaUtils.NoBG(weaponListPanel)
            weaponListPanel:Dock(TOP)
            weaponListPanel:SetTall(200)
            local upMat = Material(NetricsaStyle.up or "netricsa/up_bg.png", "noclamp smooth")
            weaponListPanel.Paint = function(self, w, h)
                surface.SetDrawColor(255, 255, 255, 255)
                surface.SetMaterial(upMat)
                surface.DrawTexturedRect(0, 0, w, h)
            end

            local weaponScroll = vgui.Create("DScrollPanel", weaponListPanel)
            weaponScroll:Dock(FILL)

            local bottomPanel = vgui.Create("DPanel", contentPanel)
            NetricsaUtils.NoBG(bottomPanel)
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
            NetricsaUtils.NoBG(textPanel)
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
                NetricsaData.READ_STATUS.weapons[class] = true
                NetricsaData.SaveProgress()
                local data = NetricsaData.WEAPONS[class]
                modelPanel:SetModel(data.mdl or "models/weapons/w_pistol.mdl")
                local ent = modelPanel:GetEntity()
                if IsValid(ent) then
                    NetricsaUtils.FitModel(ent, modelPanel)
                end
                local desc = NetricsaData.LoadDescription(class) or "No data available."
                NetricsaUtils.SetAnimatedText(descBox, desc)
            end

            for class, data in pairs(NetricsaData.WEAPONS) do
                local displayName = NetricsaData.GetEnemyDisplayName(class)
                local btn = vgui.Create("DButton", weaponScroll)
                btn:Dock(TOP)
                btn:DockMargin(5, 2, 5, 2)
                btn:SetTall(30)
                btn:SetText("")
                btn.Paint = function(self, w, h)
                    local color
                    if bottomPanel.CurrentWeapon == class then
                        color = Color(255,255,255)
                    elseif NetricsaData.READ_STATUS.weapons[class] then
                        color = Color(150,150,150)
                    else
                        color = NetricsaStyle.color
                    end
                    draw.SimpleText(displayName, "NetricsaText", 5, h/2, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
                btn.DoClick = function() OpenWeapon(class) end
            end

            NetricsaData.OpenFirstUnread(L("tabs","weapons"), OpenWeapon)

        elseif tabName == L("tabs","statistics") then
            local style = NetricsaStyle or STYLES.Revolution
            local bgMatText = Material(style.text, "noclamp smooth")

            -- ВЕРХ: панель с заголовком (имя карты из .lua)
            local headerPanel = vgui.Create("DPanel", contentPanel)
            NetricsaUtils.NoBG(headerPanel)
            headerPanel:Dock(TOP)
            headerPanel:SetTall(200) -- ← было 60
            local upMat = Material(NetricsaStyle.up or "netricsa/up_bg.png", "noclamp smooth")
            headerPanel.Paint = function(self, w, h)
                surface.SetDrawColor(255,255,255,255)
                surface.SetMaterial(upMat)
                surface.DrawTexturedRect(0, 0, w, h)

                local mapName = game.GetMap()
                local desc = NetricsaData.LoadDescription(mapName)
                local firstLine = desc and string.match(desc, "([^\n\r]+)") or mapName
                draw.SimpleText(firstLine, "NetricsaTitle", 20, 10, style.color,
                    TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end

            -- НИЗ: слева картинка уровня, справа статистика
            local bottomPanel = vgui.Create("DPanel", contentPanel)
            NetricsaUtils.NoBG(bottomPanel)
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
            NetricsaUtils.NoBG(statsPanel)
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

    -- Expose function
    NetricsaTabs = {
        SwitchTab = SwitchTab
    }

    -- Update current tab when switching
    local originalSwitchTab = SwitchTab
    function SwitchTab(tabName)
        originalSwitchTab(tabName)
        if NetricsaMain.UpdateCurrentTab then
            NetricsaMain.UpdateCurrentTab(tabName)
        end
    end
end