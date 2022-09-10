require('IndustryHudControl/IndustryHudControl')

---@type string
channelPrefix = "changeMe" --export: no underscore

---@type ManualSwitch
switch = switch
---@type Receiver
receiverControl = receiverControl
industry1, industry2, industry3, industry4, industry5, industry6, industry7, industry8 = industry1, industry2, industry3, industry4, industry5, industry6, industry7, industry8
local industries = --[[---@type Industry[] ]] {industry1, industry2, industry3, industry4, industry5, industry6, industry7, industry8}

IndustryHudControl.start(channelPrefix, switch, receiverControl, industries, unit, system)