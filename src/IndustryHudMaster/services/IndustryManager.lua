require('du_lib/utils/duluac')

local strSplit = require('du_lib/utils/fn_strSplit')

---@class IndustryManager
IndustryManager = {}

---@param emitter Emitter
---@param unit ControlUnit
---@return IndustryManager
function IndustryManager.new(emitter, unit)
    local self = --[[---@type self]]{}

    ---@param industry IndustryHudMachine
    ---@param command string
    function self.executeCommand(industry, command)
        local nameParts = strSplit(industry.name, '_')
        if #nameParts == 1 then
            error("Industry name doesn't contain the control channel prefix.")
        end

        local channelPrefix = nameParts[1]
        local controlChannel = channelPrefix .. '_Control'

        local commandParts = strSplit(command, ' ')
        if #commandParts > 2 then
            error('Invalid command entered: ' .. command)
        end

        local id = tostring(industry.id)
        local actualCommand = commandParts[1] .. '_' .. id
        if #commandParts == 2 then
            actualCommand = actualCommand .. '_' .. commandParts[2]
        end

        local timer = controlChannel .. '_' .. id
        local sentCount = 1
        local timerId
        emitter.send(controlChannel, actualCommand)
        timerId = unit:onEvent('onTimer', DuLuacUtils.createHandler({
            [timer] = function()
                if sentCount == 1 then
                    unit.stopTimer(timer)
                    unit:clearEvent('onTimer', timerId)
                end
                emitter.send(controlChannel, actualCommand)
                sentCount = sentCount + 1
            end
        }))
        unit.setTimer(timer, 0.2)
    end

    return setmetatable(self, IndustryManager)
end