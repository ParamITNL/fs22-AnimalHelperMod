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
}

---loadMap EventHandler
---@tparam string name
function AnimalHelper:loadMap(name)
    AnimalHelper:loadSettings()
    g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.hourChanged, self);
    Player.registerActionEvents = Utils.appendedFunction(Player.registerActionEvents, self.registerActionEventsPlayer);
    FSBaseMission.saveSavegame = Utils.appendedFunction(FSBaseMission.saveSavegame, self.saveSettings);
end;

--- get the filename of the xml settings are saved to/from
-- @treturn string the filename
local function getSaveFileName()
    local xmlFilePath = g_currentMission.missionInfo.savegameDirectory;
	if xmlFilePath == nil then
        xmlFilePath = string.format("%ssavegame%d",
            getUserProfileAppPath(),
            g_currentMission.missionInfo.savegameIndex)
	end;
    xmlFilePath = string.format("%s/%s.xml", xmlFilePath, AnimalHelper.modName)

    return xmlFilePath
end

function AnimalHelper:loadSettings()
    local xmlFilePath = getSaveFileName()

    if fileExists(xmlFilePath) then
        local key = AnimalHelper.modName
        local xmlFile = XMLFile.load(AnimalHelper.modName, xmlFilePath)
        if xmlFile ~= nil then
            AnimalHelper.enabled = xmlFile:getBool(key..".isEnabled", AnimalHelper.enabled)
            AnimalHelper.isDebug = xmlFile:getBool(key..".isDebug", false)
            AnimalHelper.fillStraw = xmlFile:getBool(key..".fillStraw", AnimalHelper.fillStraw)
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
    xmlFile:save();
	xmlFile:delete();
end

function AnimalHelper:registerActionEventsPlayer()
    -- @ToDo Change action text when helpers are enabled.
    printdbg("Registering Actions!");
    local valid, actionEventId, _ = g_inputBinding:registerActionEvent(InputAction.ANIMAL_HELPER_HIRE_HELPER, AnimalHelper,
        AnimalHelper.actionCallbackPlayer, false, true, false, true);

    g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW);
    g_inputBinding:setActionEventTextVisibility(actionEventId, true);
end

function AnimalHelper:actionCallbackPlayer(actionName, keyStatus, arg4, arg5, arg6)
    if actionName == "ANIMAL_HELPER_HIRE_HELPER" then
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
end;

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
-- @tparam AnimalClusterHusbandry clusterHusbandry The husbandry to run the helper for
-- @tparam integer farmId The farmId of the player
-- @treturn integer The costs calculated for the daily upkeep of the animals
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
-- @param farmId The players farmId
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
-- @param clusterHusbandry AnimalClusterHusbandry The husbandry to fill the straw levels for
-- @param farmId any The players farmId
-- @return integer costs The costs calculated for the straw.
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
-- @param clusterHusbandry AnimalClusterHusbandry The husbandry to feed.
-- @param farmId any The farmId of the players farm
-- @return integer costs The costs calculated for the food
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
-- @param foodGroup any The foodgroup we are filling
-- @return fillTypeIndex we are going to use for this foodgroup.
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
-- @param husbandry AnimalClusterHusbandry The husbandry to tend to
-- @param farmId any the Players FarmId.
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
-- @param str string inputstring
-- @param ... string format arguments
function printdbg(str, ...)
    if (AnimalHelper.isDebug == true) then
        print(string.format(str, ...))
    end
end

--[[
    function StoreDeliveries:saveSettings()

	

end;

function StoreDeliveries:loadSettings()

	local savegameFolderPath = g_currentMission.missionInfo.savegameDirectory;
	if savegameFolderPath == nil then
		savegameFolderPath = ('%ssavegame%d'):format(getUserProfileAppPath(), g_currentMission.missionInfo.savegameIndex);
	end;
	savegameFolderPath = savegameFolderPath.."/"
	local key = "storeDeliveries";

	if fileExists(savegameFolderPath.."storeDeliveries.xml") then
		local xmlFile = loadXMLFile(key, savegameFolderPath.."storeDeliveries.xml");
		StoreDeliveries.isLoaded = getXMLBool(xmlFile, key.."#isLoaded");
		if StoreDeliveries.isLoaded then
			local storePlace = g_currentMission.storeSpawnPlaces[1];
			storePlace.startX = getXMLFloat(xmlFile, key..".storeLocation#x");
			storePlace.startY = getXMLFloat(xmlFile, key..".storeLocation#y");
			storePlace.startZ = getXMLFloat(xmlFile, key..".storeLocation#z");
			storePlace.rotX = getXMLFloat(xmlFile, key..".storeRotation#x");
			storePlace.rotY = getXMLFloat(xmlFile, key..".storeRotation#y");
			storePlace.rotZ = getXMLFloat(xmlFile, key..".storeRotation#z");
			storePlace.dirX = getXMLFloat(xmlFile, key..".storeDirection#x");
			storePlace.dirY = getXMLFloat(xmlFile, key..".storeDirection#y");
			storePlace.dirZ = getXMLFloat(xmlFile, key..".storeDirection#z");
			storePlace.dirPerpX = getXMLFloat(xmlFile, key..".storePerpDirection#x");
			storePlace.dirPerpY = getXMLFloat(xmlFile, key..".storePerpDirection#y");
			storePlace.dirPerpZ = getXMLFloat(xmlFile, key..".storePerpDirection#z");
			storePlace.teleportX = getXMLFloat(xmlFile, key..".storeTeleportLocation#x");
			storePlace.teleportY = getXMLFloat(xmlFile, key..".storeTeleportLocation#y");
			storePlace.teleportZ = getXMLFloat(xmlFile, key..".storeTeleportLocation#z");
		end;
		delete(xmlFile);
	end;

	return StoreDeliveries.isLoaded;

end;
]]

