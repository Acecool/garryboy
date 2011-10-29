AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

cleanup.Register("gem_emulators")
CreateConVar('sbox_max_gem_emulators', 1)

----------------------------------------------------------------------
-- Name: SpawnFunction
-- Desc: Spawns the entity
----------------------------------------------------------------------
function ENT:SpawnFunction( ply, tr )
	if not tr.Hit then return end
	if not ply:CheckLimit( "gem_emulators" ) then return end

	local pos = tr.HitPos + tr.HitNormal * 50
	local ent = ents.Create( "gem_emulator" )
	ent:SetPly( ply )
	ent:SetPos( pos )
	ent:SetAngles( Angle(90,ply:GetAngles().y+180,0) )
	ent:Spawn()
	ent:Activate()
	
	return ent	
end

----------------------------------------------------------------------
-- Name: Initialize
-- Desc: -
----------------------------------------------------------------------
function ENT:Initialize()
	self:ChangeModel( "models/hunter/plates/plate2x2.mdl", true )
end

----------------------------------------------------------------------
-- Name: OnRemove
-- Desc: -
----------------------------------------------------------------------
function ENT:OnRemove()
	self:Exit()
end

----------------------------------------------------------------------
-- Name: InitializePhysics
-- Desc: -
----------------------------------------------------------------------
function ENT:InitializePhysics()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
end

----------------------------------------------------------------------
-- Name: ChangeModel
-- Desc: -
----------------------------------------------------------------------
function ENT:ChangeModel( model, dontMove )
	if not util.IsValidModel( model ) then return end
	local pos, height
	if not dontMove then
		pos = self:GetPos()
		height = self:OBBMaxs().y
	end
	self:SetModel( model )
	self:InitializePhysics()
	if not dontMove then 
		height = self:OBBMaxs().y - height
		self:SetPos( pos + Vector(0,0,height) ) 
	end
end

local models = {
	["1"] = "models/hunter/plates/plate1x1.mdl",
	["2"] = "models/hunter/plates/plate2x2.mdl",
	["3"] = "models/hunter/plates/plate3x3.mdl",
	["4"] = "models/hunter/plates/plate4x4.mdl",
}

concommand.Add( "gem_emulator_changemodel", function( ply, cmd, args )
	local ent = args[1]
	if not ent then ply:ChatPrint( "GEM - Invalid entity specified to changemodel command." ) return end
	ent = Entity(tonumber(ent))
	if not ent or not ent:IsValid() or ent:GetClass() ~= "gem_emulator" then ply:ChatPrint( "GEM - Invalid entity specified to changemodel command." ) return end
	if ent:GetPly() ~= ply then ply:ChatPrint( "GEM - You are not allowed to change the model of that entity." ) return end
	local model = models[args[2]]	
	if not model then ply:ChatPrint( "GEM - Invalid model specified to changemodel command." ) return end
	ent:ChangeModel( model )
end)