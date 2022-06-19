AddCSLuaFile()

SWEP.PrintName				= "SCP-173"
SWEP.Author					= "Vyrkx A.K.A. Guthen"
SWEP.Instructions			= "Left click to teleport and kill a human around you. Right click to teleport where you look. Reload to trigger the destination HUD."
SWEP.Category 				= "GuthSCP"

SWEP.Spawnable 				= true
SWEP.AdminOnly 				= false

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

SWEP.Weight					= 1
SWEP.AutoSwitchTo			= true
SWEP.AutoSwitchFrom			= false

SWEP.Slot			   	 	= 1
SWEP.SlotPos				= 1
SWEP.DrawAmmo				= false
SWEP.DrawCrosshair			= true

SWEP.HoldType 				= "passive"

SWEP.ViewModel				= "models/weapons/v_hands.mdl"
SWEP.WorldModel				= ""

SWEP.GuthSCPLVL 		   	= 	0

--	preview the teleport destination
SWEP.ShowDestinationHUD = true

local function send_target( ply, target )
	net.Start( "vkxscp173:action" )
		net.WriteBool( true )
		if IsValid( target ) then
			net.WriteBool( true )
			net.WriteEntity( target )
		else
			net.WriteBool( false )
		end
	net.Send( ply )
end

local function send_position( ply, pos )
	net.Start( "vkxscp173:action" )
		net.WriteBool( false )
		if pos then
			net.WriteBool( true )
			net.WriteVector( pos )
		else
			net.WriteBool( false )
		end
	net.Send( ply )
end

local function kill_target( ply, target )
	ply:SetPos( target:GetPos() - ( target:GetPos() - ply:GetPos() ):GetNormalized() * 15 )
	target:TakeDamage( math.huge, ply, ply:GetActiveWeapon() )
	target:EmitSound( GuthSCP.Config.vkxscp173.sounds_snapped_neck[math.random( #GuthSCP.Config.vkxscp173.sounds_snapped_neck )] )
	
	if ply.vkxscp173_next_target then
		send_target( ply ) --  erase target

		ply.vkxscp173_next_target = nil
	end

	ply:SetNWAngle( "vkxscp173:eye_angles", ply:EyeAngles() )
end

local function move_at( ply, pos )
	ply:SetPos( pos )
	ply:EmitSound( GuthSCP.Config.vkxscp173.sounds_teleported[math.random( #GuthSCP.Config.vkxscp173.sounds_teleported )] )

	if ply.vkxscp173_next_position then
		send_position( ply ) --  erase position

		ply.vkxscp173_next_position = nil
	end
	
	ply:SetNWAngle( "vkxscp173:eye_angles", ply:EyeAngles() )
end

function SWEP:PrimaryAttack()
	if not SERVER then return end

	local ply = self:GetOwner()
	local tr = ply:GetEyeTrace()
	local target = tr.Entity
	if not IsValid( target ) then return end

	--  kill target
	if target:IsPlayer() or target:IsNPC() or target:IsNextBot() then
		if target:GetPos():DistToSqr( ply:GetPos() ) > GuthSCP.Config.vkxscp173.distance_unit_sqr then return end
		if GuthSCP.isSCP( target ) then return end

		if target:Health() > 0 then --  not using Player/Alive caused not existing on NPCs
			if GuthSCP.isSCP173Looked( ply ) then
				send_target( ply, target )

				ply.vkxscp173_next_target = target
				ply.vkxscp173_next_position = nil
			else
				kill_target( ply, target )
			end
			
			self:SetNextPrimaryFire( CurTime() + .5 )
		end
	--  break entities
	elseif GuthSCP.Config.vkxscp173.breaking_enabled then
		if target:GetPos():Distance( ply:GetPos() ) > 80 then return end
		if not GuthSCP.isBreakableEntity( target ) then return end

		--  counter decrease
		target.vkxscp173_break_count = ( tr.Entity.vkxscp173_break_count or GuthSCP.Config.vkxscp173.break_hit_count ) - 1

		--  break
		if target.vkxscp173_break_count <= 0 then
			GuthSCP.breakEntitiesAtPlayerTrace( tr, GuthSCP.Config.vkxscp173.break_force_scale )
			target.vkxscp173_break_count = nil
		--  hit
		else
			--  sparks effect
			if IsFirstTimePredicted() then
				local effect = EffectData()
				effect:SetOrigin( target:GetPos() + target:OBBCenter() )
				effect:SetMagnitude( 3 )
				effect:SetScale( 2 )
				effect:SetRadius( 5 )
				util.Effect( "Sparks", effect, true, true )
			end

			target:EmitSound( ( "physics/concrete/concrete_break%i.wav" ):format( math.random( 2, 3 ) ) )
            util.ScreenShake( target:GetPos(), 5, 20, 1, 200 )
		end

		self:SetNextPrimaryFire( CurTime() + .75 )
	end
end

function SWEP:SecondaryAttack()
	if not SERVER then return end
	if GuthSCP.Config.vkxscp173.disable_teleport then return end

	local ply = self:GetOwner()

	local pos = ply:GetEyeTrace().HitPos
	if ply:GetPos():DistToSqr( pos ) > GuthSCP.Config.vkxscp173.distance_unit_sqr or GuthSCP.isGround( pos ) then return end

	if GuthSCP.isSCP173Looked( ply ) then 
		send_position( ply, pos )

		ply.vkxscp173_next_position = pos
		ply.vkxscp173_next_target = nil
	else
		move_at( ply, pos )
	end

	self.Weapon:SetNextSecondaryFire( CurTime() + .5 )
end

function SWEP:Reload()
	if self.NextReloadTime and self.NextReloadTime >= CurTime() then return end

	self.ShowDestinationHUD = not self.ShowDestinationHUD
	self.NextReloadTime = CurTime() + .5
end

function SWEP:Think()
	local ply = self:GetOwner()
	if GuthSCP.isSCP173Looked( ply ) then return end

	self.GuthSCPLVL = GuthSCP.Config.vkxscp173.keycard_level or 0

	if IsValid( ply.vkxscp173_next_target ) then
		if ply.vkxscp173_next_target:GetPos():DistToSqr( ply:GetPos() ) > GuthSCP.Config.vkxscp173.distance_unit_sqr then 
			send_target( ply ) --  erase target

			ply.vkxscp173_next_target = nil
			return
		end
		kill_target( ply, ply.vkxscp173_next_target )
	elseif ply.vkxscp173_next_position then
		if ply.vkxscp173_next_position:DistToSqr( ply:GetPos() ) > GuthSCP.Config.vkxscp173.distance_unit_sqr then 
			send_position( ply ) --  erase position

			ply.vkxscp173_next_position = nil
			return
		end
		move_at( ply, ply.vkxscp173_next_position )
	end
end

--[[ function SWEP:Deploy()
	if not SERVER then return end

	local ply = self:GetOwner()
	--	don't know why but model isn't networked well from server to client on my game, so I improvise
	ply:SetNWString( "vkxscp173:model", ply:GetModel() )
end ]]

if CLIENT then
	function SWEP:DrawHUD()
		local ply = LocalPlayer() 
		if not ply or not IsValid( ply ) then return end
	
		if GuthSCP.isSCP173Looked( ply ) then
			draw.SimpleTextOutlined( "Looked at", "ScoreboardDefaultTitle", ScrW() / 2, ScrH() * .85, team.GetColor( ply:Team() ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 3, color_black )
		end
	end
end