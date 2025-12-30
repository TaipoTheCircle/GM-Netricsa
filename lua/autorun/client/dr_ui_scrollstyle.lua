-- dr_ui_scrollstyle.lua
-- Автоматическое оформление скроллбаров под цвет текущего стиля Netricsa

local scrollbar_bg = Color(15, 15, 15, 180) -- общий фон позади ползунка

local function GetStyleColor()
    -- если стиль ещё не инициализирован - возвращаем дефолтный
    if not NetricsaStyle or not NetricsaStyle.color then
        return Color(0, 255, 0)
    end
    return NetricsaStyle.color
end

hook.Add("Think", "DR_StyleScrollbars_Dynamic", function()
    for _, pnl in ipairs(vgui.GetWorldPanel():GetChildren()) do
        if pnl:GetClassName() == "DScrollPanel" and not pnl._drStyled then
            local sbar = pnl:GetVBar()
            if IsValid(sbar) then
                -- фон всего скроллбара
                function sbar:Paint(w, h)
                    draw.RoundedBox(4, 0, 0, w, h, scrollbar_bg)
                end

                -- сам ползунок
                function sbar.btnGrip:Paint(w, h)
                    local col = GetStyleColor()
                    if self:IsHovered() then
                        col = Color(
                            math.min(col.r + 40, 255),
                            math.min(col.g + 40, 255),
                            math.min(col.b + 40, 255),
                            230
                        )
                    end
                    draw.RoundedBox(4, 0, 0, w, h, col)
                end

                -- скрываем стрелочки
                function sbar.btnUp:Paint() end
                function sbar.btnDown:Paint() end
            end
            pnl._drStyled = true
        end
    end
end)

-- если стиль меняется во время работы - обновляем все панели
hook.Add("PostRenderVGUI", "DR_RefreshScrollbarColor", function()
    if not NetricsaStyle or not NetricsaStyle.color then return end

    for _, pnl in ipairs(vgui.GetWorldPanel():GetChildren()) do
        if pnl:GetClassName() == "DScrollPanel" and pnl._drStyled then
            local sbar = pnl:GetVBar()
            if IsValid(sbar) and IsValid(sbar.btnGrip) then
                -- динамическое обновление цвета (без пересоздания)
                sbar.btnGrip.Paint = function(self, w, h)
                    local col = GetStyleColor()
                    if self:IsHovered() then
                        col = Color(
                            math.min(col.r + 40, 255),
                            math.min(col.g + 40, 255),
                            math.min(col.b + 40, 255),
                            230
                        )
                    end
                    draw.RoundedBox(4, 0, 0, w, h, col)
                end
            end
        end
    end
end)
