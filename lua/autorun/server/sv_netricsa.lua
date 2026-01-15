if SERVER then
    -- Network strings
    util.AddNetworkString("Netricsa_AddEnemy")
    util.AddNetworkString("Netricsa_AddWeapon")
    util.AddNetworkString("Netricsa_PlaySound")
    util.AddNetworkString("Netricsa_ContinueCampaign")
    util.AddNetworkString("Netricsa_UpdateStats")
    util.AddNetworkString("Netricsa_UpdateScore")
    util.AddNetworkString("Netricsa_AddScoreForNPC")

 
    -- 🔹 ТАБЛИЦА ДРУЖЕСТВЕННЫХ NPC
    local FRIENDLY_NPCS = { 
        ["npc_citizen"] = true,
        ["npc_monk"] = true,
        ["npc_alyx"] = true,
        ["npc_barney"] = true,
        ["npc_dog"] = true,
        ["npc_magnusson"] = true,
        ["npc_breen"] = true,
        ["npc_eli"] = true,
        ["generic_actor"] = true,
        ["monster_generic"] = true,
        ["cycler_actor"] = true,
        ["#npc_sightgman"] = true,
        ["npc_sightgman"] = true,
        ["npc_vj_hlr1a_scientist"] = true,
        ["npc_vj_hlr1a_securityguard"] = true,
        ["npc_vj_hlrof_cleansuitsci"] = true,
        ["npc_vj_hlrdc_keller"] = true,
        ["npc_vj_hlrbs_rosenberg"] = true,
        ["npc_vj_hlr1_gman"] = true,
        ["npc_vj_hlrof_otis"] = true,
        ["npc_vj_hlr1_scientist"] = true,
        ["npc_vj_hlr1a_probedroid"] = true,
        ["npc_vj_hlr1_rat"] = true,
        ["npc_vj_hlr1_securityguard"] = true,
        ["sent_vj_xen_spore_large"] = true,
        ["sent_vj_xen_spore_medium"] = true,
        ["sent_vj_xen_spore_small"] = true,
        ["sent_vj_xen_plant_light"] = true,
        ["sent_vj_xen_hair"] = true,
        ["sent_vj_xen_crystal"] = true,
        ["npc_vj_hlr1_xen_tree"] = true,
        ["monster_cockroach"] = true,
        ["npc_mossman"] = true,
        ["monster_scientist"] = true,
        ["monster_barney"] = true,
        ["npc_fisherman"] = true,
        ["npc_kleiner"] = true,
        ["monster_gman"] = true,
        ["npc_gman"] = true,
        ["monster_hgrunt_dead_2"] = true,
        ["monster_hgrunt_dead_1"] = true,
        ["monster_hgrunt_dead_3"] = true,
        ["monster_hevsuit_dead_1"] = true,
        ["monster_hevsuit_dead_3"] = true,
        ["monster_hevsuit_dead_4"] = true,
        ["monster_hevsuit_dead_2"] = true,
        ["monster_barney_dead_1"] = true,
        ["monster_barney_dead_2"] = true,
        ["monster_barney_dead_3"] = true,
        ["monster_barney_dead_4"] = true,
        ["monster_barney_dead_5"] = true,
        ["monster_barney_dead_6"] = true,
        ["monster_barney_dead_7"] = true,
        ["monster_scientist_dead_7"] = true,
        ["monster_scientist_dead_6"] = true,
        ["monster_scientist_dead_5"] = true,
        ["monster_scientist_dead_4"] = true,
        ["monster_scientist_dead_1"] = true,
        ["monster_scientist_dead_2"] = true,
        ["monster_scientist_dead_3"] = true,
        ["xen_hair"] = true,
        ["xen_plantlight"] = true,
        ["xen_spore_large"] = true,
        ["xen_spore_medium"] = true,
        ["xen_spore_small"] = true,
        ["xen_tree"] = true,
        ["npc_vj_hlr2_alyx"] = true,
        ["npc_vj_hlr2_barney"] = true,
        ["npc_vj_hlr2_citizen"] = true,
        ["npc_vj_hlr2_father_grigori"] = true,
        ["npc_vj_hlr2b_merkava"] = true,
        ["npc_vj_hlr2_rebel"] = true,
        ["npc_vj_hlr2_rebel_engineer"] = true,
        ["npc_vj_hlr2_refugee"] = true,
        ["npc_vortigaunt"] = true,
        ["obj_ss3_spider_egg"] = true,
        ["npc_vj_hlrdc_xen_tree"] = true,
    }

    -- 🔹 ПРОСТАЯ ФУНКЦИЯ ПРОВЕРКИ - ВРАГ ЛИ NPC
    local function IsEnemy(npc)
        if not IsValid(npc) then return false end
        if not npc:IsNPC() then return false end
        
        local npcClass = npc:GetClass()
        local isEnemy = not FRIENDLY_NPCS[npcClass]
        
        return isEnemy
    end

    util.AddNetworkString("Netricsa_UpdateStats")

    -- 🔹 ПЕРЕМЕННЫЕ
    local stats_kills = 0
    local stats_totalEnemies = 0
    local stats_startTime = CurTime()
    local trackedNPCs = {} -- 🔹 Отслеживаемые NPC: id -> {entity, killed}

