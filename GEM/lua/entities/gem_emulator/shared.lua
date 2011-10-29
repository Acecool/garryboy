ENT.Type            = "anim"
ENT.Base            = "base_gmodentity"

ENT.PrintName       = "GEM - Gmod Emulator"
ENT.Author          = "Techni and Divran"
ENT.Contact         = "www.wiremod.com"
ENT.Purpose         = "Emulates things"
ENT.Instructions    = "Spawn and follow onscreen instructions."

ENT.Spawnable       = true
ENT.AdminSpawnable  = true

----------------------------------------------------------------------
-- Name: SetPly
-- Desc: Used to set the owner of the entity
----------------------------------------------------------------------
function ENT:SetPly( ply )
	self:SetNWEntity( "Ply", ply )
	self:SetNWInt( "UniqueID", ply:UniqueID() )
end

----------------------------------------------------------------------
-- Name: GetPly
-- Desc: Used to get the owner of the entity
----------------------------------------------------------------------
function ENT:GetPly()
	local ret = self:GetNWEntity( "Ply", false )
	if not ret or not ret:IsValid() then
		local id = self:GetNWInt( "UniqueID" )
		for k,v in pairs( player.GetHumans() ) do
			if v:UniqueID() == id then
				self:SetPly( v )
				return v
			end
		end
	end
	return ret
end

----------------------------------------------------------------------
-- Name: LoadLib
-- Desc: Runs all files in the lib folder
----------------------------------------------------------------------
local function LoadLib()
	if SERVER then
		AddCSLuaFile( "lib/core.lua" )
	else
		include( "lib/core.lua" )
	end

	local folder = "entities/gem_emulator/lib/"
	local entries = file.FindInLua( folder .. "*.lua" )
	for _, entry in ipairs( entries ) do
		if entry:sub(1,3) == "sv_" then
			if SERVER then
				include( folder .. entry )
			end
		elseif entry:sub(1,3) == "sh_" then
			if SERVER then
				AddCSLuaFile( folder .. entry )
			end
			include( folder .. entry )
		elseif entry ~= "core.lua" then
			if SERVER then
				AddCSLuaFile( folder .. entry )
			else
				include( folder .. entry )
			end
		end
	end
end
LoadLib()

concommand.Add( "gem_emulator_reload", function( ply, cmd, args )
	if ply:IsSuperAdmin() then
		LoadLib()
		ply:ChatPrint( "Reloading GEM..." )
	else
		ply:ChatPrint( "You are not allowed to do that." )
	end
end )

function ENT:Enter()
	--[[
	if CLIENT then
		RunConsoleCommand( "gem_emulator_enter" )
		self:CreateTextEntry()
	else
		if not self:GetPly() or not self:GetPly():IsValid() then 
			self.Using = nil
		elseif not self.Using then
			self.Using = true
			self:GetPly():SetPos( self:GetPos() + self:GetUp() * 80 - Vector(0,0,60) )
			self:GetPly():SetEyeAngles( self:LocalToWorldAngles( Angle(90,180,0) ) )
			self:GetPly():Freeze( true )
			self:GetPly():Lock()
			self:GetPhysicsObject():EnableMotion( false )
			self:GetPly():DrawViewModel( false )
		end
	end
	]]
end
function ENT:Exit()
	--[[
	if CLIENT then
		RunConsoleCommand( "gem_emulator_leave" )
		self:RemoveTextEntry()
		self.errordata = {
			draw_message = "Game Paused"
		}
		self.buttons = {
			y = 100,
			{	text = "Resume",
				OnPress = function( self ) self.errordata = nil; self:Enter() end,
			},
			{	text = "Main Menu",
				OnPress = self.Restart,
			},
		}		
	else
		if not self:GetPly() or not self:GetPly():IsValid() then
			self.Using = nil
		elseif self.Using then
			self.Using = nil
			local ang = self:GetPly():EyeAngles()
			ang.r = 0
			ang.p = 0
			self:GetPly():SetEyeAngles( ang )
			self:GetPly():Freeze( false )
			self:GetPly():UnLock()
			self:GetPly():DrawViewModel( true )
		end
	end
	]]
end

if SERVER then
	concommand.Add( "gem_emulator_enter", function( ply, cmd, args )
		local ent = ply:GetEyeTrace().Entity
		if ent and ent:IsValid() and ent:GetClass() == "gem_emulator" and ent:GetPly() == ply then
			ent:Enter()
		end
	end)
	concommand.Add( "gem_emulator_leave", function( ply, cmd, args )
		local ent = ply:GetEyeTrace().Entity
		if ent and ent:IsValid() and ent:GetClass() == "gem_emulator" and ent:GetPly() == ply then
			ent:Exit()
		else
			for k,v in pairs( ents.FindByClass( "gem_emulator" ) ) do
				if v:GetPly() == ply then
					v:Exit()
				end
			end
		end
	end)
end