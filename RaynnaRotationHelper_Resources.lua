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

local SPRITE_PREFIX = "Interface\\AddOns\\RaynnaRotationHelper\\Media\\Sprites\\"
local RESOURCE_SPRITES = {
    COMBO_POINTS = "claw",
    ARCANE_CHARGES = "arcane-crystal",
    HOLY_POWER = "hammer",
    CHI = "dagger",
    SHADOW_ORBS = "arcane-crystal",
    SOUL_SHARDS = "arcane-crystal",
    BURNING_EMBERS = "dagger",
    DEMONIC_FURY = "dagger",
    DEFAULT = "dagger",
}

local function ResourceSprite(resource, filled)
    local name = RESOURCE_SPRITES[resource or ""] or RESOURCE_SPRITES.DEFAULT
    return SPRITE_PREFIX .. name .. (filled and "-filled-color.png" or "-outline-color.png")
end

local function ResourceColor(resource)
    local color = RESOURCE_COLORS[resource or ""] or { 1, 1, 1, 1 }
    return { color[1], color[2], color[3], color[4] }
end

local function GenericLoad()
    return { use_petbattle = false, use_vehicleUi = false, use_never = false, class = { multi = {} }, class_and_spec = { multi = {} }, talent = { multi = {} }, spec = { multi = {} }, size = { multi = {} } }
end

local function ResourceXOffset(index)
    return (index - 3) * 20
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
        texture = ResourceSprite(resource, true),
        textureWrapMode = "CLAMP",
        blendMode = "BLEND",
        width = 22,
        height = 22,
        xOffset = ResourceXOffset(index),
        yOffset = 0,
        anchorPoint = "CENTER",
        anchorFrameType = "SCREEN",
        selfPoint = "CENTER",
        frameStrata = 4,
        alpha = 0,
        color = { 1, 1, 1, 1 },
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
    local resource
    if _G.RaynnaRotationHelperGetResourceInfo then
        resource = select(3, _G.RaynnaRotationHelperGetResourceInfo())
    end
    return {
        id = id,
        uid = "raynna-rotation-resource-bg-" .. index,
        parent = parentId,
        regionType = "texture",
        texture = ResourceSprite(resource, false),
        textureWrapMode = "CLAMP",
        blendMode = "BLEND",
        width = 22,
        height = 22,
        xOffset = ResourceXOffset(index),
        yOffset = 0,
        anchorPoint = "CENTER",
        anchorFrameType = "SCREEN",
        selfPoint = "CENTER",
        frameStrata = 2,
        alpha = 1,
        color = { 1, 1, 1, 0.72 },
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
        texture = "Interface\\Buttons\\UI-ActionButton-Border",
        textureWrapMode = "CLAMP",
        blendMode = "ADD",
        width = 34,
        height = 34,
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

local RESOURCE_FILL_FULL_HEIGHT = 22
local RESOURCE_FILL_EMPTY_HEIGHT = 0.5
local RESOURCE_FILL_SPEED = 4.2
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

local function SetRegionTexture(region, texture)
    if not region or not texture then return end
    if region.SetTexture then
        pcall(region.SetTexture, region, texture)
    end
    if region.texture and region.texture.SetTexture then
        pcall(region.texture.SetTexture, region.texture, texture)
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

local function SetResourceFillCrop(region, height)
    if not region then return end
    local fraction = math.max(0.001, math.min(1, height / RESOURCE_FILL_FULL_HEIGHT))
    local top = 1 - fraction
    if region.texture and region.texture.SetTexCoord then
        region.texture:SetTexCoord(0, 1, top, 1)
    elseif region.SetTexCoord then
        region:SetTexCoord(0, 1, top, 1)
    end
end

local function SetResourceFillYOffset(region, height)
    if not region then return end
    local y = -11 + (height / 2)
    if region.SetYOffset then
        region:SetYOffset(y)
    elseif region.SetPoint and region.ClearAllPoints then
        region:ClearAllPoints()
        region:SetPoint("CENTER", UIParent, "CENTER", ResourceXOffset(region.RaynnaResourceIndex or 1), y)
    end
end

local activeResourceGlows = {}

local function EnsureResourceFallbackGlow(region)
    if not region or not region.CreateTexture then return nil end
    if region.RaynnaResourceGlow then
        return region.RaynnaResourceGlow
    end
    local glow = region:CreateTexture(nil, "OVERLAY")
    glow:SetTexture("Interface/Buttons/UI-ActionButton-Border")
    glow:SetBlendMode("ADD")
    glow:SetVertexColor(1, 0.78, 0.12, 0.95)
    glow:SetPoint("CENTER", region, "CENTER", 0, 0)
    glow:SetSize(44, 44)
    glow:Hide()
    region.RaynnaResourceGlow = glow
    return glow
end

local function ShowResourceGlow(region)
    if not region then return end
    if activeResourceGlows[region] then
        local existingGlow = EnsureResourceFallbackGlow(region)
        if existingGlow then existingGlow:Show() end
        return
    end
    activeResourceGlows[region] = true
    if ActionButton_ShowOverlayGlow then
        pcall(ActionButton_ShowOverlayGlow, region)
    end
    local glow = EnsureResourceFallbackGlow(region)
    if glow then glow:Show() end
end

local function HideResourceGlow(region)
    if not region then return end
    if ActionButton_HideOverlayGlow then
        pcall(ActionButton_HideOverlayGlow, region)
    end
    if region.RaynnaResourceGlow then
        region.RaynnaResourceGlow:Hide()
    end
    activeResourceGlows[region] = nil
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

    local borderColor = ResourceColor(resource)
    borderColor[4] = 0.32

    for i = 1, #RESOURCE_IDS do
        local fill = WeakAuraRegion(RESOURCE_IDS[i])
        local outline = WeakAuraRegion(RESOURCE_OUTLINE_IDS[i])
        local border = WeakAuraRegion(RESOURCE_GCD_IDS[i])
        local slotActive = maxCount > 0 and i <= maxCount
        local filled = slotActive and i <= count
        local targetHeight = filled and RESOURCE_FILL_FULL_HEIGHT or RESOURCE_FILL_EMPTY_HEIGHT
        local current = resourceFillHeights[i]
        if current == nil then current = targetHeight end
        local step = RESOURCE_FILL_SPEED * elapsed
        if current < targetHeight then
            current = math.min(targetHeight, current + step)
        elseif current > targetHeight then
            current = math.max(targetHeight, current - step)
        end
        resourceFillHeights[i] = current

        if fill then
            SetRegionTexture(fill, ResourceSprite(resource, true))
            fill.RaynnaResourceIndex = i
            SetResourceFillHeight(fill, current)
            SetResourceFillCrop(fill, current)
            SetResourceFillYOffset(fill, current)
            if fill.SetAlpha then
                local alpha = (slotActive and current > RESOURCE_FILL_EMPTY_HEIGHT + 0.05) and 1 or 0
                if remaining and remaining ~= math.huge and remaining <= 4 and filled then
                    alpha = math.max(0.45, alpha * (0.5 + 0.5 * math.abs(math.sin(now * 0.9))))
                end
                fill:SetAlpha(alpha)
            end
            SetTextureColor(fill, { 1, 1, 1, 1 })
        end

        if outline then
            SetRegionTexture(outline, ResourceSprite(resource, false))
            if outline.SetAlpha then outline:SetAlpha(slotActive and 0.9 or 0) end
            SetTextureColor(outline, { 1, 1, 1, 0.9 })
        end

        if border then
            borderColor[4] = slotActive and 0.28 or 0
            SetTextureColor(border, borderColor)
            HideResourceGlow(border)
        end
    end
end