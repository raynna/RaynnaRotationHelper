local _, A = ...

-- The applied Faerie Fire effect can use the caster or Feral spell family.
local faerieFire = { 770, 778, 9749, 9907, 16857, 17390, 17391, 17392 }
local aliases = {}
for _, id in ipairs(faerieFire) do
    aliases[id] = faerieFire
end

function A.AuraState(unit, base, helpful, anyCaster)
    local unknown = { present = nil, remaining = nil, stacks = nil }
    if not C_UnitAuras then
        return unknown
    end
    if A.Call(UnitExists, unit) == false or A.Call(UnitIsVisible, unit) == false then
        unknown.reason = 'unit-not-visible'
        return unknown
    end
    local ids, names = {}, {}
    local function add(id)
        if not id then
            return
        end
        ids[id] = true
        local info = A.SpellInfo(id)
        if info and A.Readable(info.name) and type(info.name) == 'string' then
            names[info.name] = true
        end
    end
    add(base)
    add(A.ResolveSpell(base))
    for _, id in ipairs(aliases[base] or {}) do
        add(id)
    end
    for name in pairs(names) do
        local family = A.spellFamilies and A.spellFamilies[name]
        for id in pairs(family and family.ids or {}) do
            ids[id] = true
        end
    end
    local filter = helpful and 'HELPFUL' or (anyCaster and 'HARMFUL' or 'HARMFUL|PLAYER')
    local uncertain, found = false, nil
    local idQueries, idEmpty, idErrors, idSecret = 0, 0, 0, 0

    local function accept(aura, filtered, identified)
        if not A.Readable(aura) then
            uncertain = true
            return
        end
        if not aura then
            return
        end
        if not identified then
            local byID = A.Readable(aura.spellId) and ids[aura.spellId]
            local byName = A.Readable(aura.name) and names[aura.name]
            if not byID and not byName then
                if not A.Readable(aura.spellId) or not A.Readable(aura.name) then
                    uncertain = true
                end
                return
            end
        end
        if
            not helpful
            and not anyCaster
            and A.Readable(aura.sourceUnit)
            and type(aura.sourceUnit) == 'string'
            and aura.sourceUnit ~= 'player'
            and aura.sourceUnit ~= 'pet'
            and aura.sourceUnit ~= 'vehicle'
        then
            return
        end
        if not filtered then
            local kind = aura[helpful and 'isHelpful' or 'isHarmful']
            if A.Readable(kind) and kind == false then
                return
            end
            if not helpful and not anyCaster then
                -- ID lookup is not caster-filtered. Never confuse someone
                -- else's bleed with ours, or infer ownership from secret data.
                local source = A.Readable(aura.sourceUnit) and aura.sourceUnit
                if source ~= 'player' and source ~= 'pet' and source ~= 'vehicle' then
                    if type(source) == 'string' then
                        return
                    end
                    if
                        not A.Readable(aura.isFromPlayerOrPlayerPet)
                        or aura.isFromPlayerOrPlayerPet ~= true
                    then
                        uncertain = true
                        return
                    end
                end
            end
        end
        local remaining
        if A.Readable(aura.expirationTime) and type(aura.expirationTime) == 'number' then
            remaining = aura.expirationTime == 0 and math.huge or math.max(0, aura.expirationTime - GetTime())
            if remaining == 0 then
                return
            end
        end
        local stacks = A.Readable(aura.applications)
                and type(aura.applications) == 'number'
                and aura.applications
            or nil
        -- Presence remains known even if its timer or stack count is hidden.
        if not found or (remaining and not found.remaining) then
            found = { present = true, remaining = remaining, stacks = stacks }
        end
    end

    -- Negative results are not an early exit: another lookup may see a ranked
    -- aura that the name API omits. An early exit can repeat apply advice.
    if C_UnitAuras.GetAuraDataBySpellName then
        for name in pairs(names) do
            local ok, aura = pcall(C_UnitAuras.GetAuraDataBySpellName, unit, name, filter)
            if ok then
                accept(aura, true, true)
            else
                uncertain = true
            end
        end
    end
    if C_UnitAuras.GetUnitAuraBySpellID then
        for id in pairs(ids) do
            idQueries = idQueries + 1
            local ok, aura = pcall(C_UnitAuras.GetUnitAuraBySpellID, unit, id)
            if ok then
                if not A.Readable(aura) then
                    idSecret = idSecret + 1
                elseif aura == nil then
                    idEmpty = idEmpty + 1
                end
                accept(aura, false, true)
            else
                idErrors = idErrors + 1
                uncertain = true
            end
        end
    end
    if unit == 'player' and helpful and C_UnitAuras.GetPlayerAuraBySpellID then
        for id in pairs(ids) do
            local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, id)
            if ok then
                accept(aura, true, true)
            else
                uncertain = true
            end
        end
    end
    if C_UnitAuras.GetUnitAuras then
        local ok, list = pcall(C_UnitAuras.GetUnitAuras, unit, filter, 255)
        if ok and A.Readable(list) and type(list) == 'table' then
            local scanned = pcall(function()
                for _, aura in ipairs(list) do
                    accept(aura, true, false)
                end
            end)
            if not scanned then
                uncertain = true
            end
        end
    end
    local complete = false
    if C_UnitAuras.GetAuraDataByIndex then
        for index = 1, 255 do
            local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, filter)
            if not ok or not A.Readable(aura) then
                uncertain = true
                break
            end
            if not aura then
                complete = true
                break
            end
            accept(aura, true, false)
        end
    end
    if found then
        return found
    end
    -- An explicit, readable nil from every candidate ID is documented absence
    -- on a visible unit. An empty restricted index scan alone is not. Check
    -- visibility because ID queries also return nil for units on other maps.
    if
        idQueries > 0
        and idEmpty == idQueries
        and A.Call(UnitIsVisible, unit) == true
        and A.Call(UnitExists, unit) == true
        and not (
            C_Secrets
            and C_Secrets.ShouldAurasBeSecret
            and A.Call(C_Secrets.ShouldAurasBeSecret) ~= false
        )
    then
        return { present = false, remaining = 0, stacks = 0, reason = 'visible-ID-absence' }
    end
    local restricted = C_Secrets
        and C_Secrets.ShouldAurasBeSecret
        and A.Call(C_Secrets.ShouldAurasBeSecret) ~= false
    if complete and not uncertain and not restricted then
        return { present = false, remaining = 0, stacks = 0 }
    end
    unknown.reason = 'IDs='
        .. idQueries
        .. '/empty='
        .. idEmpty
        .. '/secret='
        .. idSecret
        .. '/errors='
        .. idErrors
    return unknown
