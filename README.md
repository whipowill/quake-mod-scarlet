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

### Mod Mergers

- [FrikBot4+Copper](https://github.com/whipowill/quake-mod-frikbot4/tree/copper) - a branch of FrikBot merged w/ [Copper](http://lunaran.com/copper/) v1.19

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

### Core Changes

These are my changes from the original FrikBot code:

- Bots ``skill`` now scales linearly from ``0`` to ``3`` (25% to 100% accuracy)
- Bots can now be spawned w/ random ``skill`` levels (simulates real multiplayer game)
- Bots no longer try to follow each other in team deathmatch games (fixes clumping)
- Bots will now wear the proper team color in coop games
- Bots will now wait 5 seconds after death before respawning
- Items now always respawn in singleplayer and coop games
- Added waypoints files: ``nova``, ``travelert6``
- Renamed a few bots

### Optional Changes

These are optional changes you can control using cvars in your ``autoexec.cfg`` file:

- ``frikbot4_gore 1``
    - Increases the amount of bood particles
    - Increases the amount of gibs in death explosions
    - Enemies now bleed (profusely) when hit from direct or blast damage
    - Enemy heads and gibs are now kickable *
    - Enemy bodies can now be gibbed into chunks *
- ``frikbot4_nametag 1``
    - Displays player names on screen when aiming at them
- ``frikbot4_placeholder 0`` **
    - Disables transparent item placeholders in maps to restore normal item behavior

You will want to run the game w/ ``-particles 16384`` to increase the amount of particles allowed in the game.

- ``*`` this feature does not work w/ the Copper branch
- ``**`` this feature only works w/ the Copper branch

## Credits

- Original bot mod by [FrikaC](https://www.moddb.com/mods/frikbot-x), Igor9, and JLaw
- Original waypoint files by [LightningHunter](https://www.celephais.net/board/view_thread.php?id=60404)
- Original nametag code by [BenVanCitters](https://gist.github.com/BenVanCitters/a157f58e906bf00adc39a484cbcee12f)
- Original corpse gibbing code by [Kryten](https://www.insideqc.com/qctut/qctut-33.shtml)
- Original corpse kicking code by [Ivana](http://www.insideqc.com/qctut/lesson-52.shtml)
- Original enemy bleeding code by [Maniac](https://www.insideqc.com/qctut/qctut-47.shtml)
- Original Copper mod by [Lunaran](http://lunaran.com/copper/) (using v1.19)

## References

- [Intro to QuakeC](https://codedocs.org/what-is/quakec) - nice intro to what QuakeC is and it's history.
- [FTEQCC](https://fte.triptohell.info/downloads) - the QuakeC compiler I used to compile this code.
- [FTEQCC Docs](https://fte.triptohell.info/moodles/fteqcc/README.html) - the difficult to find docs about FTEQCC.
- [QuakeC Manual](http://www.cataboligne.org/extra/qcmanual.html#Names) - helpful list of available functions.
- [QuakeC Tutorials](https://quakewiki.org/wiki/QuakeC_tutorials) - a list of tutorials for modding QuakeC.
- [Quake Bot Archive](https://github.com/Jason2Brownlee/QuakeBotArchive) - an archive of all Quake bot versions w/ a little history.
- [Copper Mod](http://lunaran.com/copper/) - the website for the vanilla+ mod and related docs.