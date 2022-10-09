local guthscp173 = guthscp.modules.guthscp173

function guthscp173.is_scp_173( ply )
    if not IsValid( ply ) then return end

    return ply:HasWeapon( "vkx_scp_173" )
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


hook.Add( "SetupMove", "guthscp173:no_move", function( ply, mv, cmd )
    if not guthscp173.is_scp_173( ply ) then return end
    if ply:GetMoveType() == MOVETYPE_NOCLIP then return end --  allow noclip

    local looked = guthscp173.is_scp_173_looked( ply )

    --  disable jump
    if guthscp.configs.guthscp173.disable_jump or looked then
        mv:SetButtons( bit.bxor( mv:GetButtons(), IN_JUMP ) )
    end

    --  disable directional movement
    if guthscp.configs.guthscp173.disable_directional_movement or looked then
        mv:SetSideSpeed( 0 )
        mv:SetForwardSpeed( 0 )
    end
end )