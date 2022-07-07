# Frikbot4 for Quake

A Quake mod for playing w/ multiplayer bots.

The Frikbot mod is one of the best Quake bots to play with.  This repo continues the development of some old code for an even older game.

## Install

See my other [repo](https://github.com/whipowill/quake-dir) where I've uploaded my Quake directory.

## History

I'm making a tiny change to a mod created by others:

- ``frikbot x`` - by FrikaC (I'm calling this ``frikbot1``)
- ``frikbot x+`` - by Igor9 (I'm calling this ``frikbot2``)
- ``firkbot x++`` - by JLaw (I'm calling this ``frikbot3``)

Which brings me to ``frikbot4``.  My change is very minimal.

## Problem

I spent a week playing w/ ``v3`` and had a blast, but what I found was that teamplay games didn't work so well.

It turns out there was a flaw in the bot logic that made them want to follow teammates around the map.  What ended up happening is the bots would clump together and just idle there.

I found the priority logic in the bot code and made following teammates a priority of zero.  I literally commented out a single line of code.

You can now play teamplay games and the bots are awesome, just like they are in FFA.

## Changelog

- Changed teammate following logic.
- Changed some bot names.

## Todo

I want to add item respawn on coop games.

## References

- [Deathmatch With Bots](https://steamcommunity.com/sharedfiles/filedetails/?id=123626484) - a guide I used to figure out what bot to use.
- [Frikbot X on ModDB](https://www.moddb.com/mods/frikbot-x) - where I found the missing campaign waypoint files.
- [Quake Bot Archive](https://github.com/Jason2Brownlee/QuakeBotArchive) - an archive of all Quake bot versions w/ a little history.
- [Quake Config Mod](https://www.moddb.com/downloads/quake-config-mod) - the mod I used for coop respawn of items.
- [Intro to QuakeC](https://codedocs.org/what-is/quakec) - page I found on how to compile QuakeC code.