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
			{
				type = "Category",
				name = "General",
			},
			{
				type = "NumWang",
				name = "Distance Unit",
				id = "distance_unit",
				desc = "Maximum distance where SCP-173 can moves and kills his targets. 1 meter ~= 40 unit",
				default = 10 * 40, --  10 meter
			},
			{
				type = "NumWang",
				name = "Attack Hull Size",
				id = "attack_hull_size",
				desc = "Size of tolerance for targeting in units. The higher the number, the easier it is to aim, but the less precise it is",
				default = 5,
			},
			{
				type = "NumWang",
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
				type = "CheckBox",
				name = "Disable NPC",
				id = "disable_npc",
				desc = "If unchecked, NPCs will neither blink nor freeze 173 even though looking at him",
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
				name = "Break Distance Unit",
				id = "break_distance_unit",
				desc = "Maximum distance where SCP-173 can breaks entities. Must be lower than 'Distance Unit' variable. 1 meter ~= 40 unit",
				default = 3 * 40, --  3 meter
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
				desc = "If checked, the blink system will work only if at least one SCP-173 is on the server. Else, the blink system work everytime. Note that it WILL NOT work if 'Distance Unit' is greater than 0.",
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
			guthscp.config.create_apply_button(),
			guthscp.config.create_reset_button(),
		},
		parse = function( form )
			if SERVER then
				--  regenerate the blink counter if switched from arcade to realistic mode
				if form.realistic_blink and not guthscp.configs.guthscp173.realistic_blink then
					for i, v in ipairs( player.GetAll() ) do
						if guthscp.is_scp and guthscp.is_scp( v ) then continue end  --  don't count on SCPs
						guthscp.modules.guthscp173.set_blink_counter( v, math.random( guthscp.configs.guthscp173.blink_maximum_count ) )
					end
				end

				--  ajust blink update timer
				timer.Adjust( "guthscp173:blink", form.blink_update_timer )
			end

			form.distance_unit_sqr = form.distance_unit ^ 2
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
