require('du_lib/requires/service')
require('du_lib/requires/dataHud')
require('du_lib/markers/MarkerManager')

require('IndustryHudMaster/services/RecipeContainerHighlighter')
require('IndustryHudMaster/services/IndustryManager')
require('IndustryHudMaster/services/IndustryHud')


local workPerTick = 1000 --export: coroutine amount of work done per tick
local workTickInterval = 0.1 --export: coroutine interval between ticks
local contentFontSize = 15 --export: size of the font of the content of all panels in pixels
local elementsByPage = 20 --export: maximum amount of elements displayed on a single page
local groupsByPage = 10 --export: maximum amount of groups displayed per page

--need to convert this to use the talent level db
local containerProficiencyLvl = 0 --export: talent level
local containerOptimizationLvl = 0 --export: talent level


emitter = emitter


local markerManager = MarkerManager.new(core, unit)
local recipeContainerHighlighter = RecipeContainerHighlighter.new(system, core, containerProficiencyLvl, containerOptimizationLvl)
local industryManager = IndustryManager.new(emitter, unit)
local hud = FullDataHud.new(system, contentFontSize, elementsByPage, groupsByPage)
local industryHud = IndustryHud.new(system, core, hud, markerManager, recipeContainerHighlighter, industryManager)

local services = { industryHud, hud, markerManager, recipeContainerHighlighter }

State.new(services, unit, system, workPerTick, workTickInterval).start()