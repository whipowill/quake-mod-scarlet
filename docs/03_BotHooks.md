# Docs | Bot Hooks

In ``client.qc``:

```
void() PlayerPreThink =
{
    if (BotPreFrame()) return; // SCARLET - bots integration.
```

```
void() PlayerPostThink =
{
    if (BotPostFrame()) return; // SCARLET - bots integration.
```

```
void() ClientConnect =
{
    ClientInRankings(); // SCARLET - bots integration.
```

```
void() ClientDisconnect =
{
    ClientDisconnected(); // SCARLET - bots integration.
```

In ``world.qc``:

```
void() worldspawn =
{
    ...
    BotInit(); // SCARLET - bots integration.
    InitBodyQue ();
```

```
void() StartFrame =
{
    BotFrame(); // SCARLET - bots integration.
```

Fix a problem in ``plats.qc``:

```
self.classname = "plat"; // SCARLET - bots integration (Lunaran commented this out?)
```

Fix a problem in ``client.qc``:

```
entity() SelectSpawnPoint =
{
    entity spot;
    float pcount;

    if (deathmatch)
    {
        return RandomSpawnLocation(); // SCARLET - bots integration.

        /*
        spot = lastspawn;
        pcount = ceil(random() * 4);
        while (pcount)
        {
            pcount--;

            spot = find(spot, classname, "info_player_deathmatch");
            if (spot == world)
                spot = find(world, classname, "info_player_deathmatch");
            if (spot == world)
                error("This map does not support deathmatch! (no spawn points)\n");
        }
        lastspawn = spot;
        return spot;
        */
    }
```