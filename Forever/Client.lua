local _, A = ...

-- Never perform arithmetic, comparisons or table lookups on secret values.
function A.Readable(value)
    return not issecretvalue or not issecretvalue(value)
end

function A.Call(fn, ...)
    if type(fn) ~= 'function' then
        return nil
    end
    local ok, value = pcall(fn, ...)
    if ok and A.Readable(value) then
        return value
    end
end

function A.SpellInfo(id)
    return A.Call(C_Spell and C_Spell.GetSpellInfo, id)
end

-- Resolve by localized spell name through the current spellbook, so trained
-- ranks and Forever overrides are used instead of always recommending rank 1.
function A.RefreshSpells()
    A.spells = {}
    A.spellFamilies = {}
    local book = C_SpellBook
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
    local count = book and A.Call(book.GetNumSpellBookSkillLines)
    for line = 1, type(count) == 'number' and count or 0 do
        local info = A.Call(book.GetSpellBookSkillLineInfo, line)
        if
            info
            and A.Readable(info.itemIndexOffset)
            and A.Readable(info.numSpellBookItems)
            and type(info.itemIndexOffset) == 'number'
            and type(info.numSpellBookItems) == 'number'
        then
            for slot = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
                local item = A.Call(book.GetSpellBookItemInfo, slot, bank)
                if
                    item
                    and A.Readable(item.spellID)
                    and type(item.spellID) == 'number'
                    and A.Readable(item.isPassive)
                    and not item.isPassive
                    and A.Readable(item.isOffSpec)
                    and not item.isOffSpec
                    and A.Call(book.IsSpellKnown, item.spellID) == true
                then
                    local spellInfo = A.SpellInfo(item.spellID)
                    local name = spellInfo and A.Readable(spellInfo.name) and spellInfo.name
                    if type(name) == 'string' then
                        local family = A.spellFamilies[name] or { ids = {}, rank = -1 }
                        A.spellFamilies[name] = family
                        family.ids[item.spellID] = true
                        local rank = 0
                        if book.GetSpellBookItemName then
                            local ok, _, subName = pcall(book.GetSpellBookItemName, slot, bank)
                            if ok and A.Readable(subName) and type(subName) == 'string' then
                                rank = tonumber(subName:match('%d+')) or 0
                            end
                        end
                        if rank > family.rank then
                            family.rank, family.best = rank, item.spellID
                        end
                    end
                end
            end
        end
    end
    for _, profile in ipairs(A.profiles) do
        if profile.class == A.class then
            for _, rule in ipairs(profile.rules) do
                A.ResolveSpell(rule.id)
            end
        end
    end
    for _, id in ipairs(A.support[A.class] or {}) do
        A.ResolveSpell(id)
    end
end

function A.ResolveSpell(base)
    A.spells = A.spells or {}
    if A.spells[base] ~= nil then
        return A.spells[base] or nil
    end
    local info = A.SpellInfo(base)
    local spell
    if info and A.Readable(info.name) and info.name and C_SpellBook then
        local family = A.spellFamilies and A.spellFamilies[info.name]
        if family and family.rank > 0 then
            A.spells[base] = family.best
            return family.best
        end
        local slot = A.Call(C_SpellBook.FindSpellBookSlotForSpell, info.name, false, false, false, false)
        if slot then
            local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
            local item = A.Call(C_SpellBook.GetSpellBookItemInfo, slot, bank)
            if item and A.Readable(item.spellID) and A.Readable(item.isPassive) and not item.isPassive then
                spell = item.spellID
            end
        end
        if not spell and A.Call(C_SpellBook.IsSpellKnown, base) == true then
            spell = base
        end
    end
    A.spells[base] = spell or false
    return spell
end

function A.Ready(id)
    local usable = A.Call(C_Spell and C_Spell.IsSpellUsable, id)
    if usable == nil then
        return nil
    elseif not usable then
        return false
    end
    local cooldown = A.Call(C_Spell and C_Spell.GetSpellCooldown, id)
    if not cooldown or not A.Readable(cooldown.isEnabled) then
        return nil
    end
    if cooldown.isEnabled == false then
        return false
    end
    -- Forever explicitly exposes isActive even when numeric cooldown times
    -- are secret. Use that public flag instead of discarding a ready spell.
    if A.Readable(cooldown.isActive) and cooldown.isActive == false then
        return true
    end
    if not A.Readable(cooldown.startTime) or not A.Readable(cooldown.duration) then
        return nil
    end
    if type(cooldown.startTime) ~= 'number' or type(cooldown.duration) ~= 'number' then
        return nil
    end
    -- Compare against the actual GCD rather than treating all short cooldowns as ready.
    local remaining = cooldown.startTime + cooldown.duration - GetTime()
    if remaining <= 0 then
        return true
    end
    local gcd = A.Call(C_Spell.GetSpellCooldown, 61304)
    if gcd and A.Readable(gcd.startTime) and A.Readable(gcd.duration) then
        return cooldown.startTime == gcd.startTime and cooldown.duration == gcd.duration
    end
    return nil
end

function A.HealthPercent(unit)
    local value, maximum = A.Call(UnitHealth, unit), A.Call(UnitHealthMax, unit)
    if type(value) == 'number' and type(maximum) == 'number' and maximum > 0 then
        return value * 100 / maximum
    end
end

function A.ComboPoints()
    local points = A.Call(UnitPower, 'player', 4)
    if type(points) == 'number' then
        return points
    end
    return A.Call(GetComboPoints, 'player', 'target')
end

function A.TargetInterruptible()
    for index, fn in ipairs({ UnitCastingInfo or false, UnitChannelInfo or false }) do
        if type(fn) == 'function' then
            local values = { pcall(fn, 'target') }
            local name, blocked = values[2], values[index == 1 and 9 or 8]
            if values[1] and A.Readable(name) and name and A.Readable(blocked) and blocked == false then
                return true
            end
        end
    end
    return false
end
