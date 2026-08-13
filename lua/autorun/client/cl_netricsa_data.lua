if CLIENT then
    -- ============================================================
    -- 1. ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
    -- ============================================================
    NetricsaData = NetricsaData or {}
    
    NetricsaData.PROGRESS_FILE = "netricsa_progress.json"
    NetricsaData.BACKUP_FILE = "netricsa_progress_backup.json"
    NetricsaData.CONTINUE_FILE = "netricsa_continue_campaign.flag"
    NetricsaData.EXIT_TIME_FILE = "netricsa_exit_time.txt"

    stats_kills = 0
    stats_totalEnemies = 0
    stats_startTime = 0
    stats_maxEnemies = 0
    stats_secrets = 0
    stats_secrets_total = 0
    stats_total_score = 0

    -- ============================================================
    -- 2. ФУНКЦИИ РАБОТЫ С ВРЕМЕНЕМ (ДОБАВИТЬ!)
    -- ============================================================
    local function SaveExitTime()
        local exitTime = os.time()
        file.Write(NetricsaData.EXIT_TIME_FILE, tostring(exitTime))
        print("[Netricsa] Saved exit time: " .. exitTime)
    end

    local function LoadExitTime()
        if file.Exists(NetricsaData.EXIT_TIME_FILE, "DATA") then
            local raw = file.Read(NetricsaData.EXIT_TIME_FILE, "DATA")
            if raw then
                local time = tonumber(raw)
                if time then
                    print("[Netricsa] Loaded exit time: " .. time)
                    return time
                end
            end
        end
        print("[Netricsa] No exit time file found")
        return 0
    end

    -- ============================================================
    -- 3. АЛИАСЫ NPC
    -- ============================================================
    NetricsaData.NPC_ALIASES = {
        ["npc_vj_ssc_eyeman_female"] = "npc_vj_ssc_eyeman_female",
        ["npc_vj_ssc_eyeman_female_flying"] = "npc_vj_ssc_eyeman_female",
        ["npc_vj_ssc_eyeman_female_flying_and_invisible"] = "npc_vj_ssc_eyeman_female",
        ["npc_vj_ssc_eyeman_female_invisible"] = "npc_vj_ssc_eyeman_female",
        ["npc_vj_ssc_eyeman_male"] = "npc_vj_ssc_eyeman_male",
        ["npc_vj_ssc_eyeman_male_flying"] = "npc_vj_ssc_eyeman_male",
        ["npc_vj_ssc_eyeman_male_flying_and_invisible"] = "npc_vj_ssc_eyeman_male",
        ["npc_vj_ssc_eyeman_male_invisible"] = "npc_vj_ssc_eyeman_male",
        ["npc_vj_ssc_eyeman_lava"] = "npc_vj_ssc_eyeman_lava",
        ["npc_vj_ssc_eyeman_lava_flying"] = "npc_vj_ssc_eyeman_lava",
        ["npc_vj_ssc_eyeman_lava_flying_and_invisible"] = "npc_vj_ssc_eyeman_lava",
        ["npc_vj_ssc_eyeman_lava_invisible"] = "npc_vj_ssc_eyeman_lava",
        ["npc_vj_ssc_eyeman_tropic_male"] = "npc_vj_ssc_eyeman_tropic_male",
        ["npc_vj_ssc_eyeman_tropic_male_flying"] = "npc_vj_ssc_eyeman_tropic_male",
        ["npc_vj_ssc_eyeman_tropic_male_flying_and_invisible"] = "npc_vj_ssc_eyeman_tropic_male",
        ["npc_vj_ssc_eyeman_tropic_male_invisible"] = "npc_vj_ssc_eyeman_tropic_male",
        ["npc_vj_ssc_eyeman_tropic_female"] = "npc_vj_ssc_eyeman_tropic_female",
        ["npc_vj_ssc_eyeman_tropic_female_flying"] = "npc_vj_ssc_eyeman_tropic_female",
        ["npc_vj_ssc_eyeman_tropic_female_flying_and_invisible"] = "npc_vj_ssc_eyeman_tropic_female",
        ["npc_vj_ssc_eyeman_tropic_female_invisible"] = "npc_vj_ssc_eyeman_tropic_female",
        ["npc_vj_ssc_eyeman_shaman_female"] = "npc_vj_ssc_eyeman_shaman_female",
        ["npc_vj_ssc_eyeman_shaman_female_flying"] = "npc_vj_ssc_eyeman_shaman_female",
        ["npc_vj_ssc_eyeman_shaman_female_flying_and_invisible"] = "npc_vj_ssc_eyeman_shaman_female",
        ["npc_vj_ssc_eyeman_shaman_female_invisible"] = "npc_vj_ssc_eyeman_shaman_female",
        ["npc_vj_ssc_eyeman_primitive_male"] = "npc_vj_ssc_eyeman_primitive_male",
        ["npc_vj_ssc_eyeman_primitive_male_flying"] = "npc_vj_ssc_eyeman_primitive_male",
        ["npc_vj_ssc_eyeman_primitive_male_flying_and_invisible"] = "npc_vj_ssc_eyeman_primitive_male",
        ["npc_vj_ssc_eyeman_primitive_male_invisible"] = "npc_vj_ssc_eyeman_primitive_male",
        ["npc_vj_ss2_turret_machinegun"] = "npc_vj_ss2_turret_machinegun",
        ["npc_vj_ss2_turret_plasma"] = "npc_vj_ss2_turret_plasma",
        ["npc_vj_ssc_gizmo"] = "npc_vj_ssc_gizmo",
        ["npc_vj_sscr_gizmo_spawner"] = "npc_vj_ssc_gizmo",
        ["npc_vj_ssc_gizmo_spawner"] = "npc_vj_ssc_gizmo",
        ["npc_vj_ss2_lizard"] = "npc_vj_ss2_lizard",
        ["npc_vj_ss2_lizard_rider"] = "npc_vj_ss2_lizard",
    }

    NetricsaData.SPECIAL_BODYGROUP_OVERRIDES = {
        ["npc_vj_ssc_eyeman_female_flying"] = {{ group = 0, value = 1 }, { group = 1, value = 0 }},
        ["npc_vj_ssc_eyeman_female_flying_and_invisible"] = {{ group = 0, value = 1 }, { group = 1, value = 0 }},
        ["npc_vj_ssc_eyeman_male_flying"] = {{ group = 0, value = 1 }, { group = 1, value = 0 }},
        ["npc_vj_ssc_eyeman_male_flying_and_invisible"] = {{ group = 0, value = 1 }, { group = 1, value = 0 }},
    }

    -- ============================================================
    -- 3. ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
    -- ============================================================
    local function GetNPCAliasKey(npcClass)
        if not npcClass then return npcClass end
        return NetricsaData.NPC_ALIASES[npcClass] or npcClass
    end

    local function IsNPCAlias(npcClass)
        return npcClass ~= nil and NetricsaData.NPC_ALIASES[npcClass] ~= nil
    end

    local function GetNPCsByAlias(aliasKey)
        local result = {}
        if not aliasKey then return result end
        for npcClass, alias in pairs(NetricsaData.NPC_ALIASES) do
            if alias == aliasKey then table.insert(result, npcClass) end
        end
        if #result == 0 then table.insert(result, aliasKey) end
        return result
    end

    local function GetEnemyDisplayName(npcClass)
        npcClass = GetNPCAliasKey(npcClass)
        local lang = CurrentLang or "en"
        
        local paths = {
            "netricsa/descriptions/" .. lang .. "/" .. npcClass .. ".lua",
            "lua/netricsa/descriptions/" .. lang .. "/" .. npcClass .. ".lua",
        }
        
        for _, path in ipairs(paths) do
            if file.Exists(path, "GAME") then
                local content = file.Read(path, "GAME")
                if content and content ~= "" then
                    local firstLine = ""
                    local i = 1
                    while i <= #content do
                        local char = string.sub(content, i, i)
                        if char == "\n" or char == "\r" then
                            break
                        end
                        firstLine = firstLine .. char
                        i = i + 1
                    end
                    
                    if string.byte(firstLine, 1) == 239 and string.byte(firstLine, 2) == 187 and string.byte(firstLine, 3) == 191 then
                        firstLine = string.sub(firstLine, 4)
                    end
                    
                    firstLine = string.Trim(firstLine)
                    
                    if firstLine ~= "" and #firstLine < 200 then
                        return firstLine
                    end
                end
            end
        end
        
        return npcClass
    end

    local function GetScoreForNPC(npcClass)
        npcClass = GetNPCAliasKey(npcClass)
        local lang = CurrentLang or "en"
        local path = "netricsa/descriptions/" .. lang .. "/" .. npcClass .. ".lua"
        
        if file.Exists(path, "GAME") then
            local content = file.Read(path, "GAME")
            if content then
                local lines = string.Explode("\n", content)
                if #lines >= 11 then
                    local line11 = lines[11]
                    local score = string.match(line11, "(%d+)")
                    if score then
                        return tonumber(score)
                    end
                end
            end
        else
            local altPath = "lua/netricsa/descriptions/" .. lang .. "/" .. npcClass .. ".lua"
            if file.Exists(altPath, "GAME") then
                local content = file.Read(altPath, "GAME")
                if content then
                    local lines = string.Explode("\n", content)
                    if #lines >= 11 then
                        local line11 = lines[11]
                        local score = string.match(line11, "(%d+)")
                        if score then
                            return tonumber(score)
                        end
                    end
                end
            end
        end
        
        return 100
    end

    function GetNPCScore(npcClass)
        local key = GetNPCAliasKey(npcClass)
        local data = NetricsaData.ENEMIES and NetricsaData.ENEMIES[key]
        if data and data.score then
            return data.score
        end
        return GetScoreForNPC(key) or 100
    end

    -- ============================================================
    -- 4. ТАБЛИЦЫ ДАННЫХ
    -- ============================================================
    local ENEMIES = {}
    local WEAPONS = {}
    local SAVED_MAPS = {}
    local READ_STATUS = { maps = {}, enemies = {}, weapons = {} }
    local showScan = false
    local is_loading_process = true
    local continueCampaign = false
    local hasStarted = false

    -- ============================================================
    -- 5. ФУНКЦИЯ СОХРАНЕНИЯ
    -- ============================================================
    SaveProgress = function()
        SAVED_MAPS = SAVED_MAPS or {}
        ENEMIES = ENEMIES or {}
        WEAPONS = WEAPONS or {}
        READ_STATUS = READ_STATUS or { maps = {}, enemies = {}, weapons = {} }

        local currentMap = game.GetMap()
        if currentMap and currentMap ~= "" then
            SAVED_MAPS[currentMap] = true
        end

        NetricsaData.SAVED_MAPS = SAVED_MAPS
        NetricsaData.ENEMIES = ENEMIES
        NetricsaData.WEAPONS = WEAPONS
        NetricsaData.READ_STATUS = READ_STATUS

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
            print("[Netricsa] ✅ Saved:", table.Count(ENEMIES), "enemies,", table.Count(WEAPONS), "weapons,", table.Count(SAVED_MAPS), "maps, Score:", stats_total_score or 0)
        else
            print("[Netricsa] ❌ Failed to save!")
        end
    end

    -- ============================================================
    -- 6. NET.RECEIVE
    -- ============================================================
    net.Receive("Netricsa_AddEnemy", function()
        local npcClass = net.ReadString()
        local mdl = net.ReadString()
        local skin = net.ReadUInt(8)
        local bgCount = net.ReadUInt(8)
        local bodygroups = {}
        for i = 1, bgCount do bodygroups[i] = net.ReadUInt(8) end

        local color = Color(255,255,255,255)
        local rendermode, renderfx, material, nodraw, scale = 0, 0, "", false, 1
        local aliasKey = GetNPCAliasKey(npcClass)

        pcall(function()
            color = Color(net.ReadUInt(8) or 255, net.ReadUInt(8) or 255, net.ReadUInt(8) or 255, net.ReadUInt(8) or 255)
            rendermode = net.ReadUInt(8) or 0
            renderfx = net.ReadUInt(8) or 0
            material = net.ReadString() or ""
            nodraw = net.ReadBool() or false
            scale = net.ReadFloat() or 1
            local receivedAlias = net.ReadString()
            if receivedAlias and receivedAlias ~= "" then aliasKey = GetNPCAliasKey(receivedAlias) end
        end)

        local keyToCheck = aliasKey or npcClass
        local isNew = not ENEMIES[keyToCheck]
        local npcScore = GetScoreForNPC(keyToCheck)
        local old = ENEMIES[keyToCheck]

        ENEMIES[keyToCheck] = {
            mdl = mdl, skin = skin, bodygroups = bodygroups,
            alias = aliasKey ~= npcClass and aliasKey or nil,
            originalClasses = old and old.originalClasses or {},
            score = npcScore, color = color, rendermode = rendermode,
            renderfx = renderfx, material = material, nodraw = nodraw, scale = scale
        }
        ENEMIES[keyToCheck].originalClasses[npcClass] = true
        NetricsaData.ENEMIES = ENEMIES

        print("[Netricsa Client] Received AddEnemy: " .. npcClass .. " -> " .. keyToCheck .. " (score: " .. npcScore .. ")")

        if isNew then
            NetricsaData.showScan = true
            timer.Simple(2, function() if NetricsaData then NetricsaData.showScan = false end end)
            surface.PlaySound("netricsa/Info.wav")
        end
        
        SaveProgress()
    end)

    net.Receive("Netricsa_AddWeapon", function()
        local class = net.ReadString()
        local mdl = net.ReadString()

        if not WEAPONS[class] then
            WEAPONS[class] = { mdl = mdl }
            NetricsaData.WEAPONS = WEAPONS
            SaveProgress()
            print("[Netricsa Client] New weapon discovered: " .. class)
        end
    end)

    net.Receive("Netricsa_UpdateScore", function()
        local points = net.ReadUInt(16) or 0
        stats_total_score = (stats_total_score or 0) + points
        SaveProgress()
        print("[Netricsa] Added " .. points .. " points. Total: " .. stats_total_score)
    end)

    net.Receive("Netricsa_UpdateStats", function()
        local kills = net.ReadUInt(16) or 0
        local total = net.ReadUInt(16) or 0
        local startTime = net.ReadFloat() or CurTime()
        local maxEnemies = net.ReadUInt(16) or total

        stats_kills = kills
        stats_totalEnemies = total
        stats_startTime = startTime
        stats_maxEnemies = maxEnemies

        if IsValid(NetricsaFrame) and NetricsaFrame:IsVisible() then
            local currentTab = _G.NetricsaCurrentTab or ""
            if currentTab == L("tabs", "statistics") then
                NetricsaTabs.SwitchTab(currentTab)
            end
        end
    end)

    -- ============================================================
    -- 7. ОСТАЛЬНЫЕ ФУНКЦИИ
    -- ============================================================
    local function LoadDescription(name)
        local lang = CurrentLang or "en"
        name = GetNPCAliasKey(name)
        
        local paths = {
            "netricsa/descriptions/" .. lang .. "/" .. name .. ".lua",
            "lua/netricsa/descriptions/" .. lang .. "/" .. name .. ".lua",
            "netricsa/descriptions/" .. lang .. "/ssfrac_" .. name .. ".lua",
            "netricsa/descriptions/" .. lang .. "/ss_planet_" .. name .. ".lua",
        }
        
        for _, path in ipairs(paths) do
            if file.Exists(path, "GAME") then
                local content = file.Read(path, "GAME")
                if content and content ~= "" then
                    return content
                end
            end
        end
        
        return L("ui", "no_data")
    end

    local function LoadProgress()
        print("[Netricsa Client] Loading progress from file: " .. NetricsaData.PROGRESS_FILE)

        if not file.Exists(NetricsaData.PROGRESS_FILE, "DATA") then
            print("[Netricsa Client] Progress file does not exist")
            return false
        end

        local raw = file.Read(NetricsaData.PROGRESS_FILE, "DATA")
        if not raw or raw == "" then
            print("[Netricsa Client] File is empty")
            return false
        end

        local data = util.JSONToTable(raw)
        if not data then
            print("[Netricsa Client] Failed to parse JSON")
            return false
        end

        if type(data.maps) == "table" then
            SAVED_MAPS = {}
            for k, v in pairs(data.maps) do
                if type(k) == "number" then
                    SAVED_MAPS[v] = true
                else
                    SAVED_MAPS[k] = v
                end
            end
        else
            SAVED_MAPS = {}
        end

        ENEMIES = data.enemies or {}
        WEAPONS = data.weapons or {}
        READ_STATUS = data.read or { maps = {}, enemies = {}, weapons = {} }
        stats_total_score = data.total_score or 0

        if not READ_STATUS.maps then READ_STATUS.maps = {} end
        if not READ_STATUS.enemies then READ_STATUS.enemies = {} end
        if not READ_STATUS.weapons then READ_STATUS.weapons = {} end

        local currentMap = game.GetMap()
        if currentMap and currentMap ~= "" then
            SAVED_MAPS[currentMap] = true
        end

        print("[Netricsa Client] ✅ SUCCESSFULLY LOADED:")
        print("  Maps:", table.Count(SAVED_MAPS))
        print("  Enemies:", table.Count(ENEMIES))
        print("  Weapons:", table.Count(WEAPONS))
        print("  Score:", stats_total_score)

        NetricsaData.SAVED_MAPS = SAVED_MAPS
        NetricsaData.ENEMIES = ENEMIES
        NetricsaData.WEAPONS = WEAPONS
        NetricsaData.READ_STATUS = READ_STATUS

        return true
    end

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
        if not key then return end

        local t = (key == "maps" and SAVED_MAPS)
            or (key == "enemies" and ENEMIES)
            or (key == "weapons" and WEAPONS)

        if not t then return end

        READ_STATUS = READ_STATUS or { maps = {}, enemies = {}, weapons = {} }
        READ_STATUS[key] = READ_STATUS[key] or {}

        for k, _ in pairs(t) do
            if not READ_STATUS[key][k] then
                opener(k)
                return
            end
        end

        local lastKey = nil
        for k, _ in pairs(t) do
            lastKey = k
        end

        if lastKey then
            opener(lastKey)
        end
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

