--[[
    Animal Helper
    Author:         ParamIT
    Version:        1.0
]]--
if (animalHelper ~= nil) then
    print("Unregister mod events...");
    removeModEventListener(animalHelper);
end;

animalHelper = {
    helpers = {
        ["HORSE"] = function(husbandry) 
            animalHelper:printf("Horse Helper Activated");
            animalHelper:doForHusbandry(husbandry);
            animalHelper:trainHorses(husbandry);
            return 5000;
        end,
        ["FALLBACK"] = function(husbandry)
            animalHelper:printf("Starting FALLBACK helper. No specific helper for animal is configured");
            animalHelper:doForHusbandry(husbandry);
            return 3000;
        end
    },
    enableLogging = false,
    modDir = g_currentModDirectory,
    enabled = false,
    version = "",
    configXML = ""
}

function animalHelper:dayChanged()
    if animalHelper.enabled == true then
        for _,husbandry in pairs(g_currentMission.husbandries) do
            animalHelper:printf("Training the horses...");
            if (husbandry.ownerFarmId == 1 and husbandry.modulesByName.animals.animalType == "HORSE") then
                animalHelper:trainHorses(husbandry);
            end;
        end;
    end;
end;


function animalHelper:init() 
    animalHelper.modDir = animalHelper:getModDir();

    local modDescXML = loadXMLFile("modDesc", animalHelper.modDir .. "modDesc.xml");
    animalHelper.version = getXMLString(modDescXML, "modDesc.version");
    
    animalHelper.configXML = loadXMLFile("animalHelperXMLFile", animalHelper.modDir .. "animalHelper.xml");
    animalHelper.enableLogging = Utils.getNoNil(getXMLBool(animalHelper.configXML, "animalHelper.logging#enabled"), true);

    Player.registerActionEvents = Utils.appendedFunction(Player.registerActionEvents, animalHelper.registerActionEventsPlayer);
    print("Script: animalHelper v"..tostring(animalHelper.version).." by ParamIT");
end;

function animalHelper:getModDir() 
    local dir = g_currentModDirectory;
    if (dir == nil) then
        if (animalHelper.modDir == nil) then 
            animalHelper.modDir = "D:/FS19/Modding/mods/animalHelper/" ;
        end;
        animalHelper:printf("Warning: ModDir UNKNOWN. Using " .. animalHelper.modDir);
        dir = animalHelper.modDir;
    end;

    animalHelper:printf("Using modDir: " .. dir);
    return dir;
end;

function animalHelper:loadMap(name)
    animalHelper:printf("loadMap: " ..name);
    g_currentMission.environment:addDayChangeListener(animalHelper);
end;

function animalHelper:keyEvent(unicode, sym, modifier, isDown)
    if bitAND(modifier, Input.MOD_CTRL) > 0 and bitAND(modifier, Input.MOD_ALT) > 0 and Input.isKeyPressed(Input.KEY_9) then
        -- animalHelper:startHelper();
    end;
    if bitAND(modifier, Input.MOD_CTRL) > 0 and bitAND(modifier, Input.MOD_ALT) > 0 and Input.isKeyPressed(Input.KEY_8) then
        g_currentMission:addMoney(1000000, owner, "animalUpkeep");
    end;
end;

function animalHelper:registerActionEventsPlayer()
    print ("Registering Actions!");
    --g_inputBinding:setActionEventActive(g_easyDevControls.eventIdObjectDelete, self.lastFoundObject ~= nil)
    local valid, actionEventId, _ = g_inputBinding:registerActionEvent(InputAction.ANIMAL_HELPER_HIRE_HELPER, self, animalHelper.actionCallbackPlayer, false, true, false, true);
    animalHelper:printf("eventId" .. actionEventId );
    g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH);
    g_inputBinding:setActionEventActive(actionEventId, true);
end;

function animalHelper:actionCallbackPlayer(actionName, keyStatus, arg4, arg5, arg6)
    if actionName == "ANIMAL_HELPER_HIRE_HELPER" then animalHelper:startHelper();
    end;
end;

