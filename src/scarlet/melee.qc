//-------------------------------------------------
// Enable melee and grenade attacks.
// by whipowill
//-------------------------------------------------

.float grenades_used;
.float grenades_time;

void() AxeAttack =
{
    if (!cvar("scarlet_melee")) return;

    if (self.health <= 0) return;

    if (self.attack_finished <= time)
    {
        player_run();
        self.weaponmodel = "progs/v_axe2.mdl";
        W_AxeSwing();
    }
};

void() GrenadeAttack =
{
    if (!cvar("scarlet_grenades")) return;

    if (self.health <= 0) return;

    if (self.grenades_time <= time) self.grenades_used = 0;

    if (self.attack_finished <= time && self.grenades_used < cvar("scarlet_grenades_max")) //self.ammo_rockets >= 1
    {
        self.weaponmodel = string_null;
        self.grenades_used = self.grenades_used + 1;
        self.grenades_time = time + cvar("scarlet_grenades_cooldown");

        HandGrenadeThrow();
    }
};

void() HandGrenadeThrow =
{
    entity g;
    float base;
    vector gvel;

    //self.ammo_rockets = self.ammo_rockets - cvar("scarlet_dec_rockets");
    //W_SetCurrentAmmo();

    sound(self, CHAN_WEAPON, "halo3/weapons/frag_throw.wav", 1, ATTN_NORM);
    self.punchangle_x = -1 * cvar("scarlet_kick_gl");

    // set grenade speed
    makevectors(self.v_angle);
    base = 200;
    if (self.v_angle_x)
        gvel = v_forward * base * 3 + v_up * base + crandom() * v_right * 10 + crandom() * v_up * 10;
    else
    {
        gvel = aim(self, AUTOAIM_DIST);
        gvel = gvel * base * 3;
        gvel_z = base;
    }

    g = toss_projectile(self.origin, gvel, "grenade");
    g.avelocity = '300 300 300';
    g.lifetime_finished = time + cvar("scarlet_grenades_fuse"); // make grenade explode quickly
    g.touch = HandGrenadeTouch;
    g.th_die = GrenadeExplode;
    SUB_ChangeModel(g, "progs/items/hipnotic/proxbomb_edited.mdl");

    self.attack_finished = time + cvar("scarlet_rof_gl");
}

void() HandGrenadeTouch =
{
    if (other == self.owner) return;
    if (CheckProjectilePassthru()) return;
    if (other.takedamage == DAMAGE_AIM)
    {
        self.velocity = '0 0 0';
        T_MissileExplode();
        T_ExplosiveTouch();
        return;
    }
    sound (self, CHAN_WEAPON, "halo3/weapons/frag_bnc_stone1.wav", 1, ATTN_NORM);
    if (self.velocity == '0 0 0')
        self.avelocity = '0 0 0';
}

void() FixWeaponState =
{
    if (self.weaponmodel != string_null && self.weaponmodel != "progs/v_axe2.mdl")
        return;

    if (self.weapon == IT_AXE)
        self.weaponmodel = "progs/v_axe2.mdl";
    else if (self.weapon == IT_SHOTGUN)
        self.weaponmodel = "progs/v_shot.mdl";
    else if (self.weapon == IT_SUPER_SHOTGUN)
        self.weaponmodel = "progs/v_shot2.mdl";
    else if (self.weapon == IT_NAILGUN)
        self.weaponmodel = "progs/v_nail.mdl";
    else if (self.weapon == IT_SUPER_NAILGUN)
        self.weaponmodel = "progs/v_nail2.mdl";
    else if (self.weapon == IT_GRENADE_LAUNCHER)
        self.weaponmodel = "progs/v_rock.mdl";
    else if (self.weapon == IT_ROCKET_LAUNCHER)
        self.weaponmodel = "progs/v_rock2.mdl";
    else if (self.weapon == IT_LIGHTNING)
        self.weaponmodel = "progs/v_light.mdl";
    else
        self.weaponmodel = string_null;
}