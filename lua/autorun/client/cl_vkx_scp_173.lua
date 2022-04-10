if not GuthSCP or not GuthSCP.Config then
    return
end

local choose_target, next_position = NULL, nil
net.Receive( "vkxscp173:action", function()
    local is_attack = net.ReadBool()
    local is_replacing = net.ReadBool()

    if is_attack then
        choose_target = is_replacing and net.ReadEntity() or NULL
        next_position = nil
    else
        next_position = is_replacing and net.ReadVector() or nil
        choose_target = NULL
    end
end )

--  HUD
CreateConVar( "vkx_scp173_blink", "1", { FCVAR_USERINFO, FCVAR_ARCHIVE }, "Enables the black blinking screen, it's only visual" )
local halo_convar = CreateClientConVar( "vkx_scp173_halo", "1", nil, nil, "As 173, show or not halos on players" )

local target_color = Color( 200, 150, 25 )
local choose_target_color = Color( 200, 100, 25 )
local red, green = Color( 200, 20, 20 ), Color( 20, 200, 20 )
hook.Add( "PreDrawHalos", "vkxscp173:hud", function()
    if not halo_convar:GetBool() then return end

    local ply = LocalPlayer()
    if not GuthSCP.isSCP173( ply ) then return end

    local target = ply:GetEyeTrace().Entity

    for i, v in ipairs( ents.FindInSphere( ply:GetPos(), GuthSCP.Config.vkxscp173.distance_unit ) ) do
        if not v:IsPlayer() or not v:Alive() then continue end
        if GuthSCP.isSCP and GuthSCP.isSCP( v ) then continue end

        if not ( v == target ) and not ( v == choose_target ) then
            local color = red
            if not GuthSCP.isSCP173Looked( ply ) and ply:GetPos():DistToSqr( v:GetPos() ) <= GuthSCP.Config.vkxscp173.distance_unit_sqr then
                color = ( not GuthSCP.isLookingAt( v, ply ) or GuthSCP.isBlinking( v ) ) and green or red
            end
            halo.Add( { v }, color )
        else
            local t = math.abs( math.sin( CurTime() * 10 ) ) * 2
            halo.Add( { v }, v == choose_target and choose_target_color or target_color, 2 + t, 2 + t )
        end
    end
end )

hook.Add( "PlayerFootstep", "vkxscp173:sound", function( ply )
    if not GuthSCP.isSCP173( ply ) then return end

    --  play sound
    if not GuthSCP.getPlayedSound( ply, GuthSCP.Config.vkxscp173.sound_moved ) then
        GuthSCP.playSound( ply, GuthSCP.Config.vkxscp173.sound_moved, 400, true, 1 )
    end

    --  stop sound after some time (reset the timer each time it walks)
    timer.Create( "vkxscp173:footstep_sound" .. ( ply:AccountID() or ply:EntIndex() ), .35, 1, function()
        GuthSCP.stopSound( ply, GuthSCP.Config.vkxscp173.sound_moved )
    end )
    return true
end )

local preview_model = ClientsideModel( "models/player/scp/173/scp.mdl" )
preview_model:SetMaterial( "debug/debugwireframe" )
preview_model:SetNoDraw( true )

hook.Add( "PostDrawOpaqueRenderables", "vkxscp173:new_pos", function()
    local ply = LocalPlayer()

    local swep = ply:GetActiveWeapon()
    if not IsValid( swep ) or not ( swep:GetClass() == "vkx_scp_173" ) then return end
    if GuthSCP.Config.vkxscp173.disable_teleport then return end
    if not swep.ShowDestinationHUD then return end

    local tr = ply:GetEyeTrace()
    if tr.Entity:IsPlayer() and not next_position then return end

    --	color
    local pos, ang = next_position or tr.HitPos, Angle( 0, ply:GetAngles().y, 0 )
    if ply:GetPos():DistToSqr( pos ) > GuthSCP.Config.vkxscp173.distance_unit_sqr or GuthSCP.isGround( pos ) then 
        render.SetColorModulation( .75, 0, 0 )
    else
        render.SetColorModulation( 0, .75, 0 )
    end

    --	alpha
    render.SetBlend( .1 )

    --	model
    --model:SetNoDraw( false )
    preview_model:SetRenderOrigin( next_position or pos )
    preview_model:SetRenderAngles( ang )
    preview_model:SetModel( ply:GetModel() )
    preview_model:DrawModel()
    --[[ render.Model( {
        model = ply:GetModel(),
        pos = next_position or pos,
        angle = ang,
    }, model ) ]]
    --model:SetNoDraw( true )
end )

local replace_model = ClientsideModel( "models/player/scp/173/scp.mdl" )
replace_model:SetNoDraw( true )

hook.Add( "PrePlayerDraw", "vkxscp173:eye_angle", function( ply )
    --if ply == LocalPlayer() then return end
    if not GuthSCP.isSCP173( ply ) then return end

    --  force a specific angle
    local angles = ply:GetNWAngle( "vkxscp173:eye_angles", ply:EyeAngles() )
    angles.p = 0

    replace_model:SetRenderOrigin( ply:GetPos() )
    replace_model:SetRenderAngles( angles )

    replace_model:SetModel( ply:GetModel() )
    replace_model:SetupBones()  --  allow to draw the model multiple times
    replace_model:DrawModel()
    return true
end )