﻿-- Core Meltdown Boss Mod for King Boss Mods
-- Written by Paul Snart
-- Copyright 2012
--

KBMSLNMECCM_Settings = nil
chKBMSLNMECCM_Settings = nil

-- Link Mods
local AddonData, KBM = ...
if not KBM.BossMod then
	return
end
local Instance = KBM.BossMod["Empyrean Core"]

local MOD = {
	Directory = Instance.Directory,
	File = "Core.lua",
	Enabled = true,
	Instance = Instance.Name,
	InstanceObj = Instance,
	HasPhases = true,
	Lang = {},
	ID = "Norm_Core",
	Object = "MOD",
}

MOD.Core = {
	Mod = MOD,
	Level = "60",
	Active = false,
	Name = "Core Meltdown",
	NameShort = "Core",
	Menu = {},
	Castbar = nil,
	Dead = false,
	Available = false,
	UnitID = nil,
	UTID = "none",
	TimeOut = 5,
	Triggers = {},
	Settings = {
		CastBar = KBM.Defaults.CastBar(),
	}
}

KBM.RegisterMod(MOD.ID, MOD)

-- Main Unit Dictionary
MOD.Lang.Unit = {}
MOD.Lang.Unit.Core = KBM.Language:Add(MOD.Core.Name)
MOD.Lang.Unit.Core:SetGerman("Kernschmelze")
MOD.Core.Name = MOD.Lang.Unit.Core[KBM.Lang]
MOD.Descript = MOD.Core.Name
MOD.Lang.Unit.AndShort = KBM.Language:Add("Core")
MOD.Lang.Unit.AndShort:SetGerman("Kern")
MOD.Core.NameShort = MOD.Lang.Unit.AndShort[KBM.Lang]

-- Ability Dictionary
MOD.Lang.Ability = {}

function MOD:AddBosses(KBM_Boss)
	self.MenuName = self.Descript
	self.Bosses = {
		[self.Core.Name] = self.Core,
	}
end

function MOD:InitVars()
	self.Settings = {
		Enabled = true,
		CastBar = self.Core.Settings.CastBar,
		EncTimer = KBM.Defaults.EncTimer(),
		PhaseMon = KBM.Defaults.PhaseMon(),
		-- MechTimer = KBM.Defaults.MechTimer(),
		-- Alerts = KBM.Defaults.Alerts(),
		-- TimersRef = self.Core.Settings.TimersRef,
		-- AlertsRef = self.Core.Settings.AlertsRef,
	}
	KBMSLNMECCM_Settings = self.Settings
	chKBMSLNMECCM_Settings = self.Settings
	
end

function MOD:SwapSettings(bool)

	if bool then
		KBMSLNMECCM_Settings = self.Settings
		self.Settings = chKBMSLNMECCM_Settings
	else
		chKBMSLNMECCM_Settings = self.Settings
		self.Settings = KBMSLNMECCM_Settings
	end

end

function MOD:LoadVars()	
	if KBM.Options.Character then
		KBM.LoadTable(chKBMSLNMECCM_Settings, self.Settings)
	else
		KBM.LoadTable(KBMSLNMECCM_Settings, self.Settings)
	end
	
	if KBM.Options.Character then
		chKBMSLNMECCM_Settings = self.Settings
	else
		KBMSLNMECCM_Settings = self.Settings
	end	
end

function MOD:SaveVars()	
	if KBM.Options.Character then
		chKBMSLNMECCM_Settings = self.Settings
	else
		KBMSLNMECCM_Settings = self.Settings
	end	
end

function MOD:Castbar(units)
end

function MOD:RemoveUnits(UnitID)
	if self.Core.UnitID == UnitID then
		self.Core.Available = false
		return true
	end
	return false
end

function MOD:Death(UnitID)
	if self.Core.UnitID == UnitID then
		self.Core.Dead = true
		return true
	end
	return false
end

function MOD:UnitHPCheck(uDetails, unitID)	
	if uDetails and unitID then
		if not uDetails.player then
			if uDetails.name == self.Core.Name then
				if not self.EncounterRunning then
					self.EncounterRunning = true
					self.StartTime = Inspect.Time.Real()
					self.HeldTime = self.StartTime
					self.TimeElapsed = 0
					self.Core.Dead = false
					self.Core.Casting = false
					self.Core.CastBar:Create(unitID)
					self.PhaseObj:Start(self.StartTime)
					self.PhaseObj:SetPhase(KBM.Language.Options.Single[KBM.Lang])
					self.PhaseObj.Objectives:AddPercent(self.Core.Name, 0, 100)
					self.Phase = 1
				end
				self.Core.UnitID = unitID
				self.Core.Available = true
				return self.Core
			end
		end
	end
end

function MOD:Reset()
	self.EncounterRunning = false
	self.Core.Available = false
	self.Core.UnitID = nil
	self.Core.CastBar:Remove()
	self.PhaseObj:End(Inspect.Time.Real())
end

function MOD:Timer()	
end

function MOD:DefineMenu()
	self.Menu = Instance.Menu:CreateEncounter(self.Core, self.Enabled)
end

function MOD:Start()
	-- Create Timers
	--KBM.Defaults.TimerObj.Assign(self.Core)
	
	-- Create Alerts
	--KBM.Defaults.AlertObj.Assign(self.Core)
	
	-- Assign Alerts and Timers to Triggers
	
	self.Core.CastBar = KBM.CastBar:Add(self, self.Core)
	self.PhaseObj = KBM.PhaseMonitor.Phase:Create(1)
	self:DefineMenu()
end