if CLIENT then
    include("cl_netricsa_styles.lua")
    include("cl_netricsa_lang.lua")
    include("cl_netricsa_fonts.lua")
    include("cl_netricsa_utils.lua")
    include("cl_netricsa_data.lua")
    include("cl_netricsa_tabs.lua")
    include("cl_netricsa_main.lua")
    include("cl_netricsa_hooks.lua")

    -- Load progress on client init
    NetricsaData.LoadProgress()
end