function animalHelper:startHelper()
    animalHelper:printf("Animal Helper - Running Animal Helper");
    local helperCosts = 0;
    local farmId;

    for _,husbandry in pairs(g_currentMission.husbandries) do
        if (husbandry.ownerFarmId == 1) then
            animalHelper:printf("Searching helper for animal: " .. husbandry.modulesByName.animals.animalType);
            local helper = Utils.getNoNil(animalHelper.helpers[husbandry.modulesByName.animals.animalType],
                                          animalHelper.helpers.FALLBACK);
            if (helper ~= nil) then
                helperCosts = helperCosts + helper(husbandry);
                farmId = husbandry:getOwnerFarmId();
            end;
        end;
    end;
    g_currentMission:addMoney(-helperCosts, farmId, MoneyType.ANIMAL_UPKEEP, true, true);
end;

function animalHelper:doForHusbandry(husbandry)
    local foodModule = husbandry.modulesByName.food;
    if (foodModule == nil) then
        animalHelper:printf("ERROR, No food module found for animal " .. husbandry.modulesByName.animals.animalType);
    end;

    local fillTypes = animalHelper:getFillTypes(foodModule);
    if fillTypes ~= nil then
        animalHelper:fillFoods(foodModule, fillTypes)
    end;

    local waterModule = husbandry.modulesByName.water;
    if (waterModule ~= nil) then 
        animalHelper:fillWater(husbandry, waterModule);
    end;

    local strawModule = husbandry.modulesByName.straw;
    if (strawModule ~= nil) then
        animalHelper:fillStraw(husbandry, strawModule);
    end;
end;

function animalHelper:fillFoods(foodModule, fillTypes)
    for _,foodGroupInfo in pairs(fillTypes) do
        for _,fillType in pairs(foodGroupInfo.foodGroup.fillTypes) do
            local currentFreeCapacity = foodModule:getFreeCapacity(fillType);
            animalHelper:printf("fillType: " .. tostring(fillType));
            animalHelper:printf("free Capacity: " .. tostring(currentFreeCapacity));
            animalHelper:printf("capacity: " .. tostring(foodGroupInfo.capacity));
            foodModule:changeFillLevels(currentFreeCapacity, fillType);
        end;
    end;
end;

function animalHelper:fillWater(husbandry, waterModule) 
    animalHelper:printf("Filling water for animal: " .. husbandry.modulesByName.animals.animalType);
    local waterCapacity = waterModule:getCapacity();
    if waterCapacity ~= nil then waterModule:setFillLevel(FillType.WATER, waterCapacity) end;
    animalHelper:printf("Water level filled to " .. tostring(Utils.getNoNil(waterCapacity, 0.0)));
end;

function animalHelper:fillStraw(husbandry, strawModule)
    animalHelper:printf("Filling straw for animal: " .. husbandry.modulesByName.animals.animalType);
    local strawCapacity = strawModule:getCapacity();
    if strawCapacity ~= nil then strawModule:setFillLevel(FillType.STRAW, strawCapacity) end;
    animalHelper:printf ("Straw level filled to " .. tostring(Utils.getNoNil(strawCapacity, 0.0)));
end;

function animalHelper:getFillTypes(foodModule)
    local fillTypes = foodModule:getFilltypeInfos();
    if (fillTypes == nil) then
        animalHelper:printf("ERROR: no fillTypes found...");
    end;

    return fillTypes;
end;

function animalHelper:trainHorses(husbandry) 
    if husbandry.modulesByName.animals.animalType ~= "HORSE" then 
        return 
    end;

    -- loop through animals in Husbandry:
    for _,animal in pairs(husbandry:getAnimals()) do
        if animal.module.animalType == "HORSE" then
            animal.ridingTimerSent = animal.DAILY_TARGET_RIDING_TIME;
            animal.ridingTimer = animal.DAILY_TARGET_RIDING_TIME;
        end;
    end;
end;

function animalHelper:update(dt)
end;

function animalHelper:draw()
end;

function animalHelper:deleteMap()
end;

function animalHelper:mouseEvent(posX, posY, isDown, isUp, button)
end;

function animalHelper:printf(message) 
    if animalHelper.enableLogging ~= true then return end;
    print("Animal Helper v" .. animalHelper.version .. " - " .. message);
end;

animalHelper:init();

addModEventListener(animalHelper);