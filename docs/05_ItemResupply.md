# Docs | Item Resupply

This is for making all items respawn on coop and singleplayer, optionally activated w/ ``scarlet_resupply 1`` in console.

This is hard to show snippets of where to make code changes.

Basically you're going into ``item_*.qc`` files and search for ``coop``.  You replace that with ``cvar("scarlet_resupply")`` and make sure the logic checks out on all the IF statements.