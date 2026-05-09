local ADDON_NAME = ...

UnderhealDB = UnderhealDB or {}

local Underheal = CreateFrame("Frame")
local MOVER_NAME = "UnderhealRaidFrameMover"
local TANK_BUTTON_WIDTH = 220
local SetRaidFramesUnlocked

local defaults = {
	raidFrame = {
		unlocked = false,
		grouped = true,
		groupGap = 12,
		groupsPerRow = 3,
		showPets = true,
		showTanks = true,
		skinRaidFrames = true,
		showGroupLabels = true,
		hasPosition = false,
		x = 250,
		y = 600,
	},
	pets = {
		x = 250,
		y = 360,
	},
	tanks = {
		hasPosition = false,
		x = 250,
		y = 720,
	},
}

local function Print(message)
	DEFAULT_CHAT_FRAME:AddMessage("|cff73d0ffUnderheal:|r " .. message)
end

local function EnsureDefaults()
	UnderhealDB.raidFrame = UnderhealDB.raidFrame or {}
	UnderhealDB.pets = UnderhealDB.pets or {}
	UnderhealDB.tanks = UnderhealDB.tanks or {}

	for key, value in pairs(defaults.raidFrame) do
		if UnderhealDB.raidFrame[key] == nil then
			UnderhealDB.raidFrame[key] = value
		end
	end

	for key, value in pairs(defaults.pets) do
		if UnderhealDB.pets[key] == nil then
			UnderhealDB.pets[key] = value
		end
	end

	for key, value in pairs(defaults.tanks) do
		if UnderhealDB.tanks[key] == nil then
			UnderhealDB.tanks[key] = value
		end
	end

	if UnderhealDB.raidFrame.groupGap < 12 then
		UnderhealDB.raidFrame.groupGap = 12
	end
end

local function GetRaidFrame()
	return _G.CompactRaidFrameContainer or _G.CompactRaidFrameManager
end

local function GetHealthColor(healthPercent)
	if healthPercent >= 0.9 then
		return 0.0, 0.70, 0.0
	elseif healthPercent >= 0.8 then
		return 0.45, 0.62, 0.0
	elseif healthPercent >= 0.6 then
		return 0.90, 0.48, 0.0
	elseif healthPercent >= 0.5 then
		return 1.0, 0.38, 0.0
	elseif healthPercent >= 0.3 then
		return 1.0, 0.22, 0.0
	elseif healthPercent >= 0.2 then
		return 0.82, 0.0, 0.0
	elseif healthPercent >= 0.1 then
		return 1.0, 0.0, 0.0
	end

	return 1.0, 0.0, 0.0
end

local function SortByVisualPosition(a, b)
	if math.abs(a.top - b.top) > 8 then
		return a.top > b.top
	end

	return a.left < b.left
end

local function SortByRaidGroup(a, b)
	if a.subgroup ~= b.subgroup then
		return a.subgroup < b.subgroup
	end

	if a.raidIndex ~= b.raidIndex then
		return a.raidIndex < b.raidIndex
	end

	return SortByVisualPosition(a, b)
end

local function IsDiscreteGroupMemberFrame(frame)
	local name = frame and frame:GetName()
	return name and string.match(name, "^CompactRaidGroup%d+Member%d+$")
end

local function SetCompactProfileOption(option, value)
	if _G.CompactUnitFrameProfiles_SetOption then
		pcall(_G.CompactUnitFrameProfiles_SetOption, option, value)
	end

	if _G.CompactUnitFrameProfiles_GetCurrentProfile then
		local ok, profile = pcall(_G.CompactUnitFrameProfiles_GetCurrentProfile)
		if ok and type(profile) == "table" then
			profile[option] = value
		end
	end

	if _G.CompactUnitFrameProfiles_ApplyCurrentSettings then
		pcall(_G.CompactUnitFrameProfiles_ApplyCurrentSettings)
	end
end

function Underheal:ApplyGroupProfile()
	if InCombatLockdown() then
		self.pendingGroupProfile = true
		return
	end

	SetCompactProfileOption("keepGroupsTogether", UnderhealDB.raidFrame.grouped)

	if UnderhealDB.raidFrame.grouped then
		SetCompactProfileOption("sortBy", "group")
	end

	self:ApplyBlizzardContainerGrouping()
end

function Underheal:ApplyBlizzardContainerGrouping()
	local container = _G.CompactRaidFrameContainer
	if not container or not UnderhealDB.raidFrame.grouped then
		return
	end

	if _G.CompactRaidFrameContainer_SetGroupMode then
		pcall(_G.CompactRaidFrameContainer_SetGroupMode, container, "discrete")
	else
		container.groupMode = "discrete"
	end

	local sortFunction = _G.CRFSort_Group or _G.CompactRaidFrameContainer_SortByGroup
	if sortFunction then
		if _G.CompactRaidFrameContainer_SetFlowSortFunction then
			pcall(_G.CompactRaidFrameContainer_SetFlowSortFunction, container, sortFunction)
		else
			container.flowSortFunc = sortFunction
		end
	end

	if _G.CompactRaidFrameContainer_TryUpdate then
		pcall(_G.CompactRaidFrameContainer_TryUpdate, container)
	elseif _G.CompactRaidFrameContainer_LayoutFrames then
		pcall(_G.CompactRaidFrameContainer_LayoutFrames, container)
	end
