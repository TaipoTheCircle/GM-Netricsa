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
                settings   = "SETTINGS"   
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
                no_data       = "No data available. If you want to help and suggest your improvements or translations, you can contact us on our github: (https://github.com/TaipoTheCircle/GM-Netricsa)",

                -- Settings
                settings_tab       = "SETTINGS",
                settings_help       = "Netricsa interface settings",
                settings_key_help   = "Choose the key to open Netricsa (default: N)",
                settings_current    = "Current key: ",
                settings_default    = "Default: N. Changes are saved automatically.",

                -- 🔹 New line for auto-open checkbox
                settings_auto_open  = "Open Netricsa automatically when the map starts",

                -- 🔹 SCAN SYSTEM TRANSLATIONS
                scan_prompt         = "Press [%s] to scan", -- %s будет заменено на клавишу
                scan_key_help       = "Choose the key to scan NPCs (default: E)",
                scan_current        = "Current scan key: ",
                scan_default        = "Default: E. Changes are saved automatically.",

                -- 🔹 WELCOME MESSAGE
                welcome             = "WELCOME TO NETRICSA!",

                -- 🔹 VERSION
                version             = "NETRICSA v2.01",
                score               = "SCORE",

                -- НОВЫЕ ПЕРЕВОДЫ
                auto_rotate_help    = "Automatic rotation of models",
                auto_rotate_label   = "Auto-rotate NPC models"
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
                settings   = "НАСТРОЙКИ"  
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
                no_data       = "Нет данных. Если вы хотите помочь и предложить свои улучшения или переводы, можете обратиться на наш github: (https://github.com/TaipoTheCircle/GM-Netricsa)",

                -- Настройки
                settings_tab       = "НАСТРОЙКИ",
                settings_help       = "Настройки интерфейса ИНЕРТАНА",
                settings_key_help   = "Выберите клавишу для открытия ИНЕРТАНА (по умолчанию N)",
                settings_current    = "Текущая клавиша: ",
                settings_default    = "По умолчанию: N. Изменения сохраняются автоматически.",
                settings_auto_open  = "Открывать ИНЕРТАН при запуске карты",
                scan_prompt         = "Нажмите [%s] для сканирования", -- %s будет заменено на клавишу
                scan_key_help       = "Выберите клавишу для сканирования NPC (по умолчанию E)",
                scan_current        = "Текущая клавиша сканирования: ",
                scan_default        = "По умолчанию: E. Изменения сохраняются автоматически.",
                welcome             = "ДОБРО ПОЖАЛОВАТЬ В ИНЕРТАН!",

                -- 🔹 ПЕРЕВОД ВЕРСИИ
                version             = "ИНЕРТАН v2.01",
                score               = "СЧЁТ",

                -- НОВЫЕ ПЕРЕВОДЫ
                auto_rotate_help    = "Автоматическое вращение моделей",
                auto_rotate_label   = "Авто-вращение моделей NPC"
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