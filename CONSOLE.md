# Console Reference

Everything in Scarlet is controlled by console variables (cvars) and a few impulse commands.

## How to use cvars

- **Try things live:** open the console (``~``) and type the cvar and a value, e.g. ``scarlet_gore 5``.  Most take effect within a second (the mod re-reads them once a second).
- **Make them permanent:** put ``set scarlet_gore 5`` lines in your ``autoexec.cfg`` (or any cfg you ``exec``).  The mod's own defaults live in ``default.cfg``; don't edit that, override it from your own cfg instead.
- **Set them before the map loads** if they affect level setup (``scarlet_music``, ``weapons``, ``scarlet_remove_weaker_weapons``, ``scarlet_singleplayer_resupply``, ``scarlet_item_ghosts``).  Changing these mid-game usually needs a ``map`` or ``restart`` to show up.
- **Defaults** listed below are what ``default.cfg`` sets.  If a cvar is missing from your config, QuakeC reads it as ``0``, so always load ``default.cfg`` (the mod does this for you) or set what you care about yourself.
- Cvars marked **(DM only)** do nothing in singleplayer or coop.
- Cvars marked **(SP/co-op only)** do nothing in deathmatch.

---

## Gameplay

| Cvar | Default | What it does |
|---|---|---|
| ``scarlet_singleplayer_resupply`` | ``1`` | **(SP/co-op only)** Forces items (powerups, etc.) to respawn in singleplayer and coop, where vanilla Quake never respawns them.  Deathmatch always respawns items. |
| ``scarlet_autoswitch`` | ``1`` | ``1`` switches to a weapon when you pick it up.  ``0`` keeps your current weapon (you still auto-switch if you run out of ammo). |
| ``scarlet_visible_weapons`` | ``0`` | ``1`` makes a dead player's weapon drop as a visible pickup on the floor instead of inside the backpack. |
| ``scarlet_remove_weaker_weapons`` | ``0`` | ``1`` removes the Shotgun and Nailgun from the game.  Players spawn with the Super Shotgun instead. |
| ``scarlet_corpses`` | ``0`` | ``1`` leaves player corpses on the map for a while (they can be gibbed) instead of vanishing immediately.  |
| ``scarlet_football`` | ``1`` | ``1`` lets you kick severed heads around like a football. |
| ``scarlet_item_ghosts`` | ``0`` | ``1`` leaves a faint see-through ghost of an item where it was picked up and flickers it back in before it respawns, so you can see what is coming back and when.  Without it the item just vanishes and reappears.  Also makes dropped items blink out. |
| ``scarlet_respawn`` | ``5`` | Seconds a dead player must wait before they are allowed to respawn (the "death timeout"). |

## Stats

| Cvar | Default | What it does |
|---|---|---|
| ``scarlet_assist_window`` | ``10`` | Seconds before a kill during which damaging the victim earns you an assist.  Teammate damage and the killer don't count.  ``0`` turns assists off. |
| ``scarlet_team_markers`` | ``1`` | In teamplay, the HUD mod draws a colored marker and name over each teammate's head, visible through walls.  Needs the HUD mod (``csprogs.dat``); does nothing without it. |
| ``scarlet_team_marker_scale`` | ``1`` | Size of the teammate marker and its name.  ``1`` is normal, ``2`` is double, ``0.5`` is half.  Needs ``scarlet_team_markers 1``. |
| ``scarlet_team_marker_names`` | ``1`` | ``1`` shows the teammate's name over their marker.  ``0`` shows just the marker.  Needs ``scarlet_team_markers 1``. |

## Audio

| Cvar | Default | What it does |
|---|---|---|
| ``scarlet_footsteps`` | ``1`` | Players make footstep sounds as they walk and run. |
| ``scarlet_music`` | ``0`` | ``1`` picks a random music track every time a map loads, replacing the map's own track.  ``0`` plays the map's normal music. |
| ``scarlet_music_min`` | ``2`` | Lowest track number the shuffle may pick. |
| ``scarlet_music_max`` | ``21`` | Highest track number the shuffle may pick. |

