local _, A = ...
local groupID = "Raynna's Rotation Helper - Forever"
A.auraGroupID = groupID

function RaynnaRotationHelperForeverGCD()
    local cooldown = A.Call(C_Spell and C_Spell.GetSpellCooldown, 61304)
    if
        cooldown
        and A.Readable(cooldown.startTime)
        and A.Readable(cooldown.duration)
        and type(cooldown.startTime) == 'number'
        and type(cooldown.duration) == 'number'
    then
        return cooldown.duration, cooldown.startTime + cooldown.duration
    end
    return 0, 0
end

local function trigger(slot)
    return string.format(
        [[function()
        if type(RaynnaRotationHelperForeverSlot) ~= 'function' then
            aura_env.spell, aura_env.key = nil, nil
            return false
        end
        local id, key = RaynnaRotationHelperForeverSlot(%d)
        aura_env.spell, aura_env.key = id, key
        return id ~= nil
    end]],
        slot
    )
end

function RaynnaRotationHelperForeverSlot(slot)
    if not A.db or A.db.hidden or not A.last then
        return nil
    end
    local entry = A.DisplayEntry(slot)
    if entry then
        return entry.id, entry.pending and 'WAIT' or (A.KeyForSpell and A.KeyForSpell(entry.id) or '')
    end
end

local function child(slot)
    local size = slot <= 2 and 48 or (slot == 5 and 36 or 34)
    local positions = { { -28, 0 }, { 28, 0 }, { 76, -7 }, { -76, -7 }, { 0, 48 }, { 116, -7 }, { -116, -7 } }
    return {
        id = groupID .. ' - ' .. slot,
        uid = 'raynna-forever-slot-' .. slot,
        parent = groupID,
        regionType = 'icon',
        internalVersion = 90,
        width = size,
        height = size,
        xOffset = positions[slot][1],
        yOffset = positions[slot][2],
        anchorPoint = 'CENTER',
        selfPoint = 'CENTER',
        anchorFrameType = 'SCREEN',
        alpha = 1,
        icon = true,
        iconSource = -1,
        displayIcon = 134400,
        zoom = 0.07,
        color = { 1, 1, 1, 1 },
        cooldown = slot <= 2,
        cooldownSwipe = true,
        cooldownEdge = slot <= 2,
        cooldownTextDisabled = true,
        load = {
            class = { multi = {} },
            spec = { multi = {} },
            size = { multi = {} },
            talent = { multi = {} },
        },
        triggers = {
            {
                trigger = {
                    type = 'custom',
                    custom_type = 'status',
                    check = 'update',
                    onUpdateThrottle = 0.1,
                    custom = trigger(slot),
                    customIcon = [[function()
                    local info = aura_env.spell and C_Spell.GetSpellInfo(aura_env.spell)
                    return info and info.iconID or 134400
                end]],
                    customName = [[function() return aura_env.key or '' end]],
                    customDuration = slot <= 2
                            and [[function()
                        if type(RaynnaRotationHelperForeverGCD) ~= 'function' then return 0, 0 end
                        return RaynnaRotationHelperForeverGCD()
                    end]]
                        or '',
                    debuffType = 'HELPFUL',
                },
                untrigger = {},
            },
            disjunctive = 'any',
            activeTriggerMode = -10,
        },
        subRegions = {
            { type = 'subbackground' },
            {
                type = 'subborder',
                border_visible = true,
                border_size = 1,
                border_offset = 1,
                border_edge = 'Square Full White',
                border_color = { 0, 0, 0, 1 },
            },
            {
                type = 'subglow',
                glow = true,
                glowType = 'Proc',
                glowFrequency = 0.25,
                glowDuration = 1,
                glowThickness = 1,
                glowScale = 1,
                glowLength = 10,
                glowLines = 8,
                glowBorder = false,
                glowColor = slot == 1 and { 1, 0.82, 0.15, 1 } or { 0.3, 0.7, 1, 1 },
            },
            {
                type = 'subtext',
                text_text = '%n',
                text_visible = true,
                text_font = 'Friz Quadrata TT',
                text_fontSize = slot == 1 and 16 or 12,
                text_fontType = 'OUTLINE',
                text_color = { 1, 1, 1, 1 },
                text_shadowColor = { 0, 0, 0, 1 },
                text_shadowXOffset = 1,
                text_shadowYOffset = -1,
                text_selfPoint = 'AUTO',
                anchor_point = 'INNER_BOTTOM',
                text_justify = 'CENTER',
                text_automaticWidth = 'Auto',
                text_fixedWidth = size,
            },
        },
        animation = { start = { type = 'none' }, main = { type = 'none' }, finish = { type = 'none' } },
        actions = { start = {}, init = {}, finish = {} },
        conditions = {},
        config = {},
        authorOptions = {},
        information = { showNilIsFalse = true },
    }
