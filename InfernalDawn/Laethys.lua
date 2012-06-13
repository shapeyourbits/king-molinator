﻿-- Laethys Boss Mod for King Boss Mods
-- Written by Paul Snart & Ciladan
-- Copyright 2011
--

KBMINDLT_Settings = nil
chKBMINDLT_Settings = nil

-- Link Mods
local AddonData = Inspect.Addon.Detail("KingMolinator")
local KBM = AddonData.data
local IND = KBM.BossMod["Infernal Dawn"]

local LT = {
	Enabled = true,
	Directory = IND.Directory,
	File = "Laethys.lua",
	Instance = IND.Name,
	Type = "20man",
	HasPhases = true,
	Phase = 1,
	Lang = {},
	ID = "Laethys",
	Object = "LT",
}

LT.Laethys = {
	Mod = LT,
	Level = "??",
	Active = false,
	Name = "Laethys",
--  Name = "Normal Practice Dummy",
	NameShort = "Laethys",
	Dead = false,
	Available = false,
	Menu = {},
	UnitID = nil,
	TimeOut = 5,
	Castbar = nil,
	TimersRef = {},
	AlertsRef = {},
	Triggers = {},
	Settings = {
		CastBar = KBM.Defaults.CastBar(),
		 TimersRef = {
			Enabled = true,
			Funnel = KBM.Defaults.TimerObj.Create("red"),
			StormFirst = KBM.Defaults.TimerObj.Create("red"),
		  	Storm = KBM.Defaults.TimerObj.Create("red"),
		  	Breath = KBM.Defaults.TimerObj.Create("blue"),
		  	OrbFirst = KBM.Defaults.TimerObj.Create("dark_green"),
		  	Orb = KBM.Defaults.TimerObj.Create("dark_green"), 
		  	FlareFirst = KBM.Defaults.TimerObj.Create("cyan"),
		  	Flare = KBM.Defaults.TimerObj.Create("cyan"),
		  	GoldFirst = KBM.Defaults.TimerObj.Create("yellow"),
		  	Gold = KBM.Defaults.TimerObj.Create("yellow"),
		 	AddsFirst = KBM.Defaults.TimerObj.Create("purple"),
		 	Adds = KBM.Defaults.TimerObj.Create("purple"),
		  
		 },
		 AlertsRef = {
			Enabled = true,
			Funnel = KBM.Defaults.AlertObj.Create("red"),
			Storm = KBM.Defaults.AlertObj.Create("red"),
			Orb = KBM.Defaults.AlertObj.Create("dark_green"),
			Flare = KBM.Defaults.AlertObj.Create("cyan"),
		 },
	}
}

KBM.RegisterMod(LT.ID, LT)

-- Main Unit Dictionary
LT.Lang.Unit = {}
LT.Lang.Unit.Laethys = KBM.Language:Add(LT.Laethys.Name)
LT.Lang.Unit.Laethys:SetGerman()
LT.Lang.Unit.Laethys:SetFrench()
LT.Lang.Unit.Laethys:SetRussian("Лаэтис")

-- Ability Dictionary
LT.Lang.Ability = {}
LT.Lang.Ability.Breath = KBM.Language:Add("Golden Breath")
LT.Lang.Ability.Storm = KBM.Language:Add("Storm of Treasure")
LT.Lang.Ability.Flare = KBM.Language:Add("Annihilating Flare")
LT.Lang.Ability.Orb = KBM.Language:Add("Metallic Orb")
LT.Lang.Ability.Gold = KBM.Language:Add("Molten Gold")

-- Mechanic Dictionary
LT.Lang.Mechanic = {}
LT.Lang.Mechanic.Adds = KBM.Language:Add("Adds spawn")

-- Menu Dictionary
LT.Lang.Menu = {}
LT.Lang.Menu.Storm = KBM.Language:Add("First Storm of Treasure")
LT.Lang.Menu.Flare = KBM.Language:Add("First Annihilating Flare")
LT.Lang.Menu.Orb = KBM.Language:Add("First Metallic Orb")
LT.Lang.Menu.Gold = KBM.Language:Add("First Molten Gold")
LT.Lang.Menu.Adds = KBM.Language:Add("First Adds spawn")


LT.Laethys.Name = LT.Lang.Unit.Laethys[KBM.Lang]
LT.Laethys.NameShort = LT.Lang.Unit.Laethys[KBM.Lang]
LT.Descript = LT.Laethys.Name

function LT:AddBosses(KBM_Boss)
	self.MenuName = self.Descript
	self.Bosses = {
		[self.Laethys.Name] = self.Laethys,
	}
	KBM_Boss[self.Laethys.Name] = self.Laethys
end

function LT:InitVars()
	self.Settings = {
		Enabled = true,
		CastBar = self.Laethys.Settings.CastBar,
		EncTimer = KBM.Defaults.EncTimer(),
		PhaseMon = KBM.Defaults.PhaseMon(),
		 MechTimer = KBM.Defaults.MechTimer(),
		 Alerts = KBM.Defaults.Alerts(),
		 TimersRef = self.Laethys.Settings.TimersRef,
		 AlertsRef = self.Laethys.Settings.AlertsRef,
	}
	KBMINDLT_Settings = self.Settings
	chKBMINDLT_Settings = self.Settings
	
