gem = {}
local gem = gem -- Faster access
gem.mt = {} -- The metatable
gem.mt.base = gem -- Faster access to the base global table
gem.mt.__index = gem.mt
gem["8080"] = {}
gem.GBZ80 = {}

local rt = GetRenderTarget("gem_rt_1", 256, 256)

----------------------------------------------------------------------
-- Name: New
-- Desc: Creates a new instance of the emulator
----------------------------------------------------------------------
function gem.New( ent, ROMstring, emulatortype )
	local new = setmetatable({}, gem.mt)
	new.entity = ent
	new.ROMstring = ROMstring
	new.emulatortype = emulatortype
	new.RTMaterial = rt
	new:ClearRT()
	
	if emulatortype == "GBZ80" then
		for k,v in pairs( gem.GBZ80 ) do
			new[k] = v
		end
	elseif emulatortype == "8080" then
		for k,v in pairs( gem["8080"] ) do
			new[k] = v
		end
	end
	
	new:Initialize()
	
	if ent.Debugging then
		new:EnableDebugging()
	end
	
	return new
end

----------------------------------------------------------------------
-- Name: Error
-- Desc: Helper function for erroring
----------------------------------------------------------------------
function gem.mt:Error( msg )
	self.entity:Error( msg )
end

----------------------------------------------------------------------
-- Name: Initialize
-- Desc: Called when the instance is created
----------------------------------------------------------------------
function gem.mt:Initialize()
	-- Placeholder
end

function gem.mt:ClearRT( color )
	render.ClearRenderTarget(self.RTMaterial, color or Color( 0,0,0,255 ))
end

----------------------------------------------------------------------
-- Name: StartRenderTarget
-- Desc: Loads the rendertarget for rendering
----------------------------------------------------------------------
local render_GetRenderTarget = render.GetRenderTarget
local render_SetRenderTarget = render.SetRenderTarget
local render_SetViewPort = render.SetViewPort
local cam_Start2D = cam.Start2D
function gem.mt:StartRenderTarget()
	self.OldWidth, self.OldHeight = ScrW(), ScrH()
	self.OldRT = render_GetRenderTarget()
	render_SetRenderTarget( self.RTMaterial )
	render_SetViewPort(0, 0, 512, 512)
	cam_Start2D()
end

----------------------------------------------------------------------
-- Name: EndRenderTarget
-- Desc: Closes the rendertarget
----------------------------------------------------------------------
local cam_End2D = cam.End2D
function gem.mt:EndRenderTarget()
	cam_End2D()
	render_SetViewPort(0, 0, self.OldWidth, self.OldHeight)
	render_SetRenderTarget( self.OldRT )
end

----------------------------------------------------------------------
-- Name: Draw
-- Desc: Called in the entity's Draw hook
----------------------------------------------------------------------
function gem.mt:Draw()
end

----------------------------------------------------------------------
-- Name: Think
-- Desc: Called in the entity's Think hook
----------------------------------------------------------------------
function gem.mt:Think()
	-- Process here
end

----------------------------------------------------------------------
-- Name: OnRemove
-- Desc: Called when the entity is removed
----------------------------------------------------------------------
function gem.mt:OnRemove()
	-- Do shutdown stuff here (backup state? maybe)
end

----------------------------------------------------------------------
-- Name: KeyChanged
-- Desc: Called when the user presses/releases a key
----------------------------------------------------------------------
function gem.mt:KeyChanged( key, bool )

end

----------------------------------------------------------------------
-- Name: IsDebugging
-- Desc: Returns true if the emulator is in debug mode
----------------------------------------------------------------------
function gem.mt:IsDebugging()
	return (self.Debugging == true)
end

----------------------------------------------------------------------
-- Name: EnableDebugging
-- Desc: User wants to enable debugging
----------------------------------------------------------------------
function gem.mt:EnableDebugging()
	if self:IsDebugging() then return false end
	self._Think = self.Think
	self.Think = function() end
	self.Debugging = true
	return true
end