local function BroadcastStats()
    net.Start("Netricsa_UpdateStats")
        net.WriteUInt(math.min(stats_kills, 65535), 16)
        net.WriteUInt(math.min(stats_totalEnemies, 65535), 16)
        net.WriteFloat(stats_startTime)
    net.Broadcast()
    
    print("[Netricsa] Stats broadcast: " .. stats_kills .. "/" .. stats_totalEnemies .. " (tracked: " .. table.Count(trackedNPCs) .. ")")
end

    -- 🔹 Функция для очистки невалидных NPC из трекинга
    local function CleanupInvalidNPCs()
        local removed = 0
        for id, data in pairs(trackedNPCs) do
            if not IsValid(data.entity) then
                trackedNPCs[id] = nil
                removed = removed + 1
            end
        end
        if removed > 0 then
            print("[Netricsa] Cleaned up " .. removed .. " invalid NPCs from tracking")
        end
    end

    -- при старте карты
-- при старте карты
hook.Add("InitPostEntity", "Netricsa_StatsInit", function()
    stats_kills = 0
    stats_totalEnemies = 0
    stats_startTime = CurTime()
    trackedNPCs = {}

    -- 🔹 ОТЛАДКА ПРИ СТАРТЕ
    local totalNPCs = 0
    local enemyNPCs = 0
    local friendlyNPCs = 0
    
    print("[Netricsa] === SCANNING NPCs ===")
    
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent:IsNPC() then
            totalNPCs = totalNPCs + 1
            local npcClass = ent:GetClass()
            
            if IsEnemy(ent) then
                enemyNPCs = enemyNPCs + 1
                local id = ent:EntIndex()
                if not trackedNPCs[id] then
                    trackedNPCs[id] = {
                        entity = ent,
                        killed = false
                    }
                    stats_totalEnemies = stats_totalEnemies + 1
                end
                print("[Netricsa] ENEMY: " .. npcClass)
            else
                friendlyNPCs = friendlyNPCs + 1
                print("[Netricsa] FRIENDLY: " .. npcClass)
            end
        end
    end
    
    print("[Netricsa] === SCAN RESULTS ===")
    print("[Netricsa] Total NPCs: " .. totalNPCs)
    print("[Netricsa] Enemies: " .. enemyNPCs)
    print("[Netricsa] Friendly: " .. friendlyNPCs)
    print("[Netricsa] Tracked: " .. stats_totalEnemies)

    BroadcastStats()
    
    -- 🔹 Запускаем периодическую очистку невалидных NPC
    timer.Create("Netricsa_Cleanup", 10, 0, CleanupInvalidNPCs)
end)

    -- NPC появился
    hook.Add("OnEntityCreated", "Netricsa_StatsOnSpawn", function(ent)
        timer.Simple(0.1, function()
            if not IsValid(ent) or not ent:IsNPC() then return end
            
            if IsEnemy(ent) then
                local id = ent:EntIndex()
                if not trackedNPCs[id] then
                    trackedNPCs[id] = {
                        entity = ent,
                        killed = false
                    }
                    stats_totalEnemies = stats_totalEnemies + 1
                    BroadcastStats()
                    print("[Netricsa] SPAWNED ENEMY: " .. ent:GetClass() .. " -> " .. stats_totalEnemies)
                end
            else
                print("[Netricsa] SPAWNED FRIENDLY: " .. ent:GetClass())
            end
        end)
    end)

    -- NPC убит
