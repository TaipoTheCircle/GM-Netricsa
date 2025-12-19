if CLIENT then
    -- 🔹 Настройка клавиши открытия
    local cvar_name = "netricsa_open_key"
    local default_letter = "N"
    CreateClientConVar(cvar_name, default_letter, true, false,
        "Клавиша открытия меню Netricsa (по умолчанию N)")

    -- 🔹 Настройка клавиши сканирования
    local scan_cvar_name = "netricsa_scan_key" 
    local default_scan_letter = "E"
    CreateClientConVar(scan_cvar_name, default_scan_letter, true, false,
        "Клавиша сканирования NPC (по умолчанию E)")

    -- 🔹 Настройка автозапуска
    local auto_open_cvar = CreateClientConVar(
        "netricsa_auto_open", "1", true, false,
        "Включать Netricsa автоматически при запуске карты (1 - вкл, 0 - выкл)"
    )

    local function StringToKey(str)
        if not str or str == "" then return KEY_N end
        str = tostring(str):upper()
        return _G["KEY_" .. str] or KEY_N
    end

    local function KeyToString(key)
        for k, v in pairs(_G) do
            if isnumber(v) and v == key and string.StartWith(k, "KEY_") then
                return string.sub(k, 5)
            end
        end
        return default_letter
    end

    -- 🔹 Отслеживание кастомной клавиши открытия
    hook.Add("Think", "Netricsa_CustomOpenKey", function()
        if vgui.CursorVisible() then return end
        local key = StringToKey(GetConVar(cvar_name):GetString())
        if input.IsKeyDown(key) then
            if not Netricsa_LastPress or CurTime() - Netricsa_LastPress > 0.5 then
                Netricsa_LastPress = CurTime()
                if OpenNetricsa then
                    OpenNetricsa()
                end
            end
        end
    end)

    -- 🔹 Добавляем вкладку Netricsa в спавн-меню
    hook.Add("AddToolMenuTabs", "Netricsa_CreateTab", function()
        spawnmenu.AddToolTab("Netricsa", "Netricsa", "icon16/book_open.png")
    end)

    -- 🔹 Добавляем панель настроек
    hook.Add("PopulateToolMenu", "Netricsa_AddSettingsPanel", function()
        spawnmenu.AddToolMenuOption(
            "Netricsa", "Settings", "NetricsaConfig", L("ui", "settings_tab"), "", "", function(panel)
                panel:ClearControls()
                panel:Help(L("ui", "settings_help"))

                -- Настройка клавиши открытия
                panel:Help(L("ui", "settings_key_help"))
                local binder = vgui.Create("DBinder")
                binder:SetSize(200, 30)
                local curValue = GetConVar(cvar_name):GetString()
                if not curValue or curValue == "" or curValue == "0" or curValue == "NONE" then
                    RunConsoleCommand(cvar_name, default_letter)
                    curValue = default_letter
                end
                binder:SetValue(StringToKey(curValue))
                binder.OnChange = function(_, num)
                    if num and num > 0 then
                        local str = KeyToString(num)
                        RunConsoleCommand(cvar_name, str)
                        surface.PlaySound("")
                    end
                end
                panel:AddItem(binder)
                panel:Help(L("ui", "settings_current") .. GetConVar(cvar_name):GetString())
                panel:ControlHelp(L("ui", "settings_default"))

                -- 🔹 НАСТРОЙКА КЛАВИШИ СКАНИРОВАНИЯ (С ПЕРЕВОДОМ)
                panel:Help(L("ui", "scan_key_help"))
                local scanBinder = vgui.Create("DBinder")
                scanBinder:SetSize(200, 30)
                local scanCurValue = GetConVar(scan_cvar_name):GetString()
                if not scanCurValue or scanCurValue == "" or scanCurValue == "0" or scanCurValue == "NONE" then
                    RunConsoleCommand(scan_cvar_name, default_scan_letter)
                    scanCurValue = default_scan_letter
                end
                scanBinder:SetValue(StringToKey(scanCurValue))
                scanBinder.OnChange = function(_, num)
                    if num and num > 0 then
                        local str = KeyToString(num)
                        RunConsoleCommand(scan_cvar_name, str)
                        surface.PlaySound("")
                    end
                end
                panel:AddItem(scanBinder)
                panel:Help(L("ui", "scan_current") .. GetConVar(scan_cvar_name):GetString())
                panel:ControlHelp(L("ui", "scan_default"))

                -- 🔹 Чекбокс для автозапуска
                panel:Help(L("ui", "settings_auto_open"))
                panel:CheckBox(L("ui", "settings_auto_open"), "netricsa_auto_open")

            end
        )
    end)
end