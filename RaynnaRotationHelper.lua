local LEGACY_FERAL_ID = "Raynna's Feral Druid Rotation Helper"
local LEGACY_CHILD_ID = LEGACY_FERAL_ID .. " - Next Action"
local LEGACY_ALT_CHILD_ID = LEGACY_FERAL_ID .. " - Next Action Alt"
local TARGET_ID = "Raynna Rotation Helper"
local CHILD_ID = TARGET_ID .. " - Next Action"
local ALT_CHILD_ID = TARGET_ID .. " - Next Action Alt"
local DEFENSIVE_CHILD_ID = TARGET_ID .. " - Defensive Action"
local THREAT_CHILD_ID = TARGET_ID .. " - Threat Action"
local INTERRUPT_CHILD_ID = TARGET_ID .. " - Interrupt Action"
local PET_CHILD_ID = TARGET_ID .. " - Pet Action"
local UTILITY_CHILD_ID = TARGET_ID .. " - Utility Action"
local GROUND_AOE_INDICATOR_IDS = {
    BAD = TARGET_ID .. " - Ground AoE Bad",
    OK = TARGET_ID .. " - Ground AoE OK",
    GOOD = TARGET_ID .. " - Ground AoE Good",
    BEST = TARGET_ID .. " - Ground AoE Best",
}
local GROUND_AOE_QUALITIES = { "BAD", "OK", "GOOD", "BEST" }
local GROUND_AOE_COLORS = {
    BAD = { 0.95, 0.12, 0.08, 1 },
    OK = { 1, 0.45, 0.08, 1 },
    GOOD = { 1, 0.88, 0.12, 1 },
    BEST = { 0.12, 0.9, 0.28, 1 },
}
local OLD_RESOURCE_GROUP_IDS = { TARGET_ID .. " - Resource Pips", TARGET_ID .. " - Druid Combo points" }
local RESOURCE_GROUP_ID = "Raynna's Pips"
local RESOURCE_IDS = {}
local RESOURCE_OUTLINE_IDS = {}
local RESOURCE_GCD_IDS = {}
for i = 1, 5 do
    RESOURCE_IDS[i] = TARGET_ID .. " - Pip " .. i
    RESOURCE_OUTLINE_IDS[i] = TARGET_ID .. " - Pip " .. i .. " BlackOutline"
    RESOURCE_GCD_IDS[i] = TARGET_ID .. " - Pip " .. i .. " GCD"
end
local ACTION_UIDS = {
    [1] = "raynna-rotation-next-action",
    [2] = "raynna-rotation-next-action-alt",
    [3] = "raynna-rotation-defensive-action",
    [4] = "raynna-rotation-threat-action",
    [5] = "raynna-rotation-interrupt-action",
    [6] = "raynna-rotation-pet-action",
    [7] = "raynna-rotation-utility-action",
}
local GROUND_AOE_INDICATOR_UIDS = {
    BAD = "raynna-rotation-ground-aoe-bad",
    OK = "raynna-rotation-ground-aoe-ok",
    GOOD = "raynna-rotation-ground-aoe-good",
    BEST = "raynna-rotation-ground-aoe-best",
}

local ADDON_NAME = "Raynna Rotation Helper"
local MODE_AUTO = "auto"
local MODE_BOSS = "boss"
local MODE_TRASH = "trash"
local PET_AUTO = "auto"
local PET_DUNGEON = "dungeon"
local PET_SOLO = "solo"
local PET_OFF = "off"

local function GetDB()
    RaynnaRotationHelperDB = RaynnaRotationHelperDB or {}
    if RaynnaRotationHelperDB.mode ~= MODE_BOSS and RaynnaRotationHelperDB.mode ~= MODE_TRASH then
        RaynnaRotationHelperDB.mode = MODE_AUTO
    end
    if RaynnaRotationHelperDB.warlockPetMode ~= PET_DUNGEON and RaynnaRotationHelperDB.warlockPetMode ~= PET_SOLO and RaynnaRotationHelperDB.warlockPetMode ~= PET_OFF then
        RaynnaRotationHelperDB.warlockPetMode = PET_AUTO
    end
    if RaynnaRotationHelperDB.actionBarGlow == nil then
        RaynnaRotationHelperDB.actionBarGlow = true
    end
    if RaynnaRotationHelperDB.groundAoeIndicator == nil then
        RaynnaRotationHelperDB.groundAoeIndicator = true
    end
    if RaynnaRotationHelperDB.healFrameGlow == nil then
        RaynnaRotationHelperDB.healFrameGlow = true
    end
    return RaynnaRotationHelperDB
end
local function GetMode()
    return GetDB().mode or MODE_AUTO
end

local function SetMode(mode)
    if mode ~= MODE_BOSS and mode ~= MODE_TRASH then
        mode = MODE_AUTO
    end
    GetDB().mode = mode
    return mode
end

local function GetWarlockPetMode()
    return GetDB().warlockPetMode or PET_AUTO
end

local function SetWarlockPetMode(mode)
    if mode ~= PET_DUNGEON and mode ~= PET_SOLO and mode ~= PET_OFF then
        mode = PET_AUTO
    end
    GetDB().warlockPetMode = mode
    return mode
end

local function SettingEnabled(key)
    return GetDB()[key] ~= false
end

local function SetSettingEnabled(key, enabled)
    GetDB()[key] = enabled and true or false
    return GetDB()[key]
end

local PRIMARY_NEXT_ACTION_SOURCE = [=[
function(event, ...)
    if not _G.RaynnaRotationHelperGetRecommendation then
        aura_env.recommendedSpellID = nil
        return false
    end
    local spellID = _G.RaynnaRotationHelperGetRecommendation(1)
    aura_env.recommendedSpellID = spellID
    return spellID ~= nil
end
]=]

local ALT_NEXT_ACTION_SOURCE = [=[
function(event, ...)
    if not _G.RaynnaRotationHelperGetRecommendation then
        aura_env.recommendedSpellID = nil
        return false
    end
    local spellID = _G.RaynnaRotationHelperGetRecommendation(2)
    aura_env.recommendedSpellID = spellID
    return spellID ~= nil
end
]=]

local DEFENSIVE_NEXT_ACTION_SOURCE = [=[
function(event, ...)
    if not _G.RaynnaRotationHelperGetRecommendation then
        aura_env.recommendedSpellID = nil
        return false
    end
    local spellID = _G.RaynnaRotationHelperGetRecommendation(3)
    aura_env.recommendedSpellID = spellID
    return spellID ~= nil
end
]=]

local THREAT_ACTION_SOURCE = [=[
function(event, ...)
    if not _G.RaynnaRotationHelperGetRecommendation then
        aura_env.recommendedSpellID = nil
        return false
    end
    local spellID = _G.RaynnaRotationHelperGetRecommendation(4)
    aura_env.recommendedSpellID = spellID
    return spellID ~= nil
end
]=]

local INTERRUPT_ACTION_SOURCE = [=[
function(event, ...)
    if not _G.RaynnaRotationHelperGetRecommendation then
        aura_env.recommendedSpellID = nil
        return false
    end
    local spellID = _G.RaynnaRotationHelperGetRecommendation(5)
    aura_env.recommendedSpellID = spellID
    return spellID ~= nil
end
]=]

local PET_ACTION_SOURCE = [=[
function(event, ...)
    if not _G.RaynnaRotationHelperGetRecommendation then
        aura_env.recommendedSpellID = nil
        return false
    end
    local spellID = _G.RaynnaRotationHelperGetRecommendation(6)
    aura_env.recommendedSpellID = spellID
    return spellID ~= nil
end
]=]


local UTILITY_ACTION_SOURCE = [=[
function(event, ...)
    if not _G.RaynnaRotationHelperGetRecommendation then
        aura_env.recommendedSpellID = nil
        return false
    end
    local spellID = _G.RaynnaRotationHelperGetRecommendation(7)
    aura_env.recommendedSpellID = spellID
    return spellID ~= nil
end
]=]


local GROUND_AOE_TRIGGER_TEMPLATE = [=[
function(event, ...)
    if not _G.RaynnaRotationHelperGetGroundAoeQuality then
        return false
    end
    local quality = _G.RaynnaRotationHelperGetGroundAoeQuality()
    return quality == "%%QUALITY%%"
end
]=]

local GROUND_AOE_NAME_SOURCE = [=[
function()
    if not _G.RaynnaRotationHelperGetGroundAoeLabel then
        return ""
    end
    return _G.RaynnaRotationHelperGetGroundAoeLabel() or ""
end
]=]
local GCD_DURATION_SOURCE = [=[
function()
    local start, duration, enabled = GetSpellCooldown(61304)
    start = start or 0
    duration = duration or 0
    if enabled == 0 or start <= 0 or duration <= 0 then
        return 0, math.huge
    end
    return duration, start + duration
end
]=]
local ICON_SOURCE = [=[
function()
    local spellID = aura_env.recommendedSpellID or 33876
    local _, _, icon = GetSpellInfo(spellID)
    return icon
end
]=]

local NAME_SOURCE = [=[
function()
    local spellID = aura_env.recommendedSpellID
    return spellID and GetSpellInfo(spellID) or ""
end
]=]

local KEYBIND_SOURCE = [=[
function()
    local spellID = aura_env.recommendedSpellID
    if not spellID then
        return ""
    end
    if _G.RaynnaRotationHelperGetSpellLabel then
        return _G.RaynnaRotationHelperGetSpellLabel(spellID) or ""
    end
    if _G.RaynnaRotationHelperGetSpellKeybind then
        return _G.RaynnaRotationHelperGetSpellKeybind(spellID) or ""
    end
    return ""
end
]=]
local RESOURCE_TRIGGER_TEMPLATE = [=[
function(event, ...)
    if not _G.RaynnaRotationHelperGetResourceInfo then
        return false
    end
    local count, maxCount = _G.RaynnaRotationHelperGetResourceInfo()
    return maxCount and maxCount >= %%INDEX%% and count and count >= %%INDEX%%
end
]=]

local RESOURCE_SLOT_TRIGGER_TEMPLATE = [=[
function(event, ...)
    if not _G.RaynnaRotationHelperGetResourceInfo then
        return false
    end
    local _, maxCount = _G.RaynnaRotationHelperGetResourceInfo()
    return maxCount and maxCount >= %%INDEX%%
end
]=]

local RESOURCE_ICON_SOURCE = [=[
function()
    if not _G.RaynnaRotationHelperGetResourceInfo then
        return 134400
    end
    local _, _, _, icon = _G.RaynnaRotationHelperGetResourceInfo()
    return icon or 134400
end
]=]

local function SafeFindAuraBySpellID(unit, spellID, filter, caster)
    if not UnitAura then
        return nil
    end
    local spellName = GetSpellInfo and GetSpellInfo(spellID) or nil
    for i = 1, 40 do
        local name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, auraSpellID = UnitAura(unit, i, filter)
        if not name then
            return nil
        end
        if (auraSpellID == spellID or (spellName and name == spellName)) and (not caster or source == caster) then
            return name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, auraSpellID
        end
    end
    return nil
end

local function SafeUnitBuff(unit, spellID)
    if WA_GetUnitBuff then
        local name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, auraSpellID = WA_GetUnitBuff(unit, spellID)
        if name then
            return name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, auraSpellID
        end
    end
    return SafeFindAuraBySpellID(unit, spellID, "HELPFUL")
end

local function SafeUnitDebuff(unit, spellID, caster)
    if WA_GetUnitDebuff then
        local name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, auraSpellID = WA_GetUnitDebuff(unit, spellID, caster)
        if name then
            return name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, auraSpellID
        end
    end
    return SafeFindAuraBySpellID(unit, spellID, "HARMFUL", caster)
end

local function SpellKnown(spellID)
    if IsPlayerSpell and IsPlayerSpell(spellID) then
        return true
    end
    if IsSpellKnown and IsSpellKnown(spellID) then
        return true
    end
    if not IsPlayerSpell and not IsSpellKnown then
        return GetSpellInfo(spellID) ~= nil
    end
    return false
end

local GROUND_TARGET_SPELLS = {
    [10] = true, -- Blizzard
    [2120] = true, -- Flamestrike
    [30283] = true, -- Shadowfury
    [43265] = true, -- Death and Decay
    [5740] = true, -- Rain of Fire
    [61882] = true, -- Earthquake
    [82691] = true, -- Ring of Frost area
    [102793] = true, -- Ursol's Vortex
    [113724] = true, -- Ring of Frost
    [114158] = true, -- Light's Hammer
    [116844] = true, -- Ring of Peace
}

local GROUND_TARGET_DURATIONS = {
    [10] = 8,
    [2120] = 8,
    [30283] = 3,
    [43265] = 10,
    [5740] = 8,
    [61882] = 10,
    [82691] = 10,
    [102793] = 10,
    [113724] = 10,
    [114158] = 16,
    [116844] = 8,
}

local groundTargetEffectUntil = {}
local activeGroundTargetSpellID
local activeGroundTargetSpellAt = 0

local function IsGroundTargetSpell(spellID)
    return spellID and GROUND_TARGET_SPELLS[spellID] or false
end

local function RememberGroundTargetSpell(spellID)
    if IsGroundTargetSpell(spellID) then
        activeGroundTargetSpellID = spellID
        activeGroundTargetSpellAt = GetTime()
    end
end

local function GroundTargetSpellIDFromName(spellName)
    if not spellName then
        return nil
    end
    for spellID in pairs(GROUND_TARGET_SPELLS) do
        local name = GetSpellInfo(spellID)
        if name and name == spellName then
            return spellID
        end
    end
    return nil
end

local function ActiveGroundTargetSpellID()
    if IsCurrentSpell then
        for spellID in pairs(GROUND_TARGET_SPELLS) do
            if IsCurrentSpell(spellID) then
                RememberGroundTargetSpell(spellID)
                return spellID
            end
        end
    end
    if SpellIsTargeting and SpellIsTargeting() and activeGroundTargetSpellID and GetTime() - activeGroundTargetSpellAt <= 12 then
        return activeGroundTargetSpellID
    end
    return nil
end

local function IsGroundTargetingSpell(spellID)
    if not IsGroundTargetSpell(spellID) then
        return false
    end
    if IsCurrentSpell and IsCurrentSpell(spellID) then
        RememberGroundTargetSpell(spellID)
        return true
    end
    return SpellIsTargeting and SpellIsTargeting() and ActiveGroundTargetSpellID() == spellID or false
end

local function GroundTargetEffectRemaining(spellID)
    local expires = groundTargetEffectUntil[spellID] or 0
    return math.max(0, expires - GetTime())
end

local function MarkGroundTargetSpellCast(spellID)
    if IsGroundTargetSpell(spellID) then
        RememberGroundTargetSpell(spellID)
        groundTargetEffectUntil[spellID] = GetTime() + (GROUND_TARGET_DURATIONS[spellID] or 8)
    end
end

local function ExtractGroundTargetSpellID(...)
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if type(value) == "number" and IsGroundTargetSpell(value) then
            return value
        end
    end
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if type(value) == "string" then
            for spellID in pairs(GROUND_TARGET_SPELLS) do
                local name = GetSpellInfo(spellID)
                if name and value == name then
                    return spellID
                end
            end
        end
    end
    return nil
end

local function TrackGroundTargetSpellCast(unit, ...)
    if unit ~= "player" then
        return
    end
    local spellID = ExtractGroundTargetSpellID(...)
    if spellID then
        MarkGroundTargetSpellCast(spellID)
    end
end

local groundTargetHooksInstalled = false
local function SafeHookGlobal(name, handler)
    if hooksecurefunc and _G[name] then
        pcall(hooksecurefunc, name, handler)
    end
end

local function InstallGroundTargetHooks()
    if groundTargetHooksInstalled then
        return
    end
    groundTargetHooksInstalled = true
    SafeHookGlobal("UseAction", function(slot)
        if not GetActionInfo then
            return
        end
        local actionType, id = GetActionInfo(slot)
        if actionType == "spell" then
            RememberGroundTargetSpell(id)
        elseif actionType == "macro" and GetMacroSpell then
            local spellName, _, spellID = GetMacroSpell(id)
            RememberGroundTargetSpell(spellID or GroundTargetSpellIDFromName(spellName))
        end
    end)
    SafeHookGlobal("CastSpellByID", function(spellID)
        RememberGroundTargetSpell(spellID)
    end)
    SafeHookGlobal("CastSpellByName", function(spellName)
        RememberGroundTargetSpell(GroundTargetSpellIDFromName(spellName))
    end)
    SafeHookGlobal("CastSpell", function(spellBookID, bookType)
        if GetSpellBookItemInfo then
            local _, spellID = GetSpellBookItemInfo(spellBookID, bookType)
            RememberGroundTargetSpell(spellID)
        end
    end)
end
local RECENT_ATTACKER_WINDOW = 6
local recentHostileAttackers = {}
local recentMeleeAttackers = {}

local function CleanupRecentHostileAttackers(now)
    for guid, timestamp in pairs(recentHostileAttackers) do
        if now - timestamp > RECENT_ATTACKER_WINDOW then
            recentHostileAttackers[guid] = nil
        end
    end
    for guid, timestamp in pairs(recentMeleeAttackers) do
        if now - timestamp > RECENT_ATTACKER_WINDOW then
            recentMeleeAttackers[guid] = nil
        end
    end
end

local function AddRecentHostileAttacker(guid, isMelee)
    if guid then
        local now = GetTime()
        recentHostileAttackers[guid] = now
        if isMelee then
            recentMeleeAttackers[guid] = now
        end
    end
end

local function CountRecentHostileAttackers(now)
    CleanupRecentHostileAttackers(now or GetTime())
    local count = 0
    for _ in pairs(recentHostileAttackers) do
        count = count + 1
    end
    return count
end

local function CountRecentMeleeAttackers(now)
    CleanupRecentHostileAttackers(now or GetTime())
    local count = 0
    for _ in pairs(recentMeleeAttackers) do
        count = count + 1
    end
    return count
end

local hostileCombatLogEvents = {
    SWING_DAMAGE = true,
    SWING_MISSED = true,
    RANGE_DAMAGE = true,
    RANGE_MISSED = true,
    SPELL_DAMAGE = true,
    SPELL_MISSED = true,
    SPELL_PERIODIC_DAMAGE = true,
    SPELL_PERIODIC_MISSED = true,
}

local function TrackCombatLogHostileAttacker(...)
    local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID
    if CombatLogGetCurrentEventInfo then
        timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID = CombatLogGetCurrentEventInfo()
    else
        timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID = ...
    end
    if not hostileCombatLogEvents[subevent] then
        return
    end
    local playerGUID = UnitGUID("player")
    if playerGUID and destGUID == playerGUID and sourceGUID and sourceGUID ~= playerGUID then
        AddRecentHostileAttacker(sourceGUID, subevent == "SWING_DAMAGE" or subevent == "SWING_MISSED")
    end
end
local currentTargetGUID = nil
local currentTargetStart = 0
local lastActiveModuleKey = nil
local lastActiveModuleReason = "none"
local lastRecommendationReasons = {}
local SPEC_INFERENCE = {
    DEATHKNIGHT = {
        { 1, 55050, 48982, 55233 },
        { 2, 49184, 49020, 51271 },
        { 3, 55090, 63560, 85948 },
    },
    DRUID = {
        { 1, 78674, 48505, 2912 },
        { 2, 5221, 1079, 1822 },
        { 3, 33917, 33745, 77758 },
        { 4, 33763, 18562, 48438 },
    },
    HUNTER = {
        { 1, 34026, 19574, 120679 },
        { 2, 19434, 53209, 120360 },
        { 3, 53301, 3674, 77767 },
    },
    MAGE = {
        { 1, 30451, 44425, 12051 },
        { 2, 11366, 11129, 108853 },
        { 3, 31687, 84714, 30455 },
    },
    MONK = {
        { 1, 121253, 115295, 115069 },
        { 2, 119611, 124682, 115151 },
        { 3, 113656, 107428, 100787 },
    },
    PALADIN = {
        { 1, 20473, 53563, 82326 },
        { 2, 31935, 53600, 53595 },
        { 3, 85256, 53385, 879 },
    },
    PRIEST = {
        { 1, 47540, 33206, 62618 },
        { 2, 34861, 88625, 81206 },
        { 3, 15473, 15407, 8092 },
    },
    ROGUE = {
        { 1, 1329, 32645, 79140 },
        { 2, 84617, 51690, 13877 },
        { 3, 51713, 16511, 53 },
    },
    SHAMAN = {
        { 1, 51505, 61882, 117014 },
        { 2, 17364, 60103, 51533 },
        { 3, 61295, 974, 73920 },
    },
    WARLOCK = {
        { 1, 103103, 30108, 48181 },
        { 2, 103958, 105174, 104316 },
        { 3, 116858, 17962, 108683 },
    },
    WARRIOR = {
        { 1, 12294, 86346, 56636 },
        { 2, 23881, 85288, 46917 },
        { 3, 23922, 20243, 12975 },
    },
}

local function InferSpecialization(class)
    if GetSpecialization then
        local spec = GetSpecialization()
        if spec then
            return spec
        end
    end
    if GetPrimaryTalentTree then
        local spec = GetPrimaryTalentTree()
        if spec then
            return spec
        end
    end

    local rules = SPEC_INFERENCE[class]
    if not rules then
        return nil
    end
    for _, rule in ipairs(rules) do
        for i = 2, #rule do
            if SpellKnown(rule[i]) then
                return rule[1]
            end
        end
    end
    return nil
