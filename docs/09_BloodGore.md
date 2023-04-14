# Docs | Blood & Gore

For adding gore features (lots of blood) to the game, optionally activated w/ ``scarlet_gore 1`` in console.

In ``meat.qc``:

```
void(vector org, vector vel, float damage) SpawnBlood =
{
    // SCARLET - gore integration.
    if (cvar("scarlet_gore"))
    {
            local float i;
            local float j = cvar("scarlet_gore"); // number of times to loop
            for (i=1; i<=j; i++)
            {
                    particle (org, vel*i, 64+(random()*12), damage*i);
            }
    }
    // SCARLET - end.

    particle (org, vel*0.1, 73, damage*2);
}

...

void(string headmdl, float dm) GibSpray =
{
    ThrowGib ("progs/gib1.mdl", dm);
    ThrowGib ("progs/gib2.mdl", dm);
    ThrowGib ("progs/gib3.mdl", dm);

    // SCARLET - gore integration.
    if (cvar("scarlet_gore"))
    {
        local float i;
        local float j = cvar("scarlet_gore"); // number of times to loop
        for (i=1; i<=j; i++)
        {
            ThrowGib ("progs/gib1.mdl", dm);
            ThrowGib ("progs/gib2.mdl", dm);
            ThrowGib ("progs/gib3.mdl", dm);
        }
    }
    // SCARLET - end.
```

In ``w_lightning.qc``:

```
// COMMENT OUT EVERY particle() referrence in the file!

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
                ThrowBloodSplat(v_forward, self.origin, other, self.dmg, 1);
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
        if(random() < 0.4) ThrowBloodSplat(dir, trace_endpos, trace_ent, damage, 2); // SCARLET - gore integration.
    }
    else gunshot(org);

    return org;
}
```

In ``w_axe.qc``:

```
void() W_FireAxe =
{
    ...

        org = trace_endpos - v_forward*4;

        if (trace_ent.takedamage)
        {
            trace_ent.customflags = trace_ent.customflags | CFL_AXEHITME;
            SpawnBlood (org, '0 0 0', cvar("scarlet_dmg_axe")); // was 20, SCARLET - custom dmg integration
            T_Damage (trace_ent, self, self, cvar("scarlet_dmg_axe")); // was 24, SCARLET - custom dmg integration.
            ThrowBloodSplat(org, trace_endpos, trace_ent, cvar("scarlet_dmg_axe"), 5); // SCARLET - gore integration.

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

In ``meat.qc``:

```
void(string gibname, float dm) ThrowHead =
{
    setmodel (self, gibname);
    self.frame = 0;
    self.nextthink = -1;
    self.movetype = MOVETYPE_BOUNCE;
    self.takedamage = DAMAGE_NO;
    self.solid = SOLID_TRIGGER; // SCARLET - football integration.
    self.touch = KickGibs; // SCARLET - football integration.
    self.view_ofs = '0 0 8';
    setsize (self, '-16 -16 0', '16 16 56');
    self.velocity += GibVelocityForHealth(dm);
    self.origin_z = self.origin_z - 24;
    self.flags = self.flags - (self.flags & FL_ONGROUND);
    self.type = "head";
    self.avelocity = crandom() * '0 600 0';
}
```

You can optionally add this to ``ThrowGibs()`` also, but I think it looks better to only do this to heads.

In ``world.qc``:

```
void(entity ent) CopyToBodyQueue =
{
    bodyqueue_head.touch = ent.touch; // SCARLET - football integration.
    bodyqueue_head.solid = ent.solid; // SCARLET - football integration.
```