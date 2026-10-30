# Bot pathing and Trailgen

How Scarlet's bots find their way around a map, and the tool that makes the map data they need.

Scarlet's bots started as [FrikBot X](https://www.moddb.com/mods/frikbot-x) by FrikaC, Igor9 and JLaw, and the way they walk, aim and talk is still FrikBot's.  The pathing has since evolved into something quite different.  FrikBot needed a hand-made waypoint file for every map (`.way`, made with its in-game editor).  Scarlet drops all of that.  It generates the waypoints from the map itself with a tool called **trailgen**, and a map without a trail file has bots that stand still.

## The short version

1. `trailgen` reads a map's `.bsp`, works out where a player can walk, jump, fall and teleport, and writes `maps/<map>.ent`.
2. That file is the map's own entities plus about a hundred `waypoint` entities, each linked to up to four others.
3. When the map loads, the engine reads the `.ent` instead of the entities inside the `.bsp`, so the waypoints simply appear.
4. The bots walk that graph.  They pick a goal (an item, a player, a spot to patrol), ask the route table for the shortest way there, and follow it hop by hop.

The waypoints are ordinary entities in an `.ent` file, so this works in any engine that loads `maps/<map>.ent`, including vkQuake, which has no file access for QuakeC.  Nothing is read or written while you play.

## Telling which mode a map is in

Once a map has loaded, in a game with room for more than one player (a multiplayer game, or single player with bots), the mod reports whether the map has a trail:

- **With a trail**, the console says `Bot pathing: Trailgen file found (219 waypoints loaded from maps/nova.ent)`.  Each human player also gets a chat line about three seconds after they arrive: `Bot pathing: Trailgen file found (219 waypoints, maps/nova.ent)`.
- **Without one**, the console says `Bot pathing: no Trailgen file found, so the bots will not move`, and players get a similar chat line.  There is no fallback.  The bots still join, but they have no goals and stay where they spawned, and they don't strafe or dodge either.  Build the map's trail (below) and restart the map.

## Building the trails

The `trailgen` program comes with the mod, one for each kind of computer: `trailgen` (Linux), `trailgen.exe` (Windows), `trailgen-mac-arm64` (Mac with an Apple chip, M1 and later) and `trailgen-mac-intel` (Intel Mac).  They all do the same thing and make identical files.  Put the one for your computer in your Quake folder, the one that holds `id1`, open a terminal there and run it with nothing after it.

**Linux**

```
cd /path/to/quake
./trailgen                       # every map under this folder, files into scarlet/maps (old trailgen files go first)
./trailgen id1/maps/dm4.bsp      # one map
./trailgen id1/pak1.pak          # every map in one pak
./trailgen scarlet/maps          # one folder
./trailgen -keep                 # leave the old files and only rebuild what changed
```

