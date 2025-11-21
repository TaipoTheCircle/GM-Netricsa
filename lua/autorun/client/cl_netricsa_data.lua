if CLIENT then
    -- переменные статистики
    stats_kills = 0
    stats_totalEnemies = 0
    stats_startTime = 0
    stats_maxEnemies = 0
    stats_secrets = 0
    stats_secrets_total = 0

net.Receive("Netricsa_UpdateStats", function()
    local kills = net.ReadUInt(16) or 0
    local total = net.ReadUInt(16) or 0
    local startTime = net.ReadFloat() or CurTime()
    
    print("[Netricsa Client] Raw network data - kills: " .. kills .. ", total: " .. total)
    
    -- Обновляем переменные
    stats_kills = kills
    stats_totalEnemies = total
    stats_startTime = startTime
    
    -- 🔹 ОБНОВЛЯЕМ МАКСИМАЛЬНОЕ КОЛИЧЕСТВО ВРАГОВ
    stats_maxEnemies = math.max(stats_maxEnemies or 0, stats_totalEnemies)
    
    print("[Netricsa Client] Processed stats: " .. stats_kills .. "/" .. stats_totalEnemies .. " (max: " .. stats_maxEnemies .. ")")
    
    -- 🔹 ОБНОВЛЯЕМ СТАТИСТИКУ ЕСЛИ ОНА ОТКРЫТА
    if IsValid(NetricsaFrame) and NetricsaFrame:IsVisible() then
        local currentTab = _G.NetricsaCurrentTab or ""
        if currentTab == L("tabs","statistics") then
            print("[Netricsa] Refreshing statistics tab with new data")
            -- Просто переключаем на ту же вкладку для обновления
            NetricsaTabs.SwitchTab(currentTab)
        end
    end
end)

    local ENEMIES = {}
    local WEAPONS = {}
    local SAVED_MAPS = {}
    local READ_STATUS = { maps = {}, enemies = {}, weapons = {} }
    local showScan = false
    local is_loading_process = true

    local CONTINUE_FILE = "netricsa_continue_campaign.flag"
    local PROGRESS_FILE = "netricsa_progress.json"
    local BACKUP_FILE = "netricsa_progress_backup.json" -- 🔹 Бэкап файл

    local continueCampaign = false --  Флаг для перехода по триггеру
    
    -- ConVar'ы для отслеживания кампании
    local CAMPAIGN_MAP_CONVAR = "netricsa_campaign_map"
    local CAMPAIGN_TIME_CONVAR = "netricsa_campaign_time"
    local CAMPAIGN_ACTIVE_CONVAR = "netricsa_campaign_active"
    
    CreateClientConVar(CAMPAIGN_MAP_CONVAR, "", FCVAR_ARCHIVE, "Current map in campaign")
    CreateClientConVar(CAMPAIGN_TIME_CONVAR, "0", FCVAR_ARCHIVE, "Last activity timestamp in campaign")
    CreateClientConVar(CAMPAIGN_ACTIVE_CONVAR, "0", FCVAR_ARCHIVE, "Is campaign active")

    net.Receive("Netricsa_ContinueCampaign", function()
        -- пишем простой флаг, который переживёт загрузку новой карты
        file.Write(CONTINUE_FILE, tostring(os.time()))
    end)

    local function SaveProgress()
        if is_loading_process == true then
            return
        end

        print("[Netricsa Client] Saving progress to file: " .. PROGRESS_FILE)
        local data = {
            maps = SAVED_MAPS,
            enemies = ENEMIES,
            weapons = WEAPONS,
            read = READ_STATUS,
            version = "2.01" -- 🔹 Добавляем версию для совместимости
        }
        local json = util.TableToJSON(data, true)
        if json then
            file.Write(PROGRESS_FILE, json)
            
            -- 🔹 Создаем бэкап
            file.Write(BACKUP_FILE, json)
            
            print("[Netricsa Client] Successfully saved progress: " .. table.Count(SAVED_MAPS) .. " maps, " .. table.Count(ENEMIES) .. " enemies, " .. table.Count(WEAPONS) .. " weapons")
        else
            print("[Netricsa Client] Failed to serialize progress data")
        end
        -- Принудительно обновляем глобальные переменные после сохранения
        NetricsaData.SAVED_MAPS = SAVED_MAPS
        NetricsaData.ENEMIES = ENEMIES
        NetricsaData.WEAPONS = WEAPONS
        NetricsaData.READ_STATUS = READ_STATUS
    end

    local function LoadProgress()
        print("[Netricsa Client] Loading progress from file: " .. PROGRESS_FILE)
        
        -- 🔹 Пытаемся загрузить основной файл
        if file.Exists(PROGRESS_FILE, "DATA") then
            local raw = file.Read(PROGRESS_FILE, "DATA")
            if raw then
                local data = util.JSONToTable(raw)
                if data then
                    SAVED_MAPS = data.maps or {}
                    ENEMIES = data.enemies or {}
                    WEAPONS = data.weapons or {}
                    READ_STATUS = data.read or { maps = {}, enemies = {}, weapons = {} }
                    print("[Netricsa Client] Successfully loaded progress: " .. table.Count(SAVED_MAPS) .. " maps, " .. table.Count(ENEMIES) .. " enemies, " .. table.Count(WEAPONS) .. " weapons")
                    
                    NetricsaData.SAVED_MAPS = SAVED_MAPS
                    NetricsaData.ENEMIES = ENEMIES
                    NetricsaData.WEAPONS = WEAPONS
                    NetricsaData.READ_STATUS = READ_STATUS
                    return true
                else
                    print("[Netricsa Client] Failed to parse JSON data from main file")
                end
            else
                print("[Netricsa Client] Failed to read main file")
            end
        end
        
        -- 🔹 Если основной файл не загрузился, пробуем бэкап
        print("[Netricsa Client] Trying to load backup file: " .. BACKUP_FILE)
        if file.Exists(BACKUP_FILE, "DATA") then
            local raw = file.Read(BACKUP_FILE, "DATA")
            if raw then
                local data = util.JSONToTable(raw)
                if data then
                    SAVED_MAPS = data.maps or {}
                    ENEMIES = data.enemies or {}
                    WEAPONS = data.weapons or {}
                    READ_STATUS = data.read or { maps = {}, enemies = {}, weapons = {} }
                    print("[Netricsa Client] Successfully loaded progress from BACKUP: " .. table.Count(SAVED_MAPS) .. " maps, " .. table.Count(ENEMIES) .. " enemies, " .. table.Count(WEAPONS) .. " weapons")
                    
                    -- 🔹 Восстанавливаем основной файл из бэкапа
                    SaveProgress()
                    
                    NetricsaData.SAVED_MAPS = SAVED_MAPS
                    NetricsaData.ENEMIES = ENEMIES
                    NetricsaData.WEAPONS = WEAPONS
                    NetricsaData.READ_STATUS = READ_STATUS
                    return true
                else
                    print("[Netricsa Client] Failed to parse JSON data from backup file")
                end
            else
                print("[Netricsa Client] Failed to read backup file")
            end
        else
            print("[Netricsa Client] Progress file does not exist")
        end
        
        return false
    end

    local function ResetCampaign()
        print("[Netricsa] Resetting campaign progress")
        if file.Exists(PROGRESS_FILE, "DATA") then
            file.Delete(PROGRESS_FILE)
        end
        
        ENEMIES = {}
        WEAPONS = {}
        SAVED_MAPS = {}
        READ_STATUS = { maps = {}, enemies = {}, weapons = {} }
        
        -- Добавляем текущую карту
        local currentMap = game.GetMap()
        SAVED_MAPS[currentMap] = true
        
        RunConsoleCommand(CAMPAIGN_ACTIVE_CONVAR, "0")
        RunConsoleCommand(CAMPAIGN_MAP_CONVAR, "")
        RunConsoleCommand(CAMPAIGN_TIME_CONVAR, "0")
        
        print("[Netricsa] Campaign reset complete")
    end

    -- 🔹 Функция для проверки целостности данных
    local function ValidateData()
        -- Проверяем, что все основные таблицы существуют
        if not SAVED_MAPS then SAVED_MAPS = {} end
        if not ENEMIES then ENEMIES = {} end
        if not WEAPONS then WEAPONS = {} end
        if not READ_STATUS then READ_STATUS = { maps = {}, enemies = {}, weapons = {} } end
        
        -- Проверяем подтаблицы READ_STATUS
        if not READ_STATUS.maps then READ_STATUS.maps = {} end
        if not READ_STATUS.enemies then READ_STATUS.enemies = {} end
        if not READ_STATUS.weapons then READ_STATUS.weapons = {} end
        
        -- Убеждаемся, что текущая карта есть в списке
        local currentMap = game.GetMap()
        if not SAVED_MAPS[currentMap] then
            SAVED_MAPS[currentMap] = true
        end
        
        return true
    end

    hook.Add("InitPostEntity", "Netricsa_AddCurrentMap", function()
        -- Сначала загружаем прогресс на основе кампании
        NetricsaData.OnStart()

        -- Затем добавляем текущую карту, если её нет в загруженном прогрессе
        local currentMap = game.GetMap()
        if not SAVED_MAPS[currentMap] then
            SAVED_MAPS[currentMap] = true
            SaveProgress()
            print("[Netricsa Client] Added current map to progress: " .. currentMap)
        end
    end)

    -- Обновляем время активности при выгрузке карты
    hook.Add("ShutDown", "Netricsa_CampaignUpdate", function()
        local currentTime = os.time()
        RunConsoleCommand(CAMPAIGN_TIME_CONVAR, tostring(currentTime))
        SaveProgress() -- 🔹 Сохраняем прогресс при выходе
        print("[Netricsa Client] Updated campaign time on shutdown: " .. currentTime)
    end)

    -- 🔹 Хук для защиты от сброса при ошибках
    hook.Add("OnReloaded", "Netricsa_ReloadProtection", function()
        print("[Netricsa] Addon reloaded, preserving data...")
        -- Данные уже в памяти, они сохранятся
    end)

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

    local function GetUnreadCount(tab)
        local key = NetricsaUtils.TabKeyFromName(tab)
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
        local key = NetricsaUtils.TabKeyFromName(tab)
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

    local function OnStart()
        local currentMap = game.GetMap()
        local currentTime = os.time()
        
        -- 🔹 Сначала проверяем целостность данных в памяти
        ValidateData()
        
        -- Получаем данные кампании
        local campaignMap = GetConVar(CAMPAIGN_MAP_CONVAR):GetString()
        local campaignTime = GetConVar(CAMPAIGN_TIME_CONVAR):GetInt()
        local campaignActive = GetConVar(CAMPAIGN_ACTIVE_CONVAR):GetBool()

        print("[Netricsa OnStart] Campaign check:")
        print("  Current map: " .. currentMap)
        print("  Campaign map: " .. campaignMap)
        print("  Campaign time: " .. campaignTime)
        print("  Campaign active: " .. tostring(campaignActive))
        if campaignTime > 0 then
            print("  Time difference: " .. (currentTime - campaignTime) .. " seconds")
        end

        -- Проверяем условия сброса кампании
        local shouldReset = false
        
        if not campaignActive then
            -- Кампания не активна - начинаем новую
            print("[Netricsa] Starting new campaign")
            shouldReset = true
        elseif campaignTime > 0 and (currentTime - campaignTime) >= 600 then -- 10 минут = 600 секунд
            -- Прошло больше 10 минут - сбрасываем
            print("[Netricsa] Campaign expired (10+ minutes), resetting")
            shouldReset = true
        elseif campaignMap == currentMap then
            -- Вернулись на ту же карту - продолжаем кампанию
            print("[Netricsa] Continuing campaign on same map")
            LoadProgress()
        else
            -- Перешли на новую карту - продолжаем кампанию
            print("[Netricsa] Continuing campaign on new map: " .. currentMap)
            LoadProgress()
            
            -- Добавляем новую карту в прогресс
            if not SAVED_MAPS[currentMap] then
                SAVED_MAPS[currentMap] = true
                SaveProgress()
                print("[Netricsa] Added new map to campaign: " .. currentMap)
            end
        end

        -- Сбрасываем кампанию если нужно
        if shouldReset then
            ResetCampaign()
        else
            -- 🔹 Всегда проверяем целостность после загрузки
            ValidateData()
        end
        
        -- Обновляем данные кампании
        RunConsoleCommand(CAMPAIGN_MAP_CONVAR, currentMap)
        RunConsoleCommand(CAMPAIGN_TIME_CONVAR, tostring(currentTime))
        RunConsoleCommand(CAMPAIGN_ACTIVE_CONVAR, "1")

        -- Добавляем текущую карту если её нет
        if not SAVED_MAPS[currentMap] then
            SAVED_MAPS[currentMap] = true
            SaveProgress()
            print("[Netricsa] Added current map to progress: " .. currentMap)
        end

