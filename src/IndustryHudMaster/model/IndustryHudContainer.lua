local strSplit = require('du_lib/utils/fn_strSplit')

---@class IndustryHudContainer
IndustryHudContainer = {}
IndustryHudContainer.__index = IndustryHudContainer

---@type table<string, number>
local CONTAINER_VOLUME_LIST = { xxl = 512000, xl = 256000, l = 128000, m = 64000, s = 8000, xs = 1000 }

---@param core CoreUnit
---@param id number
---@return boolean
function IndustryHudContainer.isContainer(core, id)
    local elementType = core.getElementDisplayNameById(id):lower()
    return --[[---@type boolean]] elementType:lower():find("container")
end

---@param core CoreUnit
---@param containerProficiencyLvl number
---@param containerOptimizationLvl number
---@return IndustryHudContainer
function IndustryHudContainer.new(core, id, containerProficiencyLvl, containerOptimizationLvl)
    local self = --[[---@type self]] { }

    self.id = id

    function self.refresh()
        local type = core.getElementDisplayNameById(id)
        self.type = type
        local name = core.getElementNameById(id)
        self.name = name

        local splitName = strSplit(name, '_')
        if #splitName == 1 then
            return
        end

        local itemId = tonumber(splitName[2])

        local containerSize = "XS"
        local containerAmount = 1
        local containerEmptyMass = 0
        local containerVolume = 0

        if not type:lower():find("hub") then
            local containerMaxHP = core.getElementMaxHitPointsById(itemId)
            if containerMaxHP > 68000 then
                containerSize = "XXL"
                containerEmptyMass = 88410
                containerVolume = 512000 * (containerProficiencyLvl * 0.1) + 512000
            elseif containerMaxHP > 33000 then
                containerSize = "XL"
                containerEmptyMass = 44210
                containerVolume = 256000 * (containerProficiencyLvl * 0.1) + 256000
            elseif containerMaxHP > 17000 then
                containerSize = "L"
                containerEmptyMass = 14842.7
                containerVolume = 128000 * (containerProficiencyLvl * 0.1) + 128000
            elseif containerMaxHP > 7900 then
                containerSize = "M"
                containerEmptyMass = 7421.35
                containerVolume = 64000 * (containerProficiencyLvl * 0.1) + 64000
            elseif containerMaxHP > 900 then
                containerSize = "S"
                containerEmptyMass = 1281.31
                containerVolume = 8000 * (containerProficiencyLvl * 0.1) + 8000
            else
                containerSize = "XS"
                containerEmptyMass = 229.09
                containerVolume = 1000 * (containerProficiencyLvl * 0.1) + 1000
            end
        else
            if splitName[3] then
                containerSize = splitName[3]
            end
            if splitName[4] then
                containerAmount = tonumber(splitName[4])
            end

            local volume = 0
            containerSize = containerSize:lower()
            if CONTAINER_VOLUME_LIST[containerSize] then
                volume = CONTAINER_VOLUME_LIST[containerSize]
            end
            containerVolume = (volume * containerProficiencyLvl * 0.1 + volume) * tonumber(containerAmount)
            containerEmptyMass = 55.8
        end

        local item = system.getItem(itemId)
        local totalMass = core.getElementMassById(id)
        local contentMassKg = totalMass - containerEmptyMass

        self.itemId = itemId
        self.itemName = item.displayNameWithSize
        self.quantity = contentMassKg / (item.unitMass - (item.unitMass * (containerOptimizationLvl * 0.05)))
        self.volume = containerVolume
        self.percent = utils.round((item.unitVolume * self.quantity) * 100 / containerVolume)

        if item.name == "InvalidItem" then
            self.percent = 0
            self.quantity = 0
        end
        if self.percent > 100 then
            self.percent = 100
        end
    end

    return setmetatable(self, IndustryHudContainer)
end