end
local function BuildContext()
    local now = GetTime()
    local energyType = Enum and Enum.PowerType and Enum.PowerType.Energy or 3

    local targetGUID = UnitGUID and UnitGUID("target") or nil
    if targetGUID ~= currentTargetGUID then
        currentTargetGUID = targetGUID
        currentTargetStart = now
    end

    local class = select(2, UnitClass("player"))
    local ctx = {
        now = now,
        class = class,
        spec = InferSpecialization(class),
        energyType = energyType,
        targetGUID = targetGUID,
        mode = GetMode(),
    }

    function ctx.targetMode()
        return ctx.mode or MODE_AUTO
    end

    function ctx.targetAge()
        return targetGUID and math.max(0, now - (currentTargetStart or now)) or 0
    end

    function ctx.isOpener(seconds)
        return ctx.hasAttackTarget and ctx.hasAttackTarget() and ctx.targetAge() <= (seconds or 8)
    end

    function ctx.known(spellID)
        return SpellKnown(spellID)
    end

    function ctx.ready(spellID, powerCost, powerType)
        if not SpellKnown(spellID) then
            return false
        end
        local usable = IsUsableSpell(spellID)
        if not usable then
            return false
        end
        if powerCost then
            local pType = powerType or energyType
            if (UnitPower("player", pType) or 0) < powerCost then
                return false
            end
        end
        local start, duration, enabled = GetSpellCooldown(spellID)
        duration = duration or 0
        start = start or 0
        if enabled == 0 then
            return false
        end
        return duration <= 1.5 or start + duration - now <= 0.1
    end

    function ctx.cooldownRemaining(spellID)
        if not SpellKnown(spellID) then
            return nil
        end
        local start, duration, enabled = GetSpellCooldown(spellID)
        duration = duration or 0
        start = start or 0
        if enabled == 0 then
            return nil
        end
        if duration <= 1.5 then
            return 0
        end
        return math.max(0, start + duration - now)
    end

    function ctx.cooldownReady(spellID, powerCost, powerType)
        if not SpellKnown(spellID) then
            return false
        end
        if powerCost then
            local pType = powerType or energyType
            if (UnitPower("player", pType) or 0) < powerCost then
                return false
            end
        end
        local start, duration, enabled = GetSpellCooldown(spellID)
        duration = duration or 0
        start = start or 0
        if enabled == 0 then
            return false
        end
        return duration <= 1.5 or start + duration - now <= 0.1
    end

    function ctx.buffRem(unit, ...)
        local best = 0
        for i = 1, select("#", ...) do
            local spellID = select(i, ...)
            local name, _, _, _, _, exp = SafeUnitBuff(unit, spellID)
            if name then
                if exp == 0 then
                    return math.huge
                end
                best = math.max(best, (exp or 0) - now)
            end
        end
        return best
    end

    function ctx.debuffRem(unit, spellID, ownOnly)
        local name, _, _, _, _, exp = SafeUnitDebuff(unit, spellID, ownOnly and "player" or nil)
        if not name then
            return 0
        end
        if exp == 0 then
            return math.huge
        end
        return (exp or 0) - now
    end

    function ctx.debuffAnyRem(unit, ownOnly, ...)
        local best = 0
        for i = 1, select("#", ...) do
            best = math.max(best, ctx.debuffRem(unit, select(i, ...), ownOnly))
        end
        return best
    end

    function ctx.inRange(spellID)
        local name = GetSpellInfo(spellID)
        if not name then
            ctx.rangeDebug = "spell missing"
            return false
        end
        local range = IsSpellInRange(name, "target")
        if range == 0 then
            ctx.rangeDebug = name .. " out of range"
            return false
        end
        if range == 1 then
            ctx.rangeDebug = name .. " in range"
            return true
        end
        ctx.rangeDebug = name .. " range unknown"
        return true
    end

    function ctx.targetIsBoss()
        if ctx.targetMode and ctx.targetMode() == MODE_BOSS then
            return ctx.hasAttackTarget and ctx.hasAttackTarget()
        end
        if ctx.targetMode and ctx.targetMode() == MODE_TRASH then
            return false
        end
        local classification = UnitClassification and UnitClassification("target") or ""
        return UnitLevel("target") == -1 or classification == "worldboss"
    end

    function ctx.behindTarget()
        if not UnitPosition or not UnitFacing then
            ctx.behindDebug = "no UnitPosition/UnitFacing"
            return nil
        end
        local px, py, pMap = UnitPosition("player")
        local tx, ty, tMap = UnitPosition("target")
        local facing = UnitFacing("target")
        if not px or not py or not tx or not ty or pMap ~= tMap or not facing then
            ctx.behindDebug = "missing position/facing"
            return nil
        end
        local function atan2(y, x)
            if math.atan2 then return math.atan2(y, x) end
            if x > 0 then return math.atan(y / x) end
            if x < 0 and y >= 0 then return math.atan(y / x) + math.pi end
            if x < 0 and y < 0 then return math.atan(y / x) - math.pi end
            if y > 0 then return math.pi / 2 end
            if y < 0 then return -math.pi / 2 end
            return 0
        end
        local function normDiff(a, b)
            return math.abs(atan2(math.sin(a - b), math.cos(a - b)))
        end
        local angleXY = atan2(py - ty, px - tx)
        local angleYX = atan2(px - tx, py - ty)
        local diffXY = normDiff(angleXY, facing)
        local diffYX = normDiff(angleYX, facing)
        local behind = diffXY > 1.55 or diffYX > 1.55
        ctx.behindDebug = string.format("behind=%s diffXY=%.2f diffYX=%.2f facing=%.2f", tostring(behind), diffXY, diffYX, facing)
        return behind
    end

    function ctx.targetHpPct()
        local maxHealth = UnitHealthMax("target") or 0
        if maxHealth <= 0 then
            return 100
        end
        return ((UnitHealth("target") or 0) / maxHealth) * 100
    end

    function ctx.hasBuff(spellID)
        return ctx.buffRem("player", spellID) > 0
    end

    function ctx.buffStacks(unit, spellID)
        local name, _, count = SafeUnitBuff(unit, spellID)
        if not name then
            return 0
        end
        return count or 0
    end

    function ctx.arcaneChargeBuffStacks()
        local function auraCount(unit, spellID, filter)
            if not UnitAura or not UnitExists(unit) then
                return 0
            end
            local name, _, count = SafeFindAuraBySpellID(unit, spellID, filter)
            if name then
                return count and count > 0 and count or 1
            end
            return 0
        end
        local knownStacks = math.max(
            auraCount("player", 36032, "HELPFUL"),
            auraCount("player", 36033, "HELPFUL"),
            auraCount("player", 36032, "HARMFUL"),
            auraCount("player", 36033, "HARMFUL"),
            auraCount("target", 36032, "HELPFUL"),
            auraCount("target", 36033, "HELPFUL"),
            auraCount("target", 36032, "HARMFUL"),
            auraCount("target", 36033, "HARMFUL")
        )
        if knownStacks > 0 or not UnitAura then
            return knownStacks
        end
        local function scanByName(unit, filter)
            if not UnitExists(unit) then
                return 0
            end
            for i = 1, 40 do
                local name, _, count, _, _, _, _, _, _, auraSpellID = UnitAura(unit, i, filter)
                if not name then
                    return 0
                end
                local lower = name:lower()
                if auraSpellID == 36032 or auraSpellID == 36033 or lower == "arcane charge" or lower == "arcane charges" then
                    return count and count > 0 and count or 1
                end
            end
            return 0
        end
        return math.max(
            scanByName("player", "HELPFUL"),
            scanByName("player", "HARMFUL"),
            scanByName("target", "HELPFUL"),
            scanByName("target", "HARMFUL")
        )
    end
    function ctx.arcaneChargeRemaining()
        if not UnitAura then
            return nil
        end
        local best = 0
        local function scan(unit, filter)
            if not UnitExists(unit) then
                return
            end
            for i = 1, 40 do
                local name, _, _, _, _, expirationTime, _, _, _, auraSpellID = UnitAura(unit, i, filter)
                if not name then
                    return
                end
                local lower = name:lower()
                if auraSpellID == 36032 or auraSpellID == 36033 or lower == "arcane charge" or lower == "arcane charges" then
                    if expirationTime == 0 then
                        best = math.huge
                    elseif expirationTime and expirationTime > 0 then
                        best = math.max(best, expirationTime - now)
                    end
                end
            end
        end
        scan("player", "HELPFUL")
        scan("player", "HARMFUL")
        scan("target", "HELPFUL")
        scan("target", "HARMFUL")
        return best > 0 and best or nil
    end
    function ctx.arcaneCharges()
        local buffCharges = ctx.arcaneChargeBuffStacks()
        local powerType = SPELL_POWER_ARCANE_CHARGES or (Enum and Enum.PowerType and Enum.PowerType.ArcaneCharges) or 16
        local powerCharges = UnitPower and UnitPower("player", powerType) or 0
        return math.max(buffCharges or 0, powerCharges or 0)
    end

    function ctx.arcaneChargesMax()
        local powerType = SPELL_POWER_ARCANE_CHARGES or (Enum and Enum.PowerType and Enum.PowerType.ArcaneCharges) or 16
        local powerMax = UnitPowerMax and UnitPowerMax("player", powerType) or 0
        return math.max(powerMax or 0, 4)
    end

    ctx.focusType = Enum and Enum.PowerType and Enum.PowerType.Focus or 2
    ctx.rageType = Enum and Enum.PowerType and Enum.PowerType.Rage or 1
    ctx.runicPowerType = SPELL_POWER_RUNIC_POWER or (Enum and Enum.PowerType and Enum.PowerType.RunicPower) or 6
    ctx.holyPowerType = SPELL_POWER_HOLY_POWER or (Enum and Enum.PowerType and Enum.PowerType.HolyPower) or 9
    ctx.eclipseType = SPELL_POWER_ECLIPSE or (Enum and Enum.PowerType and Enum.PowerType.Eclipse) or 8
    ctx.chiType = SPELL_POWER_CHI or (Enum and Enum.PowerType and Enum.PowerType.Chi) or 12
    ctx.shadowOrbType = SPELL_POWER_SHADOW_ORBS or (Enum and Enum.PowerType and Enum.PowerType.ShadowOrbs) or 13
    ctx.soulShardType = SPELL_POWER_SOUL_SHARDS or (Enum and Enum.PowerType and Enum.PowerType.SoulShards) or 7
    ctx.burningEmberType = SPELL_POWER_BURNING_EMBERS or (Enum and Enum.PowerType and Enum.PowerType.BurningEmbers) or 14
    ctx.demonicFuryType = SPELL_POWER_DEMONIC_FURY or (Enum and Enum.PowerType and Enum.PowerType.DemonicFury) or 15

    function ctx.power(powerType)
        return UnitPower and UnitPower("player", powerType) or 0
    end

    function ctx.powerMax(powerType)
        return UnitPowerMax and UnitPowerMax("player", powerType) or 0
    end

    function ctx.manaPct()
        local maxMana = ctx.powerMax(0)
        if maxMana <= 0 then
            return 100
        end
        return (ctx.power(0) / maxMana) * 100
    end

    function ctx.holyPower()
        return ctx.power(ctx.holyPowerType)
    end

    function ctx.holyPowerMax()
        return math.max(ctx.powerMax(ctx.holyPowerType), 5)
    end

    function ctx.chi()
        return ctx.power(ctx.chiType)
    end

    function ctx.chiMax()
        return math.max(ctx.powerMax(ctx.chiType), 4)
    end

    function ctx.shadowOrbs()
        return ctx.power(ctx.shadowOrbType)
    end

    function ctx.soulShards()
        return ctx.power(ctx.soulShardType)
    end

    function ctx.burningEmbersRaw()
        return ctx.power(ctx.burningEmberType)
    end

    function ctx.burningEmbers()
        local raw = ctx.burningEmbersRaw()
        local maxRaw = ctx.powerMax(ctx.burningEmberType)
        if maxRaw and maxRaw > 4 then
            return raw / 10
        end
        return raw
    end

    function ctx.burningEmbersMax()
        local maxRaw = ctx.powerMax(ctx.burningEmberType)
        if maxRaw and maxRaw > 4 then
            return math.max(maxRaw / 10, 4)
        end
        return math.max(maxRaw or 0, 4)
    end

    function ctx.demonicFury()
        return ctx.power(ctx.demonicFuryType)
    end

    function ctx.demonicFuryMax()
        return math.max(ctx.powerMax(ctx.demonicFuryType), 1000)
    end

    function ctx.inMetamorphosis()
        return ctx.buffRem("player", 103958) > 0 or ctx.buffRem("player", 109151) > 0
    end

    function ctx.darkSoulActive(...)
        return ctx.buffRem("player", ...) > 0
    end
    function ctx.comboPoints()
        return GetComboPoints and (GetComboPoints("player", "target") or 0) or 0
    end

    function ctx.stealthed()
        return (IsStealthed and IsStealthed()) or ctx.buffRem("player", 1784) > 0
    end

    function ctx.lowSelf(threshold)
        return ctx.unitHpPct("player") <= threshold
    end

    function ctx.bossCombat()
        return ctx.targetIsBoss() and UnitAffectingCombat and UnitAffectingCombat("player")
    end

    function ctx.hasPetOrSacrifice()
        return ctx.petAlive() or ctx.buffRem("player", 108503) > 0
    end

    function ctx.selfBuffMissing(...)
        return ctx.buffRem("player", ...) <= 0
    end

    function ctx.readyInRange(spellID, powerCost, powerType)
        return ctx.ready(spellID, powerCost, powerType) and ctx.inRange(spellID)
    end

    function ctx.groundTargeting(spellID)
        return IsGroundTargetingSpell(spellID)
    end

    function ctx.groundEffectRem(spellID)
        return GroundTargetEffectRemaining(spellID)
    end

    function ctx.groundReady(spellID, powerCost, powerType)
        return ctx.ready(spellID, powerCost, powerType) and (ctx.groundTargeting(spellID) or ctx.groundEffectRem(spellID) <= 0)
    end

    function ctx.hasAttackTarget()
        return UnitExists("target") and not UnitIsDead("target") and UnitCanAttack("player", "target")
    end

    function ctx.nearbyEnemyCount(radius)
        radius = radius or 12
        local seen = {}
        if UnitPosition then
            local px, py, pMap = UnitPosition("player")
            if px and py then
                if ctx.hasAttackTarget() then
                    local tx, ty, tMap = UnitPosition("target")
                    if tx and ty and tMap == pMap then
                        local dx = tx - px
                        local dy = ty - py
                        if (dx * dx + dy * dy) <= (radius * radius) then
                            seen[UnitGUID("target") or "target"] = true
                        end
                    end
                end
                if C_NamePlate and C_NamePlate.GetNamePlates then
                    for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
                        local unit = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
                        if unit and UnitExists(unit) and not UnitIsDead(unit) and UnitCanAttack("player", unit) then
                            local guid = UnitGUID(unit) or unit
                            local active = not UnitAffectingCombat or UnitAffectingCombat(unit) or guid == UnitGUID("target")
                            if active then
                                local ux, uy, uMap = UnitPosition(unit)
                                if ux and uy and uMap == pMap then
                                    local dx = ux - px
                                    local dy = uy - py
                                    if (dx * dx + dy * dy) <= (radius * radius) then
                                        seen[guid] = true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        CleanupRecentHostileAttackers(now)
        for guid in pairs(recentMeleeAttackers) do
            seen[guid] = true
        end
        local count = 0
        for _ in pairs(seen) do
            count = count + 1
        end
        return count
    end

    function ctx.enemyCount()
        local targetCluster = ctx.clusteredEnemyCount and ctx.clusteredEnemyCount(12) or 0
        local playerCluster = ctx.nearbyEnemyCount and ctx.nearbyEnemyCount(12) or 0
        local count = math.max(targetCluster, playerCluster)
        if count == 0 and ctx.hasAttackTarget() then
            count = 1
        end
        return count
    end

    function ctx.clusteredEnemyCount(radius)
        radius = radius or 12
        if not UnitPosition or not UnitExists("target") then
            return 0
        end
        local tx, ty, tMap = UnitPosition("target")
        if not tx or not ty then
            return 0
        end
        local seen = {}
        if ctx.hasAttackTarget() then
            seen[UnitGUID("target") or "target"] = true
        end
        if C_NamePlate and C_NamePlate.GetNamePlates then
            for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
                local unit = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
                if unit and UnitExists(unit) and not UnitIsDead(unit) and UnitCanAttack("player", unit) then
                    local ux, uy, uMap = UnitPosition(unit)
                    if ux and uy and uMap == tMap then
                        local dx = ux - tx
                        local dy = uy - ty
                        local guid = UnitGUID(unit) or unit
                        local active = not UnitAffectingCombat or UnitAffectingCombat(unit) or guid == UnitGUID("target")
                        if active and (dx * dx + dy * dy) <= (radius * radius) then
                            seen[guid] = true
                        end
                    end
                end
            end
        end
        local count = 0
        for _ in pairs(seen) do
            count = count + 1
        end
        return count
    end

    function ctx.avengersShieldTargetCount()
        local clustered = ctx.clusteredEnemyCount(12)
        local melee = CountRecentMeleeAttackers(now)
        if ctx.hasAttackTarget() and melee > 0 then
            local targetGUID = UnitGUID("target")
            if targetGUID and not recentMeleeAttackers[targetGUID] and UnitPosition then
                local px, py, pMap = UnitPosition("player")
                local tx, ty, tMap = UnitPosition("target")
                if px and py and tx and ty and pMap == tMap then
                    local dx = px - tx
                    local dy = py - ty
                    if (dx * dx + dy * dy) <= 144 then
                        melee = melee + 1
                    end
                end
            end
        end
        return math.max(clustered, melee)
    end

    function ctx.multiTarget(minTargets)
        return ctx.enemyCount() >= (minTargets or 2)
    end

    function ctx.healUnit()
        if UnitExists("target") and not UnitIsDead("target") and UnitCanAssist("player", "target") then
            return "target"
        end
        return "player"
    end

    function ctx.unitHpPct(unit)
        if not UnitExists(unit) then
            return 100
        end
        local maxHealth = UnitHealthMax(unit) or 0
        if maxHealth <= 0 then
            return 100
        end
        return ((UnitHealth(unit) or 0) / maxHealth) * 100
    end

    function ctx.petAlive()
        return UnitExists("pet") and not UnitIsDead("pet")
    end

    function ctx.petHpPct()
        return ctx.unitHpPct("pet")
    end

    function ctx.readyAny(powerCost, powerType, ...)
        for i = 1, select("#", ...) do
            local spellID = select(i, ...)
            if ctx.ready(spellID, powerCost, powerType) then
                return spellID
            end
        end
        return nil
    end

    function ctx.readyAnyInRange(...)
        for i = 1, select("#", ...) do
            local spellID = select(i, ...)
            if ctx.readyInRange(spellID) then
                return spellID
            end
        end
        return nil
    end

    function ctx.readySoon(spellID, seconds)
        local remaining = ctx.cooldownRemaining(spellID)
        return remaining ~= nil and remaining <= (seconds or 1.5)
    end

    function ctx.resourceReadySoon(cost, powerType, seconds)
        local current = UnitPower("player", powerType or energyType) or 0
        if current >= cost then
            return true
        end
        local regen = GetPowerRegen and select(2, GetPowerRegen()) or 0
        return regen > 0 and current + regen * (seconds or 1.5) >= cost
    end

    return ctx
end

local rotationModules = {}
local rotationModuleOrder = {}

local function RegisterRotation(key, module)
    rotationModules[key] = module
    table.insert(rotationModuleOrder, key)
end

RegisterRotation("DRUID:1", {
    name = "Balance Druid",
    resource = "ECLIPSE",
    formSpellID = 24858,
    enabled = function(ctx)
        return ctx.class == "DRUID" and ctx.spec == 1
    end,
    recommend = function(ctx)
        if ctx.known(24858) and not ctx.hasBuff(24858) and ctx.ready(24858) then return 24858 end
        if ctx.known(1126) and ctx.buffRem("player", 1126) <= 0 and ctx.ready(1126) then return 1126 end
        if not ctx.hasAttackTarget() then return nil end

        local bossTarget = ctx.targetIsBoss()
        local inCombat = UnitAffectingCombat and UnitAffectingCombat("player")
        local enemies = ctx.enemyCount()
        local eclipse = ctx.power(ctx.eclipseType)
        local moonfireRem = ctx.debuffRem("target", 8921, true)
        local sunfireRem = ctx.debuffRem("target", 93402, true)

        if enemies >= 6 and ctx.ready(16914) then return 16914 end
        if bossTarget and inCombat and ctx.ready(102560) then return 102560 end
        if bossTarget and inCombat and ctx.ready(112071) then return 112071 end
        if ctx.ready(48505) and ctx.buffRem("player", 48505) <= 0 then return 48505 end
        if moonfireRem <= 3 and ctx.ready(8921) and ctx.inRange(8921) then return 8921 end
        if ctx.known(93402) and sunfireRem <= 3 and ctx.ready(93402) and ctx.inRange(93402) then return 93402 end
        if ctx.ready(78674) and ctx.inRange(78674) then return 78674 end
        if eclipse < 0 and ctx.ready(2912) and ctx.inRange(2912) then return 2912 end
        if ctx.ready(5176) and ctx.inRange(5176) then return 5176 end
        if ctx.ready(2912) and ctx.inRange(2912) then return 2912 end
        return nil
    end,
})

RegisterRotation("DRUID:2", {
    name = "Feral Druid",
    resource = "COMBO_POINTS",
    formSpellID = 768,
    enabled = function(ctx)
        return ctx.class == "DRUID" and (ctx.spec == 2 or ctx.spec == nil) and (ctx.known(768) or ctx.known(33876) or ctx.known(5221) or ctx.known(1822))
    end,
    recommend = function(ctx)
        if ctx.known(768) and not ctx.hasBuff(768) then
            if ctx.ready(768) then return 768 end
            return nil
        end
        if not ctx.hasAttackTarget() then return nil end

        local cp = GetComboPoints("player", "target") or 0
        local energy = UnitPower("player", ctx.energyType) or 0
        local srRem = ctx.buffRem("player", 52610, 127538)
        local ripRem = ctx.debuffRem("target", 1079, true)
        local rakeRem = ctx.debuffRem("target", 1822, true)
        local thrashRem = ctx.debuffRem("target", 106830, true)
        local bossTarget = ctx.targetIsBoss()
        local inCombat = UnitAffectingCombat and UnitAffectingCombat("player")

        if ctx.buffRem("player", 1126) <= 0 and ctx.ready(1126) then return 1126 end
        if cp > 0 and srRem <= 3 and ctx.ready(52610, 25) then return 52610 end
        if energy <= 35 and ctx.ready(5217) then return 5217 end
        if cp >= 5 and ripRem <= 2 and ctx.ready(1079, 30) then return 1079 end
        if cp >= 5 and srRem > 6 and ripRem > 8 and rakeRem > 3 and ctx.ready(22568, 25) then return 22568 end
        if bossTarget and inCombat and srRem > 6 and ripRem > 6 and ctx.ready(108288) then return 108288 end
        if bossTarget and inCombat and srRem > 6 and ripRem > 6 and ctx.ready(106951) then return 106951 end
        if rakeRem <= 3 and ctx.ready(1822, 35) then return 1822 end
        if thrashRem <= 3 and ctx.ready(106830, 50) then return 106830 end
        local behind = ctx.behindTarget()
        local shredReady = ctx.ready(5221, 40) and ctx.inRange(5221)
        local mangleReady = ctx.ready(33876, 35) and ctx.inRange(33876)
        if behind == nil and shredReady and mangleReady then return 33876, 5221 end
        if behind ~= false and shredReady then return 5221 end
        if mangleReady then return 33876 end
        return nil
    end,
})

