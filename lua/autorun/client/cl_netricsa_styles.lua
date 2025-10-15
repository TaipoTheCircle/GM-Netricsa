-- cl_netricsa_styles.lua
if CLIENT then
    -- =======================
    -- Стили
    -- =======================
    STYLES = {
        Revolution = {
            grid    = "netricsa/grid.png",
            model   = "netricsa/model_bg.png",
            text    = "netricsa/text_bg.png",
            mail    = "netricsa/mail_bg.png",
            content = "netricsa/content_bg.png",
            bg      = "netricsa/bg_netricsa.png",
            exit = "netricsa/exit_bg.png",
            color   = Color(209,171,88)
        },

        TSE = {
            grid    = "netricsa/grid_alt1.png",
            model   = "netricsa/model_bg_alt1.png",
            text    = "netricsa/text_bg_alt1.png",
            mail    = "netricsa/mail_bg_alt1.png",
            content = "netricsa/content_bg_alt1.png",
            bg      = "netricsa/bg_netricsa_alt1.png",
            exit = "netricsa/exit_bg_alt1.png",
            color   = Color(100, 200, 255)
        },

        TFE = {
            grid    = "netricsa/grid_alt2.png",
            model   = "netricsa/model_bg_alt2.png",
            text    = "netricsa/text_bg_alt2.png",
            mail    = "netricsa/mail_bg_alt2.png",
            content = "netricsa/content_bg_alt2.png",
            bg      = "netricsa/bg_netricsa_alt2.png",
            exit = "netricsa/exit_bg_alt2.png",
            color   = Color(0, 255, 0)
        },

        Red = {
            grid    = "netricsa/grid_alt3.png",
            model   = "netricsa/model_bg_alt3.png",
            text    = "netricsa/text_bg_alt3.png",
            mail    = "netricsa/mail_bg_alt3.png",
            content = "netricsa/content_bg_alt3.png",
            bg      = "netricsa/bg_netricsa_alt3.png",
            exit = "netricsa/exit_bg_alt3.png",
            color   = Color(255, 80, 80)
        },

        Orange = {
            grid    = "netricsa/grid_alt4.png",
            model   = "netricsa/model_bg_alt4.png",
            text    = "netricsa/text_bg_alt4.png",
            mail    = "netricsa/mail_bg_alt4.png",
            content = "netricsa/content_bg_alt4.png",
            bg      = "netricsa/bg_netricsa_alt4.png",
            exit = "netricsa/exit_bg_alt4.png",
            color   = Color(255, 140, 0)
        },

        Yellow = {
            grid    = "netricsa/grid_alt5.png",
            model   = "netricsa/model_bg_alt5.png",
            text    = "netricsa/text_bg_alt5.png",
            mail    = "netricsa/mail_bg_alt5.png",
            content = "netricsa/content_bg_alt5.png",
            bg      = "netricsa/bg_netricsa_alt5.png",
            exit = "netricsa/exit_bg_alt5.png",
            color   = Color(255, 255, 0)
        },

        ["NE-HD"] = {
            grid    = "netricsa/grid_alt6.png",
            model   = "netricsa/model_bg_alt6.png",
            text    = "netricsa/text_bg_alt6.png",
            mail    = "netricsa/mail_bg_alt6.png",
            content = "netricsa/content_bg_alt6.png",
            bg      = "netricsa/bg_netricsa_alt6.png",
            exit = "netricsa/exit_bg_alt6.png",
            color   = Color(255, 105, 180)
        },

        BFE = {
            grid    = "netricsa/grid_alt7.png",
            model   = "netricsa/model_bg_alt7.png",
            text    = "netricsa/text_bg_alt7.png",
            mail    = "netricsa/mail_bg_alt7.png",
            content = "netricsa/content_bg_alt7.png",
            bg      = "netricsa/bg_netricsa_alt7.png",
            exit = "netricsa/exit_bg_alt7.png",
            color   = Color(255, 255, 255)
        },

        SS2 = {
            grid    = "netricsa/grid_alt8.png",
            model   = "netricsa/model_bg_alt8.png",
            text    = "netricsa/text_bg_alt8.png",
            mail    = "netricsa/mail_bg_alt8.png",
            content = "netricsa/content_bg_alt8.png",
            bg      = "netricsa/bg_netricsa_alt8.png",
            exit = "netricsa/exit_bg_alt8.png",
            color   = Color(65, 177, 255)
        },

        BD = {
            grid    = "netricsa/grid_alt9.png",
            model   = "netricsa/model_bg_alt9.png",
            text    = "netricsa/text_bg_alt9.png",
            mail    = "netricsa/mail_bg_alt9.png",
            content = "netricsa/content_bg_alt9.png",
            bg      = "netricsa/bg_netricsa_alt9.png",
            exit = "netricsa/exit_bg_alt9.png",
            color   = Color(177, 105, 24)
        },

        SSA = {
            grid    = "netricsa/grid_alt10.png",
            model   = "netricsa/model_bg_alt10.png",
            text    = "netricsa/text_bg_alt10.png",
            mail    = "netricsa/mail_bg_alt10.png",
            content = "netricsa/content_bg_alt10.png",
            bg      = "netricsa/bg_netricsa_alt10.png",
            exit = "netricsa/exit_bg_alt10.png",
            color   = Color(248, 224, 0)
        },

        NE = {
            grid    = "netricsa/grid_alt11.png",
            model   = "netricsa/model_bg_alt11.png",
            text    = "netricsa/text_bg_alt11.png",
            mail    = "netricsa/mail_bg_alt11.png",
            content = "netricsa/content_bg_alt11.png",
            bg      = "netricsa/bg_netricsa_alt11.png",
            exit = "netricsa/exit_bg_alt11.png",
            color   = Color(250, 250, 251)
        },

        WX2 = {
            grid    = "netricsa/grid_alt12.png",
            model   = "netricsa/model_bg_alt12.png",
            text    = "netricsa/text_bg_alt12.png",
            mail    = "netricsa/mail_bg_alt12.png",
            content = "netricsa/content_bg_alt12.png",
            bg      = "netricsa/bg_netricsa_alt12.png",
            exit = "netricsa/exit_bg_alt12.png",
            color   = Color(0, 255, 169)
        },

        HL = {
            grid    = "netricsa/grid_alt13.png",
            model   = "netricsa/model_bg_alt13.png",
            text    = "netricsa/text_bg_alt13.png",
            mail    = "netricsa/mail_bg_alt13.png",
            content = "netricsa/content_bg_alt13.png",
            bg      = "netricsa/bg_netricsa_alt13.png",
            exit = "netricsa/exit_bg_alt13.png",
            color   = Color(248, 156, 0)
        },

        OPFOR = {
            grid    = "netricsa/grid_alt14.png",
            model   = "netricsa/model_bg_alt14.png",
            text    = "netricsa/text_bg_alt14.png",
            mail    = "netricsa/mail_bg_alt14.png",
            content = "netricsa/content_bg_alt14.png",
            bg      = "netricsa/bg_netricsa_alt14.png",
            exit = "netricsa/exit_bg_alt14.png",
            color   = Color(58, 183, 35)
        },

        Combine = {
            grid    = "netricsa/grid_alt15.png",
            model   = "netricsa/model_bg_alt15.png",
            text    = "netricsa/text_bg_alt15.png",
            mail    = "netricsa/mail_bg_alt15.png",
            content = "netricsa/content_bg_alt15.png",
            bg      = "netricsa/bg_netricsa_alt15.png",
            exit = "netricsa/exit_bg_alt15.png",
            color   = Color(24, 52, 96)
        },

        MineCraft = {
            grid    = "netricsa/grid_alt16.png",
            model   = "netricsa/model_bg_alt16.png",
            text    = "netricsa/text_bg_alt16.png",
            mail    = "netricsa/mail_bg_alt16.png",
            content = "netricsa/content_bg_alt16.png",
            bg      = "netricsa/bg_netricsa_alt16.png",
            exit = "netricsa/exit_bg_alt16.png",
            color   = Color(213, 232, 208)
         },

        SSEE = {
            grid    = "netricsa/grid_alt17.png",
            model   = "netricsa/model_bg_alt17.png",
            text    = "netricsa/text_bg_alt17.png",
            mail    = "netricsa/mail_bg_alt17.png",
            content = "netricsa/content_bg_alt17.png",
            bg      = "netricsa/bg_netricsa_alt17.png",
            exit = "netricsa/exit_bg_alt17.png",
            color   = Color(229,142,2)
         },

        SSXBOX = {
            grid    = "netricsa/grid_alt18.png",
            model   = "netricsa/model_bg_alt18.png",
            text    = "netricsa/text_bg_alt18.png",
            mail    = "netricsa/mail_bg_alt18.png",
            content = "netricsa/content_bg_alt18.png",
            bg      = "netricsa/bg_netricsa_alt18.png",
            exit = "netricsa/exit_bg_alt18.png",
            color   = Color(191,172,26)
         },

        OBLIVION = {
            grid    = "netricsa/grid_alt19.png",
            model   = "netricsa/model_bg_alt19.png",
            text    = "netricsa/text_bg_alt19.png",
            mail    = "netricsa/mail_bg_alt19.png",
            content = "netricsa/content_bg_alt19.png",
            bg      = "netricsa/bg_netricsa_alt19.png",
            exit = "netricsa/exit_bg_alt19.png",
            color   = Color(105,48,23)
         },
    }

local STYLE_FILE = "netricsa_style.txt"

local function SaveNetricsaStyle(name)
    file.Write(STYLE_FILE, name)
end

local function LoadNetricsaStyle()
    if file.Exists(STYLE_FILE, "DATA") then
        local saved = string.Trim(file.Read(STYLE_FILE, "DATA") or "")
        if STYLES[saved] then
            NetricsaStyle = STYLES[saved]
            return
        end
    end
    NetricsaStyle = STYLES.Revolution
end


    -- публичная функция смены стиля
function SetNetricsaStyle(name)
    if STYLES[name] then
        NetricsaStyle = STYLES[name]
        SaveNetricsaStyle(name)
        surface.PlaySound("netricsa/button_ssm_press.wav")
    end
end



    --  загружаем стиль сразу при старте
    LoadNetricsaStyle()

    -- и дополнительно в хуке (на всякий случай)
    hook.Add("Initialize", "NetricsaLoadSavedStyle", function()
        LoadNetricsaStyle()
    end)
end