end

function Underheal:ApplyGroupGap()
	if self.applyingGroupGap or InCombatLockdown() then
		return
	end

	local firstVisibleGroup
	local visibleGroups = {}

	for index = 1, 8 do
		local group = _G["CompactRaidGroup" .. index]
		if group and group:IsShown() and self:GroupHasVisibleMember(index) then
			if not firstVisibleGroup then
				firstVisibleGroup = group
			end

			visibleGroups[#visibleGroups + 1] = group
		end
	end

	if not firstVisibleGroup then
		return
	end

	self.applyingGroupGap = true

	local groupsPerRow = UnderhealDB.raidFrame.groupsPerRow or 3

	for visibleIndex, group in ipairs(visibleGroups) do
		if visibleIndex > 1 then
			local rowIndex = math.floor((visibleIndex - 1) / groupsPerRow)
			local columnIndex = (visibleIndex - 1) % groupsPerRow
			group:ClearAllPoints()

			if columnIndex == 0 then
				local rowAnchor = visibleGroups[((rowIndex - 1) * groupsPerRow) + 1]
				group:SetPoint("TOPLEFT", rowAnchor, "BOTTOMLEFT", 0, -UnderhealDB.raidFrame.groupGap)
			else
				local previousGroup = visibleGroups[visibleIndex - 1]
				group:SetPoint("TOPLEFT", previousGroup, "TOPRIGHT", UnderhealDB.raidFrame.groupGap, 0)
			end
		end
	end

	self.applyingGroupGap = false
end

function Underheal:GetRaidMemberFrames()
	local frames = {}
	local seen = {}

	local function AddFrame(frame)
		if not frame or seen[frame] or not frame:IsShown() then
			return
		end

		local unit = frame.unit or frame.displayedUnit or frame:GetAttribute("unit")
		if not unit or not UnitExists(unit) then
			return
		end

		local raidIndex = UnitInRaid(unit)
		if not raidIndex then
			raidIndex = tonumber(string.match(unit, "^raid(%d+)$"))
		end

		if not raidIndex then
			return
		end

		local _, _, subgroup = GetRaidRosterInfo(raidIndex)
		if not subgroup then
			return
		end

		seen[frame] = true
		frames[#frames + 1] = {
			frame = frame,
			name = frame:GetName(),
			raidIndex = raidIndex,
			subgroup = subgroup,
			left = frame:GetLeft() or 0,
			top = frame:GetTop() or 0,
		}
	end

	local function ScanAllCompactRaidFrames()
		if not EnumerateFrames then
			return
		end

		local frame = EnumerateFrames()
		while frame do
			local name = frame:GetName()
			if name and string.match(name, "^Compact") and string.find(name, "Raid") then
				AddFrame(frame)
			end

			frame = EnumerateFrames(frame)
		end
	end

	for index = 1, 40 do
		AddFrame(_G["CompactRaidFrame" .. index])
	end

	for group = 1, 8 do
		for member = 1, 5 do
			AddFrame(_G["CompactRaidGroup" .. group .. "Member" .. member])
		end
	end

	ScanAllCompactRaidFrames()

	return frames
end

function Underheal:EnsureGroupMarker(parent)
	if parent.UnderhealGroupMarker then
		return parent.UnderhealGroupMarker
	end

	local marker = CreateFrame("Frame", nil, parent, BackdropTemplateMixin and "BackdropTemplate")
	marker:SetSize(34, 14)
	marker:SetFrameLevel(parent:GetFrameLevel() + 5)

	if marker.SetBackdrop then
		marker:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 8,
			edgeSize = 8,
			insets = { left = 2, right = 2, top = 2, bottom = 2 },
		})
		marker:SetBackdropColor(0.05, 0.16, 0.20, 0.9)
		marker:SetBackdropBorderColor(0.45, 0.82, 1, 0.85)
	end

	local text = marker:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	text:SetPoint("CENTER", 0, 1)
	marker.text = text

	parent.UnderhealGroupMarker = marker
	return marker
end

function Underheal:ClearGroupMarkers()
	for group = 1, 8 do
		local frame = _G["CompactRaidGroup" .. group]
		if frame and frame.UnderhealGroupMarker then
			frame.UnderhealGroupMarker:Hide()
		end
	end

	for index = 1, 40 do
		local frame = _G["CompactRaidFrame" .. index]
		if frame and frame.UnderhealGroupMarker then
			frame.UnderhealGroupMarker:Hide()
		end
	end

	for group = 1, 8 do
		for member = 1, 5 do
			local frame = _G["CompactRaidGroup" .. group .. "Member" .. member]
			if frame and frame.UnderhealGroupMarker then
				frame.UnderhealGroupMarker:Hide()
			end
		end
	end
end

function Underheal:GroupHasVisibleMember(groupIndex)
	for member = 1, 5 do
		local frame = _G["CompactRaidGroup" .. groupIndex .. "Member" .. member]
		if frame and frame:IsShown() then
			local unit = frame.unit or frame.displayedUnit or frame:GetAttribute("unit")
			if unit and UnitExists(unit) then
				return true
			end
		end
	end

	return false
end

function Underheal:ApplyDiscreteGroupMarkers()
	local foundGroupFrame = false

	for group = 1, 8 do
		local frame = _G["CompactRaidGroup" .. group]
		if frame and frame:IsShown() and self:GroupHasVisibleMember(group) then
			foundGroupFrame = true
		end
	end

	return foundGroupFrame
