﻿-- Safe's Unit Library
-- Written By Paul Snart
-- Copyright 2012
--
--
-- To access this from within your Add-on.
--
-- In your RiftAddon.toc
-- ---------------------
-- Embed: SafesUnitLib
-- Dependency: SafesUnitLib, {"required", "before"}
--
-- In your Add-on's initialization
-- -------------------------------
-- local LibSUnit = Inspect.Addon.Detail("SafesUnitLib").data

SafesUnitLib_Settings = {}

local AddonIni, LibSUnit = ...

-- Timer Locals
local _inspect = Inspect.Unit.Detail
local _timeReal = Inspect.Time.Real
local _lastTick = _timeReal()

-- Used for purging Idle units (Segments in seconds)
-- Constant
local _tSegThrottle = 15
local _idleSeg = 3
local _deadSeg = 12
-- Variable
local _lastSeg = math.floor(_lastTick / _tSegThrottle)

-- Raid, Group and Player registers.
local _SpecList = {
	 [0] = "player",
	 [1] = "group01",
	 [2] = "group02",
	 [3] = "group03",
	 [4] = "group04",
	 [5] = "group05",
	 [6] = "group06",
	 [7] = "group07",
	 [8] = "group08",
	 [9] = "group09",
	[10] = "group10",
	[11] = "group11",
	[12] = "group12",
	[13] = "group13",
	[14] = "group14",
	[15] = "group15",
	[16] = "group16",
	[17] = "group17",
	[18] = "group18",
	[19] = "group19",
	[20] = "group20",
}

LibSUnit.Raid = {
	Lookup = {},
	UID = {},
	Queue = {},
	Move = {},
	Pets = {},
	Members = 0,
	Groups = {
		[1] = 0,
		[2] = 0,
		[3] = 0,
		[4] = 0,
	},
	Grouped = false,
	Combat = false,
	CombatTotal = 0,
	Wiped = false,
	DeadTotal = 0,
	Offline = 0,
}

local _AvailFullTable = {function() end, AddonIni.id, "Unit Availability Full Handler"}

LibSUnit.Cache = {
	Avail = {},
	Partial = {},
	Idle = {},
}

LibSUnit.Lookup = {
	UID = {},
	UTID = {},
	Name = {},
}

LibSUnit.Total = {
	UID = 0,
	UTID = 0,
	Name = 0,
	Avail = 0,
	Partial = 0,
	Idle = 0,
	Players = 0,
	NPC = 0,
}

LibSUnit._internal = {
	Avail = {},
	Combat = {},
	Unit = {},
	Segment = {},
	Context = UI.CreateContext(AddonIni.id),
	Settings = {
		Debug = false,
		Tracker = {
			Show = false,
			x = false,
			y = false,
		},
	},
	Event = {
		Unit = {
			New = {
				Full = Utility.Event.Create(AddonIni.id, "Unit.New.Full"),
				Partial = Utility.Event.Create(AddonIni.id, "Unit.New.Partial"),
				Idle = Utility.Event.Create(AddonIni.id, "Unit.New.Idle"),
			},
			Full = Utility.Event.Create(AddonIni.id, "Unit.Full"),
			Partial = Utility.Event.Create(AddonIni.id, "Unit.Partial"),
			Idle = Utility.Event.Create(AddonIni.id, "Unit.Idle"),
			Removed = Utility.Event.Create(AddonIni.id, "Unit.Removed"),
			Detail = {
				Percent = Utility.Event.Create(AddonIni.id, "Unit.Detail.Percent"),
				PercentFlat = Utility.Event.Create(AddonIni.id, "Unit.Detail.PercentFlat"),
				Health = Utility.Event.Create(AddonIni.id, "Unit.Detail.Health"),
				HealthMax = Utility.Event.Create(AddonIni.id, "Unit.Detail.HealthMax"),
				Mark = Utility.Event.Create(AddonIni.id, "Unit.Mark"),
				Relation = Utility.Event.Create(AddonIni.id, "Unit.Detail.Relation"),
				Role = Utility.Event.Create(AddonIni.id, "Unit.Detail.Role"),
				Name = Utility.Event.Create(AddonIni.id, "Unit.Detail.Name"),
				Power = Utility.Event.Create(AddonIni.id, "Unit.Detail.Power"),
				PowerMode = Utility.Event.Create(AddonIni.id, "Unit.Detail.PowerMode"),
				Calling = Utility.Event.Create(AddonIni.id, "Unit.Detail.Calling"),
				Combat = Utility.Event.Create(AddonIni.id, "Unit.Detail.Combat"),
				Offline = Utility.Event.Create(AddonIni.id, "Unit.Detail.Offline"),
				Planar = Utility.Event.Create(AddonIni.id, "Unit.Detail.Planar"),
				PlanarMax = Utility.Event.Create(AddonIni.id, "Unit.Detail.PlanarMax"),
				Ready = Utility.Event.Create(AddonIni.id, "Unit.Detail.Ready"),
				Vitality = Utility.Event.Create(AddonIni.id, "Unit.Detail.Vitality"),
			},
			Target = Utility.Event.Create(AddonIni.id, "Unit.Target"),
			TargetCount = Utility.Event.Create(AddonIni.id, "Unit.TargetCount"),
		},
		Combat = {
			Death = Utility.Event.Create(AddonIni.id, "Combat.Death"),
			Damage = Utility.Event.Create(AddonIni.id, "Combat.Damage"),
			Heal = Utility.Event.Create(AddonIni.id, "Combat.Heal"),
		},
		Raid = {
			Join = Utility.Event.Create(AddonIni.id, "Raid.Join"),
			Leave = Utility.Event.Create(AddonIni.id, "Raid.Leave"),
			Member = {
				Join = Utility.Event.Create(AddonIni.id, "Raid.Member.Join"),
				Leave = Utility.Event.Create(AddonIni.id, "Raid.Member.Leave"),
				Move = Utility.Event.Create(AddonIni.id, "Raid.Member.Move"),
			},
			Pet = {
				Join = Utility.Event.Create(AddonIni.id, "Raid.Pet.Join"),
				Leave = Utility.Event.Create(AddonIni.id, "Raid.Pet.Leave"),
			},
			Combat = {
				Enter = Utility.Event.Create(AddonIni.id, "Raid.Combat.Enter"),
				Leave = Utility.Event.Create(AddonIni.id, "Raid.Combat.Leave"),
			},
			Wipe = Utility.Event.Create(AddonIni.id, "Raid.Wipe"),
			Res = Utility.Event.Create(AddonIni.id, "Raid Ressurect"),
		},
		System = {
			Start = Utility.Event.Create(AddonIni.id, "System.Start"),
		},
	},
}
_lsu = LibSUnit._internal

