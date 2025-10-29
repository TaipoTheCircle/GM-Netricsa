if CLIENT then
    -- переменные статистики
    stats_kills = 0
    stats_totalEnemies = 0 -- здесь мы храним "живых сейчас", как шлёт сервер
    stats_startTime = 0

    net.Receive("Netricsa_UpdateStats", function()
        stats_kills        = net.ReadInt(16)
        stats_totalEnemies = net.ReadInt(16)
        stats_startTime    = net.ReadFloat()
    end)

    local ENEMIES = {}
    local WEAPONS = {}
    local SAVED_MAPS = {}
    local READ_STATUS = { maps = {}, enemies = {}, weapons = {} }
    local showScan = false

    local CONTINUE_FILE = "netricsa_continue_campaign.flag"

    local PROGRESS_FILE = "netricsa_progress.json"

    local continueCampaign = false --  Флаг для перехода по триггеру
    
    -- ConVar'ы для отслеживания сессии игры
    local SESSION_MAP_CONVAR = "netricsa_session_map"
    local SESSION_TIME_CONVAR = "netricsa_session_time"
    CreateClientConVar(SESSION_MAP_CONVAR, "", FCVAR_ARCHIVE, "Current map in game session")
    CreateClientConVar(SESSION_TIME_CONVAR, "0", FCVAR_ARCHIVE, "Last activity timestamp in game session")

    net.Receive("Netricsa_ContinueCampaign", function()
        -- пишем простой флаг, который переживёт загрузку новой карты
        file.Write(CONTINUE_FILE, tostring(os.time()))
    end)

    local function SaveProgress()
        print("[Netricsa Client] Saving progress to file: " .. PROGRESS_FILE)
        local data = {
            maps = SAVED_MAPS,
            enemies = ENEMIES,
            weapons = WEAPONS,
            read = READ_STATUS
        }
        local json = util.TableToJSON(data, true)
        if json then
            file.Write(PROGRESS_FILE, json)
            print("[Netricsa Client] Successfully saved progress: " .. table.Count(SAVED_MAPS) .. " maps, " .. table.Count(ENEMIES) .. " enemies, " .. table.Count(WEAPONS) .. " weapons")
        else
            print("[Netricsa Client] Failed to serialize progress data")
        end
    end

    local function LoadProgress()
        print("[Netricsa Client] Loading progress from file: " .. PROGRESS_FILE)
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
                else
                    print("[Netricsa Client] Failed to parse JSON data")
                end
            else
                print("[Netricsa Client] Failed to read file")
            end
        else
            print("[Netricsa Client] Progress file does not exist")
        end
    end

    hook.Add("InitPostEntity", "Netricsa_AddCurrentMap", function()
        local currentMap = game.GetMap()

        -- Автоматически добавляем текущую карту при загрузке
        if not SAVED_MAPS[currentMap] then
            SAVED_MAPS[currentMap] = true
            SaveProgress()
            print("[Netricsa Client] Added current map to progress: " .. currentMap)
        end
    end)

    -- Обновляем время активности при выгрузке карты
    hook.Add("ShutDown", "Netricsa_SessionUpdate", function()
        local currentTime = os.time()
        RunConsoleCommand(SESSION_TIME_CONVAR, tostring(currentTime))
        print("[Netricsa Client] Updated session time on shutdown: " .. currentTime)
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
            
        -- Логика загрузки прогресса на основе сессии
        local currentTime = os.time()
        local sessionMap = GetConVar(SESSION_MAP_CONVAR):GetString()
        local sessionTime = GetConVar(SESSION_TIME_CONVAR):GetInt()

        print("[Netricsa OnStart] Session check - Current map: " .. currentMap .. ", Session map: " .. sessionMap)
        print("[Netricsa OnStart] Session check - Current time: " .. currentTime .. ", Session time: " .. sessionTime)

        -- Сохраняем текущую карту и время в ConVar
        RunConsoleCommand(SESSION_MAP_CONVAR, currentMap)
        RunConsoleCommand(SESSION_TIME_CONVAR, tostring(currentTime))

        if sessionMap == currentMap then
            -- Та же карта - сбрасываем прогресс
            print("[Netricsa OnStart] Same map detected, resetting progress")
            if file.Exists(PROGRESS_FILE, "DATA") then
                file.Delete(PROGRESS_FILE)
                print("[Netricsa OnStart] Deleted progress file (same map)")
            end
        elseif sessionTime > 0 and (currentTime - sessionTime) >= 300 then  -- 5 минут = 300 секунд
            -- Прошло больше 5 минут - сбрасываем прогресс
            print("[Netricsa OnStart] Time difference >= 5 minutes, resetting progress")
            if file.Exists(PROGRESS_FILE, "DATA") then
                file.Delete(PROGRESS_FILE)
                print("[Netricsa OnStart] Deleted progress file (time expired)")
            end
        else
            -- Продолжаем сессию - загружаем прогресс
            print("[Netricsa OnStart] Continuing session, loading progress")
            LoadProgress()
        end
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
        OpenFirstUnread = OpenFirstUnread
    }
end