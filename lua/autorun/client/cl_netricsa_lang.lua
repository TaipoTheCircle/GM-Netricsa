if CLIENT then
    LANGUAGES = {
        en = {
            tabs = {
                tactical   = "TACTICAL DATA",
                strategic  = "STRATEGIC DATA",
                weapons    = "WEAPONS",
                enemies    = "ENEMIES",
                statistics = "STATISTICS",
                fractions  = "FACTIONS",
            },
            ui = {
                styles        = "STYLES",
                language      = "LANGUAGE",
                scanning      = "SCANNING...",
                kills         = "KILLS",
                secrets       = "SECRETS",
                game_time     = "GAME TIME",
                select_enemy  = "Select enemy above.",
                select_weapon = "Select weapon above.",
                select_map    = "Select map above.",
                no_data       = "No data available. If you want to help and suggest your improvements or translations, you can contact us on our github: (https://github.com/TaipoTheCircle/GM-Netricsa)"
            }
        },
        ru = {
            tabs = {
                tactical   = "ТАКТИКА",
                strategic  = "СТРАТЕГИЯ",
                weapons    = "ОРУЖИЕ",
                enemies    = "ВРАГИ",
                statistics = "СТАТИСТИКА",
                fractions  = "ФРАКЦИИ",
            },
            ui = {
                styles        = "СТИЛИ",
                language      = "ЯЗЫК",
                scanning      = "СКАНИРОВАНИЕ...",
                kills         = "УБИЙСТВА",
                secrets       = "СЕКРЕТЫ",
                game_time     = "ВРЕМЯ В ИГРЕ",
                select_enemy  = "Выберите врага сверху.",
                select_weapon = "Выберите оружие сверху.",
                select_map    = "Выберите карту сверху.",
                no_data       = "Нет данных. Если вы хотите помочь и предложить свои улучшения или переводы, можете обратиться на наш github: (https://github.com/TaipoTheCircle/GM-Netricsa)"
            }
        }
    }


    -- путь к файлу, который переживает перезапуск
    local LANG_FILE = "netricsa_lang.txt"
    CurrentLang = "en"

    function SaveLanguage(lang)
        file.Write(LANG_FILE, lang)
    end

    local function LoadLanguage()
        if file.Exists(LANG_FILE, "DATA") then
            local saved = file.Read(LANG_FILE, "DATA")
            if LANGUAGES[saved] then
                CurrentLang = saved
                print("[Netricsa] Loaded language: " .. saved)
                return
            end
        end
        print("[Netricsa] Using default language: EN")
        CurrentLang = "en"
    end

    function L(group, key)
        local lang = LANGUAGES[CurrentLang] or LANGUAGES.en
        return (lang[group] and lang[group][key]) or key
    end

    LoadLanguage()
end