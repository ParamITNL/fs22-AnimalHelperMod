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
--            animalHelper:trainHorses(husbandry);
        end,
        ["FALLBACK"] = function(husbandry)
            animalHelper:printf("Starting FALLBACK helper. No specific helper for animal is configured");
            animalHelper:doForHusbandry(husbandry);
        end
    },
    enableLogging = false,
    modDir = g_currentModDirectory,
    version = "",
    configXML = ""
}


function animalHelper:init() 
    animalHelper.modDir = animalHelper:getModDir();

    local modDescXML = loadXMLFile("modDesc", animalHelper.modDir .. "modDesc.xml");
    animalHelper.version = getXMLString(modDescXML, "modDesc.version");
    
    animalHelper.configXML = loadXMLFile("animalHelperXMLFile", animalHelper.modDir .. "animalHelper.xml");
    animalHelper.enableLogging = Utils.getNoNil(getXMLBool(animalHelper.configXML, "animalHelper.logging#enabled"), true);

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
end;

function animalHelper:keyEvent(unicode, sym, modifier, isDown)
    if bitAND(modifier, Input.MOD_CTRL) > 0 and bitAND(modifier, Input.MOD_ALT) > 0 and Input.isKeyPressed(Input.KEY_9) then
        animalHelper:startHelper();
    end;

    if bitAND(modifier, Input.MOD_CTRL) > 0 and bitAND(modifier, Input.MOD_ALT) > 0 and Input.isKeyPressed(Input.KEY_0) then
        animalHelper:printf("Money money money");
        g_currentMission:addMoney(10000000, 1, MoneyType.OTHER, true, true);
    end;
end;

function animalHelper:startHelper()
    animalHelper:printf("Animal Helper - Running Animal Helper");

    for _,husbandry in pairs(g_currentMission.husbandries) do
        if (husbandry.ownerFarmId == 1) then
            animalHelper:printf("Searching helper for animal: " .. husbandry.modulesByName.animals.animalType);
            local helper = Utils.getNoNil(animalHelper.helpers[husbandry.modulesByName.animals.animalType],
                                          animalHelper.helpers.FALLBACK);
            if (helper ~= nil) then
                helper(husbandry);
            end;
        end;
    end;
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