-- Settings
function _lsu.Load(AddonId)
	if AddonId == AddonIni.id then
		if next(SafesUnitLib_Settings) then
			_lsu.Settings = SafesUnitLib_Settings
		else
			SafesUnitLib_Settings = _lsu.Settings
		end
		_lsu.Debug:Init()
		if _lsu.Settings.Debug then
			_lsu.Debug.GUI.Header:SetVisible(true)
		end
	end
end

function _lsu.Save(AddonId)
	if AddonId == AddonIni.id then
		SafesUnitLib_Settings = _lsu.Settings
	end
end

-- Unit Management Event Handlers and Functions
function _lsu.Unit:DamageIn(UnitObj, info)
	if UnitObj.Loaded then
		if UnitObj.CurrentKey == "Idle" then
			if info.damage > 0 then
				UnitObj.Health = UnitObj.Health - info.damage
				self:CalcPerc(UnitObj)
			end
			self:UpdateSegment(UnitObj, _idleSeg + _lastSeg)
		end
	end
end

function _lsu.Unit:DamageOut(UnitObj)
	if UnitObj.Loaded then
		if UnitObj.CurrentKey == "Idle" then
			self:UpdateSegment(UnitObj, _idleSeg + _lastSeg)
		end
	end
end

function _lsu.Unit:HealIn(UnitObj, info)
	if UnitObj.Loaded then
		if UnitObj.CurrentKey == "Idle" then
			if info.heal > 0 then
				UnitObj.Health = UnitObj.Health + info.heal
				self:CalcPerc(UnitObj)
			end
			self:UpdateSegment(UnitObj, _idleSeg + _lastSeg)
		end
	end
end

function _lsu.Unit:HealOut(UnitObj)
	if UnitObj.Loaded then
		if UnitObj.CurrentKey == "Idle" then
			self:UpdateSegment(UnitObj, _idleSeg + _lastSeg)
		end
	end
end

function _lsu.Unit:UpdateTarget(UnitObj, newTar)
	if newTar == nil then
		newTar = Inspect.Unit.Lookup(UnitObj.UnitID..".target")
	end
	if newTar ~= UnitObj.Target then
		if UnitObj.Target then
			local targetObj = LibSUnit.Lookup.UID[UnitObj.Target]
			if targetObj then
				targetObj.TargetCount = targetObj.TargetCount - 1
				targetObj.TargetList[UnitObj.UnitID] = nil
				_lsu.Event.Unit.TargetCount(targetObj)
			end
		end
		UnitObj.Target = newTar
		if newTar then
			local targetObj = LibSUnit.Lookup.UID[newTar]
			if targetObj then
				targetObj.TargetCount = targetObj.TargetCount + 1
				targetObj.TargetList[UnitObj.UnitID] = UnitObj
				_lsu.Event.Unit.TargetCount(targetObj)
			end
		end
		-- Target Change Event
		_lsu.Event.Unit.Target(UnitObj)
	end
end

function _lsu.Unit:CalcPerc(UnitObj)
	-- Calculate Percentages
	UnitObj.PercentRaw = UnitObj.Health/UnitObj.HealthMax
	if UnitObj.PercentRaw > 1 then
		UnitObj.PercentRaw = 1
	end
	UnitObj.Percent = tonumber(string.format("%0.2f", UnitObj.PercentRaw * 100))
	UnitObj.PercentFlat = math.ceil(UnitObj.Percent)
	
	if UnitObj.PercentLast ~= UnitObj.Percent then
		-- Fire Percent (2 decimal place) change.
		_lsu.Event.Unit.Detail.Percent(UnitObj)
		-- Store change.
		UnitObj.PercentLast = UnitObj.Percent
		
		if UnitObj.PercentFlat ~= UnitObj.PercentLast then
			-- Fire a Percent Flat change Event.
			_lsu.Event.Unit.Detail.PercentFlat(UnitObj)
			-- Store change.
			UnitObj.PercentFlatLast = UnitObj.PercentFlat
		end
	end
end

function _lsu.Unit:UpdateSegment(UnitObj, New, uDetails)
	-- Adjust Idle segment placement
	if UnitObj.IdleSegment then
		_lsu.Segment[UnitObj.IdleSegment][UnitObj.Details.id] = nil
	end
	if New then
		if _lsu.Segment[New] then
			_lsu.Segment[New][UnitObj.Details.id] = UnitObj
		else
			_lsu.Segment[New] = {[UnitObj.Details.id] = UnitObj}
		end
		UnitObj.IdleSegment = New
		if uDetails then
			self.Details(UnitObj, uDetails)
		end
	else
		UnitObj.IdleSegment = false	
	end
end

function _lsu:Create(UID, uDetails, Type)
	-- Creates a new Unit Object ready for tracking.
	if not uDetails then
		return
	end
	
	local _type = LibSUnit.Cache[Type]
	local _total = LibSUnit.Total
	local _UID = LibSUnit.Lookup.UID
	local _name = LibSUnit.Lookup.Name
	local _calc = self.Unit.CalcPerc
	
	_UID[UID] = {
		Details = uDetails,
		Loaded = false,
		IdleSegment = false,
		CurrentTable = _type,
		CurrentKey = Type,
		Mark = uDetails.mark,
		Relation = uDetails.relation,
		HealthMax = uDetails.healthMax or 1,
		Health = uDetails.health or 0,
		Role = uDetails.role,
		Calling = uDetails.calling,
		Offline = uDetails.offline,
		Combat = uDetails.combat,
		Ready = uDetails.ready,
		Planar = uDetails.planar,
		PlanarMax = uDetails.planarMax,
		Vitality = uDetails.vitality,
		Target = nil,
		UnitID = UID,
		OwnerID = uDetails.ownerID,
		Dead = false,
		Name = uDetails.name,
		TargetCount = 0,
		TargetList = {},
		Position = {
			x = uDetails.coordX or 0,
			y = uDetails.coordY or 0,
			z = uDetails.coordZ or 0,
		},
	}
	
	local UnitObj = _UID[UID]
	if uDetails.mana then
		UnitObj.PowerMode = "mana"
		UnitObj.PowerMax = uDetails.manaMax
	elseif uDetails.power then
		UnitObj.PowerMode = "power"
		UnitObj.PowerMax = 100
	elseif uDetails.energy then
		UnitObj.PowerMode = "energy"
		UnitObj.PowerMax = uDetails.energyMax
	else
		UnitObj.PowerMode = ""
		UnitObj.PowerMax = 1
		UnitObj.Power = 1
	end
	
	UnitObj.Power = uDetails[PowerMode]
	
	_type[UID] = UnitObj
	_total[Type] = _total[Type] + 1
	if uDetails.availability == "full" then
		if UnitObj.Health == 0 then
			UnitObj.Dead = true
		end
		if not UnitObj.Name then
			UnitObj.Name = "<Unknown>"
		end
		if _name[UnitObj.Name] then
			_name[UnitObj.Name][UID] = true
		else
			_name[UnitObj.Name] = {UID = true}
		end
		-- Unit has been fully loaded at some point. Flag this here to ensure safe Detail reading of all fields.
		UnitObj.Loaded = true
		-- Calculate initial percentages, bypassing related events to avoid garbage results.
		UnitObj.PercentRaw = UnitObj.Health/UnitObj.HealthMax
		if UnitObj.PercentRaw > 1 then
			UnitObj.PercentRaw = 1
		end
		UnitObj.Percent = tonumber(string.format("%0.2f", UnitObj.PercentRaw * 100))
		UnitObj.PercentLast = UnitObj.Percent -- Ensure the last recorded percentage is initialized.
		UnitObj.PercentFlat = math.ceil(UnitObj.Percent)
		UnitObj.PercentFlatLast = UnitObj.PercentFlat -- Ensure the last recorded flat percentage is initialized.
		_lsu.Unit:UpdateTarget(UnitObj)
		if Type == "Avail" then
			-- Fire Unit New Full Event
			_lsu.Event.Unit.New.Full(UnitObj)
		else
			-- Fire Unit Idle Full Event
			_lsu.Event.Unit.New.Idle(UnitObj)
		end
	else
		if Type == "Avail" then
			-- Fire Unit New Partial Event
			_lsu.Event.Unit.New.Partial(UnitObj)
		else
			-- Fire Unit Idle Partial Event
			_lsu.Event.Unit.New.Partial(UnitObj)
		end
	end
	if LibSUnit.Raid.Queue[UID] then
		_lsu.Raid.Change(UID, LibSUnit.Raid.Queue[UID])
		LibSUnit.Raid.Queue[UID] = nil
	end
	return UnitObj