RegisterRotation("DRUID:3", {
    name = "Guardian Druid",
    resource = "RAGE",
    formSpellID = 5487,
    enabled = function(ctx)
        return ctx.class == "DRUID" and ctx.spec == 3
    end,
    recommend = function(ctx)
        if ctx.known(5487) and not ctx.hasBuff(5487) and ctx.ready(5487) then return 5487 end
        if ctx.known(1126) and ctx.buffRem("player", 1126) <= 0 and ctx.ready(1126) then return 1126 end
        if not ctx.hasAttackTarget() then return nil end

        local enemies = ctx.enemyCount()
        local rage = ctx.power(ctx.rageType)
        local hp = ctx.unitHpPct("player")
        if hp < 45 and ctx.ready(22842) then return 22842 end
        if rage >= 60 and ctx.ready(62606) then return 62606 end
        if ctx.debuffRem("target", 77758, true) <= 3 and ctx.ready(77758) then return 77758 end
        if enemies >= 3 and ctx.ready(779) then return 779 end
        if ctx.ready(33917) and ctx.inRange(33917) then return 33917 end
        if ctx.debuffRem("target", 33745, true) <= 3 and ctx.ready(33745) then return 33745 end
        if rage >= 85 and ctx.ready(6807) then return 6807 end
        if ctx.ready(779) then return 779 end
        return nil
    end,
})

RegisterRotation("DRUID:4", {
    name = "Restoration Druid",
    enabled = function(ctx)
        return ctx.class == "DRUID" and ctx.spec == 4
    end,
    recommend = function(ctx)
        if ctx.known(1126) and ctx.buffRem("player", 1126) <= 0 and ctx.ready(1126) then return 1126 end
        local unit = ctx.healUnit()
        local hp = ctx.unitHpPct(unit)
        if hp < 85 and ctx.buffStacks(unit, 33763) < 3 and ctx.ready(33763) then return 33763 end
        if hp < 95 and ctx.buffRem(unit, 774) <= 3 and ctx.ready(774) then return 774 end
        if hp < 70 and ctx.ready(18562) then return 18562 end
        if hp < 55 and ctx.buffRem("player", 16870) > 0 and ctx.ready(8936) then return 8936 end
        if hp < 45 and ctx.ready(5185) then return 5185 end
        if hp < 80 and ctx.ready(8936) then return 8936 end
        if ctx.ready(48438) and UnitAffectingCombat and UnitAffectingCombat("player") then return 48438 end
        if ctx.hasAttackTarget() and ctx.ready(5176) and ctx.inRange(5176) then return 5176 end
        return nil
    end,
})

RegisterRotation("MAGE:1", {
    name = "Arcane Mage",
    resource = "ARCANE_CHARGES",
    enabled = function(ctx)
        return ctx.class == "MAGE" and (ctx.spec == 1 or ctx.spec == nil)
    end,
    recommend = function(ctx)
        if ctx.known(1459) and ctx.buffRem("player", 1459, 61316) <= 0 and ctx.ready(1459) then return 1459 end
        if ctx.known(7302) and ctx.buffRem("player", 7302) <= 0 and ctx.ready(7302) then return 7302 end
        if not ctx.known(7302) and ctx.known(6117) and ctx.buffRem("player", 6117) <= 0 and ctx.ready(6117) then return 6117 end
        if not ctx.hasAttackTarget() then return nil end
        local enemies = ctx.enemyCount()
        local targetCluster = ctx.clusteredEnemyCount(12)
        local playerCluster = ctx.nearbyEnemyCount(10)
        local charges = ctx.arcaneCharges()
        local missiles = ctx.buffRem("player", 79683) > 0

        if ctx.debuffAnyRem("target", true, 44457, 114923) <= 3 then
            local bomb = ctx.readyAny(nil, nil, 44457, 114923)
            if bomb and ctx.inRange(bomb) then return bomb end
        end
        if ctx.manaPct() < 35 and ctx.ready(12051) then return 12051 end
        if ctx.targetIsBoss() and UnitAffectingCombat and UnitAffectingCombat("player") and ctx.ready(12042) then return 12042 end
        if enemies >= 3 and charges >= 4 and ctx.ready(44425) and ctx.inRange(44425) then return 44425 end
        if enemies >= 3 and playerCluster >= 3 and ctx.ready(1449) then return 1449 end
        if enemies >= 3 and targetCluster >= 3 and ctx.groundReady(10) then return 10 end
        if enemies >= 5 and ctx.ready(120) and ctx.inRange(120) then return 120 end
        if charges >= 4 and missiles and ctx.ready(5143) and ctx.inRange(5143) then return 5143 end
        if charges >= 4 and ctx.ready(44425) and ctx.inRange(44425) then return 44425 end
        if missiles and ctx.ready(5143) and ctx.inRange(5143) then return 5143 end
        if ctx.ready(30451) and ctx.inRange(30451) then return 30451 end
        if ctx.ready(133) and ctx.inRange(133) then return 133 end
        return nil
    end,
})

RegisterRotation("MAGE:2", {
    name = "Fire Mage",
    enabled = function(ctx)
        return ctx.class == "MAGE" and ctx.spec == 2
    end,
    recommend = function(ctx)
        if ctx.known(1459) and ctx.buffRem("player", 1459, 61316) <= 0 and ctx.ready(1459) then return 1459 end
        if ctx.known(30482) and ctx.buffRem("player", 30482) <= 0 and ctx.ready(30482) then return 30482 end
        if not ctx.hasAttackTarget() then return nil end

        local bossTarget = ctx.targetIsBoss()
        local inCombat = UnitAffectingCombat and UnitAffectingCombat("player")
        local enemies = ctx.enemyCount()
        local hotStreak = ctx.buffRem("player", 48108) > 0
        local heatingUp = ctx.buffRem("player", 48107) > 0
        if ctx.debuffAnyRem("target", true, 44457, 114923, 112948) <= 3 then
            local bomb = ctx.readyAny(nil, nil, 44457, 114923, 112948)
            if bomb and ctx.inRange(bomb) then return bomb end
        end
        if hotStreak and ctx.ready(11366) and ctx.inRange(11366) then return 11366 end
        if enemies >= 2 and ctx.ready(108853) and ctx.inRange(108853) then return 108853 end
        if heatingUp and ctx.ready(108853) and ctx.inRange(108853) then return 108853 end
        if enemies >= 4 and ctx.ready(31661) and ctx.inRange(31661) then return 31661 end
        if enemies >= 3 and ctx.groundReady(2120) then return 2120 end
        if bossTarget and inCombat and ctx.ready(11129) then return 11129 end
        if ctx.ready(2948) and ctx.inRange(2948) and ctx.manaPct() < 20 then return 2948 end
        if ctx.ready(133) and ctx.inRange(133) then return 133 end
        if ctx.ready(2948) and ctx.inRange(2948) then return 2948 end
        return nil
    end,
})

RegisterRotation("MAGE:3", {
    name = "Frost Mage",
    enabled = function(ctx)
        return ctx.class == "MAGE" and ctx.spec == 3
    end,
    recommend = function(ctx)
        if ctx.known(1459) and ctx.buffRem("player", 1459, 61316) <= 0 and ctx.ready(1459) then return 1459 end
        if ctx.known(7302) and ctx.buffRem("player", 7302) <= 0 and ctx.ready(7302) then return 7302 end
        if ctx.known(31687) and not ctx.petAlive() and ctx.ready(31687) then return 31687 end
        if not ctx.hasAttackTarget() then return nil end

        local enemies = ctx.enemyCount()
        if ctx.targetIsBoss() and UnitAffectingCombat and UnitAffectingCombat("player") and ctx.ready(12472) then return 12472 end
        if ctx.ready(84714) and ctx.inRange(84714) then return 84714 end
        if enemies >= 5 and ctx.ready(120) and ctx.inRange(120) then return 120 end
        if enemies >= 3 and ctx.groundReady(10) then return 10 end
        if ctx.debuffAnyRem("target", true, 44457, 114923, 112948) <= 3 then
            local bomb = ctx.readyAny(nil, nil, 44457, 114923, 112948)
            if bomb and ctx.inRange(bomb) then return bomb end
        end
        if ctx.buffRem("player", 57761) > 0 and ctx.ready(44614) and ctx.inRange(44614) then return 44614 end
        if ctx.buffRem("player", 44544) > 0 and ctx.ready(30455) and ctx.inRange(30455) then return 30455 end
        if ctx.ready(116) and ctx.inRange(116) then return 116 end
        if ctx.ready(133) and ctx.inRange(133) then return 133 end
        return nil
    end,
})

RegisterRotation("PALADIN:1", {
    name = "Holy Paladin",
    resource = "HOLY_POWER",
    enabled = function(ctx)
        return ctx.class == "PALADIN" and ctx.spec == 1
    end,
    recommend = function(ctx)
        if ctx.buffRem("player", 20165, 20154) <= 0 then local seal = ctx.readyAny(nil, nil, 20165, 20154) if seal then return seal end end
        local unit = ctx.healUnit()
        local hp = ctx.unitHpPct(unit)
        local holyPower = ctx.holyPower()
        if hp < 95 and holyPower >= 3 and ctx.ready(114163) then return 114163 end
        if hp < 95 and holyPower >= 3 and ctx.ready(85673) then return 85673 end
        if ctx.ready(20473) then return 20473 end
        if hp < 45 and ctx.ready(19750) then return 19750 end
        if hp < 70 and ctx.ready(82326) then return 82326 end
        if hp < 90 and ctx.ready(635) then return 635 end
        if ctx.hasAttackTarget() and ctx.ready(20271) and ctx.inRange(20271) then return 20271 end
        return nil
    end,
})

RegisterRotation("PALADIN:2", {
    name = "Protection Paladin",
    resource = "HOLY_POWER",
    enabled = function(ctx)
        return ctx.class == "PALADIN" and (ctx.spec == 2 or ctx.hasBuff(25780) or ctx.known(31935))
    end,
    recommend = function(ctx)
        if ctx.known(25780) and ctx.buffRem("player", 25780) <= 0 and ctx.ready(25780) then return 25780 end
        if ctx.buffRem("player", 20165, 20154) <= 0 then local seal = ctx.readyAny(nil, nil, 20165, 20154) if seal then return seal end end
        if not ctx.hasAttackTarget() then return nil end

        local enemies = ctx.enemyCount()
        local avengerTargets = ctx.avengersShieldTargetCount()
        local bossTarget = ctx.targetIsBoss()
        local holyPower = ctx.holyPower()
        if holyPower >= 5 and ctx.ready(53600) then return 53600 end
        if (bossTarget or avengerTargets >= 2) and ctx.ready(31935) then return 31935 end
        if ctx.targetHpPct() <= 20 and ctx.ready(24275) and ctx.inRange(24275) then return 24275 end
        if enemies >= 2 and ctx.ready(53595) and ctx.inRange(53595) then return 53595 end
        if enemies >= 3 and ctx.ready(26573) then return 26573 end
        if enemies >= 3 and ctx.ready(119072) then return 119072 end
        if enemies >= 3 and ctx.ready(20271) and ctx.inRange(20271) then return 20271 end
        if ctx.ready(35395) and ctx.inRange(35395) then return 35395 end
        if ctx.ready(20271) and ctx.inRange(20271) then return 20271 end
        if (bossTarget or avengerTargets >= 2) and ctx.ready(31935) then return 31935 end
        if ctx.ready(26573) then return 26573 end
        if holyPower >= 3 and ctx.ready(53600) then return 53600 end
        return nil
    end,
})

RegisterRotation("PALADIN:3", {
    name = "Retribution Paladin",
    resource = "HOLY_POWER",
    enabled = function(ctx)
        return ctx.class == "PALADIN" and (ctx.spec == 3 or ctx.spec == nil)
    end,
    recommend = function(ctx)
        if ctx.buffRem("player", 31801, 20154) <= 0 then local seal = ctx.readyAny(nil, nil, 31801, 20154) if seal then return seal end end
        if ctx.known(20217) and ctx.buffRem("player", 20217, 19740) <= 0 and ctx.ready(20217) then return 20217 end
        if ctx.known(19740) and ctx.buffRem("player", 20217, 19740) <= 0 and ctx.ready(19740) then return 19740 end
        if not ctx.hasAttackTarget() then return nil end

        local enemies = ctx.enemyCount()
        local holyPower = ctx.holyPower()
        local wings = ctx.buffRem("player", 31884) > 0
        local bossTarget = ctx.targetIsBoss()
        local inCombat = UnitAffectingCombat and UnitAffectingCombat("player")
        if holyPower >= 3 and ctx.buffRem("player", 84963) <= 4 and ctx.ready(84963) then return 84963 end
        if enemies >= 2 and holyPower >= 5 and ctx.ready(53385) then return 53385 end
        if holyPower >= 5 and ctx.ready(85256) then return 85256 end
        if bossTarget and inCombat and ctx.ready(86698) then return 86698 end
        if bossTarget and inCombat and ctx.ready(31884) then return 31884 end
        if (ctx.targetHpPct() <= 20 or wings) and ctx.ready(24275) and ctx.inRange(24275) then return 24275 end
        if enemies >= 4 and ctx.ready(53595) and ctx.inRange(53595) then return 53595 end
        if wings and ctx.ready(20271) and ctx.inRange(20271) then return 20271 end
        local talent = ctx.readyAnyInRange(114916, 114165, 114158)
        if talent then return talent end
        if ctx.ready(35395) and ctx.inRange(35395) then return 35395 end
        if ctx.ready(20271) and ctx.inRange(20271) then return 20271 end
        if ctx.ready(879) and ctx.inRange(879) then return 879 end
        if enemies >= 2 and holyPower >= 3 and ctx.ready(53385) then return 53385 end
        if holyPower >= 3 and ctx.ready(85256) then return 85256 end
        return nil
    end,
})

local function HunterPrep(ctx)
    if ctx.buffRem("player", 13165, 109260) <= 0 then
        local aspect = ctx.readyAny(nil, nil, 109260, 13165)
        if aspect then return aspect end
    end
    return nil
end

local function HunterTalent(ctx)
    local talent = ctx.readyAny(nil, nil, 120679, 131894, 117050, 109259, 120360)
    if talent and (not ctx.hasAttackTarget() or ctx.inRange(talent)) then
        return talent
    end
    return nil
end

local function HunterSerpentSting(ctx, refreshWindow)
    if ctx.debuffRem("target", 1978, true) <= (refreshWindow or 3) and ctx.ready(1978, 15, ctx.focusType) and ctx.inRange(1978) then
        return 1978
    end
    return nil
end

local function HunterArcaneShot(ctx, focus, minFocus)
    focus = focus or ctx.power(ctx.focusType)
    if focus >= (minFocus or 30) and ctx.ready(3044, 30, ctx.focusType) and ctx.inRange(3044) then
        return 3044
    end
    return nil
end

local function HunterMarkingShot(ctx, focus)
    if ctx.debuffRem("target", 1130, false) <= 0 then
        return HunterArcaneShot(ctx, focus, 30)
    end
    return nil
end

local function HunterMultiShot(ctx, focus, minTargets)
    focus = focus or ctx.power(ctx.focusType)
    minTargets = minTargets or 2
    local clustered = ctx.clusteredEnemyCount and ctx.clusteredEnemyCount(10) or 0
    local enemies = ctx.enemyCount and ctx.enemyCount() or clustered
    local count = clustered > 0 and clustered or enemies
    if count >= minTargets and focus >= 40 and ctx.ready(2643, 40, ctx.focusType) and ctx.inRange(2643) then
        return 2643
    end
    return nil
end

local function HunterFocusBuilder(ctx)
    return ctx.readyAnyInRange(77767, 56641)
end

local function HunterFallback(ctx, focus, dumpFocus)
    focus = focus or 0
    dumpFocus = dumpFocus or 60
    local arcane = HunterArcaneShot(ctx, focus, dumpFocus)
    if arcane then return arcane end
    arcane = HunterArcaneShot(ctx, focus, 30)
    if arcane then return arcane end
    local builder = HunterFocusBuilder(ctx)
    if builder then return builder end
    if ctx.readyInRange(75) then return 75 end
    return nil
end

RegisterRotation("HUNTER:1", {
    name = "Beast Mastery Hunter",
    resource = "FOCUS",
    enabled = function(ctx)
        return ctx.class == "HUNTER" and (ctx.spec == 1 or ctx.spec == nil)
    end,
    recommend = function(ctx)
        local prep = HunterPrep(ctx)
        if prep then return prep end
        if not ctx.hasAttackTarget() then return nil end

        local enemies = ctx.enemyCount()
        local focus = ctx.power(ctx.focusType)
        local bossTarget = ctx.targetIsBoss()
        local inCombat = UnitAffectingCombat and UnitAffectingCombat("player")
        local freshSerpent = HunterSerpentSting(ctx, 0)
        if freshSerpent then return freshSerpent end
        local multi = HunterMultiShot(ctx, focus, 2)
        if multi then return multi end
        local marking = HunterMarkingShot(ctx, focus)
        if marking then return marking end
        if ctx.petAlive() and ctx.ready(34026, 40, ctx.focusType) and ctx.inRange(34026) then return 34026 end
        if ctx.targetHpPct() <= 20 and ctx.ready(53351) and ctx.inRange(53351) then return 53351 end
        local serpent = HunterSerpentSting(ctx, 3)
        if serpent then return serpent end
        if bossTarget and inCombat and ctx.petAlive() and ctx.ready(19574) then return 19574 end
        if ctx.petAlive() and ctx.buffStacks("pet", 19615) >= 5 and ctx.ready(82692) then return 82692 end
        local talent = HunterTalent(ctx)
        if talent then return talent end
        multi = HunterMultiShot(ctx, focus, 2)
        if multi then return multi end
        return HunterFallback(ctx, focus, 55)
    end,
})

RegisterRotation("HUNTER:2", {
    name = "Marksmanship Hunter",
    resource = "FOCUS",
    enabled = function(ctx)
        return ctx.class == "HUNTER" and ctx.spec == 2
    end,
    recommend = function(ctx)
        local prep = HunterPrep(ctx)
        if prep then return prep end
        if not ctx.hasAttackTarget() then return nil end

        local enemies = ctx.enemyCount()
        local focus = ctx.power(ctx.focusType)
        local targetHp = ctx.targetHpPct()
        local aimedProc = ctx.buffRem("player", 82925) > 0
        local freshSerpent = HunterSerpentSting(ctx, 0)
        if freshSerpent then return freshSerpent end
        local multi = HunterMultiShot(ctx, focus, 2)
        if multi then return multi end
        local marking = HunterMarkingShot(ctx, focus)
        if marking then return marking end
        if aimedProc and ctx.ready(19434) and ctx.inRange(19434) then return 19434 end
        if enemies < 10 and ctx.ready(53209, 45, ctx.focusType) and ctx.inRange(53209) then return 53209 end
        multi = HunterMultiShot(ctx, focus, 4)
        if multi then return multi end
        local serpent = HunterSerpentSting(ctx, 3)
        if serpent then return serpent end
        if targetHp <= 20 and ctx.ready(53351) and ctx.inRange(53351) then return 53351 end
        local talent = HunterTalent(ctx)
        if talent then return talent end
        if (targetHp >= 80 or focus >= 75 or ctx.buffRem("player", 3045) > 0 or ctx.buffRem("player", 2825, 80353) > 0) and ctx.ready(19434, 50, ctx.focusType) and ctx.inRange(19434) then return 19434 end
        if focus <= 45 and ctx.buffRem("player", 53220) <= 5 and ctx.ready(56641) and ctx.inRange(56641) then return 56641 end
        return HunterFallback(ctx, focus, 65)
    end,
})

RegisterRotation("HUNTER:3", {
    name = "Survival Hunter",
    resource = "FOCUS",
    enabled = function(ctx)
        return ctx.class == "HUNTER" and ctx.spec == 3
    end,
    recommend = function(ctx)
        local prep = HunterPrep(ctx)
        if prep then return prep end
        if not ctx.hasAttackTarget() then return nil end

        local enemies = ctx.enemyCount()
        local focus = ctx.power(ctx.focusType)
        local lockAndLoad = ctx.buffRem("player", 56453) > 0
        local freshSerpent = HunterSerpentSting(ctx, 0)
        if freshSerpent then return freshSerpent end
        local multi = HunterMultiShot(ctx, focus, 4)
        if multi then return multi end
        local marking = HunterMarkingShot(ctx, focus)
        if marking then return marking end
        if (enemies < 6 or lockAndLoad) and ctx.ready(53301, 25, ctx.focusType) and ctx.inRange(53301) then return 53301 end
        if ctx.targetHpPct() <= 20 and ctx.ready(53351) and ctx.inRange(53351) then return 53351 end
        if ctx.debuffRem("target", 3674, true) <= 3 and ctx.ready(3674, 35, ctx.focusType) and ctx.inRange(3674) then return 3674 end
        multi = HunterMultiShot(ctx, focus, 2)
        if multi then return multi end
        local serpent = HunterSerpentSting(ctx, 3)
        if serpent then return serpent end
        local talent = HunterTalent(ctx)
        if talent then return talent end
        return HunterFallback(ctx, focus, 65)
    end,
})

RegisterRotation("DEATHKNIGHT:1", {
    name = "Blood Death Knight",
    resource = "RUNIC_POWER",
    enabled = function(ctx) return ctx.class == "DEATHKNIGHT" and ctx.spec == 1 end,
    recommend = function(ctx)
        if ctx.known(48263) and ctx.selfBuffMissing(48263) and ctx.ready(48263) then return 48263 end
        if ctx.known(57330) and ctx.selfBuffMissing(57330) and ctx.ready(57330) then return 57330 end
        if not ctx.hasAttackTarget() then return nil end
        local enemies = ctx.enemyCount()
        local rp = ctx.power(ctx.runicPowerType)
        if ctx.ready(49222) and ctx.buffRem("player", 49222) <= 3 then return 49222 end
        if ctx.debuffAnyRem("target", true, 55095, 55078) <= 3 and ctx.readyInRange(77575) then return 77575 end
        if ctx.debuffRem("target", 55095, true) <= 3 and ctx.readyInRange(45477) then return 45477 end
        if ctx.debuffRem("target", 55078, true) <= 3 and ctx.readyInRange(45462) then return 45462 end
        if ctx.lowSelf(65) and ctx.readyInRange(49998) then return 49998 end
        if enemies >= 3 and ctx.ready(48721) then return 48721 end
        if ctx.targetHpPct() <= 35 and ctx.readyInRange(130735) then return 130735 end
        if ctx.readyInRange(49998) then return 49998 end
        if rp >= 80 and ctx.readyInRange(56815) then return 56815 end
        if ctx.readyInRange(55050) then return 55050 end
        if ctx.ready(57330) then return 57330 end
        return nil
    end,
})

