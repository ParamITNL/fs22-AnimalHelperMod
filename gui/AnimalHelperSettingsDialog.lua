AnimalHelperSettingsDialog = {}
local AnimalHelperSettingsDialog_mt = Class(AnimalHelperSettingsDialog, DialogElement)

AnimalHelperSettingsDialog.CONTROLS = {
    SAVE_BUTTON = "okButton",
	BACK_BUTTON = "backButton"
}

function AnimalHelperSettingsDialog.new(target, customMt)
    local self = DialogElement.new(target, customMt or AnimalHelperSettingsDialog_mt)
    self:registerControls(AnimalHelperSettingsDialog.CONTROLS)
    return self
end

function AnimalHelperSettingsDialog:onOpen()
	AnimalHelperSettingsDialog:superClass().onOpen(self)

	self:initValues(true)

	-- local dynInfo = g_currentMission.missionDynamicInfo
	-- local numPlayers = dynInfo.capacity
	-- local capacityState = g_serverMinCapacity

	-- for i = 1, table.getn(self.capacityNumberTable) do
	-- 	if numPlayers == self.capacityNumberTable[i] then
	-- 		capacityState = i

	-- 		break
	-- 	end
	-- end
-- 	self.capacityElement:setState(capacityState)
-- 	self.serverNameElement:setVisible(not g_currentMission.connectedToDedicatedServer)
-- 	self.autoAcceptElement:setVisible(not g_currentMission.connectedToDedicatedServer)
-- 	self.capacityElement:setVisible(not g_currentMission.connectedToDedicatedServer)
-- 	self.serverNameElement:setText(dynInfo.serverName)
-- 	self.passwordElement:setText(dynInfo.password)
-- 	self.autoAcceptElement:setIsChecked(dynInfo.autoAccept)
-- 	self.allowOnlyFriendsElement:setIsChecked(dynInfo.allowOnlyFriends)
-- 	self.boxLayout:invalidateLayout()
end

function AnimalHelperSettingsDialog:initValues(force)

end

function AnimalHelperSettingsDialog:onClickOk()
	print("OK CLICKED")
	local workerStartHour = self.startHourElement:getText()
	if MathUtil.IsNaN(workerStartHour) then
		return false
	end

	printdbg("Worker Start Hour '%02d:00'")
    -- 	local password = self.passwordElement:getText()
    -- 	local capacity = self.capacityNumberTable[self.capacityElement:getState()]
    -- 	local autoAccept = self.autoAcceptElement:getIsChecked()
    -- 	local allowOnlyFriends = self.allowOnlyFriendsElement:getIsChecked()
    
    self:close()
    
    return false
end
