local _, A = ...

function A.Profile()
    local chosen, fallback
    for _, profile in ipairs(A.profiles) do
        if profile.class == A.class then
            if profile.key == A.db.profile then
                return profile
            end
            if profile.key == A.defaults[A.class] then
                fallback = profile
            end
            if A.ResolveSpell(profile.signature) then
                chosen = profile
            end
        end
    end
    if A.class == 'DRUID' and A.db.profile == 'auto' then
        local form = A.Call(GetShapeshiftFormID)
        local key = form == 1 and 'cat' or ((form == 5 or form == 8) and 'bear') or (form == 31 and 'balance')
        if key then
            for _, profile in ipairs(A.profiles) do
                if profile.class == A.class and profile.key == key then
                    return profile
                end
            end
        end
    end
    if A.db.profile == 'auto' and A.talentProfile then
        for _, profile in ipairs(A.profiles) do
            if profile.class == A.class and profile.key == A.talentProfile then
                return profile
            end
        end
    end
    return chosen or fallback
end

local function condition(rule)
    if rule.condition == 'talent' then
        return A.TalentRank(rule.value) > 0
    end
    if rule.condition == 'energymax' then
        local energy = A.Call(UnitPower, 'player', 3)
        if type(energy) ~= 'number' then
            return nil
        end
        return energy <= rule.value
    end
    if rule.condition == 'catbite' then
        local points = A.ComboPoints()
        local energy = A.Call(UnitPower, 'player', 3)
        local rip = A.AuraRemaining('target', 1079, false)
        if type(points) ~= 'number' or type(energy) ~= 'number' or rip == nil then
            return nil
        end
        local clear = A.AuraState('player', 16870, true).present
        return points >= 5 and rip >= 4 and (energy >= 70 or (energy >= 35 and clear == true))
    end
    if rule.condition == 'proc' then
        return A.AuraState('player', rule.value, true).present
    end
    if rule.condition == 'stacks' then
        local count = A.AuraStacks('player', rule.value[1], true)
        if count == nil then
            return nil
        end
        return count >= rule.value[2]
    end
    if rule.condition == 'usable' then
        return A.Call(C_Spell.IsSpellUsable, A.ResolveSpell(rule.id) or rule.id) == true
    end
    if rule.condition == 'manual' then
        return nil
    end
    if rule.condition == 'aoe' then
        return A.db.mode == 'trash'
    end
    if rule.condition == 'dot' then
        return A.AuraNeedsRefresh('target', rule.id, false, rule.value)
    end
    if rule.condition == 'buff' then
        -- Seal of Righteousness is only the fallback for unlearned Command.
        if rule.id == 21084 and A.Profile().key == 'retribution' and A.ResolveSpell(20375) then
            return false
        end
        return A.AuraNeedsRefresh('player', rule.id, true, rule.value)
    end
    if rule.condition == 'combo' or rule.condition == 'slice' then
        local points = A.ComboPoints()
        if type(points) ~= 'number' then
            return nil
        end
        if rule.condition == 'slice' then
            return points > 0 and A.AuraNeedsRefresh('player', 5171, true, 2)
        end
        if points < rule.value then
            return false
        end
        if rule.id == 1079 or rule.id == 1943 then
            return A.AuraNeedsRefresh('target', rule.id, false, 2)
        end
        return true
    end
    if rule.condition == 'execute' then
        local health = A.HealthPercent('target')
        if health == nil then
            return nil
        end
        return health <= rule.value
    end
    if rule.condition == 'rage' then
        local rage = A.Call(UnitPower, 'player', 1)
        if type(rage) ~= 'number' then
            return nil
        end
        return rage >= rule.value
    end
    return true
end

