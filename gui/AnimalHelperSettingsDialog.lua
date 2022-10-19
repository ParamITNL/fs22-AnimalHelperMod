AnimalHelperSettingsDialog = {
	CONTROLS = {
		SAVE_BUTTON = "okButton",
		BACK_BUTTON = "backButton",
		START_HOUR = "helperStartHourElement",
		FILL_STRAW = "animalHelperFillStraw",
		IS_DEBUG = "animalHelperIsDebug",
		BUY_PRODUCTS = "animalHelperAlwaysBuyFood"
	},
	workerStartHours = {},
	workerStartHoursNum = {}
}

local AnimalHelperSettingsDialog_mt = Class(AnimalHelperSettingsDialog, DialogElement)

function AnimalHelperSettingsDialog.new(target, customMt, l10n)
    local self = DialogElement.new(target, customMt or AnimalHelperSettingsDialog_mt)
	self.l10n = l10n
	for i = 8, 23, 1 do
		table.insert(AnimalHelperSettingsDialog.workerStartHours, string.format("%02d:00", i))
		table.insert(AnimalHelperSettingsDialog.workerStartHoursNum, i)
	end

    self:registerControls(AnimalHelperSettingsDialog.CONTROLS)

    return self
end

function AnimalHelperSettingsDialog:onOpen()
	AnimalHelperSettingsDialog:superClass().onOpen(self)
	local workHour = 1

	for i = 1, table.getn(AnimalHelperSettingsDialog.workerStartHours) do
		if (AnimalHelper.startHour == AnimalHelperSettingsDialog.workerStartHoursNum[i]) then
			workHour = i;
			break;
		end
	end

	AnimalHelperSettingsDialog.helperStartHourElement:setState(workHour)
	AnimalHelperSettingsDialog.animalHelperFillStraw:setIsChecked(AnimalHelper.fillStraw)
	AnimalHelperSettingsDialog.animalHelperIsDebug:setIsChecked(AnimalHelper.isDebug)
	AnimalHelperSettingsDialog.animalHelperAlwaysBuyFood:setIsChecked(AnimalHelper.buyProducts or true);
end

function AnimalHelperSettingsDialog:onCreateStartHour(element)
	element:setTexts(self.workerStartHours)
	element:setState(table.getn(self.workerStartHours))
	FocusManager:setFocus(element);
end

function AnimalHelperSettingsDialog:onClickOk()
	local _,_ = pcall(function()
		local workerStartHour = self.helperStartHourElement:getState()
		AnimalHelper.startHour = self.workerStartHoursNum[workerStartHour]

		local isDebug = self.animalHelperIsDebug:getIsChecked()
		if isDebug ~= nil then
			AnimalHelper.isDebug = isDebug
		end

		local fillStraw = self.animalHelperFillStraw:getIsChecked()
		if fillStraw ~= nil then
			AnimalHelper.fillStraw = fillStraw
		end

		local buyProductsEnabled = self.animalHelperAlwaysBuyFood:getIsChecked()
		if buyProductsEnabled ~= nul then
			AnimalHelper.buyProducts = buyProductsEnabled
		end
		AnimalHelper:saveSettings()
	end)

    self:close()

    return false
end
