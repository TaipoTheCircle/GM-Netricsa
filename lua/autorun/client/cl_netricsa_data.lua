if CLIENT then
    -- Глобальные переменные для путей файлов
    NetricsaData = NetricsaData or {}
    
    -- пути файлов
    NetricsaData.PROGRESS_FILE = "netricsa_progress.json"
    NetricsaData.BACKUP_FILE = "netricsa_progress_backup.json"
    NetricsaData.CONTINUE_FILE = "netricsa_continue_campaign.flag"
    NetricsaData.EXIT_TIME_FILE = "netricsa_exit_time.txt"

    -- переменные статистики
    stats_kills = 0
    stats_totalEnemies = 0
    stats_startTime = 0
    stats_maxEnemies = 0
    stats_secrets = 0
    stats_secrets_total = 0
    stats_total_score = 0

        -- Инициализация таблиц данных
    local ENEMIES = {}
    local WEAPONS = {}
    local SAVED_MAPS = {}
    local READ_STATUS = { maps = {}, enemies = {}, weapons = {} }
    local showScan = false
    local is_loading_process = true
    local continueCampaign = false

-- Функция для получения очков за убийство NPC из 11-й строки
local function GetScoreForNPC(npcClass)
    local lang = CurrentLang or "en"
    -- Исправленный путь: netricsa/descriptions/ (без lua в начале)
    local path = "netricsa/descriptions/" .. lang .. "/" .. npcClass .. ".lua"
    
    print("[Netricsa DEBUG] Looking for score in: " .. path)
    
    if file.Exists(path, "GAME") then
        local content = file.Read(path, "GAME")
        if content then
            -- Разделяем на строки
            local lines = string.Explode("\n", content)
            
            print("[Netricsa DEBUG] Total lines in file: " .. #lines)
            
            -- Покажем первые 15 строк для отладки
            for i = 1, math.min(15, #lines) do
                print("[Netricsa DEBUG] Line " .. i .. ": '" .. lines[i] .. "'")
            end
            
            -- Ищем 11-ю строку (индекс 11)
            if #lines >= 11 then
                local line11 = lines[11]
                print("[Netricsa DEBUG] Line 11 for " .. npcClass .. ": '" .. line11 .. "'")
                
                -- Ищем число в строке
                local score = string.match(line11, "(%d+)")
                
                if score then
                    local numScore = tonumber(score)
                    print("[Netricsa DEBUG] Found number in line 11: " .. numScore)
                    if numScore and numScore > 0 then
                        print("[Netricsa] Found score for " .. npcClass .. ": " .. numScore)
                        return numScore
                    end
                else
                    print("[Netricsa DEBUG] No number found in line 11")
                end
            else
                print("[Netricsa DEBUG] File has less than 11 lines")
            end
        else
            print("[Netricsa DEBUG] Could not read file content")
        end
    else
        print("[Netricsa DEBUG] File does not exist: " .. path)
        -- Попробуем альтернативный путь
        local altPath = "lua/netricsa/descriptions/" .. lang .. "/" .. npcClass .. ".lua"
        print("[Netricsa DEBUG] Trying alternative path: " .. altPath)
        
        if file.Exists(altPath, "GAME") then
            local content = file.Read(altPath, "GAME")
            if content then
                local lines = string.Explode("\n", content)
                if #lines >= 11 then
                    local line11 = lines[11]
                    print("[Netricsa DEBUG] Found in alt path, line 11: '" .. line11 .. "'")
                    local score = string.match(line11, "(%d+)")
                    if score then
                        return tonumber(score)
                    end
                end
            end
        end
    end
    
    -- Если не нашли - значение по умолчанию
    print("[Netricsa] Using default score (100) for " .. npcClass)
    return 100
end
    
    -- Обновляем сетевой обработчик для добавления очков
    net.Receive("Netricsa_AddEnemy", function()
        local npcClass = net.ReadString()
        local mdl = net.ReadString()
        local skin = net.ReadUInt(8)
        local bgCount = net.ReadUInt(8)
        local bodygroups = {}
        for i=1,bgCount do bodygroups[i] = net.ReadUInt(8) end

        print("[Netricsa Client] Received AddEnemy: " .. npcClass)
        local isNew = not NetricsaData.ENEMIES[npcClass]
        
        -- Получаем очки для этого NPC
        local npcScore = GetScoreForNPC(npcClass)
        
        NetricsaData.ENEMIES[npcClass] = { 
            mdl = mdl, 
            skin = skin, 
            bodygroups = bodygroups,
            score = npcScore -- Сохраняем очки
        }
        
        print("[Netricsa] NPC " .. npcClass .. " score: " .. npcScore)
        
        NetricsaData.SaveProgress()

        if isNew then
            print("[Netricsa Client] New enemy discovered: " .. npcClass)
            NetricsaData.showScan = true
            timer.Simple(2, function() NetricsaData.showScan = false end)
            surface.PlaySound("netricsa/Info.wav")
        end
    end)

    local function SaveProgress()
        if is_loading_process == true then
            return
        end

        -- Убедимся, что переменные инициализированы
        SAVED_MAPS = SAVED_MAPS or {}
        ENEMIES = ENEMIES or {}
        WEAPONS = WEAPONS or {}
        READ_STATUS = READ_STATUS or { maps = {}, enemies = {}, weapons = {} }

        print("[Netricsa Client] Saving progress to file: " .. NetricsaData.PROGRESS_FILE)
        local data = {
            maps = SAVED_MAPS,
            enemies = ENEMIES,
            weapons = WEAPONS,
            read = READ_STATUS,
            total_score = stats_total_score or 0,
            version = "2.01"
        }
        local json = util.TableToJSON(data, true)
        if json then
            file.Write(NetricsaData.PROGRESS_FILE, json)
            file.Write(NetricsaData.BACKUP_FILE, json)

            print("[Netricsa Client] Successfully saved progress: " ..
            table.Count(SAVED_MAPS) ..
            " maps, " .. table.Count(ENEMIES) .. " enemies, " .. 
            table.Count(WEAPONS) .. " weapons, Score: " .. (stats_total_score or 0))
        else
            print("[Netricsa Client] Failed to serialize progress data")
        end
        NetricsaData.SAVED_MAPS = SAVED_MAPS
        NetricsaData.ENEMIES = ENEMIES
        NetricsaData.WEAPONS = WEAPONS
        NetricsaData.READ_STATUS = READ_STATUS
    end
    
    -- Функция для добавления очков
local function AddScore(points)
    if not points or points <= 0 then return end
    stats_total_score = (stats_total_score or 0) + points
    
    -- Просто вызывайте SaveProgress напрямую (она в той же области видимости)
    SaveProgress()
    
    print("[Netricsa] Added " .. points .. " points. Total: " .. stats_total_score)
end
    
    
    net.Receive("Netricsa_UpdateScore", function()
        local points = net.ReadUInt(16) or 0
        AddScore(points)
    end)

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

        print("[Netricsa Client] Processed stats: " ..
        stats_kills .. "/" .. stats_totalEnemies .. " (max: " .. stats_maxEnemies .. ")")

        -- 🔹 ОБНОВЛЯЕМ СТАТИСТИКУ ЕСЛИ ОНА ОТКРЫТА
        if IsValid(NetricsaFrame) and NetricsaFrame:IsVisible() then
            local currentTab = _G.NetricsaCurrentTab or ""
            if currentTab == L("tabs", "statistics") then
                print("[Netricsa] Refreshing statistics tab with new data")
                -- Просто переключаем на ту же вкладку для обновления
                NetricsaTabs.SwitchTab(currentTab)
            end
        end
    end)


    -- ConVar'ы для отслеживания кампании
    local CAMPAIGN_MAP_CONVAR = "netricsa_campaign_map"
    local CAMPAIGN_TIME_CONVAR = "netricsa_campaign_time"
    local CAMPAIGN_ACTIVE_CONVAR = "netricsa_campaign_active"

    CreateClientConVar(CAMPAIGN_MAP_CONVAR, "", FCVAR_ARCHIVE, "Current map in campaign")
    CreateClientConVar(CAMPAIGN_TIME_CONVAR, "0", FCVAR_ARCHIVE, "Last activity timestamp in campaign")
    CreateClientConVar(CAMPAIGN_ACTIVE_CONVAR, "0", FCVAR_ARCHIVE, "Is campaign active")

    net.Receive("Netricsa_ContinueCampaign", function()
        file.Write(NetricsaData.CONTINUE_FILE, tostring(os.time()))
    end)

    -- 🔹 Функция сохранения времени выхода
    local function SaveExitTime()
        local exitTime = os.time()
        file.Write(NetricsaData.EXIT_TIME_FILE, tostring(exitTime))
        print("[Netricsa] Saved exit time: " .. exitTime)
    end

    -- 🔹 Функция загрузки времени выхода
    local function LoadExitTime()
        if file.Exists(NetricsaData.EXIT_TIME_FILE, "DATA") then
            local raw = file.Read(NetricsaData.EXIT_TIME_FILE, "DATA")
            if raw then
                return tonumber(raw) or 0
            end
        end
        return 0
    end

    -- 🔹 Функция проверки таймаута между сессиями
    local function CheckSessionTimeout()
        local exitTime = LoadExitTime()
        local currentTime = os.time()

        if exitTime > 0 then
            local timeDiff = currentTime - exitTime
            print("[Netricsa] Session check - Exit time: " ..
            exitTime .. ", Current: " .. currentTime .. ", Difference: " .. timeDiff .. "s")

            -- Если прошло больше 10 минут (600 секунд) - сбрасываем кампанию
            if timeDiff > 600 then
                print("[Netricsa] Session timeout detected (" .. timeDiff .. "s), resetting campaign")
                return true
            else
                print("[Netricsa] Continuing existing campaign (timeout: " .. timeDiff .. "s)")
                return false
            end
        end

        -- Если времени выхода нет - новая кампания
        print("[Netricsa] No previous session found, starting new campaign")
        return true
    end

    local function LoadProgress()
        print("[Netricsa Client] Loading progress from file: " .. NetricsaData.PROGRESS_FILE)

        if file.Exists(NetricsaData.PROGRESS_FILE, "DATA") then
            local raw = file.Read(NetricsaData.PROGRESS_FILE, "DATA")
            if raw then
                local data = util.JSONToTable(raw)
                if data then
                    SAVED_MAPS = data.maps or {}
                    ENEMIES = data.enemies or {}
                    WEAPONS = data.weapons or {}
                    READ_STATUS = data.read or { maps = {}, enemies = {}, weapons = {} }
                    stats_total_score = data.total_score or 0 -- НОВОЕ: загружаем очки

                    READ_STATUS.maps = READ_STATUS.maps or {}
                    READ_STATUS.enemies = READ_STATUS.enemies or {}
                    READ_STATUS.weapons = READ_STATUS.weapons or {}

                    print("[Netricsa Client] Successfully loaded progress: " ..
                        table.Count(SAVED_MAPS) .. " maps, " ..
                        table.Count(ENEMIES) .. " enemies, " ..
                        table.Count(WEAPONS) .. " weapons, Score: " .. stats_total_score)

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
        else
            print("[Netricsa Client] Progress file does not exist")
        end

        return false
    end

    local function GetNPCScore(npcClass)
        if ENEMIES[npcClass] and ENEMIES[npcClass].score then
            return ENEMIES[npcClass].score
        end
        return GetScoreForNPC(npcClass) or 100
    end

    local function ResetCampaign()
        print("[Netricsa] Resetting campaign progress")

        if file.Exists(NetricsaData.PROGRESS_FILE, "DATA") then
            local backupName = "netricsa_progress_backup_" .. os.time() .. ".json"
            local content = file.Read(NetricsaData.PROGRESS_FILE, "DATA")
            if content then
                file.Write(backupName, content)
            end
            print("[Netricsa] Created backup: " .. backupName)
        end

        ENEMIES = {}
        WEAPONS = {}
        SAVED_MAPS = {}
        READ_STATUS = { maps = {}, enemies = {}, weapons = {} }

        local currentMap = game.GetMap()
        SAVED_MAPS[currentMap] = true

        SaveProgress()

        RunConsoleCommand(CAMPAIGN_ACTIVE_CONVAR, "0")
        RunConsoleCommand(CAMPAIGN_MAP_CONVAR, "")
        RunConsoleCommand(CAMPAIGN_TIME_CONVAR, "0")

        print("[Netricsa] Campaign reset complete")
    end

    local function ValidateData()
        if not SAVED_MAPS then SAVED_MAPS = {} end
        if not ENEMIES then ENEMIES = {} end
        if not WEAPONS then WEAPONS = {} end
        if not READ_STATUS then READ_STATUS = { maps = {}, enemies = {}, weapons = {} } end

        if not READ_STATUS.maps then READ_STATUS.maps = {} end
        if not READ_STATUS.enemies then READ_STATUS.enemies = {} end
        if not READ_STATUS.weapons then READ_STATUS.weapons = {} end

        local currentMap = game.GetMap()
        if not SAVED_MAPS[currentMap] then
            SAVED_MAPS[currentMap] = true
        end

        return true
    end

    -- 🔹 Сохраняем время выхода при закрытии игры
    hook.Add("ShutDown", "Netricsa_SaveExitTime", function()
        SaveExitTime()
        local currentTime = os.time()
        RunConsoleCommand(CAMPAIGN_TIME_CONVAR, tostring(currentTime))
        SaveProgress()
        print("[Netricsa Client] Saved exit time and updated campaign time: " .. currentTime)
    end)

    -- 🔹 Также сохраняем при выходе с карты (на всякий случай)
    hook.Add("OnReloaded", "Netricsa_SaveExitTimeOnReload", function()
        SaveExitTime()
    end)

    hook.Add("InitPostEntity", "Netricsa_AddCurrentMap", function()
        NetricsaData.OnStart()
        local currentMap = game.GetMap()
        if not SAVED_MAPS[currentMap] then
            SAVED_MAPS[currentMap] = true
            SaveProgress()
            print("[Netricsa Client] Added current map to progress: " .. currentMap)
        end
    end)

    hook.Add("OnReloaded", "Netricsa_ReloadProtection", function()
        print("[Netricsa] Addon reloaded, preserving data...")
    end)

local function LoadDescription(name)
    local lang = CurrentLang or "en"
    -- Исправленный путь
    local path = "netricsa/descriptions/" .. lang .. "/" .. name .. ".lua"
    if file.Exists(path, "GAME") then
        return file.Read(path, "GAME")
    end
    -- Попробуем старый путь на всякий случай
    local altPath = "lua/netricsa/descriptions/" .. lang .. "/" .. name .. ".lua"
    if file.Exists(altPath, "GAME") then
        return file.Read(altPath, "GAME")
    end
    return L("ui", "no_data")
end

local function GetEnemyDisplayName(npcClass)
    local lang = CurrentLang or "en"
    -- Исправленный путь
    local path = "netricsa/descriptions/" .. lang .. "/" .. npcClass .. ".lua"
    if file.Exists(path, "GAME") then
        local content = file.Read(path, "GAME")
        if content and content ~= "" then
            local firstLine = string.match(content, "([^\n\r]+)")
            if firstLine and firstLine ~= "" then
                return firstLine
            end
        end
    end
    -- Попробуем старый путь
    local altPath = "lua/netricsa/descriptions/" .. lang .. "/" .. npcClass .. ".lua"
    if file.Exists(altPath, "GAME") then
        local content = file.Read(altPath, "GAME")
        if content and content ~= "" then
            local firstLine = string.match(content, "([^\n\r]+)")
            if firstLine and firstLine ~= "" then
                return firstLine
            end
        end
    end
    return npcClass
end

concommand.Add("netricsa_check_file", function(ply, cmd, args)
    if not args or #args == 0 then
        print("Usage: netricsa_check_file <npc_class>")
        return
    end
    
    local npcClass = args[1]
    local lang = CurrentLang or "en"
    
    local paths = {
        "netricsa/descriptions/" .. lang .. "/" .. npcClass .. ".lua",
        "lua/netricsa/descriptions/" .. lang .. "/" .. npcClass .. ".lua"
    }
    
    print("=== Checking file for NPC: " .. npcClass .. " ===")
    
    for _, path in ipairs(paths) do
        print("Checking path: " .. path)
        if file.Exists(path, "GAME") then
            print("✓ File exists!")
            local content = file.Read(path, "GAME")
            if content then
                local lines = string.Explode("\n", content)
                print("Total lines: " .. #lines)
                
                if #lines >= 11 then
                    print("Line 11: '" .. lines[11] .. "'")
                    local score = string.match(lines[11], "(%d+)")
                    if score then
                        print("Found score: " .. score)
                    else
                        print("No number found in line 11")
                    end
                else
                    print("File has less than 11 lines")
                end
            else
                print("Could not read file")
            end
            break
        else
            print("✗ File does not exist")
        end
    end
    
    -- Проверим GetScoreForNPC
    print("\nGetScoreForNPC result: " .. GetScoreForNPC(npcClass))
    
    print("=================================")
end)

    local function GetUnreadCount(tab)
        local key = NetricsaUtils.TabKeyFromName(tab)
        if not key then return 0 end

        local t = (key == "maps" and SAVED_MAPS)
            or (key == "enemies" and ENEMIES)
            or (key == "weapons" and WEAPONS)

        if not t then return 0 end

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
        if not key then
            print("[Netricsa] Invalid tab key for: " .. tostring(tab))
            return
        end

        local t = (key == "maps" and SAVED_MAPS)
            or (key == "enemies" and ENEMIES)
            or (key == "weapons" and WEAPONS)

        if not t then
            print("[Netricsa] No data table for key: " .. key)
            return
        end

        READ_STATUS = READ_STATUS or { maps = {}, enemies = {}, weapons = {} }
        READ_STATUS[key] = READ_STATUS[key] or {}

        print("[Netricsa] Looking for unread in " .. key .. ", total items: " .. table.Count(t))

        for k, _ in pairs(t) do
            if not READ_STATUS[key][k] then
                print("[Netricsa] Opening first unread: " .. k)
                opener(k)
                return
            end
        end

        print("[Netricsa] No unread items found, opening first available")

        local lastKey = nil
        for k, _ in pairs(t) do
            lastKey = k
        end

        if lastKey then
            print("[Netricsa] Opening last item: " .. lastKey)
            opener(lastKey)
        else
            print("[Netricsa] No items available to open")
        end
    end

    local function OnStart()
        local currentMap = game.GetMap()
        local currentTime = os.time()

        ValidateData()

        local campaignMap = GetConVar(CAMPAIGN_MAP_CONVAR):GetString()
        local campaignTime = GetConVar(CAMPAIGN_TIME_CONVAR):GetInt()
        local campaignActive = GetConVar(CAMPAIGN_ACTIVE_CONVAR):GetBool()

        print("[Netricsa OnStart] Campaign check:")
        print("  Current map: " .. currentMap)
        print("  Campaign map: " .. campaignMap)
        print("  Campaign time: " .. campaignTime)
        print("  Campaign active: " .. tostring(campaignActive))

        -- 🔹 ПРОВЕРЯЕМ ТАЙМАУТ МЕЖДУ СЕССИЯМИ
        local sessionTimeout = CheckSessionTimeout()

        local shouldReset = false

        -- Сбрасываем кампанию если:
        -- 1. Таймаут между сессиями больше 10 минут ИЛИ
        -- 2. Кампания не активна ИЛИ
        -- 3. Таймаут активности в игре больше 10 минут
        if sessionTimeout or not campaignActive or (campaignTime > 0 and (currentTime - campaignTime) > 600) then
            print("[Netricsa] Starting new campaign - session timeout or inactivity")
            shouldReset = true
        elseif campaignMap ~= currentMap then
            -- Перешли на новую карту - продолжаем кампанию
            print("[Netricsa] Continuing campaign on new map: " .. currentMap)
            LoadProgress()

            if not SAVED_MAPS[currentMap] then
                SAVED_MAPS[currentMap] = true
                SaveProgress()
                print("[Netricsa] Added new map to campaign: " .. currentMap)
            end
        else
            -- Вернулись на ту же карту - продолжаем кампанию
            print("[Netricsa] Continuing campaign on same map")
            LoadProgress()
        end

        if shouldReset then
            ResetCampaign()
        else
            ValidateData()
        end

        RunConsoleCommand(CAMPAIGN_MAP_CONVAR, currentMap)
        RunConsoleCommand(CAMPAIGN_TIME_CONVAR, tostring(currentTime))
        RunConsoleCommand(CAMPAIGN_ACTIVE_CONVAR, "1")

        if not SAVED_MAPS[currentMap] then
            SAVED_MAPS[currentMap] = true
            SaveProgress()
            print("[Netricsa] Added current map to progress: " .. currentMap)
        end

        timer.Simple(5, function()
            print("[Netricsa] Initializing statistics...")
            if stats_totalEnemies == 0 then
                print("[Netricsa] Requesting initial stats from server")
                RunConsoleCommand("netricsa_check")
            end
        end)

        is_loading_process = false
    end

    local function GetTotalScore()
        return stats_total_score or 0
    end

    NetricsaData.ENEMIES = ENEMIES
    NetricsaData.WEAPONS = WEAPONS
    NetricsaData.SAVED_MAPS = SAVED_MAPS
    NetricsaData.READ_STATUS = READ_STATUS
    NetricsaData.showScan = showScan
    NetricsaData.continueCampaign = continueCampaign
    NetricsaData.OnStart = OnStart
    NetricsaData.SaveProgress = SaveProgress
    NetricsaData.LoadProgress = LoadProgress
    NetricsaData.LoadDescription = LoadDescription
    NetricsaData.GetEnemyDisplayName = GetEnemyDisplayName
    NetricsaData.GetUnreadCount = GetUnreadCount
    NetricsaData.OpenFirstUnread = OpenFirstUnread
    NetricsaData.ValidateData = ValidateData
    NetricsaData.GetScoreForNPC = GetScoreForNPC
    NetricsaData.GetNPCScore = GetNPCScore
    NetricsaData.GetTotalScore = GetTotalScore
    NetricsaData.AddScore = AddScore

    timer.Create("Netricsa_AutoSave", 120, 0, function()
        if not is_loading_process and (table.Count(ENEMIES) > 0 or table.Count(WEAPONS) > 0) then
            SaveProgress()
            print("[Netricsa] Auto-save completed")
        end
    end)

    timer.Create("Netricsa_ActivityPulse", 30, 0, function()
        if not is_loading_process then
            local currentTime = os.time()
            RunConsoleCommand(CAMPAIGN_TIME_CONVAR, tostring(currentTime))
        end
    end)

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

    concommand.Add("netricsa_campaign_debug", function()
        local exitTime = LoadExitTime()
        local currentTime = os.time()
        local timeDiff = currentTime - exitTime

        print("=== NETRICSA CAMPAIGN DEBUG ===")
        print("Current Map: " .. game.GetMap())
        print("Campaign Map: " .. GetConVar(CAMPAIGN_MAP_CONVAR):GetString())
        print("Campaign Time: " .. GetConVar(CAMPAIGN_TIME_CONVAR):GetInt())
        print("Campaign Active: " .. tostring(GetConVar(CAMPAIGN_ACTIVE_CONVAR):GetBool()))
        print("Last Exit Time: " .. exitTime)
        print("Current Time: " .. currentTime)
        print("Time Since Exit: " .. timeDiff .. "s (" .. math.Round(timeDiff / 60, 1) .. "m)")
        print("Session Timeout: " .. tostring(timeDiff > 600))
        print("SAVED_MAPS: " .. table.Count(SAVED_MAPS))
        print("ENEMIES: " .. table.Count(ENEMIES))
        print("WEAPONS: " .. table.Count(WEAPONS))
        print("===============================")
    end)
end