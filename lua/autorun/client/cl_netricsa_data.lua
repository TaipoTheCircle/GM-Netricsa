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

    net.Receive("Netricsa_ContinueCampaign", function()
        -- пишем простой флаг, который переживёт загрузку новой карты
        file.Write(CONTINUE_FILE, tostring(os.time()))
    end)

    local function SaveProgress()
        local data = {
            maps = SAVED_MAPS,
            enemies = ENEMIES,
            weapons = WEAPONS,
            read = READ_STATUS
        }
        file.Write(PROGRESS_FILE, util.TableToJSON(data, true))
    end

    local function LoadProgress()
        if file.Exists(PROGRESS_FILE, "DATA") then
            local raw = file.Read(PROGRESS_FILE, "DATA")
            local data = util.JSONToTable(raw)
            if data then
                SAVED_MAPS = data.maps or {}
                ENEMIES = data.enemies or {}
                WEAPONS = data.weapons or {}
                READ_STATUS = data.read or { maps = {}, enemies = {}, weapons = {} }
            end
        end
    end

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

    -- Expose data and functions
    NetricsaData = {
        ENEMIES = ENEMIES,
        WEAPONS = WEAPONS,
        SAVED_MAPS = SAVED_MAPS,
        READ_STATUS = READ_STATUS,
        showScan = showScan,
        continueCampaign = continueCampaign,
        SaveProgress = SaveProgress,
        LoadProgress = LoadProgress,
        LoadDescription = LoadDescription,
        GetEnemyDisplayName = GetEnemyDisplayName,
        GetUnreadCount = GetUnreadCount,
        OpenFirstUnread = OpenFirstUnread
    }
end