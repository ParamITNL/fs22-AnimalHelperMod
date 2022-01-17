--[[ 
    Animal Helper 22
    Author:     ParamIT
    Version:    22
    ToDo:
      - Use food/straw from storage when available
      - Cleanup Code
      - Make filling straw configurable (Done)
        - Add action or GUI to enable/disable filling of straw
]]

--- AnimalHelper module
-- @module AnimalHelper
-- @author ParamIT_NL
-- @copyright © 2022, ParamIT
-- @license MIT
if (AnimalHelper ~= nil) then
    printdbg("AnimalHelper already exists, unregistering...");
    g_currentMission.hud:addSideNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format("%s", g_i18n.modEnvironments[AnimalHelper.modName].texts.ANIMAL_HELPER_UNREGISTERED))
    AnimalHelper:removeModEventListener(AnimalHelper);
end

AnimalHelper = {
    helpers = {
        ["HORSE"] = function(husbandry, farmId)
            return AnimalHelper:doForHorseHusbandry(husbandry, farmId);
        end,
        ["DEFAULT"] = function(husbandry, farmId)
            printdbg("running default helper...");
            return AnimalHelper:doForHusbandry(husbandry, farmId);
        end
    },
    enabled = false,
    isDebug = true,
    fillStraw = true,
    modName = g_currentModName,
    modDir = g_currentModDirectory,
    startHour = 9
}

---loadMap EventHandler
---@param name string
function AnimalHelper:loadMap(name)
    AnimalHelper:loadSettings()
    g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.hourChanged, self);
    Player.registerActionEvents = Utils.appendedFunction(Player.registerActionEvents, self.registerActionEventsPlayer);
    FSBaseMission.saveSavegame = Utils.appendedFunction(FSBaseMission.saveSavegame, self.saveSettings);

    local origTextElementLoadFromXml = TextElement.loadFromXML
    local origGuiElementLoadFromXml = GuiElement.loadFromXML

    local function loadElement(element, xmlFile, key)
        if xmlFile == nil then print("Error: XmlFile is nil!") end
        if element == nil then print ("Error: element is nil") end
        if key == nil then print ("Error: key is nil") end
        
        local id = Utils.getNoNil(getXMLString(xmlFile, key .. "#i18nId"), "")

        if id ~= "" and g_i18n:hasModText(id) and type(element.setText) == "function" then
            local text = g_i18n.modEnvironments[AnimalHelper.modName].texts[id]
            element:setText(text)
            printdbg("Text for %s set to: %s", id, text)
        elseif id ~= "" and not g_i18n:hasModText(id) then
            print("Warning: id '" .. id .. "' has no translations!")
        end
    end

    TextElement.loadFromXML = Utils.appendedFunction(origTextElementLoadFromXml, function(self, xmlFile, key)
        printdbg("See if we can localize...")
        local _,_ pcall(loadElement, self, xmlFile, key)
    end)
    GuiElement.loadFromXML = Utils.appendedFunction(origGuiElementLoadFromXml, function(self, xmlFile, key)
        local _,_ pcall(loadElement, self, xmlFile, key)
    end)

    local function loadAnimalHelperMenu()
        g_gui:loadProfiles(Utils.getFilename("gui/guiProfiles.xml", AnimalHelper.modDir))
        AnimalHelperSettingsDialog = AnimalHelperSettingsDialog.new()
        g_gui:loadGui(Utils.getFilename("gui/AnimalHelperSettingsDialog.xml", AnimalHelper.modDir), "AnimalHelperSettingsDialog", AnimalHelperSettingsDialog)
    end

    local state, result = pcall( loadAnimalHelperMenu )
    if not ( state ) then 
        print("Error: Error loading AnimalHelper UI: "..tostring(result))
    else
        print("Loaded AnimalHelperUI successfully")
    end

    TextElement.loadFromXML = origTextElementLoadFromXml
    GuiElement.loadFromXML = origGuiElementLoadFromXml
end;

---Get the filename for the settings xml file
---@return string filename The requested filename
local function getSaveFileName()
    local xmlFilePath = g_currentMission.missionInfo.savegameDirectory;
	if xmlFilePath == nil then
        xmlFilePath = string.format("%ssavegame%d",
            getUserProfileAppPath(),
            g_currentMission.missionInfo.savegameIndex)
	end;
    xmlFilePath = string.format("%s/%s.xml", xmlFilePath, "animalHelper")

    return xmlFilePath
