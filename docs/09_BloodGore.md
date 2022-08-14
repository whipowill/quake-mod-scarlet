# Docs | Blood & Gore

For adding gore features (lots of blood) to the game, optionally activated w/ ``scarlet_gore 1`` in console.

In ``w_lightning.qc``:

```
void(vector start, vector limit, entity from, float damage) LightningBeam =
{
    ...
    if (trace_ent.takedamage && !(trace_ent.customflags & CFL_ZAPPED))
    {
        ...
        ThrowBloodSplatByLightning(start, trace_endpos, trace_ent, damage); // SCARLET - gore integration.
    }

    if (trace_ent.takedamage && !(trace_ent.customflags & CFL_ZAPPED))  // don't add damage to any target twice
    {
        ...
        ThrowBloodSplatByLightning(start, trace_endpos, trace_ent, damage); // SCARLET - gore integration.
    }

    ...
    if (trace_ent.takedamage && !(trace_ent.customflags & CFL_ZAPPED))
    {
        ...
        ThrowBloodSplatByLightning(start, trace_endpos, trace_ent, damage); // SCARLET - gore integration.
    }
}
```

In ``w_nails.qc``:

```
void() spike_touch =
{
    if (!CheckValidSpikeTouch()) return;

    if (self.dmg)
    {
        if (other.takedamage)
        {
            spawn_touchblood (self.dmg);
            T_Damage (other, self, self.trueowner, self.dmg);

            // SCARLET - gore integration.
            if (random() < 0.8)
            {
                self.angles_x = self.angles_x*-1;
                makevectors(self.angles);
                ThrowBloodSplat(v_forward, self.origin, other, self.dmg);
            }
            // SCARLET - end.
```

In ``w_rockets.qc``:

```
void() T_MissileExplode =
{
    ...

    // don't do radius damage to other, because all damage will be done in the impact
    T_RadiusDamage (self, self.trueowner, 120, other);

    ThrowBloodSplatByExplosion(self, 120); // SCARLET - gore integration.
}
...
void() GrenadeExplode =
{
    T_RadiusDamage (self, self.trueowner, 120, world);
    //T_GibDownedZombies (self, 120);

    ThrowBloodSplatByExplosion(self, 120); // SCARLET - gore integration.

    BecomeExplosion ();
}
```

In ``w_shotguns.qc``:

```
vector(float damage, vector dir) BulletImpact =
{
    ...
    if (trace_ent.takedamage)
    {
        ...
        if(random() < 0.4) ThrowBloodSplat(dir, trace_endpos, trace_ent, damage); // SCARLET - gore integration.
    }
    else gunshot(org);

    return org;
}
```

## Gibbable Corpses

This is for adding gibbable corpses to the game, optionally activated w/ ``scarlet_corpses 1`` in console.

This doesn't work in Copper-based mods due to how Lunaran does his "pass-thru" no-clipping code for dead bodies.

In all the monster files:

- Find and replace ``elf.solid = SOLID_NOT;`` w/ ``BecomeCorpse();``
- Add ``self.headmdl = "progs/h_demon.mdl";`` just above each ``setmodel (self, "progs/demon.mdl");``
    - Of course, you would reference the proper head model file for the monster type

## Kickable Heads

For adding football features (head kicking) to the game, optionally activated w/ ``scarlet_football 1`` in console.

In ``player.qc``:

```
void(string gibname, float dm) ThrowHead =
{
    ...
    //self.solid = SOLID_NOT;
    self.solid = SOLID_TRIGGER; // SCARLET - football integration.
    self.touch = KickGibs; // SCARLET - football integration.
```

You can optionally add this to ``ThrowGibs()`` also, but I think it looks better to only do this to heads.

In ``world.qc``:

```
void(entity ent) CopyToBodyQueue =
{
    bodyqueue_head.touch = ent.touch; // SCARLET - football integration.
    bodyqueue_head.solid = ent.solid; // SCARLET - football integration.
```