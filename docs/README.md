# Docs | Intro

A walkthru of the inner-wrokings and integration of Scarlet.

## Bot Files

- ``bot.qc`` - declares variables and functions used in the core
- ``bot_ai.qc`` - the AI loop for making decisions about what to do
- ``bot_ed.qc`` - special code for waypoint editing and building
- ``bot_fight.qc`` - controls combat situations and fighting
- ``bot_misc.qc`` - random functions used throughout the core
- ``bot_move.qc`` - controls navigating obstructions and obsticles
- ``bot_phys.qc`` - helps the bot understand what is going on around him
- ``bot_qw.qc`` - same thing as ``bot.qc`` except for QuakeWorld engines
- ``bot_way.qc`` - produces a waypoint route table from a waypoint file

## Bot Summary

The bot has a pulse, a heartbeat, that runs every frame.  By the end of every pulse the bot has a target and a waypoint.

The target is the immediate goal -- it could be an item, an enemy, a teleporter, a door, whatever.  It's moving toward that target, or attacking that target.  The waypoint is the ultimate goal -- it will arrive there eventually, after it's dealt w/ all immediate targets.

The targets are fluctuating every pulse.  A priority system determines what the targets should be, and the bot considers up to 4 targets at a time.  As items are picked up, as enemies die, as teleporters are traveled thru, as doors open, new targets are added.

The waypoints are also fluctuating every pulse.  Where is the bot in the map, what is the closest waypoint that can be found?  When all the targets are cleared and there's nothing left to do, the bot will pick up the route and keep moving around the board.

Everything else in the bot programming is about the particulars of navigating targets and waypoints.  There is code for moving, jumping, meneuvering around obsticles, pushing buttons, waiting for elevators, not falling off cliff edges, etc.

## Integration Notes

The process for hooking into Copper, for when I have to do it again.

- Load Order
- Definitions
- Bot Hooks
- Map Rotation
- Item Resupply
- Custom Damage
- Score Keeper
- Name Tags
- Blood & Gore

## Special Thanks

- Command line utility ``ack`` for making it easy to search keywords in an entire directory.