--
-- HappyAnimalsMod by ParamIT
-- Version 1.0.0.0

HappyAnimals = {};

function HappyAnimals:loadMap(name)
end;

function HappyAnimals:keyEvent(unicode, sym, modifier, isDown)
    if bitAND(modifier, Input.MOD_CTRL) > 0 and bitAND(modifier, Input.MOD_ALT) > 0 and Input.isKeyPressed(Input.KEY_7) then
        print ("We're going to make animals happy!");
        HappyAnimals:makeAnimalsHappy();
    end;
end;

function HappyAnimals:update(dt)
end;

function HappyAnimals:draw()
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

function HappyAnimals:ChangeFillLevel(foodModule, fillTypeIndexes)
	for _,fillTypeIndex in pairs(fillTypeIndexes) do
        local freeCapacity = foodModule:getFreeCapacity(fillTypeIndex);
        print("FilltypeIndex:" .. fillTypeIndex .. ", freecapacity:" .. freeCapacity)

        local delta = 0.0
        if foodModule.fillLevels[fillTypeIndex] ~= nil then
            local oldFillLevel = foodModule.fillLevels[fillTypeIndex]
            local newFillLevel = oldFillLevel + freeCapacity


            newFillLevel = math.max(newFillLevel, 0.0)
            delta = newFillLevel - oldFillLevel
            foodModule:setFillLevel(fillTypeIndex, newFillLevel)
        end
        -- return delta

		-- foodModule.changeFillLevels(freeCapacity, fillTypeIndex);
	end;
end;

function HappyAnimals:FillFoodLevelsHorse(husbandry, foodModule)
	HappyAnimals:ChangeFillLevel(foodModule, {4, 30})
end;

function HappyAnimals:FillFoodLevelsSheep(husbandry, foodModule)
	-- TODO: Check if this array thingy works...
	    --[[
        Gras = 28
        Hooi = 30
    --]]
	HappyAnimals:ChangeFillLevel(foodModule, {28, 30} );
end;

function HappyAnimals:FillFoodLevelsPigs(husbandry, foodModule)
    --[[
        Mais, = 8
        Tarwe = 2
        Gerst = 3
        Sojabonen, Koolzaad, Zonnebloemen = 7/5?/6
        Aardappels/Suikerbieten = 9/10
    --]]
	HappyAnimals:ChangeFillLevel(foodModule, {8, 2, 3, 7, 5, 6, 9, 10});
end;

function HappyAnimals:FillFoodLevelsChicken(husbandry, foodModule)
    --[[
        Tarwe    2
        Gerst    3
    --]]
    HappyAnimals:ChangeFillLevel(foodModule, {2, 3} );
end;

function HappyAnimals:FillFoodLevelsCows(husbandry, foodModule)
    --[[
      Compleet gemengd rantsoen, =19
      Hooi / Kuilvoer,=30/24
      Gras  =28
    --]]
    HappyAnimals:ChangeFillLevel(foodModule, { 19, 30, 24, 28} );
end;

function HappyAnimals:FillWaterLevels(husbandry)
    --18
    local waterModule = husbandry:getModuleByName("water");
    if waterModule ~= nil then
        -- TODO: Check if ChangeFillLevel functions for WaterModule too
        HappyAnimals:ChangeFillLevel(waterModule, { 18 });
    end
end;

function HappyAnimals:FillStrawLevels(husbandry)
    --[[
        Straw = 31
    -- ]]
    local strawModule = husbandry:getModuleByName("straw");
    if strawModule ~= nil then
        HappyAnimals:ChangeFillLevel(strawModule, {31} )
    end;
end;

function HappyAnimals:CleanHusbandry(husbandry)
    if husbandry.modulesByName.foodSpillage ~= nil then
        -- Sets cleanliness to 100%
        husbandry.modulesByName.foodSpillage.cleanlinessFactor = 1.0;
        -- Sets capacity and usage for "foodSpillage"
        husbandry:setModuleParameters("foodSpillage", 0, 0);
    end;
end;

addModEventListener(HappyAnimals);