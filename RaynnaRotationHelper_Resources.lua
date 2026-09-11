local TARGET_ID = "Raynna Rotation Helper"
local ADDON_NAME = "Raynna Rotation Helper"
local RESOURCE_GROUP_ID = "Raynna's Pips"
local RESOURCE_IDS = {}
local RESOURCE_OUTLINE_IDS = {}
local RESOURCE_GCD_IDS = {}
for i = 1, 5 do
    RESOURCE_IDS[i] = RESOURCE_GROUP_ID .. " - Fill " .. i
    RESOURCE_OUTLINE_IDS[i] = RESOURCE_GROUP_ID .. " - Empty " .. i
    RESOURCE_GCD_IDS[i] = RESOURCE_GROUP_ID .. " - Pulse " .. i
end

local RESOURCE_SLOT_TRIGGER_TEMPLATE = [=[
function(event, ...)
    if not _G.RaynnaRotationHelperGetResourceInfo then
        return false
    end
    local count, maxCount = _G.RaynnaRotationHelperGetResourceInfo()
    if not maxCount or maxCount < %%INDEX%% then
        return false
    end
    if UnitExists and UnitExists("target") then
        return true
    end
    return (count or 0) >= %%INDEX%%
end
]=]

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

local function ResourceXOffset(index)
    return (index - 3) * 11
end

local function NoAnimation()
    return { start = { type = "none" }, main = { type = "none" }, finish = { type = "none" } }
end

local function SafeWeakAurasAdd(data)
    if not data or not WeakAuras or not WeakAuras.Add then return end
    local ok, err = pcall(WeakAuras.Add, data)
    if not ok then
        print("|cff66ccff" .. ADDON_NAME .. ":|r failed to add " .. tostring(data.id or "display") .. ": " .. tostring(err))
    end
end

local function BuildResourceGroup(parentId, includeChildren)
    local children = {}
    if includeChildren then
        for i = 1, #RESOURCE_OUTLINE_IDS do table.insert(children, RESOURCE_OUTLINE_IDS[i]) end
        for i = 1, #RESOURCE_IDS do table.insert(children, RESOURCE_IDS[i]) end
        for i = 1, #RESOURCE_GCD_IDS do table.insert(children, RESOURCE_GCD_IDS[i]) end
    end
    return {
        id = RESOURCE_GROUP_ID,
        uid = "raynna-rotation-resource-group",
        parent = parentId,
        regionType = "group",
        controlledChildren = children,
        internalVersion = 90,
        xOffset = -28,
        yOffset = -58,
        anchorPoint = "CENTER",
        anchorFrameType = "SCREEN",
        selfPoint = "CENTER",
        frameStrata = 1,
        alpha = 1,
        scale = 1,
        load = GenericLoad(),
        triggers = { { trigger = { type = "custom", event = "Health", unit = "player", custom_type = "status", check = "update", onUpdateThrottle = 0.25, custom = "function() return true end", names = {}, spellIds = {}, subeventPrefix = "SPELL", subeventSuffix = "_CAST_START", debuffType = "HELPFUL" }, untrigger = {} }, disjunctive = "any", activeTriggerMode = -10 },
        animation = NoAnimation(),
        actions = { start = {}, init = {}, finish = {} },
        conditions = {},
        subRegions = {},
        config = {},
        authorOptions = {},
        information = { showNilIsFalse = true, groupOffset = true, forceEvents = true, ignoreOptionsEventErrors = true },
    }
end

