concommand.Add("netricsa_lookat_bg", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local trace = ply:GetEyeTrace()
    if not IsValid(trace.Entity) then
        print("Вы ни на кого не смотрите!")
        return
    end
    
    local ent = trace.Entity
    local class = ent:GetClass()
    
    print("=== BODYGROUPS FOR " .. class .. " ===")
    print("Model: " .. (ent:GetModel() or "unknown"))
    print("Skin: " .. (ent:GetSkin() or 0))
    print("NoDraw: " .. tostring(ent:GetNoDraw()))
    print("RenderMode: " .. (ent:GetRenderMode() or 0))
    print("")
    
    local numBGs = ent:GetNumBodyGroups() or 0
    print("Bodygroups (" .. numBGs .. "):")
    for i = 0, numBGs - 1 do
        local name = ent:GetBodygroupName(i) or "Unknown"
        local value = ent:GetBodygroup(i) or 0
        print(string.format("  Group %d: %s = %d", i, name, value))
    end
    print("================================")
    
    -- Генерируем готовый код для SPECIAL_BODYGROUP_OVERRIDES
    print("")
    print("=== COPY THIS ===")
    print('["' .. class .. '"] = {')
    for i = 0, numBGs - 1 do
        local name = ent:GetBodygroupName(i) or "Unknown"
        local value = ent:GetBodygroup(i) or 0
        print(string.format('    { group = %d, value = %d },  -- %s', i, value, name))
    end
    print('},')
    print("==================")
end)

concommand.Add("netricsa_turret_bg", function()
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent:GetClass() == "npc_vj_ss2_turret_machinegun" then
            print("=== TURRET BODYGROUPS ===")
            print("Model: " .. (ent:GetModel() or "unknown"))
            print("Skin: " .. (ent:GetSkin() or 0))
            print("NoDraw: " .. tostring(ent:GetNoDraw()))
            
            if ent:GetNoDraw() then
                print("⚠️ ТУРЕЛЬ СКРЫТА! (nodraw = true)")
            end
            
            local numBGs = ent:GetNumBodyGroups() or 0
            print("")
            print("Bodygroups (" .. numBGs .. "):")
            for i = 0, numBGs - 1 do
                local name = ent:GetBodygroupName(i) or "Unknown"
                local value = ent:GetBodygroup(i) or 0
                print(string.format("  Group %d: %s = %d", i, name, value))
            end
            
            print("")
            print("Visual params:")
            print("  RenderMode: " .. (ent:GetRenderMode() or 0))
            print("  RenderFX: " .. (ent:GetRenderFX() or 0))
            print("  Material: " .. (ent:GetMaterial() or "none"))
            
            print("================================")
            
            print("")
            print("=== ДЛЯ ВСТАВКИ В SPECIAL_BODYGROUP_OVERRIDES ===")
            print('["npc_vj_ss2_turret_machinegun"] = {')
            for i = 0, numBGs - 1 do
                local name = ent:GetBodygroupName(i) or "Unknown"
                local value = ent:GetBodygroup(i) or 0
                print(string.format('    { group = %d, value = %d },  -- %s', i, value, name))
            end
            print('    -- Также нужно принудительно установить nodraw = false')
            print('},')
            print("=====================================================")
            return
        end
    end
    print("Турель не найдена на карте! Заспавньте её и попробуйте снова.")
end)

print("[Netricsa] Debug commands loaded: netricsa_lookat_bg, netricsa_turret_bg")