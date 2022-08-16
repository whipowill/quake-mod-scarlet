# Docs | Custom Weapon Damage

In ``shooters.qc``:

```
e.classname = "superspike";
e.skin = 1;
e.dmg = cvar("scarlet_dmg_nails") * 2; // was 18, SCARLET - custom dmg integration.
```

In ``projectiles.qc``:

```
entity(vector org, vector vel) launch_nail =
{
    entity spike;
    
    spike = launch_projectile(org, vel, "spike");
    spike.touch = spike_touch;
    
    SUB_ChangeModel (spike, "progs/spike.mdl"); 
    spike.dmg = cvar("scarlet_dmg_nails"); // was 9, SCARLET - custom dmg integration.
    
    return spike;
}
...
entity(vector org, vector vel) launch_knightspike =
{
    entity spike;
    
    spike = launch_projectile(org, vel, "knightspike"); // FLYMISSILE
    spike.touch = spike_touch;
    SUB_ChangeModel (spike, "progs/k_spike.mdl");
    
    spike.dmg = cvar("scarlet_dmg_nails"); // was 8, SCARLET - custom dmg integration.
    
    return spike;
}
...
entity(vector org, vector vel) launch_wizspike =
{
    entity spike;
    
    spike = launch_projectile(org, vel, "wizspike");    // FLYMISSILE
    spike.touch = spike_touch;
    spike.dmg = cvar("scarlet_dmg_nails"); // was 9, SCARLET - custom dmg integration.
    SUB_ChangeModel (spike, "progs/w_spike.mdl");
    
    return spike;   
}
...
entity(vector org, vector vel) launch_laser =
{
    entity spike;
    
    spike = launch_projectile(org, vel, "laser");
    spike.touch = spike_touch;
    spike.effects = EF_DIMLIGHT;
    spike.movetype = MOVETYPE_FLY;  // enforcer lasers aren't FLYMISSILE in id106

    SUB_ChangeModel (spike, "progs/laser.mdl");

    spike.dmg = cvar("scarlet_dmg_cells") / 2; // was 12, SCARLET - custom dmg integration.
    
    return spike;
}
...
entity(vector org, vector vel) launch_rocket =
{
    entity missile;
    
    missile = launch_projectile(org, vel, "rocket");    // FLYMISSILE
    missile.dmg = cvar("scarlet_dmg_rockets"); // was 100, SCARLET - custom dmg integration.
    missile.touch = T_MissileTouch;
    missile.type = "missile";
    
    SUB_ChangeModel (missile, "progs/missile.mdl");
    
    return missile;
}
```

In ``w_axe.qc``:

```
SpawnBlood (org, '0 0 0', cvar("scarlet_dmg_axe")); // was 20, SCARLET - custom dmg integration
T_Damage (trace_ent, self, self, cvar("scarlet_dmg_axe")); // was 24, SCARLET - custom dmg integration.
```

In ``w_shotguns.qc``:

```
void(float shotcount, vector dir, vector spread) FireBullets =
{
    ...
    for (s = 0; s < shotcount; s++)
    {
        ...
        // check for trace-through cases
        for (ig = self; ig != world; lim++) // ig == world if we hit a wall or hit nothing
        {
            ...
            if (trace_ent.takedamage &&
                (trace_ent.flags & FL_MONSTER || trace_ent.classname == "player" ) &&
                // some id shootables are actually trigger_multiples with health and SOLID_BBOX, so this doesn't work (see e1m6):
                //( trace_ent.solid == SOLID_BBOX || trace_ent.solid == SOLID_SLIDEBOX ) &&
                HasBeenShotToDeath(trace_ent) )
            {
                local float calc = (cvar("scarlet_dmg_bullets")/2)+(cvar("scarlet_dmg_bullets")/2*random());
                BulletImpact (calc, direction); // was 2+2*random(), SCARLET - custom dmg integration.
                ...
            }
            ...
        }

        if (trace_fraction != 1.0)
        {
            BulletImpact (cvar("scarlet_dmg_bullets"), direction); // was 4, SCARLET - custom dmg integration.
        }
        ...
    }
}
...
void() W_FireShotgun =
{
    ...
    self.currentammo = self.ammo_shells = self.ammo_shells - cvar("scarlet_dec_bullets"); // was 1, SCARLET - custom ammo integration.
    ...
}
...
void() W_FireSuperShotgun =
{
    ...
    self.currentammo = self.ammo_shells = self.ammo_shells - (cvar("scarlet_dec_bullets") * 2); // was 2, SCARLET - custom ammo integration.
    ...
}
```

In ``w_nails.qc``:

```
void() W_FireNailgun =
{
    vector m, v, org, dir;
    // remember sv_aim
    v = vectoangles( aim( self, AUTOAIM_DIST ) );
    v_x *= -1;  // pitch comes back inverted from vectoangles :|
    makevectors( v );

    sound (self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
    self.currentammo = self.ammo_nails = self.ammo_nails - cvar("scarlet_dec_nails"); // was 1, SCARLET - custom ammo integration.
    ...
}
...
void() W_FirePerforator =
{
    ...
    self.currentammo = self.ammo_nails = self.ammo_nails - (cvar("scarlet_dec_nails") * 2); // was 2, SCARLET - custom ammo integration.
    ...

    if (has_quad(self))
    {
        ...
        spike2.dmg = cvar("scarlet_dmg_nails")*2; // SCARLET - custom dmg integration.
        spike1.dmg = cvar("scarlet_dmg_nails")*2; // SCARLET - custom dmg integration.
        ...
    }
    ...
}
```

In ``w_rockets.qc``:

```
void() T_MissileExplode =
{
    local float damg;
    damg = cvar("scarlet_dmg_rockets") - 20 + random()*20; // was 100, SCARLET - custom dmg integration.
    
    ...

    // don't do radius damage to other, because all damage will be done in the impact
    T_RadiusDamage (self, self.trueowner, cvar("scarlet_dmg_rockets"), other); // was 120, SCARLET - custom dmg integration.

    ThrowBloodSplatByExplosion(self, cvar("scarlet_dmg_rockets")); // SCARLET - gore integration.
}
...
void() W_FireRocket =
{
    local entity missile;
    local vector loc;

    self.currentammo = self.ammo_rockets = self.ammo_rockets - cvar("scarlet_dec_rockets"); // was 1, SCARLET - custom ammo integration.
    ...
}
...
void() GrenadeExplode =
{
    T_RadiusDamage (self, self.trueowner, cvar("scarlet_dmg_rockets"), world); // was 120, SCARLET - custom dmg integration.
    //T_GibDownedZombies (self, cvar("scarlet_dmg_rockets"));

    ThrowBloodSplatByExplosion(self, cvar("scarlet_dmg_rockets")); // SCARLET - gore integration.
    
    BecomeExplosion ();
}
...
void() W_FireGrenade =
{
    entity g;
    float base;
    vector gvel;

    self.currentammo = self.ammo_rockets = self.ammo_rockets - cvar("scarlet_dec_rockets"); // was 1, SCARLET - custom ammo integration.
    ...
}
```

In ``w_lightning.qc``:

```
void() W_FireLightning =
{
    ...
    self.currentammo = self.ammo_cells = self.ammo_cells - cvar("scarlet_dec_cells"); // was 1, SCARLET - custom ammo integration.
    ...
    ClearMultiDamage();
    LightningBeam(org, trace_endpos + v_forward * 8, self, cvar("scarlet_dmg_cells")); // was 30, SCARLET - custom dmg integration.
    ApplyMultiDamage();
```