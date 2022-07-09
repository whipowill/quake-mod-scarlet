# Frikbot4 for Quake

A Quake mod for playing w/ multiplayer bots.

The Frikbot mod is one of the best Quake bots to play with.  This repo continues the development of some old code for an even older game.

## Install

See my other [repo](https://github.com/whipowill/quake-dir) where I've uploaded my Quake directory.

## Controls

You can control the bots via the console.  Press the ~ key to bring down the console screen.

- ``impulse 100`` - add a bot to the game
- ``impulse 101`` - add a bot to the other team
- ``impulse 102`` - remove most recently added bot
- ``impulse 103`` - spectate other players (use ``kill`` to exit)
- ``impulse 104`` - enter dev mode for editing waypoints

Be sure and reference the included ``instructions.html`` file from FrikaC for detailed information about using the bots.

## History

I'm making changes to a mod created by others:

- ``frikbot x`` - by FrikaC (I'm calling this ``frikbot1``)
- ``frikbot x+`` - by Igor9 (I'm calling this ``frikbot2``)
- ``frikbot x++`` - by JLaw (I'm calling this ``frikbot3``)

Which brings me to ``frikbot4``.  My changes are minimal.

## Fixes

### Teamplay

I spent a week playing w/ ``frikbot3`` and had a blast, but what I found was that teamplay games didn't work so well.

It turns out there was a flaw in the bot logic that made them want to follow other teammates around the map.  What ended up happening is the bots would clump together and just idle there.

I found the priority logic in the bot code and made a change where following teammates has a priority of zero.  I literally commented out a single line of code.

You can now play teamplay games and the bots are awesome, just like they are in FFA.

### Skills

After playing on ``skill 1`` for a while, I decided it was time to take my game up a notch.  So I bumped it up to ``skill 2``.

I then proceeded to get my ass handed to me.  What I found in the code is two sections based on skills: how fast the bot can target you, and how fast the bot can think:

- ``skill 1`` - slow targeting / slow thinking
- ``skill 2`` - fast targeting / fast thinking
- ``skill 3`` - fastest targeting / fast thinking

So I turned off fast thinking for ``skill 2``.  This seems to slow them down just enough for me to feel like it's not a total blowout.

## Changelog

- Bots ``skill`` differences more appropriately scaled.
- Bots no longer try to follow each other in team deathmatch games.
- Bots will now appropriately choose your team color in coop games.
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