//-------------------------------------------------
// Enable melee and grenade attacks.
// by whipowill
//-------------------------------------------------

.float ammo_grenades;
.float grenades_used;
.float grenades_time;

.float is_swing; // keep track of if player is in swing

.float attack_finished_melee; // timer for swings
.float attack_counter_melee; // counter for swings

.float attack_lunged_melee; // timer for lunges

void(float is_lunge = 1) AxeAttack =
{
    if (!cvar("scarlet_melee")) return;

    if (self.health <= 0) return;

    local float old_attack_finished = self.attack_finished;
    if (self.attack_finished_melee <= time)
    {
        // reset stance
        player_run();

        // mark as in melee swing
        self.is_swing = 1;

        // change weapons
        if (self.weapon != IT_AXE) self.old_weapon = self.weapon;
        self.weapon = IT_AXE;

        // change model
        self.weaponmodel = "progs/v_axe2.mdl";

        // determine if we can lunge
        if (cvar("scarlet_melee_lunge_dst") > 0 && is_lunge)
        {
            makevectors (self.v_angle);
            vector source = self.origin + '0 0 16';
            traceline (source, source + v_forward * cvar("scarlet_melee_lunge_dst"), FALSE, self);
            float is_player = ((self != trace_ent) && (trace_ent.classname == "player" || trace_ent.classname == "monster_soldier" || trace_ent.classname == "monster_dog" || trace_ent.classname == "monster_ogre" || trace_ent.classname == "monster_knight"));
            if (is_player)
            {
                // Normalize the v_forward vector
                vector forward = normalize(v_forward);

                // Project the v_forward vector onto the horizontal plane
                forward_z = (self.flags & FL_ONGROUND) ? cvar("scarlet_melee_lunge_ver") : 0; // this would be zero but we want a forced jump

                // Scale the projected vector by the desired lunge distance
                forward = forward * cvar("scarlet_melee_lunge_hor");

                // Assign the resulting vector to self.velocity
                self.velocity = forward;

                // make jump sound
                //PlayerJump();
            }
        }

        // swing axe
        W_AxeSwing();

        self.attack_finished_melee = time + cvar("scarlet_rof_axe");

        self.attack_finished = old_attack_finished;
        if (self.attack_finished < self.attack_finished_melee)
            self.attack_finished = self.attack_finished_melee;

        self.attack_counter_melee++;
    }
};

void() GrenadeAttack =
{
    if (!cvar("scarlet_grenades")) return;

    if (self.health <= 0) return;

    local float old_attack_finished = self.attack_finished;
    if (self.attack_finished_melee <= time && self.ammo_grenades > 0)
    {
        // mark as in melee swing
        self.is_swing = 1;

        // change weapons
        self.old_weapon = self.weapon;
        self.weapon = IT_GRENADE_LAUNCHER;

        self.weaponmodel = string_null;

        // take away a grenade from our ammo
        self.ammo_grenades = self.ammo_grenades - 1;

        // log time at which grenades count will reset (if using time mechanism)
        self.grenades_time = time + cvar("scarlet_grenades_restock");

        HandGrenadeThrow();

        self.attack_finished_melee = time + cvar("scarlet_rof_hg");

        self.attack_finished = old_attack_finished;
        if (self.attack_finished < self.attack_finished_melee)
            self.attack_finished = self.attack_finished_melee;
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
    if (cvar("scarlet_grenades_touch"))
        g.touch = HandGrenadeTouch;
    g.th_die = GrenadeExplode;
    SUB_ChangeModel(g, "progs/items/hipnotic/proxbomb_edited.mdl");
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
    // if not in melee swing
    if (!self.is_swing) return;

    // if dead, bail
    if (self.health < 1) return;

    // if not weaponless or using an axe, bail
    if (self.weaponmodel != string_null && self.weaponmodel != "progs/v_axe2.mdl") return;

    // if not ready for reset, bail
    if (self.attack_finished_melee > time) return;

    // change weapons back
    if (self.old_weapon)
    {
        self.weapon = self.old_weapon;
        self.old_weapon = 0;
    }

    // mark as NOT in melee swing
    self.is_swing = 0;

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

    W_ResetWeaponState();
}