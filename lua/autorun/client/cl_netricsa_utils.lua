if CLIENT then
    local function CreateButton(parent, text)
        local btn = vgui.Create("DButton", parent)
        if text then
            btn:SetText(text)
        end

        -- звук при наведении
        btn.OnCursorEntered = function(self)
            surface.PlaySound("netricsa/button_ssm.wav")
            self.HoveredColor = Color(255,255,255)
        end

        btn.OnCursorExited = function(self)
            self.HoveredColor = nil
        end

        -- звук при клике
        local oldClick = btn.DoClick
        btn.DoClick = function(self, ...)
            surface.PlaySound("netricsa/button_ssm_press.wav")
            if oldClick then oldClick(self, ...) end
        end

        -- универсальная отрисовка текста с подсветкой
        btn.Paint = function(self, w, h)
            local style = NetricsaStyle or STYLES.Revolution
            local col = self.HoveredColor or style.color
            draw.SimpleText(self:GetText(), "NetricsaText", w/2, h/2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        return btn
    end

    local function EnhanceButton(btn)
        if not IsValid(btn) then
            return
        end

        -- звук при наведении
        btn.OnCursorEntered = function(self)
            surface.PlaySound("netricsa/button_ssm.wav")
            self._hovered = true
        end

        btn.OnCursorExited = function(self)
            self._hovered = false
        end

        -- оборачиваем DoClick, чтобы всегда играл press
        local oldClick = btn.DoClick
        btn.DoClick = function(self, ...)
            surface.PlaySound("netricsa/button_ssm_press.wav")
            if oldClick then oldClick(self, ...) end
        end

        -- добавляем универсальную подсветку текста (только если нет кастомного Paint)
        if not btn._customPaint then
            local oldPaint = btn.Paint
            btn.Paint = function(self, w, h)
                local style = NetricsaStyle or STYLES.Revolution
                local col = self._hovered and Color(255,255,255) or style.color
                draw.SimpleText(self:GetText(), "NetricsaText", w/2, h/2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                if oldPaint and oldPaint ~= DButton.Paint then
                    oldPaint(self, w, h)
                end
            end
        end
    end

    local function NoBG(p)
        if not IsValid(p) then return end
        if p.SetPaintBackground then p:SetPaintBackground(false) end
        if p.SetDrawBackground then p:SetDrawBackground(false) end
        if p.SetPaintBorderEnabled then p:SetPaintBorderEnabled(false) end
    end

    local function SetAnimatedText(rt, text, step, speed)
        if not IsValid(rt) then return end
        rt:SetText("")
        local c = NetricsaStyle.color or Color(255, 255, 0)
        rt:InsertColorChange(c.r, c.g, c.b, c.a or 255)

        local i = 0
        step = step or 2
        speed = speed or 0.01
        timer.Remove("NetricsaTextAnim")
        timer.Create("NetricsaTextAnim", speed, math.ceil(#text / step), function()
            if not IsValid(rt) then return end

            i = i + step
            local part = utf8.sub(text, i - step, i - 1)
            rt:AppendText(part)

            if i >= utf8.len(text) then
                timer.Remove("NetricsaTextAnim")
            end
        end)
    end

    local function FitModel(ent, panel)
        if not IsValid(ent) then return end

        local mn, mx = ent:GetRenderBounds()
        local size = math.max(mx.x - mn.x, mx.y - mn.y, mx.z - mn.z)
        if size <= 0 then size = 50 end

        -- 🔧 динамическое масштабирование
        local scale
        if size > 250 then
            scale = 180 / size       -- крупные модели уменьшаем
        elseif size > 100 then
            scale = 1.2              -- обычные NPC - чуть крупнее
        elseif size > 60 then
            scale = 1.5              -- мелкие - побольше
        else
            scale = 80 / size        -- совсем крошечные - сильно увеличиваем
        end

        scale = math.Clamp(scale, 0.05, 3)
        ent:SetModelScale(scale, 0)

        -- ⚙️ пересчитываем центр после масштабирования
        local mn2, mx2 = ent:GetRenderBounds()
        local center = (mn2 + mx2) * 0.5
        local height = mx2.z - mn2.z

        -- 🔧 камера "сверху-сбоку" с учётом размера
        local baseDist = math.max(height * 1.8, 180) -- ближе для обычных NPC
        local camOffset = Vector(baseDist, baseDist * 0.5, baseDist * 0.35)
        local camPos = center + camOffset

        panel:SetCamPos(camPos)
        panel:SetLookAt(center)
        panel:SetFOV(35)
    end

    -- Приведение аргумента таба к "внутреннему" ключу: "maps"/"enemies"/"weapons"/...
    -- Нормализует аргумент таба: принимает либо "maps"/"enemies"/"weapons", либо локализованный текст L("tabs",...)
    local function TabKeyFromName(name)
        if not name then return nil end
        local s = tostring(name)

        -- если уже внутренний ключ - возвращаем сразу
        if s == "maps" or s == "enemies" or s == "weapons" or s == "tactical" or s == "statistics" then
            return s
        end

        -- соответствие локализованных названий → внутренние ключи
        local mapping = {}
        mapping[L("tabs","strategic")]  = "maps"      -- стратегические данные = карты
        mapping[L("tabs","enemies")]    = "enemies"
        mapping[L("tabs","weapons")]    = "weapons"
        mapping[L("tabs","tactical")]   = "tactical"
        mapping[L("tabs","statistics")] = "statistics"

        if mapping[s] then return mapping[s] end

        -- попытка по "вхождению" (на всякий случай, англ/рус)
        local low = string.lower(s)
        if low:find("map") or low:find("карта") or low:find("стратег") then return "maps" end
        if low:find("enemy") or low:find("враг") or low:find("враги") then return "enemies" end
        if low:find("weapon") or low:find("оруж") then return "weapons" end
        if low:find("tactic") or low:find("тактич") then return "tactical" end
        if low:find("stat") or low:find("стат") then return "statistics" end

        return nil
    end

    -- Expose functions
    NetricsaUtils = {
        CreateButton = CreateButton,
        EnhanceButton = EnhanceButton,
        NoBG = NoBG,
        SetAnimatedText = SetAnimatedText,
        FitModel = FitModel,
        TabKeyFromName = TabKeyFromName
    }
end