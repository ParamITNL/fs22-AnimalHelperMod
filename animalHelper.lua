-- function HappyHorse:hourChanged()
-- 	if g_currentMission.environment.currentHour == 12 then
-- 		for _,husbandry in pairs(g_currentMission.husbandrySystem.clusterHusbandries) do
-- 			if husbandry.animalTypeName == "HORSE" then
-- 				for _, horse in pairs(husbandry.animalIdToCluster) do
-- 					horse.riding = 100
-- 					horse.fitness = 100
-- 					g_currentMission.hud:addSideNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format("%s %s", horse.name, g_i18n.modEnvironments[HappyHorse.ModName].texts.info))
-- 				end
-- 			end
-- 		end
-- 	end
-- end


--[[ 
    Animal Helper 22
    Author:     ParamIT
    Version:    22
]] 


if (animalHelper ~= nil) then
    print("AnimalHelper already exists, unregistering...");
    g_currentMission.hud:addSideNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format("%s", g_i18n.modEnvironments[animalHelper.modName].texts.ANIMAL_HELPER_UNREGISTERED))
    animalHelper:removeModEventListener(animalHelper);
end

animalHelper = {
    helpers = {
        ["HORSE"] = function(husbandry, farmId)
            return animalHelper:doForHorseHusbandry(husbandry, farmId);
        end,
        -- ["HORSE"] = function(husbandry) 
        --     animalHelper:printf("Horse Helper Activated");
        --     animalHelper:doForHusbandry(husbandry);
        --     animalHelper:trainHorses(husbandry);
        --     return 5000;
        -- end,
        ["FALLBACK"] = function(husbandry, farmId)
            print("Hired running fallback method helper...");
            return animalHelper:doForHusbandry(husbandry, farmId);
        end
    },
    enabled = false,
    isDebug = true,
    modName = g_currentModName,
}

animalHelper.ANIMAL_HELPER_MAX_TABLE_DEPTH = 1
animalHelper.lastHusbandry = {}

-- addConsoleCommand("ahLastValues", "print last known husbandry values", "printLastValues", animalHelper)
-- function animalHelper:printLastValues()
--     printf("Last known values:")
--     printf("lastHusbandry")
--     DebugUtil.printTableRecursively(animalHelper.lastHusbandry or {},".",0,self.ANIMAL_HELPER_MAX_TABLE_DEPTH)
--     printf("clusterSubType")

--     DebugUtil.printTableRecursively(animalHelper.clusterSubType or {}, ".", 0, self.ANIMAL_HELPER_MAX_TABLE_DEPTH)
-- end

function animalHelper:loadMap(name)
    g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.hourChanged, self);
    Player.registerActionEvents = Utils.appendedFunction(Player.registerActionEvents, self.registerActionEventsPlayer);
end;

function animalHelper:registerActionEventsPlayer()
    print("Registering Actions!");
    local valid, actionEventId, _ = g_inputBinding:registerActionEvent(InputAction.ANIMAL_HELPER_HIRE_HELPER, animalHelper,
        animalHelper.actionCallbackPlayer, false, true, false, true);

    g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW);
    g_inputBinding:setActionEventTextVisibility(actionEventId, true);
end

function animalHelper:actionCallbackPlayer(actionName, keyStatus, arg4, arg5, arg6)
    if actionName == "ANIMAL_HELPER_HIRE_HELPER" then
        print("Enable AnimalHelper");
        -- TODO: Add action to disable helper...
        animalHelper.enabled = animalHelper.enabled ~= true;
    end
end;

function animalHelper:hourChanged()
    print("Checking if helper is enabled...");
    if (animalHelper.enabled == true and (g_currentMission.environment.currentHour == 9 or animalHelper.isDebug == true)) then
        animalHelper:runHelpers();
    end
end;

addConsoleCommand("ahRunHelpers", "Hire animal helpers now", "runHelpers", animalHelper)
function animalHelper:runHelpers() 
    g_currentMission.hud:addSideNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format("%s", g_i18n.modEnvironments[animalHelper.modName].texts.ANIMAL_HELPER_STARTED))
    for _,clusterHusbandry in pairs(g_currentMission.husbandrySystem.clusterHusbandries) do

        -- Get Helper for Current Husbandry:
        local helper = Utils.getNoNil(animalHelper.helpers[clusterHusbandry.animalTypeName], animalHelper.helpers.FALLBACK);

        -- If we have a helper, run it. We should have one, because we should fallback to the default helper.
        if (helper ~= nil) then
            local farmId = g_currentMission.player.farmId;
            local costs = helper(clusterHusbandry, farmId);

            if (costs ~= nil) then
                print(string.format("AnimalHelper for husbandry %s done. Costs were %s", clusterHusbandry.animalTypeName, -costs))
                g_currentMission:addMoney(-costs, farmId, MoneyType.ANIMAL_UPKEEP, true, true)
            else
                print(string.format("WARNING: helper '%s' didn't charge anything!", helper));
            end
        end
    end
    g_currentMission.hud:addSideNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format("%s", g_i18n.modEnvironments[animalHelper.modName].texts.ANIMAL_HELPER_DONE))
