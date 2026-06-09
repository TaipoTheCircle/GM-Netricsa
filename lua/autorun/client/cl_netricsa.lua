if CLIENT then
    -- 🔹 СНАЧАЛА САМЫЕ БАЗОВЫЕ МОДУЛИ (без зависимостей)
    include("cl_netricsa_fonts.lua")
    include("cl_netricsa_lang.lua")      -- L() функция
    include("cl_netricsa_styles.lua")    -- STYLES таблица
    
    -- 🔹 ПОТОМ DATA (должен быть ДО hooks!)
    include("cl_netricsa_data.lua")
    
    -- 🔹 ПОТОМ МОДУЛИ С ЗАВИСИМОСТЯМИ
    include("cl_netricsa_utils.lua")
    include("cl_netricsa_special_anims.lua")
    
    -- 🔹 ПОТОМ ВСЁ ОСТАЛЬНОЕ
    include("cl_netricsa_tabs.lua")
    include("cl_netricsa_main.lua")
    include("cl_netricsa_hooks.lua")     -- hooks должен быть ПОСЛЕ data!
    include("cl_netricsa_scan.lua")
    include("cl_netricsa_settings.lua")
end

-- Серверные сети
net.Receive("Netricsa_AddEnemy", function()
    local npcClass = net.ReadString()
    local mdl = net.ReadString()
    local skin = net.ReadUInt(8)
    
    local bodygroupCount = net.ReadUInt(8)
    local bodygroups = {}
    for i = 1, bodygroupCount do
        bodygroups[i] = net.ReadUInt(8)
    end

    local col = Color(
        net.ReadUInt(8),
        net.ReadUInt(8),
        net.ReadUInt(8),
        net.ReadUInt(8)
    )
    local rendermode = net.ReadUInt(8)
    local renderfx = net.ReadUInt(8)
    local material = net.ReadString()
    local nodraw = net.ReadBool()
    local scale = net.ReadFloat()

    local data = {
        class = npcClass,
        model = mdl,
        skin = skin,
        bodygroups = bodygroups,
        color = col,
        rendermode = rendermode,
        renderfx = renderfx,
        material = material,
        nodraw = nodraw,
        scale = scale
    }

    Netricsa_TrackedEnemies = Netricsa_TrackedEnemies or {}
    Netricsa_TrackedEnemies[npcClass] = data

    print("[Netricsa] Client received enemy: " .. npcClass)
end)