-- 🔹 ИНИЦИАЛИЗАЦИЯ СТАТИСТИКИ ПРИ СТАРТЕ
timer.Simple(5, function()  -- Увеличьте с 3 до 5 секунд
    print("[Netricsa] Initializing statistics...")
    if stats_totalEnemies == 0 then
        print("[Netricsa] Requesting initial stats from server")
        RunConsoleCommand("netricsa_check")
    end
end)

        is_loading_process = false
    end

    -- Expose data and functions
    NetricsaData = {
        ENEMIES = ENEMIES,
        WEAPONS = WEAPONS,
        SAVED_MAPS = SAVED_MAPS,
        READ_STATUS = READ_STATUS,
        showScan = showScan,
        continueCampaign = continueCampaign,
        OnStart = OnStart,
        SaveProgress = SaveProgress,
        LoadProgress = LoadProgress,
        LoadDescription = LoadDescription,
        GetEnemyDisplayName = GetEnemyDisplayName,
        GetUnreadCount = GetUnreadCount,
        OpenFirstUnread = OpenFirstUnread,
        ValidateData = ValidateData -- 🔹 Экспортируем для отладки
    }
    
    -- 🔹 Автоматическое сохранение каждые 2 минуты для защиты от сбоев
    timer.Create("Netricsa_AutoSave", 120, 0, function()
        if not is_loading_process and (table.Count(ENEMIES) > 0 or table.Count(WEAPONS) > 0) then
            SaveProgress()
            print("[Netricsa] Auto-save completed")
        end
    end)

    -- Команда для проверки клиентской статистики
    concommand.Add("netricsa_client_stats", function()
        print("=== NETRICSA CLIENT STATS ===")
        print("Kills: " .. (stats_kills or 0))
        print("Total Enemies (current): " .. (stats_totalEnemies or 0))
        print("Max Enemies: " .. (stats_maxEnemies or 0))
        print("Start Time: " .. (stats_startTime or 0))
        print("Current Time: " .. CurTime())
        if stats_startTime and stats_startTime > 0 then
            print("Game Time: " .. string.ToMinutesSeconds(CurTime() - stats_startTime))
        else
            print("Game Time: N/A")
        end
        print("==============================")
    end)
end