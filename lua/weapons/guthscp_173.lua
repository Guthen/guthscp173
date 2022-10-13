if not guthscp then
	error( "guthscp173 - fatal error! https://github.com/Guthen/guthscpbase must be installed on the server!" )
	return
end

local guthscp173 = guthscp.modules.guthscp173


AddCSLuaFile()

SWEP.PrintName				= "SCP-173"
SWEP.Author					= "Vyrkx A.K.A. Guthen"
SWEP.Instructions			= "Left click to teleport and to kill the human you're looking at. Right click to teleport where you look. Reload to trigger the destination HUD."
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
	net.Start( "guthscp173:action" )
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
	net.Start( "guthscp173:action" )
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
	target:EmitSound( guthscp.configs.guthscp173.sounds_snapped_neck[math.random( #guthscp.configs.guthscp173.sounds_snapped_neck )] )
	
	if ply.guthscp173_next_target then
		send_target( ply ) --  erase target

		ply.guthscp173_next_target = nil
	end

	ply:SetNWAngle( "guthscp173:eye_angles", ply:EyeAngles() )
end

local function move_at( ply, pos )
	ply:SetPos( pos )
	ply:EmitSound( guthscp.configs.guthscp173.sounds_teleported[math.random( #guthscp.configs.guthscp173.sounds_teleported )] )

	if ply.guthscp173_next_position then
		send_position( ply ) --  erase position

		ply.guthscp173_next_position = nil
	end
	
	ply:SetNWAngle( "guthscp173:eye_angles", ply:EyeAngles() )
end


function SWEP:PrimaryAttack()
	if not SERVER then return end

	local ply = self:GetOwner()
	local tr = ply:GetEyeTrace()
	local target = tr.Entity
	if not IsValid( target ) then return end

	--  kill target
	if target:IsPlayer() or target:IsNPC() or target:IsNextBot() then
		if target:GetPos():DistToSqr( ply:GetPos() ) > guthscp.configs.guthscp173.distance_unit_sqr then return end
		if guthscp.is_scp( target ) then return end

		if target:Health() > 0 then --  not using Player/Alive caused not existing on NPCs
			if guthscp173.is_scp_173_looked( ply ) then
				send_target( ply, target )

				ply.guthscp173_next_target = target
				ply.guthscp173_next_position = nil
			else
				kill_target( ply, target )
			end
			
			self:SetNextPrimaryFire( CurTime() + .5 )
		end
	--  break entities
	elseif guthscp.configs.guthscp173.breaking_enabled then
		if target:GetPos():Distance( ply:GetPos() ) > 80 then return end
		if not guthscp.is_breakable_entity( target ) then return end

		--  counter decrease
		target.guthscp173_break_count = ( tr.Entity.guthscp173_break_count or guthscp.configs.guthscp173.break_hit_count ) - 1

		--  break
		if target.guthscp173_break_count <= 0 then
			guthscp.break_entities_at_player_trace( tr, guthscp.configs.guthscp173.break_force_scale )
			target.guthscp173_break_count = nil
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
	if guthscp.configs.guthscp173.disable_teleport then return end  --  disable this behaviour via config

	local ply = self:GetOwner()

	--  check trace pos validity
	local pos = ply:GetEyeTrace().HitPos
	if ply:GetPos():DistToSqr( pos ) > guthscp.configs.guthscp173.distance_unit_sqr or not guthscp.world.is_ground( pos ) then return end

	if guthscp173.is_scp_173_looked( ply ) then 
		--  schedule next position
		send_position( ply, pos )

		ply.guthscp173_next_position = pos
		ply.guthscp173_next_target = nil
	else
		--  move directly there
		move_at( ply, pos )
	end

	--  cooldown
	self.Weapon:SetNextSecondaryFire( CurTime() + .5 )
end

function SWEP:Reload()
	if self.NextReloadTime and self.NextReloadTime >= CurTime() then return end

	self.ShowDestinationHUD = not self.ShowDestinationHUD
	self.NextReloadTime = CurTime() + .5
end

function SWEP:Think()
	local ply = self:GetOwner()
	if guthscp173.is_scp_173_looked( ply ) then return end

	self.GuthSCPLVL = guthscp.configs.guthscp173.keycard_level or 0

	if IsValid( ply.guthscp173_next_target ) then
		--  cancel if too far
		if ply.guthscp173_next_target:GetPos():DistToSqr( ply:GetPos() ) > guthscp.configs.guthscp173.distance_unit_sqr then 
			send_target( ply, nil )  --  erase target
			
			ply.guthscp173_next_target = nil
			return
		end

		--  kill scheduled target
		kill_target( ply, ply.guthscp173_next_target )
	elseif ply.guthscp173_next_position then
		--  cancel if too far
		if ply.guthscp173_next_position:DistToSqr( ply:GetPos() ) > guthscp.configs.guthscp173.distance_unit_sqr then 
			send_position( ply, nil )  --  erase position

			ply.guthscp173_next_position = nil
			return
		end

		--  move to scheduled position
		move_at( ply, ply.guthscp173_next_position )
	end
end

if CLIENT then
	function SWEP:DrawHUD()
		local ply = LocalPlayer() 
		if not IsValid( ply ) then return end	
		if not guthscp173.is_scp_173_looked( ply ) then return end

		draw.SimpleTextOutlined( "Looked at", "ScoreboardDefaultTitle", ScrW() / 2, ScrH() * .85, team.GetColor( ply:Team() ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 3, color_black )
	end

	--  add to spawnmenu
	if guthscp then
		guthscp.spawnmenu.add_weapon( SWEP, "SCPs" )
	end
end
