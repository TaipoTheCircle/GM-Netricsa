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
