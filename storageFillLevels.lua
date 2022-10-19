StorageFillLevel = {

};
local StorageFillLevel_mt = Class(ah_StorageFillLevel);

function StorageFillLevel.new(fillType, fillLevel, storage)
    local self = setmetatable({}, ah_StorageFillLevel);
    self.fillType = fillType;
    self.fillLevel = fillLevel;
    self.storage = storage
end;
