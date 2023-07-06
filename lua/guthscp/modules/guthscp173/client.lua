local guthscp173 = guthscp.modules.guthscp173

local choose_target, next_position = NULL, nil
net.Receive( "guthscp173:action", function()
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
CreateConVar( "guthscp_173_blink", "1", { FCVAR_USERINFO, FCVAR_ARCHIVE }, "Enables the black blinking screen, it's only visual" )
local halo_convar = CreateClientConVar( "guthscp_173_halo", "1", nil, nil, "As 173, show or not halos on players" )

local target_color = Color( 200, 150, 25 )
local choose_target_color = Color( 200, 100, 25 )
local red, green = Color( 200, 20, 20 ), Color( 20, 200, 20 )
hook.Add( "PreDrawHalos", "guthscp173:hud", function()
	if not halo_convar:GetBool() then return end

	local ply = LocalPlayer()
	if not guthscp173.is_scp_173( ply ) then return end

	local target = guthscp173.player_attack_trace( ply ).Entity

	for i, v in ipairs( ents.FindInSphere( ply:GetPos(), guthscp.configs.guthscp173.distance_unit ) ) do
		if v == ply then continue end 
		if not ( v:IsPlayer() and v:Alive() ) and not ( ( v:IsNPC() or v:IsNextBot() ) and v:Health() >= 0 ) then continue end
		if guthscp.is_scp( v ) then continue end

		if not ( v == target ) and not ( v == choose_target ) then
			--  draw potential target
			local color = red
			if not guthscp173.is_scp_173_looked( ply ) and ply:GetPos():DistToSqr( v:GetPos() ) <= guthscp.configs.guthscp173.distance_unit_sqr then
				color = ( guthscp173.is_blinking( v ) or not guthscp173.is_looking_at( v, ply ) ) and green or red
			end
			halo.Add( { v }, color )
		else
			--  draw choosen target
			local t = math.abs( math.sin( CurTime() * 10 ) ) * 2
			halo.Add( { v }, v == choose_target and choose_target_color or target_color, 2 + t, 2 + t )
		end
	end
end )

--  footstep sounds
hook.Add( "PlayerFootstep", "guthscp173:sound", function( ply )
	if not guthscp173.is_scp_173( ply ) then return end

	--  play sound
	if not guthscp.sound.get_played_sound( ply, guthscp.configs.guthscp173.sound_moved ) then
		guthscp.sound.play( ply, guthscp.configs.guthscp173.sound_moved, 400, true, 1 )
	end

	--  stop sound after some time (reset the timer each time it walks)
	timer.Create( "guthscp173:footstep_sound" .. ( ply:AccountID() or ply:EntIndex() ), .35, 1, function()
		guthscp.sound.stop( ply, guthscp.configs.guthscp173.sound_moved )
	end )
	return true
end )

--  preview model 
local preview_model = ClientsideModel( "models/player/scp/173/scp.mdl" )
preview_model:SetMaterial( "debug/debugwireframe" )
preview_model:SetNoDraw( true )

hook.Add( "PostDrawOpaqueRenderables", "guthscp173:new_pos", function()
	local ply = LocalPlayer()

	local swep = ply:GetActiveWeapon()
	if not IsValid( swep ) or not ( swep:GetClass() == "guthscp_173" ) then return end
	if guthscp.configs.guthscp173.disable_teleport then return end
	if not swep.ShowDestinationHUD then return end

	local tr = ply:GetEyeTrace()
	if ( tr.Entity:IsPlayer() or tr.Entity:IsNPC() or tr.Entity:IsNextBot() ) and not next_position then return end

	--	color
	local pos, ang = next_position or tr.HitPos, Angle( 0, ply:GetAngles().y, 0 )
	if ply:GetPos():DistToSqr( pos ) > guthscp.configs.guthscp173.distance_unit_sqr or not guthscp.world.is_ground( pos ) then 
		render.SetColorModulation( .75, 0, 0 )
	else
		render.SetColorModulation( 0, .75, 0 )
	end

	--	alpha
	render.SetBlend( .1 )

	--	setup model
	preview_model:SetRenderOrigin( next_position or pos )
	preview_model:SetRenderAngles( ang )
	preview_model:SetModel( ply:GetModel() )

	--  draw model
	preview_model:DrawModel()
end )

--  replacement model: allow to update the looking angle only when not looked at
local replace_model = ClientsideModel( "models/player/scp/173/scp.mdl" )
replace_model:SetNoDraw( true )

hook.Add( "PrePlayerDraw", "guthscp173:eye_angle", function( ply )
	if not guthscp173.is_scp_173( ply ) then return end

	--  force a specific angle
	local angles = ply:GetNWAngle( "guthscp173:eye_angles", ply:EyeAngles() )
	angles.p = 0

	--  setup model
	replace_model:SetRenderOrigin( ply:GetPos() )
	replace_model:SetRenderAngles( angles )
	replace_model:SetModel( ply:GetModel() )
	replace_model:SetupBones()  --  allow to draw the model multiple times

	--  draw model
	replace_model:DrawModel()

	return true
end )