local ADDON_NAME = ...

UnderhealDB = UnderhealDB or {}

local Underheal = CreateFrame("Frame")
local MOVER_NAME = "UnderhealRaidFrameMover"
local TANK_BUTTON_WIDTH = 220
local COMM_PREFIX = "Underheal"
local SetRaidFramesUnlocked

local defaults = {
	raidFrame = {
		unlocked = false,
		grouped = true,
		groupGap = 12,
		groupsPerRow = 3,
		showPets = true,
		showTanks = true,
			showBuffButtons = true,
			clickToBuff = true,
			showThreat = true,
			skinRaidFrames = true,
			showGroupLabels = true,
			scale = 1.0,
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
	clickBuffButton = {
		hasPosition = false,
		x = 250,
		y = 640,
	},
	buffButtons = {
		{
			key = "fortitude",
			label = "F",
			cast = "Prayer of Fortitude",
			aura = "Power Word: Fortitude",
			auraAliases = { "Prayer of Fortitude" },
			enabled = true,
			classes = {
				DRUID = true,
				HUNTER = true,
				MAGE = true,
				PALADIN = true,
				PRIEST = true,
				ROGUE = true,
				SHAMAN = true,
				WARLOCK = true,
				WARRIOR = true,
			},
			missingColor = { r = 0.88, g = 0.58, b = 0.24 },
			priorityColor = { r = 1.0, g = 0.38, b = 0.0 },
			clickPriority = 100,
			priorityRoles = { TANK = true, HEALER = true },
		},
		{
			key = "spirit",
			label = "S",
			cast = "Prayer of Spirit",
			aura = "Divine Spirit",
			auraAliases = { "Prayer of Spirit" },
			enabled = true,
			classes = {
				DRUID = true,
				HUNTER = true,
				MAGE = true,
				PALADIN = true,
				PRIEST = true,
				SHAMAN = true,
				WARLOCK = true,
			},
			missingColor = { r = 0.30, g = 0.55, b = 0.95 },
			priorityColor = { r = 0.12, g = 0.80, b = 1.0 },
			clickPriority = 200,
			priorityRoles = { HEALER = true },
		},
		{
			key = "fearward",
			label = "W",
			cast = "Fear Ward",
			aura = "Fear Ward",
			enabled = true,
			classes = {
				DRUID = true,
				HUNTER = true,
				MAGE = true,
				PALADIN = true,
				PRIEST = true,
				ROGUE = true,
				SHAMAN = true,
				WARLOCK = true,
				WARRIOR = true,
			},
			missingColor = { r = 0.55, g = 0.32, b = 0.14 },
			priorityColor = { r = 0.95, g = 0.45, b = 0.08 },
			clickPriority = 500,
			hideWarningOnCooldown = true,
			priorityRoles = { TANK = true, HEALER = true },
		},
		{
			key = "custom4",
			label = "4",
			cast = "",
			aura = "",
			enabled = false,
			classes = {},
			missingColor = { r = 0.70, g = 0.35, b = 0.85 },
			priorityColor = { r = 0.95, g = 0.55, b = 1.0 },
			clickPriority = 50,
			priorityRoles = {},
		},
		{
			key = "custom5",
			label = "5",
			cast = "",
			aura = "",
			enabled = false,
			classes = {},
			missingColor = { r = 0.85, g = 0.85, b = 0.20 },
			priorityColor = { r = 1.0, g = 0.95, b = 0.30 },
			clickPriority = 50,
			priorityRoles = {},
		},
	},
	clickCasts = {
		none = {
			left = "Flash Heal(Rank 4)",
			right = "Renew",
			useTrinkets = false,
		},
		alt = {
			left = "",
			right = "",
			useTrinkets = false,
		},
		ctrl = {
			left = "Flash Heal",
			right = "",
			useTrinkets = false,
		},
		shift = {
			left = "Heal(Rank 3)",
			right = "",
			useTrinkets = false,
		},
	},
}

local CLASS_ORDER = {
	{ key = "DRUID", label = "Druid" },
	{ key = "HUNTER", label = "Hunter" },
	{ key = "MAGE", label = "Mage" },
	{ key = "PALADIN", label = "Paladin" },
	{ key = "PRIEST", label = "Priest" },
	{ key = "ROGUE", label = "Rogue" },
	{ key = "SHAMAN", label = "Shaman" },
	{ key = "WARLOCK", label = "Warlock" },
	{ key = "WARRIOR", label = "Warrior" },
}

local ROLE_ORDER = {
	{ key = "TANK", label = "Tanks" },
	{ key = "HEALER", label = "Healers" },
	{ key = "DAMAGER", label = "DPS" },
}

local HEALER_CLASSES = {
	DRUID = true,
	PALADIN = true,
	PRIEST = true,
	SHAMAN = true,
}

local CLICK_CAST_ORDER = {
	{ key = "none", label = "None", prefix = "" },
	{ key = "alt", label = "Alt", prefix = "alt-" },
	{ key = "ctrl", label = "Ctrl", prefix = "ctrl-" },
	{ key = "shift", label = "Shift", prefix = "shift-" },
}

local HEALING_SPELLS = {
	["chain heal"] = true,
	["flash heal"] = true,
	["flash of light"] = true,
	["greater heal"] = true,
	["heal"] = true,
	["healing touch"] = true,
	["healing wave"] = true,
	["holy light"] = true,
	["lesser healing wave"] = true,
	["lesser heal"] = true,
	["prayer of healing"] = true,
	["regrowth"] = true,
}

local function Print(message)
	DEFAULT_CHAT_FRAME:AddMessage("|cff73d0ffUnderheal:|r " .. message)
end

local function CopyTable(source)
	if type(source) ~= "table" then
		return source
	end

	local copied = {}
	for key, value in pairs(source) do
		copied[key] = CopyTable(value)
	end
	return copied
end

local function EnsureDefaults()
	UnderhealDB.raidFrame = UnderhealDB.raidFrame or {}
	UnderhealDB.pets = UnderhealDB.pets or {}
	UnderhealDB.tanks = UnderhealDB.tanks or {}
	UnderhealDB.clickBuffButton = UnderhealDB.clickBuffButton or {}
	UnderhealDB.buffButtons = UnderhealDB.buffButtons or {}
	UnderhealDB.clickCasts = UnderhealDB.clickCasts or {}

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

	for key, value in pairs(defaults.clickBuffButton) do
		if UnderhealDB.clickBuffButton[key] == nil then
			UnderhealDB.clickBuffButton[key] = value
		end
	end

	for index, value in ipairs(defaults.buffButtons) do
		if UnderhealDB.buffButtons[index] == nil then
			UnderhealDB.buffButtons[index] = CopyTable(value)
		else
			for key, defaultValue in pairs(value) do
				if UnderhealDB.buffButtons[index][key] == nil then
					UnderhealDB.buffButtons[index][key] = CopyTable(defaultValue)
				end
			end
		end
	end

	for modifier, value in pairs(defaults.clickCasts) do
		UnderhealDB.clickCasts[modifier] = UnderhealDB.clickCasts[modifier] or {}
		for key, defaultValue in pairs(value) do
			if UnderhealDB.clickCasts[modifier][key] == nil then
				UnderhealDB.clickCasts[modifier][key] = CopyTable(defaultValue)
			end
		end
	end

	if UnderhealDB.raidFrame.groupGap < 12 then
		UnderhealDB.raidFrame.groupGap = 12
	end
end

local function GetRaidFrame()
	return _G.CompactRaidFrameContainer or _G.CompactRaidFrameManager
end

local function GetRaidFrameScale()
	local scale = UnderhealDB.raidFrame and UnderhealDB.raidFrame.scale or 1
	if scale <= 0 then
		return 1
	elseif scale < 0.8 then
		return 0.8
	elseif scale > 1.6 then
		return 1.6
	end

	return scale
end

local function IsHealerCharacter()
	local _, classFile = UnitClass("player")
	return classFile and HEALER_CLASSES[classFile]
end

local function GetRaidUnits()
	local units = {}
	if IsInRaid and IsInRaid() then
		for index = 1, 40 do
			local unit = "raid" .. index
			if UnitExists(unit) then
				units[#units + 1] = unit
			end
		end
	elseif IsInGroup and IsInGroup() then
		units[#units + 1] = "player"
		for index = 1, 4 do
			local unit = "party" .. index
			if UnitExists(unit) then
				units[#units + 1] = unit
			end
		end
	else
		units[#units + 1] = "player"
	end

	return units
end

local function IsRaidCombatClear()
	for _, unit in ipairs(GetRaidUnits()) do
		if UnitAffectingCombat(unit) then
			return false
		end
	end

	return true
end

local function IsRaidUnit(unit)
	if not unit then
		return false
	end

	return unit == "player" or string.match(unit, "^raid%d+$") or string.match(unit, "^party%d+$")
end

local function GetShortName(name)
	if not name then
		return nil
	end

	return string.match(name, "^[^-]+") or name
end

local function IsHealingSpell(spellName)
	if not spellName then
		return false
	end

	local baseName = string.lower((string.gsub(spellName, "%s*%b()", "")))
	return HEALING_SPELLS[baseName] == true
end

local function FindGroupUnitByName(name)
	local shortName = GetShortName(name)
	if not shortName then
		return nil
	end

	for _, unit in ipairs(GetRaidUnits()) do
		local unitName = UnitName(unit)
		if GetShortName(unitName) == shortName then
			return unit
		end
	end

	return nil
end

local function SendUnderhealAddonMessage(message)
	local channel
	if IsInRaid and IsInRaid() then
		channel = "RAID"
	elseif IsInGroup and IsInGroup() then
		channel = "PARTY"
	else
		return
	end

	if C_ChatInfo and C_ChatInfo.SendAddonMessage then
		C_ChatInfo.SendAddonMessage(COMM_PREFIX, message, channel)
	elseif SendAddonMessage then
		SendAddonMessage(COMM_PREFIX, message, channel)
	end
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

local function GetThreatTargetUnit()
	if UnitExists("target") and UnitCanAttack("player", "target") then
		return "target"
	end

	if UnitExists("targettarget") and UnitCanAttack("player", "targettarget") then
		return "targettarget"
	end

	return nil
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

local function UnitHasNamedAura(unit, auraName)
	if not unit or not auraName then
		return false
	end

	for index = 1, 40 do
		local name = UnitBuff(unit, index)
		if not name then
			return false
		end

		if name == auraName then
			return true
		end
	end

	return false
end

local function UnitHasConfiguredAura(unit, config)
	if not config then
		return false
	end

	local function CheckAuraName(auraName)
		if not auraName or auraName == "" then
			return false
		end

		if UnitHasNamedAura(unit, auraName) then
			return true
		end

		for auraPart in string.gmatch(auraName, "([^,;]+)") do
			local trimmedAuraName = string.gsub(auraPart, "^%s*(.-)%s*$", "%1")
			if trimmedAuraName ~= auraName and trimmedAuraName ~= "" and UnitHasNamedAura(unit, trimmedAuraName) then
				return true
			end
		end

		return false
	end

	if CheckAuraName(config.aura) or CheckAuraName(config.cast) then
		return true
	end

	if config.auraAliases then
		for _, auraName in ipairs(config.auraAliases) do
			if CheckAuraName(auraName) then
				return true
			end
		end
	end

	return false
end

local function SpellCooldownActive(spellName)
	if not spellName or spellName == "" or not GetSpellCooldown then
		return false
	end

	local start, duration, enabled = GetSpellCooldown(spellName)
	if enabled == 0 then
		return true
	end
	if start and duration and start > 0 and duration > 1.5 then
		return true
	end

	return false
end

local function GetUnitRole(unit, raidIndex)
	if UnitGroupRolesAssigned then
		local role = UnitGroupRolesAssigned(unit)
		if role and role ~= "NONE" then
			return role
		end
	end

	if GetPartyAssignment and GetPartyAssignment("MAINTANK", unit) then
		return "TANK"
	end

	if raidIndex and GetRaidRosterInfo then
		local role = select(10, GetRaidRosterInfo(raidIndex))
		if role == "TANK" or role == "MAINTANK" then
			return "TANK"
		end
	end

	return "DAMAGER"
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
			unit = unit,
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

function Underheal:GetRaidMemberBounds()
	local frames = self:GetRaidMemberFrames()
	local left, right, top

	for _, info in ipairs(frames) do
		local frame = info.frame
		if frame and frame:IsShown() and frame:GetLeft() and frame:GetRight() and frame:GetTop() then
			left = left and math.min(left, frame:GetLeft()) or frame:GetLeft()
			right = right and math.max(right, frame:GetRight()) or frame:GetRight()
			top = top and math.max(top, frame:GetTop()) or frame:GetTop()
		end
	end

	if not left or not right or not top then
		return nil
	end

	return {
		center = left + ((right - left) / 2),
		top = top,
		left = left,
		right = right,
	}
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

function Underheal:BuffAppliesToUnit(config, unit, raidIndex)
	if not config or not config.enabled or not unit or not UnitExists(unit) then
		return false
	end

	local _, classFile = UnitClass(unit)
	if config.classes and classFile and not config.classes[classFile] then
		return false
	end

	return true
end

function Underheal:BuffWarningAvailable(config)
	if not config then
		return false
	end

	if config.hideWarningOnCooldown and SpellCooldownActive(config.cast) then
		return false
	end

	return true
end

function Underheal:GetBuffButtonColor(config, unit, raidIndex)
	if not self:BuffAppliesToUnit(config, unit, raidIndex) then
		return 0.02, 0.08, 0.03, 0.35
	end

	if UnitHasConfiguredAura(unit, config) or not self:BuffWarningAvailable(config) then
		return 0.0, 0.45, 0.0, 0.55
	end

	local role = GetUnitRole(unit, raidIndex)
	local color = config.missingColor
	if config.priorityRoles and config.priorityRoles[role] and config.priorityColor then
		color = config.priorityColor
	end

	return color.r, color.g, color.b, 0.95
end

function Underheal:GetBestMissingBuffConfig(unit, raidIndex)
	local role = GetUnitRole(unit, raidIndex)
	local bestConfig
	local bestScore = -1

	for index, config in ipairs(UnderhealDB.buffButtons) do
		if config and config.enabled and config.cast ~= "" and self:BuffAppliesToUnit(config, unit, raidIndex) and self:BuffWarningAvailable(config) and not UnitHasConfiguredAura(unit, config) then
			local score = config.clickPriority or (100 - index)
			if config.priorityRoles and config.priorityRoles[role] then
				score = score + 10000
			end
			if score > bestScore then
				bestScore = score
				bestConfig = config
			end
		end
	end

	return bestConfig
end

function Underheal:GetClickBuffConfig(unit, raidIndex)
	if not UnderhealDB.raidFrame.clickToBuff then
		return nil
	end

	local config = self:GetBestMissingBuffConfig(unit, raidIndex)
	if InCombatLockdown() and config and config.key ~= "fearward" then
		return nil
	end

	return config
end

function Underheal:BuildClickCastMacro(unit, spell, useTrinkets)
	local lines = {}
	if useTrinkets then
		lines[#lines + 1] = "/use 13"
		lines[#lines + 1] = "/use 14"
	end
	lines[#lines + 1] = "/cast [@" .. unit .. "] " .. spell
	return table.concat(lines, "\n")
end

function Underheal:BuildClickBuffMacro(unit, buffSpell)
	local leftConfig = UnderhealDB.clickCasts.none or {}
	local fallbackSpell = leftConfig.left or ""
	local lines = {}

	if fallbackSpell ~= "" and leftConfig.useTrinkets then
		lines[#lines + 1] = "/use [combat] 13"
		lines[#lines + 1] = "/use [combat] 14"
	end

	if fallbackSpell ~= "" then
		lines[#lines + 1] = "/cast [nocombat,@" .. unit .. "] " .. buffSpell .. "; [@" .. unit .. "] " .. fallbackSpell
	else
		lines[#lines + 1] = "/cast [nocombat,@" .. unit .. "] " .. buffSpell
	end

	return table.concat(lines, "\n")
end

function Underheal:SetClickCastAttributes(button, unit)
	if InCombatLockdown() then
		return
	end

	button:SetAttribute("type", nil)
	button:SetAttribute("spell", nil)
	button:SetAttribute("unit", nil)
	button:SetAttribute("unit", unit)

	for _, entry in ipairs(CLICK_CAST_ORDER) do
		local config = UnderhealDB.clickCasts[entry.key]
		local prefix = entry.prefix
		local leftSpell = config and config.left or ""
		local rightSpell = config and config.right or ""
		local useTrinkets = config and config.useTrinkets

		if leftSpell and leftSpell ~= "" then
			if useTrinkets then
				button:SetAttribute(prefix .. "type1", "macro")
				button:SetAttribute(prefix .. "macrotext1", self:BuildClickCastMacro(unit, leftSpell, true))
			else
				button:SetAttribute(prefix .. "type1", "spell")
				button:SetAttribute(prefix .. "spell1", leftSpell)
				button:SetAttribute(prefix .. "unit1", unit)
			end
		else
			button:SetAttribute(prefix .. "type1", nil)
			button:SetAttribute(prefix .. "spell1", nil)
			button:SetAttribute(prefix .. "macrotext1", nil)
			button:SetAttribute(prefix .. "unit1", nil)
		end

		if rightSpell and rightSpell ~= "" then
			if useTrinkets then
				button:SetAttribute(prefix .. "type2", "macro")
				button:SetAttribute(prefix .. "macrotext2", self:BuildClickCastMacro(unit, rightSpell, true))
			else
				button:SetAttribute(prefix .. "type2", "spell")
				button:SetAttribute(prefix .. "spell2", rightSpell)
				button:SetAttribute(prefix .. "unit2", unit)
			end
		else
			button:SetAttribute(prefix .. "type2", nil)
			button:SetAttribute(prefix .. "spell2", nil)
			button:SetAttribute(prefix .. "macrotext2", nil)
			button:SetAttribute(prefix .. "unit2", nil)
		end
	end
end

function Underheal:GetRaidBuffButton(frame, index)
	frame.UnderhealBuffButtons = frame.UnderhealBuffButtons or {}
	if frame.UnderhealBuffButtons[index] then
		return frame.UnderhealBuffButtons[index]
	end

	local button = CreateFrame("Button", nil, frame, "SecureActionButtonTemplate")
	button:SetSize(14, 14)
	button:RegisterForClicks("AnyUp")
	button:SetScript("OnEnter", function(self)
		if not self.UnderhealBuffConfig then
			return
		end

		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(self.UnderhealBuffConfig.cast or "Buff")
		GameTooltip:AddLine("Click to cast on this raid member.", 1, 1, 1)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	local bg = button:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0.02, 0.08, 0.03, 0.88)
	button.bg = bg

	local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	text:SetPoint("CENTER", 0, 0)
	button.text = text

	frame.UnderhealBuffButtons[index] = button
	return button
end

function Underheal:GetRaidClickBuffButton(frame)
	if frame.UnderhealClickBuffButton then
		return frame.UnderhealClickBuffButton
	end

	local button = CreateFrame("Button", nil, frame, "SecureActionButtonTemplate")
	button:SetAllPoints(frame)
	button:RegisterForClicks("AnyUp")
	button:SetFrameLevel(frame:GetFrameLevel() + 8)
	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if self.UnderhealBuffConfig then
			GameTooltip:SetText(self.UnderhealBuffConfig.cast or "Buff")
			GameTooltip:AddLine("Left click will buff this player.", 1, 1, 1)
		else
			GameTooltip:SetText("Underheal click-cast")
			GameTooltip:AddLine("Use configured clicks on this player.", 1, 1, 1)
		end
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	button:Hide()

	frame.UnderhealClickBuffButton = button
	return button
end

function Underheal:HideClickBuffButtonOnFrame(frame)
	if frame and frame.UnderhealClickBuffButton then
		frame.UnderhealClickBuffButton:Hide()
	end
end

function Underheal:HideSideBuffButtonsOnFrame(frame)
	if not frame or not frame.UnderhealBuffButtons then
		return
	end

	for _, button in ipairs(frame.UnderhealBuffButtons) do
		button:Hide()
	end
end

function Underheal:HideBuffButtonsOnFrame(frame)
	self:HideSideBuffButtonsOnFrame(frame)
	self:HideClickBuffButtonOnFrame(frame)
end

function Underheal:ApplyBuffButtonsToFrame(frame)
	if not frame then
		self:HideBuffButtonsOnFrame(frame)
		return
	end

	local unit = frame.unit or frame.displayedUnit or frame:GetAttribute("unit")
	if not unit or not UnitExists(unit) then
		self:HideBuffButtonsOnFrame(frame)
		return
	end

	local raidIndex = UnitInRaid(unit)
	if not raidIndex then
		raidIndex = tonumber(string.match(unit, "^raid(%d+)$"))
	end

	local clickConfig = self:GetClickBuffConfig(unit, raidIndex)
	local clickButton = self:GetRaidClickBuffButton(frame)
	self:SetClickCastAttributes(clickButton, unit)
	clickButton.UnderhealBuffConfig = clickConfig
	if clickConfig and not InCombatLockdown() then
		if clickConfig.key == "fearward" then
			clickButton:SetAttribute("type1", "spell")
			clickButton:SetAttribute("spell1", clickConfig.cast)
			clickButton:SetAttribute("macrotext1", nil)
			clickButton:SetAttribute("unit", unit)
			clickButton:SetAttribute("unit1", unit)
		else
			clickButton:SetAttribute("type1", "macro")
			clickButton:SetAttribute("spell1", nil)
			clickButton:SetAttribute("unit1", nil)
			clickButton:SetAttribute("macrotext1", self:BuildClickBuffMacro(unit, clickConfig.cast))
		end
	end
	clickButton:Show()

	if not UnderhealDB.raidFrame.showBuffButtons then
		self:HideSideBuffButtonsOnFrame(frame)
		return
	end

	local visibleIndex = 0
	for index, config in ipairs(UnderhealDB.buffButtons) do
		local button = self:GetRaidBuffButton(frame, index)
		if not config or not config.enabled or config.cast == "" or not self:BuffAppliesToUnit(config, unit, raidIndex) then
			button:Hide()
		else
			visibleIndex = visibleIndex + 1
			button:ClearAllPoints()
			button:SetPoint("TOPRIGHT", frame, "TOPLEFT", -3, -((visibleIndex - 1) * 16))
			button.UnderhealBuffConfig = config

			if not InCombatLockdown() then
				button:SetAttribute("type", "spell")
				button:SetAttribute("type1", "spell")
				button:SetAttribute("spell", config.cast)
				button:SetAttribute("unit", unit)
			end

			local r, g, b, a = self:GetBuffButtonColor(config, unit, raidIndex)
			button.bg:SetColorTexture(r, g, b, a)
			button.text:SetText(config.label or "?")
			button:Show()
		end
	end
end

function Underheal:ApplyBuffButtons()
	if InCombatLockdown() then
		self.pendingBuffButtons = true
		return
	end

	local frames = self:GetRaidMemberFrames()
	for _, info in ipairs(frames) do
		if IsDiscreteGroupMemberFrame(info.frame) or not self:HasDiscreteGroupMembers() then
			self:ApplyBuffButtonsToFrame(info.frame)
		else
			self:HideBuffButtonsOnFrame(info.frame)
		end
	end
end

function Underheal:HideUnderhealRaidOverlays()
	if InCombatLockdown() then
		self.pendingDisableCleanup = true
		return
	end

		local frames = self:GetRaidMemberFrames()
		for _, info in ipairs(frames) do
			self:HideBuffButtonsOnFrame(info.frame)
			if info.frame.UnderhealThreatBar then
				info.frame.UnderhealThreatBar:Hide()
			end
			if info.frame.UnderhealThreatBorder then
				info.frame.UnderhealThreatBorder:Hide()
			end
			if info.frame.UnderhealThreatTankIcon then
				info.frame.UnderhealThreatTankIcon:Hide()
			end
		end
	end

function Underheal:EnsureThreatWidgets(frame)
	if not frame or frame.UnderhealThreatBar then
		return
	end

	local bar = frame:CreateTexture(nil, "OVERLAY")
	bar:SetPoint("LEFT", frame, "LEFT", 2, 0)
	bar:SetHeight(10)
	bar:SetColorTexture(1, 0, 0, 0.72)
	bar:Hide()
	frame.UnderhealThreatBar = bar

	local border = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
	border:SetPoint("TOPLEFT", frame, "TOPLEFT", -5, 5)
	border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 5, -5)
	border:SetFrameLevel(frame:GetFrameLevel() + 6)
	if border.SetBackdrop then
		border:SetBackdrop({
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 28,
			insets = { left = 5, right = 5, top = 5, bottom = 5 },
		})
		border:SetBackdropBorderColor(1, 0, 0, 0.95)
	end
	border:Hide()
	frame.UnderhealThreatBorder = border

	local tankIcon = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	tankIcon:SetPoint("CENTER", frame, "CENTER", 0, 0)
	tankIcon:SetText("T")
	tankIcon:SetTextColor(1, 0.08, 0.08, 0.95)
	tankIcon:SetShadowColor(0, 0, 0, 1)
	tankIcon:SetShadowOffset(1, -1)
	tankIcon:Hide()
	frame.UnderhealThreatTankIcon = tankIcon

	if not frame.UnderhealThreatFlashHooked then
		frame:HookScript("OnUpdate", function(self)
			if not self.UnderhealThreatFlashUntil or not self.UnderhealThreatBorder then
				return
			end

			local remaining = self.UnderhealThreatFlashUntil - GetTime()
			if remaining <= 0 then
				self.UnderhealThreatFlashUntil = nil
				if self.UnderhealThreatTopRank then
					self.UnderhealThreatBorder:SetBackdropBorderColor(1, 0, 0, 0.95)
					self.UnderhealThreatBorder:Show()
				else
					self.UnderhealThreatBorder:Hide()
				end
				return
			end

			local alpha = 0.25 + (math.abs(math.sin(GetTime() * 12)) * 0.75)
			self.UnderhealThreatBorder:SetBackdropBorderColor(1, 0, 0, alpha)
			self.UnderhealThreatBorder:Show()
		end)
		frame.UnderhealThreatFlashHooked = true
	end
end

function Underheal:EnsureIncomingHealWidgets(frame)
	if not frame or frame.UnderhealIncomingBar then
		return
	end
	if InCombatLockdown() then
		return
	end

	local bar = frame:CreateTexture(nil, "OVERLAY")
	bar:SetHeight(8)
	bar:SetColorTexture(0.15, 0.95, 1.0, 0.62)
	bar:Hide()
	frame.UnderhealIncomingBar = bar

	local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	text:SetPoint("BOTTOM", frame, "BOTTOM", 0, 2)
	text:SetTextColor(0.45, 1.0, 1.0, 0.95)
	text:SetShadowColor(0, 0, 0, 1)
	text:SetShadowOffset(1, -1)
	text:Hide()
	frame.UnderhealIncomingText = text

	if not frame.UnderhealIncomingHooked then
		frame:HookScript("OnUpdate", function(self, elapsed)
			self.UnderhealIncomingElapsed = (self.UnderhealIncomingElapsed or 0) + elapsed
			if self.UnderhealIncomingElapsed < 0.2 then
				return
			end

			self.UnderhealIncomingElapsed = 0
			local unit = self.unit or self.displayedUnit or (self.GetAttribute and self:GetAttribute("unit"))
			if unit and UnitExists(unit) then
				Underheal:UpdateIncomingHealFrame(self, unit)
			elseif self.UnderhealIncomingBar then
				self.UnderhealIncomingBar:Hide()
				self.UnderhealIncomingText:Hide()
			end
		end)
		frame.UnderhealIncomingHooked = true
	end
end

function Underheal:GetRemoteIncomingHeal(unit)
	if not unit or not UnitExists(unit) then
		return 0, nil
	end

	self.remoteIncomingHeals = self.remoteIncomingHeals or {}
	local guid = UnitGUID(unit)
	if not guid then
		return 0, nil
	end
	local heals = self.remoteIncomingHeals[guid]

	local now = GetTime()
	local count = 0
	local label
	if self.outgoingHealTargetGUID == guid then
		local _, _, _, _, endTimeMS = UnitCastingInfo("player")
		local endTime = endTimeMS and (endTimeMS / 1000)
		if endTime and endTime > now then
			count = count + 1
			label = self.outgoingHealSpell or "heal"
		end
	end

	if heals then
		for caster, info in pairs(heals) do
			if not info.endTime or info.endTime <= now then
				heals[caster] = nil
			else
				count = count + 1
				label = info.spell or "heal"
			end
		end
	end

	if count == 0 then
		if heals then
			self.remoteIncomingHeals[guid] = nil
		end
		return 0, nil
	end

	local healthMax = UnitHealthMax(unit) or 0
	local missing = math.max(0, healthMax - (UnitHealth(unit) or 0))
	return math.min(missing, healthMax * 0.25 * count), label
end

function Underheal:UpdateIncomingHealFrame(frame, unit)
	if not frame or not unit or not UnitExists(unit) then
		return
	end

	self:EnsureIncomingHealWidgets(frame)
	if not frame.UnderhealIncomingBar then
		return
	end

	local healthMax = UnitHealthMax(unit) or 0
	if healthMax <= 0 then
		frame.UnderhealIncomingBar:Hide()
		frame.UnderhealIncomingText:Hide()
		return
	end

	local healthCurrent = UnitHealth(unit) or 0
	local incoming = 0
	if UnitGetIncomingHeals then
		incoming = UnitGetIncomingHeals(unit) or 0
	end

	local remoteIncoming, remoteLabel = self:GetRemoteIncomingHeal(unit)
	if incoming <= 0 then
		incoming = remoteIncoming
	end

	local missing = math.max(0, healthMax - healthCurrent)
	incoming = math.min(incoming or 0, missing)
	if incoming <= 0 then
		frame.UnderhealIncomingBar:Hide()
		frame.UnderhealIncomingText:Hide()
		return
	end

	local width = math.max(1, (frame:GetWidth() or 72) - 4)
	local currentWidth = math.min(width, width * (healthCurrent / healthMax))
	local incomingWidth = math.max(2, width * (incoming / healthMax))

	frame.UnderhealIncomingBar:ClearAllPoints()
	frame.UnderhealIncomingBar:SetPoint("LEFT", frame, "LEFT", 2 + currentWidth, 0)
	frame.UnderhealIncomingBar:SetWidth(math.min(incomingWidth, width - currentWidth))
	frame.UnderhealIncomingBar:Show()

	if UnitGetIncomingHeals and UnitGetIncomingHeals(unit) and UnitGetIncomingHeals(unit) > 0 then
		frame.UnderhealIncomingText:SetText("+" .. math.floor(UnitGetIncomingHeals(unit) + 0.5))
	else
		frame.UnderhealIncomingText:SetText(remoteLabel or "incoming")
	end
	frame.UnderhealIncomingText:Show()
end

function Underheal:RefreshIncomingHeals()
	local frames = self:GetRaidMemberFrames()
	for _, info in ipairs(frames) do
		local frame = info.frame
		local unit = info.unit or frame.unit or frame.displayedUnit or (frame.GetAttribute and frame:GetAttribute("unit"))
		if frame and unit and UnitExists(unit) then
			self:UpdateIncomingHealFrame(frame, unit)
		end
	end

	if self.tankWatch and self.tankWatch.buttons then
		for _, button in ipairs(self.tankWatch.buttons) do
			if button:IsShown() then
				local unit = button:GetAttribute("unit")
				if unit and UnitExists(unit) then
					self:UpdateIncomingHealFrame(button, unit)
				end
			end
		end
	end

	if self.petWatch and self.petWatch.buttons then
		for _, button in ipairs(self.petWatch.buttons) do
			if button:IsShown() then
				local unit = button:GetAttribute("unit")
				if unit and UnitExists(unit) then
					self:UpdateIncomingHealFrame(button, unit)
				end
			end
		end
	end
end

function Underheal:ClearThreatIndicators()
	local frames = self:GetRaidMemberFrames()
	for _, info in ipairs(frames) do
		local frame = info.frame
		if frame then
				frame.UnderhealThreatTopRank = nil
				if frame.UnderhealThreatBar then
					frame.UnderhealThreatBar:Hide()
				end
				if frame.UnderhealThreatTankIcon then
					frame.UnderhealThreatTankIcon:Hide()
				end
			if frame.UnderhealThreatBorder and not frame.UnderhealThreatFlashUntil then
				frame.UnderhealThreatBorder:Hide()
			end
		end
	end
end

function Underheal:UpdateThreatIndicators()
	if not UnderhealDB.raidFrame.showThreat or not UnitDetailedThreatSituation then
		self:ClearThreatIndicators()
		return
	end

	local target = GetThreatTargetUnit()
	if not target then
		self.threatTargetGUID = nil
		self:ClearThreatIndicators()
		return
	end

	local frames = self:GetRaidMemberFrames()
	if self.tankWatch and self.tankWatch.buttons then
		for _, button in ipairs(self.tankWatch.buttons) do
			if button:IsShown() then
				local unit = button:GetAttribute("unit")
				if unit and UnitExists(unit) then
					frames[#frames + 1] = {
						frame = button,
						unit = unit,
						raidIndex = UnitInRaid(unit),
					}
				end
			end
		end
	end

	local targetGUID = UnitGUID(target)
	if targetGUID ~= self.threatTargetGUID then
		self.threatTargetGUID = targetGUID
		for _, info in ipairs(frames) do
			if info.frame then
				info.frame.UnderhealWasTanking = nil
				info.frame.UnderhealThreatFlashUntil = nil
			end
		end
	end

	local entries = {}
	local maxThreat = 0

	for _, info in ipairs(frames) do
		local frame = info.frame
		if frame and (IsDiscreteGroupMemberFrame(frame) or not self:HasDiscreteGroupMembers()) then
				local unit = info.unit or frame.unit or frame.displayedUnit or frame:GetAttribute("unit")
			if unit and UnitExists(unit) then
				local isTanking, _, threatPct, rawThreatPct, threatValue = UnitDetailedThreatSituation(unit, target)
				local value = threatValue or rawThreatPct or threatPct or 0
				if value and value > 0 then
					maxThreat = math.max(maxThreat, value)
					entries[#entries + 1] = {
						frame = frame,
						unit = unit,
						value = value,
						isTanking = isTanking,
					}
				end
			end
		end
	end

	if maxThreat <= 0 then
		self:ClearThreatIndicators()
		return
	end

	table.sort(entries, function(a, b)
		return a.value > b.value
	end)

	local topFrames = {}
	for rank = 1, math.min(5, #entries) do
		topFrames[entries[rank].frame] = true
	end

	for _, info in ipairs(frames) do
		local frame = info.frame
		if frame then
			self:EnsureThreatWidgets(frame)
			frame.UnderhealThreatTopRank = topFrames[frame]
				if frame.UnderhealThreatBar then
					frame.UnderhealThreatBar:Hide()
				end
				if frame.UnderhealThreatTankIcon then
					frame.UnderhealThreatTankIcon:Hide()
				end
			if frame.UnderhealThreatBorder and not frame.UnderhealThreatFlashUntil then
				frame.UnderhealThreatBorder:Hide()
			end
		end
	end

	for _, entry in ipairs(entries) do
		local frame = entry.frame
		self:EnsureThreatWidgets(frame)

		local width = math.max(1, (frame:GetWidth() or 72) - 4)
		local ratio = math.min(1, entry.value / maxThreat)
		frame.UnderhealThreatBar:SetWidth(math.max(1, width * ratio))
		frame.UnderhealThreatBar:Show()

		if entry.isTanking and not frame.UnderhealWasTanking then
			frame.UnderhealThreatFlashUntil = GetTime() + 3
		end
		frame.UnderhealWasTanking = entry.isTanking

		if frame.UnderhealThreatTankIcon then
			if entry.isTanking then
				frame.UnderhealThreatTankIcon:Show()
			else
				frame.UnderhealThreatTankIcon:Hide()
			end
		end

		if frame.UnderhealThreatTopRank and frame.UnderhealThreatBorder and not frame.UnderhealThreatFlashUntil then
			frame.UnderhealThreatBorder:SetBackdropBorderColor(1, 0, 0, 0.95)
			frame.UnderhealThreatBorder:Show()
		end
	end
end

function Underheal:SkinRaidMemberFrame(frame)
	if not frame or not UnderhealDB.raidFrame.skinRaidFrames then
		return
	end

	self:EnsureThreatWidgets(frame)

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
			local raidIndex
			if unit and UnitExists(unit) then
				local healthMax = UnitHealthMax(unit)
				if healthMax and healthMax > 0 then
					healthPercent = UnitHealth(unit) / healthMax
				end
				raidIndex = UnitInRaid(unit)
				if not raidIndex then
					raidIndex = tonumber(string.match(unit, "^raid(%d+)$"))
				end
			end

			local r, g, b = GetHealthColor(healthPercent)
			local missingBuffConfig
			if unit and UnitExists(unit) then
				missingBuffConfig = self:GetBestMissingBuffConfig(unit, raidIndex)
			end
			if missingBuffConfig and healthPercent >= 0.1 then
				r, g, b = self:GetBuffButtonColor(missingBuffConfig, unit, raidIndex)
			end
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

		if unit and UnitExists(unit) then
			self:UpdateIncomingHealFrame(frame, unit)
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

	self:ApplyBuffButtons()
	self:UpdateThreatIndicators()
	self:RefreshIncomingHeals()
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

	frame:SetScale(GetRaidFrameScale())

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
	local scale = GetRaidFrameScale()
	frame:SetScale(scale)
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", UnderhealDB.pets.x / scale, UnderhealDB.pets.y / scale)
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
			self:UpdateIncomingHealFrame(button, unit)
		button:Show()
	end

	for index = #pets + 1, #frame.buttons do
		frame.buttons[index]:SetAttribute("unit", nil)
		if frame.buttons[index].UnderhealIncomingBar then
			frame.buttons[index].UnderhealIncomingBar:Hide()
		end
		if frame.buttons[index].UnderhealIncomingText then
			frame.buttons[index].UnderhealIncomingText:Hide()
		end
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

	local dragLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	dragLabel:SetPoint("TOPRIGHT", -8, -7)
	dragLabel:SetText("drag")
	dragLabel:SetTextColor(0.45, 1.0, 1.0)
	dragLabel:Hide()
	frame.dragLabel = dragLabel

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

	self:EnsureThreatWidgets(button)

	frame.buttons[index] = button
	return button
end

function Underheal:PositionTankWatchFrame()
	local frame = self:GetTankWatchFrame()
	frame:SetScale(1)
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", UnderhealDB.tanks.x, UnderhealDB.tanks.y)
end

function Underheal:UpdateTankDragState()
	local frame = self.tankWatch
	if not frame then
		return
	end

	if UnderhealDB.raidFrame.unlocked then
		if frame.dragLabel then
			frame.dragLabel:Show()
		end
		if frame.SetBackdropBorderColor then
			frame:SetBackdropBorderColor(0.95, 0.85, 0.25, 1)
		end
	else
		if frame.dragLabel then
			frame.dragLabel:Hide()
		end
		if frame.SetBackdropBorderColor then
			frame:SetBackdropBorderColor(0.35, 0.65, 0.75, 0.9)
		end
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
		self:UpdateClickBuffToggleButton()
		return
	end

	frame:SetHeight(36 + (#tanks * 28))
	frame:SetWidth(TANK_BUTTON_WIDTH + 16)
	frame:SetScale(1)
	self:PositionTankWatchFrame()
	self:UpdateTankDragState()
	frame:Show()
	self:UpdateClickBuffToggleButton()

	for index, unit in ipairs(tanks) do
		local button = self:GetTankButton(index)
		self:EnsureThreatWidgets(button)
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
		self:UpdateIncomingHealFrame(button, unit)
		button:Show()
	end

	for index = #tanks + 1, #frame.buttons do
		frame.buttons[index].flashHealth = false
		frame.buttons[index].health:SetAlpha(1)
		frame.buttons[index].bg:SetColorTexture(0.02, 0.08, 0.03, 0.88)
		if frame.buttons[index].UnderhealThreatBar then
			frame.buttons[index].UnderhealThreatBar:Hide()
		end
		if frame.buttons[index].UnderhealThreatBorder then
			frame.buttons[index].UnderhealThreatBorder:Hide()
		end
		if frame.buttons[index].UnderhealThreatTankIcon then
			frame.buttons[index].UnderhealThreatTankIcon:Hide()
		end
		if frame.buttons[index].UnderhealIncomingBar then
			frame.buttons[index].UnderhealIncomingBar:Hide()
		end
		if frame.buttons[index].UnderhealIncomingText then
			frame.buttons[index].UnderhealIncomingText:Hide()
		end
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
			Underheal:UpdateClickBuffToggleButton()
		end)
		self.raidLayoutHooked = true
	end
end

function Underheal:GetClickBuffToggleButton()
	if self.clickBuffToggleButton then
		return self.clickBuffToggleButton
	end

	local button = CreateFrame("Button", "UnderhealClickBuffToggle", UIParent, "UIPanelButtonTemplate")
	button:SetSize(190, 22)
	button:SetFrameStrata("DIALOG")
	button:SetFrameLevel(60)
	button:SetClampedToScreen(true)
	button:SetMovable(true)
	button:RegisterForDrag("LeftButton")
	button:SetScript("OnDragStart", function(self)
		if UnderhealDB.raidFrame.unlocked and not InCombatLockdown() then
			self:StartMoving()
		end
	end)
	button:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		if self:GetLeft() and self:GetTop() then
			UnderhealDB.clickBuffButton.x = self:GetLeft()
			UnderhealDB.clickBuffButton.y = self:GetTop()
			UnderhealDB.clickBuffButton.hasPosition = true
		end
	end)
	button:SetScript("OnClick", function()
		UnderhealDB.raidFrame.clickToBuff = not UnderhealDB.raidFrame.clickToBuff
		Underheal:UpdateClickBuffToggleButton()
		Underheal:ApplyBuffButtons()
		Underheal:RefreshOptions()
	end)
	button:Hide()

	self.clickBuffToggleButton = button
	return button
end

function Underheal:UpdateClickBuffToggleDragState()
	local button = self.clickBuffToggleButton
	if not button then
		return
	end

	if UnderhealDB.raidFrame.unlocked then
		button:SetAlpha(1)
	else
		button:SetAlpha(0.92)
	end
end

function Underheal:UpdateClickBuffToggleButton()
	local button = self:GetClickBuffToggleButton()
	button:SetScale(1)
	button:ClearAllPoints()

	if not ((IsInGroup and IsInGroup()) or (IsInRaid and IsInRaid())) then
		button:Hide()
		return
	end

	button:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", UnderhealDB.clickBuffButton.x, UnderhealDB.clickBuffButton.y)

	button:SetText((UnderhealDB.raidFrame.clickToBuff and "Disable" or "Enable") .. " Click to Buff")
	self:UpdateClickBuffToggleDragState()
	button:Show()
end

function Underheal:DisableForNonHealer()
	self.disabledForNonHealer = true
	self.raidCombatWasClear = nil
	self.pendingApply = nil
	self.pendingUnlock = nil
	self.pendingGroupProfile = nil
	self.pendingGroupMarkers = nil
	self.pendingBuffButtons = nil
	self.pendingPetUpdate = nil
	self.pendingTankUpdate = nil

	if self.optionsFrame then
		self.optionsFrame:Hide()
	end
	if self.buffOptionsFrame then
		self.buffOptionsFrame:Hide()
	end
	if self.clickCastOptionsFrame then
		self.clickCastOptionsFrame:Hide()
	end
	if self.mover then
		self.mover:Hide()
	end
	if self.clickBuffToggleButton then
		self.clickBuffToggleButton:Hide()
	end
	if self.petWatch then
		self.petWatch:Hide()
	end
	if self.tankWatch then
		self.tankWatch:Hide()
	end

	self:HideUnderhealRaidOverlays()

	if not self.nonHealerMessageShown then
		Print("Disabled on this character because this class is not a healer.")
		self.nonHealerMessageShown = true
	end
end

function Underheal:RefreshPullAnnounceState()
	self.raidCombatWasClear = IsRaidCombatClear()
end

function Underheal:AnnouncePull(unit)
	if not unit or not UnitExists(unit) then
		return
	end

	self.raidCombatWasClear = false

	local name = UnitName(unit)
	if not name or name == "" then
		name = "Someone"
	end

	SendChatMessage(name .. " pulled!", "OFFICER")
end

function Underheal:CheckPullAnnounce(unit)
	if not IsRaidUnit(unit) then
		return
	end

	if not self.raidCombatWasClear then
		if IsRaidCombatClear() then
			self.raidCombatWasClear = true
		end
		return
	end

	if not UnitAffectingCombat(unit) then
		return
	end

	self:AnnouncePull(unit)
end

function Underheal:PollPullAnnounce(elapsed)
	self.pullPollElapsed = (self.pullPollElapsed or 0) + elapsed
	if self.pullPollElapsed < 0.15 then
		return
	end
	self.pullPollElapsed = 0

	if self.disabledForNonHealer or not ((IsInGroup and IsInGroup()) or (IsInRaid and IsInRaid())) then
		self.raidCombatWasClear = nil
		return
	end

	if not self.raidCombatWasClear then
		if IsRaidCombatClear() then
			self.raidCombatWasClear = true
		end
		return
	end

	for _, unit in ipairs(GetRaidUnits()) do
		if UnitAffectingCombat(unit) then
			self:AnnouncePull(unit)
			return
		end
	end
end

function Underheal:RegisterAddonComms()
	if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
		C_ChatInfo.RegisterAddonMessagePrefix(COMM_PREFIX)
	elseif RegisterAddonMessagePrefix then
		RegisterAddonMessagePrefix(COMM_PREFIX)
	end
end

function Underheal:SendHealStart(targetUnit, spellName)
	if not targetUnit or not UnitExists(targetUnit) or not IsHealingSpell(spellName) then
		return
	end

	local targetGUID = UnitGUID(targetUnit)
	if not targetGUID then
		return
	end

	local _, _, _, _, endTimeMS = UnitCastingInfo("player")
	local endTime = endTimeMS and (endTimeMS / 1000) or (GetTime() + 2.5)
	self.outgoingHealTargetGUID = targetGUID
	self.outgoingHealSpell = spellName

	SendUnderhealAddonMessage("HSTART\t" .. targetGUID .. "\t" .. spellName .. "\t" .. string.format("%.2f", endTime))
	self:RefreshIncomingHeals()
end

function Underheal:SendHealStop()
	if not self.outgoingHealTargetGUID then
		return
	end

	SendUnderhealAddonMessage("HSTOP\t" .. self.outgoingHealTargetGUID)
	self.outgoingHealTargetGUID = nil
	self.outgoingHealSpell = nil
	self:RefreshIncomingHeals()
end

function Underheal:HandleSpellcastSent(unit, first, second, third)
	if unit ~= "player" then
		return
	end

	if IsHealingSpell(first) then
		self.pendingHealSpell = first
		self.pendingHealTargetName = third
	else
		self.pendingHealTargetName = first
	end
end

function Underheal:HandleSpellcastStart(unit)
	if unit ~= "player" then
		return
	end

	local spellName = UnitCastingInfo("player") or self.pendingHealSpell
	if not IsHealingSpell(spellName) then
		return
	end

	local targetUnit = FindGroupUnitByName(self.pendingHealTargetName)
	if not targetUnit and UnitExists("target") and UnitCanAssist("player", "target") then
		targetUnit = "target"
	end
	if not targetUnit and UnitExists("mouseover") and UnitCanAssist("player", "mouseover") then
		targetUnit = "mouseover"
	end

	self:SendHealStart(targetUnit, spellName)
end

function Underheal:HandleAddonMessage(prefix, message, _, sender)
	if prefix ~= COMM_PREFIX or not message or GetShortName(sender) == GetShortName(UnitName("player")) then
		return
	end

	local command, rest = string.match(message, "^(%S+)%s*(.*)$")
	if command == "HSTART" then
		local targetGUID, spellName, endTimeText = string.match(rest, "^([^\t]+)\t([^\t]+)\t([^\t]+)")
		if not targetGUID or not spellName then
			return
		end

		self.remoteIncomingHeals = self.remoteIncomingHeals or {}
		self.remoteIncomingHeals[targetGUID] = self.remoteIncomingHeals[targetGUID] or {}
		self.remoteIncomingHeals[targetGUID][sender or "unknown"] = {
			spell = spellName,
			endTime = tonumber(endTimeText) or (GetTime() + 2.5),
		}
		self:RefreshIncomingHeals()
	elseif command == "HSTOP" then
		local targetGUID = string.match(rest, "^([^\t]+)")
		if targetGUID and self.remoteIncomingHeals and self.remoteIncomingHeals[targetGUID] then
			self.remoteIncomingHeals[targetGUID][sender or "unknown"] = nil
			self:RefreshIncomingHeals()
		end
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
		Underheal:PositionTankWatchFrame()
		Underheal:UpdateClickBuffToggleButton()
	end)

	mover:SetScript("OnUpdate", function()
		if Underheal.moving then
			Underheal:ApplyRaidFramePosition()
			Underheal:PositionTankWatchFrame()
			Underheal:UpdateClickBuffToggleButton()
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

	local scale = GetRaidFrameScale()

	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", UnderhealDB.raidFrame.x / scale, UnderhealDB.raidFrame.y / scale)
	frame:Show()
	self:PositionTankWatchFrame()
	self:UpdateClickBuffToggleButton()

	return true
end

function Underheal:ApplyRaidFrameScale()
	if InCombatLockdown() then
		self.pendingScale = true
		return false
	end

	local frame = GetRaidFrame()
	if not frame then
		return false
	end

	local scale = GetRaidFrameScale()
	UnderhealDB.raidFrame.scale = scale

	frame:SetScale(scale)
	self:ApplyRaidFramePosition()
	self:UpdateClickBuffToggleButton()
	self:UpdateTankWatch()
	self:UpdatePetWatch()
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
		container:SetScale(GetRaidFrameScale())
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
	self.optionsFrame.buffCheck:SetChecked(UnderhealDB.raidFrame.showBuffButtons)
	self.optionsFrame.clickBuffCheck:SetChecked(UnderhealDB.raidFrame.clickToBuff)
	self.optionsFrame.scaleSlider:SetValue(UnderhealDB.raidFrame.scale or 1)
	self.optionsFrame.scaleValue:SetText(math.floor(((UnderhealDB.raidFrame.scale or 1) * 100) + 0.5) .. "%")

	if self.buffOptionsFrame and self.buffOptionsFrame:IsShown() then
		self:RefreshBuffOptions()
	end

	if self.clickCastOptionsFrame and self.clickCastOptionsFrame:IsShown() then
		self:RefreshClickCastOptions()
	end
end

function Underheal:OpenColorPicker(config, colorKey, swatch)
	local color = config[colorKey]
	if not color then
		return
	end

	local previous = { r = color.r, g = color.g, b = color.b }
	local function ApplyColor(restore)
		local r, g, b
		if restore then
			r, g, b = restore.r, restore.g, restore.b
		else
			r, g, b = ColorPickerFrame:GetColorRGB()
		end

		color.r, color.g, color.b = r, g, b
		if swatch and swatch.texture then
			swatch.texture:SetColorTexture(r, g, b, 1)
		end
		self:ApplyBuffButtons()
	end

	ColorPickerFrame.previousValues = previous
	ColorPickerFrame.func = ApplyColor
	ColorPickerFrame.swatchFunc = ApplyColor
	ColorPickerFrame.opacityFunc = ApplyColor
	ColorPickerFrame.cancelFunc = ApplyColor
	ColorPickerFrame.hasOpacity = false
	ColorPickerFrame.opacity = 1
	ColorPickerFrame:SetColorRGB(color.r, color.g, color.b)
	ColorPickerFrame:Hide()
	ColorPickerFrame:Show()
end

function Underheal:RefreshBuffOptions()
	local frame = self.buffOptionsFrame
	if not frame then
		return
	end

	EnsureDefaults()
	local index = self.selectedBuffIndex or 1
	local config = UnderhealDB.buffButtons[index]
	if not config then
		return
	end

	for slotIndex, button in ipairs(frame.slotButtons) do
		button:SetText((slotIndex == index and "> " or "") .. slotIndex)
	end

	frame.enabledCheck:SetChecked(config.enabled)
	frame.labelBox:SetText(config.label or "")
	frame.castBox:SetText(config.cast or "")
	frame.auraBox:SetText(config.aura or "")

	for _, check in ipairs(frame.classChecks) do
		check:SetChecked(config.classes and config.classes[check.classKey])
	end

	for _, check in ipairs(frame.roleChecks) do
		check:SetChecked(config.priorityRoles and config.priorityRoles[check.roleKey])
	end

	frame.missingSwatch.texture:SetColorTexture(config.missingColor.r, config.missingColor.g, config.missingColor.b, 1)
	frame.prioritySwatch.texture:SetColorTexture(config.priorityColor.r, config.priorityColor.g, config.priorityColor.b, 1)
end

function Underheal:CreateBuffOptionsFrame()
	if self.buffOptionsFrame then
		return self.buffOptionsFrame
	end

	local frame = CreateFrame("Frame", "UnderhealBuffOptionsFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
	frame:SetSize(500, 520)
	frame:SetPoint("CENTER", UIParent, "CENTER", 290, 20)
	frame:SetFrameStrata("DIALOG")
	frame:SetFrameLevel(80)
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
			frame:SetBackdropColor(0.02, 0.04, 0.05, 0.96)
			frame:SetBackdropBorderColor(0.35, 0.65, 0.75, 1)
		end

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 18, -18)
	title:SetText("Underheal Buff Buttons")

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -4, -4)

	frame.slotButtons = {}
	for index = 1, #defaults.buffButtons do
		local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		button:SetSize(48, 22)
		button:SetPoint("TOPLEFT", 18 + ((index - 1) * 52), -52)
		button:SetScript("OnClick", function()
			Underheal.selectedBuffIndex = index
			Underheal:RefreshBuffOptions()
		end)
		frame.slotButtons[index] = button
	end

	local enabledCheck = CreateFrame("CheckButton", nil, frame, "InterfaceOptionsCheckButtonTemplate")
	enabledCheck:SetPoint("TOPLEFT", 18, -88)
	enabledCheck:SetScript("OnClick", function(self)
		local config = UnderhealDB.buffButtons[Underheal.selectedBuffIndex or 1]
		config.enabled = not not self:GetChecked()
		Underheal:ApplyBuffButtons()
	end)
	frame.enabledCheck = enabledCheck

	local enabledLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	enabledLabel:SetPoint("LEFT", enabledCheck, "RIGHT", 2, 1)
	enabledLabel:SetText("Enable this buff button")

	local function AddLabel(text, x, y)
		local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		label:SetPoint("TOPLEFT", x, y)
		label:SetText(text)
		return label
	end

	local function AddEditBox(name, y, setter)
		AddLabel(name, 22, y)
		local box = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
		box:SetSize(250, 22)
		box:SetPoint("TOPLEFT", 120, y + 4)
		box:SetAutoFocus(false)
		box:SetScript("OnEnterPressed", function(self)
			self:ClearFocus()
		end)
		box:SetScript("OnEditFocusLost", function(self)
			local config = UnderhealDB.buffButtons[Underheal.selectedBuffIndex or 1]
			setter(config, self:GetText() or "")
			Underheal:ApplyBuffButtons()
			Underheal:RefreshBuffOptions()
		end)
		return box
	end

	frame.labelBox = AddEditBox("Button label", -126, function(config, text) config.label = text end)
	frame.castBox = AddEditBox("Spell to cast", -158, function(config, text) config.cast = text end)
	frame.auraBox = AddEditBox("Buff to check", -190, function(config, text) config.aura = text end)

	AddLabel("Missing color", 22, -230)
	local missingSwatch = CreateFrame("Button", nil, frame)
	missingSwatch:SetSize(36, 20)
	missingSwatch:SetPoint("TOPLEFT", 120, -226)
	missingSwatch.texture = missingSwatch:CreateTexture(nil, "BACKGROUND")
	missingSwatch.texture:SetAllPoints()
	missingSwatch:SetScript("OnClick", function(self)
		local config = UnderhealDB.buffButtons[Underheal.selectedBuffIndex or 1]
		Underheal:OpenColorPicker(config, "missingColor", self)
	end)
	frame.missingSwatch = missingSwatch

	AddLabel("Priority color", 190, -230)
	local prioritySwatch = CreateFrame("Button", nil, frame)
	prioritySwatch:SetSize(36, 20)
	prioritySwatch:SetPoint("TOPLEFT", 284, -226)
	prioritySwatch.texture = prioritySwatch:CreateTexture(nil, "BACKGROUND")
	prioritySwatch.texture:SetAllPoints()
	prioritySwatch:SetScript("OnClick", function(self)
		local config = UnderhealDB.buffButtons[Underheal.selectedBuffIndex or 1]
		Underheal:OpenColorPicker(config, "priorityColor", self)
	end)
	frame.prioritySwatch = prioritySwatch

	AddLabel("Priority roles", 22, -268)
	frame.roleChecks = {}
	for index, role in ipairs(ROLE_ORDER) do
		local check = CreateFrame("CheckButton", nil, frame, "InterfaceOptionsCheckButtonTemplate")
		check:SetPoint("TOPLEFT", 116 + ((index - 1) * 96), -260)
		check.roleKey = role.key
		check:SetScript("OnClick", function(self)
			local config = UnderhealDB.buffButtons[Underheal.selectedBuffIndex or 1]
			config.priorityRoles = config.priorityRoles or {}
			config.priorityRoles[self.roleKey] = not not self:GetChecked()
			Underheal:ApplyBuffButtons()
		end)
		local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		label:SetPoint("LEFT", check, "RIGHT", 0, 1)
		label:SetText(role.label)
		frame.roleChecks[index] = check
	end

	AddLabel("Applies to classes", 22, -318)
	frame.classChecks = {}
	for index, class in ipairs(CLASS_ORDER) do
		local row = math.floor((index - 1) / 3)
		local column = (index - 1) % 3
		local check = CreateFrame("CheckButton", nil, frame, "InterfaceOptionsCheckButtonTemplate")
		check:SetPoint("TOPLEFT", 116 + (column * 118), -310 - (row * 30))
		check.classKey = class.key
		check:SetScript("OnClick", function(self)
			local config = UnderhealDB.buffButtons[Underheal.selectedBuffIndex or 1]
			config.classes = config.classes or {}
			config.classes[self.classKey] = not not self:GetChecked()
			Underheal:ApplyBuffButtons()
		end)
		local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		label:SetPoint("LEFT", check, "RIGHT", 0, 1)
		label:SetText(class.label)
		frame.classChecks[index] = check
	end

	local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	hint:SetPoint("BOTTOMLEFT", 24, 24)
	hint:SetWidth(440)
	hint:SetJustifyH("LEFT")
	hint:SetText("The button casts the spell, while the buff check decides when the color should warn you that it is missing.")

	self.buffOptionsFrame = frame
	self.selectedBuffIndex = self.selectedBuffIndex or 1
	return frame
end

function Underheal:ToggleBuffOptions()
	local frame = self:CreateBuffOptionsFrame()
	self:RefreshBuffOptions()
	if frame:IsShown() then
		frame:Hide()
	else
		frame:Show()
	end
end

function Underheal:RefreshClickCastOptions()
	local frame = self.clickCastOptionsFrame
	if not frame then
		return
	end

	EnsureDefaults()
	for _, row in ipairs(frame.rows) do
		local config = UnderhealDB.clickCasts[row.key]
		row.leftBox:SetText(config.left or "")
		row.rightBox:SetText(config.right or "")
		row.trinketCheck:SetChecked(config.useTrinkets)
	end
end

function Underheal:CreateClickCastOptionsFrame()
	if self.clickCastOptionsFrame then
		return self.clickCastOptionsFrame
	end

	local frame = CreateFrame("Frame", "UnderhealClickCastOptionsFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
	frame:SetSize(560, 270)
	frame:SetPoint("CENTER", UIParent, "CENTER", 290, -230)
	frame:SetFrameStrata("DIALOG")
	frame:SetFrameLevel(82)
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
		frame:SetBackdropColor(0.02, 0.04, 0.05, 0.96)
		frame:SetBackdropBorderColor(0.35, 0.65, 0.75, 1)
	end

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 18, -18)
	title:SetText("Underheal Click Casting")

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -4, -4)

	local function Header(text, x)
		local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		label:SetPoint("TOPLEFT", x, -58)
		label:SetText(text)
		return label
	end

	Header("Modifier", 24)
	Header("Left click spell", 118)
	Header("Right click spell", 302)
	Header("Trinkets", 478)

	frame.rows = {}
	for index, entry in ipairs(CLICK_CAST_ORDER) do
		local y = -78 - ((index - 1) * 38)
		local row = { key = entry.key }

		local modifier = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		modifier:SetPoint("TOPLEFT", 28, y - 4)
		modifier:SetText(entry.label)

		local function MakeSpellBox(x, field)
			local box = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
			box:SetSize(150, 22)
			box:SetPoint("TOPLEFT", x, y)
			box:SetAutoFocus(false)
			box:SetScript("OnEnterPressed", function(self)
				self:ClearFocus()
			end)
			box:SetScript("OnEditFocusLost", function(self)
				UnderhealDB.clickCasts[entry.key][field] = self:GetText() or ""
				Underheal:ApplyBuffButtons()
			end)
			return box
		end

		row.leftBox = MakeSpellBox(118, "left")
		row.rightBox = MakeSpellBox(302, "right")

		row.trinketCheck = CreateFrame("CheckButton", nil, frame, "InterfaceOptionsCheckButtonTemplate")
		row.trinketCheck:SetPoint("TOPLEFT", 486, y + 4)
		row.trinketCheck:SetScript("OnClick", function(self)
			UnderhealDB.clickCasts[entry.key].useTrinkets = not not self:GetChecked()
			Underheal:ApplyBuffButtons()
		end)

		frame.rows[index] = row
	end

	local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	hint:SetPoint("BOTTOMLEFT", 24, 24)
	hint:SetWidth(500)
	hint:SetJustifyH("LEFT")
	hint:SetText("Spell names may include ranks, e.g. Flash Heal(Rank 4). Trinkets try slots 13 and 14 before the spell.")

	self.clickCastOptionsFrame = frame
	return frame
end

function Underheal:ToggleClickCastOptions()
	local frame = self:CreateClickCastOptionsFrame()
	self:RefreshClickCastOptions()
	if frame:IsShown() then
		frame:Hide()
	else
		frame:Show()
	end
end

function Underheal:CreateOptionsFrame()
	if self.optionsFrame then
		return self.optionsFrame
	end

	local frame = CreateFrame("Frame", "UnderhealOptionsFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
	frame:SetSize(360, 455)
	frame:SetPoint("CENTER", UIParent, "CENTER", -260, 20)
	frame:SetFrameStrata("DIALOG")
	frame:SetFrameLevel(70)
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
			frame:SetBackdropColor(0.02, 0.04, 0.05, 0.94)
			frame:SetBackdropBorderColor(0.35, 0.65, 0.75, 1)
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

	local buffCheck = CreateFrame("CheckButton", nil, frame, "InterfaceOptionsCheckButtonTemplate")
	buffCheck:SetPoint("TOPLEFT", 18, -230)
	buffCheck:SetScript("OnClick", function(self)
		UnderhealDB.raidFrame.showBuffButtons = not not self:GetChecked()
		Underheal:ApplyBuffButtons()
		Underheal:RefreshOptions()
	end)
	frame.buffCheck = buffCheck

	local buffLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	buffLabel:SetPoint("LEFT", buffCheck, "RIGHT", 2, 1)
	buffLabel:SetText("Show buff buttons")

	local clickBuffCheck = CreateFrame("CheckButton", nil, frame, "InterfaceOptionsCheckButtonTemplate")
	clickBuffCheck:SetPoint("TOPLEFT", 18, -264)
	clickBuffCheck:SetScript("OnClick", function(self)
		UnderhealDB.raidFrame.clickToBuff = not not self:GetChecked()
		Underheal:UpdateClickBuffToggleButton()
		Underheal:ApplyBuffButtons()
		Underheal:RefreshOptions()
	end)
	frame.clickBuffCheck = clickBuffCheck

	local clickBuffLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	clickBuffLabel:SetPoint("LEFT", clickBuffCheck, "RIGHT", 2, 1)
	clickBuffLabel:SetText("Click raid frame to cast missing buff")

	local scaleLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	scaleLabel:SetPoint("TOPLEFT", 22, -304)
	scaleLabel:SetText("Raid frame scale")

	local scaleValue = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	scaleValue:SetPoint("TOPRIGHT", -34, -306)
	scaleValue:SetText("100%")
	frame.scaleValue = scaleValue

	local scaleSlider = CreateFrame("Slider", "UnderhealRaidScaleSlider", frame, "OptionsSliderTemplate")
	scaleSlider:SetPoint("TOPLEFT", 38, -330)
	scaleSlider:SetWidth(270)
	scaleSlider:SetMinMaxValues(0.8, 1.6)
	scaleSlider:SetValueStep(0.05)
	if scaleSlider.SetObeyStepOnDrag then
		scaleSlider:SetObeyStepOnDrag(true)
	end
	_G[scaleSlider:GetName() .. "Low"]:SetText("80%")
	_G[scaleSlider:GetName() .. "High"]:SetText("160%")
	_G[scaleSlider:GetName() .. "Text"]:SetText("")
	scaleSlider:SetScript("OnValueChanged", function(self, value)
		local rounded = math.floor((value * 20) + 0.5) / 20
		UnderhealDB.raidFrame.scale = rounded
		frame.scaleValue:SetText(math.floor((rounded * 100) + 0.5) .. "%")
		Underheal:ApplyRaidFrameScale()
	end)
	frame.scaleSlider = scaleSlider

	local buffOptions = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	buffOptions:SetSize(120, 24)
	buffOptions:SetPoint("TOPLEFT", 48, -370)
	buffOptions:SetText("Configure Buffs")
	buffOptions:SetScript("OnClick", function()
		Underheal:ToggleBuffOptions()
	end)

	local clickOptions = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	clickOptions:SetSize(120, 24)
	clickOptions:SetPoint("TOPLEFT", 178, -370)
	clickOptions:SetText("Configure Clicks")
	clickOptions:SetScript("OnClick", function()
		Underheal:ToggleClickCastOptions()
	end)

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
	Underheal:UpdateTankWatch()
	Underheal:UpdateTankDragState()
	Underheal:UpdateClickBuffToggleDragState()
	Underheal:RefreshOptions()

	if not quiet then
		if unlocked then
			Print("Mover shown. Drag the Underheal bar, Tanks panel, or click-to-buff button, then type /underheal lock.")
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
	Print("/underheal buffs - toggle buff buttons")
	Print("/underheal clickbuff - toggle clicking raid frames to buff")
	Print("/underheal buffconfig - configure buff buttons")
	Print("/underheal clickconfig - configure click-casting")
	Print("/underheal reset - restore Blizzard raid frames to a visible default spot")
end

SLASH_UNDERHEAL1 = "/underheal"
SLASH_UNDERHEAL2 = "/uh"
SlashCmdList.UNDERHEAL = function(input)
	EnsureDefaults()
	if not IsHealerCharacter() then
		Underheal:DisableForNonHealer()
		return
	end

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
	elseif command == "buffs" then
		UnderhealDB.raidFrame.showBuffButtons = not UnderhealDB.raidFrame.showBuffButtons
		Underheal:ApplyBuffButtons()
		Underheal:RefreshOptions()
		Print("Buff buttons " .. (UnderhealDB.raidFrame.showBuffButtons and "enabled." or "disabled."))
	elseif command == "clickbuff" then
		UnderhealDB.raidFrame.clickToBuff = not UnderhealDB.raidFrame.clickToBuff
		Underheal:UpdateClickBuffToggleButton()
		Underheal:ApplyBuffButtons()
		Underheal:RefreshOptions()
		Print("Click-to-buff " .. (UnderhealDB.raidFrame.clickToBuff and "enabled." or "disabled."))
	elseif command == "buffconfig" or command == "buffsconfig" then
		Underheal:ToggleBuffOptions()
	elseif command == "clickconfig" or command == "clickcast" then
		Underheal:ToggleClickCastOptions()
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
Underheal:RegisterEvent("SPELL_UPDATE_COOLDOWN")
Underheal:RegisterEvent("PLAYER_REGEN_DISABLED")
Underheal:RegisterEvent("PLAYER_TARGET_CHANGED")
Underheal:RegisterEvent("UNIT_TARGET")
Underheal:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
Underheal:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
Underheal:RegisterEvent("UNIT_FLAGS")
Underheal:RegisterEvent("CHAT_MSG_ADDON")
pcall(Underheal.RegisterEvent, Underheal, "UNIT_SPELLCAST_SENT")
pcall(Underheal.RegisterEvent, Underheal, "UNIT_SPELLCAST_START")
pcall(Underheal.RegisterEvent, Underheal, "UNIT_SPELLCAST_DELAYED")
pcall(Underheal.RegisterEvent, Underheal, "UNIT_SPELLCAST_STOP")
pcall(Underheal.RegisterEvent, Underheal, "UNIT_SPELLCAST_FAILED")
pcall(Underheal.RegisterEvent, Underheal, "UNIT_SPELLCAST_INTERRUPTED")
pcall(Underheal.RegisterEvent, Underheal, "UNIT_SPELLCAST_SUCCEEDED")
pcall(Underheal.RegisterEvent, Underheal, "UNIT_HEAL_PREDICTION")
pcall(Underheal.RegisterEvent, Underheal, "PLAYER_ROLES_ASSIGNED")
Underheal:SetScript("OnUpdate", function(self, elapsed)
	self:PollPullAnnounce(elapsed)
end)
Underheal:SetScript("OnEvent", function(self, event, ...)
	local addonName, arg2, arg3, arg4 = ...
	if event == "PLAYER_LOGIN" then
		EnsureDefaults()
		if not IsHealerCharacter() then
			self:DisableForNonHealer()
			return
		end

		self.disabledForNonHealer = false
		self:RegisterAddonComms()
		self:HookBlizzardRaidLayout()
		self:ApplyGroupProfile()
		self:ApplyRaidFrameScale()
		self:ApplyRaidFramePosition()
		self:ApplyGroupGap()
		self:ApplyGroupMarkers()
		self:SkinRaidFrames()
		self:ApplyBuffButtons()
		self:UpdateClickBuffToggleButton()
		SetRaidFramesUnlocked(UnderhealDB.raidFrame.unlocked, true)
		self:UpdateTankWatch()
		self:UpdatePetWatch()
		self:RefreshPullAnnounceState()
		Print("Loaded. Type /underheal to open options.")
	elseif event == "PLAYER_REGEN_ENABLED" then
		if self.disabledForNonHealer then
			if self.pendingDisableCleanup then
				self.pendingDisableCleanup = nil
				self:DisableForNonHealer()
			end
			return
		end

		if self.pendingApply then
			self.pendingApply = nil
			self:ApplyRaidFramePosition()
		end

		if self.pendingScale then
			self.pendingScale = nil
			self:ApplyRaidFrameScale()
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
		self:ApplyRaidFrameScale()
		self:ApplyGroupGap()
		if self.pendingGroupMarkers then
			self.pendingGroupMarkers = nil
		end
		self:ApplyGroupMarkers()
		self:SkinRaidFrames()
		if self.pendingBuffButtons then
			self.pendingBuffButtons = nil
		end
		self:ApplyBuffButtons()
		self:UpdateClickBuffToggleButton()
		if self.pendingPetUpdate then
			self.pendingPetUpdate = nil
		end
		if self.pendingTankUpdate then
			self.pendingTankUpdate = nil
		end
		self:UpdateTankWatch()
		self:UpdatePetWatch()
		self:RefreshPullAnnounceState()
	elseif event == "ADDON_LOADED" and addonName == "Blizzard_CompactRaidFrames" then
		EnsureDefaults()
		if not IsHealerCharacter() then
			self:DisableForNonHealer()
			return
		end

		self:RegisterAddonComms()
		self:HookBlizzardRaidLayout()
		self:ApplyGroupProfile()
		self:ApplyRaidFrameScale()
		self:ApplyRaidFramePosition()
		self:ApplyGroupGap()
		self:ApplyGroupMarkers()
		self:SkinRaidFrames()
		self:ApplyBuffButtons()
		self:UpdateClickBuffToggleButton()
		SetRaidFramesUnlocked(UnderhealDB.raidFrame.unlocked, true)
		self:UpdateTankWatch()
		self:UpdatePetWatch()
		self:RefreshPullAnnounceState()
	elseif event == "GROUP_ROSTER_UPDATE" then
		if self.disabledForNonHealer then
			return
		end

		EnsureDefaults()
		self:ApplyGroupProfile()
		self:ApplyRaidFrameScale()
		self:ApplyGroupGap()
		self:ApplyGroupMarkers()
		self:SkinRaidFrames()
		self:ApplyBuffButtons()
		self:UpdateClickBuffToggleButton()
		self:UpdateTankWatch()
		self:UpdatePetWatch()
		self:RefreshPullAnnounceState()
	elseif event == "PLAYER_ROLES_ASSIGNED" then
		if self.disabledForNonHealer then
			return
		end

		self:UpdateTankWatch()
		self:ApplyBuffButtons()
	elseif event == "SPELL_UPDATE_COOLDOWN" then
		if self.disabledForNonHealer then
			return
		end

		self:SkinRaidFrames()
		self:ApplyBuffButtons()
	elseif event == "PLAYER_TARGET_CHANGED" or event == "UNIT_TARGET" or event == "UNIT_THREAT_LIST_UPDATE" or event == "UNIT_THREAT_SITUATION_UPDATE" then
		if self.disabledForNonHealer then
			return
		end

		self:UpdateThreatIndicators()
	elseif event == "UNIT_FLAGS" then
		if self.disabledForNonHealer then
			return
		end

		self:CheckPullAnnounce(addonName)
	elseif event == "UNIT_HEAL_PREDICTION" then
		if self.disabledForNonHealer then
			return
		end

		self:RefreshIncomingHeals()
	elseif event == "UNIT_SPELLCAST_SENT" then
		if self.disabledForNonHealer then
			return
		end

		self:HandleSpellcastSent(addonName, arg2, arg3, arg4)
	elseif event == "UNIT_SPELLCAST_START" then
		if self.disabledForNonHealer then
			return
		end

		self:HandleSpellcastStart(addonName)
	elseif event == "UNIT_SPELLCAST_DELAYED" then
		if self.disabledForNonHealer then
			return
		end

		if addonName == "player" and self.outgoingHealTargetGUID and self.outgoingHealSpell then
			local endTimeMS = select(5, UnitCastingInfo("player")) or (GetTime() * 1000 + 2500)
			SendUnderhealAddonMessage("HSTART\t" .. self.outgoingHealTargetGUID .. "\t" .. self.outgoingHealSpell .. "\t" .. string.format("%.2f", endTimeMS / 1000))
			self:RefreshIncomingHeals()
		end
	elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_SUCCEEDED" then
		if self.disabledForNonHealer then
			return
		end

		if addonName == "player" then
			self:SendHealStop()
		end
	elseif event == "CHAT_MSG_ADDON" then
		if self.disabledForNonHealer then
			return
		end

		self:HandleAddonMessage(addonName, arg2, arg3, arg4)
	elseif event == "PLAYER_REGEN_DISABLED" then
		if self.disabledForNonHealer then
			return
		end

		self:SkinRaidFrames()
		self:ApplyBuffButtons()
	elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or event == "UNIT_AURA" then
		if self.disabledForNonHealer then
			return
		end

		local unit = addonName
		if unit and string.find(unit, "pet") then
			self:UpdatePetWatch()
		end
		if unit and (unit == "player" or string.match(unit, "^raid%d+$") or string.match(unit, "^party%d+$")) then
			self:UpdateTankWatch()
			self:SkinRaidFrames()
			self:ApplyBuffButtons()
		end
	end
end)