end

function Underheal:HasDiscreteGroupMembers()
	for group = 1, 8 do
		if self:GroupHasVisibleMember(group) then
			return true
		end
	end

	return false
end

function Underheal:HideLooseRaidFramesWhenGrouped()
	if InCombatLockdown() or not UnderhealDB.raidFrame.grouped or not self:HasDiscreteGroupMembers() then
		return
	end

	local frames = self:GetRaidMemberFrames()
	for _, info in ipairs(frames) do
		local frame = info.frame
		if frame and not IsDiscreteGroupMemberFrame(frame) then
			frame:Hide()

			if not frame.UnderhealLooseHideHooked then
				frame:HookScript("OnShow", function(self)
					if not InCombatLockdown() and UnderhealDB.raidFrame.grouped and Underheal:HasDiscreteGroupMembers() then
						self:Hide()
					end
				end)
				frame.UnderhealLooseHideHooked = true
			end
		end
	end
end

function Underheal:ApplyGroupMarkers()
	if InCombatLockdown() then
		self.pendingGroupMarkers = true
		return
	end

	self:ClearGroupMarkers()

	if not UnderhealDB.raidFrame.grouped or not UnderhealDB.raidFrame.showGroupLabels then
		return
	end

	self:HideLooseRaidFramesWhenGrouped()

	if self:ApplyDiscreteGroupMarkers() then
		return
	end

	local frames = self:GetRaidMemberFrames()
	if #frames == 0 then
		return
	end

	table.sort(frames, SortByRaidGroup)

	local lastSubgroup
	for _, info in ipairs(frames) do
		if info.subgroup ~= lastSubgroup then
			local marker = self:EnsureGroupMarker(info.frame)
			marker:ClearAllPoints()
			marker:SetPoint("BOTTOMLEFT", info.frame, "TOPLEFT", 0, 2)
			marker.text:SetText("G" .. info.subgroup)
			marker:Show()
			lastSubgroup = info.subgroup
		end
	end
end

function Underheal:ApplyMemberGroupGap()
	-- Do not manually reanchor individual Blizzard raid buttons. In Classic Era
	-- those frames are protected and can collapse into blank translucent shells.
end

function Underheal:SkinRaidMemberFrame(frame)
	if not frame or not UnderhealDB.raidFrame.skinRaidFrames then
		return
	end

	if not frame.UnderhealSkinBackground then
		local background = frame:CreateTexture(nil, "BACKGROUND")
		background:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
		background:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
		background:SetColorTexture(0.02, 0.08, 0.03, 0.88)
		frame.UnderhealSkinBackground = background
	end

	if not frame.UnderhealSkinBorder then
		local border = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
		border:SetPoint("TOPLEFT", frame, "TOPLEFT", -1, 1)
		border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1, -1)
		border:SetFrameLevel(frame:GetFrameLevel() + 2)

		if border.SetBackdrop then
			border:SetBackdrop({
				edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
				edgeSize = 8,
				insets = { left = 2, right = 2, top = 2, bottom = 2 },
			})
			border:SetBackdropBorderColor(0.35, 0.65, 0.75, 0.75)
		end

		frame.UnderhealSkinBorder = border
	end

	local healthBar = frame.healthBar or frame.healthbar or frame.HealthBar
	if healthBar then
		if healthBar.SetStatusBarTexture then
			healthBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
		end

		local unit = frame.unit or frame.displayedUnit or frame:GetAttribute("unit")
		local healthPercent = 1
		if unit and UnitExists(unit) then
			local healthMax = UnitHealthMax(unit)
			if healthMax and healthMax > 0 then
				healthPercent = UnitHealth(unit) / healthMax
			end
		end

		local r, g, b = GetHealthColor(healthPercent)
		if healthBar.SetStatusBarColor then
			healthBar:SetStatusBarColor(r, g, b, 0.95)
		end

		if healthBar.SetAlpha then
			healthBar:SetAlpha(1)
		end

		frame.UnderhealFlashHealth = healthPercent < 0.1
		frame.UnderhealFlashElapsed = frame.UnderhealFlashHealth and (frame.UnderhealFlashElapsed or 0) or 0

		if frame.UnderhealSkinBackground then
			frame.UnderhealSkinBackground:SetColorTexture(0.02, 0.08, 0.03, 0.88)
		end

		if not frame.UnderhealFlashHooked then
			frame:HookScript("OnUpdate", function(self, elapsed)
				if not self.UnderhealFlashHealth then
					return
				end

				local bar = self.healthBar or self.healthbar or self.HealthBar
				if not bar then
					return
				end

				self.UnderhealFlashElapsed = (self.UnderhealFlashElapsed or 0) + elapsed
				local alpha = 0.35 + (math.abs(math.sin(self.UnderhealFlashElapsed * 8)) * 0.65)
				if bar.SetAlpha then
					bar:SetAlpha(alpha)
				end
				if self.UnderhealSkinBackground then
					self.UnderhealSkinBackground:SetColorTexture(0.25 * alpha, 0.0, 0.0, 0.88)
				end
			end)
			frame.UnderhealFlashHooked = true
		end
	end

	local name = frame.name or frame.Name
	if name and name.SetTextColor then
		name:SetTextColor(1, 1, 1)
	end
end

