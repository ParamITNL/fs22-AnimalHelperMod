-- HappyAnimals Mod
-- 
-- Author: ParamIT
-- Version: 1.0.0.0
-- Copyright (c) 2019, ParamIT, all rights reserved
-- Thanks to: xDeekay. His animalsClean and animalsHud mod greatly helped me to write 
-- the HappyAnimals mod.

happyAnimals = {};

local modDesc = loadXMLFile("modDesc", g_currentModDirectory .. "modDesc.xml");

happyAnimals.version = getXMLString(modDesc, "modDesc.version");
happyAnimals.modDirectory = g_currentModDirectory;

addModEventListener(happyAnimals);

function happyAnimals:loadMap()
    print("#############################################");
    print("Loaded happyAnimals mod version: " .. happyAnimals.version);
end;