**Windows** (Command Prompt, or PowerShell, which needs the `.\` in front)

```
cd C:\path\to\quake
trailgen.exe                     # every map under this folder, files into scarlet\maps
trailgen.exe id1\maps\dm4.bsp    # one map
trailgen.exe -force              # rebuild everything
```

Windows may warn that the program is from an unknown publisher the first time: choose "More info" and "Run anyway".  If you'd rather not open a terminal, put `trailgen.exe` in the Quake folder and double-click it: it builds everything and the window shows the progress, but closes when it finishes, so a terminal is better if you want to read the result.

**Mac** (Terminal)

```
cd /path/to/quake
chmod +x trailgen-mac-arm64      # once, to let it run (use trailgen-mac-intel on an Intel Mac)
./trailgen-mac-arm64             # every map under this folder, files into scarlet/maps
./trailgen-mac-arm64 -force      # rebuild everything
```

The first time, macOS may say it can't be opened because it wasn't downloaded from the App Store.  Clear that with `xattr -d com.apple.quarantine trailgen-mac-arm64`, or open System Settings, Privacy & Security and choose "Open Anyway".  Not sure which Mac you have?  Apple menu, About This Mac: "Apple M1" (or later) means `trailgen-mac-arm64`, "Intel" means `trailgen-mac-intel`.

The examples below say `./trailgen`; use your own program's name.

**Every trail goes into the mod folder.** trailgen finds all the `.bsp` files and `.pak` files under the folder you run it in, but writes every `.ent` into `scarlet/maps`, whichever folder or pak the map came from.  The game looks for `maps/<map>.ent` in every game folder, and a file in the mod folder beats one anywhere else, including the entity files some engines (vkQuake, for one) have built in for e1m1, e1m2, e1m4 and more.  Files left anywhere else would lose to those, and the bots would find no waypoints.  If there is no `scarlet` folder next to where you run it, trailgen stops at once with an error and changes nothing: run it from the Quake folder, name the folder with `-mod`, or choose another place with `-o`.

It searches folders all the way down for `.bsp` files and `.pak` files, and prints a progress line for each map.  Each `.ent` is written into the mod folder's `maps` folder, as described above.  Maps inside paks (`dm1`-`dm6` and the single player levels are in `id1/pak1.pak` and `id1/pak0.pak`) are found too.  Within one game folder, a loose map beats the same map in a pak and a later pak beats an earlier one, as in the game.  Brush models for items (`maps/b_*.bsp`) are skipped.

| Option | What it does |
| --- | --- |
| `-force` | Rebuild even if the `.ent` is up to date. |
| `-keep` | Don't delete the `.ent` files trailgen made earlier, and skip the maps whose `.ent` is up to date.  By default every `.ent` that trailgen made in the folders it is about to write to is deleted first, so maps you tried once and dropped leave nothing behind.  A `.ent` written by hand (no trailgen header) is never deleted. |
| `-mod name` | The mod folder the `.ent` files go into (`maps` inside it).  `scarlet` by default. |
| `-o dir` | Write the `.ent` files into `dir` instead of the mod folder (no mod folder is needed then). |
| `-v` | List the items that could not be reached on each map, and any spawn perch that needed long drops. |
| `-step N` | Distance between waypoints, `256` by default. |
| `-lift N` | How far above a standing player's origin the waypoints sit, `12` by default. |

Every run deletes the old trailgen files first (see `-keep`), so every map is rebuilt; with `-keep`, a map that is already up to date is skipped.  The first line of every `.ent` is a header with the generator version, a hash of the `.bsp` and the `-step` and `-lift` values.  If the map, the version or those values change, the file counts as stale and is rebuilt.  Run `./trailgen` again after updating the mod.

If a map has a hand-made `.ent` (not one of trailgen's own), trailgen starts from that file's entities instead of the ones in the `.bsp`, and keeps a copy as `<map>.ent.orig` the first time it overwrites it.

It reads Quake BSP version 29 and BSP2.  Other formats are reported as errors and skipped.

## How the graph is made

Trailgen simulates a player (the standing hull, 18 units of step height, the real gravity) on the map's collision data:

1. **Seeds.**  A waypoint at every spawn (`info_player_start`, `_deathmatch` and `_coop`), inside every teleporter (linked straight to where it leads), at the bottom and top of every plat, and at every item.  Keys, sigils and runes are left out.  The shaft under a plat is kept clear, so bots don't wait where the plat will come down on them and no link crosses it.
2. **Fill.**  From each waypoint it grows new ones about 256 units away (closer where the room is tight) in 16 directions, wherever a player can walk, until nothing new fits.  A ledge a bot can step off becomes a one-way fall link, up to 160 units down.
3. **Links.**  Waypoints within two steps of each other are linked, shortest first, if a bot can walk between them without falling, with a few rules:
   - at most four links per waypoint (that is all the mod stores);
   - a link is skipped if the graph already has a path within 1.2 times as long;
   - a link needs at least 10 units of floor either side, so it doesn't run along an edge a bot would fall off;
   - a few long "express" links (up to about 900 units) are added where they save at least four hops.  The bots' route search moves one hop per frame and one bot at a time, so a shallow graph means less waiting for a route.
4. **Specials.**  Teleporter and plat links are always kept.  An item with no way to it on foot gets a launch spot from a waypoint that can reach it by a plain jump (up to about 40 units up and 160 across) or a rocket jump (from 50 below to 240 above, up to 420 across).  Both are simulated with a margin for error.
5. **Traps and perches.**  A waypoint a bot could get to but never leave is dropped.  A perch with no way down gets long drops of up to 768 units so bots can leave it, even when the perch holds more than one spawn.  That covers a spawn on a ledge with no other way off, and a ledge only reached by rocket jump.  When a spawn perch has an item on it (the red armor on aerowalk's high ledge, say), trailgen also looks for a jump or rocket jump up to it from the rest of the map, so bots can fetch the item and not just fall off the perch.  A fall of any length costs 5 health at most.
6. **Thinning.**  The web from steps 2 and 3 is only scaffolding, and left as it is it has several lines down every hall.  A person making a trail draws one path that touches every item, with waypoints at the joints.  So trailgen picks the key points (items, spawns, teleporters, plats and launch spots), joins each only to its direct neighbours (no other key point on the way) along the web's shortest path, and then pulls each path straight, dropping every waypoint a bot could walk past with a little room to drift off the line.  Waypoints that land on top of each other are merged, and no thinned link is allowed to cross a plat shaft.  What is left is the key points and the corners between them, usually a third to a half of the web.  If thinning would leave anything unreachable, or a junction needing more than four links that can't be reworked, that map keeps its full web and `-v` says why.
7. **Output.**  The waypoints are written as `waypoint` entities.  `b_pants`, `b_skill`, `b_shirt` and `b_frags` hold the numbers of up to four linked waypoints, and `b_aiflags` marks the teleporter, jump and rocket-jump links.  Every item trailgen can't get a bot to is marked `trail_skip`, and bots leave it alone.  That includes an item hanging more than 80 units above the floor under it (or with no floor under it at all), because no one standing there can touch it, and one on a ledge with no way off.

   Every map's file is saved twice, as `<map>.ent` and as `<map>@<checksum>.ent`.  vkQuake and Quakespasm look for the second name first (the checksum is a CRC-16 of the map's own entity text, in hex), and ship their own entity fixes under that name for some stock maps (e1m1, e1m2, e1m4, e2m2, e2m3 and e2m7).  With only `<map>.ent`, the engine's file would win on those maps and the bots would find no waypoints.  The copy replaces the engine's file, so trailgen starts from the engine's fixed entity list when it can find it (the `quakespasm.pak` in the Quake folder has the same fixes), and keeps those small fixes.

Kill zones are kept out of the graph: a `trigger_hurt` that does 50 or more damage, and `trigger_void` and `func_void`.  No waypoint, link, landing after a fall or jump touches one (trailgen uses the zone's bounding box and keeps 8 units clear), and the summary line says how many it found.  A zone that a trigger switches on and off counts as always on.  Lava, slime and water were already avoided.

The summary line for each map tells you what it found: waypoints, spawns, teleporters, plats, rocket jumps, how many items are reachable on foot, how many waypoints were dropped, and how winding the routes are (1.0 would be perfectly straight).

Some items can't be reached by any route trailgen can find, often because they are behind a door that needs a button or a key, in a secret, in water, or a long way from anything walkable.  Bots never choose an item the route table can't reach.  Use `-v` to see which ones.

**Doors.**  A bot opens a door by walking into it, so a plain door is no obstacle.  Trailgen treats a door as a wall when walking up to it would not open it:
- it needs a gold or silver key;
- it has to be shot (it has health), or it is a secret door;
- it is triggered by a button, a relay or anything else a bot can't use (it has a targetname).

A triggered door that a walk-in trigger volume is aimed at counts as a wall only until a bot can reach that volume.  Some of those volumes sit on the far side of the door they open, and then the door stays a wall.  Anything that can only be reached through a wall door is marked unreachable, and the bots leave it alone.  The summary line says how many doors were treated as walls.  A door that starts open is never a wall.  The bots' stuck rule (above) is still the safety net for any door this misjudges.

### Diagnostics

A few environment variables print extra information while a map is built (`TESTING.md` has the full list), and `TRAILGEN_DENSE=1` skips the thinning and keeps the full web.  Three of them:

- `TRAILGEN_NARROW=1` - how much floor there is beside each walk link and each waypoint.
- `TRAILGEN_PROBE="x,y,z"` - a text map of where a player can stand around a point.
- `TRAILGEN_WHY="x,y,z"` - the usable waypoints near a spot and whether a jump from each could land on it.

## What the bots do with the graph

- **Goals.**  A bot scores every item, player and powerup by its value and its distance and goes for the best.  It only stands still when it needs nothing at all.  A bot with nothing to fetch patrols the item spots like a player rather than wandering at random.  While it is heading somewhere it also glances around: a powerup of top priority that it passes goes to the front of its plan, and so does an ordinary item within about 200 units that is worth clearly more than the goal it is walking to (an armor upgrade, say, when it is on its way to a box of nails).
- **Routes.**  The route table floods outward from the bot's waypoint, one hop per frame, and the bot follows the shortest chain back.  Only one bot calculates at a time, so a bot can wait a moment for its turn without a goal.
- **Teleporters.**  A bot that goes through one drops its whole plan and starts again from where it came out, so it doesn't walk back through.
- **Giving up.**  A target that takes too long to reach is dropped: each gets two seconds plus the time to walk there at 200 units a second, so a long straight link isn't given up on just short of the end.  The bot then plans again.  A dropped target is left alone for about five seconds (four for a player), so the bot doesn't pick it straight away again, and an item it keeps failing to reach is left alone for longer each time, up to 90 seconds.
- **Stuck.**  A bot that has barely moved (16 units) in two seconds drops its whole plan and bans the goal it was heading for, an item or a waypoint, for 60 seconds, for every bot.  A player it was chasing is avoided for 60 seconds in deathmatch but never banned in single player and co-op, where it follows you.  A bot that is waiting for a lift is exempt.  This is what stops bots walking into a door that needs a button forever.
- **Other players.**  A bot steps aside for a player blocking its way, runs from a player carrying the pentagram, and edges sideways when it is pushing into a wall beside a doorway.
- **Falls.**  Bots stop at ledges they weren't routed over, but fall links and long drops are followed on purpose.
- **Kill zones.**  A bot about to walk off a ledge looks all the way down and treats a kill zone below like lava, and a bot walking toward one turns away.  The trails never route a bot into one, so this only matters when a bot ends up near an edge some other way.  A bot knocked off a platform by a blast can still fall in.

## Bot skill

A bot's skill (0 to 3) is the game's `skill` setting when the bot is added.  The commands that add a random bot use that or one lower.  FrikBot only ever made a weaker bot aim worse.  Scarlet holds a weaker bot back in five ways, and skill 3 is never held back:

| | skill 0 | skill 1 | skill 2 | skill 3 |
| --- | --- | --- | --- | --- |
| Reaction to a new enemy (it neither turns nor fires at it until then) | 0.6 s | 0.4 s | 0.2 s | none |
| Turning speed while hunting | 60% | 75% | 90% | instant |
| Aim wobble (a new offset every half second or so) | 6 degrees | 4 | 2 | none |
| Shots led, out of 3 predictions | 0 | 1 | 2 | 3 |
| Rockets, grenades and nails dodged (decided once per shot) | 25% | 50% | 75% | 100% |

The older rules still apply on top:
- A bot below skill 3 stops turning once it is within 11, 7.5 or 3.75 degrees of its target (skill 0, 1, 2), and fires whenever it is within 30 degrees.
- Skill 3 notices anyone it can see even when facing away.
- Skill 0 never rocket jumps.
- A bot that isn't hunting anyone turns instantly at every skill, so slow turning never sends it off a ledge.

`scarlet_bot_handicap` scales the table.  `1` is the full amount, `0` makes every bot play like skill 3, and `0.5` is half way.

In tests on nova, a skill 2 bot scored about 2.2 times as many frags as a skill 0 bot with no skill 3 bots around.  Skill 3 still wins by a wide margin whenever it is in the game, because it turns instantly and aims perfectly.

## Watching it work

Developer settings (see `CONSOLE.md`):

- `scarlet_dev_botlog 1` (with `developer 1`) - prints each bot's position and goal about once a second, the waypoint mode every ten seconds, every goal a bot reaches or gives up on, its teleports (`BOTTELE`), its deaths and where they happened (`BOTDEAD`), the items it detours for (`BOTGRAB`), the targets it can't find a route to (`BOTNOPATH`), drops of more than 80 units (`BOTFALL`), and jams and give-ups (`BOTSTUCK`, `BOTTIMEOUT`, `BOTWALL`, `BOTSQUEEZE`).
- `scarlet_dev_botgoal 1` - floats a model over each bot showing its goal (the item's own model for an item, a fireball for a waypoint, a head for a player, a rocket when fighting, a gib when running from the pentagram, a spike for no goal), and names the goal when you look straight at a bot.
- `impulse 105` - draws the links between the waypoints around you as beams (teleporter links as lightning), so you can look at a trail in the game.  Press it again to hide them.  Only the nearest six waypoints are drawn at a time.
- `scarlet_dev_autobots N` - adds bots with nobody connected, for testing on a dedicated server.
- `scarlet_dev_wayfile 1` - also loads an old `.way` file, only to compare it with a trail.

## Source

| Where | What |
| --- | --- |
| `tools/trailgen/` | The generator (Go, no dependencies).  `gen.go` builds the graph, `move.go` is the player simulation, `bsp.go` and `pak.go` read the files, `narrow.go` holds the diagnostics, `out.go` writes the `.ent`. |
| `src/frikbot/bot_way.qc` | Waypoints and the route table. |
| `src/frikbot/bot_ai.qc` | Goal choice, following a route, the give-up rules, aiming. |
| `src/frikbot/bot_fight.qc` | Fighting, the skill handicaps, dodging, running from the pentagram, stepping around players and walls. |
| `src/scarlet/bot_goalmark.qc` | The developer goal markers and drop log. |
