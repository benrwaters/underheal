local ADDON_NAME = ...

UnderhealLegacyDB = UnderhealLegacyDB or UnderhealDB or {}
UnderhealCharacterDB = UnderhealCharacterDB or {}
UnderhealDB = UnderhealCharacterDB

local Underheal = CreateFrame("Frame")
local MOVER_NAME = "UnderhealRaidFrameMover"
local TANK_BUTTON_WIDTH = 220
local COMM_PREFIX = "Underheal"
local SetRaidFramesUnlocked
local RAID_UNITS = {}
local KNOWN_SPELL_CACHE = {}
local KNOCKED_LOSS_OF_CONTROL_TYPES = {
	STUN = true,
	STUN_MECHANIC = true,
}

local defaults = {
	raidFrame = {
		unlocked = false,
		grouped = true,
		groupGap = 24,
		groupsPerRow = 4,
		showPets = true,
		showTanks = true,
		showTargetOfTarget = false,
			showBuffButtons = true,
			showBuffColors = true,
			clickToBuff = true,
			superResponsiveMode = false,
			showMagicDebuffs = true,
			showDiseaseDebuffs = true,
			showPoisonDebuffs = false,
			showCurseDebuffs = false,
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
		scale = 1.0,
	},
	targetOfTarget = {
		hasPosition = false,
		x = 250,
		y = 680,
		scale = 1.0,
	},
	clickBuffButton = {
		hasPosition = false,
		x = 250,
		y = 640,
	},
	selfWatch = {
		hasPosition = false,
		setupConfirmed = false,
		x = 250,
		y = 520,
	},
	powerInfusion = {
		enabled = false,
		spell = "",
		label = "",
		targetClass = "",
		chosenPlayer = "",
	},
	buffButtons = {
		{
			key = "custom1",
			label = "1",
			cast = "",
			aura = "",
			enabled = false,
			classes = {},
			missingColor = { r = 0.88, g = 0.58, b = 0.24 },
			priorityColor = { r = 1.0, g = 0.38, b = 0.0 },
			clickPriority = 100,
			warnBeforeExpirySeconds = 0,
			priorityRoles = {},
		},
		{
			key = "custom2",
			label = "2",
			cast = "",
			aura = "",
			enabled = false,
			classes = {},
			missingColor = { r = 0.30, g = 0.55, b = 0.95 },
			priorityColor = { r = 0.12, g = 0.80, b = 1.0 },
			clickPriority = 200,
			warnBeforeExpirySeconds = 0,
			priorityRoles = {},
		},
		{
			key = "custom3",
			label = "3",
			cast = "",
			aura = "",
			enabled = false,
			classes = {},
			missingColor = { r = 0.55, g = 0.32, b = 0.14 },
			priorityColor = { r = 0.95, g = 0.45, b = 0.08 },
			clickPriority = 500,
			warnBeforeExpirySeconds = 0,
			priorityRoles = {},
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
			warnBeforeExpirySeconds = 0,
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
			warnBeforeExpirySeconds = 0,
			priorityRoles = {},
		},
	},
	clickCasts = {
		none = {
			left = "",
			right = "",
			useTrinkets = false,
		},
		alt = {
			left = "",
			right = "",
			useTrinkets = false,
		},
		ctrl = {
			left = "",
			right = "",
			useTrinkets = false,
		},
		shift = {
			left = "",
			right = "",
			useTrinkets = false,
		},
	},
}