end

---Load the settings from animalHelper.xml
function AnimalHelper:loadSettings()
    local xmlFilePath = getSaveFileName()

    if fileExists(xmlFilePath) then
        local key = AnimalHelper.modName
        local xmlFile = XMLFile.load(AnimalHelper.modName, xmlFilePath)
        if xmlFile ~= nil then
            AnimalHelper.enabled = xmlFile:getBool(key..".isEnabled", AnimalHelper.enabled)
            AnimalHelper.isDebug = xmlFile:getBool(key..".isDebug", false)
            AnimalHelper.fillStraw = xmlFile:getBool(key..".fillStraw", AnimalHelper.fillStraw)
            AnimalHelper.startHour = xmlFile:getInt(key .. ".startHour", AnimalHelper.startHour)
        end
    end
end

--- Save the current settings when saving the game.
function AnimalHelper:saveSettings()
    print("Saving AnimalHelper settings")
    local xmlFilePath = getSaveFileName()
    local key = AnimalHelper.modName
    local xmlFile = XMLFile.create(key, xmlFilePath, key)
    xmlFile:setBool(key..".isEnabled", AnimalHelper.enabled)
    xmlFile:setBool(key..".isDebug", AnimalHelper.isDebug)
    xmlFile:setBool(key..".fillStraw", AnimalHelper.fillStraw)
    xmlFile:setInt(key .. ".startHour", AnimalHelper.startHour)
    xmlFile:save();
	xmlFile:delete();
end

---Extension on the Player.registerActionEvents function
function AnimalHelper:registerActionEventsPlayer()
    -- @ToDo Change action text when helpers are enabled.
    printdbg("Registering Actions!");
    local _, hireActionEventId, _ = g_inputBinding:registerActionEvent(InputAction.ANIMAL_HELPER_HIRE_HELPER, AnimalHelper, AnimalHelper.animalHelperHireCallback, false, true, false, true)
    g_inputBinding:setActionEventTextPriority(hireActionEventId, GS_PRIO_VERY_LOW);
    g_inputBinding:setActionEventTextVisibility(hireActionEventId, true);

    local _, optionsEventId, _ = g_inputBinding:registerActionEvent(InputAction.ANIMAL_HELPER_OPTIONS, AnimalHelper, AnimalHelper.animalHelperOptionsCallback, false, true, false, true)
    g_inputBinding:setActionEventTextPriority(optionsEventId, GS_PRIO_VERY_LOW)
    g_inputBinding:setActionEventTextVisibility(optionsEventId, true)
end

function AnimalHelper:animalHelperOptionsCallback()
        printdbg("Using the new UI...")
        g_gui:showDialog( "AnimalHelperSettingsDialog", true)
end

---ANIMAL_HELPER_HIRE_HELPER action callback
function AnimalHelper:animalHelperHireCallback()
    printdbg("Hire Helper Action")
        -- @ToDo: Add action to disable helper, or change text in help-menu
        AnimalHelper.enabled = AnimalHelper.enabled ~= true;
        local message
        if (AnimalHelper.enabled) then
            message = g_i18n.modEnvironments[AnimalHelper.modName].texts.ANIMAL_HELPER_ENABLED
        else
            message = g_i18n.modEnvironments[AnimalHelper.modName].texts.ANIMAL_HELPER_DISABLED
        end

        g_currentMission.hud:addSideNotification(FSBaseMission.INGAME_NOTIFICATION_OK, message, nil, GuiSoundPlayer.SOUND_SAMPLES.TRANSACTION )
end

function AnimalHelper:toggleStraw() 
    AnimalHelper.fillStraw = not AnimalHelper.fillStraw;
end

function AnimalHelper:changeWorkStartTime() 
end

---Translates boolean to "on"/"off" string representation
---@param b boolean Boolean value to convert
---@return string str The converted string
function AnimalHelper:BooleanToString(b)
    if (b == true) then
        return g_i18n:getText("ANIMAL_HELPER_ON_TEXT")
    else
        return g_i18n:getText("ANIMAL_HELPER_OFF_TEXT")
    end
end