end;

function animalHelper:doForHusbandry(clusterHusbandry, farmId)
    local currentCosts = 0
    print ("Fallback helper for husbandry " .. clusterHusbandry.animalTypeName);

    if (clusterHusbandry ~= nil) then
        -- Take care of food:
        local animalTypeIndex = clusterHusbandry.animalSystem:getTypeIndexByName(clusterHusbandry.animalTypeName)
        local animalFood = g_currentMission.animalFoodSystem:getAnimalFood(animalTypeIndex)

        for idx,foodGroup in pairs(animalFood.groups) do
            for _,fillTypeIndex in pairs(foodGroup.fillTypes) do
                local fillTypeName = Utils.getNoNil(g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex), "unknown")
                printf("Trying to fill %s", fillTypeName)
                local freeCapacity = math.max(0, clusterHusbandry.placeable:getFreeFoodCapacity(fillTypeIndex))
                local pricePerLiter = g_currentMission.economyManager:getPricePerLiter(fillTypeIndex)
                local priceForFood = freeCapacity * pricePerLiter

                clusterHusbandry.placeable:addFood(farmId, freeCapacity, fillTypeIndex, nil)

                print(string.format("Costs for %s liter of fillType '%s' are %s", freeCapacity, fillTypeIndex, priceForFood))
                currentCosts = currentCosts + priceForFood
            end
            print(string.format("FoodGroup %s done.", idx))
        end
    end

    return currentCosts;
end;

function animalHelper:doForHorseHusbandry(husbandry, farmId)
    local currentCosts = self:doForHusbandry(husbandry, farmId)

    for _, horse in pairs(husbandry.animalIdToCluster) do
        local currentRiding = horse.riding
        local currentFitness = horse.fitness
        horse.riding = 100
        horse.fitness = 100

        currentCosts = currentCosts + (100 - currentRiding) * 10.0
        currentCosts = currentCosts + ((100 - currentFitness) * 10.0)
    end;
    return currentCosts;
end;

addModEventListener(animalHelper);

-- function animalHelper:init()
--     animalHelper.modDir = animalHelper:getModDir();

--     local modDescXML = loadXMLFile("modDesc", animalHelper.modDir .. "modDesc.xml");
--     animalHelper.version = getXMLString(modDescXML, "modDesc.version");

--     animalHelper.configXML = loadXMLFile("animalHelperXMLFile", animalHelper.modDir .. "animalHelper.xml");
--     animalHelper.enableLogging =
--         Utils.getNoNil(getXMLBool(animalHelper.configXML, "animalHelper.logging#enabled"), true);

--     Player.registerActionEvents = Utils.appendedFunction(Player.registerActionEvents,
--         animalHelper.registerActionEventsPlayer);
--     print("Script: animalHelper v" .. tostring(animalHelper.version) .. " by ParamIT");
-- end


-- function animalHelper:loadMap(name)
--     g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.hourChanged, self)

--     animalHelper:printf("loadMap: " .. name);
--     g_currentMission.environment:addDayChangeListener(animalHelper);
-- end

-- function animalHelper:keyEvent(unicode, sym, modifier, isDown)
--     if bitAND(modifier, Input.MOD_CTRL) > 0 and bitAND(modifier, Input.MOD_ALT) > 0 and Input.isKeyPressed(Input.KEY_9) then
--         -- animalHelper:startHelper();
--     end
--     if bitAND(modifier, Input.MOD_CTRL) > 0 and bitAND(modifier, Input.MOD_ALT) > 0 and Input.isKeyPressed(Input.KEY_8) then
--         g_currentMission:addMoney(1000000, owner, "animalUpkeep");
--     end
-- end

-- function animalHelper:registerActionEventsPlayer()
--     print("Registering Actions!");
--     -- g_inputBinding:setActionEventActive(g_easyDevControls.eventIdObjectDelete, self.lastFoundObject ~= nil)
--     local valid, actionEventId, _ = g_inputBinding:registerActionEvent(InputAction.ANIMAL_HELPER_HIRE_HELPER, self,
--         animalHelper.actionCallbackPlayer, false, true, false, true);
--     animalHelper:printf("eventId" .. actionEventId);
--     g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH);
--     g_inputBinding:setActionEventActive(actionEventId, true);
-- end