concommand.Add( "gem_emulator_debug", function( ply )
	if not ply:IsSuperAdmin() then return end
	local ent = ply:GetEyeTrace().Entity
	if ent and ent:IsValid() and ent:GetClass() == "gem_emulator" then
		if ent.Emulator then
			if ent.Emulator:EnableDebugging() then
				ply:ChatPrint( "Debugging enabled." )
				return
			end
		else
			ent.Debugging = true
			ply:ChatPrint( "Debugging enabled." )
			return
		end
	end
	ply:ChatPrint( "Debug enabling failed." )
end)

----------------------------------------------------------------------
-- Name: DisableDebugging
-- Desc: User wants to disable debugging
----------------------------------------------------------------------
function gem.mt:DisableDebugging()
	if not self:IsDebugging() then return false end
	self.Think = self._Think
	self._Think = nil
	self.Debugging = false
	return true
end

concommand.Add( "gem_emulator_disabledebug", function( ply )
	if not ply:IsSuperAdmin() then return end
	local ent = ply:GetEyeTrace().Entity
	if ent and ent:IsValid() and ent:GetClass() == "gem_emulator" then
		if ent.Emulator then
			if ent.Emulator:DisableDebugging() then
				ply:ChatPrint( "Debugging disabled." )
				return
			end
		else
			ent.Debugging = nil
			ply:ChatPrint( "Debugging disabled." )
			return
		end
	end
	ply:ChatPrint( "Debug disabling failed." )
end)

----------------------------------------------------------------------
-- Name: Step
-- Desc: Debug stepping
----------------------------------------------------------------------
function gem.mt:Step()
end

concommand.Add( "gem_emulator_dostep", function( ply, cmd, args )
	if not ply:IsSuperAdmin() then return end
	local ent = ply:GetEyeTrace().Entity
	if ent and ent:IsValid() and ent:GetClass() == "gem_emulator" and ent.Emulator then
		local num = tonumber(args[1])
		if num and num > 1 then
			for i=1, num do
				ent.Emulator:Step()
				self.NextPC = self.PC
			end
		else
			ent.Emulator:Step()
		end
	end
end)

concommand.Add( "gem_emulator_stepto", function( ply, cmd, args )
	if not ply:IsSuperAdmin() then return end
	local ent = ply:GetEyeTrace().Entity
	if ent and ent:IsValid() and ent:GetClass() == "gem_emulator" and ent.Emulator then
		local num = tonumber(args[1])
		if not num then ErrorNoHalt( "Invalid step amount specified" ) return end
		local cycles = ent.Emulator.Execs
		if num > cycles then
			for i=1,num-cycles do
				ent.Emulator:Step()
			end
		elseif num < cycles then
			ent.Emulator:Restart()
			for i=1,num do
				ent.Emulator:Step()
			end
		else
			ErrorNoHalt( "It's already at that number of cycles!" )
		end
	end
end)

concommand.Add( "gem_emulator_reset", function( ply, cmd, args )
	if not ply:IsSuperAdmin() then return end
	local ent = ply:GetEyeTrace().Entity
	if ent and ent:IsValid() and ent:GetClass() == "gem_emulator" and ent.Emulator then
		ent.Emulator:Restart()
	end
end)

----------------------------------------------------------------------
-- Name: DumpHistory
-- Desc: Dump history to file
----------------------------------------------------------------------
function gem.mt:DumpHistory()
	if not file.IsDir( "gem_emulator" ) then file.CreateDir( "gem_emulator" ) end
	file.Write( "gem_emulator/history.txt", table.concat( self.History, "\n" ) )
end

concommand.Add( "gem_emulator_dumphistory", function( ply, cmd, args )
	if not ply:IsSuperAdmin() then return end
	local ent = ply:GetEyeTrace().Entity
	if ent and ent:IsValid() and ent:GetClass() == "gem_emulator" and ent.Emulator then
		ent.Emulator:DumpHistory()
	end
end)










--------------------------------------------------------------
-- TEMPORARY STUFF
--------------------------------------------------------------

concommand.Add( "gem_emulator_next_line", function( ply, cmd, args )
	if not ply:IsSuperAdmin() then return end
	local ent = ply:GetEyeTrace().Entity
	if ent and ent:IsValid() and ent:GetClass() == "gem_emulator" and ent.Emulator and ent.Emulator:IsDebugging() then
		ent.Emulator:NextLine()
	end
end)