--
-- HappyAnimalsMod by ParamIT
-- Version 1.0.0.0

HappyAnimals = {};
HappyAnimals.Counter = 0;

-- ID 28 = GRAS
-- ID 24 = SILAGE 
-- ID 30 = HEU
-- ID 19 = MISCHRATION
-- ID 18 = WASSER
-- ID 31 = STROH
-- ID 2 = WEIZEN
-- ID 8 = MAIS
-- ID 6 = SONNENBLUMEN
-- ID 9 = KARTOFFEL
-- ID 4 = HAFER
-- ID 10 = ZUCKERRÜBEN
-- ID 3 = GERSTE
-- ID 7 = SOYABOHNEN
-- ID 5 = RAPS
-- ID 14 Pallets Chicken Eggs goes in game to 1?!
-- ID 15 Pallets Sheep wool goes in game to 1 !?!
-- ID 16 milk Cows
-- ID 45 manure (mist) Cows, pigs
-- ID 46 liquid manure (gülle) Cows, pigs

function HappyAnimals:loadMap(name)
    print("loadMap");
end;

function HappyAnimals:keyEvent(unicode, sym, modifier, isDown)
    -- if bitAND(modifier, Input.MOD_CTRL) > 0 and bitAND(modifier, Input.MOD_ALT) > 0 and Input.isKeyPressed(Input.KEY_6) then
    --     local p = getUserProfileAppPath() .. "mods/happyAnimals/happyAnimals.lua";
    --     print ("Trying to reload source file from " .. p)
    --     package.loaded[p] = nil;
    --     require(p);
    -- end

    if bitAND(modifier, Input.MOD_CTRL) > 0 and bitAND(modifier, Input.MOD_ALT) > 0 and Input.isKeyPressed(Input.KEY_7) then
        print ("We're going to make animals happy!");
        HappyAnimals:makeAnimalsHappy();
    end;
    
    if bitAND(modifier, Input.MOD_CTRL) > 0 and bitAND(modifier, Input.MOD_ALT) > 0 and Input.isKeyPressed(Input.KEY_0) then 
		if (g_currentMission.missionDynamicInfo.isMultiplayer == true) and (g_currentMission.player.farmId == FarmManager.SPECTATOR_FARM_ID) then
			print("MoneyTool - Multiplayer game - Player has no Farm!");
		else
			g_currentMission:consoleCommandCheatMoney(money);
		end;
	end;
end;

function HappyAnimals:update(dt)
end;

function HappyAnimals:draw()
    -- this one get's called.. Update isn't. Don't know why...HappyAnimals
    -- print("draw");
end;

function HappyAnimals:deleteMap()
end;

function HappyAnimals:mouseEvent(posX, posY, isDown, isUp, button)
end;

function HappyAnimals:makeAnimalsHappy()

    for k,husbandry in pairs(g_currentMission.husbandries) do
        HappyAnimals:CleanHusbandry(husbandry);
        HappyAnimals:FillFoodLevels(husbandry);
        HappyAnimals:FillWaterLevels(husbandry);
        HappyAnimals:FillStrawLevels(husbandry);
    end;
end;

function HappyAnimals:FillStrawLevels(husbandry)
    print("Filling up Straw for husbandry " .. husbandry:getAnimalType())
    --31
end;

function HappyAnimals:FillFoodLevels(husbandry)
    local foodModule = husbandry.modulesByName.food;
    if foodModule == nil then
        return;
    end;

    local animalType = husbandry:getAnimalType();
    animalType = string.upper(animalType);
    if animalType == "CHICKEN" then HappyAnimals:FillFoodLevelsChicken(husbandry, foodModule);
    elseif animalType == "COW" then HappyAnimals:FillFoodLevelsCows(husbandry, foodModule);
    elseif animalType == "HORSE" then HappyAnimals:FillFoodLevelsHorse(husbandry, foodModule);
    elseif animalType == "PIG" then HappyAnimals:FillFoodLevelsPigs(husbandry, foodModule);
    elseif animalType == "SHEEP" then HappyAnimals:FillFoodLevelsSheep(husbandry, foodModule);
    end;
end;

function HappyAnimals:FillFoodLevelsHorse(husbandry, foodModule)
    --[[
        Haver = 4
        Hooi  = 30
    ]]
    local freeCapacityHay = foodModule:getFreeCapacity(30);
    local freeCapacityOat = foodModule:getFreeCapacity(4);

    print ("Filling levels..");
    foodModule:changeFillLevels(freeCapacityHay, 30);
    foodModule:changeFillLevels(freeCapacityOat, 4);
end;

function HappyAnimals:FillFoodLevelsSheep(husbandry, foodModule)
    --[[
        Gras = 28
        Hooi = 30
    --]]
end;

function HappyAnimals:FillFoodLevelsPigs(husbandry, foodModule)
    --[[
        Mais, = 8
        Tarwe = 2
        Gerst = 3
        Sojabonen, Koolzaad, Zonnebloemen = 7/5?/6
        Aardappels/Suikerbieten = 9/10
    --]]
end;

function HappyAnimals:FillFoodLevelsChicken(husbandry, foodModule)
    local freeCapacityWheet = foodModule:getFreeCapacity(2);
    local freeCapacityGerst = foodModule:getFreeCapacity(3);

    print ("Filling levels..");
    foodModule:changeFillLevels(freeCapacityWheet, 2);
    foodModule:changeFillLevels(freeCapacityGerst, 3);
end;

function HappyAnimals:FillFoodLevelsCows(husbandry, foodModule)
    --[[
      Compleet gemengd rantsoen, =19
      Hooi / Kuilvoer,=30/24
      Gras  =28
    --]]
end;

function HappyAnimals:FillWaterLevels(husbandry)
    --18
end;

function HappyAnimals:CleanHusbandry(husbandry)
    print ("Cleaning husbandry " .. husbandry:getAnimalType());

    if husbandry.modulesByName.foodSpillage ~= nil then
        -- Sets cleanliness to 100%
        husbandry.modulesByName.foodSpillage.cleanlinessFactor = 1.0;
        -- Sets capacity and usage for "foodSpillage"
        husbandry:setModuleParameters("foodSpillage", 0, 0);
    end;
end;

addModEventListener(HappyAnimals);