function Underheal:SkinRaidFrames()
	if not UnderhealDB.raidFrame.skinRaidFrames then
		return
	end

	for group = 1, 8 do
		for member = 1, 5 do
			self:SkinRaidMemberFrame(_G["CompactRaidGroup" .. group .. "Member" .. member])
		end
	end

	for index = 1, 40 do
		self:SkinRaidMemberFrame(_G["CompactRaidFrame" .. index])
	end

	local frames = self:GetRaidMemberFrames()
	for _, info in ipairs(frames) do
		self:SkinRaidMemberFrame(info.frame)
	end
end

function Underheal:GetPetWatchFrame()
	if self.petWatch then
		return self.petWatch
	end

	local frame = CreateFrame("Frame", "UnderhealPetWatchFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
	frame:SetSize(220, 28)
	frame:SetFrameStrata("MEDIUM")
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")

	if frame.SetBackdrop then
		frame:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 12,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		})
		frame:SetBackdropColor(0.03, 0.05, 0.06, 0.82)
		frame:SetBackdropBorderColor(0.35, 0.65, 0.75, 0.9)
	end

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	title:SetPoint("TOPLEFT", 8, -7)
	title:SetText("Raid Pets")
	frame.title = title

	frame.buttons = {}
	frame:SetScript("OnDragStart", function(self)
		if UnderhealDB.raidFrame.unlocked and not InCombatLockdown() then
			self:StartMoving()
		end
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		if self:GetLeft() and self:GetTop() then
			UnderhealDB.pets.x = self:GetLeft()
			UnderhealDB.pets.y = self:GetTop()
		end
	end)

	frame:Hide()
	self.petWatch = frame
	return frame
end

function Underheal:GetPetButton(index)
	local frame = self:GetPetWatchFrame()
	if frame.buttons[index] then
		return frame.buttons[index]
	end

	local button = CreateFrame("Button", nil, frame, "SecureUnitButtonTemplate")
	button:SetSize(104, 24)
	button:RegisterForClicks("AnyUp")
	button:SetAttribute("type1", "target")

	local bg = button:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0.02, 0.08, 0.03, 0.88)
	button.bg = bg

	local health = button:CreateTexture(nil, "ARTWORK")
	health:SetPoint("TOPLEFT")
	health:SetPoint("BOTTOMLEFT")
	health:SetWidth(104)
	health:SetColorTexture(0.0, 0.55, 0.0, 0.9)
	button.health = health

	local name = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	name:SetPoint("LEFT", 5, 0)
	name:SetPoint("RIGHT", -20, 0)
	name:SetJustifyH("LEFT")
	button.name = name

	local debuff = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	debuff:SetPoint("RIGHT", -5, 0)
	debuff:SetTextColor(1, 0.35, 0.35)
	button.debuff = debuff

	frame.buttons[index] = button
	return button
end

function Underheal:PositionPetWatchFrame()
	local frame = self:GetPetWatchFrame()
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", UnderhealDB.pets.x, UnderhealDB.pets.y)
end