-- Замените оба хука на один

hook.Add("EntityTakeDamage", "Netricsa_SnapshotBeforeDeath", function(ent, dmg)
    if not IsValid(ent) or not ent:IsNPC() then return end
    if ent.NetricsaSnapshot then return end

    if dmg:GetDamage() >= ent:Health() then
        -- 🔹 СОЗДАЕМ СНАПШОТ С ТЕКУЩИМИ ПАРАМЕТРАМИ
        local colorData = ent:GetColor()
        local colorTable
        
        -- 🔹 Проверяем, есть ли у NPC свой метод для получения цвета
        if ent.GetRenderColor then
            -- 🔹 Для VJ NPC или кастомных NPC
            local r, g, b, a = ent:GetRenderColor()
            colorTable = {
                r = r or 255,
                g = g or 255,
                b = b or 255,
                a = a or 255
            }
        elseif colorData and type(colorData) == "table" and colorData.r then
            -- 🔹 Стандартный метод
            colorTable = {
                r = colorData.r,
                g = colorData.g,
                b = colorData.b,
                a = colorData.a
            }
        else
            -- 🔹 Цвет по умолчанию
            colorTable = {r = 255, g = 255, b = 255, a = 255}
        end
        
        ent.NetricsaSnapshot = {
            class = ent:GetClass(),
            mdl = ent:GetModel() or "",
            skin = ent:GetSkin() or 0,

            bodygroups = (function()
                local t = {}
                for i = 0, ent:GetNumBodyGroups() - 1 do
                    t[i + 1] = ent:GetBodygroup(i)
                end
                return t
            end)(),

            -- 🔥 ВАЖНО: Получаем текущие значения ПРЯМО СЕЙЧАС
            color = colorTable,
            rendermode = ent:GetRenderMode() or 0,
            renderfx = ent:GetRenderFX() or 0,
            material = ent:GetMaterial() or "",
            nodraw = ent:GetNoDraw() or false,
            scale = ent:GetModelScale() or 1
        }
        
        -- 🔹 ОТЛАДКА: Выводим информацию о цвете
        print("[Netricsa] Snapshot for " .. ent:GetClass() .. 
              " - RenderMode: " .. tostring(ent:GetRenderMode()) ..
              " - Color: " .. colorTable.r .. "," .. colorTable.g .. "," .. colorTable.b .. "," .. colorTable.a ..
              " - Material: " .. tostring(ent:GetMaterial()))
    end
end)



