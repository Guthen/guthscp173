if not GuthSCP or not GuthSCP.Config then
    return
end

util.AddNetworkString( "vkxscp173:action" )

local scps_173 = {}
hook.Add( "Think", "vkxscp173:think", function()
    for _, v in ipairs( scps_173 ) do
        if not IsValid( v ) or not v:Alive() then continue end
        
        --  should 173 be freezed?
        local freeze = false

        for _, ply in ipairs( player.GetAll() ) do
            if ply == v then continue end
            if not ply:Alive() then continue end
            if GuthSCP.isSCP and GuthSCP.isSCP( ply ) then continue end

            local look = GuthSCP.isLookingAt( ply, v )
            if look and not GuthSCP.isBlinking( ply ) then
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

--[[ hook.Add( "PlayerDeath", "vkxscp173:un_freeze", function( ply )
    ply:Freeze( false )
end ) ]]

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
local blink_distance = CreateConVar( "vkx_scp173_blink_distance", "0", FCVAR_ARCHIVE, "When the blinking system is enabled, represents the maximum distance (in game units) from a SCP-173 instance where you can blink (similar to SCP:SL's system). 0 to disable the distance condition. 1024 is a good value." )
timer.Create( "vkxscp173:blink", .5, 0, function()
    if GuthSCP.Config.vkxscp173.blink_need_scp_173 and #scps_173 == 0 then return end

    --  decrease global blink counter
    local max_blink_count = GuthSCP.Config.vkxscp173.blink_maximum_count
    local is_global_blink = not GuthSCP.Config.vkxscp173.realistic_blink
    if is_global_blink then
        global_blink_count = ( global_blink_count - 1 ) % max_blink_count
    end

    for _, v in pairs( player.GetAll() ) do
        if not v:Alive() then continue end
        if GuthSCP.isSCP and GuthSCP.isSCP( v ) then continue end  --  don't count on SCPs

        --  apply counter
        GuthSCP.setBlinkCounter( v, is_global_blink and global_blink_count or ( GuthSCP.getBlinkCounter( v ) - 1 ) % max_blink_count )
        --debugoverlay.Text( v:GetPos() + Vector( 0, 0, 50 ), "Counter: " .. GuthSCP.getBlinkCounter( v ), GuthSCP.Config.vkxscp173.blink_update_timer )
        
        --  screen blink effect
        local n = GuthSCP.getBlinkCounter( v )
        if n == 0 and v:GetInfoNum( "vkx_scp173_blink", 1 ) == 1 then
            local can_blink, dist = true, blink_distance:GetInt()
            if dist > 0 then
                can_blink = false
                for i, scp in ipairs( scps_173 ) do
                    if v:GetPos():Distance( scp:GetPos() ) <= dist then
                        can_blink = true
                        break
                    end
                end
            end

            if can_blink then
                v:ScreenFade( SCREENFADE.IN, Color( 0, 0, 0 ), .1, GuthSCP.Config.vkxscp173.blink_update_timer )
            end
        end
    end
end )