**Music setup:** QuakeC can't browse folders, so the shuffle picks a *track number* and the engine plays the matching file from ``music/``, e.g. track 7 plays ``music/track07.ogg`` (or ``.mp3``, if your engine supports it).  Name your files ``track02`` through ``trackNN``, then set ``scarlet_music_max`` to your highest number.  Quake's track 1 is the data track, so numbering starts at ``02``.  A missing number means silence on that map.  Bind a key to ``impulse 122`` to skip to another track whenever you like.  The shuffle is picked once per map load, not mid-level.

## Name Tags & Chat

| Cvar | Default | What it does |
|---|---|---|
| ``scarlet_nametags`` | ``0`` | Shows a player's name on screen when you aim at them (Halo-style).  Drawn by the HUD mod (``csprogs.dat``); does nothing without it. |
| ``scarlet_chat_guns`` | ``1`` | Chat/print notices about weapons (e.g. "no weapon", pickups).  ``0`` silences them. |
| ``scarlet_chat_ammo`` | ``1`` | Notices about ammo pickups.  ``0`` silences them. |
| ``scarlet_chat_armor`` | ``1`` | Notices about armor pickups.  ``0`` silences them. |
| ``scarlet_chat_backpacks`` | ``1`` | Notices about backpacks.  ``0`` silences them. |
| ``scarlet_chat_deaths`` | ``1`` | Death messages.  ``0`` off, ``1`` classic Quake messages, ``2`` generic alternate messages. |
| ``scarlet_chat_killstreaks`` | ``1`` | Killstreak announcements ("Killing Spree!").  ``0`` silences them (only matters if ``scarlet_killstreaks`` is on). |

Set all the ``scarlet_chat_*`` cvars to ``0`` for a quiet console in busy bot matches.

## Bots

