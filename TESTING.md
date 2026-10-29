# Testing notes

For trying out the bots and trails.  Not shipped with the mod.

## Setting up a game

Console commands before the map:

```
developer 1          // needed for the dev logs below
deathmatch 1
skill 2              // 0-3: the skill of bots added with the impulses
teamplay 2           // optional: 1 or 2 for teams
map nova
```

Then add bots with the impulses below, or let the game do it with `scarlet_dev_autobots`.

## Impulses

| Impulse | What it does |
| --- | --- |
| `100` | Add a bot (skill = the `skill` setting). |
| `101` | Add a bot to the other team. |
| `102` | Remove the most recently added bot. |
| `110` / `111` | Add a bot of random skill (up to `skill`) / to the other team. |
| `103` | Spectate: each press moves to the next player.  Keep pressing to go back to playing. |
| `105` | Show or hide the waypoint links around you as beams (teleporters as lightning).  Only the nearest six waypoints are drawn, so it follows you. |
| `104` | Waypoint editor menu (the old FrikBot editor). |
| `113` | Teleport your bots to you (co-op, once a minute). |
| `114` | Go to the next map. |
| `150` | Go to a random map from `maps.cfg`. |
| `123` | Print every player's frags, deaths and assists. |
| `130` | Print the scorekeeper's lists. |
| `120` / `121` | Melee attack / toss a hand grenade. |

## Watching what a bot is doing

- `scarlet_dev_botgoal 1`: a model floats over every bot showing its goal.  The item's own model for an item, a fireball for a waypoint, a head for a player, a rocket when it is fighting, a gib when it is running from a pentagram, a spike when it has no goal.  Look straight at a bot and its name and goal print on screen.
- `impulse 103` to ride along with a bot, `impulse 105` to see the trail as you go.  Spectate a teammate bot in a quiet part of the map: a fighting bot ignores the waypoints, one that is just walking shows how good the trail is.

On map load a chat line says whether the map has a trail (`Trailgen file found (N waypoints)`) or not (`no Trailgen file found, so the bots will not move`).

## Settings that change how bots behave

| Setting | Default | Notes for testing |
| --- | --- | --- |
| `skill` | | 0-3.  Only skill 3 aims perfectly and turns instantly. |
| `scarlet_bot_handicap` | `1` | How much weaker skills 0-2 are.  `0` makes every bot play like skill 3, so it is the quick way to separate a skill effect from a pathing problem. |
| `scarlet_bot_goal_distance` | `1500` | Distance at which an item is worth half as much.  `0` is the old behavior: the best item anywhere. |
| `scarlet_bot_edgefriction` | `1.5` | Extra friction at a drop-off.  `1` lets bots walk off ledges. |
| `scarlet_bot_priority_quad`, `_pent`, `_mega`, `_ring` | `1000`, `1000`, `1000`, `0` | How much bots want the powerup.  The ring is `0`, so bots ignore it; raise it to test a ring route. |
| `scarlet_bot_dialogue` | `1` | Bot chatter. |
| `scarlet_testing` | `0` | Bots say the topic name instead of a quote. |
| `scarlet_bots_enemy_color` | `-1` | Color of the other team. |

## The dev log

Turn it on with `developer 1` and `scarlet_dev_botlog 1`.  Everything goes to the console, so use `-condebug` to keep it in `qconsole.log`.

| Line | Meaning |
| --- | --- |
| `BOTLOG` | Once a second per bot: position, goal, health, whether it has an enemy, whether it is on the ground. |
| `BOTMODE` | Every 10 seconds: `mode 3` is a loaded trail, `mode 0` is none. |
| `BOTLOST name ok/fail class pos` | A target the bot reached (`ok`) or gave up on (`fail`).  Waypoint hops show up here too, so count the `item_` and `weapon_` ones for goals. |
| `BOTSCAN` | A whole-map goal scan: the best pick (its class, score, model, position and name), the bot's health, armor and ammo, and why items were skipped.  A blank class with `progs/backpack.mdl` is a backpack a dead player dropped. |
| `BOTNOPATH` | A bot picked a target it had no route to, and why: no waypoint can see it, or its waypoint can't be reached from where the bot is.  A bot that repeats these with nothing else to do is looping. |
| `BOTGRAB` | A bot detoured for a clearly better item right beside it. |
| `BOTTIMEOUT`, `BOTSTUCK` | The bot gave up on a target that took over two seconds (`BOTTIMEOUT`), or hadn't moved in two seconds (`BOTSTUCK`).  After a `BOTSTUCK` the bot's whole goal, the item or far waypoint at the end of its plan, is off limits to every bot for a minute, so nobody keeps walking into the same door. |
| `BOTWALL`, `BOTSQUEEZE` | A bot pushing into a wall for over a second, and a sideways step it took to get around. |
| `BOTTELE` | A bot went through a teleporter. |
| `BOTFALL` | A drop of more than 80 units.  `tdz` is how far above the bot its next waypoint was; near 0 means an accident. |
| `BOTDEAD` | A death and where it happened. |
| `BOTWAY` | One line per waypoint as the game sees it (number, position, the numbers it links to), about 12 seconds in. |
| `BOTTURN` | How many degrees a second a bot's direction changes while walking with no enemy.  A rough smoothness measure. |
| `PLATBLOCK` | A plat held up by something in its way. |

