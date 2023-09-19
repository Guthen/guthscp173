# [GuthSCP] SCP-173

## Steam Workshop
![Steam Views](https://img.shields.io/steam/views/3034740066?color=red&style=for-the-badge)
![Steam Downloads](https://img.shields.io/steam/downloads/3034740066?color=red&style=for-the-badge)
![Steam Favorites](https://img.shields.io/steam/favorites/3034740066?color=red&style=for-the-badge)

This addon is available on the Workshop [here](https://steamcommunity.com/sharedfiles/filedetails/?id=3034740066)!

## Features
Contains a SWEP, of class `guthscp_173`, designed for multiplayer:
+ **Left Mouse Button** to **kill players or NPCs** or **break the looking entity**
+ **Right Mouse Button** to **teleport** at designated location
+ **Reload** to toggle teleport destination preview
+ **Freezes** when a non-SCP player or NPCs look at him. In this state, **SCP-173 abilities** (kill and teleport) are **scheduled to be automatically executed** when he is no longer frozen
+ **Emits** a custom sound when interacting with something (doors, buttons..)
+ Can **break doors and props** with multiple left clicks
+ Configurable in-game with [[GuthSCP] Base](https://steamcommunity.com/sharedfiles/filedetails/?id=3034737316) (`guthscp_menu` in your console)
	+ **Movement** constraints: teleport, directional movement, jump
    + **Weapon** aim and cooldowns
	+ **Blink** system (refer below for compatible HUDs)
    + **Sound** paths
    + (optional) [[GuthSCP] Keycard](https://steamcommunity.com/sharedfiles/filedetails/?id=3034740776) custom access
    + *and more..*
+ (fun) Allow multiple SCP-173 instances
+ **Not gamemode-dependent** 
+ **Custom compatibility with:**
    + [[GuthSCP] Keycard](https://steamcommunity.com/sharedfiles/filedetails/?id=3034740776)

## Convars
+ `guthscp_173_blink <0 or 1>` (client): Enables the black blinking screen, it's only visual
+ `guthscp_173_halo <0 or 1>` (client): As SCP-173, show or not halos on players

## Compatible HUDs
+ [[SCP] HUD by Guthen](https://steamcommunity.com/sharedfiles/filedetails/?id=1613150311)
+ [Flat HUD](https://steamcommunity.com/sharedfiles/filedetails/?id=2293300406) (also by me)

## Known Issues
### "This addon doesn't work!"
Be sure to have installed [[GuthSCP] Base](https://steamcommunity.com/sharedfiles/filedetails/?id=3034737316) on your server. Verify that you can open the configuration menu with `guthscp_menu` in your game console.

Then, be sure that you did well configured the SCP Teams in the config menu (`guthscp_menu` in your game's console), a SCP Team won't trigger SCP-173 behaviour.

### "I can't hear the sounds!"
Be sure to have installed [Guthen SCP Content](https://steamcommunity.com/workshop/filedetails/?id=1673048305) on your client.

Otherwise, check the configured sounds paths in the configuration menu. 

### "NPCs don't freeze me (as 173)!"
You have to check the variable `NPC Support` in the configuration menu (again `guthscp_menu` in your game's console).

## Legal Terms
This addon is licensed under [Creative Commons Sharealike 3.0](https://creativecommons.org/licenses/by-sa/3.0/) and is based on [SCP-173](http://scp-wiki.wikidot.com/scp-173).

If you create something derived from this, please credit me (you can also tell me about what you've done).

***Enjoy !***
