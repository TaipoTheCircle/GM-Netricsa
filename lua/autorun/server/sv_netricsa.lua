if SERVER then

    -- Network strings
    util.AddNetworkString("Netricsa_AddEnemy")
    util.AddNetworkString("Netricsa_AddWeapon")
    util.AddNetworkString("Netricsa_PlaySound")
    util.AddNetworkString("Netricsa_ContinueCampaign")
    util.AddNetworkString("Netricsa_UpdateStats")

    -- Таблица для сохранения состояния NPC до смерти
    local EnemyState = {} -- entIndex -> { mdl = "", skin = 0, bodygroups = { ... } }

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


local function CountAliveNPCs()
        local alive = 0
        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) and ent:IsNPC() and ent:Health() > 0 then
                alive = alive + 1
            end
        end
        return alive
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
    EnemyState = {} -- очистим состояние при рестарте карты

    -- Загружаем TrackedEnemies из файла, если SysTime() > 1 (не перезапуск сервера)
    print("[Netricsa Server] InitPostEntity - SysTime(): " .. SysTime())
    if SysTime() > 1 then
        LoadTrackedEnemies()
    else
        -- При перезапуске сервера сбрасываем файл
        print("[Netricsa Server] Server restart detected, resetting TrackedEnemies")
        TrackedEnemies = {}
        if file.Exists(TRACKED_ENEMIES_FILE, "DATA") then
            file.Delete(TRACKED_ENEMIES_FILE)
            print("[Netricsa Server] Deleted old TrackedEnemies file")
        end
    end

    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent:IsNPC() then
            local id = ent:EntIndex()
            if not trackedNPCs[id] then
                trackedNPCs[id] = true
                stats_totalEnemies = stats_totalEnemies + 1
            end
            -- Сохраняем состояние текущих NPC (чтобы потом не брать "смертельный" вид)
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
            trackedNPCs[id] = true
            stats_totalEnemies = stats_totalEnemies + 1
            BroadcastStats()
        end
        -- сохраняем модель/скин/бодигруппы при спавне
        SaveStateFor(ent)
    end)
end)

-- NPC убит → добавляем к убийствам, total не меняется
hook.Add("OnNPCKilled", "Netricsa_StatsOnKill", function(npc, attacker, inflictor)
    if not IsValid(npc) then return end
    local id = npc:EntIndex()
    stats_kills = stats_kills + 1
    -- помечаем, что он именно убит
    npc._NetricsaKilled = true
    BroadcastStats()
end)

-- NPC удалён (деспаун, remove) → уменьшаем total, НО только если он не убит
hook.Add("EntityRemoved", "Netricsa_StatsOnRemove", function(ent)
    if not IsValid(ent) or not ent:IsNPC() then
        -- даже если ent не валиден, попробуем очистить сохранённое состояние по индексу
        if ent then RemoveStateFor(ent) end
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
    -- удаляем сохранённое состояние
    EnemyState[id] = nil
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


end 