end

function LT:SwapSettings(bool)

	if bool then
		KBMINDLT_Settings = self.Settings
		self.Settings = chKBMINDLT_Settings
	else
		chKBMINDLT_Settings = self.Settings
		self.Settings = KBMINDLT_Settings
	end

end

function LT:LoadVars()	
	if KBM.Options.Character then
		KBM.LoadTable(chKBMINDLT_Settings, self.Settings)
	else
		KBM.LoadTable(KBMINDLT_Settings, self.Settings)
	end
	
	if KBM.Options.Character then
		chKBMINDLT_Settings = self.Settings
	else
		KBMINDLT_Settings = self.Settings
	end	
end

function LT:SaveVars()	
	if KBM.Options.Character then
		chKBMINDLT_Settings = self.Settings
	else
		KBMINDLT_Settings = self.Settings
	end	
end

function LT:Castbar(units)
end

function LT:RemoveUnits(UnitID)
	if self.Laethys.UnitID == UnitID then
		self.Laethys.Available = false
		return true
	end
	return false
end

function LT:Death(UnitID)
	if self.Laethys.UnitID == UnitID then
		self.Laethys.Dead = true
		return true
	end
	return false
end

function LT:UnitHPCheck(unitDetails, unitID)	
	if unitDetails and unitID then
		if not unitDetails.player then
			if unitDetails.name == self.Laethys.Name then
				if not self.EncounterRunning then
					self.EncounterRunning = true
					self.StartTime = Inspect.Time.Real()
					self.HeldTime = self.StartTime
					self.TimeElapsed = 0
					self.Laethys.Dead = false
					self.Laethys.Casting = false
					self.Laethys.CastBar:Create(unitID)
					self.PhaseObj:Start(self.StartTime)
					self.PhaseObj:SetPhase("1")
					self.PhaseObj.Objectives:AddPercent(self.Laethys.Name, 50, 100)
					self.Phase = 1
					KBM.MechTimer:AddStart(self.Laethys.TimersRef.StormFirst)
					KBM.MechTimer:AddStart(self.Laethys.TimersRef.OrbFirst)
					KBM.MechTimer:AddStart(self.Laethys.TimersRef.FlareFirst)
					KBM.MechTimer:AddStart(self.Laethys.TimersRef.GoldFirst)
					KBM.MechTimer:AddStart(self.Laethys.TimersRef.AddsFirst)
				end
				self.Laethys.UnitID = unitID
				self.Laethys.Available = true
				return self.Laethys
			end
		end
	end
end

function LT:Reset()
	self.EncounterRunning = false
	self.Laethys.Available = false
	self.Laethys.UnitID = nil
	self.Laethys.CastBar:Remove()
	self.PhaseObj:End(Inspect.Time.Real())
end

function LT:Timer()	
end

function LT.Laethys:SetTimers(bool)	
	if bool then
		for TimerID, TimerObj in pairs(self.TimersRef) do
			TimerObj.Enabled = TimerObj.Settings.Enabled
		end
	else
		for TimerID, TimerObj in pairs(self.TimersRef) do
			TimerObj.Enabled = false
		end
	end
end

function LT.Laethys:SetAlerts(bool)
	if bool then
		for AlertID, AlertObj in pairs(self.AlertsRef) do
			AlertObj.Enabled = AlertObj.Settings.Enabled
		end
	else
		for AlertID, AlertObj in pairs(self.AlertsRef) do
			AlertObj.Enabled = false
		end
	end
end

function LT:DefineMenu()
	self.Menu = IND.Menu:CreateEncounter(self.Laethys, self.Enabled)
end

function LT.PhaseTwo()
	LT.PhaseObj.Objectives:Remove()
	LT.Phase = 2
	LT.PhaseObj:SetPhase("2")
	LT.PhaseObj.Objectives:AddPercent(LT.Laethys.Name, 0, 100)
	KBM.MechTimer:AddRemove(LT.Laethys.TimersRef.Storm)
	KBM.MechTimer:AddRemove(LT.Laethys.TimersRef.Breath)
	KBM.MechTimer:AddRemove(LT.Laethys.TimersRef.Orb)
	KBM.MechTimer:AddRemove(LT.Laethys.TimersRef.Flare)
	KBM.MechTimer:AddRemove(LT.Laethys.TimersRef.Gold)
	KBM.MechTimer:AddRemove(LT.Laethys.TimersRef.AddsFirst)
	KBM.MechTimer:AddRemove(LT.Laethys.TimersRef.Adds)
end


