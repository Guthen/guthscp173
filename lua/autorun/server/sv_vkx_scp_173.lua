if not GuthSCP or not GuthSCP.Config then
    return
end

util.AddNetworkString( "vkxscp173:action" )

local npcs = {}
hook.Add( "OnEntityCreated", "vkxscp173:retrieve_npcs", function( ent )
    if not IsValid( ent ) or ( not ent:IsNPC() and not ent:IsNextBot() ) then return end

    npcs[#npcs + 1] = ent
end )

hook.Add( "EntityRemoved", "vkxscp173:remove_npcs", function( ent )
    if not IsValid( ent ) or ( not ent:IsNPC() and not ent:IsNextBot() ) then return end

    for i, v in ipairs( npcs ) do
        if v == ent then
            table.remove( npcs, i )
            break
        end
    end
end )

local scps_173 = {}
hook.Add( "Think", "vkxscp173:think", function()
    for _, v in ipairs( scps_173 ) do
        if not IsValid( v ) or not v:Alive() then continue end
        
        --  should 173 be freezed?
        local freeze = false
        
        --  players looking at 173s
        for _, ply in ipairs( player.GetAll() ) do
            if ply == v then continue end
            if not ply:Alive() then continue end
            if GuthSCP.isSCP and GuthSCP.isSCP( ply ) then continue end
            if not GuthSCP.isLookingAt( ply, v ) or GuthSCP.isBlinking( ply ) then continue end

            freeze = true
            break
        end

        --  npcs looking at 173s
        if not GuthSCP.Config.vkxscp173.disable_npc and not freeze then
            for i, npc in ipairs( npcs ) do
                if npc:Health() <= 0 then continue end
                if not GuthSCP.isLookingAt( npc, v ) or GuthSCP.isBlinking( npc ) then continue end

                freeze = true
                break
            end
        end

        if not ( freeze == v:GetNWBool( "vkxscp173:looked", false ) ) then 
            v:SetNWBool( "vkxscp173:looked", freeze )
        end
        if not freeze and not GuthSCP.Config.vkxscp173.disable_directional_movement then
            v:SetNWAngle( "vkxscp173:eye_angles", v:EyeAngles() )
        end
    end
end )

--  refresh scps list at a fixed interval
local function refresh_scps_list()
    for i, v in ipairs( scps_173 ) do
        if IsValid( v ) then
            v:Freeze( false )
        end
    end

    scps_173 = {}
    for i, v in ipairs( player.GetAll() ) do
        if GuthSCP.isSCP173( v ) then 
            scps_173[#scps_173 + 1] = v
        end
    end
end
timer.Create( "vkxscp173:add_scp", 10, 0, refresh_scps_list )

--  unfreeze on team change and add to SCP-173 table
hook.Add( "OnPlayerChangedTeam", "vkxscp173:un_freeze", function( ply, old_team, new_team )
    if GuthSCP.isSCP173( ply, new_team ) then
        scps_173[#scps_173 + 1] = ply
    elseif GuthSCP.isSCP173( ply, old_team ) then 
        ply:SetNWBool( "vkxscp173:looked", false )
        --ply:Freeze( false )
        refresh_scps_list()
    end
end )

--  oooiiiiinnnnngggr
local can_use = true
hook.Add( "PlayerUse", "zzz_vkxscp173:use", function( ply, ent ) 
    if GuthSCP.isSCP173( ply ) and GuthSCP.isSCP173Looked( ply ) then
        return false
    end

    if can_use and GuthSCP.isSCP173( ply ) and ent:GetClass():find( "button" ) then
        ent:EmitSound( GuthSCP.Config.vkxscp173.sound_button_pressed )

        can_use = false
        timer.Simple( 1, function() can_use = true end )
    end
end)

--  disable damage
hook.Add( "PlayerShouldTakeDamage", "vkxscp173:no_damage", function( ply )
    if GuthSCP.Config.vkxscp173.immortal and GuthSCP.isSCP173( ply ) then 
        return false 
    end
end )

--  HUD blink
local global_blink_count = 0
timer.Create( "vkxscp173:blink", .5, 0, function()
    if GuthSCP.Config.vkxscp173.blink_need_scp_173 and #scps_173 == 0 then return end

    --  decrease global blink counter
    local max_blink_count = GuthSCP.Config.vkxscp173.blink_maximum_count
    local is_global_blink = not GuthSCP.Config.vkxscp173.realistic_blink
    if is_global_blink then
        global_blink_count = ( global_blink_count - 1 ) % max_blink_count
    end

    --  blink on players
    for _, ply in ipairs( player.GetAll() ) do
        if not ply:Alive() then continue end
        if GuthSCP.isSCP173( ply ) or GuthSCP.isSCP( ply ) then continue end  --  don't count on SCPs

        --  apply counter
        GuthSCP.setBlinkCounter( ply, is_global_blink and global_blink_count or ( GuthSCP.getBlinkCounter( ply ) - 1 ) % max_blink_count )

        --  screen blink effect
        local n = GuthSCP.getBlinkCounter( ply )
        if n == 0 and ply:GetInfoNum( "vkx_scp173_blink", 1 ) == 1 then
            local can_blink, dist = true, GuthSCP.Config.vkxscp173.blink_distance_unit
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
                ply:ScreenFade( SCREENFADE.IN, Color( 0, 0, 0 ), .1, GuthSCP.Config.vkxscp173.blink_update_timer )
            end
        end
    end

    --  blink on npcs
    if not GuthSCP.Config.vkxscp173.disable_npc then
        for _, npc in ipairs( npcs ) do
            if npc:Health() <= 0 then continue end

            --  apply counter
            GuthSCP.setBlinkCounter( npc, is_global_blink and global_blink_count or ( GuthSCP.getBlinkCounter( npc ) - 1 ) % max_blink_count )
        end
    end
end )