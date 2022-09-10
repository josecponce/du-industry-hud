require('du_lib/requires/service')
require('du_lib/requires/dataHud')
require('du_lib/markers/MarkerManager')

require('IndustryHudMaster/model/IndustryHudMachine')
require('IndustryHudMaster/services/RecipeContainerHighlighter')
require('IndustryHudMaster/services/IndustryManager')

---@class IndustryHud : Service
IndustryHud = {}
IndustryHud.__index = IndustryHud

---@class IndustryType
IndustryType = {}
IndustryType.__index = IndustryType

---@return IndustryType
function IndustryType.new(type, tier)
    local self = --[[---@type self]] { }

    self.type = type
    self.tier = tier

    return setmetatable(self, IndustryType)
end

local HEADERS = { 'Id', 'Name', 'Output', 'Cycles From Start', 'Status', 'Mode', 'Time Remaining', 'Quantity' }
local INDUSTRY_MARKER_NAME = 'IndustryHud_selected_industry'

---@param system System
---@param core CoreUnit
---@param hud FullDataHud
---@param recipeContainerHighlighter RecipeContainerHighlighter
---@param markerManager MarkerManager
---@param industryManager IndustryManager
---@return IndustryHud
function IndustryHud.new(system, core, hud, markerManager, recipeContainerHighlighter, industryManager)
    local self = --[[---@type self]] Service.new()

    ---@type table<string, IndustryHudMachine[]>
    local industries
    ---@type string[]
    local industryTypes
    local typeSelectedIndex = 1
    local industrySelectedIndex = 1

    local function updateRecipe()
        if not industries then
            return
        end

        local type = industryTypes[typeSelectedIndex]
        local typeIndustries = industries[type]
        local industry = typeIndustries[industrySelectedIndex]

        recipeContainerHighlighter.updateOutput(industry.productId)
    end

    ---@param permit CoroutinePermit
    local function refreshIndustries(permit)
        local coreElementIds = core.getElementIdList()
        ---@type table<string, IndustryHudMachine[]>
        local loadedIndustries = {}

        for i = 1, #coreElementIds do
            permit.acquire()

            local id = coreElementIds[i]

            if IndustryHudMachine.isIndustry(core, id) then
                local industry = IndustryHudMachine.new(system, core, id)
                industry.refresh()
                loadedIndustries[industry.type] = loadedIndustries[industry.type] or {}
                table.insert(loadedIndustries[industry.type], industry)
            end
        end

        ---@type IndustryType[]
        local typesWithInfo = {}

        for type, typeIndustries in pairs(loadedIndustries) do
            local industry1 = typeIndustries[1]
            table.insert(typesWithInfo, IndustryType.new(type, industry1.tier))

            table.sort(typeIndustries, function(l, r)
                return l.productName < r.productName
                        or (l.productName == r.productName and l.typeWithSize < r.typeWithSize)
            end)
        end

        table.sort(typesWithInfo, function(l, r)
            return l.tier > r.tier or (l.tier == r.tier and l.type > r.type)
        end)

        local loadedTypes = {}
        for _, type in ipairs(typesWithInfo) do
            table.insert(loadedTypes, type.type)
        end

        industryTypes, industries = loadedTypes, loadedIndustries
        updateRecipe()
    end

    local function updateHud()
        if not industries then
            return
        end

        local type = industryTypes[typeSelectedIndex]
        local typeIndustries = industries[type]

        local industry = typeIndustries[industrySelectedIndex]
        markerManager.setElementMarker(INDUSTRY_MARKER_NAME, industry.id)

        local rows = {}
        for _, ind in ipairs(typeIndustries) do
            local quantity = recipeContainerHighlighter.getTotal(ind.productId)
            ind.refresh()
            table.insert(rows, {
                ind.id, ind.typeWithSize, ind.productName,
                ind.unitsProduced, ind.status, ind.mode,
                ind.remainingTimeString,
                string.format('%.0f', quantity)
            })
        end

        local data = FullDataHudData.new('Industry HUD', HEADERS, rows, industryTypes)
        hud.updateData(data)
    end

    ---@type IndustryHudMachine
    local commandIndustry
    local function selectType(_, selectedIndex)
        typeSelectedIndex = selectedIndex
        commandIndustry = nil
    end

    ---@param selectedIndex number
    local function selectIndustry(_, selectedIndex)
        industrySelectedIndex = selectedIndex
        commandIndustry = nil

        updateRecipe()
    end

    ---@param selectedTypeIndex number
    ---@param selectedIndustryIndex number
    local function onDetailActionLeft(_, selectedTypeIndex, selectedIndustryIndex)
        if not industries then
            return
        end

        local type = industryTypes[selectedTypeIndex]
        local typeIndustries = industries[type]
        local industry = typeIndustries[selectedIndustryIndex]

        for i, industryType in ipairs(industryTypes) do
            for j, factoryBuilder in ipairs(industries[industryType]) do
                if factoryBuilder.productId == industry.itemId then
                    hud.setSelected(i, j)
                end
            end
        end
    end

    ---@param selectedTypeIndex number
    ---@param selectedIndustryIndex number
    local function onDetailActionRight(_, selectedTypeIndex, selectedIndustryIndex)
        if not industries then
            return
        end

        local type = industryTypes[selectedTypeIndex]
        local typeIndustries = industries[type]
        local industry = typeIndustries[selectedIndustryIndex]

        for i, industryType in ipairs(industryTypes) do
            if industryType == industry.productType then
                hud.setSelected(i, 1)
            end
        end
    end

    ---@param selectedTypeIndex number
    ---@param selectedIndustryIndex number
    local function onDetailActionDown(_, selectedTypeIndex, selectedIndustryIndex)
        system.print('Please enter a command for current industry:')
        local type = industryTypes[selectedTypeIndex]
        local typeIndustries = industries[type]
        commandIndustry = typeIndustries[selectedIndustryIndex]
    end

    local function onInputText(_, text)
        if commandIndustry then
            industryManager.executeCommand(commandIndustry, text)
            commandIndustry = nil
        end
    end

    self.hasHud = true
    ---@return string
    function self.drawHud()
        return hud.drawHud() .. recipeContainerHighlighter.drawHud()
    end

    ---@param state State
    function self.start(state)
        state.registerCoroutine(self, 'IndustryHud_init', refreshIndustries, true)
        state.registerTimer('IndustryHud_refresh', 1, updateHud)
        state.registerHandler(hud, FULL_DATA_HUD_EVENTS.GROUP_SELECTED, selectType)
        state.registerHandler(hud, FULL_DATA_HUD_EVENTS.DETAIL_SELECTED, selectIndustry)
        state.registerHandler(hud, FULL_DATA_HUD_EVENTS.DETAIL_ACTION_LEFT, onDetailActionLeft)
        state.registerHandler(hud, FULL_DATA_HUD_EVENTS.DETAIL_ACTION_RIGHT, onDetailActionRight)
        state.registerHandler(hud, FULL_DATA_HUD_EVENTS.DETAIL_ACTION_DOWN, onDetailActionDown)

        state.registerHandler(system, SYSTEM_EVENTS.INPUT_TEXT, onInputText)
    end

    return setmetatable(self, IndustryHud)
end