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
local float calc = (cvar("scarlet_dmg_bullets")/2)+(cvar("scarlet_dmg_bullets")/2*random());
BulletImpact (calc, direction); // was 2+2*random(), SCARLET - custom dmg integration.
...
BulletImpact (cvar("scarlet_dmg_bullets"), direction); // was 4, SCARLET - custom dmg integration.
```

In ``w_nails.qc``:

```
spike2.dmg = cvar("scarlet_dmg_nails")*2; // SCARLET - custom dmg integration.
spike1.dmg = cvar("scarlet_dmg_nails")*2; // SCARLET - custom dmg integration.
spike2.buddy = spike1;
spike1.buddy = spike2;
```

In ``w_rockets.qc``:

```
void() T_MissileExplode =
{
    local float damg;
    damg = cvar("scarlet_dmg_rockets") - 20 + random()*20; // was 100, SCARLET - custom dmg integration.
    
    if (other.health)
    {
        if (other.classname == "monster_shambler")
            damg = damg * 0.5;
        if (other.type == "zombie")
            damg = max(damg, other.health + 25);    // so ogre rockets kill zombies despite being too weak
        T_Damage (other, self, self.trueowner, damg );
    }

    // don't do radius damage to other, because all damage will be done in the impact
    T_RadiusDamage (self, self.trueowner, cvar("scarlet_dmg_rockets"), other); // was 120, SCARLET - custom dmg integration.

    ThrowBloodSplatByExplosion(self, cvar("scarlet_dmg_rockets")); // SCARLET - gore integration.
}
...
void() GrenadeExplode =
{
    T_RadiusDamage (self, self.trueowner, cvar("scarlet_dmg_rockets"), world); // was 120, SCARLET - custom dmg integration.
    //T_GibDownedZombies (self, cvar("scarlet_dmg_rockets"));

    ThrowBloodSplatByExplosion(self, cvar("scarlet_dmg_rockets")); // SCARLET - gore integration.
    
    BecomeExplosion ();
}
```

In ``w_lightning.qc``:

```
ClearMultiDamage();
LightningBeam(org, trace_endpos + v_forward * 8, self, cvar("scarlet_dmg_cells")); // was 30, SCARLET - custom dmg integration.
ApplyMultiDamage();
```