# Licenses and credits

Scarlet is built on other people's work.  This file says who made what and on what terms it can be used.  It is a plain summary, not legal advice; the license texts and the original notices are the authority.

## The short version

- Scarlet's own code is free software under the **GNU General Public License, version 2** (see `LICENSE`).  Scarlet's QuakeC is built on id Software's Quake game source, which id released under the GPL version 2 in 1999.
- Quake itself is **not** included and not free.  You need your own copy of the game data (`id1/pak0.pak`, `id1/pak1.pak`).
- Some of the art and sound files that come with the mod were made by other people and are **not** covered by the GPL.  They are listed below.

## What is covered by the GPL (`LICENSE`)

Copyright (C) 2022-2026 whipowill, for everything written for Scarlet:

- the QuakeC changes in `src/` (the `src/scarlet/` files, the changes to id's files, and the bot changes in `src/frikbot/`);
- the Trailgen tool in `tools/trailgen/` (original code, standard library only);
- `default.cfg`, `quake.rc` and the documentation.

Under the GPL you may use, change and share this, but if you pass on a changed version you must pass it on under the same license with the source.  There is no warranty.

## id Software: the Quake game source

The base of the QuakeC code is id Software's Quake game source, copyright id Software, released under the GNU General Public License version 2 in December 1999.  The Quake game data (maps, models, sounds, textures) was not part of that release and remains id Software's.

## FrikBot

The bots are built on [FrikBot X](https://www.moddb.com/mods/frikbot-x) by Ryan "FrikaC" Smith, with Igor9 and JLaw.  FrikBot is in the public domain.  Its notice, which asks that any reproduction contain it in its entirety, stays at the top of each file in `src/frikbot/`:

> This program is in the Public Domain.  My crack legal team would like to add: RYAN "FRIKAC" SMITH IS PROVIDING THIS SOFTWARE "AS IS" AND MAKES NO WARRANTY, EXPRESS OR IMPLIED ...

Please keep those notices when you copy these files.  Scarlet's later changes to the bots (the Trailgen pathing, the skill handicaps, the fighting and dodging changes) are part of the GPL work above.  FrikBot's own documentation is no longer included.

## Other code

- The player name tag under the crosshair (`src/scarlet/nametags.qc`) began as a gist by BenVanCitters (<https://gist.github.com/BenVanCitters/a157f58e906bf00adc39a484cbcee12f>), modified by whipowill.  The gist states no license.
- Several features began as public QuakeC tutorials, modified by whipowill: head kicking (`src/scarlet/football.qc`) from Ivana, enemy bleeding (`src/scarlet/gore.qc`) from Maniac, and the footsteps pack from Seven.  The links are in the source files and in the README.  The tutorials state no license.
- The original waypoint files for the stock maps, by LightningHunter, are no longer used or included: Trailgen makes the waypoints now.
- FTEQCC, by Spike, compiles the QuakeC.  It is a tool and not part of the mod.

## Art and sound by other people

These folders hold files that were not written for Scarlet.  They are **not** covered by the GPL, their authors keep their rights, and being in this repository doesn't give you any right to reuse them.  The names below come from the folder names; the exact origin and terms of each file have not been checked, and need to be before this is shared widely.

| Files | What the name suggests |
| --- | --- |
| `progs/items/quoth/cross.mdl` | the health cross (only loaded when random powerups are on), from the Quoth mod |
| `progs/items/hipnotic/proxbomb_edited.mdl` | the hand grenade (only loaded when hand grenades are on), an edited model from the Hipnotic mission pack |
| `sound/halo3/` | weapon sounds that appear to be from Halo 3 |
| `sound/walk/` | footstep sounds, source not recorded |
| `progs/beam.mdl`, `gfx/conback.*`, `art/` | a beam model and the console background, source not recorded |

If you are the author of any of these and want something changed or removed, say so and it will be.

## The tools you need

Go (any recent version) builds Trailgen.  FTEQCC compiles the QuakeC.  Neither is included.
