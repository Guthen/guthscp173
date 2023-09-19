local MODULE = {
	name = "SCP-173",
	author = "Guthen",
	version = "2.0.0",
	description = [[Be SCP-173 and snap the necks of people!]],
	icon = "icon16/eye.png",
	version_url = "https://raw.githubusercontent.com/Guthen/guthscp173/update-to-guthscpbase-remaster/lua/guthscp/modules/guthscp173/main.lua",
	dependencies = {
		base = "2.0.0",
	},
	requires = {
		["shared.lua"] = guthscp.REALMS.SHARED,
		["server.lua"] = guthscp.REALMS.SERVER,
		["client.lua"] = guthscp.REALMS.CLIENT,
	},
}

MODULE.menu = {
	--  config
	config = {
		form = {
			--  general
			"General",
			{
				type = "Number",
				name = "Keycard Level",
				id = "keycard_level",
				desc = "Compatibility with my keycard system. Set a keycard level to SCP-173's swep",
				default = 5,
				min = 0,
				max = function( self, numwang )
					if self:is_disabled() then return 0 end
					
					return guthscp.modules.guthscpkeycard.max_keycard_level
				end,
				is_disabled = function( self, numwang )
					return guthscp.modules.guthscpkeycard == nil
				end,
			},
			{
				type = "Bool",
				name = "Disable Jump",
				id = "disable_jump",
				desc = "Should SCP-173 be able to jump?",
				default = true,
			},
			{
				type = "Bool",
				name = "Disable Directional Movement",
				id = "disable_directional_movement",
				desc = "Should SCP-173 be able to move around (forward, right, etc.)?",
				default = false,
			},
			{
				type = "Bool",
				name = "Disable Teleport",
				id = "disable_teleport",
				desc = "If checked, teleporting system implemented in the SWEP is disabled, consider uncheck 'Disable Directional Movement' else it will be impossible to move",
				default = false,
			},
			{
				type = "Bool",
				name = "Safe Teleport",
				id = "safe_teleport",
				desc = "If enabled, do an extra check before teleporting SCP-173 to ensure a safe placement. This mostly avoids teleporting in walls but can have side effects such as preventing to climb stairs and slopes. Consider disabling 'Disable Directional Movement' as a work-around",
				default = true,
			},
			{
				type = "Bool",
				name = "Immortal",
				id = "immortal",
				desc = "If checked, SCP-173 can't take damage",
				default = true,
			},
			{
				type = "Bool",
				name = "NPC Support",
				id = "npc_support",
				desc = "If checked, NPCs will be able to blink and freeze SCP-173",
				default = false,
			},
			--  weapon
			"Weapon",
			{
				type = "Number",
				name = "Distance Unit",
				id = "distance_unit",
				desc = "Maximum distance where SCP-173 can moves and kills his targets. 1 meter ~= 40 unit",
				default = 10 * 40, --  10 meter
			},
			{
				type = "Number",
				name = "Attack Hull Size",
				id = "attack_hull_size",
				desc = "Size of tolerance for targeting in units. The higher the number, the easier it is to aim, but the less precise it is",
				default = 5,
			},
			{
				type = "Number",
				name = "Kill Cooldown",
				id = "kill_cooldown",
				desc = "Cooldown between kill requests (left click)",
				default = 0.5,
				decimals = 2
			},
			{
				type = "Number",
				name = "Break Cooldown",
				id = "break_cooldown",
				desc = "Cooldown between entities breaks (left click)",
				default = 0.75,
				decimals = 2
			},
			{
				type = "Number",
				name = "Teleport Cooldown",
				id = "teleport_cooldown",
				desc = "Cooldown between teleportation requests (right click)",
				default = 0.33,
				decimals = 2
			},
			--  entity breaking
			"Entity Breaking",
			{
				type = "Bool",
				name = "Breaking Enabled",
				id = "breaking_enabled",
				desc = "If checked, SCP-173 can break doors and entities by left clicking on them",
				default = false,
			},
			{
				type = "Number",
				name = "Break Distance Unit",
				id = "break_distance_unit",
				desc = "Maximum distance where SCP-173 can breaks entities. Must be lower than 'Distance Unit' variable. 1 meter ~= 40 unit",
				default = 100,
			},
			{
				type = "Number",
				name = "Break Force Scale",
				id = "break_force_scale",
				desc = "Scale the breaking velocity force",
				default = .2,
				decimals = 2,
			},
			{
				type = "Number",
				name = "Break Hit Count",
				id = "break_hit_count",
				desc = "Number of hits to finally break the entities",
				default = 3,
				decimals = 0,
			},
			--  blink
			"Blink",
			{
				type = "Number",
				name = "Maximum Count",
				id = "blink_maximum_count",
				desc = "Maximum blink count used by the internal counter",
				default = 10,
			},
			{
				type = "Number",
				name = "Update Timer",
				id = "blink_update_timer",
				desc = "In seconds, the interval of time took to update the blink system. Each time, it decreases the blink counter by 1",
				default = .5,
				decimals = 2,
			},
			{
				type = "Number",
				name = "Distance Unit",
				id = "blink_distance_unit",
				desc = "Maximum distance from a SCP-173 instance where you can blink (similar to SCP:SL's system). 0 to disable the distance condition. 1024 is a good value.",
				default = 1024,
			},
			{
				type = "Bool",
				name = "Realistic Blink",
				id = "realistic_blink",
				desc = "If checked, changes the blink system to a realistic mode where every player have their own blink counter. Otherwise, it opts for an arcade system like SCP:SL where every player blink at the same time",
				default = true,
			},
			{
				type = "Bool",
				name = "Need SCP-173",
				id = "blink_need_scp_173",
				desc = "If checked, the blink system will work only if at least one SCP-173 is on the server.",
				default = true,
			},
			--  sounds
			"Sounds",
			{
				type = "String",
				name = "Button Pressed",
				id = "sound_button_pressed",
				desc = "Sound played when SCP-173 press a button (e.g.: open a door)",
				default = "guthen_scp/173/dooropen173.ogg",
			},
			{
				type = "String",
				name = "Moved",
				id = "sound_moved",
				desc = "Sound played when SCP-173 moves (i.e. directional movement using keyboard)",
				default = "guthen_scp/173/stonedrag.ogg",
			},
			{
				type = "String[]",
				name = "Snapped Neck",
				id = "sounds_snapped_neck",
				desc = "Sound randomly played when SCP-173 snap the neck of someone (i.e. killing someone)",
				default = {
					"guthen_scp/173/necksnap1.ogg",
					"guthen_scp/173/necksnap2.ogg",
					"guthen_scp/173/necksnap3.ogg",
				},
			},
			{
				type = "String[]",
				name = "Teleported",
				id = "sounds_teleported",
				desc = "Sound randomly played when SCP-173 teleports",
				default = {
					"guthen_scp/173/rattle1.ogg",
					"guthen_scp/173/rattle2.ogg",
					"guthen_scp/173/rattle3.ogg",
				},
			},
			guthscp.config.create_apply_button(),
			guthscp.config.create_reset_button(),
		},
		parse = function( config )
			if SERVER then
				--  regenerate the blink counter if switched from arcade to realistic mode
				if config.realistic_blink and not guthscp.configs.guthscp173.realistic_blink then
					for i, v in ipairs( player.GetAll() ) do
						if guthscp.is_scp and guthscp.is_scp( v ) then continue end  --  don't count on SCPs
						guthscp.modules.guthscp173.set_blink_counter( v, math.random( guthscp.configs.guthscp173.blink_maximum_count ) )
					end
				end

				--  ajust blink update timer
				timer.Adjust( "guthscp173:blink", config.blink_update_timer )
			end

			config.distance_unit_sqr = config.distance_unit ^ 2
		end,
	},
	--  details
	details = {
		{
			text = "CC-BY-SA",
			icon = "icon16/page_white_key.png",
		},
		"Wiki",
		{
			text = "Read Me",
			icon = "icon16/information.png",
			url = "https://github.com/Guthen/guthscp173/blob/master/README.md",
		},
		"Social",
		{
			text = "Github",
			icon = "guthscp/icons/github.png",
			url = "https://github.com/Guthen/guthscp173",
		},
		{
			text = "Steam",
			icon = "guthscp/icons/steam.png",
			url = "https://steamcommunity.com/sharedfiles/filedetails/?id=1785073622"
		},
		{
			text = "Discord",
			icon = "guthscp/icons/discord.png",
			url = "https://discord.gg/Yh5TWvPwhx",
		},
		{
			text = "Ko-fi",
			icon = "guthscp/icons/kofi.png",
			url = "https://ko-fi.com/vyrkx",
		},
	},
}

function MODULE:init()
	--  porting old config file 
	self:port_old_config_file( "guthscpbase/vkxscp173.json" )
end

guthscp.module.hot_reload( "guthscp173" )
return MODULE
