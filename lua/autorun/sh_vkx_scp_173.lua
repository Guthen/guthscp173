if not GuthSCP or not GuthSCP.Config then
    error( "[VKX SCP 173] '[SCP] Guthen's Addons Base' (https://steamcommunity.com/sharedfiles/filedetails/?id=2139692777) is not installed on the server, the addon won't work as intended, please install the base addon." )
    return
end

--[[ function GuthSCP.canHitTarget( ply, target )
    local tr = util.TraceLine( {
        start = ply:GetPos() + ply:GetViewOffsetDucked() * 1.5, 
        endpos = target:GetPos() + target:GetViewOffsetDucked() * 1.5,
        filter = { ply },
    } )

    return tr.Entity == target
end ]]

function GuthSCP.isGround( pos )
    return not util.TraceLine( {
        collisiongroup = COLLISION_GROUP_WORLD,
        start = pos,
        endpos = pos - Vector( 0, 0, 3 ),
    } ).HitWorld
end

function GuthSCP.isSCP173( ply, _team )
    if not IsValid( ply ) then return end
    if GuthSCP.getTeamKeyname( _team or ply:Team() ) == GuthSCP.Config.vkxscp173.team then return true end

    return ply:HasWeapon( "vkx_scp_173" )
end

function GuthSCP.isSCP173Looked( ply )
    return ply:GetNWBool( "vkxscp173:looked", false )
end

function GuthSCP.isLookingAt( ply, ent )
    if not IsValid( ply ) then return false end

    local pos = ent:GetPos()
    local min, max = ent:GetModelBounds()
    local tall = Vector( 0, 0, max.z - min.z )

    local vision_range = math.cos( math.rad( ( ply:GetFOV() + 25 ) / 2 ) )

    local dot = ply:GetAimVector():Dot( ( pos - ply:GetPos() ):GetNormal() )
    return dot > 0 and dot > vision_range and ( ply:IsLineOfSightClear( pos ) or ply:IsLineOfSightClear( pos + tall ) )
end

function GuthSCP.isBlinking( ply )
    if not IsValid( ply ) then return false end
    return ply:GetNWBool( "vkxscp173:blink_counter", 0 ) == 0
end

function GuthSCP.setBlinkCounter( ply, count )
    ply:SetNWInt( "vkxscp173:blink_counter", count )
end

function GuthSCP.getBlinkCounter( ply )
    local blink_counter = ply:GetNWInt( "vkxscp173:blink_counter", nil )
    if not blink_counter then 
        GuthSCP.setBlinkCounter( math.random( GuthSCP.Config.vkxscp173.blink_maximum_count ) )
        return GuthSCP.getBlinkCounter()
    end
    return blink_counter
end


hook.Add( "SetupMove", "vkxscp173:no_move", function( ply, mv, cmd )
    if not GuthSCP.isSCP173( ply ) then return end
    if ply:GetMoveType() == MOVETYPE_NOCLIP then return end --  allow noclip

    local looked = GuthSCP.isSCP173Looked( ply )

    --  disable jump
    if GuthSCP.Config.vkxscp173.disable_jump or looked then
        mv:SetButtons( bit.band( mv:GetButtons(), bit.bnot( IN_JUMP ) ) )
    end

    --  disable directional movement
    if GuthSCP.Config.vkxscp173.disable_directional_movement or looked then
        mv:SetSideSpeed( 0 )
        mv:SetForwardSpeed( 0 )
    end
end )