local function OnStart()
    if hasStarted then return end
    hasStarted = true

    local currentMap = game.GetMap()
    print("[Netricsa] ==================================================")
    print("[Netricsa] STARTING CAMPAIGN LOAD on map:", currentMap)

    -- 🔹 [ГЛАВНОЕ] ПРОВЕРЯЕМ ВРЕМЯ ВЫХОДА
    local exitTime = LoadExitTime()
    local currentTime = os.time()
    local timeDiff = exitTime > 0 and (currentTime - exitTime) or 0
    
    print("[Netricsa] === TIMEOUT CHECK ===")
    print("[Netricsa] Exit time:", exitTime)
    print("[Netricsa] Current time:", currentTime)
    print("[Netricsa] Time difference:", timeDiff, "seconds (" .. math.Round(timeDiff / 60, 1) .. " minutes)")
    print("[Netricsa] Threshold: 600 seconds (10 minutes)")
    
    local shouldReset = false
    if exitTime > 0 and timeDiff >= 600 then
        shouldReset = true
        print("[Netricsa] 🔥 TIMEOUT! Resetting campaign...")
    else
        print("[Netricsa] No timeout, loading progress...")
    end

    -- 🔥 ЕСЛИ ТАЙМАУТ - СБРАСЫВАЕМ!
    if shouldReset then
        print("[Netricsa] ⚠️ RESETTING ALL PROGRESS!")
        
        ENEMIES = {}
        WEAPONS = {}
        SAVED_MAPS = {}
        READ_STATUS = { maps = {}, enemies = {}, weapons = {} }
        stats_total_score = 0
        stats_kills = 0
        stats_totalEnemies = 0
        
        -- Добавляем текущую карту
        SAVED_MAPS[currentMap] = true
        
        -- Сохраняем пустоту
        is_loading_process = false
        SaveProgress()
        
        -- Удаляем файл времени выхода (чтобы не сбросить дважды)
        if file.Exists(NetricsaData.EXIT_TIME_FILE, "DATA") then
            file.Delete(NetricsaData.EXIT_TIME_FILE)
            print("[Netricsa] Deleted exit time file")
        end
        
        print("[Netricsa] ✅ CAMPAIGN RESET COMPLETE!")
        print("[Netricsa] ==================================================")
        return
    end

    -- 🔹 ЗАГРУЖАЕМ СОХРАНЕНИЕ (если нет таймаута)
    local loaded = LoadProgress()

    if not loaded then
        print("[Netricsa] No valid save found, initializing empty campaign")
        ENEMIES = {}
        WEAPONS = {}
        SAVED_MAPS = {}
        READ_STATUS = { maps = {}, enemies = {}, weapons = {} }
        stats_total_score = 0
    end

    -- Всегда добавляем текущую карту
    if currentMap and currentMap ~= "" and not SAVED_MAPS[currentMap] then
        SAVED_MAPS[currentMap] = true
    end

    is_loading_process = false
    SaveProgress()

    print("[Netricsa] ✅ FINAL LOADED STATE:")
    print("  Maps:", table.Count(SAVED_MAPS))
    print("  Enemies:", table.Count(ENEMIES))
    print("  Weapons:", table.Count(WEAPONS))
    print("  Score:", stats_total_score or 0)
    print("[Netricsa] ==================================================")

    timer.Simple(3, function()
        RunConsoleCommand("netricsa_check")
    end)
