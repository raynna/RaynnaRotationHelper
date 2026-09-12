local TARGET_ID = "Raynna Rotation Helper"
local RECOMMENDATION_IDS = {
    [1] = TARGET_ID .. " - Next Action",
    [2] = TARGET_ID .. " - Next Action Alt",
    [3] = TARGET_ID .. " - Defensive Action",
    [4] = TARGET_ID .. " - Threat Action",
    [5] = TARGET_ID .. " - Interrupt Action",
    [6] = TARGET_ID .. " - Pet Action",
    [7] = TARGET_ID .. " - Utility Action",
}

local buttons = {}

local PET_CAST_MACROS = {
    [136] = "/cast Mend Pet",
    [883] = "/cast Call Pet 1",
    [982] = "/cast Revive Pet",
    [688] = "/cast Summon Imp",
    [691] = "/cast Summon Felhunter",
    [697] = "/cast Summon Voidwalker",
    [712] = "/cast Summon Succubus",
    [30146] = "/cast Summon Felguard",
    [31687] = "/cast Summon Water Elemental",
}

local function MacroTextForSpell(spellID, spellName)
    return PET_CAST_MACROS[spellID] or (spellName and ("/cast " .. spellName)) or nil
end
local function WeakAuraRegion(id)
    if WeakAuras and WeakAuras.GetRegion then
        local region = WeakAuras.GetRegion(id)
        if region then return region end
    end
    return _G["WeakAuras:" .. id]
end

local function EnsureButton(slot)
    if buttons[slot] then return buttons[slot] end
    local button = CreateFrame("Button", "RaynnaRotationHelperClick" .. slot, UIParent, "SecureActionButtonTemplate")
    button:RegisterForClicks("AnyUp", "AnyDown")
    button:SetFrameStrata("TOOLTIP")
    button:SetFrameLevel(10000)
    if button.SetToplevel then button:SetToplevel(true) end
    button:SetAttribute("type", "macro")
    button:SetAttribute("type1", "macro")
    button:SetAttribute("*type1", "macro")
    local tex = button:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints(button)
    tex:SetColorTexture(1, 1, 1, 0.001)
    button.RaynnaClickTexture = tex
    button:EnableMouse(true)
    button:SetScript("OnEnter", function(self)
        if GameTooltip and self.spellName then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.spellName)
            GameTooltip:AddLine("Click to cast", 0.7, 0.9, 1)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
    button:SetScript("PostClick", function(self, mouseButton)
        self.RaynnaLastClickAt = GetTime and GetTime() or 0
        self.RaynnaLastClickButton = mouseButton or "unknown"
    end)
    button:Hide()
    buttons[slot] = button
    return button
end

local function PositionButton(button, region)
    if not region or not region.GetWidth or not region.GetHeight or not region.GetCenter then return false end
    local width = region:GetWidth() or 0
    local height = region:GetHeight() or 0
    local x, y = region:GetCenter()
    if width <= 0 or height <= 0 or not x or not y then return false end
    local scale = 1
    if region.GetEffectiveScale and UIParent.GetEffectiveScale then
        scale = region:GetEffectiveScale() / UIParent:GetEffectiveScale()
    end
    button:ClearAllPoints()
    button:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x * scale, y * scale)
    button:SetSize(width, height)
    return true
end

local function UpdateClickButtons()
    if InCombatLockdown and InCombatLockdown() then
        return
    end
    if not _G.RaynnaRotationHelperGetRecommendation then
        return
    end
    for slot, id in pairs(RECOMMENDATION_IDS) do
        local button = EnsureButton(slot)
        local region = WeakAuraRegion(id)
        local spellID = _G.RaynnaRotationHelperGetRecommendation(slot)
        local spellName = spellID and GetSpellInfo and GetSpellInfo(spellID) or nil
        local regionShown = region and (not region.IsShown or region:IsShown())
        if regionShown and spellName and PositionButton(button, region) then
            local macroText = MacroTextForSpell(spellID, spellName)
            button:SetAttribute("type", "macro")
            button:SetAttribute("type1", "macro")
            button:SetAttribute("*type1", "macro")
            button:SetAttribute("macrotext", macroText)
            button:SetAttribute("macrotext1", macroText)
            button:SetAttribute("*macrotext1", macroText)
            button.spellID = spellID
            button.spellName = spellName
            button.macroText = macroText
            button:Show()
        else
            button:SetAttribute("macrotext", nil)
            button:SetAttribute("macrotext1", nil)
            button:SetAttribute("*macrotext1", nil)
            button.spellID = nil
            button.spellName = nil
            button.macroText = nil
            button:Hide()
        end
    end
end

local frame = CreateFrame("Frame")
frame.elapsed = 0
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:SetScript("OnEvent", function()
    C_Timer.After(0.2, UpdateClickButtons)
end)
frame:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.15 then return end
    self.elapsed = 0
    UpdateClickButtons()
end)
function _G.RaynnaRotationHelperGetClickDebug(slot)
    local button = buttons and buttons[slot]
    if not button then
        return "missing", "", "false"
    end
    local shown = button.IsShown and button:IsShown() or false
    local lastClick = button.RaynnaLastClickAt and string.format("%.1f", button.RaynnaLastClickAt) or "never"
    local clickButton = button.RaynnaLastClickButton or "none"
    return tostring(button.spellName or "none"), tostring(button.macroText or "none"), tostring(shown) .. " lastClick=" .. lastClick .. " button=" .. tostring(clickButton)
end