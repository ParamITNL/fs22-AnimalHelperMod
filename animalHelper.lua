--[[ 
    Animal Helper 22
    Author:     ParamIT
    Version:    22
    ToDo:
      - Use food/straw from storage when available
      - Cleanup Code
      - Make filling straw configurable
      - Save/Load configuration 
      - Don't run while sleeping, or at least, don't generate the messages
]] 
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
        ["FALLBACK"] = function(husbandry, farmId)
            printdbg("Hired running fallback method helper...");
            return AnimalHelper:doForHusbandry(husbandry, farmId);
        end
    },
    enabled = false,
    isDebug = true,
    modName = g_currentModName,
}

function AnimalHelper:loadMap(name)
    g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.hourChanged, self);
    Player.registerActionEvents = Utils.appendedFunction(Player.registerActionEvents, self.registerActionEventsPlayer);
end;

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
        -- TODO: Add action to disable helper...
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

function AnimalHelper:hourChanged()
    printdbg("Checking if helper is enabled...");
    if (AnimalHelper.enabled == true and (g_currentMission.environment.currentHour == 9 or AnimalHelper.isDebug == true)) then
        AnimalHelper:runHelpers();
    end
end;

-- Add a consolecommand to manually run the helpers if AnimalHelper:isDebug is true:
if(AnimalHelper.isDebug) then addConsoleCommand("ahRunHelpers", "Hire animal helpers now", "runHelpers", AnimalHelper) end
---Run the hired helpers for all husbandries
function AnimalHelper:runHelpers() 
    g_currentMission.hud:addSideNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format("%s", g_i18n.modEnvironments[AnimalHelper.modName].texts.ANIMAL_HELPER_STARTED))
    for _,clusterHusbandry in pairs(g_currentMission.husbandrySystem.clusterHusbandries) do

        -- Get Helper for Current Husbandry:
        local helper = Utils.getNoNil(AnimalHelper.helpers[clusterHusbandry.animalTypeName], AnimalHelper.helpers.FALLBACK);

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
    -- ToDo: Don't notify when sleeping!
    g_currentMission.hud:addSideNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format("%s", g_i18n.modEnvironments[AnimalHelper.modName].texts.ANIMAL_HELPER_DONE))
end;

---Default Husbandry Helper
---@param clusterHusbandry AnimalClusterHusbandry The husbandry to run the helper for
---@param farmId any The farmId of the player
---@return integer costs The costs calculated for the daily upkeep of the animals
function AnimalHelper:doForHusbandry(clusterHusbandry, farmId)
    local currentCosts = 0
    printdbg("Fallback helper for husbandry " .. clusterHusbandry.animalTypeName);

    if (clusterHusbandry ~= nil) then
        currentCosts = currentCosts + AnimalHelper:doFeed(clusterHusbandry, farmId)
        currentCosts = currentCosts + AnimalHelper:giveWater(clusterHusbandry, farmId)
        -- TODO: Do we always want to top up straw? You won't be able to produce slurry then.
        currentCosts = currentCosts + AnimalHelper:giveStraw(clusterHusbandry, farmId)
    end

    return currentCosts;
end;

---Fill husbandry water level
---@param clusterHusbandry AnimalClusterHusbandry The husbandry to fill the water levels for
---@param farmId any The players farmId
---@return integer costs The costs calculated for the water. For now, water is free.
function AnimalHelper:giveWater(clusterHusbandry, farmId) 
    local freeCapacity = clusterHusbandry.placeable:getHusbandryFreeCapacity(FillType.WATER)
    printdbg("Free capacity for water = %d l", freeCapacity)

    if (freeCapacity ~= nil and freeCapacity > 0) then
        clusterHusbandry.placeable:addHusbandryFillLevelFromTool(farmId, freeCapacity, FillType.WATER, nil)
    end

    -- Water is free (for now)
    return 0
end

---Fill husbandry Straw level
---@param clusterHusbandry AnimalClusterHusbandry The husbandry to fill the straw levels for
---@param farmId any The players farmId
---@return integer costs The costs calculated for the straw.
function AnimalHelper:giveStraw(clusterHusbandry, farmId) 
    local freeCapacity = clusterHusbandry.placeable:getHusbandryFreeCapacity(FillType.STRAW)
    local strawCosts = 0

    local pricePerLiter = g_currentMission.economyManager:getPricePerLiter(FillType.STRAW)
    local applied = clusterHusbandry.placeable:addHusbandryFillLevelFromTool(farmId, freeCapacity, FillType.STRAW, nil)
    strawCosts = applied * pricePerLiter
    printdbg("%d l of straw added for € %d (%d / lt)", applied, strawCosts, pricePerLiter)

    return strawCosts
end

---Feed the animals
---@param clusterHusbandry AnimalClusterHusbandry The husbandry to feed.
---@param farmId any The farmId of the players farm
---@return integer costs The costs calculated for the food
---@ToDo: Use food from storage when available.
function AnimalHelper:doFeed(clusterHusbandry, farmId) 
    -- Take care of food:
    local animalTypeIndex = clusterHusbandry.animalSystem:getTypeIndexByName(clusterHusbandry.animalTypeName)
    local animalFood = g_currentMission.animalFoodSystem:getAnimalFood(animalTypeIndex)
    local freeCapacity = nil
    local foodCosts = 0
    
    -- Fill Eacg FoodGroup
    for idx,foodGroup in pairs(animalFood.groups) do
        printdbg("Currently processing foodgroup '%s'", foodGroup.title)
        DebugUtil.printTableRecursively(foodGroup)

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

---Get the fillTypeIndex for the fillType to use for this foodGroup
---@param foodGroup any The foodgroup we are filling
---@return any fillTypeIndex fillTypeIndex we are going to use for this foodgroup.
---@TODO Base chosen fillType on availability in storage, ie which fillType will be the cheapest.
function AnimalHelper:getFillTypeIndexToFill(foodGroup) 
    -- TODO: Choose the cheapest
    -- 1. Available in storage
    -- 2. Cheapest to buy.
    return foodGroup.fillTypes[1]
end;

---Helper method for horse-husbandries
---@param husbandry AnimalClusterHusbandry The husbandry to tend to
---@param farmId any the Players FarmId.
---@return integer costs The costs calculatod for taking care of the horses.
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

---Method that prints (formatted) text only when AnimalHelper.isDebug is true.
---@param str string inputstring
---@param ... string format arguments
function printdbg(str, ...)
    if (AnimalHelper.isDebug == true) then
        print(string.format(str, ...))
    end
end


