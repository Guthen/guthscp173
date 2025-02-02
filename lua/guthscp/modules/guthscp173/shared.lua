local guthscp173 = guthscp.modules.guthscp173
local config = guthscp.configs.guthscp173

--  scps filter
guthscp173.filter = guthscp.players_filter:new( "guthscp173" )
guthscp173.filter_131 = guthscp.players_filter:new( "guthscp131" )
if SERVER then
	guthscp173.filter:listen_disconnect()
	guthscp173.filter:listen_weapon_users( "guthscp_173" )  --  being SCP-173 just mean a player having the weapon 

	guthscp173.filter.event_removed:add_listener( "guthscp173:unfreeze", function( ply )
		ply:SetNWBool( "guthscp173:looked", false )
	end )

	guthscp173.filter_131:listen_disconnect()
	guthscp173.filter_131:listen_weapon_users( "guthscp_131" )  --  being SCP-173 just mean a player having the weapon 
end

function guthscp173.get_scps_173()
	return guthscp173.filter:get_entities()
end

--  functions
function guthscp173.is_scp_173( ply )
	if CLIENT and ply == nil then
		ply = LocalPlayer() 
	end

	return guthscp173.filter:is_in( ply )
end

-- 131 functions
function guthscp173.get_scps_131()
	return guthscp173.filter_131:get_entities()
end

--  functions
function guthscp173.is_scp_131( ply )
	if CLIENT and ply == nil then
		ply = LocalPlayer() 
	end

	return guthscp173.filter_131:is_in( ply )
end

function guthscp173.is_scp_173_looked( ply )
	return ply:GetNWBool( "guthscp173:looked", false )
end

function guthscp173.is_looking_at( ply, ent )
	if not IsValid( ply ) then return false end
	if not ply:IsPlayer() then 
		--  implementation for NPCs & NextBots
		if CLIENT then
			return false
		end
	end  

	--  get target bounds
	local pos = ent:GetPos()
	local min, max = ent:GetModelBounds()
	local tall = Vector( 0, 0, max.z - min.z )

	--  get field of view
	local fov = ( ply:IsPlayer() and ply:GetFOV() or 90 ) + 25
	local vision_range = math.cos( math.rad( fov / 2 ) )

	--  check potential visibility
	local dot = ply:GetAimVector():Dot( ( pos - ply:GetPos() ):GetNormal() )
	return dot > 0 and dot > vision_range and ( ply:IsLineOfSightClear( pos ) or ply:IsLineOfSightClear( pos + tall ) )
end

function guthscp173.is_blinking( ply )
	if not IsValid( ply ) then return false end
	return ply:GetNWBool( "guthscp173:blink_counter", 0 ) == 0
end

function guthscp173.set_blink_counter( ply, count )
	ply:SetNWInt( "guthscp173:blink_counter", count )
end

function guthscp173.get_blink_counter( ply )
	local blink_counter = ply:GetNWInt( "guthscp173:blink_counter", nil )

	--  initialize counter
	if not blink_counter then 
		guthscp173.set_blink_counter( math.random( guthscp.configs.guthscp173.blink_maximum_count ) )
		return guthscp173.get_blink_counter()
	end

	return blink_counter
end

function guthscp173.player_attack_trace( ply )
	return guthscp.world.player_trace_attack( 
		ply, 
		guthscp.configs.guthscp173.distance_unit, 
		Vector( 
			guthscp.configs.guthscp173.attack_hull_size, 
			guthscp.configs.guthscp173.attack_hull_size, 
			guthscp.configs.guthscp173.attack_hull_size 
		) 
	)
end

function guthscp173.can_teleport_to( ply, pos )
	if not guthscp.world.is_ground( pos ) then return false end
	if config.safe_teleport and guthscp.world.safe_entity_trace( ply, pos ).Hit then return false end
	
	return true
end

--  handle movement
hook.Add( "SetupMove", "guthscp173:no_move", function( ply, mv, cmd )
	if not guthscp173.is_scp_173( ply ) then return end
	if ply:GetMoveType() == MOVETYPE_NOCLIP then return end --  allow noclip

	local looked = guthscp173.is_scp_173_looked( ply )

	--  disable jump
	if guthscp.configs.guthscp173.disable_jump or looked then
		mv:SetButtons( bit.band( mv:GetButtons(), bit.bnot( IN_JUMP ) ) )
	end

	--  disable directional movement
	if guthscp.configs.guthscp173.disable_directional_movement or looked then
		mv:SetSideSpeed( 0 )
		mv:SetForwardSpeed( 0 )
	end
end )