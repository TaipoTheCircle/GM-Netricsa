if SERVER then
    -- Network strings
    util.AddNetworkString("Netricsa_AddEnemy")
    util.AddNetworkString("Netricsa_AddWeapon")
    util.AddNetworkString("Netricsa_PlaySound")
    util.AddNetworkString("Netricsa_ContinueCampaign")
    util.AddNetworkString("Netricsa_UpdateStats")

    -- Таблица для сохранения состояния NPC до смерти
    local EnemyState = {} -- entIndex -> { mdl = "", skin = 0, bodygroups = { ... } }

    -- 🔹 ТАБЛИЦА ДРУЖЕСТВЕННЫХ NPC
    local FRIENDLY_NPCS = {
        ["npc_citizen"] = true,
        ["npc_monk"] = true,
        ["npc_alyx"] = true,
        ["npc_barney"] = true,
        ["npc_dog"] = true,
        ["npc_magnusson"] = true,
        ["npc_breen"] = true,
        ["npc_vortigaunt"] = true,
        ["npc_eli"] = true,
        ["npc_mossman"] = true,
        ["monster_scientist"] = true,
        ["monster_barney"] = true,
        ["npc_fisherman"] = true,
        ["npc_kleiner"] = true,
        ["npc_gman"] = true,
        ["monster_gman"] = true,
    }

    -- 🔹 ТАБЛИЦА ОТНОШЕНИЙ NPC К ИГРОКАМ
    local hostileRelations = {} -- npcID -> playerID -> true

    local function CaptureEnemyState(ent)
        if not IsValid(ent) or not ent:IsNPC() then return nil end
        local t = {}
        t.mdl = ent:GetModel() or ""
        t.skin = ent:GetSkin() or 0
        t.bodygroups = {}
        local bgCount = ent:GetNumBodyGroups() or 0
        for i = 0, math.max(0, bgCount - 1) do
            t.bodygroups[i+1] = ent:GetBodygroup(i)
        end
        return t
    end

    local function SaveStateFor(ent)
        if not IsValid(ent) or not ent:IsNPC() then return end
        local id = ent:EntIndex()
        local st = CaptureEnemyState(ent)
        if st then
            EnemyState[id] = st
        end
    end

    local function RemoveStateFor(ent)
        if not ent then return end
        local id = ent:EntIndex()
        EnemyState[id] = nil
    end

    local function GetSavedState(ent)
        if not IsValid(ent) then return nil end
        return EnemyState[ent:EntIndex()]
    end

    -- 🔹 ФУНКЦИЯ ПРОВЕРКИ - ВРАГ ЛИ NPC ДЛЯ ИГРОКА
    local function IsEnemyForPlayer(npc, attacker)
        if not IsValid(npc) or not IsValid(attacker) then return false end
        
        local npcClass = npc:GetClass()
        
        -- Если NPC изначально враждебный (не в списке дружественных)
        if not FRIENDLY_NPCS[npcClass] then
            return true
        end
        
        -- Проверяем отношения конкретного NPC к игроку
        local npcID = npc:EntIndex()
        local attackerID = attacker:EntIndex()
        
        -- Если NPC стал враждебным к этому игроку
        if hostileRelations[npcID] and hostileRelations[npcID][attackerID] then
            return true
        end
        
        -- Проверяем текущие отношения через Disposition
        local disposition = npc:Disposition(attacker)
        if disposition == D_HT or disposition == D_FR then -- Ненависть или Страх
            -- Помечаем как враждебного для этого игрока
            if not hostileRelations[npcID] then
                hostileRelations[npcID] = {}
            end
            hostileRelations[npcID][attackerID] = true
            return true
        end
        
        return false
    end

    -- 🔹 ПЕРЕДЕЛАННАЯ ФУНКЦИЯ ПОДСЧЕТА NPC
    local function CountEnemyNPCs()
        local enemyCount = 0
        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) and ent:IsNPC() and ent:Health() > 0 then
                -- 🔹 СЧИТАЕМ ТОЛЬКО ВРАЖЕСКИХ NPC
                local isEnemy = false
                for _, ply in ipairs(player.GetAll()) do
                    if IsValid(ply) and IsEnemyForPlayer(ent, ply) then
                        isEnemy = true
                        break
                    end
                end
                
                if isEnemy then
                    enemyCount = enemyCount + 1
                end
            end
        end
        return enemyCount
    end

    util.AddNetworkString("Netricsa_UpdateStats")

    local stats_kills = 0
    local stats_totalEnemies = 0
    local stats_startTime = CurTime()
    local trackedNPCs = {} -- entIndex -> true (учтён в total)

    local function BroadcastStats()
        net.Start("Netricsa_UpdateStats")
            net.WriteInt(stats_kills or 0, 16)
            net.WriteInt(stats_totalEnemies or 0, 16) -- всего учтённых NPC
            net.WriteFloat(stats_startTime or CurTime())
        net.Broadcast()
    end

    -- Таблица известных NPC
    TrackedEnemies = TrackedEnemies or {}

    local TRACKED_ENEMIES_FILE = "netricsa_tracked_enemies.json"

    local function SaveTrackedEnemies()
        print("[Netricsa Server] Saving TrackedEnemies to file: " .. TRACKED_ENEMIES_FILE)
        local json = util.TableToJSON(TrackedEnemies, true)
        if json then
            file.Write(TRACKED_ENEMIES_FILE, json)
            print("[Netricsa Server] Successfully saved " .. table.Count(TrackedEnemies) .. " enemies")
        else
            print("[Netricsa Server] Failed to serialize TrackedEnemies")
        end
    end

    local function LoadTrackedEnemies()
        print("[Netricsa Server] Loading TrackedEnemies from file: " .. TRACKED_ENEMIES_FILE)
        if file.Exists(TRACKED_ENEMIES_FILE, "DATA") then
            local raw = file.Read(TRACKED_ENEMIES_FILE, "DATA")
            if raw then
                local data = util.JSONToTable(raw)
                if data then
                    TrackedEnemies = data
                    print("[Netricsa Server] Successfully loaded " .. table.Count(TrackedEnemies) .. " enemies")
                else
                    print("[Netricsa Server] Failed to parse JSON data")
                end
            else
                print("[Netricsa Server] Failed to read file")
            end
        else
            print("[Netricsa Server] File does not exist")
        end
    end

    -- при старте карты
    hook.Add("InitPostEntity", "Netricsa_StatsInit", function()
        stats_kills = 0
        stats_totalEnemies = 0
        stats_startTime = CurTime()
        trackedNPCs = {}
        EnemyState = {}
        hostileRelations = {}

        -- Загружаем TrackedEnemies
        if SysTime() > 1 then
            LoadTrackedEnemies()
        else
            TrackedEnemies = {}
            if file.Exists(TRACKED_ENEMIES_FILE, "DATA") then
                file.Delete(TRACKED_ENEMIES_FILE)
            end
        end

        -- 🔹 СЧИТАЕМ ТОЛЬКО ВРАЖЕСКИХ NPC ПРИ СТАРТЕ
        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) and ent:IsNPC() then
                local id = ent:EntIndex()
                if not trackedNPCs[id] then
                    -- Проверяем является ли NPC врагом для любого игрока
                    local isEnemy = false
                    for _, ply in ipairs(player.GetAll()) do
                        if IsValid(ply) and IsEnemyForPlayer(ent, ply) then
                            isEnemy = true
                            break
                        end
                    end
                    
                    if isEnemy then
                        trackedNPCs[id] = true
                        stats_totalEnemies = stats_totalEnemies + 1
                    end
                end
                SaveStateFor(ent)
            end
        end

        BroadcastStats()
    end)

    -- NPC появился
    hook.Add("OnEntityCreated", "Netricsa_StatsOnSpawn", function(ent)
        timer.Simple(0, function()
            if not IsValid(ent) or not ent:IsNPC() then return end
            local id = ent:EntIndex()
            if not trackedNPCs[id] then
                -- 🔹 ПРОВЕРЯЕМ ЯВЛЯЕТСЯ ЛИ НОВЫЙ NPC ВРАГОМ
                local isEnemy = false
                for _, ply in ipairs(player.GetAll()) do
                    if IsValid(ply) and IsEnemyForPlayer(ent, ply) then
                        isEnemy = true
                        break
                    end
                end
                
                if isEnemy then
                    trackedNPCs[id] = true
                    stats_totalEnemies = stats_totalEnemies + 1
                    BroadcastStats()
                end
            end
            SaveStateFor(ent)
        end)
    end)

    -- 🔹 ПЕРЕДЕЛАННЫЙ ХУК НА УБИЙСТВО NPC
    hook.Add("OnNPCKilled", "Netricsa_StatsOnKill", function(npc, attacker, inflictor)
        if not IsValid(npc) then return end
        
        local id = npc:EntIndex()
        
        -- 🔹 ПРОВЕРЯЕМ, ЯВЛЯЕТСЯ ЛИ NPC ВРАГОМ ДЛЯ ЭТОГО ИГРОКА
        local isEnemy = IsEnemyForPlayer(npc, attacker)
        
        if isEnemy then
            -- Считаем только вражеских NPC
            stats_kills = stats_kills + 1
            print("[Netricsa] Enemy killed: " .. npc:GetClass() .. " by " .. (IsValid(attacker) and attacker:GetName() or "unknown"))
        else
            print("[Netricsa] Friendly NPC killed: " .. npc:GetClass() .. " (not counted)")
        end
        
        -- помечаем, что он именно убит (для статистики удаления)
        npc._NetricsaKilled = true
        BroadcastStats()
    end)

    -- NPC удалён (деспаун, remove) → уменьшаем total, НО только если он не убит
    hook.Add("EntityRemoved", "Netricsa_StatsOnRemove", function(ent)
        if not IsValid(ent) or not ent:IsNPC() then
            -- даже если ent не валиден, попробуем очистить сохранённое состояние по индексу
            if ent then 
                RemoveStateFor(ent) 
                -- 🔹 очищаем отношения при удалении NPC
                local npcID = ent:EntIndex()
                hostileRelations[npcID] = nil
            end
            return
        end
        local id = ent:EntIndex()
        if trackedNPCs[id] then
            -- если он не был убит, значит despawn/remove
            if not ent._NetricsaKilled then
                stats_totalEnemies = math.max(0, stats_totalEnemies - 1)
            end
            trackedNPCs[id] = nil
            BroadcastStats()
        end
        -- удаляем сохранённое состояние и отношения
        EnemyState[id] = nil
        hostileRelations[id] = nil
    end)

    -- 🔹 ХУК ДЛЯ ОТСЛЕЖИВАНИЯ ИЗМЕНЕНИЯ ОТНОШЕНИЙ NPC (ОБНОВЛЕННЫЙ)
    hook.Add("OnEntityRelationshipChange", "Netricsa_RelationshipTracker", function(npc, target, oldRel, newRel)
        if not IsValid(npc) or not IsValid(target) or not target:IsPlayer() then return end
        
        local npcID = npc:EntIndex()
        local targetID = target:EntIndex()
        
        -- 🔹 ОБНОВЛЯЕМ СТАТИСТИКУ ПРИ ИЗМЕНЕНИИ ОТНОШЕНИЙ
        timer.Simple(0.1, function()
            if not IsValid(npc) then return end
            
            local wasTracked = trackedNPCs[npcID] or false
            local isNowEnemy = IsEnemyForPlayer(npc, target)
            
            -- Если NPC стал врагом и не был в статистике
            if isNowEnemy and not wasTracked then
                trackedNPCs[npcID] = true
                stats_totalEnemies = stats_totalEnemies + 1
                print("[Netricsa] NPC became enemy: " .. npc:GetClass() .. " - added to stats")
                BroadcastStats()
            -- Если NPC перестал быть врагом и был в статистике
            elseif not isNowEnemy and wasTracked then
                -- Проверяем не является ли NPC врагом для других игроков
                local isEnemyForAnyone = false
                for _, ply in ipairs(player.GetAll()) do
                    if IsValid(ply) and ply ~= target and IsEnemyForPlayer(npc, ply) then
                        isEnemyForAnyone = true
                        break
                    end
                end
                
                if not isEnemyForAnyone then
                    trackedNPCs[npcID] = nil
                    stats_totalEnemies = math.max(0, stats_totalEnemies - 1)
                    print("[Netricsa] NPC became friendly: " .. npc:GetClass() .. " - removed from stats")
                    BroadcastStats()
                end
            end
        end)
        
        -- 🔹 СОХРАНЯЕМ ВРАЖДЕБНЫЕ ОТНОШЕНИЯ
        if newRel == D_HT or newRel == D_FR then
            if not hostileRelations[npcID] then
                hostileRelations[npcID] = {}
            end
            hostileRelations[npcID][targetID] = true
            print("[Netricsa] NPC became hostile: " .. npc:GetClass() .. " to " .. target:GetName())
        elseif (newRel == D_LI or newRel == D_NU) and hostileRelations[npcID] then
            -- Убираем из вражеских отношений если стал дружественным
            hostileRelations[npcID][targetID] = nil
            print("[Netricsa] NPC became friendly: " .. npc:GetClass() .. " to " .. target:GetName())
        end
    end)

    -- Отслеживание NPC (отправляем данные при смерти, но используем сохранённое состояние если есть)
    hook.Add("OnNPCKilled", "NetricsaTrack", function(npc, attacker, inflictor)
        if not IsValid(npc) then return end

        local npcClass = npc:GetClass()

        -- если уже отправляли этот класс — пропускаем
        if TrackedEnemies[npcClass] then return end

        -- берем сохранённое состояние (то, что было до смерти)
        local saved = GetSavedState(npc)

        local mdl, skin, bodygroups = "", 0, {}
        if saved then
            mdl = saved.mdl or ""
            skin = saved.skin or 0
            bodygroups = saved.bodygroups or {}
        else
            -- запасной вариант — всё ещё пытаемся прочитать с сущности (на случай, если не было сохранено)
            mdl = npc:GetModel() or ""
            skin = npc:GetSkin() or 0
            bodygroups = {}
            for i = 0, (npc:GetNumBodyGroups()-1) do
                bodygroups[i+1] = npc:GetBodygroup(i)
            end
        end

        TrackedEnemies[npcClass] = true
        SaveTrackedEnemies() -- сохраняем в файл при добавлении нового NPC

        net.Start("Netricsa_AddEnemy")
            net.WriteString(npcClass)
            net.WriteString(mdl)
            net.WriteUInt(skin, 8)
            net.WriteUInt(#bodygroups, 8)
            for i, bg in ipairs(bodygroups) do
                net.WriteUInt(bg, 8)
            end
        net.Broadcast()

        net.Start("Netricsa_PlaySound")
        net.Broadcast()
    end)

    -- Отслеживание оружия
    hook.Add("PlayerSpawnedSWEP", "NetricsaTrackWeapon", function(ply, wep)
        if not IsValid(wep) then return end

        net.Start("Netricsa_AddWeapon")
            net.WriteString(wep:GetClass())
        net.Broadcast()
    end)

    -- Отслеживание ПОДБОРА оружия игроком
    hook.Add("WeaponEquip", "NetricsaTrackPickupWeapon", function(wep, ply)
        if not IsValid(wep) or not IsValid(ply) or not wep:GetClass() then return end

        net.Start("Netricsa_AddWeapon")
            net.WriteString(wep:GetClass())
            net.WriteString(wep:GetModel() or "models/weapons/w_pistol.mdl")
        net.Send(ply) -- только тому, кто подобрал
    end)

    -- Специальные NPC
    hook.Add("OnEntityCreated", "NetricsaTrackSpecialNPCs", function(ent)
        timer.Simple(0, function()
            if not IsValid(ent) then return end
            if ent:GetClass() == "monster_nihilanth" then
                local npcClass = ent:GetClass()
                local mdl = ent:GetModel() or ""
                local skin = ent:GetSkin() or 0

                local bgCount = ent:GetNumBodyGroups() or 0
                local bodygroups = {}
                for i = 0, bgCount-1 do
                    bodygroups[i+1] = ent:GetBodygroup(i)
                end

                -- Сохраняем состояние для этой сущности на всякий случай
                SaveStateFor(ent)

                net.Start("Netricsa_AddEnemy")
                    net.WriteString(npcClass)
                    net.WriteString(mdl)
                    net.WriteUInt(skin, 8)
                    net.WriteUInt(bgCount, 8)
                    for i=1, bgCount do
                        net.WriteUInt(bodygroups[i], 8)
                    end
                net.Broadcast()

                net.Start("Netricsa_PlaySound")
                net.Broadcast()
            end
        end)
    end)

    -- Список "особых" NPC, которых нужно сразу показывать
    local SpecialInstantEnemies = {
        ["monster_tentacle"] = true,
        ["monster_osprey"] = true,
        ["monster_bigmomma_strong"] = true,
        ["monster_bigmomma"] = true,
        ["monster_nihilanth"] = true,
        ["monster_flyer"] = true,
        ["monster_apache"] = true,
        ["monster_gman"] = true,
        ["npc_vj_hlrbfr_genmod262"] = true,
        ["npc_vj_hlazure_diabloboss"] = true,
        ["npc_vj_hlrof_geneworm"] = true,
        ["npc_vj_hlr1a_nihilanth"] = true,
        ["npc_vj_hlr1_gonarch"] = true,
        ["npc_vj_hlrof_pitworm"] = true,
        ["npc_vj_hlr1_gman"] = true,
        ["npc_vj_hlrof_geneworm"] = true,
        ["npc_agf_anime_saitama"] = true,
        ["npc_sniper"] = true,
        ["monster_roach"] = true,
        ["monster_geneworm"] = true,
        ["monster_alien_nihilanth"] = true,
        ["monster_hornet"] = true,
        ["npc_kingpin_r"] = true,
        ["npc_advisor"] = true,
        ["npc_helicopter"] = true,
        ["npc_combine_camera"] = true,
        ["npc_combinegunship"] = true,
        ["npc_combinedropship"] = true,
        ["npc_turret_ceiling"] = true,
        ["npc_bullseye"] = true,
        ["npc_apcdriver"] = true,
        ["npc_antlion_grub"] = true,
        ["xen_tree"] = true,
        ["xen_hair"] = true,
        ["sent_vj_xen_hair"] = true,
        ["npc_vj_hlr1_xen_tree"] = true,
        ["sent_vj_xen_plant_light"] = true,
        ["xen_plantlight"] = true,
        ["xen_spore_small"] = true,
        ["xen_spore_medium"] = true,
        ["xen_spore_large"] = true,
        ["sent_vj_xen_spore_small"] = true,
        ["sent_vj_xen_spore_medium"] = true,
        ["sent_vj_xen_spore_large"] = true,
        ["obj_vj_hlr1_hornet"] = true,
        ["sent_vj_xen_crystal"] = true,
        ["npc_missiledefense"] = true,
        ["npc_vj_ssc_devil"] = true,
        ["npc_vj_ss2_mentalfestung"] = true,
        ["npc_vj_ssc_devil_question"] = true,
        ["npc_vj_ssc_walker_female"] = true,
        ["npc_vj_ssc_elementallava_large"] = true,
        ["npc_vj_q4_strogg_harvester"] = true,
        ["npc_vj_ssc_exotechlarva"] = true,
    }

    local function AnnounceSpecialNPC(ent)
        if not IsValid(ent) or not SpecialInstantEnemies[ent:GetClass()] then return end
        local npcClass = ent:GetClass()
        if TrackedEnemies[npcClass] then return end

        local mdl = ent:GetModel() or ""
        local skin = ent:GetSkin() or 0
        local bgCount = ent:GetNumBodyGroups() or 0
        local bodygroups = {}
        for i = 0, bgCount - 1 do
            bodygroups[i+1] = ent:GetBodygroup(i)
        end

        TrackedEnemies[npcClass] = true
        SaveTrackedEnemies() -- сохраняем в файл при добавлении специального NPC

        net.Start("Netricsa_AddEnemy")
            net.WriteString(npcClass)
            net.WriteString(mdl)
            net.WriteUInt(skin, 8)
            net.WriteUInt(bgCount, 8)
            for i=1, bgCount do
                net.WriteUInt(bodygroups[i], 8)
            end
        net.Broadcast()

        net.Start("Netricsa_PlaySound")
        net.Broadcast()
    end

    hook.Add("OnEntityCreated", "Netricsa_TrackSpecialInstant", function(ent)
        timer.Simple(0, function()
            if not IsValid(ent) then return end
            AnnounceSpecialNPC(ent)
        end)
    end)

    hook.Add("InitPostEntity", "Netricsa_CheckSpecialInstant", function()
        -- задержка чтобы все NPC на карте успели проинициализироваться
        timer.Simple(0.2, function()
            for _, ent in ipairs(ents.GetAll()) do
                AnnounceSpecialNPC(ent)
            end
        end)
    end)

    -- Специальный хак для карты c4a3 (логово Нихиланта)
    hook.Add("InitPostEntity", "Netricsa_ForceNihilanthOnC4A3", function()
        if game.GetMap():lower() == "c4a3" then
            timer.Simple(0.5, function()
                for _, ent in ipairs(ents.FindByClass("monster_nihilanth")) do
                    AnnounceSpecialNPC(ent)
                end
            end)
        end
    end)
    util.AddNetworkString("Netricsa_ShowScanPrompt")
    util.AddNetworkString("Netricsa_HideScanPrompt") 
    util.AddNetworkString("Netricsa_ScanNPC")

    -- ConVar для клавиши сканирования
    CreateConVar("netricsa_scan_key", "E", FCVAR_ARCHIVE, "Key for scanning NPCs (default: E)")

    -- Таблица уже отсканированных NPC для каждого игрока
    local ScannedNPCs = {} -- playerID -> npcID -> true

    -- Функция проверки может ли NPC быть отсканирован
    local function CanScanNPC(ply, npc)
        if not IsValid(ply) or not IsValid(npc) or not npc:IsNPC() then return false end
        
        -- 🔹 УМЕНЬШЕН РАДИУС С 200 ДО 100
        local distance = ply:GetPos():Distance(npc:GetPos())
        if distance > 100 then return false end
        
        -- Проверяем LOS (линию обзора) и направление взгляда
        local trace = util.TraceLine({
            start = ply:EyePos(),
            endpos = npc:EyePos() + npc:OBBCenter(),
            filter = {ply, npc}
        })
        
        if trace.Hit and trace.Entity ~= npc then return false end
        
        -- Проверяем смотрит ли игрок на NPC (угол между направлением взгляда и направлением к NPC)
        local toNPC = (npc:EyePos() - ply:EyePos()):GetNormalized()
        local viewAng = ply:EyeAngles()
        local viewDir = viewAng:Forward()
        
        local dot = viewDir:Dot(toNPC)
        if dot < 0.8 then -- ~36 градусов конус обзора
            return false
        end

        -- 🔹 ПРОВЕРЯЕМ, ЕСТЬ ЛИ УЖЕ ЭТОТ ТИП NPC В СПИСКЕ
        local npcClass = npc:GetClass()
        if TrackedEnemies and TrackedEnemies[npcClass] then
            return false -- NPC уже есть в Netricsa, нельзя сканировать
        end
        
        -- Проверяем не отсканирован ли уже этот конкретный NPC
        local playerID = ply:SteamID64()
        local npcID = npc:EntIndex()
        
        if ScannedNPCs[playerID] and ScannedNPCs[playerID][npcID] then
            return false
        end
        
        -- Проверяем не убит ли NPC
        if npc:Health() <= 0 then return false end
        
        return true
    end

    -- Функция поиска NPC для сканирования
    local function FindNPCToScan(ply)
        local targetNPC = nil
        local bestDot = 0.8 -- минимальный dot продукт
        
        for _, npc in ipairs(ents.GetAll()) do
            if IsValid(npc) and npc:IsNPC() and CanScanNPC(ply, npc) then
                -- Вычисляем насколько прямо игрок смотрит на NPC
                local toNPC = (npc:EyePos() - ply:EyePos()):GetNormalized()
                local viewDir = ply:EyeAngles():Forward()
                local dot = viewDir:Dot(toNPC)
                
                if dot > bestDot then
                    bestDot = dot
                    targetNPC = npc
                end
            end
        end
        
        return targetNPC
    end

    -- Отправка подсказки игроку
    local function UpdateScanPrompt(ply)
        local npc = FindNPCToScan(ply)
        
        if npc then
            net.Start("Netricsa_ShowScanPrompt")
                net.WriteString(npc:GetClass())
            net.Send(ply)
        else
            net.Start("Netricsa_HideScanPrompt")
            net.Send(ply)
        end
    end

    -- Основной хук для отслеживания
    hook.Add("Think", "Netricsa_ScanSystem", function()
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply:Alive() then
                UpdateScanPrompt(ply)
            end
        end
    end)

    -- Обработка сканирования
    net.Receive("Netricsa_ScanNPC", function(len, ply)
        local npcClass = net.ReadString()
        
        -- Находим NPC который сканируется
        local targetNPC = nil
        for _, npc in ipairs(ents.GetAll()) do
            if IsValid(npc) and npc:IsNPC() and npc:GetClass() == npcClass and CanScanNPC(ply, npc) then
                targetNPC = npc
                break
            end
        end
        
        if not targetNPC then 
            print("[Netricsa] Scan failed: NPC not available or already scanned")
            return 
        end
        
        -- 🔹 ДОПОЛНИТЕЛЬНАЯ ПРОВЕРКА - УБЕДИТЬСЯ ЧТО NPC ЕЩЕ НЕТ В СПИСКЕ
        if TrackedEnemies and TrackedEnemies[npcClass] then
            print("[Netricsa] Scan failed: " .. npcClass .. " already in Netricsa")
            return
        end
        
        -- Помечаем как отсканированный
        local playerID = ply:SteamID64()
        local npcID = targetNPC:EntIndex()
        
        if not ScannedNPCs[playerID] then
            ScannedNPCs[playerID] = {}
        end
        ScannedNPCs[playerID][npcID] = true
        
        -- Добавляем в Netricsa (если еще не добавлен)
        if not TrackedEnemies[npcClass] then
            TrackedEnemies[npcClass] = true
            SaveTrackedEnemies()
            
            local mdl = targetNPC:GetModel() or ""
            local skin = targetNPC:GetSkin() or 0
            local bgCount = targetNPC:GetNumBodyGroups() or 0
            local bodygroups = {}
            for i = 0, bgCount-1 do
                bodygroups[i+1] = targetNPC:GetBodygroup(i)
            end

            net.Start("Netricsa_AddEnemy")
                net.WriteString(npcClass)
                net.WriteString(mdl)
                net.WriteUInt(skin, 8)
                net.WriteUInt(bgCount, 8)
                for i=1, bgCount do
                    net.WriteUInt(bodygroups[i], 8)
                end
            net.Send(ply)
            
            print("[Netricsa] NPC scanned: " .. npcClass .. " by " .. ply:GetName())
        end
        
        -- Скрываем подсказку
        net.Start("Netricsa_HideScanPrompt")
        net.Send(ply)
    end)

    -- Очистка при смерти NPC
    hook.Add("EntityRemoved", "Netricsa_CleanupScanned", function(ent)
        if not IsValid(ent) or not ent:IsNPC() then return end
        
        local npcID = ent:EntIndex()
        
        -- Удаляем из таблицы сканированных у всех игроков
        for playerID, scanned in pairs(ScannedNPCs) do
            scanned[npcID] = nil
        end
    end)

    -- Очистка при выходе игрока
    hook.Add("PlayerDisconnected", "Netricsa_CleanupPlayerScans", function(ply)
        local playerID = ply:SteamID64()
        ScannedNPCs[playerID] = nil
    end)

    -- 🔹 КОМАНДА ДЛЯ ПРИНУДИТЕЛЬНОГО ОБНОВЛЕНИЯ СТАТИСТИКИ
    concommand.Add("netricsa_refresh_stats", function(ply)
        if not ply:IsAdmin() then return end
        
        print("[Netricsa] Refreshing enemy statistics...")
        local newTotal = 0
        trackedNPCs = {}
        
        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) and ent:IsNPC() and ent:Health() > 0 then
                local id = ent:EntIndex()
                
                -- Проверяем является ли NPC врагом для любого игрока
                local isEnemy = false
                for _, player in ipairs(player.GetAll()) do
                    if IsValid(player) and IsEnemyForPlayer(ent, player) then
                        isEnemy = true
                        break
                    end
                end
                
                if isEnemy then
                    trackedNPCs[id] = true
                    newTotal = newTotal + 1
                end
            end
        end
        
        stats_totalEnemies = newTotal
        BroadcastStats()
        print("[Netricsa] Statistics refreshed. Total enemies: " .. newTotal)
    end)
end