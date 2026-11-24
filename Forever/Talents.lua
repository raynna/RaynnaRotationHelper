local _, A = ...

local branches = {
    DRUID = { 'balance', 'cat', 'restoration' },
    WARRIOR = { 'arms', 'fury', 'protection' },
    PALADIN = { 'holy', 'protection', 'retribution' },
    HUNTER = { 'beast', 'marks', 'survival' },
    ROGUE = { 'assassination', 'combat', 'subtlety' },
    PRIEST = { 'discipline', 'holy', 'shadow' },
    SHAMAN = { 'elemental', 'enhancement', 'restoration' },
    MAGE = { 'arcane', 'fire', 'frost' },
    WARLOCK = { 'affliction', 'demonology', 'destruction' },
}

-- Read the active configuration directly; opening the talent window and
-- installing Talent Guide are not required. Keep ranks for talent conditions.
function A.RefreshTalents()
    A.talentProfile, A.talentRanks = nil, {}
    if not C_ClassTalents or not C_Traits then
        return
    end
    local config = A.Call(C_ClassTalents.GetActiveConfigID)
    if not config then
        return
    end
    local info = A.Call(C_Traits.GetConfigInfo, config)
    if not info or not A.Readable(info.treeIDs) or type(info.treeIDs) ~= 'table' then
        return
    end
    local totals, seen = {}, {}
    for _, tree in ipairs(info.treeIDs) do
        local order = {}
        for index, group in ipairs(A.Call(C_Traits.GetGroupDisplayInfoByTreeID, tree) or {}) do
            if A.Readable(group.groupID) then
                order[group.groupID] = index
            end
        end
        for _, id in ipairs(A.Call(C_Traits.GetTreeNodes, tree) or {}) do
            local node = A.Call(C_Traits.GetNodeInfo, config, id)
            if
                node
                and not seen[id]
                and A.Readable(node.ranksPurchased)
                and type(node.ranksPurchased) == 'number'
            then
                seen[id] = true
                local group = node.groupIDs and node.groupIDs[1]
                local index = group and order[group]
                if index then
                    totals[index] = (totals[index] or 0) + node.ranksPurchased
                end
                local active = node.activeEntry
                local entry = active and A.Call(C_Traits.GetEntryInfo, config, active.entryID)
                local definition = entry and A.Call(C_Traits.GetDefinitionInfo, entry.definitionID)
                if definition and A.Readable(definition.spellID) and definition.spellID then
                    A.talentRanks[definition.spellID] = node.ranksPurchased
                end
            end
        end
    end
    local best, points, tied = nil, 0, false
    for index, count in pairs(totals) do
        if count > points then
            best, points, tied = index, count, false
        elseif count == points then
            tied = true
        end
    end
    if best and not tied and branches[A.class] then
        A.talentProfile = branches[A.class][best]
    end
end

function A.TalentRank(base)
    local name = A.SpellInfo(base)
    name = name and name.name
    for id, rank in pairs(A.talentRanks or {}) do
        if id == base then
            return rank
        end
        local info = A.SpellInfo(id)
        if info and A.Readable(info.name) and name and info.name == name then
            return rank
        end
    end
    return 0
end
