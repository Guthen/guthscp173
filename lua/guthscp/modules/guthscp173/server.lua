local guthscp173 = guthscp.modules.guthscp173
local config = guthscp.configs.guthscp173

util.AddNetworkString( "guthscp173:action" )

local scps_173 = {}
hook.Add( "Think", "guthscp173:think", function()
	for _, scp in ipairs( scps_173 ) do
		if not IsValid( scp ) or not scp:Alive() then continue end

		--  should 173 be freezed
		local should_freeze = false

		--  check players looking at him
		for _, ply in ipairs( player.GetAll() ) do
			if ply == scp then continue end
			if not ply:Alive() then continue end

			local hook_result = hook.Run( "guthscp173:can_freeze_173", ply, scp )
			if hook_result == false then continue end

			--  to avoid breaking previous behavior, we're doing the SCP condition only
			--  if the result is nil (i.e. no value returned, which is the case with no hook registered),
			--  meaning that if a hook return true, it will bypass the following rules
			if hook_result == nil then
				if not config.freeze_enable_scps and guthscp.is_scp( ply ) then continue end
			end

			if guthscp173.is_blinking( ply ) or not guthscp173.is_looking_at( ply, scp ) then continue end

			should_freeze = true
			break
		end

		--  check npcs looking at him
		if config.npc_support and not should_freeze then
			for i, npc in ipairs( guthscp.get_npcs() ) do
				if npc:Health() <= 0 then continue end

				local hook_result = hook.Run( "guthscp173:can_freeze_173", npc, scp )
				if hook_result == false then continue end

				if not guthscp173.is_looking_at( npc, scp ) or guthscp173.is_blinking( npc ) then continue end

				should_freeze = true
				break
			end
		end

		--  update on difference
		if should_freeze ~= scp:GetNWBool( "guthscp173:looked", false ) then
			scp:SetNWBool( "guthscp173:looked", should_freeze )
		end

		--  update looking angle when not looked at
		if not should_freeze and not config.disable_directional_movement then
			scp:SetNWAngle( "guthscp173:eye_angles", scp:EyeAngles() )
		end
	end
end )

--  oooiiiiinnnnngggr
local can_use = true
hook.Add( "PlayerUse", "zzz_guthscp173:use", function( ply, ent )
	if not guthscp173.is_scp_173( ply ) then return end
	if guthscp173.is_scp_173_looked( ply ) then return false end  --  prevent using on looked

	if can_use and ent:GetClass():find( "button" ) then
		ent:EmitSound( config.sound_button_pressed )

		can_use = false
		timer.Simple( 1, function() can_use = true end )
	end
end)

--  disable damage
hook.Add( "PlayerShouldTakeDamage", "guthscp173:no_damage", function( ply )
	if config.immortal and guthscp173.is_scp_173( ply ) then
		return false
	end
end )

--  HUD blink
local global_blink_count = 0
timer.Create( "guthscp173:blink", 0.5, 0, function()
	--  refresh list
	scps_173 = guthscp173.get_scps_173()

	--  check if blink should happen
	if config.blink_need_scp_173 and #scps_173 == 0 then return end

	--  decrease global blink counter
	local max_blink_count = config.blink_maximum_count
	local is_global_blink = not config.realistic_blink
	if is_global_blink then
		global_blink_count = ( global_blink_count - 1 ) % max_blink_count
	end

	--  blink on players
	for _, ply in ipairs( player.GetAll() ) do
		if not ply:Alive() then continue end
		if guthscp173.is_scp_173( ply ) then continue end

		local should_blink = hook.Run( "guthscp173:should_blink", ply )

		--  similarly to can_freeze_173, to avoid breaking previous behavior, we're doing the SCP condition only
		--  if the result is nil (i.e. no value returned, which is the case with no hook registered),
		--  meaning that if a hook return true, it will bypass the following rules
		if should_blink == nil then
			--  don't blink SCPs (if enabled)
			if not config.blink_enable_scps and guthscp.is_scp( ply ) then 
				should_blink = false 
			end
		end

		if should_blink == false then
			-- prevent blink counter from getting stuck at 0
			guthscp173.set_blink_counter( ply, math.max( 1, guthscp173.get_blink_counter( ply ) ) )
			continue
		end

		--  apply counter
		local new_blink_counter = is_global_blink
							  and global_blink_count
							  or ( guthscp173.get_blink_counter( ply ) - 1 ) % max_blink_count
		guthscp173.set_blink_counter( ply, new_blink_counter )

		--  screen blink effect
		local n = guthscp173.get_blink_counter( ply )
		if n == 0 and ply:GetInfoNum( "guthscp_173_blink", 1 ) == 1 then
			local can_blink, dist = true, config.blink_distance_unit
			if dist > 0 then
				can_blink = false
				for i, scp in ipairs( scps_173 ) do
					if ply:GetPos():Distance( scp:GetPos() ) <= dist then
						can_blink = true
						break
					end
				end
			end

			if can_blink then
				ply:ScreenFade( SCREENFADE.IN, Color( 0, 0, 0 ), 0.1, config.blink_update_timer )
			end
		end
	end

	--  blink on npcs
	if config.npc_support then
		for _, npc in ipairs( guthscp.get_npcs() ) do
			if npc:Health() <= 0 then continue end

			local should_blink = hook.Run( "guthscp173:should_blink", npc )
			if should_blink == false then
				-- prevent blink counter from getting stuck at 0
				guthscp173.set_blink_counter( npc, math.max( 1, guthscp173.get_blink_counter( npc ) ) )
				continue
			end

			--  apply counter
			guthscp173.set_blink_counter( npc, is_global_blink and global_blink_count or ( guthscp173.get_blink_counter( npc ) - 1 ) % max_blink_count )
		end
	end
end )