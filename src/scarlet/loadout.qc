//-------------------------------------------------
// Enable custom loadouts.
// by whipowill
//-------------------------------------------------

float() LoadoutParamOne =
{
    local float r;

    local float desired = cvar("weapons");
    if (desired)
    {
        if (desired == 2) r = IT_SHOTGUN | IT_AXE;
        else if (desired == 3) r = IT_SUPER_SHOTGUN | IT_AXE;
        else if (desired == 4) r = IT_NAILGUN | IT_AXE;
        else if (desired == 5) r = IT_SUPER_NAILGUN | IT_AXE;
        else if (desired == 6) r = IT_GRENADE_LAUNCHER | IT_AXE;
        else if (desired == 7) r = IT_ROCKET_LAUNCHER | IT_AXE;
        else if (desired == 8) r = IT_LIGHTNING | IT_AXE;

        return r;
    }

    r = IT_SHOTGUN | IT_AXE;
    if (cvar("scarlet_limited")) r = IT_SUPER_SHOTGUN | IT_AXE;

    return r;
};

float() LoadoutParamEight =
{
    local float r;

    local float desired = cvar("weapons");
    if (desired)
    {
        if (desired == 2) r = IT_SHOTGUN;
        else if (desired == 3) r = IT_SUPER_SHOTGUN;
        else if (desired == 4) r = IT_NAILGUN;
        else if (desired == 5) r = IT_SUPER_NAILGUN;
        else if (desired == 6) r = IT_GRENADE_LAUNCHER;
        else if (desired == 7) r = IT_ROCKET_LAUNCHER;
        else if (desired == 8) r = IT_LIGHTNING;

        return r;
    }

    r = IT_SHOTGUN;
    if (cvar("scarlet_limited")) r = IT_SUPER_SHOTGUN;

    return r;
};

float() LoadoutParamShells =
{
    local float desired = cvar("weapons");
    if (desired == 2 || desired == 3 || !desired) return 25;

    return 0;
};

float() LoadoutParamNails =
{
    local float desired = cvar("weapons");
    if (desired == 4 || desired == 5) return 25;

    return 0;
};

float() LoadoutParamRockets =
{
    local float desired = cvar("weapons");
    if (desired == 6 || desired == 7) return 25;

    return 0;
};

float() LoadoutParamCells =
{
    local float desired = cvar("weapons");
    if (desired == 8) return 25;

    return 0;
};

float(float type) LoadoutWeaponCheck =
{
    local float desired = cvar("weapons");

    if (!desired) return 1;

    return (desired == type) ? 1 : 0;
};

void() LoadoutWeaponOverride =
{
    local float desired = cvar("weapons");

    if (desired == 2)
    {
        weapon_shotgun();
    }
    else if (desired == 3)
    {
        weapon_supershotgun();
    }
    else if (desired == 4)
    {
        weapon_nailgun();
    }
    else if (desired == 5)
    {
        weapon_supernailgun();
    }
    else if (desired == 6)
    {
        weapon_grenadelauncher();
    }
    else if (desired == 7)
    {
        weapon_rocketlauncher();
    }
    else if (desired == 8)
    {
        weapon_lightning();
    }
};

float(float type) LoadoutAmmoCheck =
{
    local float desired = cvar("weapons");

    if (!desired) return 1;

    if (desired == 2) desired = 3;
    else if (desired == 4) desired = 5;
    else if (desired == 6) desired = 7;

    return (desired == type) ? 1 : 0;
};

void() LoadoutAmmoOverride =
{
    local float desired = cvar("weapons");

    if (desired == 2)
    {
        item_shells();
    }
    else if (desired == 3)
    {
        item_shells();
    }
    else if (desired == 4)
    {
        item_spikes();
    }
    else if (desired == 5)
    {
        item_spikes();
    }
    else if (desired == 6)
    {
        item_rockets();
    }
    else if (desired == 7)
    {
        item_rockets();
    }
    else if (desired == 8)
    {
        item_cells();
    }
};