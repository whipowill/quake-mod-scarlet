// -------------------------------------------------
// Enable Halo-style killstreak announcements.
// by whipowill
// -------------------------------------------------

.float killstreak;

// -------------------------------------------------
// Skulls (zombie heads) orbiting a player's feet, one more for every 5 kills in the streak.
// -------------------------------------------------

.float skulls_active; // how many skulls this player has out
.float skull_index; // which skull of the player's this is
.float streak_tier; // the tier of the player's streak (one per 5 kills), worked out when a kill comes in
.float skulls_want; // how many skulls the streak has earned, also worked out when a kill comes in (or a death)
.float skulls_check; // dev only: when to look at scarlet_dev_botskulls again
.float skulls_dev; // dev only: skulls_want came from scarlet_dev_botskulls
.float label_tier; // the tier the label sent to the HUD is for

float skulls_total; // every skull in the game
float SKULLS_MAX_TOTAL = 96; // never more than this in all, so a full server can't run out of entities

// the player's streak tier right now: 1 for every 5 kills in a row, 0 when dead
float(entity player) KillstreakTier =
{
    if (player.classname != "player" || player.deadflag || player.health < 1) return 0;
    if (intermission_running) return 0; // the effects go while the level ends, and come back with the next map
    if (cv_scarlet_dev_botskulls > 0) return cv_scarlet_dev_botskulls; // dev: every player and bot is at this tier, whatever its streak
    return player.streak_tier;
};

// the tier the visual effects go by: none at all with scarlet_killstreak_vfx off (the healing, the scoreboard and the
// chat notices use KillstreakTier and never go off)
float(entity player) KillstreakVfxTier =
{
    if (!cv_scarlet_killstreak_vfx) return 0;
    return KillstreakTier(player);
};

// how many skulls the player's streak has earned right now
float(entity player) KillstreakSkullsWanted =
{
    local float n;

    if (!cv_scarlet_killstreak_vfx_skulls) return 0;

    n = KillstreakVfxTier(player);
    if (n > cv_scarlet_killstreak_vfx_skulls_max) n = cv_scarlet_killstreak_vfx_skulls_max;
    return n;
};

void() SkullThink =
{
    local entity p;
    local float want, ang, puffs;
    local vector org;

    p = self.owner;
    want = p.skulls_want;
    if (!cv_scarlet_killstreak_vfx || p.classname != "player" || p.deadflag || p.health < 1 || intermission_running || self.skull_index >= want)
    {
        skulls_total = skulls_total - 1;
        remove(self);
        return;
    }

    // evenly spaced around the player, all turning together
    ang = time * cv_scarlet_killstreak_vfx_skulls_speed + self.skull_index * 360 / want;
    makevectors('0 1 0' * ang);
    org = p.origin + v_forward * cv_scarlet_killstreak_vfx_skulls_radius;
    org_z = p.absmin_z + cv_scarlet_killstreak_vfx_skulls_height; // above the floor under the player's feet
    setorigin(self, org);
    // facing out from the player: the zombie head's face is up in the model, so tip it forward (the pitch is a cvar in case that is the wrong way) and turn it to look along the ring's radius
    self.angles = '0 1 0' * ang + '1 0 0' * cv_scarlet_killstreak_vfx_skulls_pitch;

    // the bleeding: scarlet_killstreak_vfx_skulls_blood is the amount, and a think sends about 0.6 of a puff for every
    // 1 of it (each puff is a message to everybody).  each puff is a different red from the ramp 72-79 and stays
    // where it is made, so the skulls going round leave a ring of it behind them
    if (cv_scarlet_killstreak_vfx_skulls_blood > 0)
    {
        puffs = cv_scarlet_killstreak_vfx_skulls_blood * 0.6;
        while (puffs > 0)
        {
            if (puffs >= 1 || random() < puffs)
                particle(self.origin, '0 0 0', 72 + floor(random() * 8), 3);
            puffs = puffs - 1;
        }
    }

    self.nextthink = time + 0.05;
};

float(entity player, float index) SkullSpawn =
{
    local entity s;

    if (skulls_total >= SKULLS_MAX_TOTAL) return FALSE;

    s = spawn();
    s.classname = "killstreak_skull";
    s.owner = player;
    s.skull_index = index;
    s.movetype = MOVETYPE_STEP; // so the clients smooth out the 20 moves a second
    s.flags = FL_FLY; // and gravity leaves it alone
    s.solid = SOLID_NOT;
    setmodel(s, "progs/h_zombie.mdl");
    setsize(s, '0 0 0', '0 0 0');
    setorigin(s, player.origin);
    s.think = SkullThink;
    s.nextthink = time + 0.05;
    skulls_total = skulls_total + 1;
    return TRUE;
};