function Underheal:UpdatePetWatch()
	if InCombatLockdown() then
		self.pendingPetUpdate = true
		return
	end

	local frame = self:GetPetWatchFrame()
	self:PositionPetWatchFrame()

	if not UnderhealDB.raidFrame.showPets then
		frame:Hide()
		return
	end

	local pets = {}
	for index = 1, 40 do
		local unit = "raid" .. index .. "pet"
		if UnitExists(unit) then
			pets[#pets + 1] = unit
		end
	end

	if #pets == 0 then
		frame:Hide()
		return
	end

	frame:SetHeight(36 + (#pets * 28))
	frame:SetWidth(228)
	frame:Show()

	for index, unit in ipairs(pets) do
		local button = self:GetPetButton(index)
		local healthMax = UnitHealthMax(unit)
		local healthPercent = 1
		if healthMax and healthMax > 0 then
			healthPercent = UnitHealth(unit) / healthMax
		end

			button:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -28 - ((index - 1) * 28))
			button:SetAttribute("unit", unit)
			button.health:SetWidth(math.max(1, 104 * healthPercent))
			button.name:SetText(UnitName(unit) or "Pet")
			button.debuff:SetText(UnitDebuff(unit, 1) and "!" or "")
		button:Show()
	end

	for index = #pets + 1, #frame.buttons do
		frame.buttons[index]:SetAttribute("unit", nil)
		frame.buttons[index]:Hide()
	end
end

function Underheal:IsTankUnit(unit, raidIndex)
	if not unit or not UnitExists(unit) then
		return false
	end

	if UnitGroupRolesAssigned and UnitGroupRolesAssigned(unit) == "TANK" then
		return true
	end

	if GetPartyAssignment and GetPartyAssignment("MAINTANK", unit) then
		return true
	end

	if raidIndex and GetRaidRosterInfo then
		local role = select(10, GetRaidRosterInfo(raidIndex))
		if role == "TANK" or role == "MAINTANK" then
			return true
		end
	end

	return false
end

function Underheal:GetTankWatchFrame()
	if self.tankWatch then
		return self.tankWatch
	end

	local frame = CreateFrame("Frame", "UnderhealTankWatchFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
	frame:SetSize(TANK_BUTTON_WIDTH + 16, 28)
	frame:SetFrameStrata("MEDIUM")
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")

	if frame.SetBackdrop then
		frame:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 12,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		})
		frame:SetBackdropColor(0.03, 0.05, 0.06, 0.82)
		frame:SetBackdropBorderColor(0.35, 0.65, 0.75, 0.9)
	end

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	title:SetPoint("TOPLEFT", 8, -7)
	title:SetText("Tanks")
	frame.title = title

	frame.buttons = {}
	frame:SetScript("OnDragStart", function(self)
		if UnderhealDB.raidFrame.unlocked and not InCombatLockdown() then
			self:StartMoving()
		end
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		if self:GetLeft() and self:GetTop() then
			UnderhealDB.tanks.x = self:GetLeft()
			UnderhealDB.tanks.y = self:GetTop()
			UnderhealDB.tanks.hasPosition = true
		end
	end)

	frame:Hide()
	self.tankWatch = frame
	return frame
end

function Underheal:GetTankButton(index)
	local frame = self:GetTankWatchFrame()
	if frame.buttons[index] then
		return frame.buttons[index]
	end

	local button = CreateFrame("Button", nil, frame, "SecureUnitButtonTemplate")
	button:SetSize(TANK_BUTTON_WIDTH, 24)
	button:RegisterForClicks("AnyUp")
	button:SetAttribute("type1", "target")
	button:SetScript("OnUpdate", function(self, elapsed)
		if not self.flashHealth then
			return
		end

		self.flashElapsed = (self.flashElapsed or 0) + elapsed
		local alpha = 0.35 + (math.abs(math.sin(self.flashElapsed * 8)) * 0.65)
		self.health:SetAlpha(alpha)
		self.bg:SetColorTexture(0.25 * alpha, 0.0, 0.0, 0.88)
	end)

	local bg = button:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0.02, 0.08, 0.03, 0.88)
	button.bg = bg

	local health = button:CreateTexture(nil, "ARTWORK")
	health:SetPoint("TOPLEFT")
	health:SetPoint("BOTTOMLEFT")
	health:SetWidth(TANK_BUTTON_WIDTH)
	health:SetColorTexture(0.0, 0.55, 0.0, 0.9)
	button.health = health

	local name = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	name:SetPoint("LEFT", 5, 0)
	name:SetPoint("RIGHT", button, "CENTER", -4, 0)
	name:SetJustifyH("LEFT")
	button.name = name

	local healthText = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	healthText:SetPoint("LEFT", button, "CENTER", 4, 0)
	healthText:SetPoint("RIGHT", -22, 0)
	healthText:SetJustifyH("RIGHT")
	button.healthText = healthText

	local debuff = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	debuff:SetPoint("RIGHT", -5, 0)
	debuff:SetTextColor(1, 0.35, 0.35)
	button.debuff = debuff

	frame.buttons[index] = button
	return button
end

function Underheal:PositionTankWatchFrame()
	local frame = self:GetTankWatchFrame()
	frame:ClearAllPoints()

	if UnderhealDB.tanks.hasPosition then
		frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", UnderhealDB.tanks.x, UnderhealDB.tanks.y)
		return
	end

	local raidFrame = GetRaidFrame()
	if raidFrame and raidFrame:GetLeft() and raidFrame:GetTop() then
		frame:SetPoint("BOTTOMLEFT", raidFrame, "TOPLEFT", 0, 24)
	else
		frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", UnderhealDB.tanks.x, UnderhealDB.tanks.y)
	end
end