RegisterRotation("DEATHKNIGHT:2", {
    name = "Frost Death Knight",
    resource = "RUNIC_POWER",
    enabled = function(ctx) return ctx.class == "DEATHKNIGHT" and ctx.spec == 2 end,
    recommend = function(ctx)
        if ctx.known(48266) and ctx.selfBuffMissing(48266) and ctx.ready(48266) then return 48266 end
        if ctx.known(57330) and ctx.selfBuffMissing(57330) and ctx.ready(57330) then return 57330 end
        if not ctx.hasAttackTarget() then return nil end
        local enemies = ctx.enemyCount()
        local rp = ctx.power(ctx.runicPowerType)
        if ctx.debuffAnyRem("target", true, 55095, 55078) <= 3 and ctx.readyInRange(77575) then return 77575 end
        if enemies >= 2 and ctx.readyInRange(49184) then return 49184 end
        if ctx.debuffRem("target", 55095, true) <= 3 and ctx.readyInRange(49184) then return 49184 end
        if ctx.debuffRem("target", 55078, true) <= 3 and ctx.readyInRange(45462) then return 45462 end
        if ctx.bossCombat() and ctx.ready(51271) then return 51271 end
        if ctx.targetHpPct() <= 35 and ctx.readyInRange(130735) then return 130735 end
        if rp >= 76 and ctx.readyInRange(49143) then return 49143 end
        if ctx.readyInRange(49020) then return 49020 end
        if ctx.readyInRange(49184) then return 49184 end
        if ctx.readyInRange(49143) then return 49143 end
        if ctx.ready(57330) then return 57330 end
        return nil
    end,
})

RegisterRotation("DEATHKNIGHT:3", {
    name = "Unholy Death Knight",
    resource = "RUNIC_POWER",
    enabled = function(ctx) return ctx.class == "DEATHKNIGHT" and ctx.spec == 3 end,
    recommend = function(ctx)
        if ctx.known(48265) and ctx.selfBuffMissing(48265) and ctx.ready(48265) then return 48265 end
        if ctx.known(46584) and not ctx.petAlive() and ctx.ready(46584) then return 46584 end
        if ctx.known(57330) and ctx.selfBuffMissing(57330) and ctx.ready(57330) then return 57330 end
        if not ctx.hasAttackTarget() then return nil end
        local enemies = ctx.enemyCount()
        local rp = ctx.power(ctx.runicPowerType)
        if ctx.debuffAnyRem("target", true, 55095, 55078) <= 3 and ctx.readyInRange(77575) then return 77575 end
        if ctx.debuffRem("target", 55095, true) <= 3 and ctx.readyInRange(45477) then return 45477 end
        if ctx.debuffRem("target", 55078, true) <= 3 and ctx.readyInRange(45462) then return 45462 end
        if ctx.petAlive() and ctx.ready(63560) then return 63560 end
        if enemies >= 3 and ctx.ready(43265) then return 43265 end
        if enemies >= 3 and ctx.ready(48721) then return 48721 end
        if ctx.bossCombat() and ctx.readyInRange(49206) then return 49206 end
        if ctx.targetHpPct() <= 35 and ctx.readyInRange(130736) then return 130736 end
        if ctx.readyInRange(55090) then return 55090 end
        if ctx.readyInRange(85948) then return 85948 end
        if rp >= 80 and ctx.readyInRange(47541) then return 47541 end
        if ctx.ready(57330) then return 57330 end
        return nil
    end,
})

RegisterRotation("WARRIOR:1", {
    name = "Arms Warrior",
    resource = "RAGE",
    enabled = function(ctx) return ctx.class == "WARRIOR" and ctx.spec == 1 end,
    recommend = function(ctx)
        if ctx.selfBuffMissing(6673, 469) then local shout = ctx.readyAny(nil, nil, 6673, 469) if shout then return shout end end
        if not ctx.hasAttackTarget() then return nil end
        local enemies = ctx.enemyCount()
        local rage = ctx.power(ctx.rageType)
        if enemies >= 4 and ctx.ready(46924) then return 46924 end
        if enemies >= 3 and ctx.ready(6343) then return 6343 end
        if ctx.targetHpPct() <= 20 and ctx.readyInRange(5308) then return 5308 end
        if ctx.readyInRange(86346) then return 86346 end
        if ctx.readyInRange(12294) then return 12294 end
        if ctx.readyInRange(7384) then return 7384 end
        if rage >= 60 and ctx.readyInRange(1464) then return 1464 end
        if ctx.ready(6673) then return 6673 end
        return nil
    end,
})

RegisterRotation("WARRIOR:2", {
    name = "Fury Warrior",
    resource = "RAGE",
    enabled = function(ctx) return ctx.class == "WARRIOR" and ctx.spec == 2 end,
    recommend = function(ctx)
        if ctx.selfBuffMissing(6673, 469) then local shout = ctx.readyAny(nil, nil, 6673, 469) if shout then return shout end end
        if not ctx.hasAttackTarget() then return nil end
        local enemies = ctx.enemyCount()
        local rage = ctx.power(ctx.rageType)
        if enemies >= 4 and ctx.readyInRange(1680) then return 1680 end
        if ctx.targetHpPct() <= 20 and ctx.readyInRange(5308) then return 5308 end
        if ctx.readyInRange(86346) then return 86346 end
        if ctx.readyInRange(23881) then return 23881 end
        if ctx.readyInRange(85288) then return 85288 end
        if rage >= 70 and ctx.readyInRange(100130) then return 100130 end
        if ctx.ready(6673) then return 6673 end
        return nil
    end,
})

RegisterRotation("WARRIOR:3", {
    name = "Protection Warrior",
    resource = "RAGE",
    enabled = function(ctx) return ctx.class == "WARRIOR" and ctx.spec == 3 end,
    recommend = function(ctx)
        if ctx.known(71) and ctx.selfBuffMissing(71) and ctx.ready(71) then return 71 end
        if ctx.selfBuffMissing(6673, 469) then local shout = ctx.readyAny(nil, nil, 6673, 469) if shout then return shout end end
        if not ctx.hasAttackTarget() then return nil end
        local enemies = ctx.enemyCount()
        local rage = ctx.power(ctx.rageType)
        if rage >= 60 and ctx.lowSelf(70) and ctx.ready(112048) then return 112048 end
        if ctx.readyInRange(23922) then return 23922 end
        if ctx.readyInRange(6572) then return 6572 end
        if ctx.targetHpPct() <= 20 and ctx.readyInRange(5308) then return 5308 end
        if enemies >= 3 and ctx.ready(6343) then return 6343 end
        if ctx.readyInRange(20243) then return 20243 end
        if rage >= 60 and ctx.ready(2565) then return 2565 end
        if rage >= 90 and ctx.readyInRange(78) then return 78 end
        return nil
    end,
})

RegisterRotation("ROGUE:1", {
    name = "Assassination Rogue",
    resource = "COMBO_POINTS",
    enabled = function(ctx) return ctx.class == "ROGUE" and ctx.spec == 1 end,
    recommend = function(ctx)
        if not ctx.hasAttackTarget() then return nil end
        local enemies = ctx.enemyCount()
        local cp = ctx.comboPoints()
        local energy = ctx.power(ctx.energyType)
        if enemies >= 3 and cp >= 3 and ctx.debuffRem("target", 121411, true) <= 3 and ctx.ready(121411) then return 121411 end
        if cp >= 4 and ctx.debuffRem("target", 1943, true) <= 3 and ctx.readyInRange(1943) then return 1943 end
        if cp > 0 and ctx.buffRem("player", 5171) <= 2 and ctx.ready(5171) then return 5171 end
        if ctx.bossCombat() and ctx.readyInRange(79140) then return 79140 end
        if ctx.bossCombat() and ctx.ready(121471) then return 121471 end
        if cp >= 4 and ctx.readyInRange(32645) then return 32645 end
        if (ctx.targetHpPct() <= 35 or ctx.buffRem("player", 121153) > 0) and ctx.readyInRange(111240) then return 111240 end
        if enemies >= 3 and energy >= 35 and ctx.ready(51723) then return 51723 end
        if ctx.readyInRange(1329) then return 1329 end
        if ctx.readyInRange(1752) then return 1752 end
        return nil
    end,
})

RegisterRotation("ROGUE:2", {
    name = "Combat Rogue",
    resource = "COMBO_POINTS",
    enabled = function(ctx) return ctx.class == "ROGUE" and ctx.spec == 2 end,
    recommend = function(ctx)
        if not ctx.hasAttackTarget() then return nil end
        local enemies = ctx.enemyCount()
        local cp = ctx.comboPoints()
        if enemies >= 2 and ctx.ready(13877) and ctx.buffRem("player", 13877) <= 0 then return 13877 end
        if cp > 0 and ctx.buffRem("player", 5171) <= 2 and ctx.ready(5171) then return 5171 end
        if ctx.debuffRem("target", 84617, true) <= 3 and ctx.readyInRange(84617) then return 84617 end
        if ctx.bossCombat() and ctx.ready(13750) then return 13750 end
        if ctx.bossCombat() and ctx.ready(121471) then return 121471 end
        if ctx.bossCombat() and ctx.readyInRange(51690) then return 51690 end
        if enemies >= 8 and cp >= 5 and ctx.ready(121411) then return 121411 end
        if cp >= 5 and ctx.readyInRange(2098) then return 2098 end
        if enemies >= 8 and ctx.ready(51723) then return 51723 end
        if ctx.readyInRange(84617) then return 84617 end
        if ctx.readyInRange(1752) then return 1752 end
        return nil
    end,
})

RegisterRotation("ROGUE:3", {
    name = "Subtlety Rogue",
    resource = "COMBO_POINTS",
    enabled = function(ctx) return ctx.class == "ROGUE" and ctx.spec == 3 end,
    recommend = function(ctx)
        if not ctx.hasAttackTarget() then return nil end
        local enemies = ctx.enemyCount()
        local cp = ctx.comboPoints()
        if cp > 0 and ctx.buffRem("player", 5171) <= 2 and ctx.ready(5171) then return 5171 end
        if enemies >= 3 and cp >= 5 and ctx.ready(121411) then return 121411 end
        if cp >= 5 and ctx.debuffRem("target", 1943, true) <= 3 and ctx.readyInRange(1943) then return 1943 end
        if ctx.debuffRem("target", 16511, true) <= 3 and ctx.readyInRange(16511) then return 16511 end
        if ctx.bossCombat() and ctx.ready(51713) then return 51713 end
        if ctx.bossCombat() and ctx.ready(121471) then return 121471 end
        if cp >= 5 and ctx.readyInRange(2098) then return 2098 end
        if ctx.stealthed() and ctx.readyInRange(8676) then return 8676 end
        if enemies >= 5 and ctx.ready(51723) then return 51723 end
        if ctx.readyInRange(53) then return 53 end
        if ctx.readyInRange(16511) then return 16511 end
        return nil
    end,
})

RegisterRotation("PRIEST:1", {
    name = "Discipline Priest",
    enabled = function(ctx) return ctx.class == "PRIEST" and ctx.spec == 1 end,
    recommend = function(ctx)
        if ctx.known(21562) and ctx.selfBuffMissing(21562) and ctx.ready(21562) then return 21562 end
        if ctx.known(588) and ctx.selfBuffMissing(588, 73413) and ctx.ready(588) then return 588 end
        local unit = ctx.healUnit()
        local hp = ctx.unitHpPct(unit)
        if hp < 90 and ctx.ready(17) then return 17 end
        if hp < 80 and ctx.ready(47540) then return 47540 end
        if hp < 75 and ctx.ready(33076) then return 33076 end
        if ctx.hasAttackTarget() and ctx.readyInRange(14914) then return 14914 end
        if ctx.hasAttackTarget() and ctx.readyInRange(585) then return 585 end
        if hp < 90 and ctx.ready(2050) then return 2050 end
        return nil
    end,
})

RegisterRotation("PRIEST:2", {
    name = "Holy Priest",
    enabled = function(ctx) return ctx.class == "PRIEST" and ctx.spec == 2 end,
    recommend = function(ctx)
        if ctx.known(21562) and ctx.selfBuffMissing(21562) and ctx.ready(21562) then return 21562 end
        if ctx.known(588) and ctx.selfBuffMissing(588, 73413) and ctx.ready(588) then return 588 end
        local unit = ctx.healUnit()
        local hp = ctx.unitHpPct(unit)
        if hp < 95 and ctx.buffRem(unit, 139) <= 3 and ctx.ready(139) then return 139 end
        if hp < 80 and ctx.ready(33076) then return 33076 end
        if hp < 70 and ctx.ready(34861) then return 34861 end
        if hp < 55 and ctx.ready(2061) then return 2061 end
        if hp < 85 and ctx.ready(2050) then return 2050 end
        if ctx.hasAttackTarget() and ctx.readyInRange(14914) then return 14914 end
        if ctx.hasAttackTarget() and ctx.readyInRange(585) then return 585 end
        return nil
    end,
})

RegisterRotation("PRIEST:3", {
    name = "Shadow Priest",
    resource = "SHADOW_ORBS",
    enabled = function(ctx) return ctx.class == "PRIEST" and ctx.spec == 3 end,
    recommend = function(ctx)
        if ctx.known(15473) and ctx.selfBuffMissing(15473) and ctx.ready(15473) then return 15473 end
        if ctx.known(21562) and ctx.selfBuffMissing(21562) and ctx.ready(21562) then return 21562 end
        if ctx.known(588) and ctx.selfBuffMissing(588, 73413) and ctx.ready(588) then return 588 end
        if not ctx.hasAttackTarget() then return nil end
        local enemies = ctx.enemyCount()
        local orbs = ctx.shadowOrbs()
        if enemies >= 5 and ctx.readyInRange(48045) then return 48045 end
        if ctx.debuffRem("target", 589, true) <= 3 and ctx.readyInRange(589) then return 589 end
        if ctx.debuffRem("target", 34914, true) <= 3 and ctx.readyInRange(34914) then return 34914 end
        if ctx.bossCombat() and ctx.readyInRange(34433) then return 34433 end
        if orbs >= 3 and ctx.readyInRange(2944) then return 2944 end
        if ctx.readyInRange(8092) then return 8092 end
        if ctx.targetHpPct() <= 20 and ctx.readyInRange(32379) then return 32379 end
        local talent = ctx.readyAny(nil, nil, 120517, 110744, 121135)
        if talent then return talent end
        if ctx.readyInRange(15407) then return 15407 end
        return nil
    end,
})

RegisterRotation("SHAMAN:1", {
    name = "Elemental Shaman",
    resource = "MAELSTROM",
    enabled = function(ctx) return ctx.class == "SHAMAN" and ctx.spec == 1 end,
    recommend = function(ctx)
        if ctx.known(324) and ctx.selfBuffMissing(324) and ctx.ready(324) then return 324 end
        if not ctx.hasAttackTarget() then return nil end
        local enemies = ctx.enemyCount()
        if ctx.bossCombat() and ctx.ready(2894) then return 2894 end
        if ctx.bossCombat() and ctx.ready(120668) then return 120668 end
        if ctx.bossCombat() and ctx.ready(114049) then return 114049 end
        if ctx.debuffRem("target", 8050, true) <= 4 and ctx.readyInRange(8050) then return 8050 end
        if enemies >= 5 and ctx.readyInRange(421) then return 421 end
        if ctx.readyInRange(51505) then return 51505 end
        if ctx.buffStacks("player", 324) >= 7 and ctx.readyInRange(8042) then return 8042 end
        if enemies >= 2 and ctx.readyInRange(421) then return 421 end
        if ctx.readyInRange(403) then return 403 end
        return nil
    end,
})

RegisterRotation("SHAMAN:2", {
    name = "Enhancement Shaman",
    resource = "MAELSTROM",
    enabled = function(ctx) return ctx.class == "SHAMAN" and ctx.spec == 2 end,
    recommend = function(ctx)
        if ctx.known(324) and ctx.selfBuffMissing(324) and ctx.ready(324) then return 324 end
        if not ctx.hasAttackTarget() then return nil end
        local enemies = ctx.enemyCount()
        if ctx.bossCombat() and ctx.ready(51533) then return 51533 end
        if ctx.bossCombat() and ctx.ready(114051) then return 114051 end
        if ctx.debuffRem("target", 8050, true) <= 4 and ctx.readyInRange(8050) then return 8050 end
        if ctx.readyInRange(17364) then return 17364 end
        if ctx.readyInRange(60103) then return 60103 end
        if ctx.buffStacks("player", 53817) >= 5 and ctx.readyInRange(51505) then return 51505 end
        if ctx.buffStacks("player", 53817) >= 5 and enemies >= 3 and ctx.readyInRange(421) then return 421 end
        if ctx.readyInRange(8042) then return 8042 end
        if enemies >= 3 and ctx.ready(1535) then return 1535 end
        if ctx.readyInRange(403) then return 403 end
        return nil
    end,
})

RegisterRotation("SHAMAN:3", {
    name = "Restoration Shaman",
    enabled = function(ctx) return ctx.class == "SHAMAN" and ctx.spec == 3 end,
    recommend = function(ctx)
        if ctx.known(52127) and ctx.selfBuffMissing(52127) and ctx.ready(52127) then return 52127 end
        local unit = ctx.healUnit()
        local hp = ctx.unitHpPct(unit)
        if hp < 95 and ctx.buffRem(unit, 974) <= 3 and ctx.ready(974) then return 974 end
        if hp < 95 and ctx.buffRem(unit, 61295) <= 3 and ctx.ready(61295) then return 61295 end
        if hp < 70 and ctx.ready(5394) then return 5394 end
        if hp < 55 and ctx.ready(8004) then return 8004 end
        if hp < 80 and ctx.ready(331) then return 331 end
        if ctx.hasAttackTarget() and ctx.readyInRange(403) then return 403 end
        return nil
    end,
})

RegisterRotation("WARLOCK:1", {
    name = "Affliction Warlock",
    resource = "SOUL_SHARDS",
    enabled = function(ctx) return ctx.class == "WARLOCK" and ctx.spec == 1 end,
    recommend = function(ctx)
        if ctx.known(109773) and ctx.selfBuffMissing(109773) and ctx.ready(109773) then return 109773 end
        if not ctx.hasAttackTarget() then return nil end
        local enemies = ctx.enemyCount()
        local shards = ctx.soulShards()
        local targetHp = ctx.targetHpPct()
        local darkSoul = ctx.darkSoulActive(113860)
        local dotsReady = ctx.debuffRem("target", 980, true) > 0 and ctx.debuffRem("target", 172, true) > 0 and ctx.debuffRem("target", 30108, true) > 0
        if enemies >= 5 and shards > 0 and ctx.buffRem("player", 74434) <= 0 and ctx.ready(74434) then return 74434 end
        if enemies >= 4 and ctx.readyInRange(27243) then return 27243 end
        if ctx.debuffRem("target", 980, true) <= 7 and ctx.readyInRange(980) then return 980 end
        if ctx.debuffRem("target", 172, true) <= 6 and ctx.readyInRange(172) then return 172 end
        if ctx.debuffRem("target", 30108, true) <= 7 and ctx.readyInRange(30108) then return 30108 end
        if ctx.bossCombat() and dotsReady and ctx.ready(113860) then return 113860 end
        if dotsReady and shards > 0 and ctx.debuffRem("target", 48181, true) <= 2 and (shards >= 3 or targetHp <= 20 or darkSoul) and ctx.readyInRange(48181) then return 48181 end
        if targetHp <= 20 and ctx.readyInRange(1120) then return 1120 end
        if ctx.readyInRange(103103) then return 103103 end
        if ctx.readyInRange(686) then return 686 end
        return nil
    end,
})

RegisterRotation("WARLOCK:2", {
    name = "Demonology Warlock",
    resource = "DEMONIC_FURY",
    enabled = function(ctx) return ctx.class == "WARLOCK" and ctx.spec == 2 end,
    recommend = function(ctx)
        if ctx.known(109773) and ctx.selfBuffMissing(109773) and ctx.ready(109773) then return 109773 end
        if not ctx.hasAttackTarget() then return nil end
        local enemies = ctx.enemyCount()
        local fury = ctx.demonicFury()
        local inMeta = ctx.inMetamorphosis()
        local darkSoul = ctx.darkSoulActive(113861)
        local moltenCore = ctx.buffStacks("player", 122355)
        if inMeta then
            if ctx.debuffRem("target", 603, true) <= 30 and ctx.readyInRange(603) then return 603 end
            if enemies >= 5 and ctx.ready(104025) then return 104025 end
            if enemies >= 4 and ctx.readyInRange(103967) then return 103967 end
            if moltenCore > 0 and (darkSoul or fury >= 700 or ctx.targetHpPct() <= 25) and ctx.readyInRange(6353) then return 6353 end
            if ctx.readyInRange(103964) then return 103964 end
        else
            if ctx.debuffRem("target", 172, true) <= 6 and ctx.readyInRange(172) then return 172 end
            if ctx.debuffRem("target", 47960, true) <= 2 and ctx.readyInRange(105174) then return 105174 end
            if ctx.bossCombat() and fury >= 500 and ctx.ready(113861) then return 113861 end
            if ctx.known(104316) and ctx.bossCombat() and ctx.ready(104316) then return 104316 end
            if (fury >= 750 or darkSoul) and ctx.ready(103958) then return 103958 end
            if enemies >= 5 and ctx.ready(1949) then return 1949 end
            if moltenCore >= 8 and ctx.readyInRange(6353) then return 6353 end
            if ctx.readyInRange(686) then return 686 end
        end
        return nil
    end,
})

RegisterRotation("WARLOCK:3", {
    name = "Destruction Warlock",
    resource = "BURNING_EMBERS",
    enabled = function(ctx) return ctx.class == "WARLOCK" and ctx.spec == 3 end,
    recommend = function(ctx)
        if ctx.known(109773) and ctx.selfBuffMissing(109773) and ctx.ready(109773) then return 109773 end
        if not ctx.hasAttackTarget() then return nil end
        local enemies = ctx.enemyCount()
        local embers = ctx.burningEmbers()
        local targetHp = ctx.targetHpPct()
        local darkSoul = ctx.darkSoulActive(113858)
        if enemies >= 3 and embers >= 1 and ctx.buffRem("player", 108683) <= 0 and ctx.ready(108683) then return 108683 end
        if enemies >= 2 and ctx.groundReady(5740) then return 5740 end
        if enemies >= 2 and ctx.readyInRange(80240) then return 80240 end
        if ctx.debuffRem("target", 348, true) <= 7 and ctx.readyInRange(348) then return 348 end
        if ctx.bossCombat() and embers >= 2 and ctx.ready(113858) then return 113858 end
        if targetHp <= 20 and embers >= 1 and ctx.readyInRange(17877) then return 17877 end
        if targetHp > 20 and embers >= 1 and (embers >= 3.5 or darkSoul) and ctx.readyInRange(116858) then return 116858 end
        if ctx.readyInRange(17962) then return 17962 end
        if ctx.readyInRange(29722) then return 29722 end
        if ctx.readyInRange(686) then return 686 end
        return nil
    end,
})
RegisterRotation("MONK:1", {
    name = "Brewmaster Monk",
    resource = "CHI",
    enabled = function(ctx) return ctx.class == "MONK" and ctx.spec == 1 end,
    recommend = function(ctx)
        if ctx.known(115069) and ctx.selfBuffMissing(115069) and ctx.ready(115069) then return 115069 end
        if ctx.known(115921) and ctx.selfBuffMissing(115921) and ctx.ready(115921) then return 115921 end
        if not ctx.hasAttackTarget() then return nil end
        local enemies = ctx.enemyCount()
        local chi = ctx.chi()
        if ctx.lowSelf(65) and ctx.ready(115295) then return 115295 end
        if ctx.debuffRem("target", 121253, true) <= 3 and ctx.readyInRange(121253) then return 121253 end
        if ctx.readyInRange(121253) then return 121253 end
        if enemies >= 3 and ctx.ready(115181) then return 115181 end
        if chi >= 2 and ctx.readyInRange(100784) then return 100784 end
        if ctx.lowSelf(85) and ctx.ready(115072) then return 115072 end
        if enemies >= 4 and ctx.ready(101546) then return 101546 end
        if ctx.readyInRange(100787) then return 100787 end
        if ctx.readyInRange(100780) then return 100780 end
        return nil
    end,
})