local recommendedPresets = {
	PRIEST = {
		raidFrame = { showMagicDebuffs = true, showDiseaseDebuffs = true, showPoisonDebuffs = false, showCurseDebuffs = false },
		buffButtons = {
			{ key = "fortitude", label = "F", cast = "Prayer of Fortitude", fallbackCast = "Power Word: Fortitude", reagent = 17029, aura = "Power Word: Fortitude", auraAliases = { "Prayer of Fortitude" }, enabled = true, classes = { DRUID = true, HUNTER = true, MAGE = true, PALADIN = true, PRIEST = true, ROGUE = true, SHAMAN = true, WARLOCK = true, WARRIOR = true }, missingColor = { r = 0.88, g = 0.58, b = 0.24 }, priorityColor = { r = 1.0, g = 0.38, b = 0.0 }, clickPriority = 100, priorityRoles = { TANK = true, HEALER = true } },
			{ key = "spirit", label = "S", cast = "Prayer of Spirit", fallbackCast = "Divine Spirit", reagent = 17029, aura = "Divine Spirit", auraAliases = { "Prayer of Spirit" }, enabled = true, classes = { DRUID = true, HUNTER = true, MAGE = true, PALADIN = true, PRIEST = true, SHAMAN = true, WARLOCK = true }, missingColor = { r = 0.30, g = 0.55, b = 0.95 }, priorityColor = { r = 0.12, g = 0.80, b = 1.0 }, clickPriority = 200, priorityRoles = { HEALER = true } },
			{ key = "fearward", label = "W", cast = "Fear Ward", aura = "Fear Ward", enabled = true, classes = { DRUID = true, HUNTER = true, MAGE = true, PALADIN = true, PRIEST = true, ROGUE = true, SHAMAN = true, WARLOCK = true, WARRIOR = true }, missingColor = { r = 0.55, g = 0.32, b = 0.14 }, priorityColor = { r = 0.95, g = 0.45, b = 0.08 }, clickPriority = 500, combatPriority = true, hideWarningOnCooldown = true, warnBeforeExpirySeconds = 60, priorityRoles = { TANK = true, HEALER = true } },
		},
		clickCasts = {
			none = { left = "Flash Heal(Rank 4)", right = "Renew", useTrinkets = false },
			ctrl = { left = "Flash Heal", right = "", useTrinkets = false },
			shift = { left = "Heal(Rank 3)", right = "", useTrinkets = false },
			alt = { left = "", right = "", useTrinkets = false },
		},
		powerInfusion = { enabled = true, spell = "Power Infusion", label = "PI", targetClass = "MAGE", chosenPlayer = "" },
	},
	PALADIN = {
		raidFrame = { showMagicDebuffs = true, showDiseaseDebuffs = true, showPoisonDebuffs = true, showCurseDebuffs = false },
		buffButtons = {
			{ key = "kings", label = "K", cast = "Blessing of Kings", aura = "Blessing of Kings", enabled = true, classes = { DRUID = true, HUNTER = true, MAGE = true, PALADIN = true, PRIEST = true, ROGUE = true, WARLOCK = true, WARRIOR = true }, missingColor = { r = 0.92, g = 0.62, b = 0.18 }, priorityColor = { r = 1.0, g = 0.38, b = 0.0 }, clickPriority = 300, priorityRoles = { TANK = true } },
			{ key = "wisdom", label = "W", cast = "Blessing of Wisdom", aura = "Blessing of Wisdom", enabled = true, classes = { DRUID = true, HUNTER = true, MAGE = true, PALADIN = true, PRIEST = true, WARLOCK = true }, missingColor = { r = 0.30, g = 0.55, b = 0.95 }, priorityColor = { r = 0.12, g = 0.80, b = 1.0 }, clickPriority = 200, priorityRoles = { HEALER = true } },
			{ key = "might", label = "M", cast = "Blessing of Might", aura = "Blessing of Might", enabled = true, classes = { DRUID = true, HUNTER = true, PALADIN = true, ROGUE = true, WARRIOR = true }, missingColor = { r = 0.75, g = 0.42, b = 0.12 }, priorityColor = { r = 1.0, g = 0.48, b = 0.08 }, clickPriority = 100, priorityRoles = { TANK = true } },
		},
		clickCasts = {
			none = { left = "Flash of Light", right = "Holy Light", useTrinkets = false },
			ctrl = { left = "Holy Light", right = "", useTrinkets = false },
			shift = { left = "", right = "", useTrinkets = false },
			alt = { left = "", right = "", useTrinkets = false },
		},
		powerInfusion = { enabled = false, spell = "", label = "", targetClass = "", chosenPlayer = "" },
	},
	DRUID = {
		raidFrame = { showMagicDebuffs = false, showDiseaseDebuffs = false, showPoisonDebuffs = true, showCurseDebuffs = true },
		buffButtons = {
			{ key = "mark", label = "M", cast = "Mark of the Wild", aura = "Mark of the Wild", enabled = true, classes = { DRUID = true, HUNTER = true, MAGE = true, PALADIN = true, PRIEST = true, ROGUE = true, WARLOCK = true, WARRIOR = true }, missingColor = { r = 0.45, g = 0.72, b = 0.22 }, priorityColor = { r = 0.72, g = 0.95, b = 0.22 }, clickPriority = 200, priorityRoles = { TANK = true, HEALER = true } },
			{ key = "thorns", label = "T", cast = "Thorns", aura = "Thorns", enabled = true, classes = { DRUID = true, PALADIN = true, WARRIOR = true }, missingColor = { r = 0.62, g = 0.38, b = 0.18 }, priorityColor = { r = 0.92, g = 0.48, b = 0.12 }, clickPriority = 300, priorityRoles = { TANK = true } },
		},
		clickCasts = {
			none = { left = "Healing Touch", right = "Rejuvenation", useTrinkets = false },
			ctrl = { left = "Regrowth", right = "", useTrinkets = false },
			shift = { left = "", right = "", useTrinkets = false },
			alt = { left = "", right = "", useTrinkets = false },
		},
		powerInfusion = { enabled = false, spell = "", label = "", targetClass = "", chosenPlayer = "" },
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

local DEBUFF_COLORS = {
	Magic = { r = 0.95, g = 0.05, b = 0.05 },
	Disease = { r = 0.58, g = 0.18, b = 0.95 },
	Poison = { r = 0.05, g = 0.75, b = 0.18 },
	Curse = { r = 0.62, g = 0.22, b = 0.82 },
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

local function ClearTable(tbl)
	if wipe then
		wipe(tbl)
	else
		for key in pairs(tbl) do
			tbl[key] = nil
		end
	end
end

local function EnsureDefaults()
	UnderhealCharacterDB = UnderhealCharacterDB or {}
	UnderhealDB = UnderhealCharacterDB
	UnderhealDB.raidFrame = UnderhealDB.raidFrame or {}
	UnderhealDB.pets = UnderhealDB.pets or {}
	UnderhealDB.tanks = UnderhealDB.tanks or {}
	UnderhealDB.targetOfTarget = UnderhealDB.targetOfTarget or {}
	UnderhealDB.clickBuffButton = UnderhealDB.clickBuffButton or {}
	UnderhealDB.selfWatch = UnderhealDB.selfWatch or {}
	UnderhealDB.powerInfusion = UnderhealDB.powerInfusion or {}
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

	for key, value in pairs(defaults.targetOfTarget) do
		if UnderhealDB.targetOfTarget[key] == nil then
			UnderhealDB.targetOfTarget[key] = value
		end
	end

	for key, value in pairs(defaults.clickBuffButton) do
		if UnderhealDB.clickBuffButton[key] == nil then
			UnderhealDB.clickBuffButton[key] = value
		end
	end

	for key, value in pairs(defaults.selfWatch) do
		if UnderhealDB.selfWatch[key] == nil then
			UnderhealDB.selfWatch[key] = value
		end
	end

	for key, value in pairs(defaults.powerInfusion) do
		if UnderhealDB.powerInfusion[key] == nil then
			UnderhealDB.powerInfusion[key] = value
		end
	end

	for index, value in ipairs(defaults.buffButtons) do
		if UnderhealDB.buffButtons[index] and UnderhealDB.buffButtons[index].key == "fearward" and UnderhealDB.buffButtons[index].warnBeforeExpirySeconds == nil then
			UnderhealDB.buffButtons[index].warnBeforeExpirySeconds = 60
		end
		if UnderhealDB.buffButtons[index] and UnderhealDB.buffButtons[index].key == "fortitude" and UnderhealDB.buffButtons[index].fallbackCast == nil then
			UnderhealDB.buffButtons[index].fallbackCast = "Power Word: Fortitude"
		elseif UnderhealDB.buffButtons[index] and UnderhealDB.buffButtons[index].key == "spirit" and UnderhealDB.buffButtons[index].fallbackCast == nil then
			UnderhealDB.buffButtons[index].fallbackCast = "Divine Spirit"
		end
		if UnderhealDB.buffButtons[index] and (UnderhealDB.buffButtons[index].key == "fortitude" or UnderhealDB.buffButtons[index].key == "spirit") and (UnderhealDB.buffButtons[index].reagent == nil or UnderhealDB.buffButtons[index].reagent == "Sacred Candle") then
			UnderhealDB.buffButtons[index].reagent = 17029
		end
		if UnderhealDB.buffButtons[index] == nil then
			UnderhealDB.buffButtons[index] = CopyTable(value)
		else
			for key, defaultValue in pairs(value) do
				if UnderhealDB.buffButtons[index][key] == nil then
					UnderhealDB.buffButtons[index][key] = CopyTable(defaultValue)
				end
			end
		end
		if UnderhealDB.buffButtons[index].key == "fearward" and UnderhealDB.buffButtons[index].combatPriority == nil then
			UnderhealDB.buffButtons[index].combatPriority = true
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

	if UnderhealDB.raidFrame.groupGap < 24 or UnderhealDB.raidFrame.groupGap == 44 then
		UnderhealDB.raidFrame.groupGap = 24
	end
	if not UnderhealDB.raidFrame.groupsPerRow or UnderhealDB.raidFrame.groupsPerRow == 3 then
		UnderhealDB.raidFrame.groupsPerRow = 4
	end
end

local function GetRaidFrame()
	if IsInGroup and IsInGroup() and not (IsInRaid and IsInRaid()) and _G.CompactPartyFrame then
		return _G.CompactPartyFrame
	end

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

local function GetTankScale()
	local scale = UnderhealDB.tanks and UnderhealDB.tanks.scale or 1
	if scale <= 0 then
		return 1
	elseif scale < 0.75 then
		return 0.75
	elseif scale > 2.0 then
		return 2.0
	end

	return scale
end

local function GetTargetOfTargetScale()
	local scale = UnderhealDB.targetOfTarget and UnderhealDB.targetOfTarget.scale or 1
	if scale <= 0 then
		return 1
	elseif scale < 0.75 then
		return 0.75
	elseif scale > 2.0 then
		return 2.0
	end

	return scale
end

local function IsHealerCharacter()
	local _, classFile = UnitClass("player")
	return classFile and HEALER_CLASSES[classFile]
end

local function GetRaidUnits()
	ClearTable(RAID_UNITS)
	if IsInRaid and IsInRaid() then
		for index = 1, 40 do
			local unit = "raid" .. index
			if UnitExists(unit) then
				RAID_UNITS[#RAID_UNITS + 1] = unit
			end
		end
	elseif IsInGroup and IsInGroup() then
		RAID_UNITS[#RAID_UNITS + 1] = "player"
		for index = 1, 4 do
			local unit = "party" .. index
			if UnitExists(unit) then
				RAID_UNITS[#RAID_UNITS + 1] = unit
			end
		end
	else
		RAID_UNITS[#RAID_UNITS + 1] = "player"
	end

	return RAID_UNITS
end

local function IsRaidCombatClear()
	for _, unit in ipairs(GetRaidUnits()) do
		if UnitAffectingCombat(unit) then
			return false
		end
	end

	return true
end

local function UnitHasHostileCombatTarget(unit)
	if not unit or not UnitExists(unit) then
		return false
	end

	local targetUnit = unit == "player" and "target" or (unit .. "target")
	if not UnitExists(targetUnit) or not UnitCanAttack("player", targetUnit) then
		return false
	end

	if UnitAffectingCombat(targetUnit) then
		return true
	end

	if UnitDetailedThreatSituation then
		local isTanking, _, threatPct, rawThreatPct, threatValue = UnitDetailedThreatSituation(unit, targetUnit)
		if isTanking or (threatValue and threatValue > 0) or (rawThreatPct and rawThreatPct > 0) or (threatPct and threatPct > 0) then
			return true
		end
	end

	if UnitThreatSituation and UnitThreatSituation(unit, targetUnit) then
		return true
	end

	return false
end

local function UnitLooksLikePuller(unit)
	return unit and UnitAffectingCombat(unit) and UnitHasHostileCombatTarget(unit)
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

local function NormalizePlayerName(name)
	local shortName = GetShortName(name)
	if not shortName then
		return nil
	end

	return string.lower(shortName)
end

local function NormalizeSpellName(spellName)
	if not spellName then
		return nil
	end

	return string.lower((string.gsub(spellName, "%s*%b()", "")))
end

local function PlayerKnowsSpell(spellName)
	if not spellName or spellName == "" then
		return false
	end

	local expectedName = NormalizeSpellName(spellName)
	if KNOWN_SPELL_CACHE[expectedName] ~= nil then
		return KNOWN_SPELL_CACHE[expectedName]
	end

	if GetNumSpellTabs and GetSpellTabInfo and GetSpellBookItemName then
		local spellBookType = BOOKTYPE_SPELL or "spell"
		for tabIndex = 1, GetNumSpellTabs() do
			local _, _, offset, spellCount = GetSpellTabInfo(tabIndex)
			for spellIndex = (offset or 0) + 1, (offset or 0) + (spellCount or 0) do
				local knownName = GetSpellBookItemName(spellIndex, spellBookType)
				if NormalizeSpellName(knownName) == expectedName then
					KNOWN_SPELL_CACHE[expectedName] = true
					return true
				end
			end
		end
		KNOWN_SPELL_CACHE[expectedName] = false
		return false
	end

	local known = GetSpellInfo and GetSpellInfo(spellName) ~= nil or false
	KNOWN_SPELL_CACHE[expectedName] = known
	return known
end

local function GetSpecialPowerConfig()
	local config = UnderhealDB.powerInfusion or {}
	if (not config.spell or config.spell == "") and config.chosenMage then
		config.spell = "Power Infusion"
	end
	if not config.label or config.label == "" then
		config.label = config.spell == "Power Infusion" and "PI" or "SP"
	end
	if (not config.targetClass or config.targetClass == "") and config.spell == "Power Infusion" then
		config.targetClass = "MAGE"
	end
	if not config.chosenPlayer or config.chosenPlayer == "" then
		config.chosenPlayer = config.chosenMage or ""
	end
	UnderhealDB.powerInfusion = config
	return config
end

local function IsPowerInfusionReady()
	local config = GetSpecialPowerConfig()
	local spellName = config.spell
	if not config.enabled or not PlayerKnowsSpell(spellName) then
		return false
	end

	if not GetSpellCooldown then
		return false
	end

	local start, duration, enabled = GetSpellCooldown(spellName)
	if enabled == 0 then
		return false
	end

	if not start or not duration or start == 0 or duration == 0 then
		return true
	end

	return (start + duration) <= (GetTime and GetTime() or 0)
end

local function IsHealingSpell(spellName)
	if not spellName then
		return false
	end

	local baseName = string.lower((string.gsub(spellName, "%s*%b()", "")))
	return HEALING_SPELLS[baseName] == true
end

local function GetResurrectionSpell()
	local _, classFile = UnitClass("player")
	if classFile == "PRIEST" then
		return "Resurrection"
	elseif classFile == "PALADIN" then
		return "Redemption"
	elseif classFile == "SHAMAN" then
		return "Ancestral Spirit"
	elseif classFile == "DRUID" then
		return "Rebirth"
	end

	return nil
end

local function IsMindControlAuraName(name)
	if not name then
		return false
	end

	local lowerName = string.lower(name)
	return string.find(lowerName, "mind control", 1, true)
		or string.find(lowerName, "cause insanity", 1, true)
		or string.find(lowerName, "dominat", 1, true)
		or string.find(lowerName, "charm", 1, true)
		or string.find(lowerName, "possess", 1, true)
end

local function PlayerCanDispelAura(unit, auraName)
	if not unit or not auraName or not UnitDebuff then
		return false
	end

	for index = 1, 40 do
		local name = UnitDebuff(unit, index, "RAID")
		if not name then
			return false
		end
		if name == auraName then
			return true
		end
	end

	return false
end

local function GetMindControlInfo(unit)
	if not unit or not UnitExists(unit) or not UnitDebuff then
		return false, false
	end

	for index = 1, 40 do
		local name, _, _, fourth, fifth = UnitDebuff(unit, index)
		if not name then
			return false, false
		end
		if IsMindControlAuraName(name) then
			local debuffType = fifth
			if fourth == "Magic" or fourth == "Disease" or fourth == "Poison" or fourth == "Curse" then
				debuffType = fourth
			end
			return true, debuffType == "Magic" and PlayerCanDispelAura(unit, name)
		end
	end

	return false, false
end

local function GetUnitSpecialState(unit)
	if not unit or not UnitExists(unit) then
		return nil
	end

	local mindControlled, dispellable = GetMindControlInfo(unit)
	if mindControlled then
		return "MINDCONTROLLED", dispellable
	end

	if UnitIsFeignDeath and UnitIsFeignDeath(unit) then
		return "FEIGN"
	end

	if (UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit)) or (UnitIsDead and UnitIsDead(unit)) then
		return "RIP"
	end

	return nil
end

local function DebuffTypeEnabled(debuffType)
	if debuffType == "Magic" then
		return UnderhealDB.raidFrame.showMagicDebuffs
	elseif debuffType == "Disease" then
		return UnderhealDB.raidFrame.showDiseaseDebuffs
	elseif debuffType == "Poison" then
		return UnderhealDB.raidFrame.showPoisonDebuffs
	elseif debuffType == "Curse" then
		return UnderhealDB.raidFrame.showCurseDebuffs
	end

	return false
end

local function GetBestDebuffColor(unit)
	if not unit or not UnitExists(unit) or not UnitDebuff then
		return nil
	end

	for index = 1, 40 do
		local name, _, _, fourth, fifth = UnitDebuff(unit, index)
		if not name then
			return nil
		end
		local debuffType = fifth
		if fourth == "Magic" or fourth == "Disease" or fourth == "Poison" or fourth == "Curse" then
			debuffType = fourth
		end
		if DebuffTypeEnabled(debuffType) and DEBUFF_COLORS[debuffType] then
			return DEBUFF_COLORS[debuffType], debuffType
		end
	end

	return nil
end

local function UnitHasPolymorph(unit)
	if not unit or not UnitExists(unit) or not UnitDebuff then
		return false
	end

	for index = 1, 40 do
		local name = UnitDebuff(unit, index)
		if not name then
			return false
		end

		local lowerName = string.lower(name)
		if lowerName == "polymorph" or string.find(lowerName, "polymorph", 1, true) then
			return true
		end
	end

	return false
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

local function FindGroupUnitByGUID(guid)
	if not guid then
		return nil
	end

	for _, unit in ipairs(GetRaidUnits()) do
		if UnitGUID(unit) == guid then
			return unit
		end
	end

	for _, unit in ipairs({ "player", "target", "mouseover", "targettarget", "pet" }) do
		if UnitExists(unit) and UnitGUID(unit) == guid then
			return unit
		end
	end

	for index = 1, 40 do
		for _, unit in ipairs({ "raid" .. index .. "pet", "raidpet" .. index }) do
			if UnitExists(unit) and UnitGUID(unit) == guid then
				return unit
			end
		end
	end

	for index = 1, 4 do
		for _, unit in ipairs({ "party" .. index .. "pet", "partypet" .. index }) do
			if UnitExists(unit) and UnitGUID(unit) == guid then
				return unit
			end
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

	local aIndex = a.raidIndex or a.partyIndex or 0
	local bIndex = b.raidIndex or b.partyIndex or 0
	if aIndex ~= bIndex then
		return aIndex < bIndex
	end

	return SortByVisualPosition(a, b)
end

local function GetPartySortIndex(unit)
	if unit == "player" then
		return 0
	end

	local partyIndex = unit and tonumber(string.match(unit, "^party(%d+)$"))
	if partyIndex then
		return partyIndex
	end

	return nil
end

local function IsDiscreteGroupMemberFrame(frame)
	local name = frame and frame:GetName()
	return name and string.match(name, "^CompactRaidGroup%d+Member%d+$")
end

local function UnitHasNamedAura(unit, auraName, warnBeforeExpirySeconds)
	if not unit or not auraName then
		return false
	end

	for index = 1, 40 do
		local name, _, _, _, duration, expirationTime = UnitBuff(unit, index)
		if not name then
			return false
		end

		if name == auraName then
			local warningSeconds = tonumber(warnBeforeExpirySeconds) or 0
			if warningSeconds <= 0 or not duration or duration <= 0 or not expirationTime or expirationTime <= 0 then
				return true
			end
			if (expirationTime - (GetTime and GetTime() or 0)) > warningSeconds then
				return true
			end
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

		if UnitHasNamedAura(unit, auraName, config.warnBeforeExpirySeconds) then
			return true
		end

		for auraPart in string.gmatch(auraName, "([^,;]+)") do
			local trimmedAuraName = string.gsub(auraPart, "^%s*(.-)%s*$", "%1")
			if trimmedAuraName ~= auraName and trimmedAuraName ~= "" and UnitHasNamedAura(unit, trimmedAuraName, config.warnBeforeExpirySeconds) then
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

local function EnableCompactPartyFrames()
	if SetCVar then
		pcall(SetCVar, "useCompactPartyFrames", "1")
	end

	if _G.CompactRaidFrameManager_UpdateShown then
		pcall(_G.CompactRaidFrameManager_UpdateShown)
	end
	if _G.CompactPartyFrame_UpdateShown then
		pcall(_G.CompactPartyFrame_UpdateShown)
	end
	Underheal.raidMemberFrameCacheDirty = true
end

function Underheal:ApplyGroupProfile()
	if InCombatLockdown() then
		self.pendingGroupProfile = true
		return
	end

	EnableCompactPartyFrames()
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

	local groupsPerRow = UnderhealDB.raidFrame.groupsPerRow or 4

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
	local now = GetTime and GetTime() or 0
	if self.raidMemberFrameCache and not self.raidMemberFrameCacheDirty and self.raidMemberFrameCacheTime and (now - self.raidMemberFrameCacheTime) < 0.1 then
		return self.raidMemberFrameCache
	end

	local frames = {}
	local seen = {}

	local function AddFrame(frame, unitOverride)
		if not frame or seen[frame] or not frame:IsShown() then
			return
		end

		local unit = unitOverride or frame.unit or frame.displayedUnit or (frame.GetAttribute and frame:GetAttribute("unit"))
		if not unit or not UnitExists(unit) then
			return
		end

		local raidIndex = UnitInRaid(unit)
		if not raidIndex then
			raidIndex = tonumber(string.match(unit, "^raid(%d+)$"))
		end

		local subgroup
		local partyIndex
		if raidIndex then
			subgroup = select(3, GetRaidRosterInfo(raidIndex))
			if not subgroup then
				return
			end
		else
			partyIndex = GetPartySortIndex(unit)
			if not partyIndex then
				return
			end
			subgroup = 1
		end

		seen[frame] = true
		frames[#frames + 1] = {
			frame = frame,
			unit = unit,
			name = frame:GetName(),
			raidIndex = raidIndex,
			partyIndex = partyIndex,
			subgroup = subgroup,
			left = frame:GetLeft() or 0,
			top = frame:GetTop() or 0,
		}
	end

	for index = 1, 40 do
		AddFrame(_G["CompactRaidFrame" .. index])
	end

	for group = 1, 8 do
		for member = 1, 5 do
			AddFrame(_G["CompactRaidGroup" .. group .. "Member" .. member])
		end
	end

	if IsInGroup and IsInGroup() and not (IsInRaid and IsInRaid()) then
		AddFrame(_G.CompactPartyFrameMemberSelf, "player")
		for index = 1, 5 do
			AddFrame(_G["CompactPartyFrameMember" .. index])
		end
	end

	self.raidMemberFrameCache = frames
	self.raidMemberFrameCacheTime = now
	self.raidMemberFrameCacheDirty = nil
	return frames
end

function Underheal:GetRaidMemberBounds()
	local frames = self:GetRaidMemberFrames()
	local left, right, top, bottom

	for _, info in ipairs(frames) do
		local frame = info.frame
		if frame and frame:IsShown() and frame:GetLeft() and frame:GetRight() and frame:GetTop() and frame:GetBottom() then
			left = left and math.min(left, frame:GetLeft()) or frame:GetLeft()
			right = right and math.max(right, frame:GetRight()) or frame:GetRight()
			top = top and math.max(top, frame:GetTop()) or frame:GetTop()
			bottom = bottom and math.min(bottom, frame:GetBottom()) or frame:GetBottom()
		end
	end

	if not left or not right or not top or not bottom then
		return nil
	end

	return {
		center = left + ((right - left) / 2),
		top = top,
		bottom = bottom,
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

	local partySelf = _G.CompactPartyFrameMemberSelf
	if partySelf and partySelf.UnderhealGroupMarker then
		partySelf.UnderhealGroupMarker:Hide()
	end

	for index = 1, 5 do
		local frame = _G["CompactPartyFrameMember" .. index]
		if frame and frame.UnderhealGroupMarker then
			frame.UnderhealGroupMarker:Hide()
		end
	end
end

function Underheal:GroupHasVisibleMember(groupIndex)
	for member = 1, 5 do
		local frame = _G["CompactRaidGroup" .. groupIndex .. "Member" .. member]
		if frame and frame:IsShown() then
			local unit = frame.unit or frame.displayedUnit or (frame.GetAttribute and frame:GetAttribute("unit"))
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
	if not (IsInRaid and IsInRaid()) then
		return false
	end

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

	if not (IsInRaid and IsInRaid()) then
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

	local sortedFrames = {}
	for index, info in ipairs(frames) do
		sortedFrames[index] = info
	end
	table.sort(sortedFrames, SortByRaidGroup)

	local lastSubgroup
	for _, info in ipairs(sortedFrames) do
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
	if not PlayerKnowsSpell(config.cast) and not PlayerKnowsSpell(config.fallbackCast) then
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
	if GetUnitSpecialState(unit) then
		return nil
	end

	local config = self:GetBestMissingBuffConfig(unit, raidIndex)
	if InCombatLockdown() and config and not config.combatPriority then
		return nil
	end

	return config
end

function Underheal:GetCombatClickBuffConfig(unit, raidIndex)
	if not UnderhealDB.raidFrame.clickToBuff or GetUnitSpecialState(unit) then
		return nil
	end

	for _, config in ipairs(UnderhealDB.buffButtons) do
		if config and config.combatPriority and self:BuffAppliesToUnit(config, unit, raidIndex) then
			return config
		end
	end

	return nil
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

function Underheal:AddBuffCastLines(lines, condition, unit, config)
	if not config or not config.cast or config.cast == "" then
		return
	end

	local macroCondition = condition and condition ~= "" and condition .. ",@" .. unit or "@" .. unit
	local spell = config.cast
	if config.reagent and config.reagent ~= "" and config.fallbackCast and config.fallbackCast ~= "" and GetItemCount and GetItemCount(config.reagent) < 1 then
		spell = config.fallbackCast
	end
	lines[#lines + 1] = "/cast [" .. macroCondition .. "] " .. spell
end

function Underheal:BuildDirectBuffMacro(unit, config)
	local lines = {}
	local spell = config and config.fallbackCast
	if not spell or spell == "" then
		spell = config and config.cast
	end
	if spell and spell ~= "" then
		lines[#lines + 1] = "/cast [@" .. unit .. "] " .. spell
	end
	return table.concat(lines, "\n")
end

function Underheal:BuildClickBuffMacro(unit, buffConfig, combatBuffConfig)
	local leftConfig = UnderhealDB.clickCasts.none or {}
	local fallbackSpell = leftConfig.left or ""
	local lines = {}

	if combatBuffConfig and combatBuffConfig.cast and combatBuffConfig.cast ~= "" then
		self:AddBuffCastLines(lines, "combat", unit, combatBuffConfig)
		if buffConfig and buffConfig.cast and buffConfig.cast ~= "" then
			self:AddBuffCastLines(lines, "nocombat", unit, buffConfig)
		elseif fallbackSpell ~= "" then
			lines[#lines + 1] = "/cast [nocombat,@" .. unit .. "] " .. fallbackSpell
		end
		if fallbackSpell ~= "" then
			lines[#lines + 1] = "/cast [combat,@" .. unit .. "] " .. fallbackSpell
		end
		return table.concat(lines, "\n")
	end

	if fallbackSpell ~= "" and leftConfig.useTrinkets then
		lines[#lines + 1] = "/use [combat] 13"
		lines[#lines + 1] = "/use [combat] 14"
	end

	if fallbackSpell ~= "" then
		self:AddBuffCastLines(lines, "nocombat", unit, buffConfig)
		lines[#lines + 1] = "/cast [@" .. unit .. "] " .. fallbackSpell
	elseif buffConfig then
		self:AddBuffCastLines(lines, "nocombat", unit, buffConfig)
	end

	return table.concat(lines, "\n")
end

function Underheal:BuildDeadUnitMacro(unit, fallbackSpell, useTrinkets)
	local resSpell = GetResurrectionSpell()
	local lines = {}
	if useTrinkets then
		lines[#lines + 1] = "/use [combat] 13"
		lines[#lines + 1] = "/use [combat] 14"
	end

	if resSpell and fallbackSpell and fallbackSpell ~= "" then
		lines[#lines + 1] = "/cast [nocombat,@" .. unit .. ",dead] " .. resSpell .. "; [@" .. unit .. "] " .. fallbackSpell
	elseif resSpell then
		lines[#lines + 1] = "/cast [nocombat,@" .. unit .. ",dead] " .. resSpell
	elseif fallbackSpell and fallbackSpell ~= "" then
		lines[#lines + 1] = "/cast [@" .. unit .. "] " .. fallbackSpell
	end

	return table.concat(lines, "\n")
end

function Underheal:CaptureCastTarget(unit, fallbackName)
	self.pendingCastTargetTime = GetTime and GetTime() or 0
	self.pendingCastTargetName = fallbackName or (unit and UnitName(unit)) or nil
	self.pendingCastTargetGUID = unit and UnitExists(unit) and UnitGUID(unit) or nil
end

function Underheal:MaybeCancelCastForNewTarget(unit)
	if not UnderhealDB.raidFrame.superResponsiveMode or not unit or not UnitExists(unit) then
		return
	end
	if not UnitCastingInfo("player") and not (UnitChannelInfo and UnitChannelInfo("player")) then
		return
	end

	local clickedGUID = UnitGUID(unit)
	if clickedGUID and self.outgoingHealTargetGUID and clickedGUID ~= self.outgoingHealTargetGUID and SpellStopCasting then
		SpellStopCasting()
	end
end

function Underheal:HookCastTargetCapture(button)
	if not button or button.UnderhealCastTargetCaptureHooked then
		return
	end

	button:HookScript("PreClick", function(self)
		local unit = self:GetAttribute("unit") or self:GetAttribute("unit1")
		if unit and UnitExists(unit) then
			Underheal:MaybeCancelCastForNewTarget(unit)
			Underheal:CaptureCastTarget(unit)
		end
	end)
	button.UnderhealCastTargetCaptureHooked = true
end

function Underheal:SetClickCastAttributes(button, unit)
	self:HookCastTargetCapture(button)

	if InCombatLockdown() then
		return
	end

	button:SetAttribute("type", nil)
	button:SetAttribute("spell", nil)
	button:SetAttribute("unit", nil)
	button:SetAttribute("unit", unit)

	local specialState = GetUnitSpecialState(unit)
	if specialState == "MINDCONTROLLED" then
		for _, entry in ipairs(CLICK_CAST_ORDER) do
			local prefix = entry.prefix
			button:SetAttribute(prefix .. "type1", nil)
			button:SetAttribute(prefix .. "spell1", nil)
			button:SetAttribute(prefix .. "macrotext1", nil)
			button:SetAttribute(prefix .. "unit1", nil)
			button:SetAttribute(prefix .. "type2", nil)
			button:SetAttribute(prefix .. "spell2", nil)
			button:SetAttribute(prefix .. "macrotext2", nil)
			button:SetAttribute(prefix .. "unit2", nil)
		end
		return
	end

	for _, entry in ipairs(CLICK_CAST_ORDER) do
		local config = UnderhealDB.clickCasts[entry.key]
		local prefix = entry.prefix
		local leftSpell = config and config.left or ""
		local rightSpell = config and config.right or ""
		local useTrinkets = config and config.useTrinkets

		if leftSpell and leftSpell ~= "" then
			if specialState == "RIP" and prefix == "" and GetResurrectionSpell() then
				button:SetAttribute(prefix .. "type1", "macro")
				button:SetAttribute(prefix .. "macrotext1", self:BuildDeadUnitMacro(unit, leftSpell, useTrinkets))
				button:SetAttribute(prefix .. "spell1", nil)
				button:SetAttribute(prefix .. "unit1", nil)
			elseif useTrinkets then
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
	self:HookCastTargetCapture(button)
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

function Underheal:IsMageUnit(unit)
	if not unit or not UnitExists(unit) then
		return false
	end

	local config = GetSpecialPowerConfig()
	local _, classFile = UnitClass(unit)
	return not config.targetClass or config.targetClass == "" or classFile == string.upper(config.targetClass)
end

function Underheal:IsChosenPIMage(unit)
	local chosen = GetSpecialPowerConfig().chosenPlayer
	if not chosen or chosen == "" or not unit or not UnitExists(unit) then
		return false
	end

	return NormalizePlayerName(UnitName(unit)) == NormalizePlayerName(chosen)
end

function Underheal:GetPowerInfusionButton(frame)
	if frame.UnderhealPIButton then
		return frame.UnderhealPIButton
	end

	local button = CreateFrame("Button", nil, frame, "SecureActionButtonTemplate")
	button:SetSize(24, 18)
	button:RegisterForClicks("AnyUp")
	self:HookCastTargetCapture(button)
	button:SetFrameLevel(frame:GetFrameLevel() + 9)

	local bg = button:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0.88, 0.68, 0.05, 0.78)
	button.bg = bg

	local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	text:SetPoint("CENTER", 0, 0)
	text:SetText(GetSpecialPowerConfig().label or "SP")
	button.text = text

	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		local config = GetSpecialPowerConfig()
		GameTooltip:SetText(config.spell ~= "" and config.spell or "Special Power")
		GameTooltip:AddLine("Click to cast on this player.", 1, 1, 1)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	button:Hide()

	frame.UnderhealPIButton = button
	return button
end

function Underheal:HidePowerInfusionButton(frame)
	if frame and frame.UnderhealPIButton then
		frame.UnderhealPIButton:Hide()
		frame.UnderhealPIButton.UnderhealPIPulse = nil
	end
	if frame and frame.UnderhealPIBorder then
		frame.UnderhealPIPulse = nil
		frame.UnderhealPIBorder:Hide()
	end
end

function Underheal:UpdatePowerInfusionVisual(frame, unit)
	if not frame then
		return false
	end

	local piReady = IsPowerInfusionReady()
	local active = false

	if frame.UnderhealPIButton and frame.UnderhealPIButton:IsShown() then
		frame.UnderhealPIButton.UnderhealPIPulse = piReady
		if piReady then
			frame.UnderhealPIButton.bg:SetColorTexture(1.0, 0.82, 0.05, 0.95)
			active = true
		else
			frame.UnderhealPIButton.bg:SetColorTexture(0.38, 0.32, 0.12, 0.72)
		end
	end

	if frame.UnderhealPIBorder then
		if unit and UnitExists(unit) and UnderhealDB.powerInfusion.enabled and self:IsChosenPIMage(unit) and piReady then
			frame.UnderhealPIPulse = true
			frame.UnderhealPIBorder:Show()
			active = true
		else
			frame.UnderhealPIPulse = nil
			frame.UnderhealPIBorder:Hide()
		end
	end

	return active
end

function Underheal:RefreshPowerInfusionVisuals()
	local active = false

	if self.selfWatch and self.selfWatch:IsShown() then
		active = self:UpdatePowerInfusionVisual(self.selfWatch, "player") or active
	end
	if self.targetOfTargetWatch and self.targetOfTargetWatch.button and self.targetOfTargetWatch:IsShown() then
		active = self:UpdatePowerInfusionVisual(self.targetOfTargetWatch.button, "targettarget") or active
	end

	local frames = self:GetRaidMemberFrames()
	for _, info in ipairs(frames) do
		active = self:UpdatePowerInfusionVisual(info.frame, info.unit) or active
	end

	self.hasActivePIPulse = active
end

function Underheal:EnsurePowerInfusionBorder(frame)
	if frame.UnderhealPIBorder then
		return frame.UnderhealPIBorder
	end

	local border = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
	border:SetPoint("TOPLEFT", frame, "TOPLEFT", -4, 4)
	border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 4, -4)
	border:SetFrameLevel(frame:GetFrameLevel() + 7)
	if border.SetBackdrop then
		border:SetBackdrop({
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 14,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		})
		border:SetBackdropBorderColor(1, 0.82, 0.05, 0.95)
	end
	border:Hide()

	frame.UnderhealPIBorder = border
	return border
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
	self:HidePowerInfusionButton(frame)
end

function Underheal:HideClassicPartyFrameOverlays()
	for index = 1, 4 do
		local frame = _G["PartyMemberFrame" .. index]
		if frame then
			self:HideBuffButtonsOnFrame(frame)
			if frame.UnderhealThreatBar then
				frame.UnderhealThreatBar:Hide()
			end
			if frame.UnderhealThreatBorder then
				frame.UnderhealThreatBorder:Hide()
			end
			if frame.UnderhealThreatTankIcon then
				frame.UnderhealThreatTankIcon:Hide()
			end
			if frame.UnderhealIncomingBar then
				frame.UnderhealIncomingBar:Hide()
			end
			if frame.UnderhealIncomingText then
				frame.UnderhealIncomingText:Hide()
			end
			if frame.UnderhealStatusText then
				frame.UnderhealStatusText:Hide()
			end
			if frame.UnderhealClassText then
				frame.UnderhealClassText:Hide()
			end
		end
	end
end

function Underheal:ApplyBuffButtonsToFrame(frame)
	if not frame then
		self:HideBuffButtonsOnFrame(frame)
		return
	end

	local unit = frame.unit or frame.displayedUnit or (frame.GetAttribute and frame:GetAttribute("unit"))
	if not unit or not UnitExists(unit) then
		self:HideBuffButtonsOnFrame(frame)
		return
	end

	local raidIndex = UnitInRaid(unit)
	if not raidIndex then
		raidIndex = tonumber(string.match(unit, "^raid(%d+)$"))
	end

	local specialPower = GetSpecialPowerConfig()
	if specialPower.enabled and PlayerKnowsSpell(specialPower.spell) and self:IsMageUnit(unit) then
		local piReady = IsPowerInfusionReady()
		local piButton = self:GetPowerInfusionButton(frame)
		piButton.text:SetText(specialPower.label or "SP")
		piButton:ClearAllPoints()
		piButton:SetPoint("LEFT", frame, "RIGHT", 3, 0)
		if not InCombatLockdown() then
			piButton:SetAttribute("type", "spell")
			piButton:SetAttribute("type1", "spell")
			piButton:SetAttribute("spell", specialPower.spell)
			piButton:SetAttribute("spell1", specialPower.spell)
			piButton:SetAttribute("unit", unit)
			piButton:SetAttribute("unit1", unit)
		end
		piButton:Show()
		if self:UpdatePowerInfusionVisual(frame, unit) then
			self.hasActivePIPulse = true
		end
	else
		self:HidePowerInfusionButton(frame)
	end

	local clickConfig = self:GetClickBuffConfig(unit, raidIndex)
	local combatClickConfig = self:GetCombatClickBuffConfig(unit, raidIndex)
	local clickButton = self:GetRaidClickBuffButton(frame)
	self:SetClickCastAttributes(clickButton, unit)
	clickButton.UnderhealBuffConfig = clickConfig
	if (clickConfig or combatClickConfig) and not InCombatLockdown() then
		clickButton:SetAttribute("type1", "macro")
		clickButton:SetAttribute("spell1", nil)
		clickButton:SetAttribute("unit1", nil)
		clickButton:SetAttribute("macrotext1", self:BuildClickBuffMacro(unit, clickConfig, combatClickConfig))
	end
	clickButton:Show()

	if not UnderhealDB.raidFrame.showBuffButtons then
		self:HideSideBuffButtonsOnFrame(frame)
		return
	end

	local visibleIndex = 0
	local visibleCount = 0
	for _, config in ipairs(UnderhealDB.buffButtons) do
		if config and config.enabled and config.cast ~= "" and self:BuffAppliesToUnit(config, unit, raidIndex) then
			visibleCount = visibleCount + 1
		end
	end

	local frameHeight = frame:GetHeight() or 36
	local buttonSize = 14
	local buttonGap = 1
	if visibleCount > 0 then
		buttonSize = math.min(16, math.max(6, math.floor((frameHeight - 2 - ((visibleCount - 1) * buttonGap)) / visibleCount)))
	end
	for index, config in ipairs(UnderhealDB.buffButtons) do
		local button = self:GetRaidBuffButton(frame, index)
		if not config or not config.enabled or config.cast == "" or not self:BuffAppliesToUnit(config, unit, raidIndex) then
			button:Hide()
		else
			visibleIndex = visibleIndex + 1
			button:ClearAllPoints()
			button:SetSize(buttonSize, buttonSize)
			button:SetPoint("TOPRIGHT", frame, "TOPLEFT", -3, -1 - ((visibleIndex - 1) * (buttonSize + buttonGap)))
			button.UnderhealBuffConfig = config

			if not InCombatLockdown() then
				button:SetAttribute("type", "macro")
				button:SetAttribute("type1", "macro")
				button:SetAttribute("spell", nil)
				button:SetAttribute("spell1", nil)
				button:SetAttribute("macrotext", self:BuildDirectBuffMacro(unit, config))
				button:SetAttribute("macrotext1", self:BuildDirectBuffMacro(unit, config))
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

	self:HideClassicPartyFrameOverlays()
	if self.selfWatch and self.selfWatch:IsShown() then
		self:ApplyBuffButtonsToFrame(self.selfWatch)
	end
	if self.targetOfTargetWatch and self.targetOfTargetWatch.button and self.targetOfTargetWatch:IsShown() then
		self:ApplyBuffButtonsToFrame(self.targetOfTargetWatch.button)
	end

	local frames = self:GetRaidMemberFrames()
	local hasDiscreteMembers = self:HasDiscreteGroupMembers()
	for _, info in ipairs(frames) do
		if IsDiscreteGroupMemberFrame(info.frame) or not hasDiscreteMembers then
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
		if info.frame.UnderhealIncomingBar then
			info.frame.UnderhealIncomingBar:Hide()
		end
		if info.frame.UnderhealIncomingText then
			info.frame.UnderhealIncomingText:Hide()
		end
		if info.frame.UnderhealStatusText then
			info.frame.UnderhealStatusText:Hide()
		end
	end

	if self.selfWatch then
		self:HideBuffButtonsOnFrame(self.selfWatch)
		if self.selfWatch.UnderhealThreatBar then
			self.selfWatch.UnderhealThreatBar:Hide()
		end
		if self.selfWatch.UnderhealThreatBorder then
			self.selfWatch.UnderhealThreatBorder:Hide()
		end
		if self.selfWatch.UnderhealThreatTankIcon then
			self.selfWatch.UnderhealThreatTankIcon:Hide()
		end
		if self.selfWatch.UnderhealIncomingBar then
			self.selfWatch.UnderhealIncomingBar:Hide()
		end
		if self.selfWatch.UnderhealIncomingText then
			self.selfWatch.UnderhealIncomingText:Hide()
		end
		if self.selfWatch.UnderhealStatusText then
			self.selfWatch.UnderhealStatusText:Hide()
		end
		self.selfWatch:Hide()
	end

	if self.targetOfTargetWatch then
		self:ClearTargetOfTargetButton()
		self.targetOfTargetWatch:Hide()
	end

	for index = 1, 4 do
		local frame = _G["PartyMemberFrame" .. index]
		if frame then
			self:HideBuffButtonsOnFrame(frame)
			if frame.UnderhealThreatBar then
				frame.UnderhealThreatBar:Hide()
			end
			if frame.UnderhealThreatBorder then
				frame.UnderhealThreatBorder:Hide()
			end
			if frame.UnderhealThreatTankIcon then
				frame.UnderhealThreatTankIcon:Hide()
			end
			if frame.UnderhealIncomingBar then
				frame.UnderhealIncomingBar:Hide()
			end
			if frame.UnderhealIncomingText then
				frame.UnderhealIncomingText:Hide()
			end
			if frame.UnderhealStatusText then
				frame.UnderhealStatusText:Hide()
			end
			if frame.UnderhealClassText then
				frame.UnderhealClassText:Hide()
			end
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

	frame.UnderhealThreatFlashHooked = true
end

function Underheal:EnsureStatusText(frame)
	if not frame or frame.UnderhealStatusText then
		return
	end

	local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	text:SetPoint("CENTER", frame, "CENTER", 0, 0)
	text:SetTextColor(1, 0.12, 0.08, 1)
	text:SetShadowColor(0, 0, 0, 1)
	text:SetShadowOffset(1, -1)
	text:Hide()
	frame.UnderhealStatusText = text
end

function Underheal:EnsureSubStatusText(frame)
	if not frame or frame.UnderhealSubStatusText then
		return
	end

	local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	text:SetPoint("TOP", frame, "CENTER", 0, -12)
	text:SetTextColor(1, 0.95, 0.1, 1)
	text:SetShadowColor(0, 0, 0, 1)
	text:SetShadowOffset(1, -1)
	text:Hide()
	frame.UnderhealSubStatusText = text
end

function Underheal:UpdateSpecialStatus(frame, specialState, dispellable)
	if not frame then
		return
	end

	self:EnsureStatusText(frame)
	self:EnsureSubStatusText(frame)

	if specialState then
		local displayText = specialState == "MINDCONTROLLED" and "!!MC!!" or specialState
		frame.UnderhealStatusText:SetText(displayText)
		if frame.UnderhealStatusText.SetScale then
			frame.UnderhealStatusText:SetScale(specialState == "MINDCONTROLLED" and 0.9 or 1)
		end
		if specialState == "FEIGN" then
			frame.UnderhealStatusText:SetTextColor(1, 0.82, 0.25, 1)
		elseif specialState == "MINDCONTROLLED" then
			frame.UnderhealStatusText:SetTextColor(1, 0.05, 0.95, 1)
		else
			frame.UnderhealStatusText:SetTextColor(1, 0.12, 0.08, 1)
		end
		frame.UnderhealStatusText:Show()

		if specialState == "MINDCONTROLLED" and dispellable then
			frame.UnderhealSubStatusText:SetText("DISPEL!!")
			frame.UnderhealSubStatusText:Show()
		else
			frame.UnderhealSubStatusText:Hide()
		end
	else
		if frame.UnderhealStatusText then
			frame.UnderhealStatusText:Hide()
		end
		if frame.UnderhealSubStatusText then
			frame.UnderhealSubStatusText:Hide()
		end
	end
end

function Underheal:EnsureCastFailWidgets(frame)
	if not frame or frame.UnderhealCastFailText then
		return
	end

	local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	text:SetPoint("CENTER", frame, "CENTER", 0, 0)
	text:SetTextColor(1, 0.05, 0.05, 1)
	text:SetShadowColor(0, 0, 0, 1)
	text:SetShadowOffset(2, -2)
	if text.SetScale then
		text:SetScale(0.95)
	end
	text:Hide()
	frame.UnderhealCastFailText = text

	local border = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
	border:SetPoint("TOPLEFT", frame, "TOPLEFT", -7, 7)
	border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 7, -7)
	border:SetFrameLevel(frame:GetFrameLevel() + 14)
	if border.SetBackdrop then
		border:SetBackdrop({
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 32,
			insets = { left = 6, right = 6, top = 6, bottom = 6 },
		})
		border:SetBackdropBorderColor(1, 0.02, 0.02, 1)
	end
	border:Hide()
	frame.UnderhealCastFailBorder = border
end

local function IsRangeOrLineOfSightError(message)
	if not message or message == "" then
		return nil
	end

	local lower = string.lower(message)
	if string.find(lower, "line of sight", 1, true) then
		return "!!LOS!!"
	elseif string.find(lower, "out of range", 1, true) or string.find(lower, "too far away", 1, true) then
		return "!!RANGE!!"
	end

	return nil
end

function Underheal:ResolvePendingCastTarget()
	local now = GetTime and GetTime() or 0
	if not self.pendingCastTargetTime or (now - self.pendingCastTargetTime) > 1.5 then
		return nil
	end

	local targetUnit = FindGroupUnitByGUID(self.pendingCastTargetGUID)
	if targetUnit then
		return targetUnit
	end

	return FindGroupUnitByName(self.pendingCastTargetName or self.pendingHealTargetName)
end

function Underheal:ShowCastFailFrame(frame, label)
	if not frame then
		return
	end

	self:EnsureCastFailWidgets(frame)
	frame.UnderhealCastFailUntil = (GetTime and GetTime() or 0) + 2.5
	frame.UnderhealCastFailLabel = label or "FAILED"
	if frame.UnderhealCastFailText then
		frame.UnderhealCastFailText:SetText(frame.UnderhealCastFailLabel)
		frame.UnderhealCastFailText:Show()
	end
	if frame.UnderhealCastFailBorder then
		frame.UnderhealCastFailBorder:Show()
	end
	self.hasActiveCastFail = true
end

function Underheal:ShowCastFailure(unit, label)
	if not unit or not UnitExists(unit) then
		return
	end

	if UnitIsUnit and UnitIsUnit(unit, "player") and self.selfWatch and self.selfWatch:IsShown() then
		self:ShowCastFailFrame(self.selfWatch, label)
	end

	for _, info in ipairs(self:GetRaidMemberFrames()) do
		if info.unit and UnitIsUnit and UnitIsUnit(info.unit, unit) then
			self:ShowCastFailFrame(info.frame, label)
		end
	end

	if self.tankWatch and self.tankWatch.buttons then
		for _, button in ipairs(self.tankWatch.buttons) do
			local buttonUnit = button:GetAttribute("unit")
			if button:IsShown() and buttonUnit and UnitIsUnit and UnitIsUnit(buttonUnit, unit) then
				self:ShowCastFailFrame(button, label)
			end
		end
	end

	if self.targetOfTargetWatch and self.targetOfTargetWatch.button and self.targetOfTargetWatch:IsShown() then
		local button = self.targetOfTargetWatch.button
		local buttonUnit = button:GetAttribute("unit")
		if buttonUnit and UnitIsUnit and UnitIsUnit(buttonUnit, unit) then
			self:ShowCastFailFrame(button, label)
		end
	end
end

function Underheal:HandleUIErrorMessage(message)
	local label = IsRangeOrLineOfSightError(message)
	if not label then
		return
	end

	local targetUnit = self:ResolvePendingCastTarget()
	if targetUnit then
		self:ShowCastFailure(targetUnit, label)
	end
	self.pendingCastTargetGUID = nil
	self.pendingCastTargetName = nil
	self.pendingCastTargetTime = nil
end

function Underheal:EnsureClassText(frame)
	if not frame or frame.UnderhealClassText then
		return
	end

	local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	text:SetPoint("BOTTOM", frame, "BOTTOM", 0, 2)
	text:SetTextColor(1, 1, 1, 0.92)
	text:SetShadowColor(0, 0, 0, 1)
	text:SetShadowOffset(1, -1)
	if text.SetScale then
		text:SetScale(0.82)
	end
	text:Hide()
	frame.UnderhealClassText = text
end

function Underheal:UpdateClassText(frame, unit)
	if not frame then
		return
	end

	self:EnsureClassText(frame)
	if not frame.UnderhealClassText then
		return
	end

	if not unit or not UnitExists(unit) then
		frame.UnderhealClassText:Hide()
		return
	end

	local className = UnitClass(unit)
	if className and className ~= "" then
		frame.UnderhealClassText:SetText(className)
		frame.UnderhealClassText:Show()
	else
		frame.UnderhealClassText:Hide()
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
	text:SetPoint("TOP", frame, "TOP", 0, -2)
	text:SetTextColor(0.45, 1.0, 1.0, 0.95)
	text:SetShadowColor(0, 0, 0, 1)
	text:SetShadowOffset(1, -1)
	text:Hide()
	frame.UnderhealIncomingText = text

	frame.UnderhealIncomingHooked = true
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
	local apiIncoming = incoming

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

	if apiIncoming and apiIncoming > 0 then
		frame.UnderhealIncomingText:SetText("+" .. math.floor(apiIncoming + 0.5))
	else
		frame.UnderhealIncomingText:SetText(remoteLabel or "incoming")
	end
	frame.UnderhealIncomingText:Show()
end

function Underheal:RefreshIncomingHeals()
	if self.selfWatch and self.selfWatch:IsShown() then
		self:UpdateIncomingHealFrame(self.selfWatch, "player")
	end

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

	if self.targetOfTargetWatch and self.targetOfTargetWatch.button and self.targetOfTargetWatch:IsShown() then
		local button = self.targetOfTargetWatch.button
		local unit = button:GetAttribute("unit")
		if unit and UnitExists(unit) then
			self:UpdateIncomingHealFrame(button, unit)
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
	if self.selfWatch then
		self.selfWatch.UnderhealThreatTopRank = nil
		if self.selfWatch.UnderhealThreatBar then
			self.selfWatch.UnderhealThreatBar:Hide()
		end
		if self.selfWatch.UnderhealThreatTankIcon then
			self.selfWatch.UnderhealThreatTankIcon:Hide()
		end
		if self.selfWatch.UnderhealThreatBorder and not self.selfWatch.UnderhealThreatFlashUntil then
			self.selfWatch.UnderhealThreatBorder:Hide()
		end
	end

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

	if self.tankWatch and self.tankWatch.buttons then
		for _, frame in ipairs(self.tankWatch.buttons) do
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

	if self.targetOfTargetWatch and self.targetOfTargetWatch.button then
		local frame = self.targetOfTargetWatch.button
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

	local raidFrames = self:GetRaidMemberFrames()
	local frames = {}
	for index, info in ipairs(raidFrames) do
		frames[index] = info
	end
	if self.selfWatch and self.selfWatch:IsShown() then
		frames[#frames + 1] = {
			frame = self.selfWatch,
			unit = "player",
		}
	end
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
	if self.targetOfTargetWatch and self.targetOfTargetWatch.button and self.targetOfTargetWatch:IsShown() then
		local button = self.targetOfTargetWatch.button
		local unit = button:GetAttribute("unit")
		if unit and UnitExists(unit) then
			frames[#frames + 1] = {
				frame = button,
				unit = unit,
				raidIndex = UnitInRaid(unit),
			}
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
	local hasDiscreteMembers = self:HasDiscreteGroupMembers()

	for _, info in ipairs(frames) do
		local frame = info.frame
		local isUnderhealFrame = frame == self.selfWatch
			or (frame and self.tankWatch and frame:GetParent() == self.tankWatch)
			or (self.targetOfTargetWatch and frame == self.targetOfTargetWatch.button)
		if frame and (isUnderhealFrame or IsDiscreteGroupMemberFrame(frame) or not hasDiscreteMembers) then
			local unit = info.unit or frame.unit or frame.displayedUnit or (frame.GetAttribute and frame:GetAttribute("unit"))
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
			self.hasActiveThreatFlash = true
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

function Underheal:SkinRaidMemberFrame(frame, healthOnly)
	if not frame or not UnderhealDB.raidFrame.skinRaidFrames then
		return
	end

	self:EnsureThreatWidgets(frame)
	self:EnsureStatusText(frame)
	local unit = frame.unit or frame.displayedUnit or (frame.GetAttribute and frame:GetAttribute("unit"))
	self:UpdateClassText(frame, unit)

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
		if unit and UnitExists(unit) and healthBar.SetMinMaxValues and healthBar.SetValue then
			local healthMax = math.max(1, UnitHealthMax(unit) or 1)
			local health = UnitHealth(unit) or 0
			healthBar:SetMinMaxValues(0, healthMax)
			healthBar:SetValue(health)
			frame.UnderhealSyncedHealth = health
			frame.UnderhealSyncedHealthMax = healthMax
		end
		if healthBar.SetStatusBarTexture then
			healthBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
		end

			local healthPercent = 1
			local raidIndex
			local specialState
			local specialDispel
			if unit and UnitExists(unit) then
				specialState, specialDispel = GetUnitSpecialState(unit)
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
			if unit and UnitExists(unit) and not specialState and not healthOnly and UnderhealDB.raidFrame.showBuffColors then
				missingBuffConfig = self:GetBestMissingBuffConfig(unit, raidIndex)
			end
			if missingBuffConfig and healthPercent >= 0.1 then
				r, g, b = self:GetBuffButtonColor(missingBuffConfig, unit, raidIndex)
				frame.UnderhealCachedBuffColor = frame.UnderhealCachedBuffColor or {}
				frame.UnderhealCachedBuffColor.r = r
				frame.UnderhealCachedBuffColor.g = g
				frame.UnderhealCachedBuffColor.b = b
			elseif not healthOnly or not UnderhealDB.raidFrame.showBuffColors then
				frame.UnderhealCachedBuffColor = nil
			elseif healthOnly and frame.UnderhealCachedBuffColor and healthPercent >= 0.1 and not specialState then
				r, g, b = frame.UnderhealCachedBuffColor.r, frame.UnderhealCachedBuffColor.g, frame.UnderhealCachedBuffColor.b
			end
			if unit and UnitExists(unit) and not specialState and not healthOnly then
				local debuffColor = GetBestDebuffColor(unit)
				if debuffColor then
					r, g, b = debuffColor.r, debuffColor.g, debuffColor.b
					frame.UnderhealCachedDebuffColor = frame.UnderhealCachedDebuffColor or {}
					frame.UnderhealCachedDebuffColor.r = r
					frame.UnderhealCachedDebuffColor.g = g
					frame.UnderhealCachedDebuffColor.b = b
				else
					frame.UnderhealCachedDebuffColor = nil
				end
			elseif healthOnly and frame.UnderhealCachedDebuffColor and not specialState then
				r, g, b = frame.UnderhealCachedDebuffColor.r, frame.UnderhealCachedDebuffColor.g, frame.UnderhealCachedDebuffColor.b
			end
			if specialState == "RIP" then
				r, g, b = 0.24, 0.24, 0.24
			elseif specialState == "FEIGN" then
				r, g, b = 0.55, 0.42, 0.18
			elseif specialState == "MINDCONTROLLED" then
				r, g, b = 0.72, 0.05, 0.78
			end
			if healthBar.SetStatusBarColor then
				healthBar:SetStatusBarColor(r, g, b, 0.95)
			end

		if healthBar.SetAlpha then
			healthBar:SetAlpha(1)
		end

		frame.UnderhealFlashHealth = healthPercent < 0.1 and not specialState
		frame.UnderhealFlashElapsed = frame.UnderhealFlashHealth and (frame.UnderhealFlashElapsed or 0) or 0
		if frame.UnderhealFlashHealth then
			self.hasActiveHealthFlash = true
		end

		if frame.UnderhealSkinBackground then
			frame.UnderhealSkinBackground:SetColorTexture(0.02, 0.08, 0.03, 0.88)
		end

		self:UpdateSpecialStatus(frame, specialState, specialDispel)

		if unit and UnitExists(unit) then
			self:UpdateIncomingHealFrame(frame, unit)
		end

		frame.UnderhealFlashHooked = true
	end

	if unit and UnitExists(unit) and UnderhealDB.powerInfusion.enabled and self:IsChosenPIMage(unit) and IsPowerInfusionReady() then
		local piBorder = self:EnsurePowerInfusionBorder(frame)
		frame.UnderhealPIPulse = true
		piBorder:Show()
		self.hasActivePIPulse = true
	elseif frame.UnderhealPIBorder then
		frame.UnderhealPIPulse = nil
		frame.UnderhealPIBorder:Hide()
	end
	self:UpdatePowerInfusionVisual(frame, unit)

	local name = frame.name or frame.Name
	if name and name.SetTextColor then
		name:SetTextColor(1, 1, 1)
	end
end

function Underheal:SkinRaidFrames()
	if not UnderhealDB.raidFrame.skinRaidFrames then
		return
	end

	self:HideClassicPartyFrameOverlays()
	self:UpdateSelfWatch()

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

function Underheal:UpdateRaidUnitVisual(unit, updateBuffButtons)
	if not unit or not UnitExists(unit) then
		return
	end

	if unit == "player" and self.selfWatch then
		self:UpdateSelfWatch()
	end

	local frames = self:GetRaidMemberFrames()
	for _, info in ipairs(frames) do
		local frame = info.frame
		local frameUnit = info.unit or frame.unit or frame.displayedUnit or (frame.GetAttribute and frame:GetAttribute("unit"))
		if frameUnit == unit or (UnitIsUnit and UnitIsUnit(frameUnit, unit)) then
			self:SkinRaidMemberFrame(frame, not updateBuffButtons)
			if updateBuffButtons and not InCombatLockdown() then
				self:ApplyBuffButtonsToFrame(frame)
			end
		end
	end
end

function Underheal:GetSelfWatchFrame()
	if self.selfWatch then
		return self.selfWatch
	end

	local frame = CreateFrame("Button", "UnderhealSelfWatchFrame", UIParent, "SecureUnitButtonTemplate")
	frame:SetFrameStrata("MEDIUM")
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForClicks("AnyUp")
	frame:SetAttribute("unit", "player")

	local bg = frame:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0.02, 0.08, 0.03, 0.88)
	frame.bg = bg

	local healthBar = CreateFrame("StatusBar", nil, frame)
	healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
	healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
	healthBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
	healthBar:SetMinMaxValues(0, 1)
	healthBar:SetValue(1)
	healthBar:SetFrameLevel(frame:GetFrameLevel() + 1)
	frame.healthBar = healthBar

	local name = healthBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	name:SetPoint("LEFT", 8, 8)
	name:SetPoint("RIGHT", frame, "CENTER", -6, 0)
	name:SetJustifyH("LEFT")
	frame.name = name

	local healthText = healthBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	healthText:SetPoint("TOPRIGHT", -8, -7)
	healthText:SetJustifyH("RIGHT")
	frame.healthText = healthText

	local manaText = healthBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	manaText:SetPoint("BOTTOMRIGHT", -8, 7)
	manaText:SetJustifyH("RIGHT")
	manaText:SetTextColor(0.55, 0.75, 1.0, 1)
	frame.manaText = manaText

	local dragHandle = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
	dragHandle:SetSize(430, 26)
	dragHandle:SetPoint("BOTTOM", frame, "TOP", 0, 4)
	dragHandle:SetFrameLevel(frame:GetFrameLevel() + 12)
	dragHandle:EnableMouse(true)
	dragHandle:RegisterForDrag("LeftButton")
	if dragHandle.SetBackdrop then
		dragHandle:SetBackdrop({
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true,
			tileSize = 8,
			edgeSize = 8,
			insets = { left = 2, right = 2, top = 2, bottom = 2 },
		})
		dragHandle:SetBackdropColor(0.05, 0.16, 0.20, 0.9)
		dragHandle:SetBackdropBorderColor(0.95, 0.85, 0.25, 1)
	end
	local dragText = dragHandle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	dragText:SetPoint("LEFT", 8, 1)
	dragText:SetText("Use this to heal or cast on yourself. Drag to a suitable position.")
	dragHandle.text = dragText
	local okay = CreateFrame("Button", nil, dragHandle, "UIPanelButtonTemplate")
	okay:SetSize(42, 20)
	okay:SetPoint("RIGHT", dragHandle, "RIGHT", -3, 0)
	okay:SetText("OK")
	dragHandle.okay = okay
	dragHandle:SetScript("OnDragStart", function()
		if (UnderhealDB.raidFrame.unlocked or not UnderhealDB.selfWatch.setupConfirmed) and not InCombatLockdown() then
			frame.UnderhealMoving = true
			frame:StartMoving()
		end
	end)
	dragHandle:SetScript("OnDragStop", function()
		frame:StopMovingOrSizing()
		frame.UnderhealMoving = nil
		if frame:GetLeft() and frame:GetTop() then
			UnderhealDB.selfWatch.x = frame:GetLeft()
			UnderhealDB.selfWatch.y = frame:GetTop()
			UnderhealDB.selfWatch.hasPosition = true
			if UnderhealDB.selfWatch.setupConfirmed then
				Underheal:PositionSelfWatchFrame()
			end
		end
	end)
	okay:SetScript("OnClick", function()
		if frame:GetLeft() and frame:GetTop() then
			UnderhealDB.selfWatch.x = frame:GetLeft()
			UnderhealDB.selfWatch.y = frame:GetTop()
		end
		UnderhealDB.selfWatch.hasPosition = true
		UnderhealDB.selfWatch.setupConfirmed = true
		Underheal:PositionSelfWatchFrame()
		Underheal:UpdateSelfWatchDragState()
	end)
	dragHandle:Hide()
	frame.dragHandle = dragHandle

	self:EnsureThreatWidgets(frame)
	self:EnsureStatusText(frame)
	frame:Hide()
	self.selfWatch = frame
	return frame
end

function Underheal:UpdateSelfWatchDragState()
	if not self.selfWatch or not self.selfWatch.dragHandle then
		return
	end

	if not UnderhealDB.selfWatch.setupConfirmed then
		self.selfWatch.dragHandle:SetSize(430, 26)
		self.selfWatch.dragHandle.text:SetText("Use this to heal or cast on yourself. Drag to a suitable position.")
		self.selfWatch.dragHandle.okay:Show()
	elseif UnderhealDB.raidFrame.unlocked then
		self.selfWatch.dragHandle:SetSize(54, 16)
		self.selfWatch.dragHandle.text:SetText("drag")
		self.selfWatch.dragHandle.okay:Hide()
	end

	if (UnderhealDB.raidFrame.unlocked or not UnderhealDB.selfWatch.setupConfirmed) and not InCombatLockdown() then
		self.selfWatch.dragHandle:Show()
	else
		self.selfWatch.dragHandle:Hide()
	end
end

function Underheal:GetClampedSelfWatchPosition(width, height, x, y)
	local parentWidth = UIParent:GetWidth() or 0
	local parentHeight = UIParent:GetHeight() or 0
	if parentWidth <= 0 or parentHeight <= 0 then
		return x, y
	end

	x = math.max(0, math.min(x or defaults.selfWatch.x, math.max(0, parentWidth - (width or 260))))
	y = math.max(height or 24, math.min(y or defaults.selfWatch.y, parentHeight))
	return x, y
end

function Underheal:PositionSelfWatchFrame()
	if InCombatLockdown() and not self.selfWatch then
		self.pendingSelfUpdate = true
		return false
	end

	local frame = self:GetSelfWatchFrame()
	if frame.UnderhealMoving then
		return true
	end

	local width = 260
	local bounds = self:GetRaidMemberBounds()
	if bounds then
		width = math.max(width, bounds.right - bounds.left)
	end
	local memberHeight = 36
	local members = self:GetRaidMemberFrames()
	if members[1] and members[1].frame and members[1].frame:GetHeight() then
		memberHeight = members[1].frame:GetHeight()
	end
	local height = math.max(48, math.min(80, math.floor(memberHeight * 1.5)))

	frame:SetSize(width, height)
	frame:ClearAllPoints()
	if UnderhealDB.selfWatch.hasPosition then
		local x, y = self:GetClampedSelfWatchPosition(width, height, UnderhealDB.selfWatch.x, UnderhealDB.selfWatch.y)
		UnderhealDB.selfWatch.x = x
		UnderhealDB.selfWatch.y = y
		frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
	else
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
	return true
end

function Underheal:UpdateSelfWatch()
	if InCombatLockdown() and not self.selfWatch then
		self.pendingSelfUpdate = true
		return
	end

	local frame = self:GetSelfWatchFrame()
	if InCombatLockdown() then
		if not frame:IsShown() then
			self.pendingSelfUpdate = true
			return
		end
	elseif not self:PositionSelfWatchFrame() then
		return
	end

	if not InCombatLockdown() then
		frame:SetAttribute("unit", "player")
	end
	self:UpdateSelfWatchDragState()
	if frame.name then
		frame.name:SetText(UnitName("player") or "Me")
	end
	if frame.healthText then
		frame.healthText:SetText((UnitHealth("player") or 0) .. "/" .. (UnitHealthMax("player") or 0))
	end
	if frame.manaText then
		frame.manaText:SetText((UnitPower("player") or 0) .. "/" .. (UnitPowerMax("player") or 0))
	end
	if frame.healthBar then
		frame.healthBar:SetMinMaxValues(0, math.max(1, UnitHealthMax("player") or 1))
		frame.healthBar:SetValue(UnitHealth("player") or 0)
	end

	self:SkinRaidMemberFrame(frame)
	if not InCombatLockdown() then
		self:SetClickCastAttributes(frame, "player")
		self:ApplyBuffButtonsToFrame(frame)
	end
	if not InCombatLockdown() then
		frame:Show()
	end
	self:UpdateLowHealthAlert()
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

	frame:SetScale(1)

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	title:SetPoint("TOPLEFT", 8, -7)
	title:SetText("Raid Pets")
	frame.title = title

	frame.buttons = {}
	frame:SetScript("OnDragStart", function(self)
		if UnderhealDB.raidFrame.unlocked and not InCombatLockdown() then
			self.UnderhealMoving = true
			self:StartMoving()
		end
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		self.UnderhealMoving = nil
		if self:GetLeft() and self:GetTop() then
			UnderhealDB.pets.x = self:GetLeft()
			UnderhealDB.pets.y = self:GetTop()
		end
		Underheal:PositionPetWatchFrame()
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
	if frame.UnderhealMoving then
		return
	end
	frame:SetScale(1)
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
	local seen = {}
	local function AddPetUnit(unit)
		if UnitExists(unit) then
			local guid = UnitGUID(unit) or unit
			if not seen[guid] then
				seen[guid] = true
				pets[#pets + 1] = unit
			end
		end
	end

	if IsInRaid and IsInRaid() then
		for index = 1, 40 do
			AddPetUnit("raid" .. index .. "pet")
			AddPetUnit("raidpet" .. index)
		end
	else
		AddPetUnit("pet")
		for index = 1, 4 do
			AddPetUnit("party" .. index .. "pet")
			AddPetUnit("partypet" .. index)
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
		local healthCurrent = UnitHealth(unit) or 0
		local healthPercent = 1
		if healthMax and healthMax > 0 then
			healthPercent = healthCurrent / healthMax
		end

			button:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -28 - ((index - 1) * 28))
			button:SetAttribute("unit", unit)
			button.health:SetWidth(math.max(1, 104 * healthPercent))
			button.UnderhealSyncedHealth = healthCurrent
			button.UnderhealSyncedHealthMax = math.max(1, healthMax or 1)
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

	local resizeGrip = CreateFrame("Button", nil, frame)
	resizeGrip:SetSize(16, 16)
	resizeGrip:SetPoint("BOTTOMRIGHT", -3, 3)
	resizeGrip:EnableMouse(true)
	resizeGrip.bg = resizeGrip:CreateTexture(nil, "OVERLAY")
	resizeGrip.bg:SetAllPoints()
	resizeGrip.bg:SetColorTexture(0.95, 0.85, 0.25, 0.75)
	resizeGrip.text = resizeGrip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	resizeGrip.text:SetPoint("CENTER", 0, 0)
	resizeGrip.text:SetText("+")
	resizeGrip:SetScript("OnMouseDown", function(self, buttonName)
		if buttonName ~= "LeftButton" or not UnderhealDB.raidFrame.unlocked or InCombatLockdown() then
			return
		end

		local uiScale = UIParent:GetEffectiveScale() or 1
		local cursorX, cursorY = GetCursorPosition()
		self.resizing = true
		self.startX = cursorX / uiScale
		self.startY = cursorY / uiScale
		self.startScale = GetTankScale()
		if frame:GetLeft() and frame:GetTop() then
			UnderhealDB.tanks.x = frame:GetLeft() * self.startScale
			UnderhealDB.tanks.y = frame:GetTop() * self.startScale
		end
	end)
	resizeGrip:SetScript("OnMouseUp", function(self)
		self.resizing = nil
		UnderhealDB.tanks.scale = GetTankScale()
		Underheal:PositionTankWatchFrame()
	end)
	resizeGrip:SetScript("OnUpdate", function(self)
		if not self.resizing then
			return
		end

		local uiScale = UIParent:GetEffectiveScale() or 1
		local cursorX, cursorY = GetCursorPosition()
		cursorX = cursorX / uiScale
		cursorY = cursorY / uiScale
		local delta = ((cursorX - self.startX) - (cursorY - self.startY)) / 240
		local scale = self.startScale + delta
		if scale < 0.75 then
			scale = 0.75
		elseif scale > 2.0 then
			scale = 2.0
		end

		UnderhealDB.tanks.scale = scale
		Underheal:PositionTankWatchFrame()
	end)
	resizeGrip:Hide()
	frame.resizeGrip = resizeGrip

	frame.buttons = {}
	frame:SetScript("OnDragStart", function(self)
		if UnderhealDB.raidFrame.unlocked and not InCombatLockdown() then
			self.UnderhealMoving = true
			self:StartMoving()
		end
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		self.UnderhealMoving = nil
		if self:GetLeft() and self:GetTop() then
			local scale = GetTankScale()
			UnderhealDB.tanks.x = self:GetLeft() * scale
			UnderhealDB.tanks.y = self:GetTop() * scale
			UnderhealDB.tanks.hasPosition = true
		end
		Underheal:PositionTankWatchFrame()
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

	local renewText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	renewText:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -5, 1)
	renewText:SetTextColor(0.45, 1, 0.45, 1)
	renewText:SetShadowColor(0, 0, 0, 1)
	renewText:SetShadowOffset(1, -1)
	renewText:SetText("Renew")
	renewText:Hide()
	button.renewText = renewText

	self:EnsureThreatWidgets(button)
	self:EnsureStatusText(button)
	self:EnsureClassText(button)

	frame.buttons[index] = button
	return button
end

function Underheal:UpdateTankButtonVisual(button, unit)
	if not button or not unit or not UnitExists(unit) then
		return
	end

	local healthMax = UnitHealthMax(unit)
	local healthCurrent = UnitHealth(unit)
	local healthPercent = 1
	if healthMax and healthMax > 0 then
		healthPercent = healthCurrent / healthMax
	end

	local specialState, specialDispel = GetUnitSpecialState(unit)
	local r, g, b = GetHealthColor(healthPercent)
	local debuffColor = GetBestDebuffColor(unit)
	if debuffColor and not specialState then
		r, g, b = debuffColor.r, debuffColor.g, debuffColor.b
	elseif not specialState and UnderhealDB.raidFrame.showBuffColors then
		local raidIndex = UnitInRaid(unit)
		local missingBuffConfig = self:GetBestMissingBuffConfig(unit, raidIndex)
		if missingBuffConfig then
			r, g, b = self:GetBuffButtonColor(missingBuffConfig, unit, raidIndex)
		end
	end
	if specialState == "RIP" then
		r, g, b = 0.24, 0.24, 0.24
	elseif specialState == "FEIGN" then
		r, g, b = 0.55, 0.42, 0.18
	elseif specialState == "MINDCONTROLLED" then
		r, g, b = 0.72, 0.05, 0.78
	end

	button.health:SetWidth(math.max(1, TANK_BUTTON_WIDTH * (specialState == "RIP" and 1 or healthPercent)))
	button.health:SetColorTexture(r, g, b, 0.95)
	button.health:SetAlpha(1)
	button.UnderhealSyncedHealth = healthCurrent or 0
	button.UnderhealSyncedHealthMax = math.max(1, healthMax or 1)
	button.bg:SetColorTexture(0.02, 0.08, 0.03, 0.88)
	button.flashHealth = healthPercent < 0.1 and not specialState
	button.flashElapsed = button.flashHealth and (button.flashElapsed or 0) or 0
	if button.flashHealth then
		self.hasActiveHealthFlash = true
	end
	button.name:SetText(UnitName(unit) or "Tank")
	button.healthText:SetText((healthCurrent or 0) .. "/" .. (healthMax or 0))
	button.debuff:SetText(UnitDebuff(unit, 1) and "!" or "")
	if button.renewText then
		if UnitHasNamedAura(unit, "Renew") then
			button.renewText:Show()
		else
			button.renewText:Hide()
		end
	end
	self:UpdateClassText(button, unit)
	self:UpdateSpecialStatus(button, specialState, specialDispel)

	self:UpdateIncomingHealFrame(button, unit)
	if not InCombatLockdown() then
		self:SetClickCastAttributes(button, unit)
	end
end

function Underheal:UpdateTankUnit(unit)
	if not self.tankWatch or not self.tankWatch.buttons then
		return false
	end

	for _, button in ipairs(self.tankWatch.buttons) do
		local buttonUnit = button:GetAttribute("unit")
		if button:IsShown() and buttonUnit and (buttonUnit == unit or (UnitIsUnit and UnitIsUnit(buttonUnit, unit))) then
			self:UpdateTankButtonVisual(button, buttonUnit)
			return true
		end
	end

	return false
end

function Underheal:UpdateTankPolymorphAlert()
	local alertTank
	if self.tankWatch and self.tankWatch.buttons then
		for _, button in ipairs(self.tankWatch.buttons) do
			local unit = button:GetAttribute("unit")
			local mindControlled = unit and GetMindControlInfo(unit)
			if button:IsShown() and unit and UnitHasPolymorph(unit) and not mindControlled then
				alertTank = unit
				break
			end
		end
	end

	self.tankPolymorphAlert = alertTank
	self:UpdateLowHealthAlert()
end

function Underheal:PositionTankWatchFrame()
	local frame = self:GetTankWatchFrame()
	if frame.UnderhealMoving then
		return
	end
	local scale = GetTankScale()
	UnderhealDB.tanks.scale = scale
	frame:SetScale(scale)
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", UnderhealDB.tanks.x / scale, UnderhealDB.tanks.y / scale)
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
		if frame.resizeGrip then
			frame.resizeGrip:Show()
		end
		if frame.SetBackdropBorderColor then
			frame:SetBackdropBorderColor(0.95, 0.85, 0.25, 1)
		end
	else
		if frame.dragLabel then
			frame.dragLabel:Hide()
		end
		if frame.resizeGrip then
			frame.resizeGrip:Hide()
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
		self.tankPolymorphAlert = nil
		self:UpdateLowHealthAlert()
		return
	end

	local tanks = {}
	for _, unit in ipairs(GetRaidUnits()) do
		local raidIndex = UnitInRaid(unit)
		if self:IsTankUnit(unit, raidIndex) then
			tanks[#tanks + 1] = unit
		end
	end

	if #tanks == 0 then
		frame:Hide()
		self.tankPolymorphAlert = nil
		self:UpdateLowHealthAlert()
		self:UpdateClickBuffToggleButton()
		return
	end

	frame:SetHeight(36 + (#tanks * 28))
	frame:SetWidth(TANK_BUTTON_WIDTH + 16)
	self:PositionTankWatchFrame()
	self:UpdateTankDragState()
	frame:Show()
	self:UpdateClickBuffToggleButton()

	for index, unit in ipairs(tanks) do
		local button = self:GetTankButton(index)
		self:EnsureThreatWidgets(button)
		button:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -28 - ((index - 1) * 28))
		button:SetAttribute("unit", unit)
		self:UpdateTankButtonVisual(button, unit)
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
		if frame.buttons[index].UnderhealStatusText then
			frame.buttons[index].UnderhealStatusText:Hide()
		end
		if frame.buttons[index].UnderhealSubStatusText then
			frame.buttons[index].UnderhealSubStatusText:Hide()
		end
		if frame.buttons[index].renewText then
			frame.buttons[index].renewText:Hide()
		end
		frame.buttons[index]:SetAttribute("unit", nil)
		frame.buttons[index]:Hide()
	end
	self:UpdateTankPolymorphAlert()
end

function Underheal:GetTargetOfTargetFrame()
	if self.targetOfTargetWatch then
		return self.targetOfTargetWatch
	end

	local frame = CreateFrame("Frame", "UnderhealTargetOfTargetWatchFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
	frame:SetSize(TANK_BUTTON_WIDTH + 16, 64)
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
	title:SetText("Target of Target")
	frame.title = title

	local dragLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	dragLabel:SetPoint("TOPRIGHT", -8, -7)
	dragLabel:SetText("drag")
	dragLabel:SetTextColor(0.45, 1.0, 1.0)
	dragLabel:Hide()
	frame.dragLabel = dragLabel

	local resizeGrip = CreateFrame("Button", nil, frame)
	resizeGrip:SetSize(16, 16)
	resizeGrip:SetPoint("BOTTOMRIGHT", -3, 3)
	resizeGrip:EnableMouse(true)
	resizeGrip.bg = resizeGrip:CreateTexture(nil, "OVERLAY")
	resizeGrip.bg:SetAllPoints()
	resizeGrip.bg:SetColorTexture(0.95, 0.85, 0.25, 0.75)
	resizeGrip.text = resizeGrip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	resizeGrip.text:SetPoint("CENTER", 0, 0)
	resizeGrip.text:SetText("+")
	resizeGrip:SetScript("OnMouseDown", function(self, buttonName)
		if buttonName ~= "LeftButton" or not UnderhealDB.raidFrame.unlocked or InCombatLockdown() then
			return
		end

		local uiScale = UIParent:GetEffectiveScale() or 1
		local cursorX, cursorY = GetCursorPosition()
		self.resizing = true
		self.startX = cursorX / uiScale
		self.startY = cursorY / uiScale
		self.startScale = GetTargetOfTargetScale()
		if frame:GetLeft() and frame:GetTop() then
			UnderhealDB.targetOfTarget.x = frame:GetLeft() * self.startScale
			UnderhealDB.targetOfTarget.y = frame:GetTop() * self.startScale
		end
	end)
	resizeGrip:SetScript("OnMouseUp", function(self)
		self.resizing = nil
		UnderhealDB.targetOfTarget.scale = GetTargetOfTargetScale()
		Underheal:PositionTargetOfTargetFrame()
	end)
	resizeGrip:SetScript("OnUpdate", function(self)
		if not self.resizing then
			return
		end

		local uiScale = UIParent:GetEffectiveScale() or 1
		local cursorX, cursorY = GetCursorPosition()
		cursorX = cursorX / uiScale
		cursorY = cursorY / uiScale
		local delta = ((cursorX - self.startX) - (cursorY - self.startY)) / 240
		local scale = self.startScale + delta
		if scale < 0.75 then
			scale = 0.75
		elseif scale > 2.0 then
			scale = 2.0
		end

		UnderhealDB.targetOfTarget.scale = scale
		Underheal:PositionTargetOfTargetFrame()
	end)
	resizeGrip:Hide()
	frame.resizeGrip = resizeGrip

	frame:SetScript("OnDragStart", function(self)
		if UnderhealDB.raidFrame.unlocked and not InCombatLockdown() then
			self.UnderhealMoving = true
			self:StartMoving()
		end
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		self.UnderhealMoving = nil
		if self:GetLeft() and self:GetTop() then
			local scale = GetTargetOfTargetScale()
			UnderhealDB.targetOfTarget.x = self:GetLeft() * scale
			UnderhealDB.targetOfTarget.y = self:GetTop() * scale
			UnderhealDB.targetOfTarget.hasPosition = true
		end
		Underheal:PositionTargetOfTargetFrame()
	end)

	frame:Hide()
	self.targetOfTargetWatch = frame
	return frame
end

function Underheal:GetTargetOfTargetButton()
	local frame = self:GetTargetOfTargetFrame()
	if frame.button then
		return frame.button
	end

	local button = CreateFrame("Button", nil, frame, "SecureUnitButtonTemplate")
	button:SetSize(TANK_BUTTON_WIDTH, 24)
	button:RegisterForClicks("AnyUp")
	button:SetAttribute("unit", "targettarget")
	button:SetAttribute("type1", "target")
	button:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -28)

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

	local renewText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	renewText:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -5, 1)
	renewText:SetTextColor(0.45, 1, 0.45, 1)
	renewText:SetShadowColor(0, 0, 0, 1)
	renewText:SetShadowOffset(1, -1)
	renewText:SetText("Renew")
	renewText:Hide()
	button.renewText = renewText

	self:EnsureThreatWidgets(button)
	self:EnsureStatusText(button)
	self:EnsureClassText(button)

	frame.button = button
	return button
end

function Underheal:PositionTargetOfTargetFrame()
	local frame = self:GetTargetOfTargetFrame()
	if frame.UnderhealMoving then
		return
	end
	local scale = GetTargetOfTargetScale()
	UnderhealDB.targetOfTarget.scale = scale
	frame:SetScale(scale)
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", UnderhealDB.targetOfTarget.x / scale, UnderhealDB.targetOfTarget.y / scale)
end

function Underheal:UpdateTargetOfTargetDragState()
	local frame = self.targetOfTargetWatch
	if not frame then
		return
	end

	if UnderhealDB.raidFrame.unlocked then
		if frame.dragLabel then
			frame.dragLabel:Show()
		end
		if frame.resizeGrip then
			frame.resizeGrip:Show()
		end
		if frame.SetBackdropBorderColor then
			frame:SetBackdropBorderColor(0.95, 0.85, 0.25, 1)
		end
	else
		if frame.dragLabel then
			frame.dragLabel:Hide()
		end
		if frame.resizeGrip then
			frame.resizeGrip:Hide()
		end
		if frame.SetBackdropBorderColor then
			frame:SetBackdropBorderColor(0.35, 0.65, 0.75, 0.9)
		end
	end
end

function Underheal:ClearTargetOfTargetButton()
	local frame = self.targetOfTargetWatch
	local button = frame and frame.button
	if not button then
		return
	end

	button.flashHealth = false
	button.health:SetAlpha(1)
	button.health:SetWidth(1)
	button.bg:SetColorTexture(0.02, 0.08, 0.03, 0.88)
	button.name:SetText("No target")
	button.healthText:SetText("")
	button.debuff:SetText("")
	if button.renewText then
		button.renewText:Hide()
	end
	self:UpdateSpecialStatus(button, nil, nil)
	if button.UnderhealIncomingBar then
		button.UnderhealIncomingBar:Hide()
	end
	if button.UnderhealIncomingText then
		button.UnderhealIncomingText:Hide()
	end
	if button.UnderhealThreatBar then
		button.UnderhealThreatBar:Hide()
	end
	if button.UnderhealThreatBorder and not button.UnderhealThreatFlashUntil then
		button.UnderhealThreatBorder:Hide()
	end
	if button.UnderhealThreatTankIcon then
		button.UnderhealThreatTankIcon:Hide()
	end
	if not InCombatLockdown() then
		self:HideBuffButtonsOnFrame(button)
	end
end

function Underheal:UpdateTargetOfTargetWatch()
	if InCombatLockdown() and not self.targetOfTargetWatch then
		self.pendingTargetOfTargetUpdate = true
		return
	end

	local frame = self:GetTargetOfTargetFrame()
	local button = self:GetTargetOfTargetButton()
	self:PositionTargetOfTargetFrame()
	self:UpdateTargetOfTargetDragState()

	if not UnderhealDB.raidFrame.showTargetOfTarget then
		if not InCombatLockdown() then
			frame:Hide()
		end
		return
	end

	if not UnitExists("targettarget") or not UnitCanAssist("player", "targettarget") then
		self:ClearTargetOfTargetButton()
		if not frame:IsShown() and not InCombatLockdown() then
			frame:Show()
		end
		return
	end

	frame:SetHeight(64)
	frame:SetWidth(TANK_BUTTON_WIDTH + 16)
	if not InCombatLockdown() then
		button:SetAttribute("unit", "targettarget")
	end
	button:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -28)
	self:UpdateTankButtonVisual(button, "targettarget")
	if not InCombatLockdown() then
		self:ApplyBuffButtonsToFrame(button)
	end
	if not frame:IsShown() then
		if InCombatLockdown() then
			return
		end
		frame:Show()
	end
	if not button:IsShown() and not InCombatLockdown() then
		button:Show()
	end
end

function Underheal:PollTargetOfTarget(elapsed)
	self.targetOfTargetPollElapsed = (self.targetOfTargetPollElapsed or 0) + elapsed
	if self.targetOfTargetPollElapsed < 0.1 then
		return
	end
	self.targetOfTargetPollElapsed = 0

	if self.disabledForNonHealer or not UnderhealDB.raidFrame or not UnderhealDB.raidFrame.showTargetOfTarget then
		return
	end

	local guid = UnitGUID("targettarget")
	local health = UnitHealth("targettarget") or 0
	local healthMax = UnitHealthMax("targettarget") or 0
	if guid ~= self.lastTargetOfTargetGUID or health ~= self.lastTargetOfTargetHealth or healthMax ~= self.lastTargetOfTargetHealthMax then
		self.lastTargetOfTargetGUID = guid
		self.lastTargetOfTargetHealth = health
		self.lastTargetOfTargetHealthMax = healthMax
		self:UpdateTargetOfTargetWatch()
	end
end

function Underheal:PollBuffWarnings(elapsed)
	self.buffWarningPollElapsed = (self.buffWarningPollElapsed or 0) + elapsed
	if self.buffWarningPollElapsed < 1.0 then
		return
	end
	self.buffWarningPollElapsed = 0

	if self.disabledForNonHealer or not UnderhealDB.raidFrame or not UnderhealDB.raidFrame.showBuffColors then
		return
	end

	self:QueueRefresh(true, not InCombatLockdown(), false, false, false, false)
end

function Underheal:PollHealthBars(elapsed)
	self.healthBarPollElapsed = (self.healthBarPollElapsed or 0) + elapsed
	if self.healthBarPollElapsed < 0.2 then
		return
	end
	self.healthBarPollElapsed = 0

	if self.disabledForNonHealer then
		return
	end

	local frames = self.raidMemberFrameCache
	if not frames or self.raidMemberFrameCacheDirty then
		frames = self:GetRaidMemberFrames()
	end
	for _, info in ipairs(frames or {}) do
		local frame = info.frame
		local unit = frame and (frame.unit or frame.displayedUnit or (frame.GetAttribute and frame:GetAttribute("unit"))) or info.unit
		unit = unit or info.unit
		if frame and frame:IsShown() and unit and UnitExists(unit) then
			local health = UnitHealth(unit) or 0
			local healthMax = math.max(1, UnitHealthMax(unit) or 1)
			if frame.UnderhealSyncedHealth ~= health or frame.UnderhealSyncedHealthMax ~= healthMax then
				self:SkinRaidMemberFrame(frame, true)
			end
		end
	end

	if self.selfWatch and self.selfWatch:IsShown() then
		local health = UnitHealth("player") or 0
		local healthMax = math.max(1, UnitHealthMax("player") or 1)
		if self.selfWatch.UnderhealSyncedHealth ~= health or self.selfWatch.UnderhealSyncedHealthMax ~= healthMax then
			self:UpdateSelfWatch()
		end
	end

	if self.tankWatch and self.tankWatch.buttons then
		for _, button in ipairs(self.tankWatch.buttons) do
			local unit = button:GetAttribute("unit")
			if button:IsShown() and unit and UnitExists(unit) then
				local health = UnitHealth(unit) or 0
				local healthMax = math.max(1, UnitHealthMax(unit) or 1)
				if button.UnderhealSyncedHealth ~= health or button.UnderhealSyncedHealthMax ~= healthMax then
					button.UnderhealSyncedHealth = health
					button.UnderhealSyncedHealthMax = healthMax
					self:UpdateTankButtonVisual(button, unit)
				end
			end
		end
	end

	if self.petWatch and self.petWatch.buttons then
		for _, button in ipairs(self.petWatch.buttons) do
			local unit = button:GetAttribute("unit")
			if button:IsShown() and unit and UnitExists(unit) then
				local health = UnitHealth(unit) or 0
				local healthMax = math.max(1, UnitHealthMax(unit) or 1)
				if button.UnderhealSyncedHealth ~= health or button.UnderhealSyncedHealthMax ~= healthMax then
					self:QueueRefresh(false, false, false, false, false, true)
					break
				end
			end
		end
	end
end

function Underheal:PollThreatIndicators(elapsed)
	self.threatPollElapsed = (self.threatPollElapsed or 0) + elapsed
	if self.threatPollElapsed < 0.35 then
		return
	end
	self.threatPollElapsed = 0

	if self.disabledForNonHealer or not UnderhealDB.raidFrame or not UnderhealDB.raidFrame.showThreat then
		return
	end

	if GetThreatTargetUnit() then
		self:QueueRefresh(false, false, true, false, false, false)
	elseif self.threatTargetGUID then
		self:ClearThreatIndicators()
		self.threatTargetGUID = nil
	end
end

function Underheal:HookBlizzardRaidLayout()
	if self.raidLayoutHooked then
		return
	end

	if _G.CompactRaidFrameContainer_LayoutFrames then
		hooksecurefunc("CompactRaidFrameContainer_LayoutFrames", function()
			Underheal.raidMemberFrameCacheDirty = true
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
			self.UnderhealMoving = true
			self:StartMoving()
		end
	end)
	button:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		self.UnderhealMoving = nil
		if self:GetLeft() and self:GetTop() then
			UnderhealDB.clickBuffButton.x = self:GetLeft()
			UnderhealDB.clickBuffButton.y = self:GetTop()
			UnderhealDB.clickBuffButton.hasPosition = true
		end
	end)
	button:SetScript("OnClick", function()
		UnderhealDB.raidFrame.showBuffColors = not UnderhealDB.raidFrame.showBuffColors
		Underheal:UpdateClickBuffToggleButton()
		Underheal:SkinRaidFrames()
		Underheal:UpdateTankWatch()
		Underheal:UpdateTargetOfTargetWatch()
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
	if button.UnderhealMoving then
		return
	end
	button:SetScale(1)
	button:ClearAllPoints()

	if not ((IsInGroup and IsInGroup()) or (IsInRaid and IsInRaid())) then
		button:Hide()
		return
	end

	button:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", UnderhealDB.clickBuffButton.x, UnderhealDB.clickBuffButton.y)

	button:SetText((UnderhealDB.raidFrame.showBuffColors and "Disable" or "Enable") .. " Buffs")
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
	self.pendingTargetOfTargetUpdate = nil

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
	if self.selfWatch then
		self.selfWatch:Hide()
	end
	if self.petWatch then
		self.petWatch:Hide()
	end
	if self.tankWatch then
		self.tankWatch:Hide()
	end
	if self.targetOfTargetWatch then
		self:ClearTargetOfTargetButton()
		self.targetOfTargetWatch:Hide()
	end

	self:HideUnderhealRaidOverlays()

	if not self.nonHealerMessageShown then
		Print("Disabled on this character because this class is not a healer.")
		self.nonHealerMessageShown = true
	end
end

function Underheal:RefreshPullAnnounceState()
	if IsInRaid and IsInRaid() then
		self.raidCombatWasClear = IsRaidCombatClear()
	else
		self.raidCombatWasClear = nil
	end
end

function Underheal:GetGroupChatChannel()
	if IsInRaid and IsInRaid() then
		return "RAID"
	elseif IsInGroup and IsInGroup() then
		return "PARTY"
	end

	return nil
end

function Underheal:CheckKnockedAnnouncement()
	local channel = self:GetGroupChatChannel()
	if not channel or not C_LossOfControl or not C_LossOfControl.GetActiveLossOfControlDataCount or not C_LossOfControl.GetActiveLossOfControlData then
		return
	end

	local now = GetTime and GetTime() or 0
	for index = 1, C_LossOfControl.GetActiveLossOfControlDataCount() do
		local data = C_LossOfControl.GetActiveLossOfControlData(index)
		if data and KNOCKED_LOSS_OF_CONTROL_TYPES[data.locType] then
			local expirationTime = data.expirationTime or 0
			local remaining = expirationTime > now and (expirationTime - now) or (data.duration or 0)
			local seconds = math.max(1, math.ceil(remaining))
			local key = tostring(data.spellID or data.spellId or data.displayText or data.locType) .. ":" .. tostring(math.floor((expirationTime or 0) * 10))
			if key ~= self.activeKnockedAnnouncementKey then
				self.activeKnockedAnnouncementKey = key
				SendChatMessage("Knocked for " .. seconds .. " seconds", channel)
			end
			return
		end
	end

	self.activeKnockedAnnouncementKey = nil
end

function Underheal:AnnouncePull(unit)
	if not unit or not UnitExists(unit) then
		return
	end
	if not (IsInRaid and IsInRaid()) then
		self.raidCombatWasClear = nil
		return
	end
	if not UnitLooksLikePuller(unit) then
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
	if not (IsInRaid and IsInRaid()) then
		self.raidCombatWasClear = nil
		return
	end
	if not IsRaidUnit(unit) then
		return
	end

	if not self.raidCombatWasClear then
		if IsRaidCombatClear() then
			self.raidCombatWasClear = true
		end
		return
	end

	if not UnitLooksLikePuller(unit) then
		return
	end

	self:AnnouncePull(unit)
end

function Underheal:PollPullAnnounce(elapsed)
	self.pullPollElapsed = (self.pullPollElapsed or 0) + elapsed
	if self.pullPollElapsed < 0.5 then
		return
	end
	self.pullPollElapsed = 0

	if self.disabledForNonHealer or not (IsInRaid and IsInRaid()) then
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
		if UnitLooksLikePuller(unit) then
			self:AnnouncePull(unit)
			return
		end
	end
end

function Underheal:GetLowHealthAlertFrame()
	if self.lowHealthAlert then
		return self.lowHealthAlert
	end

	local frame = CreateFrame("Frame", "UnderhealLowHealthAlertFrame", UIParent)
	frame:SetAllPoints(UIParent)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")
	frame:SetFrameLevel(1000)
	frame:EnableMouse(false)

	local overlay = frame:CreateTexture(nil, "BACKGROUND")
	overlay:SetAllPoints()
	overlay:SetColorTexture(1, 0, 0, 0.22)
	frame.overlay = overlay

	local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
	text:SetPoint("CENTER", frame, "CENTER", 0, 0)
	text:SetText("LOW HEALTH LOW HEALTH")
	text:SetTextColor(1, 0.05, 0.05, 1)
	text:SetShadowColor(0, 0, 0, 1)
	text:SetShadowOffset(3, -3)
	frame.text = text

	frame:Hide()
	self.lowHealthAlert = frame
	return frame
end

function Underheal:UpdateLowHealthAlert()
	local healthMax = UnitHealthMax("player") or 0
	local health = UnitHealth("player") or 0
	local tankPolymorphed = self.tankPolymorphAlert ~= nil
	local shouldShow = tankPolymorphed or (healthMax > 0 and (health / healthMax) < 0.3 and not (UnitIsDeadOrGhost and UnitIsDeadOrGhost("player")))
	local frame = self:GetLowHealthAlertFrame()

	if shouldShow then
		frame.text:SetText(tankPolymorphed and "DISPEL TANK DISPEL TANK" or "LOW HEALTH LOW HEALTH")
		frame:Show()
		self.hasActiveLowHealthAlert = true
	else
		frame:Hide()
		self.hasActiveLowHealthAlert = false
	end
end

function Underheal:QueueRefresh(skin, buffs, threat, incoming, tanks, pets)
	self.queuedSkinRefresh = self.queuedSkinRefresh or skin
	self.queuedBuffRefresh = self.queuedBuffRefresh or buffs
	self.queuedThreatRefresh = self.queuedThreatRefresh or threat
	self.queuedIncomingRefresh = self.queuedIncomingRefresh or incoming
	self.queuedTankRefresh = self.queuedTankRefresh or tanks
	self.queuedPetRefresh = self.queuedPetRefresh or pets
end

function Underheal:ProcessQueuedRefreshes(elapsed)
	self.refreshElapsed = (self.refreshElapsed or 0) + elapsed
	if self.refreshElapsed < 0.2 then
		return
	end
	self.refreshElapsed = 0

	if self.disabledForNonHealer then
		return
	end

	if self.queuedTankRefresh then
		self.queuedTankRefresh = nil
		self:UpdateTankWatch()
	end

	if self.queuedPetRefresh then
		self.queuedPetRefresh = nil
		self:UpdatePetWatch()
	end

	if self.pendingSelfUpdate then
		self.pendingSelfUpdate = nil
		self:UpdateSelfWatch()
	end

	if self.queuedSkinRefresh then
		self.queuedSkinRefresh = nil
		self:SkinRaidFrames()
	end

	if self.queuedBuffRefresh then
		self.queuedBuffRefresh = nil
		self:ApplyBuffButtons()
	end

	if self.queuedThreatRefresh then
		self.queuedThreatRefresh = nil
		self:UpdateThreatIndicators()
	end

	if self.queuedIncomingRefresh then
		self.queuedIncomingRefresh = nil
		self:RefreshIncomingHeals()
	end
end

function Underheal:AnimateHealthFlash(frame, elapsed)
	if not frame or not frame.UnderhealFlashHealth then
		return false
	end

	local bar = frame.healthBar or frame.healthbar or frame.HealthBar
	if not bar then
		return false
	end

	frame.UnderhealFlashElapsed = (frame.UnderhealFlashElapsed or 0) + elapsed
	local alpha = 0.35 + (math.abs(math.sin(frame.UnderhealFlashElapsed * 8)) * 0.65)
	if bar.SetAlpha then
		bar:SetAlpha(alpha)
	end
	if frame.UnderhealSkinBackground then
		frame.UnderhealSkinBackground:SetColorTexture(0.25 * alpha, 0.0, 0.0, 0.88)
	end

	return true
end

function Underheal:AnimateTankHealthFlash(button, elapsed)
	if not button or not button.flashHealth then
		return false
	end

	button.flashElapsed = (button.flashElapsed or 0) + elapsed
	local alpha = 0.35 + (math.abs(math.sin(button.flashElapsed * 8)) * 0.65)
	button.health:SetAlpha(alpha)
	button.bg:SetColorTexture(0.25 * alpha, 0.0, 0.0, 0.88)
	return true
end

function Underheal:AnimateThreatFlash(frame)
	if not frame or not frame.UnderhealThreatFlashUntil or not frame.UnderhealThreatBorder then
		return false
	end

	local remaining = frame.UnderhealThreatFlashUntil - GetTime()
	if remaining <= 0 then
		frame.UnderhealThreatFlashUntil = nil
		if frame.UnderhealThreatTopRank then
			frame.UnderhealThreatBorder:SetBackdropBorderColor(1, 0, 0, 0.95)
			frame.UnderhealThreatBorder:Show()
		else
			frame.UnderhealThreatBorder:Hide()
		end
		return false
	end

	local alpha = 0.25 + (math.abs(math.sin(GetTime() * 12)) * 0.75)
	frame.UnderhealThreatBorder:SetBackdropBorderColor(1, 0, 0, alpha)
	frame.UnderhealThreatBorder:Show()
	return true
end

function Underheal:AnimatePowerInfusionPulse(frame)
	if not frame then
		return false
	end

	local active = false
	local alpha = 0.45 + (math.abs(math.sin((GetTime and GetTime() or 0) * 7)) * 0.55)

	if frame.UnderhealPIButton and frame.UnderhealPIButton:IsShown() and frame.UnderhealPIButton.UnderhealPIPulse then
		frame.UnderhealPIButton.bg:SetColorTexture(1.0, 0.82, 0.05, alpha)
		active = true
	end

	if frame.UnderhealPIBorder and frame.UnderhealPIBorder:IsShown() and frame.UnderhealPIBorder.SetBackdropBorderColor and frame.UnderhealPIPulse then
		frame.UnderhealPIBorder:SetBackdropBorderColor(1, 0.82, 0.05, alpha)
		active = true
	end

	return active
end

function Underheal:AnimateCastFail(frame)
	if not frame or not frame.UnderhealCastFailUntil then
		return false
	end

	local now = GetTime and GetTime() or 0
	if frame.UnderhealCastFailUntil <= now then
		frame.UnderhealCastFailUntil = nil
		if frame.UnderhealCastFailText then
			frame.UnderhealCastFailText:Hide()
		end
		if frame.UnderhealCastFailBorder then
			frame.UnderhealCastFailBorder:Hide()
		end
		return false
	end

	local alpha = 0.35 + (math.abs(math.sin(now * 14)) * 0.65)
	if frame.UnderhealCastFailText then
		frame.UnderhealCastFailText:SetAlpha(alpha)
		frame.UnderhealCastFailText:Show()
	end
	if frame.UnderhealCastFailBorder and frame.UnderhealCastFailBorder.SetBackdropBorderColor then
		frame.UnderhealCastFailBorder:SetBackdropBorderColor(1, 0, 0, alpha)
		frame.UnderhealCastFailBorder:Show()
	end
	return true
end

function Underheal:AnimateLowHealthAlert()
	if not self.lowHealthAlert or not self.lowHealthAlert:IsShown() then
		return false
	end

	local now = GetTime and GetTime() or 0
	local alpha = 0.12 + (math.abs(math.sin(now * 7)) * 0.28)
	if self.lowHealthAlert.overlay then
		self.lowHealthAlert.overlay:SetAlpha(alpha)
	end
	if self.lowHealthAlert.text then
		self.lowHealthAlert.text:SetAlpha(0.55 + (math.abs(math.sin(now * 8)) * 0.45))
	end
	return true
end

function Underheal:ProcessAnimations(elapsed)
	if not self.hasActiveHealthFlash and not self.hasActiveThreatFlash and not self.hasActivePIPulse and not self.hasActiveCastFail and not self.hasActiveLowHealthAlert then
		return
	end

	self.animationElapsed = (self.animationElapsed or 0) + elapsed
	if self.animationElapsed < 0.05 then
		return
	end
	local tickElapsed = self.animationElapsed
	self.animationElapsed = 0

	local hasHealthFlash = false
	local hasThreatFlash = false
	local hasPIPulse = false
	local hasCastFail = false
	local hasLowHealthAlert = self:AnimateLowHealthAlert()
	local needsFrameAnimations = self.hasActiveHealthFlash or self.hasActiveThreatFlash or self.hasActivePIPulse or self.hasActiveCastFail
	if needsFrameAnimations and self.selfWatch and self.selfWatch:IsShown() then
		hasHealthFlash = self:AnimateHealthFlash(self.selfWatch, tickElapsed) or hasHealthFlash
		hasThreatFlash = self:AnimateThreatFlash(self.selfWatch) or hasThreatFlash
		hasPIPulse = self:AnimatePowerInfusionPulse(self.selfWatch) or hasPIPulse
		hasCastFail = self:AnimateCastFail(self.selfWatch) or hasCastFail
	end
	if needsFrameAnimations then
		local frames = self:GetRaidMemberFrames()
		for _, info in ipairs(frames) do
			hasHealthFlash = self:AnimateHealthFlash(info.frame, tickElapsed) or hasHealthFlash
			hasThreatFlash = self:AnimateThreatFlash(info.frame) or hasThreatFlash
			hasPIPulse = self:AnimatePowerInfusionPulse(info.frame) or hasPIPulse
			hasCastFail = self:AnimateCastFail(info.frame) or hasCastFail
		end

		if self.tankWatch and self.tankWatch.buttons then
			for _, button in ipairs(self.tankWatch.buttons) do
				hasHealthFlash = self:AnimateTankHealthFlash(button, tickElapsed) or hasHealthFlash
				hasThreatFlash = self:AnimateThreatFlash(button) or hasThreatFlash
				hasCastFail = self:AnimateCastFail(button) or hasCastFail
			end
		end
		if self.targetOfTargetWatch and self.targetOfTargetWatch.button and self.targetOfTargetWatch:IsShown() then
			local button = self.targetOfTargetWatch.button
			hasHealthFlash = self:AnimateTankHealthFlash(button, tickElapsed) or hasHealthFlash
			hasThreatFlash = self:AnimateThreatFlash(button) or hasThreatFlash
			hasCastFail = self:AnimateCastFail(button) or hasCastFail
		end
	end

	self.hasActiveHealthFlash = hasHealthFlash
	self.hasActiveThreatFlash = hasThreatFlash
	self.hasActivePIPulse = hasPIPulse
	self.hasActiveCastFail = hasCastFail
	self.hasActiveLowHealthAlert = hasLowHealthAlert
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

	local targetName = self.pendingHealTargetName
	local targetUnit = FindGroupUnitByName(targetName)
	local now = GetTime and GetTime() or 0
	if not targetUnit and self.pendingCastTargetGUID and self.pendingCastTargetTime and (now - self.pendingCastTargetTime) <= 0.25 then
		return
	end
	if not targetUnit and UnitExists("mouseover") and UnitCanAssist("player", "mouseover") then
		targetUnit = "mouseover"
	end
	if not targetUnit and UnitExists("target") and UnitCanAssist("player", "target") then
		targetUnit = "target"
	end
	self:CaptureCastTarget(targetUnit, targetName)
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
	self:PositionTargetOfTargetFrame()
	self:UpdateSelfWatch()
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
	self:UpdateTargetOfTargetWatch()
	self:UpdateSelfWatch()
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

function Underheal:LoadRecommendedPreset(classFile)
	if InCombatLockdown() then
		Print("Cannot load a healer preset while in combat.")
		return
	end

	local preset = recommendedPresets[classFile]
	if not preset then
		return
	end

	UnderhealDB.buffButtons = CopyTable(defaults.buffButtons)
	for index, config in ipairs(preset.buffButtons or {}) do
		UnderhealDB.buffButtons[index] = CopyTable(config)
	end
	UnderhealDB.clickCasts = CopyTable(defaults.clickCasts)
	for key, config in pairs(preset.clickCasts or {}) do
		UnderhealDB.clickCasts[key] = CopyTable(config)
	end
	UnderhealDB.powerInfusion = CopyTable(preset.powerInfusion or defaults.powerInfusion)
	for key, value in pairs(preset.raidFrame or {}) do
		UnderhealDB.raidFrame[key] = value
	end

	self:SkinRaidFrames()
	self:ApplyBuffButtons()
	self:UpdateTankWatch()
	self:UpdateTargetOfTargetWatch()
	self:RefreshPowerInfusionVisuals()
	self:RefreshOptions()
	Print("Loaded recommended " .. string.lower(classFile) .. " settings.")
end

function Underheal:ImportLegacyProfile()
	if InCombatLockdown() then
		Print("Cannot import the legacy profile while in combat.")
		return
	end
	if not UnderhealLegacyDB or not next(UnderhealLegacyDB) then
		Print("No legacy account-wide profile was found.")
		return
	end

	UnderhealCharacterDB = CopyTable(UnderhealLegacyDB)
	UnderhealDB = UnderhealCharacterDB
	EnsureDefaults()
	if UnderhealDB.selfWatch.hasPosition then
		UnderhealDB.selfWatch.setupConfirmed = true
	end
	self:ApplyGroupProfile()
	self:ApplyRaidFrameScale()
	self:ApplyRaidFramePosition()
	self:ApplyGroupGap()
	self:ApplyGroupMarkers()
	self:SkinRaidFrames()
	self:ApplyBuffButtons()
	self:UpdateClickBuffToggleButton()
	self:UpdateTankWatch()
	self:UpdateTargetOfTargetWatch()
	self:UpdatePetWatch()
	self:RefreshPowerInfusionVisuals()
	self:RefreshOptions()
	Print("Imported the legacy account-wide settings for this character.")
end

function Underheal:RefreshOptions()
	if not self.optionsFrame then
		return
	end

	EnsureDefaults()

	self.optionsFrame.unlockCheck:SetChecked(UnderhealDB.raidFrame.unlocked)
	self.optionsFrame.groupCheck:SetChecked(UnderhealDB.raidFrame.grouped)
	self.optionsFrame.tankCheck:SetChecked(UnderhealDB.raidFrame.showTanks)
	self.optionsFrame.targetOfTargetCheck:SetChecked(UnderhealDB.raidFrame.showTargetOfTarget)
	self.optionsFrame.petCheck:SetChecked(UnderhealDB.raidFrame.showPets)
	self.optionsFrame.buffCheck:SetChecked(UnderhealDB.raidFrame.showBuffButtons)
	self.optionsFrame.clickBuffCheck:SetChecked(UnderhealDB.raidFrame.clickToBuff)
	self.optionsFrame.magicDebuffCheck:SetChecked(UnderhealDB.raidFrame.showMagicDebuffs)
	self.optionsFrame.diseaseDebuffCheck:SetChecked(UnderhealDB.raidFrame.showDiseaseDebuffs)
	self.optionsFrame.poisonDebuffCheck:SetChecked(UnderhealDB.raidFrame.showPoisonDebuffs)
	self.optionsFrame.curseDebuffCheck:SetChecked(UnderhealDB.raidFrame.showCurseDebuffs)
	self.optionsFrame.scaleSlider:SetValue(UnderhealDB.raidFrame.scale or 1)
	self.optionsFrame.scaleValue:SetText(math.floor(((UnderhealDB.raidFrame.scale or 1) * 100) + 0.5) .. "%")
	local specialPower = GetSpecialPowerConfig()
	if self.optionsFrame.specialPowerCheck then
		self.optionsFrame.specialPowerCheck:SetChecked(specialPower.enabled)
		self.optionsFrame.specialSpellBox:SetText(specialPower.spell or "")
		self.optionsFrame.specialLabelBox:SetText(specialPower.label or "")
		self.optionsFrame.specialClassBox:SetText(specialPower.targetClass or "")
		self.optionsFrame.specialPlayerBox:SetText(specialPower.chosenPlayer or "")
	end

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
	frame.expiryWarningBox:SetText(tostring(config.warnBeforeExpirySeconds or 0))

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

	frame.expiryWarningBox = AddEditBox("Warn before expiry", -414, function(config, text)
		config.warnBeforeExpirySeconds = math.max(0, tonumber(text) or 0)
	end)
	local expiryWarningSuffix = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	expiryWarningSuffix:SetPoint("LEFT", frame.expiryWarningBox, "RIGHT", 6, 0)
	expiryWarningSuffix:SetText("seconds")

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
	frame.superResponsiveCheck:SetChecked(UnderhealDB.raidFrame.superResponsiveMode)
end

function Underheal:CreateClickCastOptionsFrame()
	if self.clickCastOptionsFrame then
		return self.clickCastOptionsFrame
	end

	local frame = CreateFrame("Frame", "UnderhealClickCastOptionsFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
	frame:SetSize(560, 304)
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

	local superResponsiveCheck = CreateFrame("CheckButton", nil, frame, "InterfaceOptionsCheckButtonTemplate")
	superResponsiveCheck:SetPoint("BOTTOMLEFT", 20, 48)
	superResponsiveCheck:SetScript("OnClick", function(self)
		UnderhealDB.raidFrame.superResponsiveMode = not not self:GetChecked()
	end)
	frame.superResponsiveCheck = superResponsiveCheck

	local superResponsiveLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	superResponsiveLabel:SetPoint("LEFT", superResponsiveCheck, "RIGHT", 2, 1)
	superResponsiveLabel:SetText("Super responsive mode")

	local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	hint:SetPoint("BOTTOMLEFT", 24, 24)
	hint:SetWidth(500)
	hint:SetJustifyH("LEFT")
	hint:SetText("Super responsive mode cancels your current heal when you click a different player. Trinkets try slots 13 and 14 before the spell.")

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
	frame:SetSize(440, 760)
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

	local targetOfTargetCheck = CreateFrame("CheckButton", nil, frame, "InterfaceOptionsCheckButtonTemplate")
	targetOfTargetCheck:SetPoint("TOPLEFT", 178, -166)
	targetOfTargetCheck:SetScript("OnClick", function(self)
		UnderhealDB.raidFrame.showTargetOfTarget = not not self:GetChecked()
		Underheal:UpdateTargetOfTargetWatch()
		Underheal:RefreshOptions()
	end)
	frame.targetOfTargetCheck = targetOfTargetCheck

	local targetOfTargetLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	targetOfTargetLabel:SetPoint("LEFT", targetOfTargetCheck, "RIGHT", 2, 1)
	targetOfTargetLabel:SetText("Show ToT")

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

	local specialPowerCheck = CreateFrame("CheckButton", nil, frame, "InterfaceOptionsCheckButtonTemplate")
	specialPowerCheck:SetPoint("TOPLEFT", 18, -296)
	specialPowerCheck:SetScript("OnClick", function(self)
		GetSpecialPowerConfig().enabled = not not self:GetChecked()
		Underheal:SkinRaidFrames()
		Underheal:ApplyBuffButtons()
		Underheal:RefreshPowerInfusionVisuals()
	end)
	frame.specialPowerCheck = specialPowerCheck

	local specialPowerLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	specialPowerLabel:SetPoint("LEFT", specialPowerCheck, "RIGHT", 2, 1)
	specialPowerLabel:SetText("Enable special power")

	local function AddSpecialEditBox(name, y, key)
		local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		label:SetPoint("TOPLEFT", 22, y)
		label:SetText(name)
		local box = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
		box:SetSize(250, 22)
		box:SetPoint("TOPLEFT", 148, y + 4)
		box:SetAutoFocus(false)
		box:SetScript("OnEnterPressed", function(self)
			self:ClearFocus()
		end)
		box:SetScript("OnEditFocusLost", function(self)
			GetSpecialPowerConfig()[key] = self:GetText() or ""
			Underheal:SkinRaidFrames()
			Underheal:ApplyBuffButtons()
			Underheal:RefreshPowerInfusionVisuals()
		end)
		return box
	end

	frame.specialSpellBox = AddSpecialEditBox("Special spell", -334, "spell")
	frame.specialLabelBox = AddSpecialEditBox("Button text", -366, "label")
	frame.specialClassBox = AddSpecialEditBox("Target class", -398, "targetClass")
	frame.specialPlayerBox = AddSpecialEditBox("Chosen player", -430, "chosenPlayer")

	local debuffLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	debuffLabel:SetPoint("TOPLEFT", 22, -470)
	debuffLabel:SetText("Debuff colors")

	local function AddDebuffCheck(name, key, x, y)
		local check = CreateFrame("CheckButton", nil, frame, "InterfaceOptionsCheckButtonTemplate")
		check:SetPoint("TOPLEFT", x, y)
		check:SetScript("OnClick", function(self)
			UnderhealDB.raidFrame[key] = not not self:GetChecked()
			Underheal:SkinRaidFrames()
			Underheal:RefreshOptions()
		end)
		local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		label:SetPoint("LEFT", check, "RIGHT", 0, 1)
		label:SetText(name)
		return check
	end

	frame.magicDebuffCheck = AddDebuffCheck("Magic", "showMagicDebuffs", 18, -490)
	frame.diseaseDebuffCheck = AddDebuffCheck("Disease", "showDiseaseDebuffs", 118, -490)
	frame.poisonDebuffCheck = AddDebuffCheck("Poison", "showPoisonDebuffs", 18, -520)
	frame.curseDebuffCheck = AddDebuffCheck("Curse", "showCurseDebuffs", 118, -520)

	local scaleLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	scaleLabel:SetPoint("TOPLEFT", 22, -558)
	scaleLabel:SetText("Raid frame scale")

	local scaleValue = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	scaleValue:SetPoint("TOPRIGHT", -34, -560)
	scaleValue:SetText("100%")
	frame.scaleValue = scaleValue

	local scaleSlider = CreateFrame("Slider", "UnderhealRaidScaleSlider", frame, "OptionsSliderTemplate")
	scaleSlider:SetPoint("TOPLEFT", 38, -584)
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
	buffOptions:SetPoint("TOPLEFT", 48, -624)
	buffOptions:SetText("Configure Buffs")
	buffOptions:SetScript("OnClick", function()
		Underheal:ToggleBuffOptions()
	end)

	local clickOptions = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	clickOptions:SetSize(120, 24)
	clickOptions:SetPoint("TOPLEFT", 178, -624)
	clickOptions:SetText("Configure Clicks")
	clickOptions:SetScript("OnClick", function()
		Underheal:ToggleClickCastOptions()
	end)

	local presetLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	presetLabel:SetPoint("TOPLEFT", 22, -666)
	presetLabel:SetText("Recommended healer settings")

	local function AddPresetButton(label, classFile, x)
		local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
		button:SetSize(126, 22)
		button:SetPoint("TOPLEFT", x, -682)
		button:SetText(label)
		button:SetScript("OnClick", function()
			Underheal:LoadRecommendedPreset(classFile)
		end)
		return button
	end

	AddPresetButton("Priest", "PRIEST", 18)
	AddPresetButton("Paladin", "PALADIN", 156)
	AddPresetButton("Druid", "DRUID", 294)

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

	UnderhealDB.raidFrame.unlocked = unlocked

	local mover = GetMover()
	if unlocked and frame then
		Underheal:PlaceMover()
		mover:Show()
	else
		mover:Hide()
	end

	Underheal:ApplyRaidFramePosition()
	Underheal:UpdateTankWatch()
	Underheal:UpdateTankDragState()
	Underheal:UpdateTargetOfTargetWatch()
	Underheal:UpdateTargetOfTargetDragState()
	Underheal:UpdateSelfWatch()
	Underheal:UpdateSelfWatchDragState()
	Underheal:UpdateClickBuffToggleDragState()
	Underheal:RefreshOptions()

	if not quiet then
		if unlocked then
			Print("Mover shown. Drag the Underheal bar, self bar, Tanks panel, ToT panel, or click-to-buff button, then type /underheal lock.")
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
	Print("/underheal importlegacy - copy the old account-wide profile to this character")
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
			local unit = info.unit or info.frame.unit or info.frame.displayedUnit or (info.frame.GetAttribute and info.frame:GetAttribute("unit")) or "?"
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
	elseif command == "tot" or command == "targettarget" then
		UnderhealDB.raidFrame.showTargetOfTarget = not UnderhealDB.raidFrame.showTargetOfTarget
		Underheal:UpdateTargetOfTargetWatch()
		Underheal:RefreshOptions()
		Print("Target-of-target watch " .. (UnderhealDB.raidFrame.showTargetOfTarget and "enabled." or "disabled."))
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
	elseif command == "importlegacy" then
		Underheal:ImportLegacyProfile()
	elseif command == "reset" or command == "restore" then
		Underheal:RestoreBlizzardPosition()
	elseif command == "help" then
		PrintHelp()
	else
		Underheal:ToggleOptions()
	end
end

Underheal:RegisterEvent("PLAYER_LOGIN")
Underheal:RegisterEvent("PLAYER_ENTERING_WORLD")
Underheal:RegisterEvent("PLAYER_REGEN_ENABLED")
Underheal:RegisterEvent("ADDON_LOADED")
Underheal:RegisterEvent("GROUP_ROSTER_UPDATE")
Underheal:RegisterEvent("UNIT_HEALTH")
Underheal:RegisterEvent("UNIT_MAXHEALTH")
pcall(Underheal.RegisterEvent, Underheal, "UNIT_POWER_UPDATE")
pcall(Underheal.RegisterEvent, Underheal, "UNIT_MANA")
Underheal:RegisterEvent("UNIT_AURA")
Underheal:RegisterEvent("UNIT_PET")
Underheal:RegisterEvent("SPELL_UPDATE_COOLDOWN")
Underheal:RegisterEvent("SPELLS_CHANGED")
pcall(Underheal.RegisterEvent, Underheal, "BAG_UPDATE_DELAYED")
Underheal:RegisterEvent("PLAYER_REGEN_DISABLED")
Underheal:RegisterEvent("PLAYER_TARGET_CHANGED")
Underheal:RegisterEvent("UNIT_TARGET")
Underheal:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
Underheal:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
Underheal:RegisterEvent("UNIT_FLAGS")
Underheal:RegisterEvent("CHAT_MSG_ADDON")
Underheal:RegisterEvent("UI_ERROR_MESSAGE")
pcall(Underheal.RegisterEvent, Underheal, "LOSS_OF_CONTROL_ADDED")
pcall(Underheal.RegisterEvent, Underheal, "LOSS_OF_CONTROL_UPDATE")
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
	self:PollTargetOfTarget(elapsed)
	self:PollBuffWarnings(elapsed)
	self:PollHealthBars(elapsed)
	self:PollThreatIndicators(elapsed)
	self:ProcessQueuedRefreshes(elapsed)
	self:ProcessAnimations(elapsed)
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
		self:UpdateSelfWatch()
		self:UpdateTankWatch()
		self:UpdateTargetOfTargetWatch()
		self:UpdatePetWatch()
		self:RefreshPullAnnounceState()
		Print("Loaded. Type /underheal to open options.")
	elseif event == "PLAYER_ENTERING_WORLD" then
		EnsureDefaults()
		if not IsHealerCharacter() then
			self:DisableForNonHealer()
			return
		end

		self.disabledForNonHealer = false
		self:UpdateSelfWatch()
		self:UpdateTargetOfTargetWatch()
		self:RefreshPowerInfusionVisuals()
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
		if self.pendingTargetOfTargetUpdate then
			self.pendingTargetOfTargetUpdate = nil
		end
		self:UpdateTankWatch()
		self:UpdateTargetOfTargetWatch()
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
		self:UpdateTargetOfTargetWatch()
		self:UpdatePetWatch()
		self:RefreshPullAnnounceState()
	elseif event == "GROUP_ROSTER_UPDATE" then
		if self.disabledForNonHealer then
			return
		end

		EnsureDefaults()
		self.raidMemberFrameCacheDirty = true
		self:ApplyGroupProfile()
		self:ApplyRaidFrameScale()
		self:ApplyGroupGap()
		self:ApplyGroupMarkers()
		self:SkinRaidFrames()
		self:ApplyBuffButtons()
		self:UpdateClickBuffToggleButton()
		self:UpdateTankWatch()
		self:UpdateTargetOfTargetWatch()
		self:UpdatePetWatch()
		self:RefreshPullAnnounceState()
	elseif event == "PLAYER_ROLES_ASSIGNED" then
		if self.disabledForNonHealer then
			return
		end

		self:QueueRefresh(false, true, false, false, true, false)
	elseif event == "SPELL_UPDATE_COOLDOWN" then
		if self.disabledForNonHealer then
			return
		end

		self:RefreshPowerInfusionVisuals()
		self:QueueRefresh(true, true, false, false, false, false)
	elseif event == "SPELLS_CHANGED" then
		if self.disabledForNonHealer then
			return
		end

		ClearTable(KNOWN_SPELL_CACHE)
		self:RefreshPowerInfusionVisuals()
		self:QueueRefresh(true, true, false, false, true, false)
	elseif event == "BAG_UPDATE_DELAYED" then
		if self.disabledForNonHealer then
			return
		end

		self:QueueRefresh(false, true, false, false, false, false)
	elseif event == "UNIT_PET" then
		if self.disabledForNonHealer then
			return
		end

		self:QueueRefresh(false, false, false, false, false, true)
	elseif event == "PLAYER_TARGET_CHANGED" or event == "UNIT_TARGET" or event == "UNIT_THREAT_LIST_UPDATE" or event == "UNIT_THREAT_SITUATION_UPDATE" then
		if self.disabledForNonHealer then
			return
		end

		if event == "PLAYER_TARGET_CHANGED" or addonName == "target" or addonName == "targettarget" then
			self:UpdateTargetOfTargetWatch()
		end
		self:QueueRefresh(false, false, true, false, false, false)
	elseif event == "UNIT_FLAGS" then
		if self.disabledForNonHealer then
			return
		end

		self:CheckPullAnnounce(addonName)
		self:UpdateRaidUnitVisual(addonName, true)
		self:UpdateTankUnit(addonName)
		if addonName == "targettarget" then
			self:UpdateTargetOfTargetWatch()
		end
	elseif event == "UNIT_HEAL_PREDICTION" then
		if self.disabledForNonHealer then
			return
		end

		self:QueueRefresh(false, false, false, true, false, false)
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
			self:QueueRefresh(false, false, false, true, false, false)
		end
	elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_SUCCEEDED" then
		if self.disabledForNonHealer then
			return
		end

		if addonName == "player" then
			self:SendHealStop()
			self:RefreshPowerInfusionVisuals()
		end
	elseif event == "CHAT_MSG_ADDON" then
		if self.disabledForNonHealer then
			return
		end

		self:HandleAddonMessage(addonName, arg2, arg3, arg4)
	elseif event == "UI_ERROR_MESSAGE" then
		if self.disabledForNonHealer then
			return
		end

		self:HandleUIErrorMessage(arg2 or addonName)
	elseif event == "LOSS_OF_CONTROL_ADDED" or event == "LOSS_OF_CONTROL_UPDATE" then
		if self.disabledForNonHealer then
			return
		end

		self:CheckKnockedAnnouncement()
	elseif event == "PLAYER_REGEN_DISABLED" then
		if self.disabledForNonHealer then
			return
		end

		self:QueueRefresh(true, true, false, false, false, false)
	elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or event == "UNIT_POWER_UPDATE" or event == "UNIT_MANA" or event == "UNIT_AURA" then
		if self.disabledForNonHealer then
			return
		end

		local unit = addonName
		if (event == "UNIT_POWER_UPDATE" or event == "UNIT_MANA") and unit == "player" then
			self:UpdateSelfWatch()
			return
		end
		if event == "UNIT_AURA" and unit then
			self:UpdateTankPolymorphAlert()
		end
		if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
			self:UpdateLowHealthAlert()
		end
		if unit and string.find(unit, "pet") then
			self:QueueRefresh(false, false, false, true, false, true)
		end
		if unit and (unit == "player" or string.match(unit, "^raid%d+$") or string.match(unit, "^party%d+$")) then
			self:UpdateTankUnit(unit)
			if event == "UNIT_AURA" then
				self:UpdateRaidUnitVisual(unit, true)
				self:QueueRefresh(false, true, false, false, false, false)
			else
				self:UpdateRaidUnitVisual(unit, false)
				self:QueueRefresh(false, false, false, true, false, false)
			end
		end
		if unit == "targettarget" then
			self:UpdateTargetOfTargetWatch()
		end
	end
end)
