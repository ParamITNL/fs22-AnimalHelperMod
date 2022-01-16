AnimalHelperSettingsDialog = {}
local AnimalHelperSettingsDialog_mt = Class(AnimalHelperSettingsDialog, DialogElement)

AnimalHelperSettingsDialog.CONTROLS = {
    SAVE_BUTTON = "okButton",
	BACK_BUTTON = "backButton",
	START_HOUR = "helperStartHourElement"
}

function AnimalHelperSettingsDialog.new(target, customMt, l10n)
    local self = DialogElement.new(target, customMt or AnimalHelperSettingsDialog_mt)
	self.l10n = l10n
	self.workerStartHours = {}
	for i = 8, 23, 1 do
		table.insert(self.workerStartHours, string.format("%02d:00", i))
	end

    self:registerControls(AnimalHelperSettingsDialog.CONTROLS)

    return self
end

function AnimalHelperSettingsDialog:onOpen()
	AnimalHelperSettingsDialog:superClass().onOpen(self)
	local workHour = 0

	for i = 1, table.getn(self.workerStartHours) do
		if string.format("%02d:00", AnimalHelper.startHour) == self.workerStartHours[i] then
			workHour = i
			break
		end
	end

	self.helperStartHourElement:setState(workHour)

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

function AnimalHelperSettingsDialog:onCreateStartHour(element)
	element:setTexts(self.workerStartHours)
	element:setState(table.getn(self.workerStartHours))
end

function AnimalHelperSettingsDialog:onClickOk()
	print("OK CLICKED")
	local workerStartHour = self.helperStartHourElement:getState()

	printdbg("Worker Start Hour '%s'", workerStartHour)
    -- 	local password = self.passwordElement:getText()
    -- 	local capacity = self.capacityNumberTable[self.capacityElement:getState()]
    -- 	local autoAccept = self.autoAcceptElement:getIsChecked()
    -- 	local allowOnlyFriends = self.allowOnlyFriendsElement:getIsChecked()
    
    self:close()
    
    return false
end