end
    -- ============================================================
    -- 8. КОМАНДЫ И ХУКИ
    -- ============================================================
    concommand.Add("netricsa_save_now", function()
        is_loading_process = false
        SaveProgress()
        print("[Netricsa] Manual save completed")
        print("[Netricsa] ENEMIES: " .. table.Count(ENEMIES) .. ", WEAPONS: " .. table.Count(WEAPONS))
    end)

    hook.Add("Initialize", "Netricsa_ForceLoadOnStart", function()
        print("[Netricsa] Force loading progress on Initialize...")
        LoadProgress()
    end)

    hook.Add("InitPostEntity", "Netricsa_LoadAfterMapLoad", function()
        timer.Simple(0.5, function()
            print("[Netricsa] Loading progress after map load...")
            LoadProgress()
            is_loading_process = false
        end)
    end)

    hook.Add("InitPostEntity", "Netricsa_AddCurrentMap", function()
        NetricsaData.OnStart()
        local currentMap = game.GetMap()
        if not SAVED_MAPS[currentMap] then
            SAVED_MAPS[currentMap] = true
            SaveProgress()
        end
    end)

    hook.Add("ShutDown", "Netricsa_SaveExitTime", function()
        file.Write(NetricsaData.EXIT_TIME_FILE, tostring(os.time()))
        SaveProgress()
    end)

    -- ============================================================
    -- 9. ЭКСПОРТ В NetricsaData
    -- ============================================================
    NetricsaData.ENEMIES = ENEMIES
    NetricsaData.WEAPONS = WEAPONS
    NetricsaData.SAVED_MAPS = SAVED_MAPS
    NetricsaData.READ_STATUS = READ_STATUS
    NetricsaData.showScan = showScan
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
    NetricsaData.GetNPCAliasKey = GetNPCAliasKey
    NetricsaData.IsNPCAlias = IsNPCAlias
    NetricsaData.GetNPCsByAlias = GetNPCsByAlias

    -- ============================================================
    -- 10. ТАЙМЕРЫ
    -- ============================================================
    timer.Create("Netricsa_AutoSave", 120, 0, function()
        if not is_loading_process and (table.Count(ENEMIES) > 0 or table.Count(WEAPONS) > 0) then
            SaveProgress()
        end
    end)

    timer.Create("Netricsa_ActivityPulse", 30, 0, function()
        if not is_loading_process then
            RunConsoleCommand("netricsa_campaign_time", tostring(os.time()))
        end
    end)

end