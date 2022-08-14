# Docs | Score Keeper

In ``player.qc`` add:

```
void() PlayerDie =
{
    ...
    ClientObituary(); // moved from Killed() so it doesn't get called when non-players die

    if (ScoreKeeperEndgame()) execute_changelevel(); // SCARLET - team score integration.
```