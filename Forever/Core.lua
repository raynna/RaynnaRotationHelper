local _, A = ...
local events = CreateFrame('Frame')
A.events = events
local initialized, elapsed = false, 0

function A.Update()
    if not initialized then
        return
    end
    A.last = A.Evaluate()
    A.Draw(A.last)
    A.UpdateActionGlows()
end

local function initialize()
    if initialized then
        return
    end
    RaynnaRotationHelperForeverDB = RaynnaRotationHelperForeverDB or {}
    A.db = RaynnaRotationHelperForeverDB
    if A.db.profile == nil then
        A.db.profile = 'auto'
    end
    if A.db.mode ~= 'trash' then
        A.db.mode = 'auto'
    end
    A.db.scale = math.max(0.4, math.min(1.8, tonumber(A.db.scale) or 1))
    A.class = select(2, UnitClass('player'))
    A.RefreshTalents()
    A.RefreshSpells()
    A.BuildUI()
    A.BuildSettings()
    A.PrepareActionGlows()
    initialized = true
    A.TryInstallAuras()
    A.Update()
end

for _, event in ipairs({
    'PLAYER_LOGIN',
    'PLAYER_ENTERING_WORLD',
    'SPELLS_CHANGED',
    'PLAYER_TARGET_CHANGED',
    'PLAYER_REGEN_ENABLED',
    'PLAYER_REGEN_DISABLED',
    'UPDATE_SHAPESHIFT_FORM',
    'SPELL_UPDATE_COOLDOWN',
    'UNIT_AURA',
    'UNIT_POWER_UPDATE',
    'UNIT_HEALTH',
    'PLAYER_TALENT_UPDATE',
    'TRAIT_CONFIG_UPDATED',
    'UPDATE_BINDINGS',
    'UPDATE_MACROS',
    'ACTIONBAR_SLOT_CHANGED',
    'ACTIONBAR_PAGE_CHANGED',
    'UPDATE_BONUS_ACTIONBAR',
}) do
    pcall(events.RegisterEvent, events, event)
end
events:SetScript('OnEvent', function(_, event)
    if event == 'PLAYER_LOGIN' then
        initialize()
        return
    end
    if not initialized then
        return
    end
    if event == 'PLAYER_REGEN_ENABLED' or event == 'PLAYER_ENTERING_WORLD' then
        A.PrepareActionGlows()
        if not A.aurasEnabled then
            A.TryInstallAuras()
        end
        A.ApplyAuraScale()
    end
    if
        event == 'UPDATE_BINDINGS'
        or event == 'ACTIONBAR_SLOT_CHANGED'
        or event == 'ACTIONBAR_PAGE_CHANGED'
        or event == 'UPDATE_BONUS_ACTIONBAR'
        or event == 'UPDATE_SHAPESHIFT_FORM'
    then
        A.PrepareActionGlows()
    end
    if
        event == 'SPELLS_CHANGED'
        or event == 'PLAYER_TALENT_UPDATE'
        or event == 'TRAIT_CONFIG_UPDATED'
        or event == 'PLAYER_ENTERING_WORLD'
    then
        A.RefreshSpells()
        A.RefreshTalents()
    end
    if event == 'PLAYER_TARGET_CHANGED' then
        A.Update()
        return
    end
    -- Coalesce event bursts; timers handle cooldown expiration without a new event.
    elapsed = 0.2
end)
events:SetScript('OnUpdate', function(_, delta)
    if not initialized or A.db.hidden then
        return
    end
    elapsed = elapsed + delta
    if elapsed >= 0.2 then
        elapsed = 0
        A.Update()
    end
end)

SLASH_RAYNNAROTATIONHELPER1 = '/rrh'
SlashCmdList.RAYNNAROTATIONHELPER = function(message)
    if not initialized then
        return
    end
    message = (message or ''):lower():match('^%s*(.-)%s*$')
    if message == 'settings' or message == 'options' then
        RaynnaModsSettingsRegistry:Open('rotationhelper')
    elseif message == 'show' or message == 'hide' or message == '' then
        A.db.hidden = message == 'hide' or (message == '' and not A.db.hidden)
    elseif message == 'unlock' or message == 'lock' then
        A.db.locked = message == 'lock'
        if not A.db.locked then
            A.OpenAuraOptions()
        end
        print(
            "Raynna's Rotation Helper: "
                .. (
                    A.db.locked and 'close ForeverAuras options to finish moving.'
                    or 'move the group in ForeverAuras options.'
                )
        )
    elseif message:match('^scale ') then
        local value = tonumber(message:match('^scale (%d+)%%?$'))
        if value then
            A.SetScale(value / 100)
        end
    elseif message == 'mode trash' then
        A.db.mode = 'trash'
    elseif message == 'mode auto' or message == 'mode boss' then
        A.db.mode = 'auto'
    elseif message:match('^profile ') then
        local requested = message:match('^profile (.+)$')
        local valid = requested == 'auto'
        for _, profile in ipairs(A.profiles) do
            if profile.class == A.class and profile.key == requested then
                valid = true
            end
        end
        if valid then
            A.db.profile = requested
        else
            print('Unknown profile. Click the profile button to cycle your class profiles.')
        end
    elseif message == 'auras' then
        A.DebugAuras()
    elseif message == 'bars' then
        A.Update()
        A.DebugActionBars()
    elseif message == 'debug' then
        local profile = A.Profile()
        print('Forever beta | Class: ' .. A.class .. ' | Profile: ' .. (profile and profile.name or 'none'))
        print(A.last and A.last.status or 'Waiting for update')
        for _, entry in ipairs(A.last and A.last.guide or {}) do
            print(
                tostring(entry.id)
                    .. ' usable='
                    .. tostring(A.Call(C_Spell.IsSpellUsable, entry.id))
                    .. ' ready='
                    .. tostring(A.Ready(entry.id))
                    .. ' range='
                    .. tostring(A.Call(C_Spell.IsSpellInRange, entry.id, 'target'))
            )
        end
    else
        print(
            '/rrh show | hide | settings | lock | unlock | scale 80 | mode auto|trash|boss | profile auto | debug'
        )
    end
    A.Update()
end
