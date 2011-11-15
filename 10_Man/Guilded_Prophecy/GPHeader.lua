﻿-- Guilded Prophecy Header for KM:Boss Mods
-- Written by Paul Snart
-- Copyright 2011
--

KBMGP_Settings = {}

local GP = {
	Header = nil,
	Enabled = true,
	IsInstance = true,
	Name = "Guilded Prophecy",
	Type = "10man",
	ID = "GP",
}

local KBM = KBM_RegisterMod("Guilded Prophecy", GP)

KBM.Language:Add(GP.Name)
--KBM.Language[HK.Name]:SetFrench("Glasmarteau")

GP.Name = KBM.Language[GP.Name][KBM.Lang]

function GP:AddBosses(KBM_Boss)
end

function GP:InitVars()
end

function GP:LoadVars()
end

function GP:SaveVars()
end

function GP:Start()
	function self:Enabled(bool)
	
	end
	GP.Header = KBM.MainWin.Menu:CreateHeader(self.Name, self.Enabled, true)
	GP.Header.Check:SetEnabled(false)
end

function KBMGP_Register()
	return GP
end