RegisterRotation("MONK:2", {
    name = "Mistweaver Monk",
    resource = "CHI",
    enabled = function(ctx) return ctx.class == "MONK" and ctx.spec == 2 end,
    recommend = function(ctx)
        if ctx.known(115070) and ctx.selfBuffMissing(115070) and ctx.ready(115070) then return 115070 end
        if ctx.known(115921) and ctx.selfBuffMissing(115921) and ctx.ready(115921) then return 115921 end
        local unit = ctx.healUnit()
        local hp = ctx.unitHpPct(unit)
        local chi = ctx.chi()
        if hp < 95 and ctx.ready(115151) then return 115151 end
        if hp < 70 and ctx.ready(116670) and chi >= 2 then return 116670 end
        if hp < 55 and ctx.ready(116694) then return 116694 end
        if hp < 85 and chi >= 3 and ctx.ready(124682) then return 124682 end
        if hp < 90 and ctx.ready(115175) then return 115175 end
        if ctx.hasAttackTarget() and ctx.readyInRange(100780) then return 100780 end
        return nil
    end,
})

RegisterRotation("MONK:3", {
    name = "Windwalker Monk",
    resource = "CHI",
    enabled = function(ctx) return ctx.class == "MONK" and ctx.spec == 3 end,
    recommend = function(ctx)
        if ctx.known(103985) and ctx.selfBuffMissing(103985) and ctx.ready(103985) then return 103985 end
        if ctx.known(116781) and ctx.selfBuffMissing(116781) and ctx.ready(116781) then return 116781 end
        if not ctx.hasAttackTarget() then return nil end
        local enemies = ctx.enemyCount()
        local chi = ctx.chi()
        local energy = ctx.power(ctx.energyType)
        if ctx.targetHpPct() <= 10 and ctx.readyInRange(115080) then return 115080 end
        if ctx.debuffRem("target", 130320, true) <= 3 and ctx.readyInRange(107428) then return 107428 end
        if ctx.readyInRange(107428) then return 107428 end
        if ctx.buffRem("player", 125359) <= 3 and ctx.readyInRange(100787) then return 100787 end
        if ctx.bossCombat() and ctx.buffStacks("player", 125195) >= 10 and ctx.ready(116740) then return 116740 end
        if chi >= 3 and ctx.readyInRange(113656) then return 113656 end
        if enemies >= 3 and ctx.ready(101546) then return 101546 end
        if chi >= 2 and ctx.readyInRange(100784) then return 100784 end
        if energy <= 40 and ctx.ready(115288) then return 115288 end
        if ctx.readyInRange(100780) then return 100780 end
        return nil
    end,
})
local lastPrimaryRecommendation
local lastAlternateRecommendation
local lastDefensiveRecommendation
local lastThreatRecommendation
local lastInterruptRecommendation
local lastPetRecommendation
local lastUtilityRecommendation

local function PlayerBusyCasting()
    return (UnitCastingInfo and UnitCastingInfo("player")) or (UnitChannelInfo and UnitChannelInfo("player"))
end

local function ActiveRotation(ctx)
    local key = (ctx.class or "") .. ":" .. tostring(ctx.spec or 0)
    local module = rotationModules[key]
    if module and module.enabled and module.enabled(ctx) then
        lastActiveModuleKey = key
        lastActiveModuleReason = "direct spec match"
        return module
    end
    for _, candidateKey in ipairs(rotationModuleOrder) do
        local candidate = rotationModules[candidateKey]
        if candidate ~= module and candidate.enabled and candidate.enabled(ctx) then
            lastActiveModuleKey = candidateKey
            lastActiveModuleReason = "fallback match from class/spec signals"
            return candidate
        end
    end
    lastActiveModuleKey = nil
    lastActiveModuleReason = "no enabled module"
    return nil
end

local function GenericDefensiveRecommendation(ctx)
    local hp = ctx.unitHpPct("player")
    local spec = ctx.spec

    if ctx.class == "PALADIN" then
        local holyPower = ctx.holyPower()
        if hp <= 25 and ctx.cooldownReady(633) then return 633 end
        if hp <= 78 and holyPower >= 3 and ctx.cooldownReady(85673) then return 85673 end
        if hp <= 78 and holyPower >= 3 and ctx.cooldownReady(114163) then return 114163 end
        if hp <= 60 and ctx.cooldownReady(498) then return 498 end
        if hp <= 42 and ctx.cooldownReady(19750) then return 19750 end
        return nil
    end

    if ctx.class == "DRUID" then
        if hp <= 65 and ctx.cooldownReady(22812) then return 22812 end
        if hp <= 55 and ctx.cooldownReady(108238) then return 108238 end
        if spec == 3 and hp <= 70 and ctx.cooldownReady(22842) then return 22842 end
        if hp <= 45 and ctx.cooldownReady(18562) then return 18562 end
        return nil
    end

    if ctx.class == "MAGE" then
        if hp <= 35 and ctx.cooldownReady(45438) then return 45438 end
        if hp <= 70 and ctx.cooldownReady(115610) then return 115610 end
        if hp <= 75 and ctx.cooldownReady(11426) then return 11426 end
        return nil
    end

    if ctx.class == "HUNTER" then
        if hp <= 35 and ctx.cooldownReady(19263) then return 19263 end
        if hp <= 65 and ctx.cooldownReady(109304) then return 109304 end
        return nil
    end

    if ctx.class == "DEATHKNIGHT" then
        if hp <= 35 and ctx.cooldownReady(48743) then return 48743 end
        if hp <= 55 and ctx.cooldownReady(48792) then return 48792 end
        if spec == 1 and hp <= 70 and ctx.cooldownReady(55233) then return 55233 end
        if hp <= 65 and ctx.hasAttackTarget() and ctx.readyInRange(49998) then return 49998 end
        return nil
    end

    if ctx.class == "WARRIOR" then
        if hp <= 35 and ctx.cooldownReady(871) then return 871 end
        if hp <= 55 and ctx.cooldownReady(12975) then return 12975 end
        if hp <= 65 and ctx.cooldownReady(55694) then return 55694 end
        if hp <= 75 and ctx.hasAttackTarget() and ctx.readyInRange(34428) then return 34428 end
        return nil
    end

    if ctx.class == "ROGUE" then
        if hp <= 35 and ctx.cooldownReady(5277) then return 5277 end
        if hp <= 50 and ctx.cooldownReady(31224) then return 31224 end
        if hp <= 70 and ctx.cooldownReady(1966) then return 1966 end
        if hp <= 75 and ctx.comboPoints() >= 3 and ctx.cooldownReady(73651) then return 73651 end
        return nil
    end

    if ctx.class == "PRIEST" then
        if hp <= 35 and ctx.cooldownReady(19236) then return 19236 end
        if spec == 3 and hp <= 45 and ctx.cooldownReady(47585) then return 47585 end
        if hp <= 80 and ctx.cooldownReady(17) then return 17 end
        if hp <= 60 and ctx.cooldownReady(2061) then return 2061 end
        return nil
    end

    if ctx.class == "SHAMAN" then
        if hp <= 55 and ctx.cooldownReady(108271) then return 108271 end
        if hp <= 45 and ctx.cooldownReady(8004) then return 8004 end
        if hp <= 35 and ctx.cooldownReady(30884) then return 30884 end
        return nil
    end

    if ctx.class == "WARLOCK" then
        if hp <= 45 and ctx.cooldownReady(104773) then return 104773 end
        if hp <= 65 and ctx.cooldownReady(108359) then return 108359 end
        if UnitExists("pet") and not UnitIsDead("pet") and ctx.unitHpPct("pet") >= 35 and hp <= 50 and ctx.cooldownReady(755) then return 755 end
        return nil
    end

    if ctx.class == "MONK" then
        if hp <= 50 and ctx.cooldownReady(115203) then return 115203 end
        if spec == 1 and hp <= 70 and ctx.cooldownReady(115295) then return 115295 end
        if hp <= 65 and ctx.cooldownReady(115072) then return 115072 end
        if hp <= 55 and ctx.cooldownReady(122278) then return 122278 end
        if hp <= 55 and ctx.cooldownReady(122783) then return 122783 end
        return nil
    end

    return nil
end
local function IsTankModule(ctx, module)
    if module and module.tank then
        return true
    end
    if ctx.class == "DEATHKNIGHT" then return ctx.spec == 1 or ctx.hasBuff(48263) end
    if ctx.class == "DRUID" then return ctx.spec == 3 or (ctx.hasBuff(5487) and ctx.known(6795)) end
    if ctx.class == "MONK" then return ctx.spec == 1 or ctx.hasBuff(115069) end
    if ctx.class == "PALADIN" then return ctx.spec == 2 or ctx.hasBuff(25780) or ctx.known(31935) end
    if ctx.class == "WARRIOR" then return ctx.spec == 3 or ctx.hasBuff(71) end
    return false
end

local function TankTauntSpell(ctx)
    if ctx.class == "DEATHKNIGHT" then return 56222 end
    if ctx.class == "DRUID" then return 6795 end
    if ctx.class == "MONK" then return 115546 end
    if ctx.class == "PALADIN" then return 62124 end
    if ctx.class == "WARRIOR" then return 355 end
    return nil
end

local function TankBackupThreatSpell(ctx)
    if ctx.class == "PALADIN" and ctx.ready(31935) then return 31935 end
    if ctx.class == "WARRIOR" and ctx.readyInRange(23922) then return 23922 end
    if ctx.class == "DRUID" and ctx.readyInRange(33917) then return 33917 end
    if ctx.class == "DEATHKNIGHT" and ctx.readyInRange(49576) then return 49576 end
    if ctx.class == "MONK" and ctx.readyInRange(121253) then return 121253 end
    return nil
end