## Running a bot test without playing

`scarlet_dev_autobots N` adds bots by itself, so a dedicated server can run with nobody connected.  A throwaway copy of the game folder keeps your own settings and `qconsole.log` out of it:

```
mkdir -p /tmp/test/scarlet/maps
ln -s "$HOME/Games/Linux/Quake (1996)/id1" /tmp/test/id1
for f in pak0.pak progs.dat default.cfg quake.rc; do
    ln -s "$HOME/Games/Linux/Quake (1996)/scarlet/$f" /tmp/test/scarlet/$f; done
cp nova.ent /tmp/test/scarlet/maps/            # the trail to try
cat > /tmp/test/scarlet/autoexec.cfg <<'EOF'
developer 1
skill 2
scarlet_dev_autobots 6
scarlet_dev_botlog 1
deathmatch 1
map nova
EOF
mkfifo /tmp/test/fifo; ( sleep 130 > /tmp/test/fifo ) &
timeout 125 stdbuf -o0 "$HOME/Games/Linux/Quake (1996)/QSS-M-l64" -dedicated 16 -port 27001 \
    -basedir /tmp/test -game scarlet < /tmp/test/fifo > run.txt
```

Notes: standard input has to stay open (the fifo), `stdbuf -o0` stops the output being lost when `timeout` ends the server, and a map's `.ent` in `id1/maps` is found as well, so hide it if you want to test without one.  About a hundred seconds with six bots is enough to compare two trails; run each twice, because a single run is noisy.

Some numbers worth pulling out of `run.txt`: goals reached (`BOTLOST ... ok item_` and `weapon_`), the share of `BOTLOG` lines with `goal worldspawn` (no goal), `BOTTURN`, and the counts of `BOTSTUCK`, `BOTTIMEOUT` and `BOTWALL`.

## Trailgen

```
./trailgen -v -force -o /tmp/out id1/maps/nova.bsp     # one map, into a scratch folder
```

`-v` lists the items it couldn't reach and any spawn perch it had to help.  `-force` rebuilds even if the file is current.  Extra checks are switched on with environment variables:

| Variable | What it prints |
| --- | --- |
| `TRAILGEN_IMAGE=file.png` | A picture from above: the floors in grey, the waypoints as dots, the links in blue (short), green (medium), orange (long) and red (teleporters). |
| `TRAILGEN_CHECK=1` | Link lengths, links with no floor under part of them, and how close to a wall the waypoints sit. |
| `TRAILGEN_PROBE="x,y,z"` | A top-down text map of where a player can stand around a point. |
| `TRAILGEN_SLICE="x,y,z"` | The same as a side view along y: where the player's box fits. |
| `TRAILGEN_WHY="x,y,z"` | Why an item at that spot isn't reachable: the waypoints near it and whether a jump from each lands. |
| `TRAILGEN_NARROW=1` | How much floor there is beside each link and waypoint. |
| `TRAILGEN_DENSE=1` | Keep the full web of waypoints and don't thin it to a skeleton. |

Comparing two builds of the trail for one map is quickest with the picture and the `BOTTURN` and goal numbers above.  To see which waypoints were thinned and why a map kept its full web, look at the `skeleton:` line in the `-v` output.

## A checklist for a new trail

1. `./trailgen -v -force <map.bsp>` on the map, and read the summary line and the notes.
2. Load the map, check the console says the trail was found, add bots.
3. `impulse 105` and walk the halls: one line down a hallway, joints at the corners, no links through walls.
4. `scarlet_dev_botgoal 1` and spectate a bot or two with `impulse 103`.
5. A run with `scarlet_dev_botlog 1` and a look at `BOTSTUCK`, `BOTTIMEOUT`, `BOTWALL` and `BOTDEAD`.
