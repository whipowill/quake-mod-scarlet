# Scarlet for Quake

Scarlet is a Quake enhancement mod primarily intended for the multiplayer enthusiast. It adds a menu of modern features w/out losing the original soul of the game.

**This mod uses a totally new, completely redesigned botting program called Trailgen.  It includes an executable that automatically generates all the necessary waypoint files for every map in your game directory.**  This means you can have instant bot-compatible maps without any work at all, just run the program and it creates what it needs.

[![Scarlet for Quake](https://i.imgur.com/4o2EPCa.png)](https://rumble.com/user/whipowill24)

## Features

Adding a mix of modern conveniences to a classic game from 1996:

### Core Features

- **Multiplayer Bots** - new **Trailgen** bot players for all your games
- **Blood & Gore** - bathe in the blood of your enemies w/ native engine generated gore
- **Perfect Balance** - weapons have been tuned to perfection w/ configurable settings
- **Powerup Icons** - players who pick up powerups have that icon over their heads
- **Item Resupply** - items can respawn in singleplayer coop games
- **Music Shuffle** - maps play music at random, instead of a preset track
- **Plain Quake Underneath** - built on id Software's original Quake source, so the base game plays as it always did

### Combat Features

- **Melee Attacks** - perform a melee axe attack w/out switching weapons
- **Hand Grenades** - toss a hand grenade w/out switching weapons
- **Name Tags** - see other player names Halo-style when aiming at them
- **Killing Spree** - game announces when you're on a killstreak and when it ends
- **Random Powerups** - every kill has a chance to drop a random powerup
- **Highlander Games** - higher their killstreak, greater the chance of reward for taking their head
- **Shield Recharge** - survive the battle and your shield begins to recharge

Every single feature in this mod is optional and controlled via console variables.

## Install

The full vision and experience of this mod is represented by my uploaded Quake [directory](https://github.com/whipowill/quake-dir), which is preloaded w/ other paks and configuration files tuned to my desired settings.

### Configuration

Every feature in this mod is a console variable that can be adjusted without recompiling.

- [CONSOLE.md](CONSOLE.md) - every cvar and command, with defaults and explanations
- [CHANGELOG.md](CHANGELOG.md) - what changed as this mod has been developed
- [TRAILGEN.md](TRAILGEN.md) - how the bots find their way around a map, and the tool that builds their trails

These instructions are so extensive, playing from my uploaded Quake [directory](https://github.com/whipowill/quake-dir) is the best way to get started.

## Usage

The bots need waypoint files to function properly.  Historically, players had to create these files on their own and circulate them.  But now with Trailgen this process is entirely automated.

Put the right ``bin`` program in your Quake directory (the folder that holds ``id1``) and run it from there with nothing after it.  It finds every map under that folder and makes the trail files the bots need:

| Your computer | Program | Run it |
| --- | --- | --- |
| Linux | ``trailgen`` | ``./trailgen`` |
| Windows | ``trailgen.exe`` | ``trailgen.exe`` in Command Prompt, or ``.\trailgen.exe`` in PowerShell |
| Mac, Apple chip (M1 and later) | ``trailgen-mac-arm64`` | ``./trailgen-mac-arm64`` in Terminal |
| Mac, Intel chip | ``trailgen-mac-intel`` | ``./trailgen-mac-intel`` in Terminal |

The program will find all ``bsp`` files in your game folder and compile the necessary ``ent`` files.  It will detect changes in your maps and regenerate if you are a map creator.  ``TRAILGEN.md`` has the details, including what to do if your computer won't let you run it.

## License

Scarlet's own code is free software under the **GNU General Public License, version 2** (see [LICENSE](LICENSE)), the same license id Software released the Quake source under, which this mod is built on.  Several parts have their own terms: FrikBot's public domain notices, and some art and sound made by others.  [NOTICE.md](NOTICE.md) lists them all.  Quake's game data is not included and you need your own copy.

## Credits

- Original Quake game source by [id Software](https://github.com/id-Software/Quake)
- Original FrikBot mod by [FrikaC](https://www.moddb.com/mods/frikbot-x), Igor9, and JLaw
- Original waypoint files by [LightningHunter](https://www.celephais.net/board/view_thread.php?id=60404)
- Original nametag code by [BenVanCitters](https://gist.github.com/BenVanCitters/a157f58e906bf00adc39a484cbcee12f)
- Original corpse gibbing code by [Kryten](https://www.insideqc.com/qctut/qctut-33.shtml)
- Original head kicking code by [Ivana](http://www.insideqc.com/qctut/lesson-52.shtml)
- Original enemy bleeding code by [Maniac](https://www.insideqc.com/qctut/qctut-47.shtml)
- Original health cross model provided by [Quoth](https://www.quaddicted.com/webarchive/kell.quaddicted.com/quoth/quoth2.html)
- Original footsteps code by [Seven](https://www.quakewiki.net/quake-1/mods/footsteps-pack/)

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
- [PointerStat Explanation](https://www.attackersgored.com/?p=2909) - useful tips on sending ``globalstat()`` to the client