--  config
hook.Add( "guthscpbase:config", "vkxscp173", function()

    --  > Configuration
    GuthSCP.addConfig( "vkxscp173", {
        label = "SCP-173",
        icon = "icon16/user_red.png",
        elements = {
            {
                type = "Form",
                name = "Configuration",
                elements = {
                    {
                        type = "Category",
                        name = "General",
                    },
                    GuthSCP.createTeamConfigElement( {
                        name = "SCP-173 Team",
                        id = "team",
                        default = "TEAM_SCP173",
                    } ),
                    {
                        type = "NumWang",
                        name = "Distance Unit",
                        id = "distance_unit",
                        desc = "Maximum distance where SCP-173 can moves and kills his targets. 1 meter ~= 40 unit",
                        default = 10 * 40, --  10 meter
                    },
                    GuthSCP.maxKeycardLevel and {
                        type = "NumWang",
                        name = "Keycard Level",
                        id = "keycard_level",
                        desc = "Compatibility with my keycard system. Set a keycard level to SCP-173's swep",
                        default = 5,
                        min = 0,
                        max = GuthSCP.maxKeycardLevel,
                    },
                    {
                        type = "CheckBox",
                        name = "Disable Jump",
                        id = "disable_jump",
                        desc = "Should SCP-173 be able to jump?",
                        default = true,
                    },
                    {
                        type = "CheckBox",
                        name = "Disable Directional Movement",
                        id = "disable_directional_movement",
                        desc = "Should SCP-173 be able to move around (forward, right, etc.)?",
                        default = true,
                    },
                    {
                        type = "CheckBox",
                        name = "Disable Teleport",
                        id = "disable_teleport",
                        desc = "If checked, teleporting system implemented in the SWEP is disabled, consider uncheck 'Disable Directional Movement' else it will be impossible to move",
                        default = false,
                    },
                    {
                        type = "CheckBox",
                        name = "Immortal",
                        id = "immortal",
                        desc = "If checked, SCP-173 can't take damage",
                        default = true,
                    },
                    {
                        type = "Category",
                        name = "Entity Breaking",
                    },
                    {
                        type = "CheckBox",
                        name = "Breaking Enabled",
                        id = "breaking_enabled",
                        desc = "If checked, SCP-173 can break doors and entities by left clicking on them",
                        default = false,
                    },
                    {
                        type = "NumWang",
                        name = "Break Force Scale",
                        id = "break_force_scale",
                        desc = "Scale the breaking velocity force",
                        default = .2,
                        decimals = 2,
                    },
                    {
                        type = "NumWang",
                        name = "Break Hit Count",
                        id = "break_hit_count",
                        desc = "Number of hits to finally break the entities",
                        default = 3,
                        decimals = 0,
                    },
                    {
                        type = "Category",
                        name = "Blink",
                    },
                    {
                        type = "NumWang",
                        name = "Maximum Count",
                        id = "blink_maximum_count",
                        desc = "Maximum blink count used by the internal counter",
                        default = 10,
                    },
                    {
                        type = "NumWang",
                        name = "Update Timer",
                        id = "blink_update_timer",
                        desc = "In seconds, the interval of time took to update the blink system. Each time, it decreases the blink counter by 1",
                        default = .5,
                        decimals = 2,
                    },
                    {
                        type = "NumWang",
                        name = "Distance Unit",
                        id = "blink_distance_unit",
                        desc = "Maximum distance from a SCP-173 instance where you can blink (similar to SCP:SL's system). 0 to disable the distance condition. 1024 is a good value.",
                        default = 1024,
                    },
                    {
                        type = "CheckBox",
                        name = "Realistic Blink",
                        id = "realistic_blink",
                        desc = "If checked, changes the blink system to a realistic mode where every player have their own blink counter. Otherwise, it opts for an arcade system like SCP:SL where every player blink at the same time",
                        default = true,
                    },
                    {
                        type = "CheckBox",
                        name = "Need SCP-173",
                        id = "blink_need_scp_173",
                        desc = "If checked, the blink system will work only if at least one SCP-173 is on the server. Else, the blink system work everytime",
                        default = true,
                    },
                    {
                        type = "Category",
                        name = "Sounds",
                    },
                    {
                        type = "TextEntry",
                        name = "Button Pressed",
                        id = "sound_button_pressed",
                        desc = "Sound played when SCP-173 press a button (e.g.: open a door)",
                        default = "guthen_scp/173/dooropen173.ogg",
                    },
                    {
                        type = "TextEntry",
                        name = "Moved",
                        id = "sound_moved",
                        desc = "Sound played when SCP-173 moves (e.g.: using his keyboard)",
                        default = "guthen_scp/173/stonedrag.ogg",
                    },
                    {
                        type = "TextEntry[]",
                        name = "Snapped Neck",
                        id = "sounds_snapped_neck",
                        desc = "Sound randomly played when SCP-173 snap the neck of someone",
                        default = {
                            "guthen_scp/173/necksnap1.ogg",
                            "guthen_scp/173/necksnap2.ogg",
                            "guthen_scp/173/necksnap3.ogg",
                        },
                    },
                    {
                        type = "TextEntry[]",
                        name = "Teleported",
                        id = "sounds_teleported",
                        desc = "Sound randomly played when SCP-173 teleports",
                        default = {
                            "guthen_scp/173/rattle1.ogg",
                            "guthen_scp/173/rattle2.ogg",
                            "guthen_scp/173/rattle3.ogg",
                        },
                    },
                    {
                        type = "Button",
                        name = "Apply",
                        action = function( form, serialize_form )
                            GuthSCP.sendConfig( "vkxscp173", serialize_form )
                        end,
                    }
                }
            },
        },
        receive = function( form )
            GuthSCP.applyConfig( "vkxscp173", form, {
                network = true,
                save = true,
            } )
        end,
        parse = function( form )
            if SERVER then
                --  regenerate the blink counter if switched from arcade to realistic mode
                if form.realistic_blink and not GuthSCP.Config.vkxscp173.realistic_blink then
                    for i, v in ipairs( player.GetAll() ) do
                        if GuthSCP.isSCP and GuthSCP.isSCP( v ) then continue end  --  don't count on SCPs
                        GuthSCP.setBlinkCounter( v, math.random( GuthSCP.Config.vkxscp173.blink_maximum_count ) )
                    end
                end

                --  ajust blink update timer
                timer.Adjust( "vkxscp173:blink", form.blink_update_timer )
            end

            form.distance_unit_sqr = form.distance_unit ^ 2

            form.team = GuthSCP.parseTeamConfig( form.team )
        end,
    } )

end )