end

function A.InstallAuras()
    local WA = ForeverAuras or WeakAuras
    if not WA or not WA.Add or not WA.GetData or A.Call(InCombatLockdown) then
        return false
    end
    if WA.IsLoginFinished and not WA.IsLoginFinished() then
        return false
    end
    local old = WA.GetData(groupID)
    local group = {
        id = groupID,
        uid = 'raynna-forever-group',
        regionType = 'group',
        internalVersion = 90,
        controlledChildren = {},
        raynnaLayoutVersion = 2,
        xOffset = old and old.xOffset or 0,
        yOffset = old and old.yOffset or -120,
        anchorPoint = 'CENTER',
        selfPoint = 'CENTER',
        anchorFrameType = 'SCREEN',
        frameStrata = 4,
        alpha = 1,
        scale = old and old.scale or A.db.scale,
        load = {
            class = { multi = {} },
            spec = { multi = {} },
            size = { multi = {} },
            talent = { multi = {} },
        },
        triggers = {
            {
                trigger = {
                    type = 'custom',
                    custom_type = 'status',
                    check = 'update',
                    onUpdateThrottle = 0.25,
                    custom = 'function() return true end',
                    debuffType = 'HELPFUL',
                },
                untrigger = {},
            },
            disjunctive = 'any',
            activeTriggerMode = -10,
        },
        subRegions = {},
        config = {},
        authorOptions = {},
        information = { showNilIsFalse = true },
        conditions = {},
        actions = { start = {}, init = {}, finish = {} },
        animation = { start = { type = 'none' }, main = { type = 'none' }, finish = { type = 'none' } },
    }
    WA.Add(group)
    for slot = 1, 7 do
        local data = child(slot)
        local saved = WA.GetData(data.id)
        -- Update engine triggers without undoing the player's visual adjustments.
        for _, key in ipairs({ 'width', 'height', 'xOffset', 'yOffset', 'zoom', 'alpha', 'subRegions' }) do
            if saved and saved[key] ~= nil then
                local legacyDefault = not (old and old.raynnaLayoutVersion == 2)
                    and (
                        (key == 'xOffset' and saved[key] == (slot == 1 and 0 or 54 + (slot - 2) * 40))
                        or (key == 'yOffset' and saved[key] == 0)
                        or ((key == 'width' or key == 'height') and saved[key] == (slot == 1 and 56 or 36))
                    )
                if not legacyDefault then
                    data[key] = saved[key]
                end
            end
        end
        WA.Add(data)
        table.insert(group.controlledChildren, data.id)
    end
    WA.Add(group)
    A.aurasEnabled = true
    if A.frame then
        A.frame:Hide()
    end
    if WA.ScanEvents then
        WA.ScanEvents('RAYNNA_ROTATION_UPDATE')
    end
    return true
end

local installing, attempts = false, 0
function A.TryInstallAuras()
    if A.aurasEnabled or installing then
        return
    end
    attempts = attempts + 1
    local ok, installed = pcall(A.InstallAuras)
    if ok and installed then
        return
    end
    if not ok then
        A.auraInstallError = tostring(installed)
    end
    -- The fork loads saved displays asynchronously after PLAYER_LOGIN.
    if attempts < 15 and C_Timer and C_Timer.After then
        installing = true
        C_Timer.After(1, function()
            installing = false
            A.TryInstallAuras()
        end)
    elseif not ok then
        print("Raynna's Rotation Helper: aura setup failed: " .. A.auraInstallError)
    end
end

function A.CenterAuras()
    local WA = ForeverAuras or WeakAuras
    if not WA or not WA.GetData or A.Call(InCombatLockdown) then
        return
    end
    local data = WA.GetData(groupID)
    if data then
        data.xOffset = 0
        data.yOffset = -120
        WA.Add(data)
    end
end

function A.OpenAuraOptions()
    local WA = ForeverAuras or WeakAuras
    if WA and WA.OpenOptions then
        WA.OpenOptions(groupID)
    elseif WA and WA.ToggleOptions then
        WA.ToggleOptions()
    end
end

function A.ApplyAuraScale()
    local WA = ForeverAuras or WeakAuras
    if not WA or not WA.GetData or A.Call(InCombatLockdown) then
        return
    end
    local data = WA.GetData(groupID)
    if data then
        data.scale = A.db.scale
        WA.Add(data)
    end
end
