# Scarlet

A Quake mod for adding bots, blood, guts, and gore to the game.  Designed for the multiplayer enthusiast, sate your bloodlust w/ heart-pumping multiplayer games on demand.

[Website](https://whipowill.github.io/quake/) | [YouTube](https://www.youtube.com/@wscarlet)

[![](https://i.imgur.com/4o2EPCa.png)](https://rumble.com/user/whipowill24)

## Features

Every feature in this mod is optional and configurable.

### Base Features

- **Multiplayer Bots** - add robot players to deathmatch, teamplay, and coop games
- **Blood & Gore** - bathe in the blood of your enemies w/ scalable gore setting
- **Copper Tweaks** - all the vanilla improvements from [Copper](http://lunaran.com/copper/) mod (v1.20)
- **Perfect Balance** - find the perfect balance w/ configurable weapons
- **Item Resupply** - force items to respawn in singleplayer and coop games
- **Name Tags** - see other player names Halo-style when aiming at them
- **Foot Steps** - hear your boots touch the ground as you stalk your prey
- **Score Keeper** - make teamplay games combine scores to achieve fraglimit
- **Death Timeout** - when you die you have to sit out until timeout is over
- **Persistent Corpses** - player corpses stick around for a bit before disappearing
- **No Autoswitch** - picking up new weapons won't autoswitch anymore
- **Visible Weapons** - force weapons to drop visibly outside the backpack
- **Hitscan Nailguns** - make nailguns use hitscan Q2-style instead of projectiles
- **Melee Attacks** - perform a melee attack w/out switching weapons
- **Hand Grenades** - toss a hand grenade w/out switching weapons
- **Custom Loadouts** - play Rockets only, Shotguns only, Chaingun only, Railgun only

### Experimental Features

- **Glory Kills** - melee attacks and killstreaks grant health and armor rewards
- **Killing Spree** - game announces when you're on a killstreak and when it ends
- **Highlander Games** - higher the killstreak, the more rewards for the one who takes your head!
- **Random Powerups** - every kill has a chance to drop a random powerup

## Changelog

- May 2023 - ``v1.3.x``
    - Added new shards feature on kills
    - Added new killstreak feature
    - Weapons will switch to best on empty ammo
    - Weapons now visibly drop outside the backpack
    - Added custom weapon loadouts feature
    - Weapons kick can be customized
    - Nail speed over 2000 becomes hitscan
    - Add melee attack and grenade toss
    - Weapons crates now customizable
    - Fixed old bug where bots shoot ground
    - Taught bots how to use grenades
    - Respawn timer forces timeout
    - Player corpses stick around for a bit
- April 2023 - ``v1.2.x``
    - Gore system overhauled and is now scalable
    - Added option to disable weapon autoswitch
    - Weapon damage now configurable
    - Weapon bullets-per-shell now configurable
    - Weapon rate of fire now configurable
    - Weapon spread now configurable
    - Weapon projectile speed now configurable
    - Random bots will now be closer to ``skill``
    - Thunderbolt range now extended to infinite
    - Thunderbolt can now have a rate of fire
    - Upgraded to Copper v1.20
- August 2022 - ``v1.1.x``
    - Bots now choose from over 500 random names
    - Bots now know if they are losing and become depressed
    - Team bots now report when they pickup important items
    - Bots can now teleport to your location in coop
    - Added nametags, footsteps, and gore
- July 2022 - ``v1.0.x``
    - Merged FrikBot w/ Copper v1.19
    - Bots ``skill`` now scales linearly from ``0`` to ``3``
    - Bots can now be spawned w/ random ``skill`` levels
    - Bots no longer crowd together in team games
    - Bots no longer spam teleporters repeatedly
    - Bots now wear proper team color in coop games
    - Bots now recover from fool's errand more quickly
    - Added item respawn for singleplayer and coop

## Install

- Find your Quake install directory
- Download this [zipfile](https://github.com/whipowill/quake-mod-scarlet/archive/master.zip) and unzip to ``C:/path/to/quake/scarlet/``
- Make sure your ``C:/path/to/quake/id1/maps/`` folder has all your map files
- Make sure your ``C:/path/to/quake/id1/maps/`` folder has all your [waypoint](https://github.com/whipowill/quake-mod-frikbot-waypoints) files
- Run the game w/ ``-game scarlet -particles 99999 -listen 16 -condebug``

See my other [repository](https://github.com/whipowill/quake-dir) where I've uploaded my Quake directory, which includes all the best multiplayer maps and waypoint files to use w/ Scarlet.  The reason I created this mod is so I can customize the game to my tastes, and this [file](https://github.com/whipowill/quake-dir/blob/master/scarlet/settings/custom.cfg) is where I make it happen.

## Options

Control the following features using cvars in your ``autoexec.cfg`` file or via console:

### Misc Settings

- ``scarlet_dialogue``- enable random comments from bots in the game (``0`` or ``1``, default is ``1``)
- ``scarlet_footsteps``- enable footstep sounds for players (``0`` or ``1``, default is ``1``)
- ``scarlet_nametags`` - display player names on screen when aiming at them (``0`` or ``1``, default is ``0``)
- ``scarlet_respawn`` - seconds to wait before bots respawn (default is ``5``)
- ``scarlet_resupply`` - force items to respawn on singleplayer and coop (``0`` or ``1``, default is ``1``)
- ``scarlet_teamscores`` - combine players' scores (if ``teamplay 1``) to achieve fraglimit (``0`` or ``1``, default is ``1``)
- ``scarlet_autoswitch`` - set if the game will autoswitch weapons (``0`` or ``1``, default is ``1``)
- ``scarlet_visible`` - enable weapons drop outside of backpack (``0`` or ``1``, default is ``0``)
- ``scarlet_limited`` - remove Shotgun and Nailgun from the game (``0`` or ``1``, default is ``0``)

### Shard Settings

- ``scarlet_shards`` - enable health/armor shards on kills (``0`` or ``1``, default is ``0``)
- ``scarlet_shards_powerups`` - include powerups in shards dice rolls (``0`` or ``1``, default is ``1``)
- ``scarlet_shards_multiplier`` - how many shards to drop per killstreak (default is ``20``)
- ``scarlet_shards_chance`` - chances that each shard will actually drop (default is ``.4``)
- ``scarlet_shards_armor`` - amount of armor gained per shard (default is ``2``)
- ``scarlet_shards_health`` - amount of health gained per shard (default is ``2``)
- ``scarlet_shards_expire`` - seconds until all shards have disappeared (default is ``15``)

### Gore Settings

- ``scarlet_gore`` - multiplier for bleed effects (default is ``3``)
- ``scarlet_gore_chance_bullets`` - how likely will a bullet cause bleeding (default is ``.3``)
- ``scarlet_gore_multiplier_bullets`` - how many drops of blood per bullet (default is ``1``)
- ``scarlet_gore_chance_nails`` - how likely will a nail cause bleeding (default is ``.6``)
- ``scarlet_gore_multiplier_nails`` - how many drops of blood per nail (default is ``1``)
- ``scarlet_gore_chance_rockets`` - how likely will a rocket cause bleeding (default is ``.8``)
- ``scarlet_gore_multiplier_rockets`` - how many drops of blood per rocket (default is ``12``)
- ``scarlet_gore_chance_cells`` - how likely will lightning cause bleeding (default is ``.6``)
- ``scarlet_gore_multiplier_cells`` - how many drops of blood per lightning (default is ``6``)
- ``scarlet_gore_limit_shot`` - roll chance to bleed for the entire shot (``0`` or ``1``, default is ``0``)
- ``scarlet_gore_limit_drop`` - roll chance to bleed for each individual blood drop (``0`` or ``1``, default is ``1``)
- ``scarlet_football`` - make enemy heads kickable like a football (``0`` or ``1``, default is ``1``)

### Weapon Settings

- ``scarlet_dmg_axe`` - set the damage done by axes (default is ``24``)
- ``scarlet_bullets_in_shell_sg`` - set # bullets in a shell from a Shotgun (default is ``6``)
- ``scarlet_bullets_in_shell_ssg`` - set # bullets in 2 shells from a Super Shotgun (default is ``14``)
- ``scarlet_dmg_bullets`` - set the damage done by bullets (default is ``4``)
- ``scarlet_dmg_nails`` - set the damage done by nails (default is ``9``)
- ``scarlet_dmg_rockets`` - set the damage done by rockets (default is ``120``)
- ``scarlet_dmg_cells`` - set the damage done by lightning (default is ``30``)
- ``scarlet_dec_shells`` - set the ammo consumption of bullets (default is ``1``)
- ``scarlet_dec_nails`` - set the ammo consumption of nails (default is ``1``)
- ``scarlet_dec_rockets`` - set the ammo consumption of rockets (default is ``1``)
- ``scarlet_dec_cells`` - set the ammo consumption of cells (default is ``1``)
- ``scarlet_max_shells`` - set the max amount of bullets (default is ``100``)
- ``scarlet_max_nails`` - set the max amount of nails (default is ``200``)
- ``scarlet_max_rockets`` - set the max amount of rockets (default is ``100``)
- ``scarlet_max_cells`` - set the max amount of cells (default is ``100``)
- ``scarlet_shells_big`` - set the amount of shells in a big crate (default is ``40``)
- ``scarlet_shells_small`` - set the amount of shell in a small crate (default is ``20``)
- ``scarlet_nails_big`` - set the amount of nails in a big crate (default is ``50``)
- ``scarlet_nails_small`` - set the amount of nails in a small crate (default is ``25``)
- ``scarlet_rockets_big`` - set the amount of rockets in a big crate (default is ``8``)
- ``scarlet_rockets_small`` - set the amount of rockets in a small crate (default is ``4``)
- ``scarlet_cells_big`` - set the amount of cells in a big crate (default is ``12``)
- ``scarlet_cells_small`` - set the amount of cells in a small crate (default is ``6``)
- ``scarlet_rof_axe`` - set axe rate of fire delay in seconds (default is ``.49``)
- ``scarlet_rof_sg`` - set Shotgun rate of fire delay in seconds (default is ``.5``)
- ``scarlet_rof_ssg`` - set Super Shotgun rate of fire delay in seconds (default is ``.7``)
- ``scarlet_rof_ng`` - set Nailgun rate of fire delay in seconds (default is ``.095``)
- ``scarlet_rof_sng`` - set Perforator rate of fire delay in seconds (default is ``.095``)
- ``scarlet_rof_rl`` - set Rocket Launcher rate of fire delay in seconds (default is ``.8``)
- ``scarlet_rof_gl`` - set Grenade Launcher rate of fire delay in seconds (default is ``.6``)
- ``scarlet_rof_tb`` - set Thunderbolt rate of fire delay in seconds (default is ``0``)
- ``scarlet_spr_sg`` - set spread of bullets from Shotgun (default is ``4``)
- ``scarlet_spr_ssg`` - set spread of bullets from Super Shotgun (default is ``14``)
- ``scarlet_spr_ng`` - set spread of bullets from Nailgun (default is ``0``)
- ``scarlet_spr_sng`` - set spread of nail from Perforator (default is ``2``)
- ``scarlet_spd_ng`` - set speed of nails from Nailgun (default is ``1996``, ``2000+`` becomes hitscan)
- ``scarlet_spd_sng`` - set speed of nails from Perforator (default is ``1020``, ``2000+`` becomes hitscan)
- ``scarlet_kick_sg`` - set weapon kick for Shotgun (default is ``2``)
- ``scarlet_kick_ssg`` - set weapon kick for Super Shotgun (default is ``4``)
- ``scarlet_kick_ng`` - set weapon kick for Nailgun (default is ``2``)
- ``scarlet_kick_sng`` - set weapon kick for Perforator (default is ``2``)
- ``scarlet_kick_gl`` - set weapon kick for Grenade Launcher (default is ``2``)
- ``scarlet_kick_rl`` - set weapon kick for Rocket Launcher (default is ``2``)
- ``scarlet_kick_tb`` - set weapon kick for Thunderbolt (default is ``2``)

### Loadout Settings

- ``weapons`` - replace all weapons and ammo in the game (``1`` thru ``8`` for each weapon, default is ``0``)

### Melee & Grenades Settings

- ``scarlet_melee`` - allow melee attack (``0`` or ``1``, default is ``0``)
- ``scarlet_grenades`` - allow grenade toss (``0`` or ``1``, default is ``0``)
- ``scarlet_grenades_max`` - number of grenades that can be thrown (default is ``4``)
- ``scarlet_grenades_cooldown`` - seconds to wait before throwing again (default is ``10``)
- ``scarlet_grenades_fuse`` - seconds before grenade will explode (default is ``1``)
- ``scarlet_rof_hg`` - set Hand Grenade rate of fire delay in seconds (default is ``.6``)

## Usage

Utilize melee and grenade abilities by binding keys:

- ``impulse 120`` - melee attack
- ``impulse 121`` - grenade toss

Control bots via these console commands:

- ``skill`` - set the bot skill level (``0`` to ``3``)
- ``teamplay`` - turn on teamplay mode (``0`` or ``1``)
- ``deathmatch`` - turn on deathmatch mode (``0`` or ``1``)
- ``coop`` - turn on coop mode (``0`` or ``1``)
- ``impulse 100`` - add a bot to the game
- ``impulse 101`` - add a bot to the other team
- ``impulse 102`` - remove most recently added bot
- ``impulse 103`` - spectate other players
- ``impulse 104`` - enter dev mode for editing waypoints
- ``impulse 110`` - add a bot to the game of random skill level (up to ``skill``)
- ``impulse 111`` - add a bot to the other team of random skill level (up to ``skill``)
- ``impulse 113`` - teleport bots to your location in coop (only once per minute)

Reference the included ``instructions.html`` file from FrikaC for detailed information about the bots.

## Credits

- Original Copper mod by [Lunaran](http://lunaran.com/copper/)
- Original FrikBot mod by [FrikaC](https://www.moddb.com/mods/frikbot-x), Igor9, and JLaw
- Original waypoint files by [LightningHunter](https://www.celephais.net/board/view_thread.php?id=60404)
- Original nametag code by [BenVanCitters](https://gist.github.com/BenVanCitters/a157f58e906bf00adc39a484cbcee12f)
- Original corpse gibbing code by [Kryten](https://www.insideqc.com/qctut/qctut-33.shtml)
- Original head kicking code by [Ivana](http://www.insideqc.com/qctut/lesson-52.shtml)
- Original enemy bleeding code by [Maniac](https://www.insideqc.com/qctut/qctut-47.shtml)
- Original footsteps code by [Seven](https://www.quakewiki.net/quake-1/mods/footsteps-pack/)
- Original models provided by [Quoth](https://www.quaddicted.com/webarchive/kell.quaddicted.com/quoth/quoth2.html)

## External Links

- [Slipseer](https://www.slipseer.com/index.php) - where all the cool Quake kids hangout
- [Intro to QuakeC](https://codedocs.org/what-is/quakec) - nice intro to what QuakeC is and it's history
- [FTEQCC](https://fte.triptohell.info/downloads) - the QuakeC compiler I used to compile this code
- [FTEQCC Docs](https://fte.triptohell.info/moodles/fteqcc/README.html) - the difficult to find docs about FTEQCC
- [QuakeC Manual](http://www.cataboligne.org/extra/qcmanual.html#Names) - helpful list of available functions
- [QuakeC Tutorials](https://quakewiki.org/wiki/QuakeC_tutorials) - a list of tutorials for modding QuakeC
- [Level Book Design](https://book.leveldesignbook.com/appendix/resources/quake) - some modding instructions from a slick website
- [Quake Bot Archive](https://github.com/Jason2Brownlee/QuakeBotArchive) - an archive of all Quake bot versions w/ a little history
- [FrikBot Waypoint Files](https://github.com/whipowill/quake-mod-frikbot-waypoints) - an archive of all the bot waypoints files
- [Tome of Preach](https://tomeofpreach.wordpress.com/about/) - not using anything from here but might someday