end

-- Details Updates
function _lsu.Unit.Name(uList)
	local _lookup = LibSUnit.Lookup.Name
	local _cache = LibSUnit.Lookup.UID
	local nList = {}
	for UID, Name in pairs(uList) do
		if Name then
			local UnitObj = _cache[UID]
			if UnitObj.Name ~= Name then
				if _lookup[UnitObj.Name] then
					_lookup[UnitObj.Name][UID] = nil
					if not next(_lookup[UnitObj.Name]) then
						_lookup[UnitObj.Name] = nil
					end
				end				
			end
			UnitObj.Details.name = Name
			UnitObj.Name = Name
			if _lookup[UnitObj.Name] then
				_lookup[UnitObj.Name][UID] = true
			else
				_lookup[UnitObj.Name] = {UID = true}
			end
			nList[UID] = UnitObj
		end
	end
	_lsu.Event.Unit.Detail.Name(nList)	
end

function _lsu.Unit.Health(uList)
	local _cache = LibSUnit.Lookup.UID
	for UID, Health in pairs(uList) do
		Health = tonumber(Health)
		if not Health then
			--print("Adjusted HP to "..tostring(Health))
			Health = 0
		end
		_cache[UID].Health = Health
		_lsu.Unit:CalcPerc(_cache[UID])
		uList[UID] = _cache[UID]
		if Health == 0 then
			if not UnitObj.Dead then
				_lsu.Raid.ManageDeath(UnitObj, true)
			end
		elseif Health > 0 then
			if UnitObj.Dead then
				_lsu.Raid.ManageDeath(UnitObj, false)
			end
		end
	end
	_lsu.Event.Unit.Detail.Health(uList)	
end

function _lsu.Unit.HealthMax(uList)
	local _cache = LibSUnit.Lookup.UID
	local nList = {}
	for UID, HealthMax in pairs(uList) do
		HealthMax = tonumber(HealthMax)
		if HealthMax then
			if HealthMax ~= _cache[UID].HealthMax then
				_cache[UID].HealthMax = HealthMax
				_lsu.Unit:CalcPerc(_cache[UID])
				nList[UID] = _cache[UID]
			end
		end
	end
	_lsu.Event.Unit.Detail.HealthMax(nList)	
end

function _lsu.Unit.Power(uList, PowerMode)
	local _cache = LibSUnit.Lookup.UID
	local nList = {}
	for UID, Power in pairs(uList) do
		if Power then
			if Power ~= _cache[UID].Power then
				if PowerMode ~= _cache[UID].PowerMode then
					_cache[UID].PowerMode = PowerMode
					_lsu.Event.Unit.Detail.PowerMode(_cache[UID])
				end
				_cache[UID].Details[PowerMode] = Power
				_cache[UID].Power = Power
				nList[UID] = _cache[UID]
			end
		end
	end
	_lsu.Event.Unit.Detail.Power(nList)	
end

function _lsu.Unit.Offline(uList)
	local _cache = LibSUnit.Lookup.UID
	for UID, Offline in pairs(uList) do
		_cache[UID].Offline = Offline
		uList[UID] = _cache[UID]
	end
	_lsu.Event.Unit.Detail.Offline(uList)	
end

function _lsu.Unit.Vitality(uList)
	local _cache = LibSUnit.Lookup.UID
	for UID, Vitality in pairs(uList) do
		_cache[UID].Vitality = Vitality
		uList[UID] = _cache[UID]
	end
	_lsu.Event.Unit.Detail.Vitality(uList)	
end

function _lsu.Unit.Ready(uList)
	local _cache = LibSUnit.Lookup.UID
	for UID, Ready in pairs(uList) do
		_cache[UID].Ready = Ready
		uList[UID] = _cache[UID]
	end
	_lsu.Event.Unit.Detail.Ready(uList)	
end

function _lsu.Unit.Mark(uList)
	local _cache = LibSUnit.Lookup.UID
	for UID, Mark in pairs(uList) do
		_cache[UID].Mark = Mark
		uList[UID] = _cache[UID]
	end
	_lsu.Event.Unit.Detail.Mark(uList)	
end

function _lsu.Unit.Planar(uList)
	local _cache = LibSUnit.Lookup.UID
	for UID, Planar in pairs(uList) do
		_cache[UID].Planar = Planar
		uList[UID] = _cache[UID]
	end
	_lsu.Event.Unit.Detail.Planar(uList)	
end

function _lsu.Unit.PlanarMax(uList)
	local _cache = LibSUnit.Lookup.UID
	for UID, PlanarMax in pairs(uList) do
		_cache[UID].PlanarMax = PlanarMax
		uList[UID] = _cache[UID]		
	end
	_lsu.Event.Unit.Detail.PlanarMax(uList)