// called every frame for every player: brings in the skulls a new 5 kills has earned (they remove themselves when they are too many)
void(entity player) KillstreakSkulls =
{
    local float want;

    // the count is worked out when a kill or a death changes the streak (KillstreakAdd, KillstreakReset).  Only the
    // developer setting can change it in between, so only that is looked at, once a second
    if ((cv_scarlet_dev_botskulls > 0 || player.skulls_dev) && time >= player.skulls_check)
    {
        player.skulls_check = time + 1;
        player.skulls_dev = (cv_scarlet_dev_botskulls > 0);
        player.skulls_want = KillstreakSkullsWanted(player);
    }
    want = player.skulls_want;
    if (want < player.skulls_active)
        player.skulls_active = want;
    while (player.skulls_active < want)
    {
        if (!SkullSpawn(player, player.skulls_active)) return;
        player.skulls_active = player.skulls_active + 1;
    }
};

// -------------------------------------------------
// A swirl of blood at the feet of a player on a streak.  No entities, just particle messages: a few every
// tenth of a second, placed around a ring that turns, so they trail round the player.  Every tier
// (5 kills) adds particles, widens the ring and raises the swirl, and every second tier adds another arm.
// -------------------------------------------------

.float swirl_next; // when the next puff is due

void(entity player) KillstreakSwirl =
{
    local float tier, arms, count, i, ang, radius;
    local vector org, tangent;

    if (!cv_scarlet_killstreak_vfx_swirl) return;
    if (time < player.swirl_next) return;
    tier = KillstreakVfxTier(player);
    if (tier < 1) return;
    player.swirl_next = time + 0.1;

    // pulses: a wave of blood leaves the player's feet and travels outward, and the higher the streak the quicker
    // the waves follow each other, so more of them are in the air at once
    if (cv_scarlet_killstreak_vfx_swirl_style == 1)
    {
        radius = 1.3 - 0.12 * tier; // seconds between waves
        if (radius < 0.3) radius = 0.3;
        ang = floor(time / radius); // the number of the wave
        if (time - ang * radius < 0.2) // a wave is sent for the first two puffs
        {
            i = 0;
            while (i < 12)
            {
                makevectors('0 1 0' * (i * 30 + ang * 15)); // each wave is turned a little from the last
                org = player.origin + v_forward * cv_scarlet_killstreak_vfx_swirl_radius;
                org_z = player.absmin_z + 4;
                particle(org, v_forward * 7 + '0 0 0.5', 72 + floor(random() * 8), 2); // outward, about 100 units a second, each puff a different red
                i = i + 1;
            }
        }
        return;
    }

    // disc: a flat spiral of blood, all on one plane just above the floor, turning slowly round the player's feet like
    // a record.  One arm to begin with and another every 3 tiers (3 at most), each dotted with a few puffs from the
    // middle out, and the further out a puff the more its arm has curled back.  Dark reds, to stay quiet
    if (cv_scarlet_killstreak_vfx_swirl_style == 3)
    {
        player.swirl_next = time + 0.2; // slower than the other styles' tick, it is only a glow
        arms = 1 + floor((tier - 1) / 3);
        if (arms > 3) arms = 3;
        i = 0;
        while (i < arms)
        {
            count = 1;
            while (count <= 4)
            {
                radius = cv_scarlet_killstreak_vfx_swirl_radius * (0.25 + count * 0.25) * 1.4; // 4 puffs from near the middle out
                ang = time * cv_scarlet_killstreak_vfx_swirl_speed * 0.25 + i * 360 / arms + count * 35; // the curl
                makevectors('0 1 0' * ang);
                org = player.origin + v_forward * radius;
                org_z = player.absmin_z + 3; // the one plane
                particle(org, '0 0 0', 66 + floor(random() * 8), 1); // reds 66 to 73, none of the brightest
                count = count + 1;
            }
            i = i + 1;
        }
        return;
    }

    // vortex: blood climbs from the feet to the head in a spiral, one more strand for every 2 tiers.  Every strand
    // is dotted with puffs up its height that move up the player as time goes, so it reads as a helix turning round
    if (cv_scarlet_killstreak_vfx_swirl_style == 2)
    {
        arms = 1 + floor(tier / 2);
        if (arms > 4) arms = 4;
        i = 0;
        while (i < arms)
        {
            count = 0;
            while (count < 4)
            {
                radius = (time * 0.8 + count * 0.25) - floor(time * 0.8 + count * 0.25); // 0 at the feet, 1 at the head
                ang = time * cv_scarlet_killstreak_vfx_swirl_speed + radius * 540 + i * 360 / arms;
                makevectors('0 1 0' * ang);
                org = player.origin + v_forward * (cv_scarlet_killstreak_vfx_swirl_radius * (1 - radius * 0.4));
                org_z = player.absmin_z + 4 + radius * 52;
                particle(org, '0 0 6', 72 + floor(random() * 8), 2);
                count = count + 1;
            }
            i = i + 1;
        }
        return;
    }

    arms = 1 + floor(tier / 2);
    if (arms > 4) arms = 4;
    count = 3 + 2 * tier;
    if (count > 20) count = 20;
    radius = cv_scarlet_killstreak_vfx_swirl_radius + 2 * tier;

    i = 0;
    while (i < arms)
    {
        ang = time * cv_scarlet_killstreak_vfx_swirl_speed + i * 360 / arms;
        makevectors('0 1 0' * ang);
        org = player.origin + v_forward * radius;
        org_z = player.absmin_z + 4 + tier; // from the feet, a little higher with the streak
        tangent = '0 0 0' - v_right; // along the ring
        particle(org, tangent * 3 + '0 0 2', 72 + floor(random() * 8), count); // each arm a different red
        i = i + 1;
    }
};