function Underheal:UpdateTankWatch()
	if InCombatLockdown() then
		self.pendingTankUpdate = true
		return
	end

	local frame = self:GetTankWatchFrame()
	self:PositionTankWatchFrame()

	if not UnderhealDB.raidFrame.showTanks then
		frame:Hide()
		return
	end

	local tanks = {}
	if IsInRaid and IsInRaid() then
		for index = 1, 40 do
			local unit = "raid" .. index
			if self:IsTankUnit(unit, index) then
				tanks[#tanks + 1] = unit
			end
		end
	else
		if self:IsTankUnit("player") then
			tanks[#tanks + 1] = "player"
		end

		for index = 1, 4 do
			local unit = "party" .. index
			if self:IsTankUnit(unit) then
				tanks[#tanks + 1] = unit
			end
		end
	end

	if #tanks == 0 then
		frame:Hide()
		return
	end

	frame:SetHeight(36 + (#tanks * 28))
	frame:SetWidth(TANK_BUTTON_WIDTH + 16)
	frame:Show()

	for index, unit in ipairs(tanks) do
		local button = self:GetTankButton(index)
			local healthMax = UnitHealthMax(unit)
			local healthCurrent = UnitHealth(unit)
			local healthPercent = 1
			if healthMax and healthMax > 0 then
				healthPercent = healthCurrent / healthMax
			end
			local r, g, b = GetHealthColor(healthPercent)

			button:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -28 - ((index - 1) * 28))
			button:SetAttribute("unit", unit)
			button.health:SetWidth(math.max(1, TANK_BUTTON_WIDTH * healthPercent))
			button.health:SetColorTexture(r, g, b, 0.95)
			button.health:SetAlpha(1)
			button.bg:SetColorTexture(0.02, 0.08, 0.03, 0.88)
			button.flashHealth = healthPercent < 0.1
			button.flashElapsed = button.flashHealth and (button.flashElapsed or 0) or 0
			button.name:SetText(UnitName(unit) or "Tank")
			button.healthText:SetText(healthCurrent .. "/" .. healthMax)
			button.debuff:SetText(UnitDebuff(unit, 1) and "!" or "")
			button:Show()
		end

		for index = #tanks + 1, #frame.buttons do
			frame.buttons[index].flashHealth = false
			frame.buttons[index].health:SetAlpha(1)
			frame.buttons[index].bg:SetColorTexture(0.02, 0.08, 0.03, 0.88)
			frame.buttons[index]:SetAttribute("unit", nil)
			frame.buttons[index]:Hide()
		end
end

function Underheal:HookBlizzardRaidLayout()
	if self.raidLayoutHooked then
		return
	end

	if _G.CompactRaidFrameContainer_LayoutFrames then
		hooksecurefunc("CompactRaidFrameContainer_LayoutFrames", function()
			Underheal.captureGroupBase = true
			Underheal:ApplyGroupGap()
			Underheal:ApplyGroupMarkers()
			Underheal:SkinRaidFrames()
		end)
		self.raidLayoutHooked = true
	end
end

local function GetMover()
	if Underheal.mover then
		return Underheal.mover
	end

	local mover = CreateFrame("Frame", MOVER_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate")
	mover:SetSize(220, 24)
	mover:SetFrameStrata("DIALOG")
	mover:SetClampedToScreen(true)
	mover:SetMovable(true)
	mover:EnableMouse(true)
	mover:RegisterForDrag("LeftButton")

	if mover.SetBackdrop then
		mover:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 16,
			edgeSize = 12,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		})
		mover:SetBackdropColor(0.05, 0.16, 0.20, 0.85)
		mover:SetBackdropBorderColor(0.45, 0.82, 1, 0.9)
	end

	local label = mover:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("CENTER")
	label:SetText("Underheal raid frame mover")

	mover:SetScript("OnDragStart", function(self)
		if UnderhealDB.raidFrame.unlocked and not InCombatLockdown() then
			self:StartMoving()
			Underheal.moving = true
		end
	end)

	mover:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		Underheal.moving = false
		Underheal:SaveMoverPosition()
		Underheal:ApplyRaidFramePosition()
	end)

	mover:SetScript("OnUpdate", function()
		if Underheal.moving then
			Underheal:ApplyRaidFramePosition()
		end
	end)

	mover:Hide()
	Underheal.mover = mover
	return mover
end

function Underheal:PlaceMover()
	local mover = GetMover()
	mover:ClearAllPoints()

	if UnderhealDB.raidFrame.hasPosition then
		mover:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", UnderhealDB.raidFrame.x, UnderhealDB.raidFrame.y + 4)
		return
	end

	local frame = GetRaidFrame()
	if frame and frame:GetLeft() and frame:GetTop() then
		mover:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 4)
	else
		mover:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
	end
end

function Underheal:SaveMoverPosition()
	local mover = GetMover()
	if not mover:GetLeft() or not mover:GetBottom() then
		return
	end

	UnderhealDB.raidFrame.x = mover:GetLeft()
	UnderhealDB.raidFrame.y = mover:GetBottom() - 4
	UnderhealDB.raidFrame.hasPosition = true
end

function Underheal:ApplyRaidFramePosition()
	if InCombatLockdown() then
		self.pendingApply = true
		return false
	end

	local frame = GetRaidFrame()
	if not frame or not UnderhealDB.raidFrame.hasPosition then
		return false
	end

	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", UnderhealDB.raidFrame.x, UnderhealDB.raidFrame.y)
	frame:Show()

	return true
end

function Underheal:RestoreBlizzardPosition()
	if InCombatLockdown() then
		Print("Cannot restore raid frames while in combat.")
		return
	end

	for key, value in pairs(defaults.raidFrame) do
		UnderhealDB.raidFrame[key] = value
	end

	local mover = GetMover()
	mover:Hide()

	local container = _G.CompactRaidFrameContainer
	if container then
		container:ClearAllPoints()
		container:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 4, -300)
		container:Show()
	end

	local manager = _G.CompactRaidFrameManager
	if manager then
		manager:ClearAllPoints()
		manager:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -7, -140)
		manager:Show()
	end

	self:RefreshOptions()
	Print("Restored Blizzard raid frames to a visible default spot. Use /reload if Blizzard does not redraw them immediately.")
end

function Underheal:RefreshOptions()
	if not self.optionsFrame then
		return
	end

	EnsureDefaults()

	self.optionsFrame.unlockCheck:SetChecked(UnderhealDB.raidFrame.unlocked)
	self.optionsFrame.groupCheck:SetChecked(UnderhealDB.raidFrame.grouped)
	self.optionsFrame.tankCheck:SetChecked(UnderhealDB.raidFrame.showTanks)
	self.optionsFrame.petCheck:SetChecked(UnderhealDB.raidFrame.showPets)
end