end

function _lsu.Unit.Combat(uList, Silent)
	local _cache = LibSUnit.Lookup.UID
	for UID, Combat in pairs(uList) do
		if LibSUnit.Raid.UID[UID] then
			-- Adjust Raid Combat State
			if Combat ~= _cache[UID].Combat then
				if Combat then
					LibSUnit.Raid.CombatTotal = LibSUnit.Raid.CombatTotal + 1
					if not LibSUnit.Raid.Combat then
						LibSUnit.Raid.Combat = true
						--print("Raid Entered Combat")
						_lsu.Event.Raid.Combat.Enter()
					end
					if _lsu.Settings.Debug then
						_lsu.Debug:UpdateCombat()
					end
				else
					LibSUnit.Raid.CombatTotal = LibSUnit.Raid.CombatTotal - 1
					if LibSUnit.Raid.Combat then
						if LibSUnit.Raid.CombatTotal == 0 then
							LibSUnit.Raid.Combat = false
							--print("Raid Left Combat")
							_lsu.Event.Raid.Combat.Leave()
						end
					end
					if _lsu.Settings.Debug then
						_lsu.Debug:UpdateCombat()
					end
				end
			end
		end
		_cache[UID].Combat = Combat
		uList[UID] = _cache[UID]
	end
	if not Silent then
		_lsu.Event.Unit.Detail.Combat(uList)
	end
end

function _lsu.Unit.Details(UnitObj, uDetails)
	if UnitObj.CurrentKey == "Partial" then
		
	else
		if UnitObj.Mark ~= uDetails.mark then
			UnitObj.Mark = uDetails.mark
			_lsu.Event.Unit.Detail.Mark({[UnitObj.UnitID] = UnitObj})
		end
		if uDetails.relation then
			if UnitObj.Relation ~= uDetails.relation then
				UnitObj.Relation = uDetails.relation
				_lsu.Event.Unit.Detail.Relation(UnitObj)
			end
		end
		if uDetails.player then
			if uDetails.role then
				if UnitObj.Role ~= uDetails.role then
					UnitObj.Role = uDetails.role
					_lsu.Event.Unit.Detail.Role(UnitObj)
				end
			end
		end
		if uDetails.calling then
			if UnitObj.Calling ~= uDetails.calling then
				UnitObj.Calling = uDetails.calling
				_lsu.Event.Unit.Detail.Calling(UnitObj)
			end
		end
		if uDetails.healthMax then
			if uDetails.healthMax ~= UnitObj.HealthMax then
				UnitObj.HealthMax = uDetails.healthMax
			end
		end
		UnitObj.Health = uDetails.health or 0
		if uDetails.health ~= UnitObj.Health then
			UnitObj.Health = uDetails.health
		end
		UnitObj.Planar = uDetails.planar
		UnitObj.PlanarMax = uDetails.planarMax
		UnitObj.Ready = uDetails.ready
		UnitObj.Vitality = uDetails.vitality
		if UnitObj.Combat ~= uDetails.combat then
			_lsu.Unit.Combat({[UnitObj.UnitID] = uDetails.combat})
		end
		_lsu.Unit:CalcPerc(UnitObj)
		UnitObj.Details = uDetails
		UnitObj.Loaded = true
		if UnitObj.Health == 0 then
			if not UnitObj.Dead then
				_lsu.Raid.ManageDeath(UnitObj, true)
			end
		elseif UnitObj.Health > 0 then
			if UnitObj.Dead then
				_lsu.Raid.ManageDeath(UnitObj, false)
			end
		end
	end
end

function _lsu:Available(UnitObj, uDetails)
	-- Switches State for Units to Available.
	local UID = UnitObj.UnitID
	local Total = LibSUnit.Total
	
	Total[UnitObj.CurrentKey] = Total[UnitObj.CurrentKey] - 1
	UnitObj.CurrentTable[UID] = nil
	UnitObj.CurrentTable = LibSUnit.Cache.Avail
	UnitObj.CurrentKey = "Avail"
	LibSUnit.Cache.Avail[UID] = UnitObj
	self.Unit:UpdateSegment(UnitObj)
	Total.Avail = Total.Avail + 1
	self.Unit.Details(UnitObj, uDetails)
	
	self.Event.Unit.Full(UnitObj)
end

function _lsu:Partial(UnitObj, uDetails)
	-- Switches State for Units to Partial.
	local UID = UnitObj.Details.id
	local Total = LibSUnit.Total
	
	Total[UnitObj.CurrentKey] = Total[UnitObj.CurrentKey] - 1
	UnitObj.CurrentTable[UID] = nil
	UnitObj.CurrentTable = LibSUnit.Cache.Partial
	UnitObj.CurrentKey = "Partial"
	LibSUnit.Cache.Partial[UID] = UnitObj
	self.Unit:UpdateSegment(UnitObj)
	Total.Partial = Total.Partial + 1
	
	self.Event.Unit.Partial(UnitObj)
end

function _lsu:Idle(UnitObj)
	-- Switches State for Units to Unavailable.
	local UID = UnitObj.Details.id
	local Total = LibSUnit.Total
	
	Total[UnitObj.CurrentKey] = Total[UnitObj.CurrentKey] - 1
	UnitObj.CurrentTable[UID] = nil
	UnitObj.CurrentTable = LibSUnit.Cache.Idle
	UnitObj.CurrentKey = "Idle"
	LibSUnit.Cache.Idle[UID] = UnitObj
	self.Unit:UpdateSegment(UnitObj, _idleSeg + _lastSeg)
	Total.Idle = Total.Idle + 1
	if UnitObj.Mark then
		UnitObj.Mark = false
		_lsu.Event.Unit.Detail.Mark{[UnitObj.UnitID] = UnitObj}
	end
	
	self.Event.Unit.Idle(UnitObj)
end

-- Unit Availability Handlers
function _lsu.Avail.Full(uList)
	-- Main handler for new Units

	-- Optimize
	local _lookup = LibSUnit.Lookup.UID
	local _create = _lsu.Create
	
	-- Manage Units.
	for UID, Spec in pairs(uList) do
		local UnitObj = _lookup[UID]
		if not _lookup[UID] then
			_create(_lsu, UID, _inspect(UID), "Avail")
		else
			_lsu:Available(_lookup[UID], _inspect(UID))
		end
	end
	
	if _lsu.Settings.Debug then
		_lsu.Debug:UpdateAll()
	end
end

