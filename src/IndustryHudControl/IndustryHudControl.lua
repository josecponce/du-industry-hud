---@class IndustryHudControl
IndustryHudControl = {}
IndustryHudControl.__index = IndustryHudControl

local INIT_DONE = 'initDone_'

---@param channelPrefix string no underscore
---@param switch ManualSwitch
---@param receiverControl Receiver
---@param industries Industry[]
---@param unit ControlUnit
---@param system System
function IndustryHudControl.start(channelPrefix, switch, receiverControl, industries, unit, system)
    local initDoneChannel = INIT_DONE .. channelPrefix .. '_' .. #industries
    local controlChannel = channelPrefix .. '_Control'

    ---@overload fun(): void
    local function complete(errorMessage)
        if errorMessage then
            system.print(errorMessage)
            error(errorMessage)
        end
        switch.deactivate()
        unit.exit()
    end

    local function initAndValidate()
        local controlChannels = receiverControl.getChannelList()
        if controlChannels and #controlChannels == 2 then
            local lastInitDoneChannel = controlChannels[1]

            if lastInitDoneChannel == initDoneChannel then
                return
            end
        end

        --init not done yet
        local factoryPrefixPattern = '^' .. channelPrefix .. '_'
        for _, industry in ipairs(industries) do
            local name = industry.getName()
            if not name:find(factoryPrefixPattern) then
                complete("Factory name doesn't start with valid prefix. Name '" .. name ..
                        "', expected prefix '" .. channelPrefix .. "_'.")
            end
        end

        local controlChannels = { initDoneChannel, controlChannel }
        if not receiverControl.setChannelList(controlChannels) == 1 then
            complete('Failed to setup control channels.')
        end

        system.print('Config validation done.')
    end

    ---@type table<string, fun(ind: Industry) | fun(ind: Industry, param: string)>
    local commands = {
        --run
        ['R'] = function(industry)
            industry.startRun()
        end,
        --batch
        ['B'] = function(industry, batches)
            industry.batchStart(tonumber(batches))
        end,
        --maintain
        ['M'] = function(industry, quantity)
            industry.startMaintain(tonumber(quantity))
        end,
        ['S'] = function(industry, force)
            force = force or 'false'
            industry.stop(force:lower() == "true", false)
        end
    }

    ---@return string[]
    local function strSplit(s, delimiter)
        local result = {};
        for match in (s..delimiter):gmatch("(.-)"..delimiter) do
            table.insert(result, match);
        end
        return result;
    end

    ---@type table<number, Industry>
    local industryIds = {}
    ---@param channel string
    ---@param message string command_id_param
    local function executeCommand(_, channel, message)
        if channel == controlChannel then
            local commandParts = strSplit(message, '_')
            local command = commands[commandParts[1]:upper()]
            if command then
                local id = tonumber(commandParts[2])
                if id then
                    command(industryIds[id], commandParts[3])
                end
            end
        end
        complete()
    end

    local TIMEOUT_TIMER = 'timeout'
    local function timeoutShutdown(_, timer)
        if timer == TIMEOUT_TIMER then
            complete()
        end
    end

    initAndValidate()

    for _, industry in ipairs(industries) do
        industryIds[industry.getLocalId()] = industry
    end

    receiverControl:onEvent('onReceived', executeCommand)
    unit:onEvent('onTimer', timeoutShutdown)
    unit.setTimer(TIMEOUT_TIMER, 1)
end