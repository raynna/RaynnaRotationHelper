local _, A = ...
local function text(parent, size, x, y, value)
    local label = parent:CreateFontString(nil, 'OVERLAY')
    label:SetFont(STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF', size)
    label:SetPoint('TOPLEFT', x, y)
    label:SetTextColor(1, 0.85, 0.5)
    label:SetText(value or '')
    return label
end
local function button(parent, x, y, width, value, callback)
    local control = CreateFrame('Button', nil, parent, 'UIPanelButtonTemplate')
    control:SetPoint('TOPLEFT', x, y)
    control:SetSize(width, 22)
    control:SetText(value)
    control:SetScript('OnClick', callback)
    return control
end
local function icon(parent, x, y, size)
    local frame = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
    frame:SetPoint('TOPLEFT', x, y)
    frame:SetSize(size, size)
    frame:SetBackdrop({ edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border', edgeSize = 10 })
    frame:SetBackdropBorderColor(0.74, 0.55, 0.22)
    frame.texture = frame:CreateTexture(nil, 'ARTWORK')
    frame.texture:SetPoint('TOPLEFT', 3, -3)
    frame.texture:SetPoint('BOTTOMRIGHT', -3, 3)
    frame.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    frame:EnableMouse(true)
    frame:SetScript('OnEnter', function(self)
        if not self.entry then
            return
        end
        GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
        GameTooltip:SetSpellByID(self.entry.id)
        GameTooltip:AddLine(self.entry.hint, 1, 0.85, 0.5, true)
        GameTooltip:Show()
    end)
    frame:SetScript('OnLeave', function()
        GameTooltip:Hide()
    end)
    return frame
end
local function fill(frame, entry)
    frame.entry = entry
    local info = entry and A.SpellInfo(entry.id)
    frame.texture:SetTexture(info and info.iconID or 134400)
    frame:SetAlpha(entry and 1 or 0.3)
end

function A.SetScale(value)
    value = tonumber(value)
    if not value then
        return
    end
    A.db.scale = math.max(0.4, math.min(1.8, value))
    if A.frame then
        A.frame:SetScale(A.db.scale)
    end
    if A.ApplyAuraScale then
        A.ApplyAuraScale()
    end
end

function A.CycleProfile()
    local choices = { 'auto' }
    for _, profile in ipairs(A.profiles) do
        if profile.class == A.class then
            table.insert(choices, profile.key)
        end
    end
    for i, key in ipairs(choices) do
        if key == A.db.profile then
            A.db.profile = choices[i % #choices + 1]
            A.Update()
            return
        end
    end
    A.db.profile = 'auto'
    A.Update()
end

function A.BuildUI()
    local frame = CreateFrame('Frame', 'RaynnaRotationHelperForeverFrame', UIParent, 'BackdropTemplate')
    A.frame = frame
    frame:SetSize(370, 242)
    frame:SetScale(A.db.scale)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag('LeftButton')
    frame:SetScript('OnDragStart', function(self)
        if not A.db.locked then
            self:StartMoving()
        end
    end)
    frame:SetScript('OnDragStop', function(self)
        self:StopMovingOrSizing()
        local point, _, relative, x, y = self:GetPoint()
        A.db.position = { point = point, relative = relative, x = x, y = y }
    end)
    local position = A.db.position
    if position then
        frame:SetPoint(position.point, UIParent, position.relative, position.x, position.y)
    else
        frame:SetPoint('CENTER', 0, -150)
    end
    frame:SetBackdrop({
        bgFile = 'Interface\\Tooltips\\UI-Tooltip-Background',
        edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
        edgeSize = 12,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.035, 0.027, 0.018, 0.97)
    frame:SetBackdropBorderColor(0.74, 0.55, 0.22)
    local title = frame:CreateTexture(nil, 'BACKGROUND')
    title:SetColorTexture(0.24, 0.115, 0.035, 1)
    title:SetPoint('TOPLEFT', 5, -5)
    title:SetPoint('TOPRIGHT', -5, -5)
    title:SetHeight(23)
    text(frame, 13, 12, -10, "Raynna's Rotation Helper")
    button(frame, 312, -6, 23, '?', function()
        RaynnaModsSettingsRegistry:Open('rotationhelper')
    end)
    button(frame, 338, -6, 23, 'X', function()
        A.db.hidden = true
        A.Update()
    end)
    frame.profile = button(frame, 12, -34, 240, '', A.CycleProfile)
    frame.mode = button(frame, 258, -34, 100, '', function()
        A.db.mode = A.db.mode == 'trash' and 'auto' or 'trash'
        A.Update()
    end)
    frame.status = text(frame, 11, 12, -63)
    frame.primary = icon(frame, 12, -82, 54)
    frame.name = text(frame, 13, 76, -86)
    frame.name:SetWidth(278)
    frame.name:SetJustifyH('LEFT')
    frame.hint = text(frame, 10, 76, -108)
    frame.hint:SetWidth(278)
    frame.hint:SetJustifyH('LEFT')
    text(frame, 10, 12, -143, 'Secondary suggestions')
    text(frame, 10, 248, -143, '')
    frame.guide, frame.support = {}, {}
    for i = 1, 6 do
        frame.guide[i] = icon(frame, 12 + (i - 1) * 37, -159, 34)
    end
    for i = 1, 3 do
        frame.support[i] = icon(frame, 248 + (i - 1) * 37, -159, 34)
    end
    frame.resource = CreateFrame('StatusBar', nil, frame)
    frame.resource:SetPoint('TOPLEFT', 12, -205)
    frame.resource:SetSize(346, 10)
    frame.resource:SetStatusBarTexture('Interface\\TargetingFrame\\UI-StatusBar')
    frame.resource:SetStatusBarColor(0.2, 0.5, 0.9)
    frame.resourceText = text(frame, 10, 12, -220)
    frame:EnableMouseWheel(true)
    frame:SetScript('OnMouseWheel', function(_, delta)
        if IsControlKeyDown() then
            A.SetScale(A.db.scale + delta * 0.05)
        end
    end)
end

function A.Draw(result)
    local frame = A.frame
    if not frame then
        return
    end
    frame:SetShown(not A.db.hidden and not A.aurasEnabled)
    frame.profile:SetText(
        (A.db.profile == 'auto' and 'Auto: ' or '') .. (result.profile and result.profile.name or A.class)
    )
    frame.mode:SetText(A.db.mode == 'trash' and 'Multi-target' or 'Single target')
    frame.status:SetText(result.status)
    local entry = result.primary
    fill(frame.primary, entry)
    local info = entry and A.SpellInfo(entry.id)
    frame.name:SetText(info and info.name or 'Waiting for an available ability')
    frame.hint:SetText(
        entry and entry.hint or 'Target an enemy. Suggestions update as abilities become usable.'
    )
    for i, slot in ipairs(frame.guide) do
        fill(slot, result.support[i])
        slot:SetShown(result.support[i] ~= nil)
    end
    for i, slot in ipairs(frame.support) do
        slot:Hide()
    end
    local powerType = A.Call(UnitPowerType, 'player')
    local value = A.Call(UnitPower, 'player', powerType)
    local maximum = A.Call(UnitPowerMax, 'player', powerType)
    if type(value) == 'number' and type(maximum) == 'number' and maximum > 0 then
        frame.resource:SetMinMaxValues(0, maximum)
        frame.resource:SetValue(value)
        frame.resource:Show()
        local label = ({ [0] = 'Mana', [1] = 'Rage', [2] = 'Focus', [3] = 'Energy' })[powerType] or 'Power'
        local combo = A.Call(GetComboPoints, 'player', 'target')
        local suffix = type(combo) == 'number' and combo > 0 and ('  |  Combo points: ' .. combo) or ''
        frame.resourceText:SetText(label .. ': ' .. value .. ' / ' .. maximum .. suffix)
    else
        frame.resource:Hide()
        frame.resourceText:SetText('Resource data unavailable')
    end
end

-- Independent non-secure borders; never modify action bindings or cast spells.
function A.PrepareActionGlows()
    if A.Call(InCombatLockdown) then
        return
    end
    A.actionGlows = A.actionGlows or {}
    for _, prefix in ipairs({
        'ActionButton',
        'MultiBarBottomLeftButton',
        'MultiBarBottomRightButton',
        'MultiBarRightButton',
        'MultiBarLeftButton',
        'MultiBar5Button',
        'MultiBar6Button',
        'MultiBar7Button',
    }) do
        for index = 1, 12 do
            local name = prefix .. index
            local action = _G[name]
            if action and not A.actionGlows[name] then
                local border = CreateFrame('Frame', nil, UIParent, 'BackdropTemplate')
                border:SetPoint('TOPLEFT', action, 'TOPLEFT', -3, 3)
                border:SetPoint('BOTTOMRIGHT', action, 'BOTTOMRIGHT', 3, -3)
                border:SetFrameStrata('HIGH')
                border:SetBackdrop({ edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border', edgeSize = 12 })
                border:SetBackdropBorderColor(1, 0.82, 0.1)
                border:Hide()
                A.actionGlows[name] = { button = action, border = border }
            end
        end
    end
end

local function actionSlot(button)
    -- The secure action attribute can be an unpaged index (1-12), while Cat
    -- Form displays another page. Use the client's resolved action first.
    local slot = A.Call(button.CalculateAction, button) or A.Call(button.GetPagedID, button)
    if A.Readable(slot) and type(slot) == 'number' and slot > 0 then
        return slot
    end
    slot = button.action
    if A.Readable(slot) and type(slot) == 'number' and slot > 0 then
        return slot
    end
    return A.Call(button.GetAttribute, button, 'action')
end

local function actionSpell(button)
    local slot = actionSlot(button)
    if not A.Readable(slot) or type(slot) ~= 'number' or not GetActionInfo then
        return
    end
    local ok, kind, id, subType, spellID = pcall(GetActionInfo, slot)
    if not ok or not A.Readable(kind) then
        return
    end
    if kind == 'macro' then
        -- Modern clients may return macro, spellID, "spell", not a macro index.
        if A.Readable(subType) and subType == 'spell' and A.Readable(id) then
            return id
        end
        if A.Readable(subType) and subType == 'item' then
            return
        end
        if not A.Readable(id) then
            return
        end
        return A.Call(GetMacroSpell, id)
    end
    if kind == 'spell' then
        if A.Readable(spellID) and type(spellID) == 'number' and spellID > 0 then
            return spellID
        end
        if A.Readable(id) then
            return id
        end
    end
end

local function sameSpell(left, right)
    if not left or not right then
        return false
    end
    if left == right then
        return true
    end
    if type(left) == 'string' then
        local info = A.SpellInfo(right)
        return info and A.Readable(info.name) and left == info.name
    end
    local a, b = A.SpellInfo(left), A.SpellInfo(right)
    return a and b and A.Readable(a.name) and A.Readable(b.name) and a.name == b.name
end

local function macroMatches(id, spell)
    local info = A.SpellInfo(spell)
    if not info or not A.Readable(info.name) or type(info.name) ~= 'string' then
        return false
    end
    local body = A.Call(GetMacroBody, id)
    if not body and GetMacroInfo then
        local ok, _, _, text = pcall(GetMacroInfo, id)
        if ok and A.Readable(text) then
            body = text
        end
    end
    if type(body) ~= 'string' then
        return false
    end
    local wanted = info.name:lower()
    for line in body:gmatch('[^\r\n]+') do
        local command, arguments = line:match('^%s*([/#]%S+)%s*(.-)%s*$')
        command = command and command:lower()
        if
            command == '/cast'
            or command == '/use'
            or command == '/castsequence'
            or command == '/castrandom'
            or command == '#showtooltip'
        then
            -- Ask the client to choose conditional branches when possible. This
            -- only reads the command; it never executes a macro or casts a spell.
            if arguments:find('[', 1, true) and SecureCmdOptionParse then
                arguments = A.Call(SecureCmdOptionParse, arguments) or ''
            end
            arguments = arguments:gsub('%b[]', ''):gsub('reset=%S+%s*', '')
            for token in arguments:gmatch('[^,;]+') do
                token = token:match('^%s*(.-)%s*$'):gsub('^!', '')
                token = token:gsub('%s*%([^)]*%)%s*$', ''):lower()
                if token == wanted then
                    return true
                end
                if command ~= '/use' and tonumber(token) == spell then
                    return true
                end
            end
        end
    end
    return false
end

local function buttonMatches(button, spell)
    if not spell then
        return false
    end
    local resolved = actionSpell(button)
    if sameSpell(resolved, spell) then
        return true
    end
    local slot = actionSlot(button)
    if not A.Readable(slot) or type(slot) ~= 'number' or not GetActionInfo then
        return false
    end
    local ok, kind, id, subType = pcall(GetActionInfo, slot)
    return ok
        and A.Readable(kind)
        and kind == 'macro'
        and A.Readable(subType)
        and subType ~= 'spell'
        and subType ~= 'item'
        and A.Readable(id)
        and type(id) == 'number'
        and macroMatches(id, spell)
end

function A.DebugActionBars()
    A.PrepareActionGlows()
    local spell = A.last and A.last.primary and A.last.primary.id
    local info = spell and A.SpellInfo(spell)
    local count = 0
    for _ in pairs(A.actionGlows or {}) do
        count = count + 1
    end
    print(
        'RRH: buttons='
            .. count
            .. ' primary='
            .. tostring(spell)
            .. ' name='
            .. tostring(info and A.Readable(info.name) and info.name)
            .. ' key='
            .. (spell and A.KeyForSpell(spell) or '')
            .. ' glows='
            .. tostring(A.db.actionBarGlow ~= false)
    )
    local names = {}
    for name in pairs(A.actionGlows or {}) do
        table.insert(names, name)
    end
    table.sort(names)
    for _, name in ipairs(names) do
        local entry = A.actionGlows[name]
        if entry.button:IsShown() then
            local slot = actionSlot(entry.button)
            local kind, id
            if A.Readable(slot) and type(slot) == 'number' and GetActionInfo then
                local ok, actionType, actionID = pcall(GetActionInfo, slot)
                if ok and A.Readable(actionType) then
                    kind = actionType
                end
                if ok and A.Readable(actionID) then
                    id = actionID
                end
            end
            local matches = buttonMatches(entry.button, spell)
            if name:match('^ActionButton%d+$') or kind == 'macro' or matches then
                local hot = entry.button.HotKey
                print(
                    name
                        .. ' slot='
                        .. tostring(A.Readable(slot) and slot or 'restricted')
                        .. ' type='
                        .. tostring(kind)
                        .. ' id='
                        .. tostring(id)
                        .. ' resolved='
                        .. tostring(actionSpell(entry.button))
                        .. ' match='
                        .. tostring(matches and true or false)
                        .. ' hotkey='
                        .. tostring(hot and A.Call(hot.GetText, hot))
                )
            end
        end
    end
end

function A.KeyForSpell(spell)
    for name, entry in pairs(A.actionGlows or {}) do
        if entry.button:IsShown() and buttonMatches(entry.button, spell) then
            local binding = entry.button.bindingAction
            if not A.Readable(binding) or type(binding) ~= 'string' then
                local prefix, number = name:match('^(.-)(%d+)$')
                local commands = {
                    ActionButton = 'ACTIONBUTTON',
                    MultiBarBottomLeftButton = 'MULTIACTIONBAR1BUTTON',
                    MultiBarBottomRightButton = 'MULTIACTIONBAR2BUTTON',
                    MultiBarRightButton = 'MULTIACTIONBAR3BUTTON',
                    MultiBarLeftButton = 'MULTIACTIONBAR4BUTTON',
                    MultiBar5Button = 'MULTIACTIONBAR5BUTTON',
                    MultiBar6Button = 'MULTIACTIONBAR6BUTTON',
                    MultiBar7Button = 'MULTIACTIONBAR7BUTTON',
                }
                binding = commands[prefix] and commands[prefix] .. number
            end
            local key = binding and A.Call(GetBindingKey, binding)
            if not key or key == '' then
                key = A.Call(GetBindingKey, 'CLICK ' .. name .. ':LeftButton')
            end
            if not key or key == '' then
                local hotkey = entry.button.HotKey or _G[name .. 'HotKey']
                key = hotkey and A.Call(hotkey.GetText, hotkey)
                if key == RANGE_INDICATOR or key == '●' then
                    key = nil
                end
            end
            if key then
                return key:gsub('SHIFT%-', 'S-'):gsub('CTRL%-', 'C-'):gsub('ALT%-', 'A-')
            end
        end
    end
    return ''
end

function A.UpdateActionGlows()
    local visible = not A.db.hidden and A.db.actionBarGlow ~= false
    local primary = A.last.primary and not A.last.primary.pending and A.last.primary.id
    for _, entry in pairs(A.actionGlows or {}) do
        local matches, main = false, false
        if visible and entry.button:IsShown() then
            main = buttonMatches(entry.button, primary)
            matches = main or buttonMatches(entry.button, A.last.alternate and A.last.alternate.id)
            if not matches then
                for _, suggestion in ipairs(A.last.support or {}) do
                    if buttonMatches(entry.button, suggestion.id) then
                        matches = true
                        break
                    end
                end
            end
        end
        if main then
            entry.border:SetBackdropBorderColor(1, 0.82, 0.1)
        else
            entry.border:SetBackdropBorderColor(0.3, 0.7, 1)
        end
        entry.border:SetShown(matches and true or false)
    end
end

function A.BuildSettings()
    RaynnaModsSettingsRegistry:Register('rotationhelper', 'Rotation Helper', function(parent)
        text(parent, 18, 24, -15, "Raynna's Rotation Helper — Forever")
        text(
            parent,
            12,
            24,
            -46,
            'Live icons use ForeverAuras. Change size below; edit positions in aura options.'
        )
        local refresh
        local visibility = button(parent, 24, -78, 220, '', function()
            A.db.hidden = not A.db.hidden
            A.Update()
            refresh()
        end)
        local lock = button(parent, 24, -110, 220, '', function()
            A.OpenAuraOptions()
            refresh()
        end)
        local glow = button(parent, 264, -110, 220, '', function()
            A.db.actionBarGlow = A.db.actionBarGlow == false
            A.Update()
            refresh()
        end)
        button(parent, 24, -142, 220, 'Center window', function()
            A.CenterAuras()
            A.db.position = nil
            A.frame:ClearAllPoints()
            A.frame:SetPoint('CENTER', 0, -150)
        end)
        local profileButton = button(parent, 24, -174, 220, '', function()
            A.CycleProfile()
            refresh()
        end)
        local modeButton = button(parent, 264, -174, 220, '', function()
            A.db.mode = A.db.mode == 'trash' and 'auto' or 'trash'
            A.Update()
            refresh()
        end)
        text(parent, 12, 24, -215, 'Interface scale')
        local input = CreateFrame('EditBox', nil, parent, 'InputBoxTemplate')
        input:SetPoint('TOPLEFT', 190, -210)
        input:SetSize(60, 24)
        input:SetAutoFocus(false)
        refresh = function()
            local profile = A.Profile()
            profileButton:SetText(
                (A.db.profile == 'auto' and 'Auto: ' or '') .. (profile and profile.name or A.class)
            )
            modeButton:SetText(A.db.mode == 'trash' and 'Multi-target' or 'Single target')
            visibility:SetText(A.db.hidden and 'Show helper' or 'Hide helper')
            lock:SetText('Move / customize icons')
            glow:SetText(
                A.db.actionBarGlow == false and 'Enable action bar glow' or 'Disable action bar glow'
            )
            input:SetText(math.floor(A.db.scale * 100 + 0.5) .. '%')
        end
        input:SetScript('OnEnterPressed', function(self)
            local value = tonumber(((self:GetText() or ''):gsub('%%', '')))
            if value then
                A.SetScale(value / 100)
            end
            self:ClearFocus()
            refresh()
        end)
        input:SetScript('OnEscapePressed', function(self)
            self:ClearFocus()
            refresh()
        end)
        button(parent, 153, -210, 26, '-', function()
            A.SetScale(A.db.scale - 0.05)
            refresh()
        end)
        button(parent, 261, -210, 26, '+', function()
            A.SetScale(A.db.scale + 0.05)
            refresh()
        end)
        text(parent, 12, 24, -260, 'Unavailable conditions are skipped. WAIT means the action is not ready.')
        text(parent, 12, 24, -284, 'Healing profiles provide damage and utility suggestions.')
        return refresh
    end)
end