function _lsu.Avail.Partial(uList)
	-- Main handler for Partial Units

	-- Optimize
	local _lookup = LibSUnit.Lookup.UID
	local _create = _lsu.Create
	local _part = _lsu.Partial
	
	-- Manage Units.
	for UID, Spec in pairs(uList) do
		if not _lookup[UID] then
			_create(_lsu, UID, _inspect(UID), "Avail")
		else
			_part(_lsu, _lookup[UID], _inspect(UID))
		end
	end
	if _lsu.Settings.Debug then
		_lsu.Debug:UpdateAll()
	end
end

function _lsu.Avail.None(uList)
	-- Move to Idle

	-- Optimize
	local _lookup = LibSUnit.Lookup.UID
	local _create = _lsu.Create
	local _idle = _lsu.Idle
	
	-- Manage Units.
	for UID, Spec in pairs(uList) do
		if not _lookup[UID] then
		else
			_idle(_lsu, _lookup[UID])
		end
	end
	
	if _lsu.Settings.Debug then
		_lsu.Debug:UpdateAll()
	end	
end

function _lsu.Unit.Change(UnitID, Spec)
	local sourceUID = Inspect.Unit.Lookup(Spec)
	if sourceUID then
		local UnitObj = LibSUnit.Lookup.UID[sourceUID]
		if UnitObj then
			_lsu.Unit:UpdateTarget(UnitObj, UnitID)
		end
	end
end

-- Raid Management
_lsu.Raid = {}
function _lsu.Raid.ManageDeath(UnitObj, Dead)
	if UnitObj.Loaded then
		if UnitObj.CurrentKey ~= "Partial" then
			if LibSUnit.Raid.UID[UnitObj.UnitID] then
				if Dead then 
					if not UnitObj.Dead then
						LibSUnit.Raid.DeadTotal = LibSUnit.Raid.DeadTotal + 1
						--print(">>> "..UnitObj.Name.." has died")
						if LibSUnit.Raid.DeadTotal == LibSUnit.Raid.Members then
							if not LibSUnit.Raid.Wiped then
								LibSUnit.Raid.Wiped = true
								_lsu.Event.Raid.Wipe()
							end
						end
						if _lsu.Settings.Debug then
							_lsu.Debug:UpdateDeath()
						end
					end
				else
					if UnitObj.Dead then
						--print("<<< "..UnitObj.Name.." has is now alive")
						LibSUnit.Raid.DeadTotal = LibSUnit.Raid.DeadTotal - 1
						LibSUnit.Raid.Wiped = false
						_lsu.Event.Raid.Res(targetObj, sourceObj)
						if _lsu.Settings.Debug then
							_lsu.Debug:UpdateDeath()
						end
					end
				end
			end
			UnitObj.Dead = Dead	
		end
	end
end

function _lsu.Raid.Check(UnitID, skipSpec)
	local checkUnitID
	for Index, Spec in pairs(_SpecList) do
		if Index > 0 then
			if Spec ~= skipSpec then
				checkUnitID = Inspect.Unit.Lookup(Spec)
				if checkUnitID == UnitID then
					return true
				end
			end
		end
	end
end

function _lsu.Raid.Change(UnitID, Spec)
	local UnitObj
	UnitObj = LibSUnit.Raid.Lookup[Spec].Unit
	if UnitObj then
		if LibSUnit.Raid.Move[UnitObj.UnitID] then
			-- Raid Member Moved Process Move with Event
			local newSpec = LibSUnit.Raid.Move[UnitObj.UnitID]
			LibSUnit.Raid.Lookup[newSpec].Unit = UnitObj
			LibSUnit.Raid.UID[UnitObj.UnitID] = newSpec
			UnitObj.RaidLoc = newSpec
			if not UnitID then
				LibSUnit.Raid.Lookup[Spec].Unit = nil
			end
			_lsu.Event.Raid.Member.Move(UnitObj, Spec, newSpec)
			LibSUnit.Raid.Move[UnitObj.UnitID] = nil
		else
			if not _lsu.Raid.Check(UnitObj.UnitID, Spec) then
				-- Raid Member Leave
				if UnitObj.Combat then
					LibSUnit.Raid.CombatTotal = LibSUnit.Raid.CombatTotal - 1
					if LibSUnit.Raid.CombatTotal == 0 then
						LibSUnit.Raid.Combat = false
						_lsu.Event.Raid.Combat.Leave()
					end
				end
				LibSUnit.Raid.Lookup[Spec].Unit = nil
				LibSUnit.Raid.Members = LibSUnit.Raid.Members - 1
				LibSUnit.Raid.UID[UnitObj.UnitID] = nil
				UnitObj.RaidLoc = nil
				if UnitObj.Dead then
					LibSUnit.Raid.DeadTotal = LibSUnit.Raid.DeadTotal - 1
					--print(UnitObj.Name.." has left the Raid and removed death count")
				end
				_lsu.Event.Raid.Member.Leave(UnitObj, Spec)
				if LibSUnit.Raid.Members == 0 then
					LibSUnit.Grouped = false
					_lsu.Event.Raid.Leave()
				elseif LibSUnit.Raid.Members > 1 then
					if LibSUnit.Raid.Members == LibSUnit.Raid.DeadTotal then
						if not LibSUnit.Raid.Wiped then
							LibSUnit.Raid.Wiped = true
							_lsu.Event.Raid.Wipe()
						end
					else
						LibSUnit.Raid.Wiped = false
					end				
				end
				if _lsu.Settings.Debug then
					_lsu.Debug:UpdateDeath()
					_lsu.Debug:UpdateCombat()
				end			
			else
				-- Unit Still exists, wait for appropriate Join message.
				LibSUnit.Raid.Move[UnitObj.UnitID] = Spec
				if not UnitID then
					LibSUnit.Raid.Lookup[Spec].Unit = nil
				end
			end
		end
	end
	if UnitID then
		-- Raid Member Join
		UnitObj = LibSUnit.Lookup.UID[UnitID]
		if UnitObj then
			if not LibSUnit.Raid.Move[UnitID] then
				if not LibSUnit.Raid.UID[UnitID] then
					LibSUnit.Raid.Members = LibSUnit.Raid.Members + 1
					LibSUnit.Raid.Lookup[Spec].Unit = UnitObj
					LibSUnit.Raid.UID[UnitID] = Spec
					UnitObj.RaidLoc = Spec
					if LibSUnit.Raid.Members == 1 then
						--print("You have joined a Raid or Group")
						LibSUnit.Grouped = true
						_lsu.Event.Raid.Join()
					end
					--print("New Player Joined Raid: "..UnitObj.Name)
					_lsu.Event.Raid.Member.Join(UnitObj, Spec)
					if UnitObj.Combat then
						LibSUnit.Raid.CombatTotal = LibSUnit.Raid.CombatTotal + 1
						if LibSUnit.Raid.CombatTotal == 1 then
							LibSUnit.Raid.Combat = true
							_lsu.Event.Raid.Combat.Enter()
						end
					end
					if UnitObj.Dead then
						LibSUnit.Raid.DeadTotal = LibSUnit.Raid.DeadTotal + 1
						--print(UnitObj.Name.." joined and marked as Dead")
					end
					if LibSUnit.Raid.Members == LibSUnit.Raid.DeadTotal then
						if not LibSUnit.Raid.Wiped then
							LibSUnit.Raid.Wiped = true
							_lsu.Event.Raid.Wipe()
						end
					else
						if LibSUnit.Raid.Wiped then
							LibSUnit.Raid.Wiped = false
						end
					end
					if _lsu.Settings.Debug then
						_lsu.Debug:UpdateDeath()
						_lsu.Debug:UpdateCombat()
					end
				else
					-- Raid Member duplicate, wait for appropriate leave message.
					LibSUnit.Raid.Move[UnitID] = Spec
				end
			else
				-- Raid Member Moved Process Move with Event
				LibSUnit.Raid.Lookup[Spec].Unit = UnitObj
				LibSUnit.Raid.UID[UnitID] = Spec
				UnitObj.RaidLoc = Spec
				_lsu.Event.Raid.Member.Move(UnitObj, LibSUnit.Raid.Move[UnitID], Spec)
				LibSUnit.Raid.Move[UnitID] = nil
			end
		else
			-- Unit Queued for Joining once loaded in to cache.
			LibSUnit.Raid.Queue[UnitID] = Spec
		end
	end
	if _lsu.Settings.Debug then
		_lsu.Debug:UpdateAll()
	end