// -------------------------------------------------
// Killstreak on the HUD: the HUD mod draws the player's own streak at the bottom center, a skull for every 5 kills.
// Nobody else's streak is sent, so the HUD can't be made to show where other players are.
// -------------------------------------------------

float(string s) strlen = #114;
float(string s, float index) str2chr = #222;

// three letters of a label in one number (a stat can carry 24 bits exactly), counting from letter i * 3
float(string s, float i) KillstreakPack =
{
    local float n, a, b, c;

    n = strlen(s);
    if (i * 3 < n) a = str2chr(s, i * 3);
    if (i * 3 + 1 < n) b = str2chr(s, i * 3 + 1);
    if (i * 3 + 2 < n) c = str2chr(s, i * 3 + 2);
    return a + b * 256 + c * 65536;
};

// called every frame for every player
void(entity player) KillstreakStats =
{
    KillstreakSwirl(player);

    if (!player.ishuman) return;

    player.stat_killstreak = 0;
    if (player.health > 0 && !intermission_running && cv_scarlet_killstreak_vfx)
    {
        player.stat_killstreak = player.killstreak;
        if (cv_scarlet_dev_botskulls > 0)
            player.stat_killstreak = 5 * cv_scarlet_dev_botskulls; // dev: the HUD shows the same tier
    }
    local string label;
    local float tier;
    tier = KillstreakVfxTier(player);
    if (tier != player.label_tier)
    {
        player.label_tier = tier;
        label = KillstreakLabel(tier);
        player.stat_kl0 = KillstreakPack(label, 0);
        player.stat_kl1 = KillstreakPack(label, 1);
        player.stat_kl2 = KillstreakPack(label, 2);
        player.stat_kl3 = KillstreakPack(label, 3);
        player.stat_kl4 = KillstreakPack(label, 4);
        player.stat_kl5 = KillstreakPack(label, 5);
    }
};

void(entity player) KillstreakReset =
{
    if (player.killstreak >= 5 && cv_scarlet_chat_killstreaks)
    {
        bprint(player.netname);
        bprint("'s kill streak has ended (");
        bprint(ftos(player.killstreak));
        bprint(").\n");
    }

    player.killstreak = 0;
    player.streak_tier = 0;
    player.skulls_want = 0;
}

// The label of a streak tier (one tier per 5 kills).  The HUD shows it, and it is what a streak is announced as.
// The HUD has room for 16 characters.
string(float tier) KillstreakLabel =
{
    if (tier == 1) return "Cutthroat";
    if (tier == 2) return "Gore Hound";
    if (tier == 3) return "Slaughterhouse";
    if (tier == 4) return "Crimson Tide";
    if (tier == 5) return "Nightmare";
    if (tier == 6) return "Boogeyman";
    if (tier == 7) return "Grim Reaper";
    if (tier >= 8) return "Demon";
    return "";
};

void(entity player) KillstreakAdd =
{
    local float tier;

    if (player.classname != "player") return;

    player.killstreak = player.killstreak + 1;
    if (player.killstreak > player.best_killstreak)
        player.best_killstreak = player.killstreak;
    // every 5 kills in a row is a new tier: the one place the tier, the skulls and the announcement are worked out
    tier = player.killstreak / 5;
    if (tier >= 1 && tier == floor(tier))
    {
        player.streak_tier = tier;
        player.skulls_want = KillstreakSkullsWanted(player);

        if (cv_scarlet_chat_killstreaks && tier <= 8)
        {
            bprint(player.netname);
            bprint(" is a ");
            bprint(KillstreakLabel(tier));
            bprint("!\n");
        }
    }
}
