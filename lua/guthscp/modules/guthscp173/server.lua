local guthscp173 = guthscp.modules.guthscp173

util.AddNetworkString( "guthscp173:action" )

local scps_173 = {}
hook.Add( "Think", "guthscp173:think", function()
    for _, v in ipairs( scps_173 ) do
        if not IsValid( v ) or not v:Alive() then continue end
        
        --  should 173 be freezed
        local freeze = false
        
        --  check players looking at him
        for _, ply in ipairs( player.GetAll() ) do
            if ply == v then continue end
            if not ply:Alive() then continue end
            if guthscp.is_scp and guthscp.is_scp( ply ) then continue end
            if guthscp173.is_blinking( ply ) or not guthscp173.is_looking_at( ply, v ) then continue end

            freeze = true
            break
        end

        --  check npcs looking at him
        if not guthscp.configs.guthscp173.disable_npc and not freeze then
            for i, npc in ipairs( guthscp.get_npcs() ) do
                if npc:Health() <= 0 then continue end
                if not guthscp173.is_looking_at( npc, v ) or guthscp173.is_blinking( npc ) then continue end

                freeze = true
                break
            end
        end

        --  update on difference
        if not ( freeze == v:GetNWBool( "guthscp173:looked", false ) ) then 
            v:SetNWBool( "guthscp173:looked", freeze )
        end

        --  update looking angle when not looked at
        if not freeze and not guthscp.configs.guthscp173.disable_directional_movement then
            v:SetNWAngle( "guthscp173:eye_angles", v:EyeAngles() )
        end
    end
end )

--  refresh scps list at a fixed interval
--  TODO: make a global system for managing scp players
local function refresh_scps_list()
    for i, v in ipairs( scps_173 ) do
        if IsValid( v ) then
            v:Freeze( false )
        end
    end

    scps_173 = {}
    for i, v in ipairs( player.GetAll() ) do
        if guthscp173.is_scp_173( v ) then 
            scps_173[#scps_173 + 1] = v
        end
    end
end
timer.Create( "guthscp173:refresh", 10, 0, refresh_scps_list )

--  unfreeze on team change and add to SCP-173 table
hook.Add( "OnPlayerChangedTeam", "guthscp173:un_freeze", function( ply, old_team, new_team )
    if guthscp173.is_scp_173( ply ) then
        scps_173[#scps_173 + 1] = ply
    elseif guthscp173.is_scp_173( ply ) then 
        ply:SetNWBool( "guthscp173:looked", false )
        --ply:Freeze( false )
        refresh_scps_list()
    end
    --  TODO: check this ^
end )

--  oooiiiiinnnnngggr
local can_use = true
hook.Add( "PlayerUse", "zzz_guthscp173:use", function( ply, ent ) 
    if not guthscp173.is_scp_173( ply ) then return end
    if guthscp173.is_scp_173_looked( ply ) then return false end  --  prevent using on looked

    if can_use and ent:GetClass():find( "button" ) then
        ent:EmitSound( guthscp.configs.guthscp173.sound_button_pressed )

        can_use = false
        timer.Simple( 1, function() can_use = true end )
    end
end)

--  disable damage
hook.Add( "PlayerShouldTakeDamage", "guthscp173:no_damage", function( ply )
    if guthscp.configs.guthscp173.immortal and guthscp173.is_scp_173( ply ) then 
        return false 
    end
end )

--  HUD blink
local global_blink_count = 0
timer.Create( "guthscp173:blink", .5, 0, function()
    if guthscp.configs.guthscp173.blink_need_scp_173 and #scps_173 == 0 then return end

    --  decrease global blink counter
    local max_blink_count = guthscp.configs.guthscp173.blink_maximum_count
    local is_global_blink = not guthscp.configs.guthscp173.realistic_blink
    if is_global_blink then
        global_blink_count = ( global_blink_count - 1 ) % max_blink_count
    end

    --  blink on players
    for _, ply in ipairs( player.GetAll() ) do
        if not ply:Alive() then continue end
        if guthscp173.is_scp_173( ply ) or guthscp.is_scp( ply ) then continue end  --  don't count on SCPs

        --  apply counter
        guthscp173.set_blink_counter( ply, is_global_blink and global_blink_count or ( guthscp173.get_blink_counter( ply ) - 1 ) % max_blink_count )

        --  screen blink effect
        local n = guthscp173.get_blink_counter( ply )
        if n == 0 and ply:GetInfoNum( "guthscp_173_blink", 1 ) == 1 then
            local can_blink, dist = true, guthscp.configs.guthscp173.blink_distance_unit
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
                ply:ScreenFade( SCREENFADE.IN, Color( 0, 0, 0 ), .1, guthscp.configs.guthscp173.blink_update_timer )
            end
        end
    end

    --  blink on npcs
    if not guthscp.configs.guthscp173.disable_npc then
        for _, npc in ipairs( guthscp.get_npcs() ) do
            if npc:Health() <= 0 then continue end

            --  apply counter
            guthscp173.set_blink_counter( npc, is_global_blink and global_blink_count or ( guthscp173.get_blink_counter( npc ) - 1 ) % max_blink_count )
        end
    end
end )