end

function _lsu.Raid.PetChange(UnitID, Spec)

end

-- Combat Handlers
function _lsu.Combat.stdHandler(UID, segPlus)
	if UID then
		local _cache = LibSUnit.Lookup.UID
		local UnitObj = _cache[UID]
		if UnitObj then
			if UnitObj.CurrentKey == "Idle" then
				_lsu.Unit:UpdateSegment(UnitObj, segPlus + _lastSeg, _inspect(UID))
			end
		else
			UnitObj = _lsu:Create(UID, _inspect(UID), "Idle")		
		end
		return UnitObj
	end
end

function _lsu.Combat.Damage(info)
	local _stdHandler = _lsu.Combat.stdHandler
	local targetObj, sourceObj
	info.damage = info.damage or 0
	targetObj = _stdHandler(info.target, _idleSeg)
	if targetObj then
		_lsu.Unit:DamageIn(targetObj, info)
	end
	sourceObj = _stdHandler(info.caster, _idleSeg)
	if sourceObj then
		_lsu.Unit:DamageOut(sourceObj, info)
	end
	info.targetObj = targetObj
	info.sourceObj = sourceObj
	_lsu.Event.Combat.Damage(info)
end

function _lsu.Combat.Heal(info)
	local _stdHandler = _lsu.Combat.stdHandler
	local targetObj, sourceObj
	info.heal = info.heal or 0
	targetObj = _stdHandler(info.target, _idleSeg)
	if targetObj then
		_lsu.Unit:HealIn(targetObj, info)
		if targetObj.Dead then
			_lsu.Raid.ManageDeath(targetObj, false)
		end
	end
	sourceObj = _stdHandler(info.caster, _idleSeg)
	if sourceObj then
		_lsu.Unit:HealOut(sourceObj, info)
	end
	info.targetObj = targetObj
	info.sourceObj = sourceObj
	_lsu.Event.Combat.Heal(info)
end

function _lsu.Combat.Death(info)
	local _cache = LibSUnit.Lookup.UID
	local targetObj, sourceObj
	sourceObj = _lsu.Combat.stdHandler(info.caster, _idleSeg)
	info.sourceObj = sourceObj
	targetObj = _lsu.Combat.stdHandler(info.target, _deadSeg)
	info.targetObj = targetObj
	if targetObj then
		if not targetObj.Dead then
			_lsu.Raid.ManageDeath(targetObj, true)
		end
		_lsu.Event.Combat.Death(info)
	end
end

-- Base Functions
function _lsu:UpdateSegment(_tSeg)
	local _lookup = LibSUnit.Lookup
	local _cache = LibSUnit.Cache
	local _total = LibSUnit.Total

	if self.Segment[_tSeg] then
		local RemoveList = {}
		for UID, UnitObj in pairs(self.Segment[_tSeg]) do
			RemoveList[UID] = UnitObj
			_lookup.UID[UID] = nil
			if UnitObj.Name then
				if _lookup.Name[UnitObj.Name] then
					_lookup.Name[UnitObj.Name][UID] = nil
					if not next(_lookup.Name[UnitObj.Name]) then
						_lookup.Name[UnitObj.Name] = nil
					end
				end
			end
			_cache.Idle[UID] = nil
			_total.Idle = _total.Idle - 1
		end
		self.Event.Unit.Removed(RemoveList)
	end
	self.Segment[_tSeg] = nil
	if self.Settings.Debug then
		self.Debug:UpdateAll()
	end
end

function _lsu.Tick()
	local _cTime = _timeReal()
	local _tSeg = math.floor(_cTime / _tSegThrottle)
	
	if _tSeg ~= _lastSeg then
		_lsu:UpdateSegment(_tSeg)
		_lastSeg = _tSeg
	end
	_lastTick = _cTime
end

