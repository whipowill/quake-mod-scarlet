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
    if (!cv_scarlet_melee) return;

    if (self.health <= 0) return;

    local float old_attack_finished = self.attack_finished;
    if (self.attack_finished_melee <= time)
    {
        // reset stance
        player_run();

        // change weapons (remember the weapon in hand, but not one that a swing or toss already swapped in)
        if (!self.is_swing) self.old_weapon = self.weapon;
        self.weapon = IT_AXE;

        // mark as in melee swing
        self.is_swing = 1;

        // change model
        self.weaponmodel = "progs/v_axe.mdl";

        // determine if we can lunge
        if (is_lunge && cv_scarlet_melee_lunge && self.attack_lunged_melee <= time && cv_scarlet_melee_lunge_speed > 0 && (cv_scarlet_melee_lunge_range > 0 || cv_scarlet_melee_lunge_always))
        {
            makevectors (self.v_angle);
            vector source = self.origin + '0 0 16';
            traceline (source, source + v_forward * cv_scarlet_melee_lunge_range, FALSE, self);
            float is_player = ((self != trace_ent) && (trace_ent.classname == "player" || trace_ent.classname == "monster_soldier" || trace_ent.classname == "monster_dog" || trace_ent.classname == "monster_ogre" || trace_ent.classname == "monster_knight"));
            if (is_player || cv_scarlet_melee_lunge_always)
            {
                // lunge in the direction you are facing at the lunge speed
                vector forward = normalize(v_forward) * cv_scarlet_melee_lunge_speed;

                // add a hop if on the ground (the hop replaces any up or down aim)
                forward_z = (self.flags & FL_ONGROUND) ? cv_scarlet_melee_lunge_hop : 0;

                self.velocity = forward;

                // the lunge can't be used again for a while
                self.attack_lunged_melee = time + cv_scarlet_melee_lunge_cooldown;

                // make jump sound
                //PlayerJump();
            }
        }

        // swing axe
        W_AxeSwing();

        self.attack_finished_melee = time + cv_scarlet_rof_axe;

        self.attack_finished = old_attack_finished;
        if (self.attack_finished < self.attack_finished_melee)
            self.attack_finished = self.attack_finished_melee;

        self.attack_counter_melee++;
    }
};

void() GrenadeAttack =
{
    if (!cv_scarlet_grenades) return;

    if (self.health <= 0) return;

    local float old_attack_finished = self.attack_finished;
    if (self.attack_finished_melee <= time && self.ammo_grenades > 0)
    {
        // change weapons (remember the weapon in hand, but not one that a swing or toss already swapped in)
        if (!self.is_swing) self.old_weapon = self.weapon;
        self.weapon = IT_GRENADE_LAUNCHER;

        // mark as in melee swing
        self.is_swing = 1;

        self.weaponmodel = string_null;

        // take away a grenade from our ammo
        self.ammo_grenades = self.ammo_grenades - 1;

        // log time at which grenades count will reset (if using time mechanism)
        self.grenades_time = time + cv_scarlet_grenades_restock;

        HandGrenadeThrow();

        self.attack_finished_melee = time + cv_scarlet_rof_hg;

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

    //self.ammo_rockets = self.ammo_rockets - cv_scarlet_dec_rockets;
    //W_SetCurrentAmmo();

    sound(self, CHAN_WEAPON, "halo3/weapons/frag_throw.wav", 1, ATTN_NORM);
    self.punchangle_x = -1 * cv_scarlet_kick_gl;

    // set grenade speed
    makevectors(self.v_angle);
    base = 200;
    if (self.v_angle_x)
        gvel = v_forward * base * 3 + v_up * base + crandom() * v_right * 10 + crandom() * v_up * 10;
    else
    {
        gvel = aim(self, 1000);
        gvel = gvel * base * 3;
        gvel_z = base;
    }

    g = spawn();
    g.owner = self;
    g.movetype = MOVETYPE_BOUNCE;
    g.solid = SOLID_BBOX;
    g.classname = "grenade";
    g.velocity = gvel;
    g.avelocity = '300 300 300';
    g.angles = vectoangles(g.velocity);
    g.touch = HandGrenadeTouch;
    g.nextthink = time + cv_scarlet_grenades_fuse; // make grenade explode quickly
    g.think = GrenadeExplode;
    setmodel(g, "progs/items/hipnotic/proxbomb_edited.mdl");
    setsize(g, '0 0 0', '0 0 0');
    setorigin(g, self.origin + v_forward * 8 + '0 0 16');
}

void() HandGrenadeTouch =
{
    if (other == self.owner) return;
    if (cv_scarlet_grenades_touch && other.takedamage == DAMAGE_AIM)
    {
        GrenadeExplode();
        return;
    }
    sound (self, CHAN_WEAPON, "halo3/weapons/frag_bnc_stone1.wav", 1, ATTN_NORM);
    if (self.velocity == '0 0 0')
        self.avelocity = '0 0 0';
}

// the player picked a weapon on purpose, so a swing or toss in progress must not put the old one back later
void() MeleeCancel =
{
    self.is_swing = 0;
    self.old_weapon = 0;
};

void() FixWeaponState =
{
    // if not in melee swing
    if (!self.is_swing) return;

    // if dead, bail
    if (self.health < 1) return;

    // if not weaponless or using an axe, bail
    if (self.weaponmodel != string_null && self.weaponmodel != "progs/v_axe.mdl") return;

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
        self.weaponmodel = "progs/v_axe.mdl";
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