-- function animalHelper:actionCallbackPlayer(actionName, keyStatus, arg4, arg5, arg6)
--     if actionName == "ANIMAL_HELPER_HIRE_HELPER" then
--         animalHelper:startHelper();
--     end
-- end

-- function animalHelper:startHelper()
--     animalHelper:printf("Animal Helper - Running Animal Helper");
--     local helperCosts = 0;
--     local farmId;

--     for _, husbandry in pairs(g_currentMission.husbandries) do
--         if (husbandry.ownerFarmId == 1) then
--             animalHelper:printf("Searching helper for animal: " .. husbandry.modulesByName.animals.animalType);
--             local helper = Utils.getNoNil(animalHelper.helpers[husbandry.modulesByName.animals.animalType],
--                 animalHelper.helpers.FALLBACK);
--             if (helper ~= nil) then
--                 helperCosts = helperCosts + helper(husbandry);
--                 farmId = husbandry:getOwnerFarmId();
--             end
--         end
--     end
--     g_currentMission:addMoney(-helperCosts, farmId, MoneyType.ANIMAL_UPKEEP, true, true);
-- end

-- function animalHelper:doForHusbandry(husbandry)
--     local foodModule = husbandry.modulesByName.food;
--     if (foodModule == nil) then
--         animalHelper:printf("ERROR, No food module found for animal " .. husbandry.modulesByName.animals.animalType);
--     end

--     local fillTypes = animalHelper:getFillTypes(foodModule);
--     if fillTypes ~= nil then
--         animalHelper:fillFoods(foodModule, fillTypes)
--     end

--     local waterModule = husbandry.modulesByName.water;
--     if (waterModule ~= nil) then
--         animalHelper:fillWater(husbandry, waterModule);
--     end

--     local strawModule = husbandry.modulesByName.straw;
--     if (strawModule ~= nil) then
--         animalHelper:fillStraw(husbandry, strawModule);
--     end
-- end

-- function animalHelper:fillFoods(foodModule, fillTypes)
--     for _, foodGroupInfo in pairs(fillTypes) do
--         for _, fillType in pairs(foodGroupInfo.foodGroup.fillTypes) do
--             local currentFreeCapacity = foodModule:getFreeCapacity(fillType);
--             animalHelper:printf("fillType: " .. tostring(fillType));
--             animalHelper:printf("free Capacity: " .. tostring(currentFreeCapacity));
--             animalHelper:printf("capacity: " .. tostring(foodGroupInfo.capacity));
--             foodModule:changeFillLevels(currentFreeCapacity, fillType);
--         end
--     end
-- end

-- function animalHelper:fillWater(husbandry, waterModule)
--     animalHelper:printf("Filling water for animal: " .. husbandry.modulesByName.animals.animalType);
--     local waterCapacity = waterModule:getCapacity();
--     if waterCapacity ~= nil then
--         waterModule:setFillLevel(FillType.WATER, waterCapacity)
--     end
--     animalHelper:printf("Water level filled to " .. tostring(Utils.getNoNil(waterCapacity, 0.0)));
-- end

-- function animalHelper:fillStraw(husbandry, strawModule)
--     animalHelper:printf("Filling straw for animal: " .. husbandry.modulesByName.animals.animalType);
--     local strawCapacity = strawModule:getCapacity();
--     if strawCapacity ~= nil then
--         strawModule:setFillLevel(FillType.STRAW, strawCapacity)
--     end
--     animalHelper:printf("Straw level filled to " .. tostring(Utils.getNoNil(strawCapacity, 0.0)));
-- end

-- function animalHelper:getFillTypes(foodModule)
--     local fillTypes = foodModule:getFilltypeInfos();
--     if (fillTypes == nil) then
--         animalHelper:printf("ERROR: no fillTypes found...");
--     end

--     return fillTypes;
-- end

-- function animalHelper:trainHorses(husbandry)
--     if husbandry.modulesByName.animals.animalType ~= "HORSE" then
--         return
--     end

--     -- loop through animals in Husbandry:
--     for _, animal in pairs(husbandry:getAnimals()) do
--         if animal.module.animalType == "HORSE" then
--             animal.ridingTimerSent = animal.DAILY_TARGET_RIDING_TIME;
--             animal.ridingTimer = animal.DAILY_TARGET_RIDING_TIME;
--         end
--     end
-- end

-- function animalHelper:update(dt)
-- end

-- function animalHelper:draw()
-- end

-- function animalHelper:deleteMap()
-- end

-- function animalHelper:mouseEvent(posX, posY, isDown, isUp, button)
-- end

-- function animalHelper:printf(message)
--     if animalHelper.enableLogging ~= true then
--         return
--     end
--     print("Animal Helper v" .. animalHelper.version .. " - " .. message);
-- end

-- animalHelper:init();


