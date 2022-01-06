--[[ 
    Animal Helper 22
    Author:     ParamIT
    Version:    22
    ToDo:
      - Use food/straw from storage when available
      - Cleanup Code
      - Make filling straw configurable
      - Save/Load configuration 
]] 
if (AnimalHelper ~= nil) then
    print("AnimalHelper already exists, unregistering...");
    g_currentMission.hud:addSideNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format("%s", g_i18n.modEnvironments[AnimalHelper.modName].texts.ANIMAL_HELPER_UNREGISTERED))
    AnimalHelper:removeModEventListener(AnimalHelper);
end

AnimalHelper = {
    helpers = {
        ["HORSE"] = function(husbandry, farmId)
            return AnimalHelper:doForHorseHusbandry(husbandry, farmId);
        end,
        ["FALLBACK"] = function(husbandry, farmId)
            printd("Hired running fallback method helper...");
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
    printd("Registering Actions!");
    local valid, actionEventId, _ = g_inputBinding:registerActionEvent(InputAction.ANIMAL_HELPER_HIRE_HELPER, AnimalHelper,
        AnimalHelper.actionCallbackPlayer, false, true, false, true);

    g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW);
    g_inputBinding:setActionEventTextVisibility(actionEventId, true);
end

function AnimalHelper:actionCallbackPlayer(actionName, keyStatus, arg4, arg5, arg6)
    if actionName == "ANIMAL_HELPER_HIRE_HELPER" then
        printd("Enable AnimalHelper");
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
    printd("Checking if helper is enabled...");
    if (AnimalHelper.enabled == true and (g_currentMission.environment.currentHour == 9 or AnimalHelper.isDebug == true)) then
        AnimalHelper:runHelpers();
    end
end;

if(AnimalHelper.isDebug) then
    addConsoleCommand("ahRunHelpers", "Hire animal helpers now", "runHelpers", AnimalHelper)
end

function AnimalHelper:runHelpers() 
    g_currentMission.hud:addSideNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format("%s", g_i18n.modEnvironments[AnimalHelper.modName].texts.ANIMAL_HELPER_STARTED))
    for _,clusterHusbandry in pairs(g_currentMission.husbandrySystem.clusterHusbandries) do

        -- Get Helper for Current Husbandry:
        local helper = Utils.getNoNil(AnimalHelper.helpers[clusterHusbandry.animalTypeName], AnimalHelper.helpers.FALLBACK);

        -- If we have a helper, run it. We should have one, because we should fallback to the default helper.
        if (helper ~= nil) then
            local farmId = g_currentMission.player.farmId;
            local costs = helper(clusterHusbandry, farmId);

            if (costs ~= nil) then
                printd(string.format("AnimalHelper for husbandry %s done. Costs were %s", clusterHusbandry.animalTypeName, -costs))
                g_currentMission:addMoney(-costs, farmId, MoneyType.ANIMAL_UPKEEP, true, true)
            else
                print(string.format("WARNING: helper '%s' didn't charge anything!", helper));
            end
        end
    end
    g_currentMission.hud:addSideNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format("%s", g_i18n.modEnvironments[AnimalHelper.modName].texts.ANIMAL_HELPER_DONE))
end;

function AnimalHelper:doForHusbandry(clusterHusbandry, farmId)
    local currentCosts = 0
    printd("Fallback helper for husbandry " .. clusterHusbandry.animalTypeName);

    if (clusterHusbandry ~= nil) then
        currentCosts = currentCosts + AnimalHelper:doFeed(clusterHusbandry, farmId)
        currentCosts = currentCosts + AnimalHelper:giveWater(clusterHusbandry, farmId)
        -- TODO: Do we always want to top up straw? You won't be able to produce slurry then.
        currentCosts = currentCosts + AnimalHelper:giveStraw(clusterHusbandry, farmId)
    end

    return currentCosts;
end;

function AnimalHelper:giveWater(clusterHusbandry, farmId) 
    local freeCapacity = clusterHusbandry.placeable:getHusbandryFreeCapacity(FillType.WATER)
    printd("Free capacity for water = %d l", freeCapacity)

    if (freeCapacity ~= nil and freeCapacity > 0) then
        clusterHusbandry.placeable:addHusbandryFillLevelFromTool(farmId, freeCapacity, FillType.WATER, nil)
    end

    -- Water is free (for now)
    return 0
end

function AnimalHelper:giveStraw(clusterHusbandry, farmId) 
    local freeCapacity = clusterHusbandry.placeable:getHusbandryFreeCapacity(FillType.STRAW)
    local strawCosts = 0

    local pricePerLiter = g_currentMission.economyManager:getPricePerLiter(FillType.STRAW)
    local applied = clusterHusbandry.placeable:addHusbandryFillLevelFromTool(farmId, freeCapacity, FillType.STRAW, nil)
    strawCosts = applied * pricePerLiter
    printd("%d l of straw added for € %d (%d / lt)", applied, strawCosts, pricePerLiter)

    return strawCosts
end

function AnimalHelper:doFeed(clusterHusbandry, farmId) 
    -- Take care of food:
    local animalTypeIndex = clusterHusbandry.animalSystem:getTypeIndexByName(clusterHusbandry.animalTypeName)
    local animalFood = g_currentMission.animalFoodSystem:getAnimalFood(animalTypeIndex)
    local freeCapacity = nil
    local foodCosts = 0
    
    for idx,foodGroup in pairs(animalFood.groups) do
        printd("Currently processing foodgroup '%s'", foodGroup.title)
        DebugUtil.printTableRecursively(foodGroup)

        local fillTypeIndex = AnimalHelper:getFillTypeIndexToFill(foodGroup)
        freeCapacity = freeCapacity or clusterHusbandry.placeable:getFreeFoodCapacity(fillTypeIndex)

        -- Using EatWeight, so all groups getting emptied equally
        local fillAmount = freeCapacity * foodGroup.eatWeight
        local pricePerLiter = g_currentMission.economyManager:getPricePerLiter(fillTypeIndex)
        local priceForFood = fillAmount * pricePerLiter

        clusterHusbandry.placeable:addFood(farmId, fillAmount, fillTypeIndex, nil)

        printd(string.format("Costs for %s  (of %s) liter of fillType '%s' are %s", fillAmount, freeCapacity, fillTypeIndex, priceForFood))
        foodCosts = foodCosts + priceForFood

        printd(string.format("FoodGroup %s done.", idx))
    end

    return foodCosts
end

function AnimalHelper:getFillTypeIndexToFill(foodGroup) 
    -- TODO: Choose the cheapest
    -- 1. Available in storage
    -- 2. Cheapest to buy.
    return foodGroup.fillTypes[1]
end;

function AnimalHelper:doForHorseHusbandry(husbandry, farmId)
    local currentCosts = self:doForHusbandry(husbandry, farmId)

    for _, horse in pairs(husbandry.animalIdToCluster) do
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

addModEventListener(AnimalHelper);

function printd(str, ...)
    if (AnimalHelper.isDebug == true) then
        print(string.format(str, ...))
    end
end