local function AddKnownHostileThreatUnit(units, seen, unit)
    if not unit or not UnitExists or not UnitExists(unit) or UnitIsDead(unit) or not UnitCanAttack("player", unit) then
        return
    end
    local guid = UnitGUID and UnitGUID(unit) or unit
    if guid and not seen[guid] then
        seen[guid] = true
        units[#units + 1] = unit
    end
end

local function AddNameplateThreatUnits(units, seen)
    if C_NamePlate and C_NamePlate.GetNamePlates then
        for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
            local unit = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
            AddKnownHostileThreatUnit(units, seen, unit)
        end
    end
    for i = 1, 40 do
        AddKnownHostileThreatUnit(units, seen, "nameplate" .. i)
    end
end

local function AddGroupTargetThreatUnits(units, seen)
    AddKnownHostileThreatUnit(units, seen, "pettarget")
    if IsInRaid and IsInRaid() then
        local count = GetNumGroupMembers and GetNumGroupMembers() or 0
        for i = 1, count do
            AddKnownHostileThreatUnit(units, seen, "raid" .. i .. "target")
            AddKnownHostileThreatUnit(units, seen, "raidpet" .. i .. "target")
        end
    else
        local count = GetNumSubgroupMembers and GetNumSubgroupMembers() or (GetNumPartyMembers and GetNumPartyMembers() or 0)
        for i = 1, count do
            AddKnownHostileThreatUnit(units, seen, "party" .. i .. "target")
            AddKnownHostileThreatUnit(units, seen, "partypet" .. i .. "target")
        end
    end
end

local function KnownHostileThreatUnits()
    local units, seen = {}, {}
    AddKnownHostileThreatUnit(units, seen, "target")
    AddKnownHostileThreatUnit(units, seen, "focus")
    AddKnownHostileThreatUnit(units, seen, "mouseover")
    for i = 1, 5 do
        AddKnownHostileThreatUnit(units, seen, "boss" .. i)
    end
    AddNameplateThreatUnits(units, seen)
    AddGroupTargetThreatUnits(units, seen)
    return units
end

local function GroupThreatUnits()
    local units = {}
    if IsInRaid and IsInRaid() then
        local count = GetNumGroupMembers and GetNumGroupMembers() or 0
        for i = 1, count do
            local unit = "raid" .. i
            if UnitExists(unit) and not UnitIsUnit(unit, "player") then
                units[#units + 1] = unit
            end
        end
    else
        local count = GetNumSubgroupMembers and GetNumSubgroupMembers() or (GetNumPartyMembers and GetNumPartyMembers() or 0)
        for i = 1, count do
            local unit = "party" .. i
            if UnitExists(unit) then
                units[#units + 1] = unit
            end
        end
    end
    return units
end

local function FriendlyUnitTankingMob(member, mob)
    if not UnitExists(member) or UnitIsDead(member) then
        return false
    end
    if UnitDetailedThreatSituation then
        local isTanking, status = UnitDetailedThreatSituation(member, mob)
        if isTanking or status == 3 then
            return true
        end
    end
    return false
end

local function HostileUnitTargetsGroupMember(mob, groupUnits)
    local targetUnit = mob .. "target"
    if UnitExists(targetUnit) and not UnitIsUnit(targetUnit, "player") and UnitCanAssist("player", targetUnit) then
        return true, UnitName(targetUnit) or targetUnit
    end
    for _, member in ipairs(groupUnits) do
        if FriendlyUnitTankingMob(member, mob) then
            return true, UnitName(member) or member
        end
    end
    return false, nil
end

local function FindLooseTankThreatUnit()
    local units = KnownHostileThreatUnits()
    if #units == 0 then
        return nil, "no known hostile units"
    end
    local groupUnits = GroupThreatUnits()
    for _, unit in ipairs(units) do
        local playerTanking, status
        if UnitDetailedThreatSituation then
            playerTanking, status = UnitDetailedThreatSituation("player", unit)
        end
        if not playerTanking and status ~= 3 then
            local targetsGroupMember, targetName = HostileUnitTargetsGroupMember(unit, groupUnits)
            if targetsGroupMember then
                return unit, "group aggro: " .. tostring(targetName or "party")
            end
            if status ~= nil and status < 3 then
                return unit, "low tank threat"
            end
        end
    end
    return nil, "all known mobs on tank"
end

local function GenericThreatRecommendation(ctx, module)
    if not IsTankModule(ctx, module) then
        return nil
    end
    local inCombat = UnitAffectingCombat and UnitAffectingCombat("player")
    if not inCombat and ctx.hasAttackTarget and ctx.hasAttackTarget() then
        inCombat = UnitAffectingCombat("target")
    end
    if not inCombat then
        return nil
    end

    local looseUnit, looseReason = FindLooseTankThreatUnit()
    if looseUnit then
        lastRecommendationReasons.threatDetail = looseReason or "loose threat"
        local taunt = TankTauntSpell(ctx)
        if taunt and ctx.ready(taunt) then
            if UnitIsUnit(looseUnit, "target") then
                if ctx.inRange(taunt) then
                    return taunt
                end
            else
                return taunt
            end
        end
        return TankBackupThreatSpell(ctx)
    end

    if not ctx.hasAttackTarget() then
        return nil
    end

    local isTanking, status
    if UnitDetailedThreatSituation then
        isTanking, status = UnitDetailedThreatSituation("player", "target")
    end
    if isTanking then
        if status == 2 then
            lastRecommendationReasons.threatDetail = "target threat lead low"
            return TankBackupThreatSpell(ctx)
        end
        return nil
    end
    if status == 3 then
        return nil
    end

    if status == nil and UnitExists("targettarget") then
        if UnitIsUnit("targettarget", "player") then
            return nil
        end
    elseif status == nil then
        return nil
    end

    lastRecommendationReasons.threatDetail = "target unsafe"
    local taunt = TankTauntSpell(ctx)
    if taunt and ctx.ready(taunt) and ctx.inRange(taunt) then
        return taunt
    end
    return TankBackupThreatSpell(ctx)
end
local INTERRUPT_SPELLS_BY_CLASS = {
    DEATHKNIGHT = { 47528, 47476 },
    DRUID = { 106839, 80965 },
    HUNTER = { 147362, 34490 },
    MAGE = { 2139 },
    MONK = { 116705 },
    PALADIN = { 96231, 31935 },
    PRIEST = { 15487 },
    ROGUE = { 1766 },
    SHAMAN = { 57994 },
    WARLOCK = { 119910, 19647, 132409, 119911, 115781 },
    WARRIOR = { 6552 },
}

local STUN_SPELLS_BY_CLASS = {
    DEATHKNIGHT = { 108194, 115001, 47481 },
    DRUID = { 5211, 22570 },
    HUNTER = { 19577, 19503, 109248 },
    MAGE = { 44572, 31661, 113724, 82691 },
    MONK = { 119381, 119392, 115078 },
    PALADIN = { 853, 105593, 115750 },
    PRIEST = { 64044, 8122 },
    ROGUE = { 408, 1833, 1776 },
    SHAMAN = { 108269 },
    WARLOCK = { 30283, 6789 },
    WARRIOR = { 46968, 107570, 100 },
}

local CONTROL_SPELLS_BY_CLASS = {
    DRUID = { 33786, 2637 },
    HUNTER = { 19386 },
    MAGE = { 118, 113724, 82691 },
    MONK = { 115078 },
    PALADIN = { 20066 },
    PRIEST = { 8122, 64044 },
    ROGUE = { 2094 },
    SHAMAN = { 51514 },
    WARLOCK = { 5782, 5484, 6789 },
}

local function UnitInterruptibleCast(unit)
    if not UnitExists or not UnitExists(unit) or UnitIsDead(unit) then
        return nil
    end
    local name, notInterruptible
    if UnitCastingInfo then
        local castName, _, _, _, _, _, _, _, castNotInterruptible = UnitCastingInfo(unit)
        if castName then
            name = castName
            notInterruptible = castNotInterruptible
        end
    end
    if not name and UnitChannelInfo then
        local channelName, _, _, _, _, _, _, channelNotInterruptible = UnitChannelInfo(unit)
        if channelName then
            name = channelName
            notInterruptible = channelNotInterruptible
        end
    end
    if not name or notInterruptible then
        return nil
    end
    return name
end

local function FindInterruptibleCastUnit()
    local units = KnownHostileThreatUnits()
    for _, unit in ipairs(units) do
        local name = UnitInterruptibleCast(unit)
        if name then
            return unit, name
        end
    end
    return nil, nil
end

local function ReadyControlSpellForUnit(ctx, spellIDs, unit)
    if not spellIDs then
        return nil
    end
    for _, spellID in ipairs(spellIDs) do
        if ctx.ready(spellID) then
            if UnitIsUnit(unit, "target") then
                if ctx.inRange(spellID) then
                    return spellID
                end
            else
                return spellID
            end
        end
    end
    return nil
end

local function GenericInterruptRecommendation(ctx)
    local unit, castName = FindInterruptibleCastUnit()
    if not unit then
        return nil, "no interruptible cast"
    end

    local interrupt = ReadyControlSpellForUnit(ctx, INTERRUPT_SPELLS_BY_CLASS[ctx.class], unit)
    if interrupt then
        return interrupt, UnitIsUnit(unit, "target") and "interruptible target cast" or ("interrupt off-target cast: " .. tostring(castName))
    end

    local stun = ReadyControlSpellForUnit(ctx, STUN_SPELLS_BY_CLASS[ctx.class], unit)
    if stun then
        return stun, UnitIsUnit(unit, "target") and "stun backup for cast" or ("stun off-target cast: " .. tostring(castName))
    end

    local control = ReadyControlSpellForUnit(ctx, CONTROL_SPELLS_BY_CLASS[ctx.class], unit)
    if control then
        return control, UnitIsUnit(unit, "target") and "control backup for cast" or ("control off-target cast: " .. tostring(castName))
    end

    return nil, "interrupt/control unavailable"
end
local function InGroupContent()
    local instanceType
    if GetInstanceInfo then
        _, instanceType = GetInstanceInfo()
    end
    if instanceType == "party" or instanceType == "raid" or instanceType == "scenario" then
        return true
    end
    return IsInGroup and IsInGroup() or false
end

local function PetNameLooksLike(...)
    if not UnitExists("pet") or UnitIsDead("pet") then
        return false
    end
    local petName = UnitName("pet") or ""
    local family = UnitCreatureFamily and UnitCreatureFamily("pet") or ""
    local haystack = (petName .. " " .. family):lower()
    for i = 1, select("#", ...) do
        local needle = select(i, ...)
        if needle and haystack:find(tostring(needle):lower(), 1, true) then
            return true
        end
    end
    return false
end

local function WarlockPetMatchesSpell(spellID)
    if spellID == 30146 then return PetNameLooksLike("felguard", "wrathguard") end
    if spellID == 691 then return PetNameLooksLike("felhunter", "observer") end
    if spellID == 697 then return PetNameLooksLike("voidwalker", "voidlord") end
    if spellID == 688 then return PetNameLooksLike("imp", "fel imp") end
    if spellID == 712 then return PetNameLooksLike("succubus", "shivarra") end
    return false
end

local function PreferredWarlockPetSpell(ctx)
    if GetWarlockPetMode() == PET_OFF or ctx.buffRem("player", 108503) > 0 then
        return nil
    end
    if ctx.spec == 2 and ctx.known(30146) then
        return 30146
    end
    local mode = GetWarlockPetMode()
    if mode == PET_AUTO then
        mode = InGroupContent() and PET_DUNGEON or PET_SOLO
    end
    if mode == PET_DUNGEON then
        if ctx.known(691) then return 691 end
        if ctx.known(688) then return 688 end
        if ctx.known(712) then return 712 end
        if ctx.known(697) then return 697 end
    elseif mode == PET_SOLO then
        if ctx.known(697) then return 697 end
        if ctx.known(688) then return 688 end
        if ctx.known(712) then return 712 end
        if ctx.known(691) then return 691 end
    end
    return ctx.readyAny(nil, nil, 691, 688, 697, 712, 30146)
end
local function GenericPetRecommendation(ctx)
    if ctx.class == "HUNTER" then
        if ctx.known(982) and UnitExists("pet") and UnitIsDead("pet") and ctx.ready(982) then return 982, "pet dead" end
        if ctx.known(883) and not ctx.petAlive() and ctx.ready(883) then return 883, "pet missing" end
        if ctx.petAlive() and ctx.petHpPct() < 70 and ctx.ready(136) then return 136, "pet low health" end
    elseif ctx.class == "WARLOCK" then
        local preferredPet = PreferredWarlockPetSpell(ctx)
        if preferredPet and ctx.ready(preferredPet) then
            if not ctx.hasPetOrSacrifice() then
                return preferredPet, "preferred pet missing"
            end
            if ctx.petAlive() and not WarlockPetMatchesSpell(preferredPet) and (not UnitAffectingCombat or not UnitAffectingCombat("player")) then
                return preferredPet, "preferred pet for " .. GetWarlockPetMode()
            end
        end
        if ctx.petAlive() and ctx.petHpPct() < 65 and ctx.cooldownReady(755) then return 755, "pet low health" end
    elseif ctx.class == "MAGE" and ctx.spec == 3 then
        if not ctx.petAlive() and ctx.ready(31687) then return 31687, "water elemental missing" end
    end
    return nil, "pet ok"
end


local function GenericUtilityRecommendation(ctx)
    if not ctx.hasAttackTarget() then
        return nil, "no hostile target"
    end
    if ctx.class == "DRUID" then
        if ctx.debuffAnyRem("target", false, 770, 113746) <= 0 and ctx.ready(770) and ctx.inRange(770) then
            return 770, "armor debuff missing"
        end
    elseif ctx.class == "WARLOCK" then
        if ctx.debuffAnyRem("target", false, 1490, 116202) <= 0 and ctx.ready(1490) and ctx.inRange(1490) then
            return 1490, "magic debuff missing"
        end
    end
    return nil, "utility ok"
end
local function GenericFallbackRecommendation(ctx, module)
    if not ctx.hasAttackTarget() then
        return nil, "no hostile target"
    end
    local class = ctx.class
    if class == "HUNTER" then
        local focus = ctx.power(ctx.focusType)
        if focus >= 30 and ctx.ready(3044, 30, ctx.focusType) and ctx.inRange(3044) then return 3044, "focus dump fallback" end
        local builder = ctx.readyAnyInRange(77767, 56641, 75)
        if builder then return builder, "focus builder/ranged fallback" end
    elseif class == "MAGE" then
        local spell = ctx.readyAnyInRange(30451, 133, 116, 44614, 2948)
        if spell then return spell, "ranged caster fallback" end
    elseif class == "PALADIN" then
        local spell = ctx.readyAnyInRange(20271, 35395, 879)
        if spell then return spell, "melee/ranged fallback" end
    elseif class == "DRUID" then
        local spell = ctx.readyAnyInRange(5176, 33876, 5221, 33917, 8921)
        if spell then return spell, "form fallback" end
    elseif class == "PRIEST" then
        local spell = ctx.readyAnyInRange(589, 8092, 585)
        if spell then return spell, "caster fallback" end
    elseif class == "SHAMAN" then
        local spell = ctx.readyAnyInRange(403, 17364, 8050)
        if spell then return spell, "shaman fallback" end
    elseif class == "WARLOCK" then
        local spell = ctx.readyAnyInRange(686, 103103, 29722)
        if spell then return spell, "warlock fallback" end
    elseif class == "WARRIOR" then
        local spell = ctx.readyAnyInRange(78, 100, 23881, 23922)
        if spell then return spell, "warrior fallback" end
    elseif class == "DEATHKNIGHT" then
        local spell = ctx.readyAnyInRange(49998, 55050, 49184, 45462)
        if spell then return spell, "death knight fallback" end
    elseif class == "ROGUE" then
        local spell = ctx.readyAnyInRange(1752, 53)
        if spell then return spell, "rogue fallback" end
    elseif class == "MONK" then
        local spell = ctx.readyAnyInRange(100780, 100787, 121253)
        if spell then return spell, "monk fallback" end
    end
    return nil, "no fallback ready or in range"
end
local function ComputeRecommendations()
    if PlayerBusyCasting() and (lastPrimaryRecommendation or lastAlternateRecommendation or lastDefensiveRecommendation or lastThreatRecommendation or lastInterruptRecommendation or lastPetRecommendation or lastUtilityRecommendation) then
        return lastPrimaryRecommendation, lastAlternateRecommendation, lastDefensiveRecommendation, lastThreatRecommendation, lastInterruptRecommendation, lastPetRecommendation, lastUtilityRecommendation
    end
    local ctx = BuildContext()
    local module = ActiveRotation(ctx)
    lastRecommendationReasons = {
        module = module and module.name or "none",
        moduleKey = lastActiveModuleKey or "none",
        moduleSource = lastActiveModuleReason or "none",
        opener = tostring(ctx.isOpener and ctx.isOpener(8) or false),
        boss = tostring(ctx.targetIsBoss and ctx.targetIsBoss() or false),
        mode = tostring(ctx.targetMode and ctx.targetMode() or MODE_AUTO),
        targetAge = string.format("%.1f", ctx.targetAge and ctx.targetAge() or 0),
    }
    if not module or not module.recommend then
        lastPrimaryRecommendation = nil
        lastAlternateRecommendation = nil
        lastDefensiveRecommendation = nil
        lastThreatRecommendation = nil
        lastInterruptRecommendation = nil
        lastPetRecommendation = nil
        lastUtilityRecommendation = nil
        lastRecommendationReasons.primary = "no module"
        return nil, nil, nil, nil, nil, nil, nil
    end
    local primary, alternate = module.recommend(ctx)
    if primary then
        lastRecommendationReasons.primary = "module priority"
    else
        primary, lastRecommendationReasons.primary = GenericFallbackRecommendation(ctx, module)
    end
    lastRecommendationReasons.alternate = alternate and "alternate module option" or "none"

    local defensive = nil
    if module.defensive then
        defensive = module.defensive(ctx)
        if defensive then
            lastRecommendationReasons.defensive = "module defensive"
        end
    end
    if not defensive then
        defensive = GenericDefensiveRecommendation(ctx)
        lastRecommendationReasons.defensive = defensive and "generic defensive threshold" or "none"
    end

    local threat = GenericThreatRecommendation(ctx, module)
    lastRecommendationReasons.threat = threat and "tank threat unsafe" or "none"
    local interrupt, interruptReason = GenericInterruptRecommendation(ctx)
    local pet, petReason = GenericPetRecommendation(ctx)
    local utility, utilityReason = GenericUtilityRecommendation(ctx)
    lastRecommendationReasons.interrupt = interruptReason or "none"
    lastRecommendationReasons.pet = petReason or "none"
    lastRecommendationReasons.utility = utilityReason or "none"

    lastPrimaryRecommendation = primary
    lastAlternateRecommendation = alternate
    lastDefensiveRecommendation = defensive
    lastThreatRecommendation = threat
    lastInterruptRecommendation = interrupt
    lastPetRecommendation = pet
    lastUtilityRecommendation = utility
    return primary, alternate, defensive, threat, interrupt, pet, utility
end

local function ComputeResourceInfo()
    local ctx = BuildContext()
    local module = ActiveRotation(ctx)
    if not module then
        return 0, 0, nil, nil
    end
    if module.resource == "COMBO_POINTS" then
        return GetComboPoints("player", "target") or 0, 5, module.resource, 132127
    end
    if module.resource == "ARCANE_CHARGES" then
        return ctx.arcaneCharges(), ctx.arcaneChargesMax(), module.resource, 135734, ctx.arcaneChargeRemaining()
    end
    if module.resource == "HOLY_POWER" then
        return ctx.holyPower(), ctx.holyPowerMax(), module.resource, 135920
    end
    if module.resource == "CHI" then
        return ctx.chi(), ctx.chiMax(), module.resource, 606552
    end
    if module.resource == "SHADOW_ORBS" then
        return ctx.shadowOrbs(), 3, module.resource, 136224
    end
    if module.resource == "SOUL_SHARDS" then
        return ctx.soulShards(), 4, module.resource, 538443
    end
    if module.resource == "BURNING_EMBERS" then
        return math.floor(ctx.burningEmbers()), math.floor(ctx.burningEmbersMax()), module.resource, 460700
    end
    if module.resource == "DEMONIC_FURY" then
        local maxFury = ctx.demonicFuryMax()
        return math.floor((ctx.demonicFury() / maxFury) * 4 + 0.0001), 4, module.resource, 136172
    end
    return 0, 0, module.resource, nil
end

function _G.RaynnaRotationHelperGetRecommendation(slot)
    local primary, alternate, defensive, threat, interrupt, pet, utility = ComputeRecommendations()
    if slot == 7 then
        return utility
    end
    if slot == 6 then
        return pet
    end
    if slot == 5 then
        return interrupt
    end
    if slot == 4 then
        return threat
    end
    if slot == 3 then
        return defensive
    end
    if slot == 2 then
        return alternate
    end
    return primary
end

function _G.RaynnaRotationHelperGetResourceInfo()
    return ComputeResourceInfo()
end

local function BuildGroup(includeChildren)
    local children = {}
    if includeChildren then
        children = { CHILD_ID, ALT_CHILD_ID, DEFENSIVE_CHILD_ID, THREAT_CHILD_ID, INTERRUPT_CHILD_ID, PET_CHILD_ID, UTILITY_CHILD_ID }
        for _, quality in ipairs(GROUND_AOE_QUALITIES) do table.insert(children, GROUND_AOE_INDICATOR_IDS[quality]) end
        table.insert(children, RESOURCE_GROUP_ID)
    end
    return {
        id = TARGET_ID,
        uid = "raynna-rotation-helper-group",
        regionType = "group",
        controlledChildren = children,
        xOffset = 0,
        yOffset = -120,
        anchorPoint = "CENTER",
        anchorFrameType = "SCREEN",
        selfPoint = "CENTER",
        frameStrata = 4,
        alpha = 1,
        scale = 1,
        load = { use_petbattle = false, use_vehicleUi = false, use_never = false, class = { multi = {} }, spec = { multi = {} }, size = { multi = {} }, talent = { multi = {} } },
        triggers = { { trigger = { type = "aura2", event = "Health", unit = "player", debuffType = "HELPFUL", names = {}, spellIds = {} }, untrigger = {} } },
        animation = { start = { type = "none" }, main = { type = "none" }, finish = { type = "none" } },
        actions = { start = {}, init = {}, finish = {} },
        conditions = {},
        subRegions = {},
        config = {},
        authorOptions = {},
        information = { showNilIsFalse = true },
    }
end

local function BuildAura(parentId, slot, forceChild)
    slot = slot or 1
    local isAlt = slot == 2
    local isDefensive = slot == 3
    local isThreat = slot == 4
    local isInterrupt = slot == 5
    local isPet = slot == 6
    local isUtility = slot == 7
    local showGcd = slot == 1 or slot == 2
    local childMode = parentId or forceChild
    local auraId = CHILD_ID
    local auraUid = ACTION_UIDS[1]
    local displayIcon = 132135
    local customSource = PRIMARY_NEXT_ACTION_SOURCE
    local xOffset = -28
    local yOffset = 0
    local size = 48
    local textSize = 16
    local glowColor = { 1, 1, 1, 1 }

    if isAlt then
        auraId = ALT_CHILD_ID
        auraUid = ACTION_UIDS[2]
        displayIcon = 132122
        customSource = ALT_NEXT_ACTION_SOURCE
        xOffset = 28
    elseif isDefensive then
        auraId = DEFENSIVE_CHILD_ID
        auraUid = ACTION_UIDS[3]
        displayIcon = 135920
        customSource = DEFENSIVE_NEXT_ACTION_SOURCE
        xOffset = 76
        yOffset = -7
        size = 34
        textSize = 12
        glowColor = { 0.25, 0.95, 0.65, 1 }
    elseif isThreat then
        auraId = THREAT_CHILD_ID
        auraUid = ACTION_UIDS[4]
        displayIcon = 132270
        customSource = THREAT_ACTION_SOURCE
        xOffset = -76
        yOffset = -7
        size = 34
        textSize = 12
        glowColor = { 1, 0.08, 0.04, 1 }
    elseif isInterrupt then
        auraId = INTERRUPT_CHILD_ID
        auraUid = ACTION_UIDS[5]
        displayIcon = 132219
        customSource = INTERRUPT_ACTION_SOURCE
        xOffset = 0
        yOffset = 48
        size = 36
        textSize = 12
        glowColor = { 1, 0.82, 0.16, 1 }
    elseif isPet then
        auraId = PET_CHILD_ID
        auraUid = ACTION_UIDS[6]
        displayIcon = 132161
        customSource = PET_ACTION_SOURCE
        xOffset = 116
        yOffset = -7
        size = 34
        textSize = 12
        glowColor = { 0.45, 0.72, 1, 1 }
    elseif isUtility then
        auraId = UTILITY_CHILD_ID
        auraUid = ACTION_UIDS[7]
        displayIcon = 136033
        customSource = UTILITY_ACTION_SOURCE
        xOffset = -116
        yOffset = -7
        size = 34
        textSize = 12
        glowColor = { 1, 0.64, 0.18, 1 }
    end

    return {
        id = childMode and auraId or TARGET_ID,
        uid = auraUid,
        parent = parentId,
        regionType = "icon",
        icon = true,
        iconSource = -1,
        displayIcon = displayIcon,
        width = size,
        height = size,
        xOffset = parentId and xOffset or 0,
        yOffset = parentId and yOffset or -120,
        anchorPoint = "CENTER",
        anchorFrameType = "SCREEN",
        selfPoint = "CENTER",
        frameStrata = 4,
        alpha = 1,
        zoom = 0.6,
        color = { 1, 1, 1, 1 },
        cooldown = true,
        cooldownSwipe = true,
        cooldownEdge = showGcd,
        cooldownTextDisabled = true,
        useCooldownModRate = false,
        keepAspectRatio = true,
        internalVersion = 90,
        load = {
            use_petbattle = false,
            use_vehicleUi = false,
            use_never = false,
            class = { multi = {} },
            class_and_spec = { multi = {} },
            talent = { multi = {} },
            spec = { multi = {} },
            size = { multi = {} },
        },
        triggers = {
            {
                trigger = {
                    type = "custom",
                    custom_type = "status",
                    check = "update",
                    onUpdateThrottle = 0.1,
                    custom = customSource,
                    customDuration = showGcd and GCD_DURATION_SOURCE or "",
                    customIcon = ICON_SOURCE,
                    customName = KEYBIND_SOURCE,
                    debuffType = "HELPFUL",
                },
                untrigger = {},
            },
            disjunctive = "any",
            activeTriggerMode = -10,
        },
        subRegions = {
            { type = "subbackground" },
            { type = "subborder", border_visible = true, border_size = 1, border_offset = 1, border_edge = "Square Full White", border_color = { 0, 0, 0, 1 } },
            { type = "subglow", glow = true, glowType = "Proc", glowFrequency = 0.25, glowDuration = 1, glowThickness = 1, glowScale = 1, glowLength = 10, glowLines = 8, glowBorder = false, glowColor = glowColor },
            { type = "subtext", text_text = "%n", text_visible = true, text_font = "Expressway", text_fontSize = textSize, text_fontType = "OUTLINE", text_color = { 1, 1, 1, 1 }, text_shadowColor = { 0, 0, 0, 1 }, text_shadowXOffset = 2, text_shadowYOffset = -2, text_selfPoint = "AUTO", text_anchorXOffset = 0, text_anchorYOffset = -2, anchor_point = "INNER_BOTTOM", anchorXOffset = 0, anchorYOffset = 0, text_justify = "CENTER", text_wordWrap = "WordWrap", text_automaticWidth = "Auto", text_fixedWidth = 64, rotateText = "NONE" },
        },
        animation = {
            start = { type = "none", easeType = "none", easeStrength = 3, duration_type = "seconds" },
            main = { type = "none", easeType = "none", easeStrength = 3, duration_type = "seconds" },
            finish = { type = "none", easeType = "none", easeStrength = 3, duration_type = "seconds" },
        },
        actions = { start = {}, init = {}, finish = {} },
        conditions = {},
        authorOptions = {},
        config = {},
        information = { showNilIsFalse = true, forceEvents = false, ignoreOptionsEventErrors = false },
    }
end


local function BuildGroundAoeIndicator(parentId, quality)
    local color = GROUND_AOE_COLORS[quality] or { 1, 1, 1, 1 }
    return {
        id = GROUND_AOE_INDICATOR_IDS[quality],
        uid = GROUND_AOE_INDICATOR_UIDS[quality],
        parent = parentId,
        regionType = "icon",
        icon = true,
        iconSource = -1,
        displayIcon = "Interface\\Buttons\\WHITE8X8",
        width = 34,
        height = 34,
        xOffset = parentId and 78 or 0,
        yOffset = parentId and 28 or -120,
        anchorPoint = "CENTER",
        anchorFrameType = "SCREEN",
        selfPoint = "CENTER",
        frameStrata = 4,
        alpha = 1,
        zoom = 0,
        color = color,
        cooldown = false,
        cooldownTextDisabled = true,
        keepAspectRatio = true,
        internalVersion = 90,
        load = { use_petbattle = false, use_vehicleUi = false, use_never = false, class = { multi = {} }, class_and_spec = { multi = {} }, talent = { multi = {} }, spec = { multi = {} }, size = { multi = {} } },
        triggers = {
            {
                trigger = {
                    type = "custom",
                    custom_type = "status",
                    check = "update",
                    onUpdateThrottle = 0.1,
                    custom = GROUND_AOE_TRIGGER_TEMPLATE:gsub("%%%%QUALITY%%%%", quality),
                    customName = GROUND_AOE_NAME_SOURCE,
                    debuffType = "HELPFUL",
                },
                untrigger = {},
            },
            disjunctive = "any",
            activeTriggerMode = -10,
        },
        subRegions = {
            { type = "subbackground" },
            { type = "subborder", border_visible = true, border_size = 2, border_offset = 1, border_edge = "Square Full White", border_color = { 0, 0, 0, 1 } },
            { type = "subtext", text_text = "%n", text_visible = true, text_font = "Expressway", text_fontSize = 10, text_fontType = "OUTLINE", text_color = { 1, 1, 1, 1 }, text_shadowColor = { 0, 0, 0, 1 }, text_shadowXOffset = 1, text_shadowYOffset = -1, text_selfPoint = "AUTO", text_anchorXOffset = 0, text_anchorYOffset = 0, anchor_point = "CENTER", anchorXOffset = 0, anchorYOffset = 0, text_justify = "CENTER", text_wordWrap = "WordWrap", text_automaticWidth = "Auto", text_fixedWidth = 40, rotateText = "NONE" },
        },
        animation = { start = { type = "none" }, main = { type = "none" }, finish = { type = "none" } },
        actions = { start = {}, init = {}, finish = {} },
        conditions = {},
        authorOptions = {},
        config = {},
        information = { showNilIsFalse = true, forceEvents = false, ignoreOptionsEventErrors = false },
    }
end
local function ClearGeneratedTextFields(id)
    local data = WeakAurasSaved.displays[id]
    if data then
        data.customText = nil
        data.customTextUpdate = nil
    end
end


local RESOURCE_COLORS = {
    COMBO_POINTS = { 1, 0.090196080505848, 0, 1 },
    ARCANE_CHARGES = { 0.58, 0.2, 1, 1 },
    HOLY_POWER = { 1, 0.82, 0.18, 1 },
    CHI = { 0.1, 0.95, 0.55, 1 },
    SHADOW_ORBS = { 0.62, 0.22, 0.92, 1 },
    SOUL_SHARDS = { 0.55, 0.85, 1, 1 },
    BURNING_EMBERS = { 1, 0.34, 0.08, 1 },
    DEMONIC_FURY = { 0.58, 0.12, 0.9, 1 },
}


local function ResourceColor(resource)
    local color = RESOURCE_COLORS[resource or ""] or { 1, 1, 1, 1 }
    return { color[1], color[2], color[3], color[4] }
end

local function GenericLoad()
    return { use_petbattle = false, use_vehicleUi = false, use_never = false, class = { multi = {} }, class_and_spec = { multi = {} }, talent = { multi = {} }, spec = { multi = {} }, size = { multi = {} } }
end

local function DeepCopy(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local copy = {}
    seen[value] = copy
    for key, item in pairs(value) do
        copy[DeepCopy(key, seen)] = DeepCopy(item, seen)
    end
    return copy
end

local function ResourceXOffset(index)
    return (index - 3) * 35
end

local function ResourceFallbackGroup(parentId, includeChildren)
    local children = {}
    if includeChildren then
        for i = 1, #RESOURCE_IDS do table.insert(children, RESOURCE_IDS[i]) end
        for i = 1, #RESOURCE_OUTLINE_IDS do table.insert(children, RESOURCE_OUTLINE_IDS[i]) end
        for i = 1, #RESOURCE_GCD_IDS do table.insert(children, RESOURCE_GCD_IDS[i]) end
    end
    return {
        id = RESOURCE_GROUP_ID,
        uid = "raynna-rotation-resource-group",
        parent = parentId,
        regionType = "group",
        controlledChildren = children,
        xOffset = -323.63379956615,
        yOffset = -67.929352127084,
        anchorPoint = "CENTER",
        anchorFrameType = "SCREEN",
        selfPoint = "BOTTOMLEFT",
        frameStrata = 1,
        alpha = 1,
        scale = 0.55,
        load = GenericLoad(),
        triggers = { { trigger = { type = "aura2", event = "Health", unit = "player", debuffType = "HELPFUL", names = {}, spellIds = {} }, untrigger = {} } },
        animation = { start = { type = "none" }, main = { type = "none" }, finish = { type = "none" } },
        actions = { start = {}, init = {}, finish = {} },
        conditions = {},
        subRegions = {},
        config = {},
        authorOptions = {},
        information = { showNilIsFalse = true, groupOffset = true, forceEvents = true, ignoreOptionsEventErrors = true },
    }
end

local function FinalizeResourceClone(data, id, uid, parentId)
    data.id = id
    data.uid = uid
    data.parent = parentId
    data.load = GenericLoad()
    data.wagoID = nil
    data.url = nil
    data.semver = nil
    data.version = nil
    data.tocversion = nil
    data.source = nil
    data.preferToUpdate = false
    return data
end

local function BuildResourceGroup(parentId, includeChildren)
    return ResourceFallbackGroup(parentId, includeChildren)
end

local function BuildResourceFillAura(parentId, index, forceChild)
    local childMode = parentId or forceChild
    local id = childMode and RESOURCE_IDS[index] or TARGET_ID
    local data = {
        regionType = "texture",
        texture = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Circle_Smooth_Border",
        textureWrapMode = "CLAMP",
        blendMode = "BLEND",
        width = 42.76575088501,
        height = 42.765598297119,
        xOffset = ResourceXOffset(index),
        yOffset = -165,
        anchorPoint = "CENTER",
        anchorFrameType = "SCREEN",
        selfPoint = "CENTER",
        frameStrata = 3,
        alpha = 1,
        subRegions = { { type = "subbackground" } },
    }
    local resource = select(3, ComputeResourceInfo())
    FinalizeResourceClone(data, id, "raynna-rotation-cp-fill-" .. index, parentId)
    data.color = ResourceColor(resource)
    data.triggers = {
        {
            trigger = { type = "custom", custom_type = "status", check = "update", onUpdateThrottle = 0.1, custom = RESOURCE_TRIGGER_TEMPLATE:gsub("%%%%INDEX%%%%", tostring(index)), debuffType = "HELPFUL" },
            untrigger = {},
        },
        disjunctive = "all",
        activeTriggerMode = -10,
    }
    return data
end

local function BuildResourceBlackOutlineAura(parentId, index, forceChild)
    local childMode = parentId or forceChild
    local id = childMode and RESOURCE_OUTLINE_IDS[index] or TARGET_ID
    local data = {
        regionType = "texture",
        texture = "Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Auras\\Aura73",
        textureWrapMode = "CLAMP",
        blendMode = "BLEND",
        width = 75,
        height = 75,
        xOffset = ResourceXOffset(index),
        yOffset = -165,
        anchorPoint = "CENTER",
        anchorFrameType = "SCREEN",
        selfPoint = "CENTER",
        frameStrata = 3,
        alpha = 1,
        subRegions = { { type = "subbackground" } },
    }
    FinalizeResourceClone(data, id, "raynna-rotation-cp-black-outline-" .. index, parentId)
    data.color = { 0, 0, 0, 1 }
    data.triggers = {
        {
            trigger = { type = "custom", custom_type = "status", check = "update", onUpdateThrottle = 0.1, custom = RESOURCE_SLOT_TRIGGER_TEMPLATE:gsub("%%%%INDEX%%%%", tostring(index)), debuffType = "HELPFUL" },
            untrigger = {},
        },
        disjunctive = "any",
        activeTriggerMode = -10,
    }
    return data
end

local function BuildResourceGcdAura(parentId, index, forceChild)
    local childMode = parentId or forceChild
    local id = childMode and RESOURCE_GCD_IDS[index] or TARGET_ID
    local data = {
        regionType = "progresstexture",
        texture = "Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Auras\\Aura73",
        foregroundTexture = "Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Auras\\Aura73",
        sameTexture = true,
        textureWrapMode = "CLAMP",
        blendMode = "BLEND",
        width = 63,
        height = 63,
        xOffset = ResourceXOffset(index),
        yOffset = -165,
        anchorPoint = "CENTER",
        anchorFrameType = "SCREEN",
        selfPoint = "CENTER",
        frameStrata = 3,
        alpha = 1,
        subRegions = {},
    }
    FinalizeResourceClone(data, id, "raynna-rotation-cp-yellow-gcd-" .. index, parentId)
    data.triggers = {
        {
            trigger = {
                type = "spell",
                event = "Global Cooldown",
                unit = "player",
                use_unit = true,
                unevent = "auto",
                duration = "1",
                use_inverse = false,
                names = {},
                spellIds = {},
                subeventPrefix = "SPELL",
                subeventSuffix = "_CAST_START",
                debuffType = "HELPFUL",
            },
            untrigger = {},
        },
        {
            trigger = { type = "custom", custom_type = "status", check = "update", onUpdateThrottle = 0.1, custom = RESOURCE_SLOT_TRIGGER_TEMPLATE:gsub("%%%%INDEX%%%%", tostring(index)), debuffType = "HELPFUL" },
            untrigger = {},
        },
        disjunctive = "all",
        activeTriggerMode = -10,
    }
    return data
end

local SafeWeakAurasAdd
local function InstallResourcePips(parentId)
    SafeWeakAurasAdd(BuildResourceGroup(parentId, true))
    for i = 1, #RESOURCE_IDS do
        SafeWeakAurasAdd(BuildResourceFillAura(RESOURCE_GROUP_ID, i, true))
        SafeWeakAurasAdd(BuildResourceBlackOutlineAura(RESOURCE_GROUP_ID, i, true))
        SafeWeakAurasAdd(BuildResourceGcdAura(RESOURCE_GROUP_ID, i, true))
    end
end
local function ClearGeneratedAuraData()
    WeakAurasSaved.displays[CHILD_ID] = nil
    WeakAurasSaved.displays[ALT_CHILD_ID] = nil
    WeakAurasSaved.displays[DEFENSIVE_CHILD_ID] = nil
    WeakAurasSaved.displays[THREAT_CHILD_ID] = nil
    WeakAurasSaved.displays[INTERRUPT_CHILD_ID] = nil
    WeakAurasSaved.displays[PET_CHILD_ID] = nil
    WeakAurasSaved.displays[UTILITY_CHILD_ID] = nil
    for _, quality in ipairs(GROUND_AOE_QUALITIES) do WeakAurasSaved.displays[GROUND_AOE_INDICATOR_IDS[quality]] = nil end
    for i = 1, #RESOURCE_IDS do
        WeakAurasSaved.displays[RESOURCE_IDS[i]] = nil
        WeakAurasSaved.displays[RESOURCE_OUTLINE_IDS[i]] = nil
        WeakAurasSaved.displays[RESOURCE_GCD_IDS[i]] = nil
        WeakAurasSaved.displays[TARGET_ID .. " - CP " .. i] = nil
        WeakAurasSaved.displays[TARGET_ID .. " - CP" .. i .. "BlackOutline"] = nil
        WeakAurasSaved.displays[TARGET_ID .. " - CP" .. i .. "YellowOutline GCD"] = nil
        WeakAurasSaved.displays[TARGET_ID .. " - Resource " .. i] = nil
        WeakAurasSaved.displays[TARGET_ID .. " - Resource Outline " .. i] = nil
    end
    WeakAurasSaved.displays[RESOURCE_GROUP_ID] = nil
    for _, oldGroupId in ipairs(OLD_RESOURCE_GROUP_IDS) do
        WeakAurasSaved.displays[oldGroupId] = nil
    end
    local legacyPips = WeakAurasSaved.displays["Druid Combo points"]
    if legacyPips and (legacyPips.parent == TARGET_ID or legacyPips.parent == RESOURCE_GROUP_ID) then
        legacyPips.parent = nil
    end
    WeakAurasSaved.displays[TARGET_ID] = nil
end

function SafeWeakAurasAdd(data)
    if not data then
        return false
    end
    local ok, err = pcall(WeakAuras.Add, data)
    if not ok then
        print("|cff66ccff" .. ADDON_NAME .. ":|r failed to add " .. tostring(data.id) .. ": " .. tostring(err))
        return false
    end
    return true
end

local function SetChildDisabled(data, disabled)
    data.load = data.load or {}
    data.load.use_never = disabled and true or false
    SafeWeakAurasAdd(data)
end

local function AddUniqueChild(children, childId)
    for _, existing in ipairs(children) do
        if existing == childId then
            return
        end
    end
    table.insert(children, childId)
end

local function AddExistingChild(children, childId)
    if WeakAurasSaved.displays[childId] then
        AddUniqueChild(children, childId)
    end
end

local function RemoveChild(children, childId)
    for i = #children, 1, -1 do
        if children[i] == childId then
            table.remove(children, i)
        end
    end
end

local function ChildListed(group, childId)
    if not group or not group.controlledChildren then
        return false
    end
    for _, existing in ipairs(group.controlledChildren) do
        if existing == childId then
            return true
        end
    end
    return false
end

local function SanitizeWeakAurasHierarchy()
    local displays = WeakAurasSaved and WeakAurasSaved.displays
    if not displays then
        return
    end
    for id, data in pairs(displays) do
        if data and data.controlledChildren then
            for i = #data.controlledChildren, 1, -1 do
                local childId = data.controlledChildren[i]
                local child = displays[childId]
                if not child or child.parent ~= id then
                    table.remove(data.controlledChildren, i)
                    if data.sortHybridTable then
                        data.sortHybridTable[childId] = nil
                    end
                end
            end
        end
    end
    for id, data in pairs(displays) do
        if data and data.parent then
            local parent = displays[data.parent]
            if not ChildListed(parent, id) then
                data.parent = nil
            end
        end
    end
end

local function SetLegacyFeralLoad(data)
    data.load = data.load or {}
    data.load.use_class = true
    data.load.class = data.load.class or { multi = {} }
    data.load.class.single = "DRUID"
    data.load.class.multi = { DRUID = true }
    data.load.use_class_and_spec = true
    data.load.class_and_spec = data.load.class_and_spec or { multi = {} }
    data.load.class_and_spec.single = 103
    data.load.class_and_spec.multi = { [103] = true }
end

local function ShouldDisableRaynnaChild(id, data)
    if id == LEGACY_CHILD_ID or id == LEGACY_ALT_CHILD_ID then
        return true
    end
    if id == CHILD_ID or id == ALT_CHILD_ID or id == DEFENSIVE_CHILD_ID or id == THREAT_CHILD_ID or id == INTERRUPT_CHILD_ID or id == PET_CHILD_ID or id == UTILITY_CHILD_ID or id == RESOURCE_GROUP_ID or data.parent == RESOURCE_GROUP_ID or GROUND_AOE_INDICATOR_IDS.BAD == id or GROUND_AOE_INDICATOR_IDS.OK == id or GROUND_AOE_INDICATOR_IDS.GOOD == id or GROUND_AOE_INDICATOR_IDS.BEST == id or id == "Druid Combo points" or data.parent == "Druid Combo points" then
        return false
    end
    return id == "Highlight" or data.parent == "Highlight"
end

local function PatchLegacyFeralGroup(group)
    group.sortHybridTable = group.sortHybridTable or {}
    group.controlledChildren = group.controlledChildren or {}
    RemoveChild(group.controlledChildren, LEGACY_CHILD_ID)
    RemoveChild(group.controlledChildren, LEGACY_ALT_CHILD_ID)
    RemoveChild(group.controlledChildren, CHILD_ID)
    RemoveChild(group.controlledChildren, ALT_CHILD_ID)
    RemoveChild(group.controlledChildren, DEFENSIVE_CHILD_ID)
    RemoveChild(group.controlledChildren, THREAT_CHILD_ID)
    RemoveChild(group.controlledChildren, INTERRUPT_CHILD_ID)
    RemoveChild(group.controlledChildren, PET_CHILD_ID)
    RemoveChild(group.controlledChildren, UTILITY_CHILD_ID)
    for _, quality in ipairs(GROUND_AOE_QUALITIES) do RemoveChild(group.controlledChildren, GROUND_AOE_INDICATOR_IDS[quality]) end
    RemoveChild(group.controlledChildren, RESOURCE_GROUP_ID)
    for _, oldGroupId in ipairs(OLD_RESOURCE_GROUP_IDS) do RemoveChild(group.controlledChildren, oldGroupId) end
    AddExistingChild(group.controlledChildren, "Cooldowns")
    AddExistingChild(group.controlledChildren, "Highlight")
    group.sortHybridTable[LEGACY_CHILD_ID] = nil
    group.sortHybridTable[LEGACY_ALT_CHILD_ID] = nil
    group.sortHybridTable[CHILD_ID] = nil
    group.sortHybridTable[ALT_CHILD_ID] = nil
    group.sortHybridTable[DEFENSIVE_CHILD_ID] = nil
    group.sortHybridTable[THREAT_CHILD_ID] = nil
    group.sortHybridTable[INTERRUPT_CHILD_ID] = nil
    group.sortHybridTable[PET_CHILD_ID] = nil
    group.sortHybridTable[UTILITY_CHILD_ID] = nil
    group.sortHybridTable[RESOURCE_GROUP_ID] = nil
    for _, oldGroupId in ipairs(OLD_RESOURCE_GROUP_IDS) do group.sortHybridTable[oldGroupId] = nil end
    for _, quality in ipairs(GROUND_AOE_QUALITIES) do group.sortHybridTable[GROUND_AOE_INDICATOR_IDS[quality]] = nil end

    local descendants = {}
    local changed = true
    while changed do
        changed = false
        for id, data in pairs(WeakAurasSaved.displays) do
            if id ~= CHILD_ID and id ~= ALT_CHILD_ID and id ~= DEFENSIVE_CHILD_ID and id ~= THREAT_CHILD_ID and id ~= INTERRUPT_CHILD_ID and id ~= PET_CHILD_ID and id ~= UTILITY_CHILD_ID and not descendants[id] and (data.parent == LEGACY_FERAL_ID or descendants[data.parent]) then
                descendants[id] = true
                changed = true
            end
        end
    end

    for id in pairs(descendants) do
        local data = WeakAurasSaved.displays[id]
        if data then
            SetLegacyFeralLoad(data)
        end
    end
    SetLegacyFeralLoad(group)
    for id in pairs(descendants) do
        local data = WeakAurasSaved.displays[id]
        if data then
            SetChildDisabled(data, ShouldDisableRaynnaChild(id, data))
        end
    end
    SafeWeakAurasAdd(group)
end

local actionButtonNames = {
    "ActionButton",
    "BonusActionButton",
    "OverrideActionBarButton",
    "MultiBarBottomLeftButton",
    "MultiBarBottomRightButton",
    "MultiBarRightButton",
    "MultiBarLeftButton",
    "MultiBar5Button",
    "MultiBar6Button",
    "MultiBar7Button",
}

local bindingByPrefix = {
    ActionButton = "ACTIONBUTTON",
    BonusActionButton = "ACTIONBUTTON",
    OverrideActionBarButton = "ACTIONBUTTON",
    MultiBarBottomLeftButton = "MULTIACTIONBAR1BUTTON",
    MultiBarBottomRightButton = "MULTIACTIONBAR2BUTTON",
    MultiBarRightButton = "MULTIACTIONBAR3BUTTON",
    MultiBarLeftButton = "MULTIACTIONBAR4BUTTON",
    MultiBar5Button = "MULTIACTIONBAR5BUTTON",
    MultiBar6Button = "MULTIACTIONBAR6BUTTON",
    MultiBar7Button = "MULTIACTIONBAR7BUTTON",
}

local activeGlowButtons = {}
local activeHealFrame

local function IsHealerSpec(ctx)
    if ctx.class == "DRUID" then return ctx.spec == 4 end
    if ctx.class == "PALADIN" then return ctx.spec == 1 end
    if ctx.class == "PRIEST" then return ctx.spec == 1 or ctx.spec == 2 end
    if ctx.class == "SHAMAN" then return ctx.spec == 3 end
    if ctx.class == "MONK" then return ctx.spec == 2 end
    return false
end

local function EnsureHealFrameGlow(frame)
    if frame.RaynnaHealGlow then return frame.RaynnaHealGlow end
    local glow = frame:CreateTexture(nil, "OVERLAY")
    glow:SetTexture("Interface/Buttons/UI-ActionButton-Border")
    glow:SetBlendMode("ADD")
    glow:SetVertexColor(0.2, 1, 0.35, 1)
    glow:SetAlpha(1)
    glow:SetPoint("CENTER", frame, "CENTER", 0, 0)
    glow:SetSize((frame:GetWidth() or 80) * 1.18, (frame:GetHeight() or 36) * 1.65)
    glow:Hide()
    frame.RaynnaHealGlow = glow
    return glow
end

local function HideHealFrameGlow()
    if activeHealFrame and activeHealFrame.RaynnaHealGlow then
        activeHealFrame.RaynnaHealGlow:Hide()
    end
    activeHealFrame = nil
end

local function FrameUnit(frame, fallback)
    return frame and (frame.unit or frame.displayedUnit or fallback)
end

local function MaybeGlowHealFrame(frame, fallback, unit)
    if not frame or not frame.IsVisible or not frame:IsVisible() then return false end
    local frameUnit = FrameUnit(frame, fallback)
    if frameUnit and UnitExists(frameUnit) and UnitIsUnit(frameUnit, unit) then
        local glow = EnsureHealFrameGlow(frame)
        glow:Show()
        activeHealFrame = frame
        return true
    end
    return false
end

local function UpdateHealFrameGlow()
    if not SettingEnabled("healFrameGlow") then
        HideHealFrameGlow()
        return
    end
    local ctx = BuildContext()
    if not IsHealerSpec(ctx) then
        HideHealFrameGlow()
        return
    end
    local unit = ctx.healUnit()
    if not unit or unit == "player" or ctx.unitHpPct(unit) > 92 then
        HideHealFrameGlow()
        return
    end
    if activeHealFrame and MaybeGlowHealFrame(activeHealFrame, nil, unit) then
        return
    end
    HideHealFrameGlow()
    for i = 1, 5 do
        if MaybeGlowHealFrame(_G["CompactPartyFrameMember" .. i], "party" .. i, unit) then return end
    end
    for i = 1, 40 do
        if MaybeGlowHealFrame(_G["CompactRaidFrame" .. i], nil, unit) then return end
    end
    for i = 1, 4 do
        if MaybeGlowHealFrame(_G["PartyMemberFrame" .. i], "party" .. i, unit) then return end
    end
end

local function ShortKeybind(key)
    if not key or key == "" then
        return ""
    end
    local text = GetBindingText(key, "KEY_") or key
    text = text:gsub("CTRL%-", "C-")
    text = text:gsub("SHIFT%-", "S-")
    text = text:gsub("ALT%-", "A-")
    text = text:gsub("MOUSEWHEELUP", "MWU")
    text = text:gsub("MOUSEWHEELDOWN", "MWD")
    text = text:gsub("BUTTON", "M")
    text = text:gsub("NUMPAD", "N")
    return text
end

local function ButtonActionSlot(button)
    if not button then
        return nil
    end
    return button.action or button:GetAttribute("action") or button:GetID()
end

local function ButtonSpellName(button)
    local slot = ButtonActionSlot(button)
    if not slot or not HasAction(slot) then
        return nil
    end
    local actionType, id = GetActionInfo(slot)
    if actionType == "spell" and id then
        return GetSpellInfo(id)
    elseif actionType == "macro" and id then
        local macroSpell = GetMacroSpell(id)
        if type(macroSpell) == "number" then
            return GetSpellInfo(macroSpell)
        end
        return macroSpell
    end
    return nil
end

local function MacroBodyMatchesSpell(macroID, spellName)
    if not macroID or not spellName or not GetMacroInfo then
        return false
    end
    local _, _, body = GetMacroInfo(macroID)
    if not body then
        return false
    end
    local wanted = spellName:lower()
    for line in body:gmatch("[^\\r\\n]+") do
        local lower = line:lower():gsub("^%s+", "")
        if lower:match("^#showtooltip") and lower:find(wanted, 1, true) then
            return true
        end
        if lower:match("^/?cast") or lower:match("^/?castsequence") or lower:match("^/?use") then
            if lower:find(wanted, 1, true) then
                return true
            end
        end
    end
    return false
end

local function ButtonMatchesSpell(button, spellID)
    local wanted = GetSpellInfo(spellID)
    if not wanted then
        return false
    end
    local actual = ButtonSpellName(button)
    if actual and wanted == actual then
        return true
    end
    local slot = ButtonActionSlot(button)
    if not slot then
        return false
    end
    local actionType, id = GetActionInfo(slot)
    return actionType == "macro" and MacroBodyMatchesSpell(id, wanted)
end

local IterateActionButtons

local function ButtonBinding(button)
    if not button then
        return ""
    end
    if button.commandName then
        return ShortKeybind(GetBindingKey(button.commandName))
    end
    local name = button.GetName and button:GetName() or ""
    for prefix, bindingPrefix in pairs(bindingByPrefix) do
        local index = name:match("^" .. prefix .. "(%d+)$")
        if index then
            return ShortKeybind(GetBindingKey(bindingPrefix .. index))
        end
    end
    return ""
end
local function PrintButtonMatches(label, spellID)
    if not spellID then
        return false
    end
    local spellName = GetSpellInfo(spellID) or tostring(spellID)
    local found = false
    IterateActionButtons(function(button)
        if ButtonMatchesSpell(button, spellID) then
            found = true
            local buttonName = button.GetName and button:GetName() or "unknown button"
            local binding = ButtonBinding(button)
            if binding ~= "" then
                print("|cff66ccff" .. ADDON_NAME .. ":|r " .. label .. " found " .. spellName .. " on " .. buttonName .. " [" .. binding .. "]")
            else
                print("|cff66ccff" .. ADDON_NAME .. ":|r " .. label .. " found " .. spellName .. " on " .. buttonName .. " [no keybind]")
            end
        end
    end)
    if not found then
        print("|cff66ccff" .. ADDON_NAME .. ":|r " .. label .. " no visible default action button or macro matched " .. spellName .. ".")
    end
    return found
end

IterateActionButtons = function(callback)
    for _, prefix in ipairs(actionButtonNames) do
        for i = 1, 12 do
            local button = _G[prefix .. i]
            if button then
                callback(button)
            end
        end
    end
end

function _G.RaynnaRotationHelperGetSpellKeybind(spellID)
    local result = ""
    IterateActionButtons(function(button)
        if result == "" and ButtonMatchesSpell(button, spellID) then
            result = ButtonBinding(button)
        end
    end)
    return result
end

local function GroundAoeInfo(spellID)
    if not SettingEnabled("groundAoeIndicator") then
        return nil
    end
    if not spellID then
        spellID = ActiveGroundTargetSpellID()
    end
    if not spellID then
        local recommendations = { ComputeRecommendations() }
        for _, candidate in ipairs(recommendations) do
            if IsGroundTargetSpell(candidate) then
                spellID = candidate
                break
            end
        end
    end
    if not IsGroundTargetSpell(spellID) then
        return nil
    end
    local ctx = BuildContext()
    local targetCount = ctx.clusteredEnemyCount and ctx.clusteredEnemyCount(12) or 0
    local selfCount = ctx.nearbyEnemyCount and ctx.nearbyEnemyCount(10) or 0
    local count = targetCount
    local place = "PACK"
    if selfCount > targetCount then
        count = selfCount
        place = "SELF"
    end

    local quality = "BAD"
    if count >= 4 then
        quality = "BEST"
    elseif count >= 3 then
        quality = "GOOD"
    elseif count >= 2 then
        quality = "OK"
    end

    return quality, count, place, IsGroundTargetingSpell(spellID)
end

local function GroundTargetPlacementLabel(spellID)
    local quality, count, place, targeting = GroundAoeInfo(spellID)
    if not quality then
        return nil
    end
    if targeting then
        return "PLACE\n" .. place .. " " .. tostring(count)
    end
    return quality .. " " .. tostring(count)
end

function _G.RaynnaRotationHelperGetGroundAoeQuality()
    local quality = GroundAoeInfo()
    return quality
end

function _G.RaynnaRotationHelperGetGroundAoeLabel()
    local quality, count, place, targeting = GroundAoeInfo()
    if not quality then
        return ""
    end
    if targeting then
        return place .. "\n" .. tostring(count)
    end
    return quality .. "\n" .. tostring(count)
end

function _G.RaynnaRotationHelperGetSpellLabel(spellID)
    local binding = _G.RaynnaRotationHelperGetSpellKeybind(spellID) or ""
    if IsGroundTargetSpell(spellID) then
        local placement = GroundTargetPlacementLabel(spellID) or "AREA"
        if binding ~= "" and not IsGroundTargetingSpell(spellID) then
            return binding .. "\n" .. placement
        end
        return placement
    end
    return binding
end

_G.RaynnaFeralGetSpellKeybind = _G.RaynnaRotationHelperGetSpellKeybind

local function EnsureFallbackGlow(button)
    if button.RaynnaRotationGlow then
        return button.RaynnaRotationGlow
    end
    local glow = button:CreateTexture(nil, "OVERLAY")
    glow:SetTexture("Interface/Buttons/UI-ActionButton-Border")
    glow:SetBlendMode("ADD")
    glow:SetVertexColor(1, 0.95, 0.15, 1)
    glow:SetAlpha(1)
    glow:SetPoint("CENTER", button, "CENTER", 0, 0)
    local size = math.max(button:GetWidth() or 36, button:GetHeight() or 36) * 2.15
    glow:SetSize(size, size)
    glow:Hide()
    button.RaynnaRotationGlow = glow
    return glow
end

local function ShowGlow(button)
    activeGlowButtons[button] = true
    if ActionButton_ShowOverlayGlow then
        ActionButton_ShowOverlayGlow(button)
    end
    EnsureFallbackGlow(button):Show()
end

local function HideGlow(button)
    if ActionButton_HideOverlayGlow then
        ActionButton_HideOverlayGlow(button)
    end
    if button.RaynnaRotationGlow then
        button.RaynnaRotationGlow:Hide()
    end
    activeGlowButtons[button] = nil
end

local function UpdateActionBarGlow()
    if not SettingEnabled("actionBarGlow") then
        for button in pairs(activeGlowButtons) do HideGlow(button) end
        return
    end
    local primary, alternate = ComputeRecommendations()
    for button in pairs(activeGlowButtons) do
        if (not primary or not ButtonMatchesSpell(button, primary)) and (not alternate or not ButtonMatchesSpell(button, alternate)) then
            HideGlow(button)
        end
    end
    if not primary and not alternate then
        return
    end
    IterateActionButtons(function(button)
        if (primary and ButtonMatchesSpell(button, primary)) or (alternate and ButtonMatchesSpell(button, alternate)) then
            ShowGlow(button)
        end
    end)
end

local function PrintActionBarDebug()
    local ctx = BuildContext()
    local module = ActiveRotation(ctx)
    local spellID, altSpellID, defensiveSpellID, threatSpellID, interruptSpellID, petSpellID, utilitySpellID = ComputeRecommendations()
    local spellName = spellID and GetSpellInfo(spellID) or "none"
    local altName = altSpellID and GetSpellInfo(altSpellID) or "none"
    local defensiveName = defensiveSpellID and GetSpellInfo(defensiveSpellID) or "none"
    local threatName = threatSpellID and GetSpellInfo(threatSpellID) or "none"
    local interruptName = interruptSpellID and GetSpellInfo(interruptSpellID) or "none"
    local petName = petSpellID and GetSpellInfo(petSpellID) or "none"
    local utilityName = utilitySpellID and GetSpellInfo(utilitySpellID) or "none"
    print("|cff66ccff" .. ADDON_NAME .. ":|r module " .. (module and module.name or "none") .. ", recommended " .. spellName .. " " .. (spellID and ("(" .. spellID .. ")") or "") .. ", alternate " .. altName .. " " .. (altSpellID and ("(" .. altSpellID .. ")") or "") .. ", defensive " .. defensiveName .. " " .. (defensiveSpellID and ("(" .. defensiveSpellID .. ")") or "") .. ", threat " .. threatName .. " " .. (threatSpellID and ("(" .. threatSpellID .. ")") or "") .. ", interrupt " .. interruptName .. " " .. (interruptSpellID and ("(" .. interruptSpellID .. ")") or "") .. ", pet " .. petName .. " " .. (petSpellID and ("(" .. petSpellID .. ")") or "") .. ", utility " .. utilityName .. " " .. (utilitySpellID and ("(" .. utilitySpellID .. ")") or ""))
    print("|cff66ccff" .. ADDON_NAME .. ":|r class=" .. tostring(ctx.class or "none") .. " spec=" .. tostring(ctx.spec or "none") .. " mode=" .. tostring(ctx.targetMode and ctx.targetMode() or MODE_AUTO) .. " enemies=" .. tostring(ctx.enemyCount and ctx.enemyCount() or 0) .. " targetCluster=" .. tostring(ctx.clusteredEnemyCount and ctx.clusteredEnemyCount(12) or 0) .. " playerCluster=" .. tostring(ctx.nearbyEnemyCount and ctx.nearbyEnemyCount(12) or 0) .. " attackers=" .. tostring(CountRecentHostileAttackers(GetTime())) .. " meleeAttackers=" .. tostring(CountRecentMeleeAttackers(GetTime())) .. " avengerTargets=" .. tostring(ctx.avengersShieldTargetCount and ctx.avengersShieldTargetCount() or 0) .. " targetAge=" .. string.format("%.1f", ctx.targetAge and ctx.targetAge() or 0) .. " targetHp=" .. string.format("%.1f", ctx.targetHpPct and ctx.targetHpPct() or 100) .. " range=" .. tostring(ctx.rangeDebug or "none checked") .. " threatStatus=" .. tostring((UnitDetailedThreatSituation and select(2, UnitDetailedThreatSituation("player", "target"))) or "none") .. " threatPct=" .. tostring((UnitDetailedThreatSituation and select(3, UnitDetailedThreatSituation("player", "target"))) or "none") .. " casting=" .. tostring(PlayerBusyCasting() and true or false))
    print("|cff66ccff" .. ADDON_NAME .. ":|r why primary=" .. tostring(lastRecommendationReasons.primary or "none") .. ", alt=" .. tostring(lastRecommendationReasons.alternate or "none") .. ", defensive=" .. tostring(lastRecommendationReasons.defensive or "none") .. ", threat=" .. tostring(lastRecommendationReasons.threat or "none") .. ", threatDetail=" .. tostring(lastRecommendationReasons.threatDetail or "none") .. ", interrupt=" .. tostring(lastRecommendationReasons.interrupt or "none") .. ", pet=" .. tostring(lastRecommendationReasons.pet or "none") .. ", utility=" .. tostring(lastRecommendationReasons.utility or "none") .. ", moduleKey=" .. tostring(lastRecommendationReasons.moduleKey or "none") .. ", moduleSource=" .. tostring(lastRecommendationReasons.moduleSource or "none") .. ", opener=" .. tostring(lastRecommendationReasons.opener or "false") .. ", boss=" .. tostring(lastRecommendationReasons.boss or "false") .. ", mode=" .. tostring(lastRecommendationReasons.mode or MODE_AUTO) .. ", targetAge=" .. tostring(lastRecommendationReasons.targetAge or "0"))
    local resourceCount, resourceMax, resourceName = ComputeResourceInfo()
    print("|cff66ccff" .. ADDON_NAME .. ":|r resource " .. tostring(resourceName or "none") .. " " .. tostring(resourceCount or 0) .. "/" .. tostring(resourceMax or 0))
    if module and module.name == "Arcane Mage" then
        local arcanePowerType = SPELL_POWER_ARCANE_CHARGES or (Enum and Enum.PowerType and Enum.PowerType.ArcaneCharges) or 16
        local buffStacks = ctx.arcaneChargeBuffStacks and ctx.arcaneChargeBuffStacks() or 0
        local powerStacks = UnitPower and UnitPower("player", arcanePowerType) or 0
        local powerMax = UnitPowerMax and UnitPowerMax("player", arcanePowerType) or 0
        print("|cff66ccff" .. ADDON_NAME .. ":|r arcane detail buff=" .. tostring(buffStacks) .. " powerType=" .. tostring(arcanePowerType) .. " power=" .. tostring(powerStacks) .. "/" .. tostring(powerMax))
    end
    if module and module.name == "Feral Druid" then
        local behind = ctx.behindTarget()
        print("|cff66ccff" .. ADDON_NAME .. ":|r behind target " .. tostring(behind) .. " (" .. (ctx.behindDebug or "no debug") .. ")")
    end
    if ctx.class == "HUNTER" then
        local serpentRem = ctx.debuffRem("target", 1978, true)
        local serpentReady = ctx.ready(1978, 15, ctx.focusType)
        local serpentRange = ctx.inRange(1978)
        local focus = ctx.power(ctx.focusType)
        print("|cff66ccff" .. ADDON_NAME .. ":|r hunter serpent rem=" .. tostring(serpentRem) .. " ready=" .. tostring(serpentReady) .. " range=" .. tostring(serpentRange) .. " focus=" .. tostring(focus) .. "/" .. tostring(ctx.powerMax(ctx.focusType)) .. " rangeDebug=" .. tostring(ctx.rangeDebug or "none"))
    end
    PrintButtonMatches("primary", spellID)
    PrintButtonMatches("alternate", altSpellID)
    PrintButtonMatches("defensive", defensiveSpellID)
    PrintButtonMatches("threat", threatSpellID)
    PrintButtonMatches("interrupt", interruptSpellID)
    PrintButtonMatches("pet", petSpellID)
    PrintButtonMatches("utility", utilitySpellID)
end

local function WeakAuraRegion(id)
    if WeakAuras and WeakAuras.GetRegion then
        local region = WeakAuras.GetRegion(id)
        if region then
            return region
        end
    end
    return _G["WeakAuras:" .. id]
end

local function SetResourceFillAlpha(alpha)
    for i = 1, #RESOURCE_IDS do
        local region = WeakAuraRegion(RESOURCE_IDS[i])
        if region and region.SetAlpha then
            region:SetAlpha(alpha)
        end
    end
end

local function UpdateResourcePulse()
    local count, _, resource, _, remaining = ComputeResourceInfo()
    if resource ~= "ARCANE_CHARGES" or not remaining or remaining == math.huge or remaining > 4 or (count or 0) <= 0 then
        SetResourceFillAlpha(1)
        return
    end
    local pulse = 0.55 + 0.45 * math.abs(math.sin(GetTime() * 4))
    for i = 1, #RESOURCE_IDS do
        local region = WeakAuraRegion(RESOURCE_IDS[i])
        if region and region.SetAlpha then
            region:SetAlpha(i <= count and pulse or 1)
        end
    end
end
local glowFrame = CreateFrame("Frame")
glowFrame:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed < 0.05 then
        return
    end
    self.elapsed = 0
    UpdateActionBarGlow()
    UpdateHealFrameGlow()
    UpdateResourcePulse()
end)

local function Install()
    if not WeakAuras or not WeakAuras.Add or not WeakAurasSaved or not WeakAurasSaved.displays then
        print("|cff66ccff" .. ADDON_NAME .. ":|r WeakAuras is not ready.")
        return
    end

    local legacy = WeakAurasSaved.displays[LEGACY_FERAL_ID]
    if legacy and (legacy.regionType == "group" or legacy.regionType == "dynamicgroup") then
        PatchLegacyFeralGroup(legacy)
    end

    ClearGeneratedAuraData()
    SafeWeakAurasAdd(BuildGroup(false))
    SafeWeakAurasAdd(BuildAura(nil, 1, true))
    ClearGeneratedTextFields(CHILD_ID)
    SafeWeakAurasAdd(BuildAura(nil, 2, true))
    ClearGeneratedTextFields(ALT_CHILD_ID)
    SafeWeakAurasAdd(BuildAura(nil, 3, true))
    ClearGeneratedTextFields(DEFENSIVE_CHILD_ID)
    SafeWeakAurasAdd(BuildAura(nil, 4, true))
    ClearGeneratedTextFields(THREAT_CHILD_ID)
    SafeWeakAurasAdd(BuildAura(nil, 5, true))
    ClearGeneratedTextFields(INTERRUPT_CHILD_ID)
    SafeWeakAurasAdd(BuildAura(nil, 6, true))
    ClearGeneratedTextFields(PET_CHILD_ID)
    SafeWeakAurasAdd(BuildAura(nil, 7, true))
    ClearGeneratedTextFields(UTILITY_CHILD_ID)
    for _, quality in ipairs(GROUND_AOE_QUALITIES) do SafeWeakAurasAdd(BuildGroundAoeIndicator(nil, quality)) end
    InstallResourcePips(nil)

    C_Timer.After(0.1, function()
        SafeWeakAurasAdd(BuildAura(TARGET_ID, 1))
        ClearGeneratedTextFields(CHILD_ID)
        SafeWeakAurasAdd(BuildAura(TARGET_ID, 2))
        ClearGeneratedTextFields(ALT_CHILD_ID)
        SafeWeakAurasAdd(BuildAura(TARGET_ID, 3))
        ClearGeneratedTextFields(DEFENSIVE_CHILD_ID)
        SafeWeakAurasAdd(BuildAura(TARGET_ID, 4))
        ClearGeneratedTextFields(THREAT_CHILD_ID)
        SafeWeakAurasAdd(BuildAura(TARGET_ID, 5))
        ClearGeneratedTextFields(INTERRUPT_CHILD_ID)
        SafeWeakAurasAdd(BuildAura(TARGET_ID, 6))
        ClearGeneratedTextFields(PET_CHILD_ID)
        SafeWeakAurasAdd(BuildAura(TARGET_ID, 7))
        ClearGeneratedTextFields(UTILITY_CHILD_ID)
        for _, quality in ipairs(GROUND_AOE_QUALITIES) do SafeWeakAurasAdd(BuildGroundAoeIndicator(TARGET_ID, quality)) end
        InstallResourcePips(TARGET_ID)
        SafeWeakAurasAdd(BuildGroup(true))
        SanitizeWeakAurasHierarchy()
        WeakAuras.ScanEvents("PLAYER_TARGET_CHANGED")
        print("|cff66ccff" .. ADDON_NAME .. ":|r patched group '" .. TARGET_ID .. "'.")
    end)
end

local optionsPanel
local function RefreshOptionsPanel()
    if not optionsPanel then return end
    if optionsPanel.modeButton then optionsPanel.modeButton:SetText("Rotation mode: " .. GetMode()) end
    if optionsPanel.petButton then optionsPanel.petButton:SetText("Warlock pet: " .. GetWarlockPetMode()) end
    if optionsPanel.glowCheck then optionsPanel.glowCheck:SetChecked(SettingEnabled("actionBarGlow")) end
    if optionsPanel.groundCheck then optionsPanel.groundCheck:SetChecked(SettingEnabled("groundAoeIndicator")) end
    if optionsPanel.healCheck then optionsPanel.healCheck:SetChecked(SettingEnabled("healFrameGlow")) end
end

local function CreateOptionsButton(parent, text, x, y, width, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 210, 24)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    return button
end

local function CreateOptionsCheck(parent, text, x, y, key)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    check.text = check:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    check.text:SetPoint("LEFT", check, "RIGHT", 2, 0)
    check.text:SetText(text)
    check:SetScript("OnClick", function(self)
        SetSettingEnabled(key, self:GetChecked())
        UpdateActionBarGlow()
        if WeakAuras and WeakAuras.ScanEvents then WeakAuras.ScanEvents("RAYNNA_ROTATION_UPDATE") end
    end)
    return check
end

local function CreateOptionsPanel()
    if optionsPanel then return optionsPanel end
    optionsPanel = CreateFrame("Frame", "RaynnaRotationHelperOptionsPanel")
    optionsPanel.name = ADDON_NAME
    local title = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", optionsPanel, "TOPLEFT", 16, -16)
    title:SetText(ADDON_NAME)
    local note = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    note:SetPoint("TOPLEFT", optionsPanel, "TOPLEFT", 16, -44)
    note:SetText("Simple behavior settings. Use WeakAuras to drag or fine tune display positions.")
    optionsPanel.modeButton = CreateOptionsButton(optionsPanel, "Rotation mode", 16, -78, 230, function()
        local mode = GetMode()
        if mode == MODE_AUTO then mode = MODE_BOSS elseif mode == MODE_BOSS then mode = MODE_TRASH else mode = MODE_AUTO end
        SetMode(mode)
        RefreshOptionsPanel()
    end)
    optionsPanel.petButton = CreateOptionsButton(optionsPanel, "Warlock pet", 16, -110, 230, function()
        local mode = GetWarlockPetMode()
        if mode == PET_AUTO then mode = PET_DUNGEON elseif mode == PET_DUNGEON then mode = PET_SOLO elseif mode == PET_SOLO then mode = PET_OFF else mode = PET_AUTO end
        SetWarlockPetMode(mode)
        RefreshOptionsPanel()
    end)
    optionsPanel.glowCheck = CreateOptionsCheck(optionsPanel, "Action bar glow", 16, -150, "actionBarGlow")
    optionsPanel.groundCheck = CreateOptionsCheck(optionsPanel, "Ground AoE quality square", 16, -180, "groundAoeIndicator")
    optionsPanel.healCheck = CreateOptionsCheck(optionsPanel, "Highlight lowest visible party/raid frame for healers", 16, -210, "healFrameGlow")
    CreateOptionsButton(optionsPanel, "Open WeakAuras group", 16, -252, 230, function()
        if WeakAuras and WeakAuras.OpenOptions then WeakAuras.OpenOptions(TARGET_ID) elseif WeakAuras and WeakAuras.ToggleOptions then WeakAuras.ToggleOptions() end
    end)
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(optionsPanel, ADDON_NAME)
        optionsPanel.category = category
        optionsPanel.categoryId = category and category.ID
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(optionsPanel)
    end
    RefreshOptionsPanel()
    return optionsPanel
end

local function OpenOptionsPanel()
    local panel = CreateOptionsPanel()
    RefreshOptionsPanel()
    if panel and Settings and Settings.OpenToCategory and panel.categoryId then
        Settings.OpenToCategory(panel.categoryId)
    elseif panel and InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(panel)
        InterfaceOptionsFrame_OpenToCategory(panel)
    else
        print("|cff66ccff" .. ADDON_NAME .. ":|r settings panel is not available on this client.")
    end
end

local function OpenWeakAurasGroup()
    if WeakAuras and WeakAuras.OpenOptions then
        WeakAuras.OpenOptions(TARGET_ID)
    elseif WeakAuras and WeakAuras.ToggleOptions then
        WeakAuras.ToggleOptions()
    else
        print("|cff66ccff" .. ADDON_NAME .. ":|r WeakAuras options are not available.")
    end
end
SLASH_RAYNNAROTATIONHELPER1 = "/rrh"
SLASH_RAYNNAROTATIONHELPER2 = "/raynna"
SLASH_RAYNNAROTATIONHELPER3 = "/crh"
SLASH_RAYNNAROTATIONHELPER4 = "/cfh"
SlashCmdList.RAYNNAROTATIONHELPER = function(msg)
    msg = msg and msg:lower():match("^%s*(.-)%s*$") or ""
    if msg == "debug" or msg == "d" then
        PrintActionBarDebug()
        return
    end
    if msg == "settings" or msg == "options" then
        OpenOptionsPanel()
        return
    end
    if msg == "unlock" or msg == "move" then
        OpenWeakAurasGroup()
        return
    end
    if msg == "pet" then
        print("|cff66ccff" .. ADDON_NAME .. ":|r warlock pet mode is " .. GetWarlockPetMode() .. " (/rrh pet auto, dungeon, solo, off)")
        return
    end
    local requestedPetMode = msg:match("^pet%s+(%S+)$")
    if requestedPetMode then
        local mode = SetWarlockPetMode(requestedPetMode)
        print("|cff66ccff" .. ADDON_NAME .. ":|r warlock pet mode set to " .. mode)
        RefreshOptionsPanel()
        return
    end
    if msg == "mode" then
        print("|cff66ccff" .. ADDON_NAME .. ":|r mode is " .. GetMode() .. " (/rrh mode auto, /rrh mode boss, /rrh mode trash)")
        return
    end
    local requestedMode = msg:match("^mode%s+(%S+)$")
    if requestedMode or msg == "auto" or msg == "boss" or msg == "trash" then
        local mode = SetMode(requestedMode or msg)
        print("|cff66ccff" .. ADDON_NAME .. ":|r mode set to " .. mode)
        UpdateActionBarGlow()
        UpdateHealFrameGlow()
        if WeakAuras and WeakAuras.ScanEvents then
            WeakAuras.ScanEvents("RAYNNA_ROTATION_UPDATE")
        end
        return
    end
    if msg == "help" or msg == "?" then
        print("|cff66ccff" .. ADDON_NAME .. ":|r /rrh debug, /rrh settings, /rrh unlock, /rrh mode auto|boss|trash, /rrh pet auto|dungeon|solo|off")
        return
    end
    Install()
    UpdateActionBarGlow()
end

local frame = CreateFrame("Frame")
local function SafeRegisterEvent(event)
    pcall(frame.RegisterEvent, frame, event)
end
SafeRegisterEvent("PLAYER_LOGIN")
SafeRegisterEvent("PLAYER_ENTERING_WORLD")
SafeRegisterEvent("PLAYER_TARGET_CHANGED")
SafeRegisterEvent("UNIT_TARGET")
SafeRegisterEvent("UNIT_THREAT_LIST_UPDATE")
SafeRegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
SafeRegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
SafeRegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
SafeRegisterEvent("SPELLS_CHANGED")
SafeRegisterEvent("SPELL_UPDATE_COOLDOWN")
SafeRegisterEvent("UNIT_SPELLCAST_START")
SafeRegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
SafeRegisterEvent("UNIT_SPELLCAST_STOP")
SafeRegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
SafeRegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
SafeRegisterEvent("UNIT_SPELLCAST_INTERRUPTABLE")
SafeRegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
SafeRegisterEvent("UNIT_AURA")
SafeRegisterEvent("UNIT_HEALTH")
SafeRegisterEvent("UNIT_MAXHEALTH")
SafeRegisterEvent("UNIT_POWER")
SafeRegisterEvent("UNIT_POWER_FREQUENT")
SafeRegisterEvent("UNIT_PET")
SafeRegisterEvent("PET_BAR_UPDATE")
SafeRegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
SafeRegisterEvent("PLAYER_REGEN_ENABLED")
SafeRegisterEvent("PLAYER_REGEN_DISABLED")
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        TrackCombatLogHostileAttacker(...)
        UpdateActionBarGlow()
        UpdateResourcePulse()
        if WeakAuras and WeakAuras.ScanEvents then
            WeakAuras.ScanEvents("RAYNNA_ROTATION_UPDATE")
        end
        return
    end
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        TrackGroundTargetSpellCast(...)
    end
    if event == "PLAYER_REGEN_ENABLED" then
        if wipe then
            wipe(recentHostileAttackers)
            wipe(recentMeleeAttackers)
        else
            for guid in pairs(recentHostileAttackers) do
                recentHostileAttackers[guid] = nil
            end
            for guid in pairs(recentMeleeAttackers) do
                recentMeleeAttackers[guid] = nil
            end
        end
    end
    local unit = ...
    if event == "PLAYER_LOGIN" then
        InstallGroundTargetHooks()
        CreateOptionsPanel()
        C_Timer.After(1, Install)
        return
    end
    if unit and unit ~= "player" and unit ~= "target" and unit ~= "pet" and not tostring(unit):match("^party") and not tostring(unit):match("^raid") then
        return
    end
    UpdateActionBarGlow()
    UpdateHealFrameGlow()
    UpdateResourcePulse()
    if WeakAuras and WeakAuras.ScanEvents then
        WeakAuras.ScanEvents("RAYNNA_ROTATION_UPDATE")
    end
end)
