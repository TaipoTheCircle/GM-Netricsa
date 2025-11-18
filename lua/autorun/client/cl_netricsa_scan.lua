if CLIENT then
    local scanPromptNPC = nil
    local scanPromptTime = 0
    local lastScanKeyPress = 0

    -- Net handlers
    net.Receive("Netricsa_ShowScanPrompt", function()
        local npcClass = net.ReadString()
        scanPromptNPC = npcClass
        scanPromptTime = CurTime()
    end)

    net.Receive("Netricsa_HideScanPrompt", function()
        scanPromptNPC = nil
    end)

    -- Функция получения клавиши сканирования
    local function GetScanKey()
        local key = GetConVar("netricsa_scan_key"):GetString()
        if key == "" then key = "E" end
        return input.GetKeyCode(key:lower()) or KEY_E
    end

    -- Отрисовка подсказки (только когда смотрим на NPC)
    hook.Add("HUDPaint", "Netricsa_ScanPrompt", function()
        -- 🔹 НЕ ПОКАЗЫВАТЬ ПОДСКАЗКУ ЕСЛИ ОТКРЫТ ИНТЕРФЕЙС NETRICSA
        if IsValid(NetricsaFrame) and NetricsaFrame:IsVisible() then
            return
        end
        
        if not scanPromptNPC then return end
        
        local alpha = math.abs(math.sin(CurTime() * 3)) * 255
        local style = NetricsaStyle or STYLES.Revolution
        
        -- 🔹 ИСПОЛЬЗУЕМ ЛОКАЛЬНУЮ ПЕРЕМЕННУЮ ДЛЯ ЦВЕТА, А НЕ МЕНЯЕМ ГЛОБАЛЬНЫЙ STYLE
        local scanColor = Color(style.color.r, style.color.g, style.color.b, alpha)
        
        local keyName = GetConVar("netricsa_scan_key"):GetString()
        if keyName == "" then keyName = "E" end
        
        local text = L("ui", "scan_prompt"):format(keyName:upper())
        
        -- Рисуем внизу экрана по центру
        draw.SimpleText(text, "NetricsaBig", ScrW() / 2, ScrH() - 100, scanColor, TEXT_ALIGN_CENTER)
        
        -- Дополнительная подсказка - какой NPC сканируется
        local displayName = NetricsaData.GetEnemyDisplayName(scanPromptNPC) or scanPromptNPC
        draw.SimpleText(displayName, "NetricsaText", ScrW() / 2, ScrH() - 130, scanColor, TEXT_ALIGN_CENTER)
    end)

    -- Обработка нажатия клавиши сканирования
    hook.Add("Think", "Netricsa_ScanInput", function()
        -- 🔹 НЕ ОБРАБАТЫВАТЬ ВВОД ЕСЛИ ОТКРЫТ ИНТЕРФЕЙС NETRICSA
        if IsValid(NetricsaFrame) and NetricsaFrame:IsVisible() then
            return
        end
        
        if not scanPromptNPC then return end
        
        local scanKey = GetScanKey()
        
        if input.IsKeyDown(scanKey) and CurTime() - lastScanKeyPress > 0.5 then
            lastScanKeyPress = CurTime()
            
            -- Отправляем запрос на сканирование
            net.Start("Netricsa_ScanNPC")
                net.WriteString(scanPromptNPC)
            net.SendToServer()
            
            -- Воспроизводим звук и показываем SCANNING
            surface.PlaySound("netricsa/button_ssm_press.wav")
            NetricsaData.showScan = true
            timer.Simple(2, function() 
                NetricsaData.showScan = false 
            end)
        end
    end)
end