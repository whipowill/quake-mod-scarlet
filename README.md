# Frikbot4 for Quake

A Quake mod for playing w/ multiplayer bots.

The Frikbot mod is one of the best Quake bots to play with.  This repo continues the development of some old code for an even older game.

## Install

See my other [repo](https://github.com/whipowill/quake-dir) where I've uploaded my Quake directory.

## Controls

You can control the bots via the console.  Press the ~ key to bring down the console screen.

- ``skill <x>`` - set the bot skill level (0 to 3)
- ``teamplay <x>`` - turn on teamplay mode (1 or 0)
- ``deathmatch <x>`` - turn on deathmatch mode (1 or 0)
- ``coop <x>`` - turn on coop mode (1 or 0)
- ``impulse 100`` - add a bot to the game
- ``impulse 110`` - add a bot to the game of random skill level (up to ``skill`` setting)
- ``impulse 101`` - add a bot to the other team
- ``impulse 110`` - add a bot to the other team of random skill level (up to ``skill`` setting)
- ``impulse 102`` - remove most recently added bot
- ``impulse 103`` - spectate other players (use ``kill`` to exit)
- ``impulse 104`` - enter dev mode for editing waypoints

Be sure and reference the included ``instructions.html`` file from FrikaC for detailed information about using the bots.

## History

I'm making changes to a mod created by others:

- ``frikbot x`` - by FrikaC
- ``frikbot x+`` - by Igor9
- ``frikbot x++`` - by JLaw

## Changelog

- Bots ``skill`` levels are now appropriately scaled from ``0`` to ``3``.
- Bots can now be spawned w/ random ``skill`` levels using new ``impulse 110`` and ``impulse 111`` commands.
- Bots no longer try to follow each other in team deathmatch games.
- Bots will now wear the proper team color in coop games.
- Bots "Pimp Bot" and "Frik Bot" have had their names changed.
- Items now always respawn over time in singleplayer and coop games.
- Added waypoints files:
    - ``travelert6``

## Credits

- Original Frikbot mod by FrikaC, Igor9, and JLaw
- Original compilation of waypoint files by LightningHunter

## References

- [FTEQCC](https://www.fteqcc.org/) - the QuakeC compiler I used to compile this code.
- [Intro to QuakeC](https://codedocs.org/what-is/quakec) - nice intro I found on how to compile QuakeC code.
- [Deathmatch With Bots](https://steamcommunity.com/sharedfiles/filedetails/?id=123626484) - a guide I used to figure out what bot to use.
- [Frikbot X on ModDB](https://www.moddb.com/mods/frikbot-x) - where I found the missing campaign waypoint files.
- [Quake Bot Archive](https://github.com/Jason2Brownlee/QuakeBotArchive) - an archive of all Quake bot versions w/ a little history.
- [Definitive Frikbot Waypack](https://www.celephais.net/board/view_thread.php?id=60404) - where almost all the waypoints come from.