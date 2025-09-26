if CLIENT then
    LANGUAGES = {
        en = {
            tabs = {
                tactical   = "TACTICAL DATA",
                strategic  = "STRATEGIC DATA",
                weapons    = "WEAPONS",
                enemies    = "ENEMIES",
                statistics = "STATISTICS",
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
                no_data       = "No data available."
            }
        },
        ru = {
            tabs = {
                tactical   = "ТАКТИКА",
                strategic  = "СТРАТЕГИЯ",
                weapons    = "ОРУЖИЕ",
                enemies    = "ВРАГИ",
                statistics = "СТАТИСТИКА",
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
                no_data       = "Нет данных."
            }
        }
    }

    local LANG_FILE = "netricsa_lang.txt"
    CurrentLang = "en"

    local function SaveLanguage(lang)
        file.Write(LANG_FILE, lang)
    end

    local function LoadLanguage()
        if file.Exists(LANG_FILE, "DATA") then
            local saved = file.Read(LANG_FILE, "DATA")
            if LANGUAGES[saved] then
                CurrentLang = saved
                return
            end
        end
        CurrentLang = "en"
    end

    function L(group, key)
        local lang = LANGUAGES[CurrentLang] or LANGUAGES.en
        return (lang[group] and lang[group][key]) or key
    end

    LoadLanguage()
end