function _lsu.Wait(uList)
	if uList[_lsu.PlayerID] then
		_lsu.Event.System.Start()
		
		-- Check current availability list.
		local uList = Inspect.Unit.List()
		_lsu.Avail.Full(uList)
		
		_AvailFullTable[1] = _lsu.Avail.Full
		
		-- Unit Management Events
		table.insert(Event.Unit.Availability.Partial, {_lsu.Avail.Partial, AddonIni.id, "Unit Availability Partial Handler"})
		table.insert(Event.Unit.Availability.None, {_lsu.Avail.None, AddonIni.id, "Unit Availability None Handler"})

		-- Unit Data Change
		table.insert(Event.Unit.Detail.Health, {_lsu.Unit.Health, AddonIni.id, "Unit HP Change"})
		table.insert(Event.Unit.Detail.Name, {_lsu.Unit.Name, AddonIni.id, "Unit Name Change"})
		table.insert(Event.Unit.Detail.HealthMax, {_lsu.Unit.HealthMax, AddonIni.id, "Unit HP Max Change"})
		table.insert(Event.Unit.Detail.Power, {function (List) _lsu.Unit.Power(List, "power") end, AddonIni.id, "Power Change"})
		table.insert(Event.Unit.Detail.Energy, {function (List) _lsu.Unit.Power(List, "energy") end, AddonIni.id, "Energy Change"})
		table.insert(Event.Unit.Detail.Mana, {function (List) _lsu.Unit.Power(List, "mana") end, AddonIni.id, "Mana Change"})
		table.insert(Event.Unit.Detail.Offline, {_lsu.Unit.Offline, AddonIni.id, "Unit Offline state Change"})
		table.insert(Event.Unit.Detail.Combat, {_lsu.Unit.Combat, AddonIni.id, "Unit Combat state Change"})
		table.insert(Event.Unit.Detail.Planar, {_lsu.Unit.Planar, AddonIni.id, "Unit Planar Chanage"})
		table.insert(Event.Unit.Detail.PlanarMax, {_lsu.Unit.PlanarMax, AddonIni.id, "Unit Planar Max Change"})
		table.insert(Event.Unit.Detail.Ready, {_lsu.Unit.Ready, AddonIni.id, "Unit Ready State Change"})
		table.insert(Event.Unit.Detail.Vitality, {_lsu.Unit.Vitality, AddonIni.id, "Unit Vitality Change"})
		table.insert(Event.Unit.Detail.Mark, {_lsu.Unit.Mark, AddonIni.id, "Unit Mark Change"})
		
		-- Unit Combat Events
		table.insert(Event.Combat.Damage, {_lsu.Combat.Damage, AddonIni.id, "Unit Combat Damage"})
		table.insert(Event.Combat.Heal, {_lsu.Combat.Heal, AddonIni.id, "Unit Combat Heal"})
		table.insert(Event.Combat.Death, {_lsu.Combat.Death, AddonIni.id, "Unit Death"})
	
		-- Register Events with LibUnitChange
		local EventTable
		for Index, Spec in pairs(_SpecList) do
			if Spec ~= "player" then
				EventTable = Library.LibUnitChange.Register(Spec)
				table.insert(EventTable, {function (data) _lsu.Raid.Change(data, Spec) end, AddonIni.id, Spec.." changed"})
				EventTable = Library.LibUnitChange.Register(Spec..".pet")
				table.insert(EventTable, {function (data) _lsu.Raid.PetChange(data, Spec) end, AddonIni.id, Spec.." pet changed"})
				LibSUnit.Raid.Lookup[Spec] = {
					Group = math.ceil(Index / 5),
					Specifier = Spec,
				}
				LibSUnit.Raid.Pets[Spec] = {
					Group = LibSUnit.Raid.Lookup[Spec].Group,
					Specifier = Spec..".pet",
				}
				_lsu.Raid.Change(Inspect.Unit.Lookup(Spec), Spec)
			end
			EventTable = Library.LibUnitChange.Register(Spec..".pet.target")
			table.insert(EventTable, {function (data) _lsu.Unit.Change(data, Spec..".pet") end, AddonIni.id, Spec.." pet target changed"})
			EventTable = Library.LibUnitChange.Register(Spec..".pet.target.target")
			table.insert(EventTable, {function (data) _lsu.Unit.Change(data, Spec..".pet.target") end, AddonIni.id, Spec.." pet targets target changed"})
			EventTable = Library.LibUnitChange.Register(Spec..".target")
			table.insert(EventTable, {function (data) _lsu.Unit.Change(data, Spec) end, AddonIni.id, Spec.." target changed"})
			EventTable = Library.LibUnitChange.Register(Spec..".target.target")
			table.insert(EventTable, {function (data) _lsu.Unit.Change(data, Spec..".target") end, AddonIni.id, Spec.." targets target changed"})
		end
	end
end

function _lsu.Start(AddonId)
	if AddonIni.id == AddonId then
		_lsu.PlayerID = Inspect.Unit.Lookup("player")
		_AvailFullTable[1] = _lsu.Wait
		table.insert(Event.Unit.Availability.Full, _AvailFullTable)
	end
end

function _lsu.SlashHandler(cmd)
	cmd = string.lower(cmd or "")
	if cmd == "debug" then
		if _lsu.Settings.Debug then
			_lsu.Settings.Debug = false
			_lsu.Debug.GUI.Header:SetVisible(false)
		else
			_lsu.Settings.Debug = true
			_lsu.Debug.GUI.Header:SetVisible(true)
		end
	end
end

-- Addon Specific Events
table.insert(Event.Addon.Load.End, {_lsu.Start, AddonIni.id, "Initialize all currently seen Units if any"})
table.insert(Event.Addon.SavedVariables.Load.End, {_lsu.Load, AddonIni.id, "Load Vars"})
table.insert(Event.Addon.SavedVariables.Save.Begin, {_lsu.Save, AddonIni.id, "Save Vars"})

-- System Specific Events
table.insert(Event.System.Update.Begin, {_lsu.Tick, AddonIni.id, "Redraw start"})
table.insert(Command.Slash.Register("libsunit"), {_lsu.SlashHandler, AddonIni.id, "LibSUnit Slash Command"})

-- DEBUG STUFF
_lsu.Debug = {}
function _lsu.AttachDragFrame(parent, hook, name, layer)
	if not name then name = "" end
	if not layer then layer = 0 end
	
	local Drag = {}
	Drag.Frame = UI.CreateFrame("Frame", "Drag Frame", parent)
	Drag.Frame:SetPoint("TOPLEFT", parent, "TOPLEFT")
	Drag.Frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT")
	Drag.Frame.parent = parent
	Drag.Frame.MouseDown = false
	Drag.Frame:SetLayer(layer)
	Drag.hook = hook
	Drag.Layer = parent:GetLayer()
	Drag.Parent = parent
	
	function Drag.Frame.Event:LeftDown()
		self.MouseDown = true
		mouseData = Inspect.Mouse()
		self.MyStartX = self.parent:GetLeft()
		self.MyStartY = self.parent:GetTop()
		self.StartX = mouseData.x - self.MyStartX
		self.StartY = mouseData.y - self.MyStartY
		tempX = self.parent:GetLeft()
		tempY = self.parent:GetTop()
		tempW = self.parent:GetWidth()
		tempH =	self.parent:GetHeight()
		self.parent:ClearAll()
		self.parent:SetPoint("TOPLEFT", UIParent, "TOPLEFT", tempX, tempY)
		self.parent:SetWidth(tempW)
		self.parent:SetHeight(tempH)
		self:SetBackgroundColor(0,0,0,0.5)
		Drag.hook("start")
		Drag.Parent:SetLayer(10)
	end
	
	function Drag.Frame.Event:MouseMove(mouseX, mouseY)
		if self.MouseDown then
			self.parent:SetPoint("TOPLEFT", UIParent, "TOPLEFT", (mouseX - self.StartX), (mouseY - self.StartY))
		end
	end
	
	function Drag.Frame.Event:LeftUp()
		if self.MouseDown then
			self.MouseDown = false
			self:SetBackgroundColor(0,0,0,0)
			Drag.hook("end")
			Drag.Parent:SetLayer(Drag.Layer)
		end
	end
	
	function Drag.Frame:Remove()	
		self.Event.LeftDown = nil
		self.Event.MouseMove = nil
		self.Event.LeftUp = nil
		Drag.hook = nil
		self:sRemove()
		self.Remove = nil		
	end	
	return Drag.Frame