--- hourChanged event handler.
-- Handles the hourChanged event. If the time is correct and helpers is enabled, the runHelpers method will be invoked.
-- @see AnimalHelper:runHelpers
function AnimalHelper:hourChanged()
    printdbg("Checking if helper is enabled...");
    local isTime = g_currentMission.environment.currentHour == 9 or AnimalHelper.isDebug
    local isSleeping = g_sleepManager:getIsSleeping()
    if (AnimalHelper.enabled and isTime and not isSleeping) then
        AnimalHelper:runHelpers();
    end
end;

-- Add a consolecommand to manually run the helpers if AnimalHelper:isDebug is true:
if(AnimalHelper.isDebug) then addConsoleCommand("ahRunHelpers", "Hire animal helpers now", "runHelpers", AnimalHelper) end

--- Run the hired helpers for all husbandries.
function AnimalHelper:runHelpers() 
    g_currentMission.hud:addSideNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format("%s", g_i18n.modEnvironments[AnimalHelper.modName].texts.ANIMAL_HELPER_STARTED))
    for _,clusterHusbandry in pairs(g_currentMission.husbandrySystem.clusterHusbandries) do

        -- Get Helper for Current Husbandry:
        local helper = Utils.getNoNil(AnimalHelper.helpers[clusterHusbandry.animalTypeName], AnimalHelper.helpers.DEFAULT);

        -- If we have a helper, run it. We should have one, because we should fallback to the default helper.
        if (helper ~= nil) then
            local farmId = g_currentMission.player.farmId;
            local costs = helper(clusterHusbandry, farmId);

            -- If helper reported costs, deduct them from the bank-account
            if (costs ~= nil) then
                g_currentMission:addMoney(-costs, farmId, MoneyType.ANIMAL_UPKEEP, true, true)
            end
        end
    end

    -- Notify the player that the helpers are done.
    -- @ToDo: Don't notify when sleeping!
    g_currentMission.hud:addSideNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format("%s", g_i18n.modEnvironments[AnimalHelper.modName].texts.ANIMAL_HELPER_DONE))
end;

--- Default Husbandry Helper.
--- @tparam AnimalClusterHusbandry clusterHusbandry  The husbandry to run the helper for
--- @tparam integer farmId The farmId of the player
--- @treturn integer The costs calculated for the daily upkeep of the animals
function AnimalHelper:doForHusbandry(clusterHusbandry, farmId)
    local currentCosts = 0
    printdbg("Default helper for husbandry " .. clusterHusbandry.animalTypeName);

    if (clusterHusbandry ~= nil) then
        currentCosts = currentCosts + AnimalHelper:doFeed(clusterHusbandry, farmId)
        currentCosts = currentCosts + AnimalHelper:giveWater(clusterHusbandry, farmId)

        if (AnimalHelper.giveStraw) then
            currentCosts = currentCosts + AnimalHelper:giveStraw(clusterHusbandry, farmId)
        end
    end

    return currentCosts;
end;

--- Fill husbandry water level
-- @tparam AnimalClusterHusbandry clusterHusbandry The husbandry to fill the water levels for
-- @tparam integer farmId The players farmId
-- @treturn integer The costs calculated for the water. For now, water is free.
function AnimalHelper:giveWater(clusterHusbandry, farmId) 
    local freeCapacity = clusterHusbandry.placeable:getHusbandryFreeCapacity(FillType.WATER)
    printdbg("Free capacity for water = %d l", freeCapacity)

    if (freeCapacity ~= nil and freeCapacity > 0) then
        clusterHusbandry.placeable:addHusbandryFillLevelFromTool(farmId, freeCapacity, FillType.WATER, nil)
    end

    -- Water is free (for now)
    return 0
end

--- Fill husbandry Straw level
-- @tparam AnimalClusterHusbandry clusterHusbandry The husbandry to fill the straw levels for
-- @tparam integer farmId The players farmId
-- @treturn integer The costs calculated for the straw.
function AnimalHelper:giveStraw(clusterHusbandry, farmId) 
    local freeCapacity = clusterHusbandry.placeable:getHusbandryFreeCapacity(FillType.STRAW)
    local strawCosts = 0

    local pricePerLiter = g_currentMission.economyManager:getPricePerLiter(FillType.STRAW)
    local applied = clusterHusbandry.placeable:addHusbandryFillLevelFromTool(farmId, freeCapacity, FillType.STRAW, nil)
    strawCosts = applied * pricePerLiter
    printdbg("%d l of straw added for € %d (%d / lt)", applied, strawCosts, pricePerLiter)

    return strawCosts
