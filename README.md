# Frikbot4 for Quake

A Quake mod for playing w/ multiplayer bots.

The Frikbot mod is one of the best Quake bots to play with.  This repo continues the development of some old code for an even older game.

## History

I'm making changes to a mod created by others:

- ``frikbot x`` - by FrikaC
- ``frikbot x+`` - by Igor9
- ``frikbot x++`` - by JLaw

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
- ``impulse 103`` - spectate other players
- ``impulse 104`` - enter dev mode for editing waypoints

Be sure and reference the included ``instructions.html`` file from FrikaC for detailed information about using the bots.

## Changelog

- Bots ``skill`` now scales linearly from ``0`` to ``3`` (25% to 100% accuracy).
- Bots can now be spawned w/ random ``skill`` levels (simulates real multiplayer game).
- Bots no longer try to follow each other in team deathmatch games (fixes clumping).
- Bots will now wear the proper team color in coop games.
- Bots will now wait 5 seconds after death before respawning.
- Items now always respawn in singleplayer and coop games.
- Added waypoints files: ``nova``, ``travelert6``
- Renamed a few bots.

### Gore

Initiated by adding ``frikbot4_gore 1`` to your ``autoexec.cfg`` file.

- Increases the amount of bood particles.
- Increases the amount of gibs in death explosions.
- Enemies now bleed (profusely) when hit from direct or blast damage.
- Enemy heads and gibs are now kickable.
- Enemy bodies can now be gibbed into chunks.

I think this is really tastefully done and brings Quake up to a level of violence worthy of a Doom successor.  What's different from other gore mods is I didn't use any new textures or decals, making this mod compatible w/ any Quake engine you might use.  I just changed the programming of the assets that are already baked into the game.

You will want to run the game w/ ``-particles 16384`` to increase the amount of particles allowed in the game.

## Nametags

Initiated by adding ``frikbot4_nametags 1`` to your ``autoexec.cfg`` file.

- Displays player names on screen when aiming at them.

## Credits

- Original Frikbot mod by FrikaC, Igor9, and JLaw
- Original compilation of waypoint files by LightningHunter

## References

- [FTEQCC](https://www.fteqcc.org/) - the QuakeC compiler I used to compile this code.
- [Intro to QuakeC](https://codedocs.org/what-is/quakec) - nice intro I found on how to compile QuakeC code.
- [QuakeC Manual](http://www.cataboligne.org/extra/qcmanual.html#Names) - helpful list of available functions.
- [Deathmatch With Bots](https://steamcommunity.com/sharedfiles/filedetails/?id=123626484) - a guide I used to figure out what bot to use.
- [Frikbot X on ModDB](https://www.moddb.com/mods/frikbot-x) - where I found the missing campaign waypoint files.
- [Quake Bot Archive](https://github.com/Jason2Brownlee/QuakeBotArchive) - an archive of all Quake bot versions w/ a little history.
- [Definitive Frikbot Waypack](https://www.celephais.net/board/view_thread.php?id=60404) - where almost all the waypoints come from.
- [QuakeC Tutorials](https://quakewiki.org/wiki/QuakeC_tutorials) - a list of tutorials for modding QuakeC.