| Cvar | Default | What it does |
|---|---|---|
| ``scarlet_dialogue`` | ``1`` | Bots occasionally say things (greetings, taunts, complaints when losing). |
| ``scarlet_singleplayer_monsters_density_easy`` | ``1`` | **(SP/co-op only)** How many monsters there are on Easy skill.  ``1`` is the map as built, ``0.75`` removes a quarter of them at random, ``1.5`` adds an extra monster next to half of them.  Monsters that trigger something when they die, triggered or teleported-in monsters, fish and bosses are never touched.  Extras can't be added past about 250 per map, and very big maps may hit the engine's entity limit.  Set it before the map loads. |
| ``scarlet_singleplayer_monsters_density_normal`` | ``1`` | **(SP/co-op only)** How many monsters there are on Normal skill.  ``1`` is the map as built, ``0.75`` removes a quarter of them at random, ``1.5`` adds an extra monster next to half of them.  Monsters that trigger something when they die, triggered or teleported-in monsters, fish and bosses are never touched.  Extras can't be added past about 250 per map, and very big maps may hit the engine's entity limit.  Set it before the map loads. |
| ``scarlet_singleplayer_monsters_density_hard`` | ``1`` | **(SP/co-op only)** How many monsters there are on Hard skill.  ``1`` is the map as built, ``0.75`` removes a quarter of them at random, ``1.5`` adds an extra monster next to half of them.  Monsters that trigger something when they die, triggered or teleported-in monsters, fish and bosses are never touched.  Extras can't be added past about 250 per map, and very big maps may hit the engine's entity limit.  Set it before the map loads. |
| ``scarlet_singleplayer_monsters_density_nightmare`` | ``1`` | **(SP/co-op only)** How many monsters there are on Nightmare skill.  ``1`` is the map as built, ``0.75`` removes a quarter of them at random, ``1.5`` adds an extra monster next to half of them.  Monsters that trigger something when they die, triggered or teleported-in monsters, fish and bosses are never touched.  Extras can't be added past about 250 per map, and very big maps may hit the engine's entity limit.  Set it before the map loads. |
| ``scarlet_singleplayer_monsters_drop_chance`` | ``0`` | **(SP/co-op only)** Chance (``0``-``1``) that a monster killed by a player (or a bot) drops one random powerup: Megahealth, Quad or Pent, equally likely.  Lasts ``scarlet_rewards_expire`` seconds.  ``0`` turns it off. |
| ``scarlet_singleplayer_monsters_speed_easy`` | ``1`` | **(SP/co-op only)** On easy skill, monsters that can see a player chase faster: ``1.5`` runs and animates 50% faster, and they start their first attack sooner after spotting you.  ``1`` is stock.  Also applies to monsters fighting your bots. |
| ``scarlet_singleplayer_monsters_speed_normal`` | ``1`` | **(SP/co-op only)** On normal skill, monsters that can see a player chase faster: ``1.5`` runs and animates 50% faster, and they start their first attack sooner after spotting you.  ``1`` is stock.  Also applies to monsters fighting your bots. |
| ``scarlet_singleplayer_monsters_speed_hard`` | ``1`` | **(SP/co-op only)** On hard skill, monsters that can see a player chase faster: ``1.5`` runs and animates 50% faster, and they start their first attack sooner after spotting you.  ``1`` is stock.  Also applies to monsters fighting your bots. |
| ``scarlet_singleplayer_monsters_speed_nightmare`` | ``1`` | **(SP/co-op only)** On nightmare skill, monsters that can see a player chase faster: ``1.5`` runs and animates 50% faster, and they start their first attack sooner after spotting you.  ``1`` is stock.  Also applies to monsters fighting your bots. |
| ``scarlet_singleplayer_monsters_damage_easy`` | ``1`` | **(SP/co-op only)** On easy skill, monsters hit players this many times harder.  ``1.5`` is 50% more damage.  Applies to every monster attack on a player (bots too), including projectiles and explosions.  Monsters hurting each other is unchanged. |
| ``scarlet_singleplayer_monsters_damage_normal`` | ``1`` | **(SP/co-op only)** On normal skill, monsters hit players this many times harder.  ``1.5`` is 50% more damage.  Applies to every monster attack on a player (bots too), including projectiles and explosions.  Monsters hurting each other is unchanged. |
| ``scarlet_singleplayer_monsters_damage_hard`` | ``1`` | **(SP/co-op only)** On hard skill, monsters hit players this many times harder.  ``1.5`` is 50% more damage.  Applies to every monster attack on a player (bots too), including projectiles and explosions.  Monsters hurting each other is unchanged. |
| ``scarlet_singleplayer_monsters_damage_nightmare`` | ``1`` | **(SP/co-op only)** On nightmare skill, monsters hit players this many times harder.  ``1.5`` is 50% more damage.  Applies to every monster attack on a player (bots too), including projectiles and explosions.  Monsters hurting each other is unchanged. |
| ``scarlet_singleplayer_keep_progress`` | ``0`` | **(SP/co-op only)** In co-op, when every player is dead the level normally restarts from scratch.  ``1`` stops that: you respawn at the start of the map after a short wait, the monsters you killed stay dead, and doors and items stay as you left them.  Needs ``coop 1`` (the ``singleplayer`` alias sets that). |
| ``scarlet_singleplayer_bots_range`` | ``1000`` | **(SP/co-op only)** Bots only go after monsters and items within this many units of a player, so they stay near you instead of running across the map to a far away Megahealth or monster.  ``0`` removes the limit. |
| ``scarlet_singleplayer_bots_follow_distance`` | ``128`` | **(SP/co-op only)** How far from the player (in units) a following bot stops.  Bigger means they hang back more.  A bot closer than 3/8 of this walks away to make room.  ``128`` is the original FrikBot value. |
| ``scarlet_singleplayer_bots_regroup_distance`` | ``1500`` | **(SP/co-op only)** Bots follow the nearest player and never shoot players.  A bot that falls this many units behind every player, and can't see any of them, teleports to the nearest one.  ``0`` turns the teleporting off.  Players can also bring everyone back with ``impulse 113``. |
| ``scarlet_bots_enemy_color`` | ``-1`` | In teamplay, the opposing team of bots (added with ``impulse 101`` or ``111``) always wears this color, so enemies are easy to spot.  Use the same numbers as the ``color`` command: ``0`` white, ``1`` brown, ``2`` light blue, ``3`` green, ``4`` red, ``5`` tan, ``6`` orange, ``7`` pink, ``8`` purple, ``9`` dusty rose, ``10`` dark sienna, ``11`` blue-green, ``12`` yellow, ``13`` blue.  ``-1`` turns it off.  If your own team already wears that color, the bots pick another.  Only affects bots added afterward. |
| ``scarlet_bots_team_jersey`` | ``1`` | In teamplay, bots wear their team color.  ``0`` lets each bot keep a unique shirt color while the pants still show the team. |
| ``scarlet_testing`` | ``0`` | Developer aid: bots say the topic name ("connect", "welcome") instead of a random quote so dialogue can be tested. |
| ``scarlet_priority_quad`` | ``1000`` | How badly bots want a Quad Damage.  Higher means they route to it sooner. |
| ``scarlet_priority_pent`` | ``1000`` | Same, for Pentagram of Protection. |
| ``scarlet_priority_ring`` | ``0`` | Same, for Ring of Shadows. |
| ``scarlet_priority_mega`` | ``1000`` | Same, for Megahealth. |
| ``scarlet_bot_edgefriction`` | ``1`` | Friction multiplier bots feel when their leading edge is over a dropoff.  ``2`` is stock Quake (bots brake hard at ledges and rarely fall); ``1`` removes the extra braking so they can fall off bridges like players do. |
| ``scarlet_bot_handicap`` | ``1`` | How much weaker a bot below skill 3 is.  A low skill bot reacts late to a new enemy, turns slower, aims with a wobble, leads its shots less and dodges fewer rockets.  ``1`` is the full effect, ``0`` makes every bot play like skill 3, and values between scale it.  Skill 3 is never held back.  See ``TRAILGEN.md`` for the numbers. |
| ``scarlet_bot_goal_distance`` | ``1500`` | How far away an item is worth half as much to a bot, in units.  A bot scores every item by how much it wants it, divided by one plus its distance over this number, so it goes for a good item close by before a slightly better one across the map.  ``0`` ignores distance (the bot goes for the best item anywhere).  Powerups worth 100 or more are always worth the trip. |
| ``scarlet_dev_autobots`` | ``0`` | Developer test: adds this many bots by itself a moment after the map starts, so a dedicated server can run a bot test with nobody connected. |
| ``scarlet_dev_botlog`` | ``0`` | Developer test: ``1`` prints each bot's position and goal once a second, every goal it reaches or gives up on, and the waypoint mode every 10 seconds (``mode 3`` is a loaded trail, ``mode 0`` is a map with no trail, where the bots stand still).  Also prints ``BOTSQUEEZE`` when a bot jammed against a wall steps sideways, ``BOTSTUCK`` and ``BOTTIMEOUT`` when a bot gives up on a target, ``BOTTELE`` for each teleport and ``BOTFALL`` for each drop of more than 80 units (``tdz`` is how far above the bot its next waypoint was, so a drop with ``tdz`` near 0 was an accident).  Needs ``developer 1``. |
| ``scarlet_dev_botgoal`` | ``0`` | Developer test: ``1`` floats a model over every bot showing its goal (the item's own model when it is after an item, a fireball for a waypoint, a head for a player, a rocket when it is fighting, a gib when it is running from a pentagram, a spike for no goal), and prints a bot's name and goal in the middle of your screen while you look straight at it. |
| ``scarlet_dev_wayfile`` | ``0`` | Developer test: ``1`` also loads the old ``maps/<map>.way`` waypoint file, only to compare it against a trail. |
| ``scarlet_powerup_icons`` | ``1`` | Float a small spinning quad or pentagram above anyone carrying one.  Needs an engine that supports the ``scale`` field (QSS, FTE, DarkPlaces); on others the icons show full size, so turn this off. |
| ``scarlet_powerup_icon_scale`` | ``0.4`` | Size of the floating icon. |
| ``scarlet_powerup_icon_height`` | ``42`` | How far above the player's origin the icon floats.  The top of the head is about ``32``. |

## Killstreaks & Rewards

| Cvar | Default | What it does |
|---|---|---|
| ``scarlet_killstreaks`` | ``0`` | Announces killing sprees (every 5 kills without dying) and when they end. |
| ``scarlet_rewards`` | ``0`` | **(DM only)** Dead players can drop powerup rewards (Megahealth, Quad, Pent) that anyone can grab. |
| ``scarlet_rewards_drop_chance`` | ``0.07`` | Chance (``0``-``1``) that any kill drops one powerup (Megahealth, Quad or Pent, equally likely).  Axe kills are 4x as likely. |
| ``scarlet_rewards_drop_streak`` | ``0.05`` | Extra chance added for every kill in the killstreak of the player who died, so killing someone on a hot streak is more likely to drop a powerup.  ``0`` ignores killstreaks. |
| ``scarlet_rewards_expire`` | ``30`` | Seconds until uncollected rewards vanish. |

## Recharge

Lets players regenerate after surviving a fight.

| Cvar | Default | What it does |
|---|---|---|
| ``scarlet_recharge`` | ``0`` | Enable recharge. |
| ``scarlet_recharge_cooldown`` | ``5`` | Seconds without taking damage before recharging begins. |
| ``scarlet_recharge_armor`` | ``10`` | Armor restored per second. |
| ``scarlet_recharge_health`` | ``0`` | Health restored per second. |

## Gore

Bleeding is rolled per hit: a **chance** decides if the hit bleeds at all, and a **multiplier** decides how many blood drops spawn.

| Cvar | Default | What it does |
|---|---|---|
| ``scarlet_gore`` | ``3`` | Master multiplier for all blood.  ``0`` turns gore off. |
| ``scarlet_gore_chance_bullets`` | ``0.3`` | Chance a bullet makes the target bleed. |
| ``scarlet_gore_multiplier_bullets`` | ``1`` | Blood drops per bullet. |
| ``scarlet_gore_chance_nails`` | ``0.6`` | Chance a nail makes the target bleed. |
| ``scarlet_gore_multiplier_nails`` | ``1`` | Blood drops per nail. |
| ``scarlet_gore_chance_rockets`` | ``0.8`` | Chance a rocket makes the target bleed. |
| ``scarlet_gore_multiplier_rockets`` | ``12`` | Blood drops per rocket. |
| ``scarlet_gore_chance_cells`` | ``0.6`` | Chance lightning makes the target bleed. |
| ``scarlet_gore_multiplier_cells`` | ``8`` | Blood drops per lightning hit. |
| ``scarlet_gore_chance_per_hit`` | ``0`` | ``1`` rolls the bleed chance once for each hit (every pellet, nail, rocket or axe swing counts as a hit).  If the roll fails, that hit makes no blood at all. |
| ``scarlet_gore_chance_per_drop`` | ``1`` | ``1`` rolls the bleed chance again for every individual blood drop in a hit, so each hit makes a smaller, scattered splatter.  With both this and ``_per_hit`` at ``0``, the chance is ignored and every hit makes the full splatter. |

## Weapons

Tune any weapon.  Names: ``sg`` Shotgun, ``ssg`` Super Shotgun, ``ng`` Nailgun, ``sng`` Perforator, ``gl`` Grenade Launcher, ``rl`` Rocket Launcher, ``tb`` Thunderbolt, ``hg`` Hand Grenade.

### Loadout

| Cvar | Default | What it does |
|---|---|---|
| ``weapons`` | ``0`` | Everyone gets only the axe plus one weapon, and only that weapon's ammo appears on the map.  ``0`` normal game, ``1`` axe only, ``2`` Shotgun, ``3`` Super Shotgun, ``4`` Nailgun, ``5`` Perforator, ``6`` Grenade Launcher, ``7`` Rocket Launcher, ``8`` Thunderbolt. |

### Damage

| Cvar | Default | Notes |
|---|---|---|
| ``scarlet_dmg_axe`` | ``24`` | |
| ``scarlet_dmg_bullets`` | ``4`` | Per bullet. |
| ``scarlet_dmg_nails`` | ``9`` | Per nail. |
| ``scarlet_dmg_rockets`` | ``120`` | Direct and splash. |
| ``scarlet_dmg_cells`` | ``30`` | Lightning. |
| ``scarlet_bullets_in_shell_sg`` | ``6`` | Pellets per Shotgun shot. |
| ``scarlet_bullets_in_shell_ssg`` | ``14`` | Pellets per Super Shotgun shot (2 shells). |

### Ammo use & capacity

| Cvar | Default | Notes |
|---|---|---|
| ``scarlet_dec_shells`` / ``_nails`` / ``_rockets`` / ``_cells`` | ``1`` | Ammo spent per shot. |
| ``scarlet_absorb_green`` | ``0.3`` | Share of each hit that green armor absorbs (0.3 is 30%). |
| ``scarlet_absorb_yellow`` | ``0.6`` | Share of each hit that yellow armor absorbs.  Keep it between green and red. |
| ``scarlet_absorb_red`` | ``0.8`` | Share of each hit that red armor absorbs. |
| ``scarlet_max_shells`` | ``100`` | Maximum carried. |
| ``scarlet_max_nails`` | ``200`` | |
| ``scarlet_max_rockets`` | ``100`` | |
| ``scarlet_max_cells`` | ``100`` | |

### Ammo crates

``scarlet_<type>_big`` and ``scarlet_<type>_small`` set how much each crate gives.

| Type | Big | Small |
|---|---|---|
| shells | ``40`` | ``20`` |
| nails | ``50`` | ``25`` |
| rockets | ``8`` | ``4`` |
| cells | ``12`` | ``6`` |

### Rate of fire

Seconds between shots.  Lower is faster.

| Cvar | Default |
|---|---|
| ``scarlet_rof_axe`` | ``0.49`` |
| ``scarlet_rof_sg`` | ``0.5`` |
| ``scarlet_rof_ssg`` | ``0.7`` |
| ``scarlet_rof_ng`` | ``0.095`` |
| ``scarlet_rof_sng`` | ``0.095`` |
| ``scarlet_rof_gl`` | ``0.6`` |
| ``scarlet_rof_rl`` | ``0.8`` |
| ``scarlet_rof_tb`` | ``0`` |
| ``scarlet_rof_hg`` | ``0.6`` |

### Spread, kick & speed

| Cvar | Default | What it does |
|---|---|---|
| ``scarlet_spr_sg`` / ``_ssg`` / ``_ng`` / ``_sng`` | ``4`` / ``14`` / ``0`` / ``2`` | Spread of shots.  ``0`` is perfectly accurate. |
| ``scarlet_kick_sg`` / ``_ssg`` / ``_ng`` / ``_sng`` / ``_gl`` / ``_rl`` / ``_tb`` | ``2`` / ``4`` / ``2`` / ``2`` / ``2`` / ``2`` / ``2`` | How far your view jolts when firing.  ``0`` for none. |
| ``scarlet_spd_ng`` | ``1996`` | Nailgun nail speed.  ``2000`` or more becomes instant hitscan. |
| ``scarlet_spd_sng`` | ``1020`` | Perforator nail speed.  ``2000`` or more becomes instant hitscan. |

## Melee

Attack with the axe without switching weapons.  Bind a key: ``bind f "impulse 120"``.

| Cvar | Default | What it does |
|---|---|---|
| ``scarlet_melee`` | ``0`` | Enable the melee attack. |
| ``scarlet_melee_spam`` | ``2`` | How many swings happen each time the key is pressed. |
| ``scarlet_melee_lunge`` | ``0`` | ``1`` turns on the lunge when you use the alternate axe attack.  ``0`` turns it off no matter what the settings below are. |
| ``scarlet_melee_lunge_speed`` | ``0`` | How fast the alternate axe attack throws you forward, in units per second.  ``0`` also turns the lunge off.  ``250`` to ``500`` is a good range. |
| ``scarlet_melee_lunge_hop`` | ``0`` | Upward speed added when you lunge from the ground, so you hop instead of sliding.  ``60`` is a small hop. |
| ``scarlet_melee_lunge_range`` | ``0`` | Lunge only when a player or monster is within this many units in front of you.  ``0`` means no range check.  ``250`` is a good value. |
| ``scarlet_melee_lunge_always`` | ``0`` | ``1`` lunges on every alternate axe attack, even with nobody in front of you.  Overrides the range. |
| ``scarlet_melee_lunge_cooldown`` | ``10`` | Seconds before the lunge can be used again after it has thrown you forward.  ``0`` means no limit.  A swing during the cooldown still hits, it just doesn't throw you. |

The lunge needs ``scarlet_melee_lunge 1``, ``scarlet_melee_lunge_speed`` above ``0`` and either a range or ``scarlet_melee_lunge_always 1``.

Lunging is buggy because of engine collision handling, which is why it's off by default.

## Hand Grenades

Toss a grenade without switching weapons.  Bind a key: ``bind g "impulse 121"``.

| Cvar | Default | What it does |
|---|---|---|
| ``scarlet_grenades`` | ``0`` | Enable grenades. |
| ``scarlet_grenades_min`` | ``2`` | Grenades you spawn with. |
| ``scarlet_grenades_max`` | ``4`` | Most grenades you can hold. |
| ``scarlet_grenades_fuse`` | ``1.5`` | Seconds until a thrown grenade explodes. |
| ``scarlet_grenades_touch`` | ``0`` | ``1`` makes grenades explode on contact with a player. |
| ``scarlet_grenades_maxpack`` | ``2`` | Most grenades that can appear in one backpack. |
| ``scarlet_grenades_restock`` | ``0`` | ``0`` means grenades come from backpacks (old maps have no grenade pickups to place).  ``1`` or more gives you a full restock every that many seconds. |
| ``scarlet_grenades_chance`` | ``0.5`` | Chance a bot throws a grenade when it can. |
| ``scarlet_grenades_cooldown`` | ``8`` | Seconds a bot waits between throws. |

---

## Commands

### Player impulses

| Command | What it does |
|---|---|
| ``impulse 120`` | Melee attack (needs ``scarlet_melee 1``). |
| ``impulse 160`` | Best rocket weapon: the rocket launcher, or the grenade launcher if that is missing or out of rockets. |
| ``impulse 161`` | Best nail gun: the super nailgun, or the nailgun. |
| ``impulse 162`` | Best shotgun: the super shotgun, or the shotgun. |
| ``impulse 121`` | Toss a hand grenade (needs ``scarlet_grenades 1``). |
| ``impulse 123`` | Print every player's frags, deaths and assists to your console. |
| ``impulse 122`` | Swap to a different random music track right now, picked from ``scarlet_music_min`` to ``scarlet_music_max`` and never the same track twice in a row.  Switches for every player and announces the track number in chat.  Works even if ``scarlet_music`` is ``0``. |

### Bot impulses

| Command | What it does |
|---|---|
| ``impulse 100`` | Add a bot. |
| ``impulse 101`` | Add a bot to the other team. |
| ``impulse 102`` | Remove the most recently added bot. |
| ``impulse 103`` | Spectate other players. |
| ``impulse 104`` | Enter dev mode for editing waypoints. |
| ``impulse 105`` | Show or hide the waypoint links around you, drawn as beams (lightning for a teleporter link).  Only the nearest six waypoints are drawn, so it follows you as you walk. |
| ``impulse 110`` | Add a bot with random skill (up to ``skill``). |
| ``impulse 111`` | Add a random-skill bot to the other team. |
| ``impulse 113`` | Teleport your bots to you in coop (once per minute). |
| ``impulse 150`` | Load a random ``mapN`` alias from ``maps.cfg`` (uses ``samelevel`` as the map count, else ``20``). |

### Game mode cvars (standard Quake)

| Cvar | What it does |
|---|---|
| ``skill`` | Bot skill ``0`` to ``3``, also the monster skill. |
| ``teamplay`` | ``1`` turns teamplay on. |
| ``deathmatch`` | ``1`` turns deathmatch on. |
| ``coop`` | ``1`` turns coop on. |

For how the bots find their way around a map (and how to build the trail files they need), see ``TRAILGEN.md``.