function Underheal:CreateOptionsFrame()
	if self.optionsFrame then
		return self.optionsFrame
	end

	local frame = CreateFrame("Frame", "UnderhealOptionsFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
	frame:SetSize(340, 280)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:Hide()

	if frame.SetBackdrop then
		frame:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile = true,
			tileSize = 32,
			edgeSize = 32,
			insets = { left = 8, right = 8, top = 8, bottom = 8 },
		})
	end

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 18, -18)
	title:SetText("Underheal")

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -4, -4)

	local unlockCheck = CreateFrame("CheckButton", nil, frame, "InterfaceOptionsCheckButtonTemplate")
	unlockCheck:SetPoint("TOPLEFT", 18, -58)
	unlockCheck:SetScript("OnClick", function(self)
		SetRaidFramesUnlocked(self:GetChecked())
		Underheal:RefreshOptions()
	end)
	frame.unlockCheck = unlockCheck

	local unlockLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	unlockLabel:SetPoint("LEFT", unlockCheck, "RIGHT", 2, 1)
	unlockLabel:SetText("Unlock raid frames")

	local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	hint:SetPoint("TOPLEFT", unlockCheck, "BOTTOMLEFT", 2, -8)
	hint:SetWidth(290)
	hint:SetJustifyH("LEFT")
	hint:SetText("When unlocked, drag the Underheal mover bar to reposition Blizzard raid frames.")

	local groupCheck = CreateFrame("CheckButton", nil, frame, "InterfaceOptionsCheckButtonTemplate")
	groupCheck:SetPoint("TOPLEFT", 18, -116)
	groupCheck:SetScript("OnClick", function(self)
		UnderhealDB.raidFrame.grouped = not not self:GetChecked()
		Underheal:ApplyGroupProfile()
		Underheal:ApplyGroupGap()
		Underheal:ApplyGroupMarkers()
		Underheal:RefreshOptions()
	end)
	frame.groupCheck = groupCheck

	local groupLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	groupLabel:SetPoint("LEFT", groupCheck, "RIGHT", 2, 1)
	groupLabel:SetText("Keep raid frames grouped")

	local groupHint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	groupHint:SetPoint("TOPLEFT", groupCheck, "BOTTOMLEFT", 2, -8)
	groupHint:SetWidth(290)
	groupHint:SetJustifyH("LEFT")
	groupHint:SetText("Uses Blizzard raid groups and keeps duplicate loose frames hidden.")

	local tankCheck = CreateFrame("CheckButton", nil, frame, "InterfaceOptionsCheckButtonTemplate")
	tankCheck:SetPoint("TOPLEFT", 18, -166)
	tankCheck:SetScript("OnClick", function(self)
		UnderhealDB.raidFrame.showTanks = not not self:GetChecked()
		Underheal:UpdateTankWatch()
		Underheal:RefreshOptions()
	end)
	frame.tankCheck = tankCheck

	local tankLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	tankLabel:SetPoint("LEFT", tankCheck, "RIGHT", 2, 1)
	tankLabel:SetText("Show tanks")

	local petCheck = CreateFrame("CheckButton", nil, frame, "InterfaceOptionsCheckButtonTemplate")
	petCheck:SetPoint("TOPLEFT", 18, -198)
	petCheck:SetScript("OnClick", function(self)
		UnderhealDB.raidFrame.showPets = not not self:GetChecked()
		Underheal:UpdatePetWatch()
		Underheal:RefreshOptions()
	end)
	frame.petCheck = petCheck

	local petLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	petLabel:SetPoint("LEFT", petCheck, "RIGHT", 2, 1)
	petLabel:SetText("Show raid pets")

	local reset = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	reset:SetSize(120, 24)
	reset:SetPoint("BOTTOMLEFT", 18, 18)
	reset:SetText("Reset Position")
	reset:SetScript("OnClick", function()
		Underheal:RestoreBlizzardPosition()
		Underheal:RefreshOptions()
	end)

	self.optionsFrame = frame
	return frame
end

function Underheal:ToggleOptions()
	local frame = self:CreateOptionsFrame()
	self:RefreshOptions()

	if frame:IsShown() then
		frame:Hide()
	else
		frame:Show()
	end
end

SetRaidFramesUnlocked = function(unlocked, quiet)
	unlocked = not not unlocked

	if InCombatLockdown() then
		Print("Cannot change raid frame movement while in combat. I will try again when combat ends.")
		Underheal.pendingUnlock = unlocked
		return
	end

	local frame = GetRaidFrame()
	if not frame then
		Print("Blizzard raid frames are not loaded yet. Open raid frames once, or join a group, then try again.")
		return
	end

	UnderhealDB.raidFrame.unlocked = unlocked

	local mover = GetMover()
	if unlocked then
		Underheal:PlaceMover()
		mover:Show()
	else
		mover:Hide()
	end

	Underheal:ApplyRaidFramePosition()
	Underheal:RefreshOptions()

	if not quiet then
		if unlocked then
			Print("Mover shown. Drag the Underheal bar, then type /underheal lock.")
		else
			Print("Raid frame mover hidden.")
		end
	end
end

local function PrintHelp()
	Print("/underheal - open Underheal options")
	Print("/underheal unlock - show the raid-frame mover")
	Print("/underheal lock - hide the raid-frame mover")
	Print("/underheal groups - toggle grouped raid frames")
	Print("/underheal groupdebug - list visible raid frame groups")
	Print("/underheal tanks - toggle the tank watch")
	Print("/underheal pets - toggle the raid pet watch")
	Print("/underheal reset - restore Blizzard raid frames to a visible default spot")
end