-- Secondary recommendations are evaluated independently of the main rotation.
-- Missing data for one action must not blank every other readable suggestion.
local secondaryRules = {
    DRUID = {
        { 16857, 'debuff', 'Apply Faerie Fire (Feral)' },
        { 770, 'debuff', 'Apply Faerie Fire' },
        { 1126, 'buff', 'Maintain Mark of the Wild' },
        { 22812, 'health', 'Use Barkskin', 50 },
    },
    WARRIOR = { { 6673, 'buff', 'Maintain Battle Shout' }, { 871, 'health', 'Use Shield Wall', 30 } },
    PALADIN = { { 19740, 'buff', 'Maintain Blessing of Might' }, { 642, 'health', 'Use Divine Shield', 20 } },
    HUNTER = { { 1130, 'debuff', "Apply Hunter's Mark" }, { 136, 'pethealth', 'Mend your pet', 65 } },
    ROGUE = { { 5277, 'health', 'Use Evasion', 40 } },
    MAGE = { { 1459, 'buff', 'Maintain Arcane Intellect' }, { 168, 'buff', 'Maintain Frost Armor' } },
    PRIEST = { { 1243, 'buff', 'Maintain Power Word: Fortitude' }, { 17, 'health', 'Shield yourself', 40 } },
    SHAMAN = { { 324, 'buff', 'Maintain Lightning Shield' } },
    WARLOCK = { { 687, 'buff', 'Maintain Demon Skin' } },
}
function A.SecondarySuggestions()
    local suggestions = {}
    local interrupts = {
        WARRIOR = { 6552, 72 },
        PALADIN = { 96231 },
        ROGUE = { 1766 },
        MAGE = { 2139 },
        SHAMAN = { 8042 },
        PRIEST = { 15487 },
        DRUID = { 106839 },
    }
    if A.Call(UnitCanAttack, 'player', 'target') == true and A.TargetInterruptible() then
        for _, base in ipairs(interrupts[A.class] or {}) do
            local id = A.ResolveSpell(base)
            if id and A.Ready(id) == true and A.Call(C_Spell.IsSpellInRange, id, 'target') == true then
                table.insert(
                    suggestions,
                    { id = id, hint = 'Interrupt the target cast', category = 'interrupt' }
                )
                break
            end
        end
    end
    local faerieFireSuggested = false
    for _, rule in ipairs(secondaryRules[A.class] or {}) do
        local id = A.ResolveSpell(rule[1])
        if id and A.Ready(id) == true then
            local needed
            if rule[2] == 'buff' or rule[2] == 'debuff' then
                local helpful = rule[2] == 'buff'
                needed = A.AuraNeedsRefresh(helpful and 'player' or 'target', rule[1], helpful, 0, true)
            else
                local health = A.HealthPercent(rule[2] == 'pethealth' and 'pet' or 'player')
                needed = health ~= nil and health < rule[4]
            end
            local faerie = rule[1] == 16857 or rule[1] == 770
            local range = rule[2] ~= 'debuff'
                or (
                    A.Call(UnitCanAttack, 'player', 'target') == true
                    and A.Call(UnitIsDeadOrGhost, 'target') == false
                    and A.Call(C_Spell.IsSpellInRange, id, 'target') == true
                )
            if needed and range and not (faerie and faerieFireSuggested) then
                local category = rule[2] == 'health' and 'defensive'
                    or (rule[2] == 'pethealth' and 'pet')
                    or 'utility'
                table.insert(suggestions, { id = id, hint = rule[3], category = category })
                if faerie then
                    faerieFireSuggested = true
                end
            end
        end
    end
    return suggestions
end

function A.Evaluate()
    local profile = A.Profile()
    local result = { profile = profile, guide = {}, support = {}, status = 'No supported class profile' }
    if not profile then
        return result
    end
    for _, rule in ipairs(profile.rules) do
        local spell = A.ResolveSpell(rule.id)
        if spell then
            table.insert(result.guide, { id = spell, hint = rule.hint, rule = rule })
        end
    end
    if A.Call(UnitIsDeadOrGhost, 'player') == true then
        result.status = 'Dead — priority reference'
        return result
    end
    result.support = A.SecondarySuggestions()
    local target = A.Call(UnitCanAttack, 'player', 'target')
    if target ~= true or A.Call(UnitIsDeadOrGhost, 'target') ~= false then
        result.status = 'Select a living enemy — priority reference'
        return result
    end
    local uncertain = false
    local waiting
    for _, entry in ipairs(result.guide) do
        local allowed = condition(entry.rule)
        if allowed == nil then
            uncertain = true
        elseif allowed then
            local ready = A.Ready(entry.id)
            local range = A.Call(C_Spell and C_Spell.IsSpellInRange, entry.id, 'target')
            if ready == true then
                result.primary = entry
                if profile.key == 'cat' and entry.rule.id == 5221 then
                    local claw = A.ResolveSpell(1082)
                    if claw and A.Ready(claw) == true then
                        result.alternate = { id = claw, hint = 'Use Claw when you cannot attack from behind' }
                    end
                end
                if range == false then
                    result.status = 'Move into range'
                else
                    result.status = uncertain and 'Suggested action - some conditions unavailable'
                        or 'Suggested action'
                end
                return result
            elseif ready == nil then
                uncertain = true
                waiting = waiting or { entry = entry, status = 'Next ability - readiness unavailable' }
            else
                waiting = waiting
                    or { entry = entry, status = 'Next ability - waiting for resource or cooldown' }
            end
        end
    end
    if waiting then
        result.primary = waiting.entry
        result.primary.pending = true
        result.status = waiting.status
        return result
    end
    result.status = uncertain and 'Priority guide — live data unavailable' or 'Waiting for a usable action'
    return result
end

-- Compatibility entry point for consumers of the original addon. Reference
-- icons are deliberately not exposed as live recommendations.
function RaynnaRotationHelperGetRecommendation(slot)
    if slot == nil or slot == 1 then
        return A.last and A.last.primary and A.last.primary.id
    end
    local entry = A.DisplayEntry(slot)
    return entry and entry.id
end

-- Match the original public slot contract: primary, positional alternative,
-- defensive, threat, interrupt, pet and utility. Slots never change purpose.
function A.DisplayEntry(slot)
    if not A.last then
        return
    end
    if slot == 1 then
        return A.last.primary
    end
    if slot == 2 then
        return A.last.alternate
    end
    local category = ({ [3] = 'defensive', [4] = 'threat', [5] = 'interrupt', [6] = 'pet', [7] = 'utility' })[slot]
    for _, entry in ipairs(A.last.support or {}) do
        if entry.category == category then
            return entry
        end
    end
end
