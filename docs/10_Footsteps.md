# Docs | Footsteps

In ``world.qc``:

```
// player sounds
precache_sound ("walk/generic1.wav"); // SCARLET - footstep integration.
precache_sound ("walk/generic2.wav"); // SCARLET - footstep integration.
precache_sound ("walk/generic3.wav"); // SCARLET - footstep integration.
precache_sound ("walk/generic4.wav"); // SCARLET - footstep integration.
precache_sound ("walk/generic5.wav"); // SCARLET - footstep integration.
precache_sound ("walk/metal1.wav"); // SCARLET - footstep integration.
precache_sound ("walk/metal2.wav"); // SCARLET - footstep integration.
precache_sound ("walk/metal3.wav"); // SCARLET - footstep integration.
precache_sound ("walk/metal4.wav"); // SCARLET - footstep integration.
precache_sound ("items/itembk2.wav");       // item respawn sound
```

In ``player.qc``:

```
void()  player_run =[   $rockrun1,  player_run  ]
{
    ...

    // SCARLET - footsteps integration.
    if (self.walkframe == 1 || self.walkframe == 4 )
        if (checkbottom(self) == TRUE)
            if (self.waterlevel == 0)
                WalkSound (self);
    // SCARLET - end.

    self.walkframe = self.walkframe + 1;
}
```