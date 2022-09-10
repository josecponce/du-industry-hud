local secondsToClockString = require('du_lib/utils/fn_secondsToClockString')

---@class IndustryHudMachine
---@field id number
---@field type string
---@field typeWithSize string
---@field tier number
---@field size string
---@field itemId number
---@field name string
---@field status string
---@field productId number
---@field productName string
---@field productType string
---@field unitsProduced number
---@field remainingTime number
---@field remainingTimeString string
---@field mode string
---@field batchesRequested number
---@field maintainProductAmount number
IndustryHudMachine = {}
IndustryHudMachine.__index = IndustryHudMachine

local STATUS_LIST = { "STOPPED", "RUNNING", "MISSING INGREDIENT", "OUTPUT FULL", "NO OUTPUT CONTAINER", "PENDING", "MISSING SCHEMATIC" }

---@param core CoreUnit
---@param id number
---@return boolean
function IndustryHudMachine.isIndustry(core, id)
    local elementType = core.getElementDisplayNameById(id):lower()
    return --[[---@type boolean]] elementType:find("assembly line") or
            elementType:find("glass furnace") or
            elementType:find("3d printer") or
            elementType:find("smelter") or
            elementType:find("recycler") or
            elementType:find("refinery") or
            elementType:find("refiner") or
            elementType:find("industry")
                    and (
                    elementType:find("chemical") or
                            elementType:find("electronics") or
                            elementType:find("metalwork")
            ) or
            elementType == "transfer unit"
end

---@param system System
---@param core CoreUnit
---@param id number
---@return IndustryHudMachine
function IndustryHudMachine.new(system, core, id)
    local self = --[[---@type self]] { }

    local itemId = core.getElementItemIdById(id)
    local item = system.getItem(itemId)

    self.id = id
    self.type = item.displayName --e.g. "Basic Assembly Line" without size
    self.typeWithSize = item.displayNameWithSize
    self.tier = item.tier
    self.size = item.size
    self.itemId = item.id

    function self.refresh()
        self.name = core.getElementNameById(id)

        local status = core.getElementIndustryInfoById(self.id)

        local productId = -1
        local productName = "-"
        local productType = '-'
        if #status.currentProducts > 0 then
            productId = status.currentProducts[1].id
            local item = system.getItem(productId)
            if item.locDisplayNameWithSize then
                productName = item.locDisplayNameWithSize
                productType = item.displayName
            end
        end

        self.productId = productId
        self.productName = productName
        self.productType = productType

        local remainingTime = 0
        if (status) and (status.remainingTime) and (status.remainingTime <= (3600 * 24 * 365)) then
            remainingTime = status.remainingTime
        end
        self.remainingTime = remainingTime
        self.remainingTimeString = secondsToClockString(remainingTime)

        self.status = STATUS_LIST[status.state] or '-'
        self.unitsProduced = status.unitsProduced or 0

        local mode = "-"
        self.maintainProductAmount = status.maintainProductAmount
        self.batchesRequested = status.batchesRequested
        if status.maintainProductAmount > 0 then
            mode = "Maintain " .. math.floor(status.maintainProductAmount)
        elseif status.batchesRequested > 0 and status.batchesRequested <= 99999999 then
            mode = "Produce " .. math.floor(status.batchesRequested)
        end
        self.mode = mode
    end

    return setmetatable(self, IndustryHudMachine)
end