function LT:Start()
	-- Create Timers
	
	 self.Laethys.TimersRef.StormFirst = KBM.MechTimer:Add(self.Lang.Ability.Storm[KBM.Lang], 40)
 	 self.Laethys.TimersRef.StormFirst.MenuName = self.Lang.Menu.Storm[KBM.Lang]
 	 self.Laethys.TimersRef.Storm = KBM.MechTimer:Add(self.Lang.Ability.Storm[KBM.Lang], 60)
 	 self.Laethys.TimersRef.Breath = KBM.MechTimer:Add(self.Lang.Ability.Breath[KBM.Lang], 11)
 	 self.Laethys.TimersRef.OrbFirst = KBM.MechTimer:Add(self.Lang.Ability.Orb[KBM.Lang], 35)
 	 self.Laethys.TimersRef.OrbFirst.MenuName = self.Lang.Menu.Orb[KBM.Lang]
 	 self.Laethys.TimersRef.Orb = KBM.MechTimer:Add(self.Lang.Ability.Orb[KBM.Lang], 35)
 	 self.Laethys.TimersRef.FlareFirst = KBM.MechTimer:Add(self.Lang.Ability.Flare[KBM.Lang], 23)
 	 self.Laethys.TimersRef.FlareFirst.MenuName = self.Lang.Menu.Flare[KBM.Lang]
 	 self.Laethys.TimersRef.Flare = KBM.MechTimer:Add(self.Lang.Ability.Flare[KBM.Lang], 23)
 	 self.Laethys.TimersRef.GoldFirst = KBM.MechTimer:Add(self.Lang.Ability.Gold[KBM.Lang],20)
 	 self.Laethys.TimersRef.GoldFirst.MenuName = self.Lang.Menu.Gold[KBM.Lang]
 	 self.Laethys.TimersRef.Gold = KBM.MechTimer:Add(self.Lang.Ability.Gold[KBM.Lang], 20)
 	 self.Laethys.TimersRef.AddsFirst = KBM.MechTimer:Add(self.Lang.Menu.Adds[KBM.Lang],34)
 	 self.Laethys.TimersRef.Adds = KBM.MechTimer:Add(self.Lang.Mechanic.Adds[KBM.Lang], 81)
 	
 	 
	 KBM.Defaults.TimerObj.Assign(self.Laethys)
--	 Create Alerts
	self.Laethys.AlertsRef.Storm = KBM.Alert:Create(self.Lang.Ability.Storm[KBM.Lang], nil, false, true, "red")
	self.Laethys.AlertsRef.Orb = KBM.Alert:Create(self.Lang.Ability.Orb[KBM.Lang], nil, false, true, "dark_green")
	self.Laethys.AlertsRef.Flare = KBM.Alert:Create(self.Lang.Ability.Flare[KBM.Lang], nil, false, true, "cyan")

	 KBM.Defaults.AlertObj.Assign(self.Laethys)
	
--	 Assign Alerts and Timers to Triggers
	self.Laethys.Triggers.PhaseTwo = KBM.Trigger:Create(50, "percent", self.Laethys)
	self.Laethys.Triggers.PhaseTwo:AddPhase(self.PhaseTwo)
	
	self.Laethys.Triggers.Adds = KBM.Trigger:Create(34, "time", self.Laethys)
	self.Laethys.Triggers.Adds:AddTimer(self.Laethys.TimersRef.Adds)
	
	self.Laethys.Triggers.Adds2 = KBM.Trigger:Create(115, "time", self.Laethys)
	self.Laethys.Triggers.Adds2:AddTimer(self.Laethys.TimersRef.Adds)
	
	self.Laethys.Triggers.Breath = KBM.Trigger:Create(self.Lang.Ability.Breath[KBM.Lang], "cast", self.Laethys)
	self.Laethys.Triggers.Breath:AddTimer(self.Laethys.TimersRef.Breath)

	self.Laethys.Triggers.Gold = KBM.Trigger:Create(self.Lang.Ability.Gold[KBM.Lang], "cast", self.Laethys)
	self.Laethys.Triggers.Gold:AddTimer(self.Laethys.TimersRef.Gold)
	
	self.Laethys.Triggers.Storm = KBM.Trigger:Create(self.Lang.Ability.Storm[KBM.Lang], "cast", self.Laethys)
	self.Laethys.Triggers.Storm:AddAlert(self.Laethys.AlertsRef.Storm)
	self.Laethys.Triggers.Storm:AddTimer(self.Laethys.TimersRef.Storm)

	self.Laethys.Triggers.Orb = KBM.Trigger:Create(self.Lang.Ability.Orb[KBM.Lang], "cast", self.Laethys)
	self.Laethys.Triggers.Orb:AddAlert(self.Laethys.AlertsRef.Orb)
	self.Laethys.Triggers.Orb:AddTimer(self.Laethys.TimersRef.Orb)
	
	self.Laethys.Triggers.Flare = KBM.Trigger:Create(self.Lang.Ability.Flare[KBM.Lang], "cast", self.Laethys)
	self.Laethys.Triggers.Flare:AddAlert(self.Laethys.AlertsRef.Flare)
	self.Laethys.Triggers.Flare:AddTimer(self.Laethys.TimersRef.Flare)
	
	self.Laethys.CastBar = KBM.CastBar:Add(self, self.Laethys)
	self.PhaseObj = KBM.PhaseMonitor.Phase:Create(1)
	self:DefineMenu()
end