SLASH_UNDERHEAL1 = "/underheal"
SLASH_UNDERHEAL2 = "/uh"
SlashCmdList.UNDERHEAL = function(input)
	local command = string.lower(input or ""):match("^%s*(%S*)")

	if command == "unlock" then
		SetRaidFramesUnlocked(true)
	elseif command == "lock" then
		SetRaidFramesUnlocked(false)
	elseif command == "groups" then
		UnderhealDB.raidFrame.grouped = not UnderhealDB.raidFrame.grouped
		Underheal:ApplyGroupProfile()
		Underheal:ApplyGroupGap()
		Underheal:ApplyGroupMarkers()
		Underheal:RefreshOptions()
		Print("Grouped raid frames " .. (UnderhealDB.raidFrame.grouped and "enabled." or "disabled."))
	elseif command == "groupdebug" then
		local frames = Underheal:GetRaidMemberFrames()
		Print("Found " .. #frames .. " visible Blizzard raid member frame(s).")
		for index, info in ipairs(frames) do
			local unit = info.frame.unit or info.frame.displayedUnit or info.frame:GetAttribute("unit") or "?"
			Print(index .. ": " .. (info.frame:GetName() or "unnamed") .. " unit=" .. unit .. " group=" .. info.subgroup)
		end
	elseif command == "pets" then
		UnderhealDB.raidFrame.showPets = not UnderhealDB.raidFrame.showPets
		Underheal:UpdatePetWatch()
		Underheal:RefreshOptions()
		Print("Raid pet watch " .. (UnderhealDB.raidFrame.showPets and "enabled." or "disabled."))
	elseif command == "tanks" then
		UnderhealDB.raidFrame.showTanks = not UnderhealDB.raidFrame.showTanks
		Underheal:UpdateTankWatch()
		Underheal:RefreshOptions()
		Print("Tank watch " .. (UnderhealDB.raidFrame.showTanks and "enabled." or "disabled."))
	elseif command == "reset" or command == "restore" then
		Underheal:RestoreBlizzardPosition()
	elseif command == "help" then
		PrintHelp()
	else
		Underheal:ToggleOptions()
	end
end

Underheal:RegisterEvent("PLAYER_LOGIN")
Underheal:RegisterEvent("PLAYER_REGEN_ENABLED")
Underheal:RegisterEvent("ADDON_LOADED")
Underheal:RegisterEvent("GROUP_ROSTER_UPDATE")
Underheal:RegisterEvent("UNIT_HEALTH")
Underheal:RegisterEvent("UNIT_MAXHEALTH")
Underheal:RegisterEvent("UNIT_AURA")
pcall(Underheal.RegisterEvent, Underheal, "PLAYER_ROLES_ASSIGNED")
Underheal:SetScript("OnEvent", function(self, event, addonName)
	if event == "PLAYER_LOGIN" then
		EnsureDefaults()
		self:HookBlizzardRaidLayout()
		self:ApplyGroupProfile()
		self:ApplyRaidFramePosition()
		self:ApplyGroupGap()
		self:ApplyGroupMarkers()
		self:SkinRaidFrames()
		SetRaidFramesUnlocked(UnderhealDB.raidFrame.unlocked, true)
		self:UpdateTankWatch()
		self:UpdatePetWatch()
		Print("Loaded. Type /underheal to open options.")
	elseif event == "PLAYER_REGEN_ENABLED" then
		if self.pendingApply then
			self.pendingApply = nil
			self:ApplyRaidFramePosition()
		end

		if self.pendingUnlock ~= nil then
			local unlocked = self.pendingUnlock
			self.pendingUnlock = nil
			SetRaidFramesUnlocked(unlocked)
		end

		if self.pendingGroupProfile then
			self.pendingGroupProfile = nil
		end

		self:ApplyGroupProfile()
		self:ApplyGroupGap()
		if self.pendingGroupMarkers then
			self.pendingGroupMarkers = nil
		end
		self:ApplyGroupMarkers()
		self:SkinRaidFrames()
		if self.pendingPetUpdate then
			self.pendingPetUpdate = nil
		end
		if self.pendingTankUpdate then
			self.pendingTankUpdate = nil
		end
		self:UpdateTankWatch()
		self:UpdatePetWatch()
	elseif event == "ADDON_LOADED" and addonName == "Blizzard_CompactRaidFrames" then
		EnsureDefaults()
		self:HookBlizzardRaidLayout()
		self:ApplyGroupProfile()
		self:ApplyRaidFramePosition()
		self:ApplyGroupGap()
		self:ApplyGroupMarkers()
		self:SkinRaidFrames()
		SetRaidFramesUnlocked(UnderhealDB.raidFrame.unlocked, true)
		self:UpdateTankWatch()
		self:UpdatePetWatch()
	elseif event == "GROUP_ROSTER_UPDATE" then
		EnsureDefaults()
		self:ApplyGroupProfile()
		self:ApplyGroupGap()
		self:ApplyGroupMarkers()
		self:SkinRaidFrames()
		self:UpdateTankWatch()
		self:UpdatePetWatch()
	elseif event == "PLAYER_ROLES_ASSIGNED" then
		self:UpdateTankWatch()
	elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or event == "UNIT_AURA" then
		local unit = addonName
		if unit and string.find(unit, "pet") then
			self:UpdatePetWatch()
		end
		if unit and (unit == "player" or string.match(unit, "^raid%d+$") or string.match(unit, "^party%d+$")) then
			self:UpdateTankWatch()
		end
		if unit and string.find(unit, "raid") then
			self:SkinRaidFrames()
		end
	end
end)