end

--- Feed the animals
-- @tparam AnimalClusterHusbandry clusterHusbandry The husbandry to feed.
-- @tparam integer farmId The farmId of the players farm
-- @treturn integer The costs calculated for the food
function AnimalHelper:doFeed(clusterHusbandry, farmId) 
    -- @ToDo: Use food from storage when available.
    -- Take care of food:
    local animalTypeIndex = clusterHusbandry.animalSystem:getTypeIndexByName(clusterHusbandry.animalTypeName)
    local animalFood = g_currentMission.animalFoodSystem:getAnimalFood(animalTypeIndex)
    local freeCapacity = nil
    local foodCosts = 0
    
    -- Fill Each FoodGroup
    for idx,foodGroup in pairs(animalFood.groups) do
        local fillTypeIndex = AnimalHelper:getFillTypeIndexToFill(foodGroup)
        freeCapacity = freeCapacity or clusterHusbandry.placeable:getFreeFoodCapacity(fillTypeIndex)

        -- Using EatWeight, so all groups getting emptied equally
        local fillAmount = freeCapacity * foodGroup.eatWeight
        local pricePerLiter = g_currentMission.economyManager:getPricePerLiter(fillTypeIndex)
        local priceForFood = fillAmount * pricePerLiter

        clusterHusbandry.placeable:addFood(farmId, fillAmount, fillTypeIndex, nil)

        printdbg(string.format("Costs for %s  (of %s) liter of fillType '%s' are %s", fillAmount, freeCapacity, fillTypeIndex, priceForFood))
        foodCosts = foodCosts + priceForFood

        printdbg(string.format("FoodGroup %s done.", idx))
    end

    return foodCosts
end

--- Get the fillTypeIndex for the fillType to use for this foodGroup
-- @tparam any foodGroup The foodgroup we are filling
-- @treturn integer fillTypeIndex we are going to use for this foodgroup.
function AnimalHelper:getFillTypeIndexToFill(foodGroup) 
    local storedFillType = {
        fillTypeIndex = 0,
        amount = 0,
        storageId = nil
    };

    local storedFillTypes = {};

    for idx,fillType in pairs(foodGroup.fillTypes) do
        printdbg("Checking Storages for available fillTypes:")
        for stIdx, storage in ipairs(g_currentMission.storageSystem.storages) do
            local fillLevelInStorage = storage.fillLevels[fillType];
            printdbg("fillLevel for fillType %s is %d", fillType, fillLevelInStorage)
        end
    end

    -- @ToDo: Base chosen fillType on availability in storage, ie which fillType will be the cheapest.
    -- @Todo: Choose the cheapest


    -- 1. Available in storage
    -- 2. Cheapest to buy.
    return foodGroup.fillTypes[1]
end;

--- Helper method for horse-husbandries
-- @tparam AnimalClusterHusbandry husbandry The husbandry to tend to
-- @tparam integer farmId the Players FarmId.
-- @return integer costs The costs calculatod for taking care of the horses.
function AnimalHelper:doForHorseHusbandry(husbandry, farmId)
    local currentCosts = self:doForHusbandry(husbandry, farmId)

    for _, horse in pairs(husbandry.animalIdToCluster) do
        -- Ride and clean the horses.
        local currentRiding = horse.riding
        local currentFitness = horse.fitness
        horse.riding = 100
        horse.fitness = 100
        horse.dirt = 0

        currentCosts = currentCosts + (100 - currentRiding) * 10.0
        currentCosts = currentCosts + ((100 - currentFitness) * 10.0)
    end;
    return currentCosts;
end;

-- Register AnimalHelper as an EventListener
addModEventListener(AnimalHelper);

--- Method that prints (formatted) text only when AnimalHelper.isDebug is true.
-- @tparam string str inputstring
-- @tparam any ... string format arguments
function printdbg(str, ...)
    if (AnimalHelper.isDebug == true) then
        print(string.format(str, ...))
    end
end
