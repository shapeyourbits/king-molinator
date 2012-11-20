﻿-- Necrotic Throne Boss Mod for King Boss Mods
-- Written by Paul Snart
-- Copyright 2012
--

KBMSLEXUBFNCT_Settings = nil
chKBMSLEXUBFNCT_Settings = nil

-- Link Mods
local AddonData, KBM = ...
if not KBM.BossMod then
	return
end
local Instance = KBM.BossMod["EUnhallowed_Boneforge"]

local MOD = {
	Directory = Instance.Directory,
	File = "Throne.lua",
	Enabled = true,
	Instance = Instance.Name,
	InstanceObj = Instance,
	HasPhases = true,
	Lang = {},
	ID = "Ex_Throne",
	Object = "MOD",
}

MOD.Throne = {
	Mod = MOD,
	Level = "52",
	Active = false,
	Name = "Necrotic Throne",
	NameShort = "Throne",
	Menu = {},
	Castbar = nil,
	Dead = false,
	Available = false,
	UnitID = nil,
	UTID = {
		[1] = "none",
		[2] = "none",
		[3] = "none",
	},
	TimeOut = 5,
	Triggers = {},
	Settings = {
		CastBar = KBM.Defaults.CastBar(),
	}
}

KBM.RegisterMod(MOD.ID, MOD)

-- Main Unit Dictionary
MOD.Lang.Unit = {}
MOD.Lang.Unit.Throne = KBM.Language:Add(MOD.Throne.Name)
MOD.Lang.Unit.Throne:SetGerman("Nekrotischer Thron")
MOD.Lang.Unit.ThroneL = KBM.Language:Add("Left Throne")
MOD.Lang.Unit.ThroneR = KBM.Language:Add("Right Throne")
MOD.Throne.Name = MOD.Lang.Unit.Throne[KBM.Lang]
MOD.Descript = MOD.Throne.Name
MOD.Lang.Unit.AndShort = KBM.Language:Add("Throne")
MOD.Lang.Unit.AndShort:SetGerman("Thron")
MOD.Throne.NameShort = MOD.Lang.Unit.AndShort[KBM.Lang]

-- Ability Dictionary
MOD.Lang.Ability = {}

MOD.ThroneL = {
	Mod = MOD,
	Level = "52",
	Active = false,
	Name = MOD.Lang.Unit.ThroneL[KBM.Lang],
	NameShort = "Throne",
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

MOD.ThroneR = {
	Mod = MOD,
	Level = "52",
	Active = false,
	Name = MOD.Lang.Unit.ThroneR[KBM.Lang],
	NameShort = "Throne",
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

function MOD:AddBosses(KBM_Boss)
	self.MenuName = self.Descript
	self.Bosses = {
		[self.Throne.Name] = self.Throne,
		--[self.ThroneL.Name] = self.ThroneL,
		--[self.ThroneR.Name] = self.ThroneR,
	}
end

function MOD:InitVars()
	self.Settings = {
		Enabled = true,
		CastBar = self.Throne.Settings.CastBar,
		EncTimer = KBM.Defaults.EncTimer(),
		PhaseMon = KBM.Defaults.PhaseMon(),
		-- MechTimer = KBM.Defaults.MechTimer(),
		-- Alerts = KBM.Defaults.Alerts(),
		-- TimersRef = self.Throne.Settings.TimersRef,
		-- AlertsRef = self.Throne.Settings.AlertsRef,
	}
	KBMSLEXUBFNCT_Settings = self.Settings
	chKBMSLEXUBFNCT_Settings = self.Settings
	
end

function MOD:SwapSettings(bool)

	if bool then
		KBMSLEXUBFNCT_Settings = self.Settings
		self.Settings = chKBMSLEXUBFNCT_Settings
	else
		chKBMSLEXUBFNCT_Settings = self.Settings
		self.Settings = KBMSLEXUBFNCT_Settings
	end

end

function MOD:LoadVars()	
	if KBM.Options.Character then
		KBM.LoadTable(chKBMSLEXUBFNCT_Settings, self.Settings)
	else
		KBM.LoadTable(KBMSLEXUBFNCT_Settings, self.Settings)
	end
	
	if KBM.Options.Character then
		chKBMSLEXUBFNCT_Settings = self.Settings
	else
		KBMSLEXUBFNCT_Settings = self.Settings
	end	
end

function MOD:SaveVars()	
	if KBM.Options.Character then
		chKBMSLEXUBFNCT_Settings = self.Settings
	else
		KBMSLEXUBFNCT_Settings = self.Settings
	end	
end

function MOD:Castbar(units)
end

function MOD:RemoveUnits(UnitID)
	if self.Throne.UnitID == UnitID then
		self.Throne.Available = false
		return true
	end
	return false
end

function MOD:Death(UnitID)
	if self.Throne.UnitID == UnitID then
		self.Throne.Dead = true
		return true
	end
	return false
end

function MOD:UnitHPCheck(uDetails, unitID)	
	if uDetails and unitID then
		if not uDetails.player then
			local BossObj
			if uDetails.type == self.Throne.UTID then
				BossObj = self.Throne
			elseif uDetails.type == self.ThroneL.UTID then
				BossObj = self.ThroneL
			elseif uDetails.type == self.ThroneR.UTID then
				BossObj = self.ThroneR
			end
			if BossObj then
				if not self.EncounterRunning then
					self.EncounterRunning = true
					self.StartTime = Inspect.Time.Real()
					self.HeldTime = self.StartTime
					self.TimeElapsed = 0
					BossObj.Dead = false
					BossObj.Casting = false
					BossObj.CastBar:Create(unitID)
					self.PhaseObj:Start(self.StartTime)
					self.PhaseObj:SetPhase(KBM.Language.Options.Single[KBM.Lang])
					self.PhaseObj.Objectives:AddPercent(self.Throne.Name, 0, 100)
					self.PhaseObj.Objectives:AddPercent(self.ThroneL, 0, 100)
					self.PhaseObj.Objectives:AddPercent(self.ThroneR, 0, 100)
					self.Phase = 1
				end
				BossObj.UnitID = unitID
				BossObj.Available = true
				return BossObj
			end
		end
	end
end

function MOD:Reset()
	self.EncounterRunning = false
	self.Throne.Available = false
	self.Throne.UnitID = nil
	self.Throne.CastBar:Remove()
	self.PhaseObj:End(Inspect.Time.Real())
end

function MOD:Timer()	
end

function MOD:DefineMenu()
	self.Menu = Instance.Menu:CreateEncounter(self.Throne, self.Enabled)
end

function MOD:Start()
	-- Create Timers
	--KBM.Defaults.TimerObj.Assign(self.Throne)
	
	-- Create Alerts
	--KBM.Defaults.AlertObj.Assign(self.Throne)
	
	-- Assign Alerts and Timers to Triggers
	
	self.Throne.CastBar = KBM.CastBar:Add(self, self.Throne)
	self.PhaseObj = KBM.PhaseMonitor.Phase:Create(1)
	self:DefineMenu()
end