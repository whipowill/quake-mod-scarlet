//-------------------------------------------------
// Enable melee and grenade attacks.
// by whipowill
//-------------------------------------------------

void() AxeAttack =
{
    if (self.attack_finished <= time)
    {
        player_run();
        self.weaponmodel = "progs/v_axe2.mdl";
        W_AxeSwing();
    }
};

void() GrenadeAttack =
{
    if (self.attack_finished <= time && self.ammo_rockets >= 1)
    {
        W_FireGrenadeCustom();
    }
};

void() W_FireGrenadeCustom =
{
    entity g;
    float base;
    vector gvel;

    self.ammo_rockets = self.ammo_rockets - cvar("scarlet_dec_rockets");
    W_SetCurrentAmmo();

    sound (self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);
    self.punchangle_x = -1 * cvar("scarlet_kick_gl");

    // set grenade speed
    makevectors (self.v_angle);
    base = 200;
    if (self.v_angle_x)
        gvel = v_forward * base * 3 + v_up * base + crandom() * v_right * 10 + crandom() * v_up * 10;
    else
    {
        gvel = aim(self, AUTOAIM_DIST);
        gvel = gvel * base * 3;
        gvel_z = base;
    }

    g = launch_grenade(self.origin, gvel);
    self.attack_finished = time + cvar("scarlet_rof_gl");
    g.touch = GrenadeTouch;
    g.th_die = GrenadeExplode;
}