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
    button:RegisterForClicks("AnyUp")
    button:SetFrameStrata("DIALOG")
    button:SetFrameLevel(100)
    button:SetAttribute("type", "spell")
    button:EnableMouse(true)
    button:Hide()
    buttons[slot] = button
    return button
end

local function PositionButton(button, region)
    if not region or not region.GetWidth or not region.GetHeight then return false end
    local width = region:GetWidth() or 0
    local height = region:GetHeight() or 0
    if width <= 0 or height <= 0 then return false end
    button:ClearAllPoints()
    button:SetPoint("CENTER", region, "CENTER", 0, 0)
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
            button:SetAttribute("spell", spellName)
            button:Show()
        else
            button:SetAttribute("spell", nil)
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