local function BuildResourceFillAura(parentId, index, forceChild)
    local childMode = parentId or forceChild
    local id = childMode and RESOURCE_IDS[index] or TARGET_ID
    local resource
    if _G.RaynnaRotationHelperGetResourceInfo then
        resource = select(3, _G.RaynnaRotationHelperGetResourceInfo())
    end
    return {
        id = id,
        uid = "raynna-rotation-resource-fill-" .. index,
        parent = parentId,
        regionType = "texture",
        texture = "Interface\\Buttons\\WHITE8X8",
        textureWrapMode = "CLAMP",
        blendMode = "BLEND",
        width = 7,
        height = 1,
        xOffset = ResourceXOffset(index),
        yOffset = -14,
        anchorPoint = "BOTTOM",
        anchorFrameType = "SCREEN",
        selfPoint = "BOTTOM",
        frameStrata = 4,
        alpha = 0,
        color = ResourceColor(resource),
        rotate = false,
        scalex = 1,
        scaley = 1,
        internalVersion = 90,
        load = GenericLoad(),
        triggers = {
            {
                trigger = { type = "custom", event = "Health", unit = "player", custom_type = "status", check = "update", onUpdateThrottle = 0.1, custom = RESOURCE_SLOT_TRIGGER_TEMPLATE:gsub("%%%%INDEX%%%%", tostring(index)), names = {}, spellIds = {}, subeventPrefix = "SPELL", subeventSuffix = "_CAST_START", debuffType = "HELPFUL" },
                untrigger = {},
            },
            disjunctive = "all",
            activeTriggerMode = -10,
        },
        animation = NoAnimation(),
        actions = { start = {}, init = {}, finish = {} },
        conditions = {},
        subRegions = { { type = "subbackground" } },
        config = {},
        authorOptions = {},
        information = { showNilIsFalse = true, forceEvents = true, ignoreOptionsEventErrors = true },
    }
end

local function BuildResourceBlackOutlineAura(parentId, index, forceChild)
    local childMode = parentId or forceChild
    local id = childMode and RESOURCE_OUTLINE_IDS[index] or TARGET_ID
    return {
        id = id,
        uid = "raynna-rotation-resource-bg-" .. index,
        parent = parentId,
        regionType = "texture",
        texture = "Interface\\Buttons\\WHITE8X8",
        textureWrapMode = "CLAMP",
        blendMode = "BLEND",
        width = 9,
        height = 28,
        xOffset = ResourceXOffset(index),
        yOffset = 0,
        anchorPoint = "CENTER",
        anchorFrameType = "SCREEN",
        selfPoint = "CENTER",
        frameStrata = 2,
        alpha = 1,
        color = { 0.035, 0.04, 0.05, 0.58 },
        scalex = 1,
        scaley = 1,
        internalVersion = 90,
        load = GenericLoad(),
        triggers = {
            {
                trigger = { type = "custom", event = "Health", unit = "player", custom_type = "status", check = "update", onUpdateThrottle = 0.1, custom = RESOURCE_SLOT_TRIGGER_TEMPLATE:gsub("%%%%INDEX%%%%", tostring(index)), names = {}, spellIds = {}, subeventPrefix = "SPELL", subeventSuffix = "_CAST_START", debuffType = "HELPFUL" },
                untrigger = {},
            },
            disjunctive = "any",
            activeTriggerMode = -10,
        },
        animation = NoAnimation(),
        actions = { start = {}, init = {}, finish = {} },
        conditions = {},
        subRegions = { { type = "subbackground" } },
        config = {},
        authorOptions = {},
        information = { showNilIsFalse = true, forceEvents = true, ignoreOptionsEventErrors = true },
    }
end

local function BuildResourceGcdAura(parentId, index, forceChild)
    local childMode = parentId or forceChild
    local id = childMode and RESOURCE_GCD_IDS[index] or TARGET_ID
    local resource
    if _G.RaynnaRotationHelperGetResourceInfo then
        resource = select(3, _G.RaynnaRotationHelperGetResourceInfo())
    end
    local borderColor = ResourceColor(resource)
    borderColor[4] = 0.32
    return {
        id = id,
        uid = "raynna-rotation-resource-border-" .. index,
        parent = parentId,
        regionType = "texture",
        texture = "Interface\\Buttons\\WHITE8X8",
        textureWrapMode = "CLAMP",
        blendMode = "ADD",
        width = 12,
        height = 32,
        xOffset = ResourceXOffset(index),
        yOffset = 0,
        anchorPoint = "CENTER",
        anchorFrameType = "SCREEN",
        selfPoint = "CENTER",
        frameStrata = 3,
        alpha = 0.42,
        color = borderColor,
        scalex = 1,
        scaley = 1,
        internalVersion = 90,
        load = GenericLoad(),
        triggers = {
            {
                trigger = { type = "custom", event = "Health", unit = "player", custom_type = "status", check = "update", onUpdateThrottle = 0.1, custom = RESOURCE_SLOT_TRIGGER_TEMPLATE:gsub("%%%%INDEX%%%%", tostring(index)), names = {}, spellIds = {}, subeventPrefix = "SPELL", subeventSuffix = "_CAST_START", debuffType = "HELPFUL" },
                untrigger = {},
            },
            disjunctive = "any",
            activeTriggerMode = -10,
        },
        animation = NoAnimation(),
        actions = { start = {}, init = {}, finish = {} },
        conditions = {},
        subRegions = {},
        config = {},
        authorOptions = {},
        information = { showNilIsFalse = true, forceEvents = true, ignoreOptionsEventErrors = true },
    }