hook.Add("OnNPCKilled", "NetricsaTrackCombined", function(npc, attacker)
    if not IsValid(npc) then return end
    if not npc.NetricsaSnapshot then return end

    local snap = npc.NetricsaSnapshot
    local npcClass = snap.class

    -- Добавление врага в Netricsa (берём данные ДО смерти)
    if not TrackedEnemies[npcClass] then
        TrackedEnemies[npcClass] = true

        net.Start("Netricsa_AddEnemy")
            net.WriteString(npcClass)
            net.WriteString(snap.mdl)
            net.WriteUInt(snap.skin, 8)
            net.WriteUInt(#snap.bodygroups, 8)
            for _, bg in ipairs(snap.bodygroups) do
                net.WriteUInt(bg, 8)
            end
            
            -- 🔥 ДОБАВЛЕННЫЕ СТРОКИ ЗДЕСЬ (после основных данных NPC)
            net.WriteUInt(snap.color.r, 8)
            net.WriteUInt(snap.color.g, 8)
            net.WriteUInt(snap.color.b, 8)
            net.WriteUInt(snap.color.a, 8)

            net.WriteUInt(snap.rendermode or 0, 8)
            net.WriteUInt(snap.renderfx or 0, 8)
            net.WriteString(snap.material or "")
            net.WriteBool(snap.nodraw or false)
            net.WriteFloat(snap.scale or 1)
        net.Broadcast()

        net.Start("Netricsa_PlaySound")
        net.Broadcast()
    end

    -- Отправка очков игроку
    if IsValid(attacker) and attacker:IsPlayer() then
        print("[Netricsa] Sending score for " .. npcClass .. " to " .. attacker:GetName())

        net.Start("Netricsa_AddScoreForNPC")
            net.WriteString(npcClass)
        net.Send(attacker)
    end

    -- Обновление статистики убийств
    if IsValid(attacker) and attacker:IsPlayer() then
        local id = npc:EntIndex()

        if trackedNPCs[id] and not trackedNPCs[id].killed then
            trackedNPCs[id].killed = true
            stats_kills = stats_kills + 1

            print("[Netricsa] Player " .. attacker:GetName() ..
                  " killed enemy: " .. npcClass ..
                  " (kills: " .. stats_kills .. ")")

            BroadcastStats()
        end
    end
end)


    -- NPC удалён
    hook.Add("EntityRemoved", "Netricsa_StatsOnRemove", function(ent)
        if not IsValid(ent) or not ent:IsNPC() then return end
        
        if IsEnemy(ent) then
            local id = ent:EntIndex()
            if trackedNPCs[id] then
                local wasKilled = trackedNPCs[id].killed
                
                if not wasKilled then
                    -- NPC удалён без убийства (деспавн) - уменьшаем общее количество
                    stats_totalEnemies = math.max(0, stats_totalEnemies - 1)
                    BroadcastStats()
                    print("[Netricsa] REMOVED ENEMY (despawn): " .. ent:GetClass() .. " -> " .. stats_totalEnemies)
                else
                    print("[Netricsa] REMOVED KILLED ENEMY: " .. ent:GetClass() .. " (no change)")
                end
                
                trackedNPCs[id] = nil
            end
        end
    end)

    -- 🔹 КОМАНДА ДЛЯ ПРОВЕРКИ ТЕКУЩЕГО СОСТОЯНИЯ
    concommand.Add("netricsa_check", function(ply)
        local totalNPCs = 0
        local enemyNPCs = 0
        local friendlyNPCs = 0
        local trackedCount = 0
        local killedCount = 0
        
        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) and ent:IsNPC() then
                totalNPCs = totalNPCs + 1
                if IsEnemy(ent) then
                    enemyNPCs = enemyNPCs + 1
                else
                    friendlyNPCs = friendlyNPCs + 1
                end
            end
        end
        
        -- Считаем трекнутые NPC
        for id, data in pairs(trackedNPCs) do
            trackedCount = trackedCount + 1
            if data.killed then
                killedCount = killedCount + 1
            end
        end
        
        print("=== NETRICSA CHECK ===")
        print("Stats: " .. stats_kills .. "/" .. stats_totalEnemies)
        print("Tracked - Total: " .. trackedCount .. ", Killed: " .. killedCount)
        print("Current NPCs - Total: " .. totalNPCs)
        print("Current NPCs - Enemies: " .. enemyNPCs) 
        print("Current NPCs - Friendly: " .. friendlyNPCs)
        print("==============================")
    end)

    -- 🔹 КОМАНДА ДЛЯ ПОЛНОГО СБРОСА
    concommand.Add("netricsa_hard_reset", function(ply)
        if not ply:IsAdmin() then return end
        print("[Netricsa] HARD RESET by admin")
        
        stats_kills = 0
        stats_totalEnemies = 0
        stats_startTime = CurTime()
        trackedNPCs = {}
        
        -- Пересчитываем текущих NPC
        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) and ent:IsNPC() and IsEnemy(ent) then
                local id = ent:EntIndex()
                if not trackedNPCs[id] then
                    trackedNPCs[id] = {
                        entity = ent,
                        killed = false
                    }
                    stats_totalEnemies = stats_totalEnemies + 1
                end
            end
        end
        
        BroadcastStats()
        print("[Netricsa] Hard reset complete")
    end)

    -- 🔹 КОМАНДА ДЛЯ СИНХРОНИЗАЦИИ С ТЕКУЩИМИ NPC
    concommand.Add("netricsa_sync", function(ply)
        if not ply:IsAdmin() then return end
        
        print("[Netricsa] Syncing with current NPCs...")
        local newTotal = 0
        local newTracked = {}
        
        -- Собираем текущих вражеских NPC
        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) and ent:IsNPC() and IsEnemy(ent) then
                local id = ent:EntIndex()
                local wasKilled = trackedNPCs[id] and trackedNPCs[id].killed or false
                
                newTracked[id] = {
                    entity = ent,
                    killed = wasKilled
                }
                newTotal = newTotal + 1
                
                if not wasKilled then
                    print("[Netricsa] Added live enemy to sync: " .. ent:GetClass())
                else
                    print("[Netricsa] Added killed enemy to sync: " .. ent:GetClass())
                end
            end
        end
        
        -- Обновляем статистику
        trackedNPCs = newTracked
        stats_totalEnemies = newTotal
        
        BroadcastStats()
        print("[Netricsa] Sync complete. Total enemies: " .. newTotal)
    end)

    -- Остальной код для трекинга врагов и оружия...
    -- Таблица известных NPC
    TrackedEnemies = TrackedEnemies or {}

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
        ["npc_wc_anime_saitama"] = true,
        ["npc_wc_shaids_gand_battle_robot_boss"] = true,
        ["npc_wc_tf2_headless_hatman"] = true,
        ["npc_wc_others_jew_boxer"] = true,
        ["npc_vj_mc_mzs_wroughtnaut"] = true,
        ["npc_vj_ssc_gizmo_big_secret"] = true,
        ["npc_vj_fc1_stone_head_helicopter"] = true,
        ["npc_vj_fc1_helicopter"] = true,
        ["npc_vj_fc1_hell_nit_helicopter"] = true,
        ["npc_vj_fc1_stone_head"] = true,
        ["npc_vj_fc1_helicopter_cut"] = true,
        ["npc_vj_fc1_security_helicopter"] = true,
        ["npc_vj_fc1_mutant_krieger"] = true,
        ["npc_vj_fc1_mutant_krieger_cut_eyes"] = true,
        ["obj_ss3_spider_egg"] = true,
        ["npc_vj_hlrdc_xen_tree"] = true,
        ["npc_vj_ssc_spaceship"] = true,
        ["npc_vj_ssc_summoner"] = true,
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
            if IsValid(ent) and ent:IsNPC() and IsEnemy(ent) then
                local id = ent:EntIndex()
                if not trackedNPCs[id] then
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

-- ▼ флаг при входе/срабатывании триггера смены уровня
hook.Add("AcceptInput", "Netricsa_ChangeLevelFlag", function(ent, input, activator, caller, data)
    if not IsValid(ent) then return end
    if ent:GetClass() ~= "trigger_changelevel" then return end
    if input ~= "ChangeLevel" then return end

    net.Start("Netricsa_ContinueCampaign")
    if IsValid(activator) and activator:IsPlayer() then
        net.Send(activator)
    else
        net.Broadcast()
    end
end)

-- ▼ запасной вариант: если карта использует только касание триггера
hook.Add("StartTouch", "Netricsa_ChangeLevelTouchFlag", function(ent, other)
    if ent:GetClass() == "trigger_changelevel" and IsValid(other) and other:IsPlayer() then
        net.Start("Netricsa_ContinueCampaign")
        net.Send(other)
    end
end)