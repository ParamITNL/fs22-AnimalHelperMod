StorageFillLevel = {};
local StorageFillLevel_mt = Class(StorageFillLevel_mt);

function StorageFillLevel.new(fillType, fillLevel, storage)
    local self = setmetatable({}, StorageFillLevel_mt);
    self.fillType = fillType;
    self.fillLevel = fillLevel;
    self.storage = storage
end;