end

function _G.RaynnaRotationHelperInstallResourcePips(parentId)
    SafeWeakAurasAdd(BuildResourceGroup(parentId, false))
    for i = 1, #RESOURCE_IDS do
        SafeWeakAurasAdd(BuildResourceBlackOutlineAura(RESOURCE_GROUP_ID, i, true))
        SafeWeakAurasAdd(BuildResourceFillAura(RESOURCE_GROUP_ID, i, true))
        SafeWeakAurasAdd(BuildResourceGcdAura(RESOURCE_GROUP_ID, i, true))
    end
    SafeWeakAurasAdd(BuildResourceGroup(parentId, true))
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

local RESOURCE_FILL_FULL_HEIGHT = 28
local RESOURCE_FILL_EMPTY_HEIGHT = 0.5
local RESOURCE_FILL_SPEED = 25
local resourceFillHeights = {}

local function SetTextureColor(region, color)
    if region and color then
        if region.Color then
            region:Color(color[1], color[2], color[3], color[4])
        elseif region.texture and region.texture.SetVertexColor then
            region.texture:SetVertexColor(color[1], color[2], color[3], color[4])
        end
    end
end

local function SetResourceFillHeight(region, height)
    if not region then return end
    if region.SetRegionHeight then
        region:SetRegionHeight(height)
    elseif region.SetHeight then
        region:SetHeight(height)
    end
end

function _G.RaynnaRotationHelperUpdateResourceVisuals(elapsed)
    local count, maxCount, resource, _, remaining = 0, 0, nil, nil, nil
    if _G.RaynnaRotationHelperGetResourceInfo then
        count, maxCount, resource, _, remaining = _G.RaynnaRotationHelperGetResourceInfo()
    end
    count = count or 0
    maxCount = maxCount or 0
    elapsed = elapsed or 0.05
    local now = GetTime and GetTime() or 0

    local baseColor = ResourceColor(resource)
    local borderColor = ResourceColor(resource)
    borderColor[4] = 0.32

    for i = 1, #RESOURCE_IDS do
        local fill = WeakAuraRegion(RESOURCE_IDS[i])
        local target = (i <= count) and RESOURCE_FILL_FULL_HEIGHT or RESOURCE_FILL_EMPTY_HEIGHT
        local current = resourceFillHeights[i]
        if current == nil then current = RESOURCE_FILL_EMPTY_HEIGHT end
        local step = RESOURCE_FILL_SPEED * elapsed
        if current < target then
            current = math.min(target, current + step)
        elseif current > target then
            current = math.max(target, current - step)
        end
        resourceFillHeights[i] = current

        if fill then
            SetResourceFillHeight(fill, current)
            if fill.SetAlpha then
                local alpha = current <= RESOURCE_FILL_EMPTY_HEIGHT + 0.01 and 0 or 1
                if resource == "ARCANE_CHARGES" and remaining and remaining ~= math.huge and remaining <= 4 and i <= count then
                    alpha = math.max(0.5, 0.55 + 0.45 * math.abs(math.sin(now * 4)))
                end
                fill:SetAlpha(alpha)
            end
            baseColor[4] = 1
            SetTextureColor(fill, baseColor)
        end

        local border = WeakAuraRegion(RESOURCE_GCD_IDS[i])
        if border then
            if maxCount > 0 and count >= maxCount and i <= maxCount then
                SetTextureColor(border, { 1, 0.82, 0.18, 0.95 })
            else
                SetTextureColor(border, borderColor)
            end
        end
    end
end