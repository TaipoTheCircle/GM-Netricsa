if CLIENT then
    local NetricsaFrame
    local contentPanel

    function OpenNetricsa()
        if IsValid(NetricsaFrame) then
            NetricsaFrame:SetVisible(true)
            
            -- 🔹 ОБНОВЛЯЕМ СТАТИСТИКУ ПРИ ПОВТОРНОМ ОТКРЫТИИ
            if _G.NetricsaCurrentTab == L("tabs","statistics") then
                print("[Netricsa] Refreshing statistics tab on reopen")
                NetricsaTabs.SwitchTab(L("tabs","statistics"))
            end
            
            -- 🔹 ПРИНУДИТЕЛЬНО ОБНОВЛЯЕМ СТАТИСТИКУ ПРИ ОТКРЫТИИ
            timer.Simple(0.5, function()
                if stats_totalEnemies == 0 then
                    print("[Netricsa] Requesting stats update on open")
                    RunConsoleCommand("netricsa_check")
                end
            end)
            return
        end

        -- 🔹 ПРОВЕРКА В НАЧАЛЕ ФУНКЦИИ
        if not NetricsaTabs then
            print("[Netricsa] ERROR: NetricsaTabs not loaded! Loading tabs first...")
            include("cl_netricsa_tabs.lua")
            if not NetricsaTabs then
                print("[Netricsa] FATAL: Cannot load NetricsaTabs!")
                return
            end
        end

        NetricsaFrame = vgui.Create("DFrame")
        NetricsaFrame:SetSize(ScrW(), ScrH())
        NetricsaFrame:SetPos(0, 0)
        NetricsaFrame:ShowCloseButton(false)
        NetricsaFrame:SetTitle("")
        NetricsaFrame:SetDraggable(false)
        NetricsaFrame:MakePopup()

        local gridMat = Material(NetricsaStyle.grid or "netricsa/grid.png", "noclamp smooth")
        NetricsaFrame.Paint = function(self, w, h)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(gridMat)
            surface.DrawTexturedRect(0, 0, w, h)
            local style = NetricsaStyle or STYLES.Revolution
            draw.SimpleText(L("ui","version"), "NetricsaTitle", 20, 10, style.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end

        local exitBtn = vgui.Create("DButton", NetricsaFrame)
        exitBtn:SetText("")
        exitBtn:SetSize(40, 40)
        exitBtn:SetPos(ScrW() - 50, 10)

        exitBtn.DoClick = function()
            -- Воспроизводим звук Сэма при закрытии
            hook.Run("OnNetricsaClosed")
            NetricsaFrame:Close()
        end

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
        local leftMat = Material(NetricsaStyle.left or "netricsa/left_bg.png", "noclamp smooth")
        leftPanel.Paint = function(self, w, h)
            surface.SetDrawColor(255, 255, 255, 255)
            local bg = leftMat
            surface.SetMaterial(bg)
            surface.DrawTexturedRect(0, 0, w, h)
        end

        contentPanel = vgui.Create("DPanel", NetricsaFrame)
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

        -- Make contentPanel accessible globally for tabs BEFORE creating other elements
        _G.NetricsaContentPanel = contentPanel
        NetricsaMain.contentPanel = contentPanel
        print("[Netricsa] contentPanel created and set globally:", contentPanel and "valid" or "nil")

        -- вспомогательные функции
        local currentTab = L("tabs","strategic")

        local function OpenStatistics()
            NetricsaTabs.SwitchTab(L("tabs","statistics"))
            currentTab = L("tabs","statistics")
            _G.NetricsaCurrentTab = currentTab
        end

        -- Update currentTab when switching tabs
        local function UpdateCurrentTab(tabName)
            currentTab = tabName
            _G.NetricsaCurrentTab = currentTab
        end

        local function OpenNext(tab)
            if tab == "maps" then
                local keys = table.GetKeys(NetricsaData.SAVED_MAPS)
                table.sort(keys)
                local cur = contentPanel.CurrentMap
                local idx = table.KeyFromValue(keys, cur) or 0
                local nextKey = keys[(idx % #keys) + 1]
                -- Find the correct button in the map list panel
                local mapListPanel = contentPanel:GetChildren()[1] -- Assuming first child is map list
                if mapListPanel and mapListPanel:GetChildren()[1] then -- Scroll panel
                    for _, btn in pairs(mapListPanel:GetChildren()[1]:GetChildren()) do
                        if btn.DoClick and string.find(tostring(btn.DoClick), nextKey) then
                            btn:DoClick()
                            break
                        end
                    end
                end
            elseif tab == L("tabs","enemies") then
                local keys = table.GetKeys(NetricsaData.ENEMIES)
                local cur = contentPanel.CurrentEnemy
                local idx = table.KeyFromValue(keys, cur) or 0
                local nextKey = keys[(idx % #keys) + 1]
                -- Find the correct button in the enemy list panel
                local enemyListPanel = contentPanel:GetChildren()[1] -- Assuming first child is enemy list
                if enemyListPanel and enemyListPanel:GetChildren()[1] then -- Scroll panel
                    for _, btn in pairs(enemyListPanel:GetChildren()[1]:GetChildren()) do
                        if btn.DoClick and string.find(tostring(btn.DoClick), nextKey) then
                            btn:DoClick()
                            break
                        end
                    end
                end
            elseif tab == L("tabs","weapons") then
                local keys = table.GetKeys(NetricsaData.WEAPONS)
                local cur = contentPanel.CurrentWeapon
                local idx = table.KeyFromValue(keys, cur) or 0
                local nextKey = keys[(idx % #keys) + 1]
                -- Find the correct button in the weapon list panel
                local weaponListPanel = contentPanel:GetChildren()[1] -- Assuming first child is weapon list
                if weaponListPanel and weaponListPanel:GetChildren()[1] then -- Scroll panel
                    for _, btn in pairs(weaponListPanel:GetChildren()[1]:GetChildren()) do
                        if btn.DoClick and string.find(tostring(btn.DoClick), nextKey) then
                            btn:DoClick()
                            break
                        end
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
                if _G.NetricsaCurrentTab == L("tabs","strategic") then OpenNext("maps")
                elseif _G.NetricsaCurrentTab == L("tabs","enemies") then OpenNext(L("tabs","enemies"))
                elseif _G.NetricsaCurrentTab == L("tabs","weapons") then OpenNext(L("tabs","weapons"))
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
            local btn = NetricsaUtils.CreateButton(leftPanel, name)
            btn:SetText(name)
            btn:SetSize(230,40)
            btn:SetPos(10, (i-1)*45 + 10)
            btn:SetFont("NetricsaText")
            btn.Paint = function(self, w, h)
                self:SetTextColor(NetricsaStyle.color)
                local unread = NetricsaData.GetUnreadCount(name) -- уже умеет нормализовать
                if unread > 0 then
                    draw.SimpleText("("..unread..")", "NetricsaText", w-10, h/2, Color(255,0,0), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end
            end
            btn.DoClick = function()
                print("[Netricsa] Switching to tab:", name)
                NetricsaTabs.SwitchTab(name)
                UpdateCurrentTab(name)
                print("[Netricsa] Tab switched to:", name)
            end
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

                    -- если интерфейс открыт - пересоздаём его полностью, чтобы все материалы/панели взяли новый стиль
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
                    SaveLanguage(code)
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

        -- Determine the default tab: first with unread messages, or strategic if all read
        local defaultTab = L("tabs","strategic")
        for _, tabName in ipairs(tabs) do
            if NetricsaData.GetUnreadCount(tabName) > 0 then
                defaultTab = tabName
                break
            end
        end

        print("[Netricsa] Initializing default tab: " .. defaultTab)
        -- Initialize tab immediately since contentPanel is now set
        print("[Netricsa] Immediate SwitchTab call")
        NetricsaTabs.SwitchTab(defaultTab)
        UpdateCurrentTab(defaultTab)
        print("[Netricsa] Default tab initialized")
        
        -- 🔹 ЗАПРАШИВАЕМ СТАТИСТИКУ ПРИ ОТКРЫТИИ NETRICSA
        timer.Simple(0.5, function()
            print("[Netricsa] Requesting stats on interface open")
            RunConsoleCommand("netricsa_check")
        end)
    end

    -- Expose
    NetricsaMain = {
        OpenNetricsa = OpenNetricsa,
        contentPanel = contentPanel,
        UpdateCurrentTab = UpdateCurrentTab
    }

    -- Make currentTab accessible globally
    _G.NetricsaCurrentTab = currentTab
end