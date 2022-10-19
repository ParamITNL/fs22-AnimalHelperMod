StorageFillLevelInfo = {}
local StorageFillLevelInfo_mt = Class(StorageFillLevelInfo)

function StorageFillLevelInfo.new(fillType, fillLevel, storage)
    local self = setmetatable({}, StorageFillLevelInfo_mt)
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
