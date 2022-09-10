require('du_lib/requires/service')
require('du_lib/crafting/RecipeManager')

require('IndustryHudMaster/model/IndustryHudContainer')

---@class RecipeContainerHighlighter : Service
RecipeContainerHighlighter = {}
RecipeContainerHighlighter.__index = RecipeContainerHighlighter

local function ConvertLocalToWorld(a, b, c, d, e)
    local f = { a[1] * c[1], a[1] * c[2], a[1] * c[3] }
    local g = { a[2] * d[1], a[2] * d[2], a[2] * d[3] }
    local h = { a[3] * e[1], a[3] * e[2], a[3] * e[3] }
    return { f[1] + g[1] + h[1] + b[1], f[2] + g[2] + h[2] + b[2], f[3] + g[3] + h[3] + b[3] }
end

---@param system System
---@param core CoreUnit
---@param containerProficiencyLvl number
---@param containerOptimizationLvl number
---@return RecipeContainerHighlighter
function RecipeContainerHighlighter.new(system, core, containerProficiencyLvl, containerOptimizationLvl)
    local self = --[[---@type self]] Service.new()

    ---@type table<number, IndustryHudContainer[]>
    local containers
    ---@type number[]
    local ingredientItemIds
    ---@type number
    local outputItemId

    ---@param productItemId number
    ---@return number
    function self.getTotal(productItemId)
        local containers = containers
        local quantity = 0
        if containers then
            local productContainers = containers[productItemId]
            if productContainers then
                for _, container in ipairs(productContainers) do
                    quantity = quantity + container.quantity
                end
            end
        end

        return quantity
    end

    ---@param productItemId number
    function self.updateOutput(productItemId)
        if productItemId and productItemId >= 0 then
            local recipe = RecipeManager.getRawRecipe(system, productItemId)

            local newIngredients = {}
            for _, ingredient in ipairs(recipe.ingredients) do
                ---@type any
                local ingredient = ingredient
                table.insert(newIngredients, --[[---@type number]] ingredient.id)
            end
            outputItemId = productItemId
            ingredientItemIds = newIngredients
        end
    end

    ---@param permit CoroutinePermit
    local function refreshContainers(permit)
        local coreElementIds = core.getElementIdList()
        ---@type table<number, IndustryHudContainer[]>
        local loadedContainers = {}

        for i = 1, #coreElementIds do
            permit.acquire()

            local id = coreElementIds[i]

            if IndustryHudContainer.isContainer(core, id) then
                local container = IndustryHudContainer.new(core, id, containerProficiencyLvl, containerOptimizationLvl)
                container.refresh()
                if container.itemId then
                    loadedContainers[container.itemId] = loadedContainers[container.itemId] or {}
                    table.insert(loadedContainers[container.itemId], container)
                end
            end
        end

        containers = loadedContainers
    end

    local constructPos = construct.getWorldPosition()
    local constructRight = construct.getWorldRight()
    local constructForward = construct.getWorldForward()
    local constructUp = construct.getWorldUp()

    local inColorR, inColorG, inColorB = 51, 133, 255
    local outColorR, outColorG, outColorB = 0, 255, 128

    ---@param container IndustryHudContainer
    ---@return string
    local function highlightContainer(container, isOutput)
        local elementPos = core.getElementPositionById(container.id)
        local screenPos = library.getPointOnScreen(ConvertLocalToWorld(elementPos, constructPos, constructRight, constructForward, constructUp))
        local r, g, b
        if isOutput then
            r, g, b = outColorR, outColorG, outColorB
        else
            r, g, b = inColorR, inColorG, inColorB
        end

        return '<div style="text-align:center;position:absolute;left:' .. utils.round(screenPos[1] * 100)
                .. [[%;top:]] .. utils.round(screenPos[2] * 100) .. [[%;color:rgb(]] .. r .. [[,]]
                .. g .. [[,]] .. b
                .. [[);margin-left:-500px;width:1000px;"><div style="width:fit-content;padding:5px;margin:auto;border:2px solid black;border-radius:10px;background-color:rgba(100,100,100,.5);">]]
                .. container.itemName .. [[<br>]]
                .. container.percent .. [[%</div></div>]]
    end

    local showHud = true
    local hudHtml = ''
    local function updateHud()
        if showHud then
            local containers = containers
            if not containers then
                return
            end

            local html = ''
            local outputItemId = outputItemId
            if outputItemId then
                local outputContainers = containers[outputItemId]
                if outputContainers then
                    for _, container in ipairs(outputContainers) do
                        html = html .. highlightContainer(container, true)
                    end
                end
            end

            local ingredientItemIds = ingredientItemIds
            if ingredientItemIds then
                for _, ingredientItemId in ipairs(ingredientItemIds) do
                    local ingredientContainers = containers[ingredientItemId]
                    if ingredientContainers then
                        for _, container in ipairs(ingredientContainers) do
                            html = html .. highlightContainer(container, false)
                        end
                    end
                end
            end

            hudHtml = html
        end
    end

    self.hasHud = true
    ---@return string
    function self.drawHud()
        if showHud then
            return hudHtml
        else
            return ''
        end
    end

    local function onStartOption3()
        showHud = not showHud
    end

    ---@param state State
    function self.start(state)
        state.registerTimer('RecipeContainerHighlighter_updateUi', 0.1, updateHud)
        state.registerCoroutine(self, 'RecipeContainerHighlighter_init', refreshContainers, true)
        state.registerHandler(system, SYSTEM_EVENTS.ACTION_START, DuLuacUtils.createHandler({
            [LUA_ACTIONS.OPTION3] = onStartOption3
        }))
    end

    return setmetatable(self, RecipeContainerHighlighter)
end