end

function A.AuraRemaining(unit, base, helpful, anyCaster)
    return A.AuraState(unit, base, helpful, anyCaster).remaining
end

function A.AuraStacks(unit, base, helpful)
    return A.AuraState(unit, base, helpful).stacks
end

function A.AuraNeedsRefresh(unit, base, helpful, window, anyCaster)
    local state = A.AuraState(unit, base, helpful, anyCaster)
    if state.present == nil then
        return nil
    end
    if not state.present then
        return true
    end
    if not state.remaining then
        return false
    end
    return state.remaining <= (window or 0)
end

function A.DebugAuras()
    local report = {}
    A.db.auraDiagnostics = report
    local function print(message)
        report[#report + 1] = message
        _G.print(message)
    end
    local function describe(fn, ...)
        if type(fn) ~= 'function' then
            return 'unavailable'
        end
        local ok, aura = pcall(fn, ...)
        if not ok then
            if A.Readable(aura) and type(aura) == 'string' then
                return 'error: ' .. aura:gsub('[\r\n]', ' '):sub(1, 300)
            end
            return 'error (unreadable detail)'
        end
        if not A.Readable(aura) then
            return 'secret'
        end
        if not aura then
            return 'nil'
        end
        local function field(value)
            if not A.Readable(value) then
                return 'secret'
            end
            return tostring(value)
        end
        return 'aura(id='
            .. field(aura.spellId)
            .. ',owner='
            .. field(aura.sourceUnit)
            .. ',expires='
            .. field(aura.expirationTime)
            .. ')'
    end
    local profile = A.Profile()
    print(
        'RRH aura diagnostics: '
            .. (profile and profile.name or 'no profile')
            .. ' targetVisible='
            .. tostring(A.Call(UnitIsVisible, 'target'))
            .. ' restricted='
            .. tostring(C_Secrets and A.Call(C_Secrets.ShouldAurasBeSecret))
    )
    local seen = {}
    local function show(unit, id, helpful, shared)
        local key = unit .. ':' .. id
        if seen[key] then
            return
        end
        seen[key] = true
        local state = A.AuraState(unit, id, helpful, shared)
        print(
            key
                .. ' learned='
                .. tostring(A.ResolveSpell(id))
                .. ' present='
                .. tostring(state.present)
                .. ' remaining='
                .. tostring(state.remaining)
                .. ' stacks='
                .. tostring(state.stacks)
                .. ' detail='
                .. tostring(state.reason or (state.present and 'active' or 'readable-scan'))
        )
        local info = A.SpellInfo(id)
        local name = info and A.Readable(info.name) and info.name
        local filter = helpful and 'HELPFUL' or (shared and 'HARMFUL' or 'HARMFUL|PLAYER')
        local candidates = { [id] = true }
        local learned = A.ResolveSpell(id)
        if learned then
            candidates[learned] = true
        end
        local family = name and A.spellFamilies and A.spellFamilies[name]
        for rank in pairs(family and family.ids or {}) do
            candidates[rank] = true
        end
        local details = {}
        for rank in pairs(candidates) do
            table.insert(details, rank .. '=' .. describe(C_UnitAuras.GetUnitAuraBySpellID, unit, rank))
        end
        table.sort(details)
        print('  IDs: ' .. table.concat(details, '; '))
        print(
            '  name='
                .. (name and describe(C_UnitAuras.GetAuraDataBySpellName, unit, name, filter) or 'unavailable')
                .. ' index1='
                .. describe(C_UnitAuras.GetAuraDataByIndex, unit, 1, filter)
        )
        if unit == 'player' then
            print('  playerAPI=' .. describe(C_UnitAuras.GetPlayerAuraBySpellID, learned or id))
        end
        print('  bulkFirst=' .. describe(function()
            if not C_UnitAuras.GetUnitAuras then
                return nil
            end
            local values = C_UnitAuras.GetUnitAuras(unit, filter, 255)
            if not A.Readable(values) then
                return values
            end
            return values and values[1]
        end))
    end
    for _, rule in ipairs(profile and profile.rules or {}) do
        if rule.condition == 'dot' or rule.id == 1079 or rule.id == 1943 then
            show('target', rule.id, false)
        elseif rule.condition == 'buff' or rule.condition == 'slice' then
            show('player', rule.id, true)
        elseif rule.condition == 'proc' then
            show('player', rule.value, true)
        elseif rule.condition == 'stacks' then
            show('player', rule.value[1], true)
        end
    end
    if A.class == 'DRUID' then
        show('target', 16857, false, true)
        show('player', 1126, true, true)
    end
end
