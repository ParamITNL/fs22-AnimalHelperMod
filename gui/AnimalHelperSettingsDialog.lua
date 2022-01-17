AnimalHelperSettingsDialog = {}
local AnimalHelperSettingsDialog_mt = Class(AnimalHelperSettingsDialog, DialogElement)

AnimalHelperSettingsDialog.CONTROLS = {
    SAVE_BUTTON = "okButton",
	BACK_BUTTON = "backButton",
	START_HOUR = "helperStartHourElement",
	FILL_STRAW = "animalHelperFillStraw",
	IS_DEBUG = "animalHelperIsDebug"
}

function AnimalHelperSettingsDialog.new(target, customMt, l10n)
    local self = DialogElement.new(target, customMt or AnimalHelperSettingsDialog_mt)
	self.l10n = l10n
	self.workerStartHours = {}
	self.workerStartHoursNum = {}
	for i = 8, 23, 1 do
		table.insert(self.workerStartHours, string.format("%02d:00", i))
		table.insert(self.workerStartHoursNum, i)
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
	self.animalHelperFillStraw:setIsChecked(AnimalHelper.fillStraw)
	self.animalHelperIsDebug:setIsChecked(AnimalHelper.isDebug)
end

function AnimalHelperSettingsDialog:onCreateStartHour(element)
	element:setTexts(self.workerStartHours)
	element:setState(table.getn(self.workerStartHours))
end

function AnimalHelperSettingsDialog:onClickOk()
	local _,_ = pcall(function()
		printdbg("OK CLICKED")
		local workerStartHour = self.helperStartHourElement:getState()

		printdbg("Worker Start Hour '%s'", workerStartHour)
		AnimalHelper.startHour = self.workerStartHoursNum[workerStartHour]

		local isDebug = self.animalHelperIsDebug:getIsChecked()
		if isDebug ~= nil then
			AnimalHelper.isDebug = isDebug
		end

		local fillStraw = self.animalHelperFillStraw:getIsChecked()
		if fillStraw ~= nil then
			AnimalHelper.fillStraw = fillStraw
		end
	end)
	
    -- 	local password = self.passwordElement:getText()
    -- 	local capacity = self.capacityNumberTable[self.capacityElement:getState()]
    -- 	local autoAccept = self.autoAcceptElement:getIsChecked()
    -- 	local allowOnlyFriends = self.allowOnlyFriendsElement:getIsChecked()
    
    self:close()
    
    return false
end