end

function _lsu.Debug:Init()
	self.Constant = {
		Width = 150,
		Height = 20,
		Text = 12,
	}
	self.Callbacks = {}
	function self.Callbacks.Position(Type)
		if Type == "end" then
			_lsu.Settings.Tracker.x = _lsu.Debug.GUI.Header:GetLeft()
			_lsu.Settings.Tracker.y = _lsu.Debug.GUI.Header:GetTop()
		end
	end
	self.GUI = {}
	self.GUI.Header = UI.CreateFrame("Texture", "Unit_Tracking_Debug_Header", _lsu.Context)
	self.GUI.Header:SetVisible(false)
	self.GUI.Header:SetWidth(self.Constant.Width)
	self.GUI.Header:SetHeight(self.Constant.Height)
	--KBM.LoadTexture(self.GUI.Header, "KingMolinator", "Media/BarTexture.png")
	self.GUI.Header:SetBackgroundColor(0.5, 0, 0, 0.75)
	if not _lsu.Settings.Tracker.x then
		self.GUI.Header:SetPoint("CENTER", UIParent, "CENTER")
	else
		self.GUI.Header:SetPoint("TOPLEFT", UIParent, "TOPLEFT", _lsu.Settings.Tracker.x, _lsu.Settings.Tracker.y)
	end
	self.GUI.HeadText = UI.CreateFrame("Text", "Unit_Tracking_Debug_HText", self.GUI.Header)
	self.GUI.HeadText:SetFontSize(self.Constant.Text)
	self.GUI.HeadText:SetText("Unit Tracker")
	self.GUI.HeadText:SetPoint("CENTER", self.GUI.Header, "CENTER")
	self.GUI.DragFrame = _lsu.AttachDragFrame(self.GUI.Header, self.Callbacks.Position, "Drag", 5)
	self.GUI.Trackers = {}
	self.GUI.LastTracker = self.GUI.Header
	function self:CreateTrack(Name, R, G, B)
		local TrackObj = {
			GUI = {},
		}
		TrackObj.GUI.Frame = UI.CreateFrame("Frame", Name, self.GUI.Header)
		TrackObj.GUI.Frame:SetBackgroundColor(0,0,0,0.33)
		TrackObj.GUI.Frame:SetPoint("TOPLEFT", self.GUI.LastTracker, "BOTTOMLEFT")
		TrackObj.GUI.Frame:SetPoint("RIGHT", self.GUI.LastTracker, "RIGHT")
		TrackObj.GUI.Frame:SetHeight(self.Constant.Height)
		TrackObj.GUI.Text = UI.CreateFrame("Text", Name.."_Text", TrackObj.GUI.Frame)
		TrackObj.GUI.Text:SetText(Name)
		TrackObj.GUI.Text:SetFontSize(self.Constant.Text)
		TrackObj.GUI.Text:SetPoint("CENTERLEFT", TrackObj.GUI.Frame, "CENTERLEFT", 2, 0)
		TrackObj.GUI.Data = UI.CreateFrame("Text", Name.."_Data", TrackObj.GUI.Frame)
		TrackObj.GUI.Data:SetText("0")
		TrackObj.GUI.Data:SetFontColor(R, G, B)
		TrackObj.GUI.Data:SetFontSize(self.Constant.Text)
		TrackObj.GUI.Data:SetPoint("CENTERRIGHT", TrackObj.GUI.Frame, "CENTERRIGHT", -2, 0)
		function TrackObj:UpdateDisplay(New)
			self.GUI.Data:SetText(tostring(New))
		end
		self.GUI.Trackers[Name] = TrackObj
		self.GUI.LastTracker = TrackObj.GUI.Frame
	end
	self:CreateTrack("Idle", 0.9, 0.5, 0.35)
	self:CreateTrack("Partial", 0.75, 0.75, 0.37)
	self:CreateTrack("Available", 0, 0.9, 0)
	self:CreateTrack("Total States", 1, 1, 1)
	--self:CreateTrack("Unknown", 1, 0.7, 0.7)
	--self:CreateTrack("Players", 0.7, 1, 0.7)
	--self:CreateTrack("NPCs", 0.7, 0.7, 1)
	--self:CreateTrack("Total Groups", 1, 1, 1)
	self:CreateTrack("Raid Size", 0, 0.9, 0)
	self:CreateTrack("In Combat", 0, 0.9, 0)
	self:CreateTrack("Dead", 0, 0.9, 0)
	self:CreateTrack("Wiped", 0.9, 0.9, 0)
	function self:UpdateAll()
		self.GUI.Trackers["Idle"]:UpdateDisplay(LibSUnit.Total.Idle)
		self.GUI.Trackers["Partial"]:UpdateDisplay(LibSUnit.Total.Partial)
		self.GUI.Trackers["Available"]:UpdateDisplay(LibSUnit.Total.Avail)		
		self.GUI.Trackers["Total States"]:UpdateDisplay(LibSUnit.Total.Idle + LibSUnit.Total.Partial + LibSUnit.Total.Avail)
		--self.GUI.Trackers["Unknown"]:UpdateDisplay(KBM.Unit.Unknown.Count)
		--self.GUI.Trackers["Players"]:UpdateDisplay(KBM.Unit.Player.Count)
		--self.GUI.Trackers["NPCs"]:UpdateDisplay(KBM.Unit.NPC.Count)		
		--self.GUI.Trackers["Total Groups"]:UpdateDisplay(KBM.Unit.Unknown.Count + KBM.Unit.Player.Count + KBM.Unit.NPC.Count)
		self.GUI.Trackers["Raid Size"]:UpdateDisplay(tostring(LibSUnit.Raid.Members or 0))
		self:UpdateCombat()
		self:UpdateDeath()
	end
	function self:UpdateCombat()
		self.GUI.Trackers["In Combat"]:UpdateDisplay(tostring(LibSUnit.Raid.CombatTotal or 0))	
	end
	function self:UpdateDeath()
		self.GUI.Trackers["Dead"]:UpdateDisplay(tostring(LibSUnit.Raid.DeadTotal or 0))
		self.GUI.Trackers["Wiped"]:UpdateDisplay(tostring(LibSUnit.Raid.Wiped))
	end
end