# Docs | Automatic Map Rotation

In ``t_level.qc``:

```
void() GotoNextMap =
{
    // SCARLET - automatic map rotation integration.
    if (deathmatch)
    {
        local float p;
        p = cvar("samelevel");
        if (p > 1)
        {
            localcmd("map");
            localcmd(ftos(ceil(random() * p)));
            localcmd("\n");
            return;
        }
        else if (p < 0)
        {
            localcmd("map");
            localcmd(ftos(floor(serverflags/16)+1));
            localcmd("\n");
            serverflags = serverflags+16;
            if (floor((serverflags/16)+1) > (0 - p)) {
                serverflags = serverflags & 16;
            }
            return;
        }
    }
    // SCARLET - end.

    ...
}
```