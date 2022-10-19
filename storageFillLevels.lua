StorageFillLevel = {

};
local ah_StorageFillLevel = Class(ah_StorageFillLevel);

function StorageFillLevel.new(fillType, fillLevel, storage)
    local self = setmetatable({}, ah_StorageFillLevel)
    self.fillType = fillType
    self.fillLevel = fillLevel
    self.storage = storage

    return self
end;

function StorageFillLevel:printInfo()
    print("FillType   : "..self.fillType)
    print("FillLevel  : "..self.fillLevel)
    print("Storage    : "..self.storage)
end
