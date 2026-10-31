// -------------------------------------------------
// Manage sending custom stats to client.
// by whipowill
// -------------------------------------------------

// functions needed (clientstat/globalstat are declared in defs.qc since Copper 1.30)

// globalstat was used for tracking players deaths and other info,
// like if the game is teamplay, etc for sending to the client
// to display on the HUD.  But this only worked in QSS-M and
// not vkQuake, so I had to turn it off.  Bc OpenGL got nerfed
// on Linux machines and vkQuake is now the best way to play.
// -whipowill

// my client vars (38-63; 32-37 are used by Copper 1.30) -whipowill
const float IT_GRENADES = 38;
const float GAME_TEAMPLAY = 39; // client mod turns on cl_teams when set
const float GAME_GRENADES = 40; // client mod shows grenades when set
const float GAME_DEATHS = 41; // client mod shows the deaths column when set
const float GAME_ASSISTS = 42; // client mod shows the assists column when set
const float GAME_MARKERS = 43; // client mod draws teammate markers through walls when set (2 also shows names)
const float GAME_MARKER_SCALE = 44; // client mod sizes the marker by this (percent)
const float GAME_NAMETAG = 45; // client mod prints the name of the player under the crosshair (client slot + 1, 0 = nobody)
const float GAME_KILLSTREAK_LABEL = 47; // the label of that streak, 3 letters in each of 6 stats (47-52), so up to 18 letters
const float GAME_STREAKS = 53; // client mod shows the Streak (best killstreak) column when set
const float GAME_KILLSTREAK = 46; // client mod shows the player's own killstreak as skulls at the bottom center (0 = none)
const float MARKER_STATS = 200; // 3 stats (forward, right, up) per client slot, 16 slots

// my global vars (128-255) -whipowill
const float SCORE_DEATHS = 131; // 32 slots
const float SCORE_ASSISTS = 163; // 32 slots
const float SCORE_STREAK = 64; // 32 slots (64-95), the best killstreak of the player
const float SCORE_SKILL = 96; // 16 slots (96-111), bot skill + 1 (0 = human)

float gametracker_scarlet, gametracker_teamplay, gametracker_grenades;


.float deaths;
.float assists;
.float old_weapon;
.float update_time;
.float stat_teamplay;
.float stat_markers_on;
.float stat_marker_scale;
.float stat_nametag;
.float stat_killstreak;
.float stat_kl0, stat_kl1, stat_kl2, stat_kl3, stat_kl4, stat_kl5;
.float mf0, mr0, mu0;
.float mf1, mr1, mu1;
.float mf2, mr2, mu2;
.float mf3, mr3, mu3;
.float mf4, mr4, mu4;
.float mf5, mr5, mu5;
.float mf6, mr6, mu6;
.float mf7, mr7, mu7;
.float mf8, mr8, mu8;
.float mf9, mr9, mu9;
.float mf10, mr10, mu10;
.float mf11, mr11, mu11;
.float mf12, mr12, mu12;
.float mf13, mr13, mu13;
.float mf14, mr14, mu14;
.float mf15, mr15, mu15;
.float stat_deaths_on;
.float stat_streaks_on;
.float best_killstreak; // the longest streak of kills in a row this map
.float stat_assists_on;
.float sd1, sd2, sd3, sd4, sd5, sd6, sd7, sd8, sd9, sd10, sd11, sd12, sd13, sd14, sd15, sd16; // deaths of the player at each alphabetical position
.float sa1, sa2, sa3, sa4, sa5, sa6, sa7, sa8, sa9, sa10, sa11, sa12, sa13, sa14, sa15, sa16; // assists of the player at each alphabetical position
.float sb1, sb2, sb3, sb4, sb5, sb6, sb7, sb8, sb9, sb10, sb11, sb12, sb13, sb14, sb15, sb16; // best killstreak of the player at each alphabetical position
.float ss1, ss2, ss3, ss4, ss5, ss6, ss7, ss8, ss9, ss10, ss11, ss12, ss13, ss14, ss15, ss16; // bot skill + 1 of the player at each alphabetical position
.float stat_grenades;

// this runs when client loads
void() StatsInit =
{
    // 1: string (4 stats carrying a total of 16 charactures)
    // 2: float (one stat, float converted to an integer for transportation)
    // 8: integer (one stat, not converted to an int, so this can be used to transport floats as floats - what a unique idea!)

    // client vars
    clientstat (IT_GRENADES, 2, ammo_grenades);
    clientstat (GAME_TEAMPLAY, 2, stat_teamplay);
    clientstat (GAME_GRENADES, 2, stat_grenades);

    // The HUD reads these as per-player stats by alphabetical position.  They used to be
    // globalstats, which vkQuake doesn't have, so every client gets its own copy instead.
    clientstat (GAME_MARKERS, 2, stat_markers_on);
    clientstat (GAME_MARKER_SCALE, 2, stat_marker_scale);
    clientstat (GAME_NAMETAG, 2, stat_nametag);
    clientstat (GAME_KILLSTREAK, 2, stat_killstreak);
    clientstat (GAME_KILLSTREAK_LABEL+0, 2, stat_kl0);
    clientstat (GAME_KILLSTREAK_LABEL+1, 2, stat_kl1);
    clientstat (GAME_KILLSTREAK_LABEL+2, 2, stat_kl2);
    clientstat (GAME_KILLSTREAK_LABEL+3, 2, stat_kl3);
    clientstat (GAME_KILLSTREAK_LABEL+4, 2, stat_kl4);
    clientstat (GAME_KILLSTREAK_LABEL+5, 2, stat_kl5);
    clientstat (MARKER_STATS+0, 2, mf0);
    clientstat (MARKER_STATS+1, 2, mr0);
    clientstat (MARKER_STATS+2, 2, mu0);
    clientstat (MARKER_STATS+3, 2, mf1);
    clientstat (MARKER_STATS+4, 2, mr1);
    clientstat (MARKER_STATS+5, 2, mu1);
    clientstat (MARKER_STATS+6, 2, mf2);
    clientstat (MARKER_STATS+7, 2, mr2);
    clientstat (MARKER_STATS+8, 2, mu2);
    clientstat (MARKER_STATS+9, 2, mf3);
    clientstat (MARKER_STATS+10, 2, mr3);
    clientstat (MARKER_STATS+11, 2, mu3);
    clientstat (MARKER_STATS+12, 2, mf4);
    clientstat (MARKER_STATS+13, 2, mr4);
    clientstat (MARKER_STATS+14, 2, mu4);
    clientstat (MARKER_STATS+15, 2, mf5);
    clientstat (MARKER_STATS+16, 2, mr5);
    clientstat (MARKER_STATS+17, 2, mu5);
    clientstat (MARKER_STATS+18, 2, mf6);
    clientstat (MARKER_STATS+19, 2, mr6);
    clientstat (MARKER_STATS+20, 2, mu6);
    clientstat (MARKER_STATS+21, 2, mf7);
    clientstat (MARKER_STATS+22, 2, mr7);
    clientstat (MARKER_STATS+23, 2, mu7);
    clientstat (MARKER_STATS+24, 2, mf8);
    clientstat (MARKER_STATS+25, 2, mr8);
    clientstat (MARKER_STATS+26, 2, mu8);
    clientstat (MARKER_STATS+27, 2, mf9);
    clientstat (MARKER_STATS+28, 2, mr9);
    clientstat (MARKER_STATS+29, 2, mu9);
    clientstat (MARKER_STATS+30, 2, mf10);
    clientstat (MARKER_STATS+31, 2, mr10);
    clientstat (MARKER_STATS+32, 2, mu10);
    clientstat (MARKER_STATS+33, 2, mf11);
    clientstat (MARKER_STATS+34, 2, mr11);
    clientstat (MARKER_STATS+35, 2, mu11);
    clientstat (MARKER_STATS+36, 2, mf12);
    clientstat (MARKER_STATS+37, 2, mr12);
    clientstat (MARKER_STATS+38, 2, mu12);
    clientstat (MARKER_STATS+39, 2, mf13);
    clientstat (MARKER_STATS+40, 2, mr13);
    clientstat (MARKER_STATS+41, 2, mu13);
    clientstat (MARKER_STATS+42, 2, mf14);
    clientstat (MARKER_STATS+43, 2, mr14);
    clientstat (MARKER_STATS+44, 2, mu14);
    clientstat (MARKER_STATS+45, 2, mf15);
    clientstat (MARKER_STATS+46, 2, mr15);
    clientstat (MARKER_STATS+47, 2, mu15);
    clientstat (GAME_DEATHS, 2, stat_deaths_on);
    clientstat (GAME_ASSISTS, 2, stat_assists_on);
    clientstat (SCORE_DEATHS+0, 2, sd1);
    clientstat (SCORE_DEATHS+1, 2, sd2);
    clientstat (SCORE_DEATHS+2, 2, sd3);
    clientstat (SCORE_DEATHS+3, 2, sd4);
    clientstat (SCORE_DEATHS+4, 2, sd5);
    clientstat (SCORE_DEATHS+5, 2, sd6);
    clientstat (SCORE_DEATHS+6, 2, sd7);
    clientstat (SCORE_DEATHS+7, 2, sd8);
    clientstat (SCORE_DEATHS+8, 2, sd9);
    clientstat (SCORE_DEATHS+9, 2, sd10);
    clientstat (SCORE_DEATHS+10, 2, sd11);
    clientstat (SCORE_DEATHS+11, 2, sd12);
    clientstat (SCORE_DEATHS+12, 2, sd13);
    clientstat (SCORE_DEATHS+13, 2, sd14);
    clientstat (SCORE_DEATHS+14, 2, sd15);
    clientstat (SCORE_DEATHS+15, 2, sd16);
    clientstat (SCORE_ASSISTS+0, 2, sa1);
    clientstat (SCORE_ASSISTS+1, 2, sa2);
    clientstat (SCORE_ASSISTS+2, 2, sa3);
    clientstat (SCORE_ASSISTS+3, 2, sa4);
    clientstat (SCORE_ASSISTS+4, 2, sa5);
    clientstat (SCORE_ASSISTS+5, 2, sa6);
    clientstat (SCORE_ASSISTS+6, 2, sa7);
    clientstat (SCORE_ASSISTS+7, 2, sa8);
    clientstat (SCORE_ASSISTS+8, 2, sa9);
    clientstat (SCORE_ASSISTS+9, 2, sa10);
    clientstat (SCORE_ASSISTS+10, 2, sa11);
    clientstat (SCORE_ASSISTS+11, 2, sa12);
    clientstat (SCORE_ASSISTS+12, 2, sa13);
    clientstat (SCORE_ASSISTS+13, 2, sa14);
    clientstat (SCORE_ASSISTS+14, 2, sa15);
    clientstat (SCORE_ASSISTS+15, 2, sa16);
    clientstat (GAME_STREAKS, 2, stat_streaks_on);
    clientstat (SCORE_STREAK+0, 2, sb1);
    clientstat (SCORE_STREAK+1, 2, sb2);
    clientstat (SCORE_STREAK+2, 2, sb3);
    clientstat (SCORE_STREAK+3, 2, sb4);
    clientstat (SCORE_STREAK+4, 2, sb5);
    clientstat (SCORE_STREAK+5, 2, sb6);
    clientstat (SCORE_STREAK+6, 2, sb7);
    clientstat (SCORE_STREAK+7, 2, sb8);
    clientstat (SCORE_STREAK+8, 2, sb9);
    clientstat (SCORE_STREAK+9, 2, sb10);
    clientstat (SCORE_STREAK+10, 2, sb11);
    clientstat (SCORE_STREAK+11, 2, sb12);
    clientstat (SCORE_STREAK+12, 2, sb13);
    clientstat (SCORE_STREAK+13, 2, sb14);
    clientstat (SCORE_STREAK+14, 2, sb15);
    clientstat (SCORE_STREAK+15, 2, sb16);
    clientstat (SCORE_SKILL+0, 2, ss1);
    clientstat (SCORE_SKILL+1, 2, ss2);
    clientstat (SCORE_SKILL+2, 2, ss3);
    clientstat (SCORE_SKILL+3, 2, ss4);
    clientstat (SCORE_SKILL+4, 2, ss5);
    clientstat (SCORE_SKILL+5, 2, ss6);
    clientstat (SCORE_SKILL+6, 2, ss7);
    clientstat (SCORE_SKILL+7, 2, ss8);
    clientstat (SCORE_SKILL+8, 2, ss9);
    clientstat (SCORE_SKILL+9, 2, ss10);
    clientstat (SCORE_SKILL+10, 2, ss11);
    clientstat (SCORE_SKILL+11, 2, ss12);
    clientstat (SCORE_SKILL+12, 2, ss13);
    clientstat (SCORE_SKILL+13, 2, ss14);
    clientstat (SCORE_SKILL+14, 2, ss15);
    clientstat (SCORE_SKILL+15, 2, ss16);
}

// assist tracking: when each attacker last damaged each victim, indexed by
// victim slot * 32 + attacker slot (slot = client number - 1)
float assist_time[1024];

.float slot_cache; // client slot + 1 (an entity's number never changes, so look it up once)
.float slot_bit;   // 2 to the power of the slot, for the marker bitmask
.float marker_mask; // which teammate slots had a marker last frame

// client slot (0-31) of a player entity, or -1
float(entity who) StatsSlot =
{
    local entity e;
    local float i, k, bit;

    if (who.slot_cache) return who.slot_cache - 1;

    e = nextent(world);
    i = 0;
    while (e && e != who && i < 32)
    {
        e = nextent(e);
        i = i + 1;
    }
    if (e != who || i >= 32) return -1;

    // cache the slot and its bit (2 to the power of the slot)
    bit = 1;
    for (k = 0; k < i; k = k + 1)
        bit = bit * 2;
    who.slot_cache = i + 1;
    who.slot_bit = bit;
    return i;
}

// true when two players are on the same team in a team game
float(entity a, entity b) StatsTeammates =
{
    return (teamplay && a.team > 0 && a.team == b.team);
}

// store one player's deaths and assists in a client's stat slot
void(entity to, float k, float d, float a, float s, float b) StatsSetSlot =
{
    if (k == 1) { to.sd1 = d; to.sa1 = a; to.ss1 = s; to.sb1 = b; }
    else if (k == 2) { to.sd2 = d; to.sa2 = a; to.ss2 = s; to.sb2 = b; }
    else if (k == 3) { to.sd3 = d; to.sa3 = a; to.ss3 = s; to.sb3 = b; }
    else if (k == 4) { to.sd4 = d; to.sa4 = a; to.ss4 = s; to.sb4 = b; }
    else if (k == 5) { to.sd5 = d; to.sa5 = a; to.ss5 = s; to.sb5 = b; }
    else if (k == 6) { to.sd6 = d; to.sa6 = a; to.ss6 = s; to.sb6 = b; }
    else if (k == 7) { to.sd7 = d; to.sa7 = a; to.ss7 = s; to.sb7 = b; }
    else if (k == 8) { to.sd8 = d; to.sa8 = a; to.ss8 = s; to.sb8 = b; }
    else if (k == 9) { to.sd9 = d; to.sa9 = a; to.ss9 = s; to.sb9 = b; }
    else if (k == 10) { to.sd10 = d; to.sa10 = a; to.ss10 = s; to.sb10 = b; }
    else if (k == 11) { to.sd11 = d; to.sa11 = a; to.ss11 = s; to.sb11 = b; }
    else if (k == 12) { to.sd12 = d; to.sa12 = a; to.ss12 = s; to.sb12 = b; }
    else if (k == 13) { to.sd13 = d; to.sa13 = a; to.ss13 = s; to.sb13 = b; }
    else if (k == 14) { to.sd14 = d; to.sa14 = a; to.ss14 = s; to.sb14 = b; }
    else if (k == 15) { to.sd15 = d; to.sa15 = a; to.ss15 = s; to.sb15 = b; }
    else if (k == 16) { to.sd16 = d; to.sa16 = a; to.ss16 = s; to.sb16 = b; }
}

void(entity to, float k, float f, float r, float u) StatsSetMarker =
{
    if (k == 0) { to.mf0 = f; to.mr0 = r; to.mu0 = u; }
    else if (k == 1) { to.mf1 = f; to.mr1 = r; to.mu1 = u; }
    else if (k == 2) { to.mf2 = f; to.mr2 = r; to.mu2 = u; }
    else if (k == 3) { to.mf3 = f; to.mr3 = r; to.mu3 = u; }
    else if (k == 4) { to.mf4 = f; to.mr4 = r; to.mu4 = u; }
    else if (k == 5) { to.mf5 = f; to.mr5 = r; to.mu5 = u; }
    else if (k == 6) { to.mf6 = f; to.mr6 = r; to.mu6 = u; }
    else if (k == 7) { to.mf7 = f; to.mr7 = r; to.mu7 = u; }
    else if (k == 8) { to.mf8 = f; to.mr8 = r; to.mu8 = u; }
    else if (k == 9) { to.mf9 = f; to.mr9 = r; to.mu9 = u; }
    else if (k == 10) { to.mf10 = f; to.mr10 = r; to.mu10 = u; }
    else if (k == 11) { to.mf11 = f; to.mr11 = r; to.mu11 = u; }
    else if (k == 12) { to.mf12 = f; to.mr12 = r; to.mu12 = u; }
    else if (k == 13) { to.mf13 = f; to.mr13 = r; to.mu13 = u; }
    else if (k == 14) { to.mf14 = f; to.mr14 = r; to.mu14 = u; }
    else if (k == 15) { to.mf15 = f; to.mr15 = r; to.mu15 = u; }
}

// Work out where each teammate appears relative to this player's view (forward, right and up
// components of the direction to their head, scaled to +-1000) so the HUD can draw a marker
// through walls.  vkQuake's HUD-only CSQC can't see other players, so the server does the math.
// A forward value of 0 means no marker for that slot.
void(entity player) StatsMarkers =
{
    local entity p;
    local vector org, d;
    local float slot, len, f, bit, newmask;

    if (!player.ishuman) return;

    player.stat_marker_scale = rint(100 * cv_scarlet_team_marker_scale);

    // 0 = off, 1 = markers only, 2 = markers with names
    player.stat_markers_on = 0;
    if (teamplay && cv_scarlet_team_markers)
        player.stat_markers_on = 1 + (cv_scarlet_team_marker_names > 0);

    // nothing to draw (and nothing left over from last frame to clear)
    if (!player.stat_markers_on || player.health <= 0)
    {
        if (!player.marker_mask) return;
    }
    else
    {
        makevectors(player.v_angle);
        org = player.origin + player.view_ofs;

        p = find(world, classname, "player");
        while (p)
        {
            if (p != player && p.health > 0 && p.team > 0 && p.team == player.team)
            {
                slot = StatsSlot(p);
                d = (p.origin + '0 0 44') - org;
                len = vlen(d);
                if (slot >= 0 && slot < 16 && len > 1)
                {
                    f = rint(1000 * (d * v_forward) / len);
                    if (f == 0) f = 1;
                    StatsSetMarker(player, slot, f, rint(1000 * (d * v_right) / len), rint(1000 * (d * v_up) / len));
                    newmask = newmask | p.slot_bit;
                }
            }
            p = find(p, classname, "player");
        }
    }

    // clear markers for players who left, died or stopped being visible teammates,
    // only when the set of marked players actually changed
    if (newmask != player.marker_mask)
    {
        bit = 1;
        for (slot = 0; slot < 16; slot = slot + 1)
        {
            if ((player.marker_mask & bit) && !(newmask & bit))
                StatsSetMarker(player, slot, 0, 0, 0);
            bit = bit * 2;
        }
        player.marker_mask = newmask;
    }
}

// copy everybody's deaths and assists into every client's stats
void() StatsShare =
{
    local entity to, who;

    to = find(world, classname, "player");
    while (to)
    {
        who = find(world, classname, "player");
        while (who)
        {
            StatsSetSlot(to, who.alphapos, who.deaths, who.assists, who.ishuman ? 0 : who.b_skill + 1, who.best_killstreak);
            who = find(who, classname, "player");
        }
        to = find(to, classname, "player");
    }
}

.float hit_mask; // monsters: which player slots (as bits) hurt it lately
.float hit_last; // monsters: when it was last hurt by a player

// a player hurt a monster: remember who, for assists, once the monster dies
void(entity monster, entity attacker, float damage) StatsMonsterHit =
{
    if (!(monster.flags & FL_MONSTER) || attacker.classname != "player" || damage <= 0) return;
    if (StatsSlot(attacker) < 0) return;

    // only the people who hurt it within the assist window count, so start over if it has been a while
    if (time - monster.hit_last > cv_scarlet_assist_window)
        monster.hit_mask = 0;
    monster.hit_mask = monster.hit_mask | attacker.slot_bit;
    monster.hit_last = time;
}

// a player killed a monster (single player and co-op): it is a kill, and everyone else who hurt it gets an assist
void(entity monster, entity killer) StatsMonsterKill =
{
    local entity p;

    if (killer.classname != "player") return;

    if (!deathmatch)
        killer.frags = killer.frags + 1;

    if (cv_scarlet_assist_window <= 0 || time - monster.hit_last > cv_scarlet_assist_window) return;
    p = find(world, classname, "player");
    while (p)
    {
        if (p != killer && StatsSlot(p) >= 0 && (monster.hit_mask & p.slot_bit))
            p.assists = p.assists + 1;
        p = find(p, classname, "player");
    }
    monster.hit_mask = 0;
}

// this runs when player gets hurt
void(entity player, entity attacker, float damage) StatsDamage =
{
    if (player.classname != "player")
    {
        StatsMonsterHit(player, attacker, damage);
        return;
    }

    // flag player as having been attacked (for shield recharge)
    player.last_damaged_time = time;

    // remember who hurt this player, for assists
    if (attacker.classname == "player" && attacker != player && damage > 0 && !StatsTeammates(player, attacker))
    {
        local float v, a;
        v = StatsSlot(player);
        a = StatsSlot(attacker);
        if (v >= 0 && a >= 0)
            assist_time[v * 32 + a] = time;
    }
}

// credit everyone who recently damaged the victim, except the killer
void(entity victim, entity killer) StatsAssists =
{
    local entity p;
    local float v, a, window;

    v = StatsSlot(victim);
    if (v < 0) return;
    window = cv_scarlet_assist_window;

    p = find(world, classname, "player");
    while (p)
    {
        a = StatsSlot(p);
        if (a >= 0 && assist_time[v * 32 + a])
        {
            if (p != killer && p != victim && window > 0 && time - assist_time[v * 32 + a] <= window)
                if (killer.classname == "player" && killer != victim)
                    p.assists = p.assists + 1;
            assist_time[v * 32 + a] = 0;
        }
        p = find(p, classname, "player");
    }
}

// kills, deaths and assists for every player, one line each
string() StatsScoreText =
{
    local entity p;
    local string s;

    s = "";
    p = find(world, classname, "player");
    while (p)
    {
        s = strcat(s, p.netname);
        s = strcat(s, ": ");
        s = strcat(s, ftos(p.frags));
        s = strcat(s, " frags, ");
        s = strcat(s, ftos(p.deaths));
        s = strcat(s, " deaths, ");
        s = strcat(s, ftos(p.assists));
        s = strcat(s, " assists\n");
        p = find(p, classname, "player");
    }
    return s;
}

// this runs when player dies
void(entity player, entity attacker) StatsDeath =
{
    // Don't put any player or attacker classname checks in
    // here bc it gets too complicated.  All these functions will
    // check it on their own as needed.

    // add to player deaths
    player.deaths = player.deaths + 1;

    // credit assists to anyone who helped the killer
    if (player.classname == "player")
        StatsAssists(player, attacker);

    // discontinue melee spam (if applicable)
    self.attack_counter_melee = 0;

    // killstreak integration
    KillstreakAdd(attacker);

    // some bot chat diologue
    if (attacker.classname == "player")
        if (player != attacker && !player.ishuman)
            bot_start_topic(5); // death chat
    if (attacker.classname == "teledeath")
        if (!player.ishuman)
            bot_start_topic(9.5); // ridicule chat

    // if using alternate death notices...
    if (cv_scarlet_chat_deaths == 2)
    {
        if (attacker.deathtype != string_null && attacker.classname != "player" )
        {
            bprint(player.netname);
            bprint(" died");
            bprint("\n");

            //if (deathmatch && (attacker.classname == "trigger_void" || attacker.classname == "func_void"))
                //player.frags = player.frags - 1;

            return;
        }
        if (attacker.classname == "teledeath")
        {
            bprint(attacker.owner.netname);
            bprint(" telefragged ");
            bprint(player.netname);
            bprint("\n");

            //if (deathmatch)
                //attacker.owner.frags = attacker.owner.frags + 1;

            return;
        }
        if (attacker.classname == "trigger_void" || attacker.classname == "func_void")
        {
            bprint(player.netname);
            bprint(" died");
            bprint("\n");

            //if (deathmatch)
                //player.frags = player.frags - 1;

            return;
        }
        if (attacker.classname == "teledeath2")
        {
            bprint(player.netname);
            bprint(" died");
            bprint("\n");

            //if (deathmatch)
                //player.frags = player.frags - 1;

            return;
        }

        if (attacker.classname == "player")
        {
            if (player == attacker)
            {
                bprint(player.netname);
                bprint(" committed suicide");
                bprint("\n");

                //if (deathmatch)
                    //attacker.frags = attacker.frags - 1;

                return;
            }

            if ( (teamplay == 2) && (player.team > 0) && (player.team == attacker.team) )
            {
                bprint(attacker.netname);
                bprint(" killed teammate ");
                bprint(player.netname);
                bprint("\n");

                //if (deathmatch)
                    //attacker.frags = attacker.frags - 1;

                return;
            }
            else
            {
                bprint(attacker.netname);
                bprint(" killed ");
                bprint(player.netname);
                bprint("\n");

                //if (deathmatch)
                    //attacker.frags = attacker.frags + 1;

                return;
            }
        }
    }
}

// this runs when player respawns
void(entity player) StatsRespawn =
{
    if (player.classname != "player") return;

    // reset stats
    player.ammo_grenades = cv_scarlet_grenades_min;

    // make sure player is in scorekeeper index
    ScoreKeeperAddPlayer(player, TRUE);
}

float scorekeeper_time; // next time the shared roster gets re-sorted

// this runs every frame
void(entity player) StatsUpdate =
{
    if (player.classname != "player") return;

    NameTag(); // SCARLET - nametags integration.
    KillstreakSkulls(player); // SCARLET - killstreak skulls integration.
    KillstreakStats(player); // SCARLET - killstreak HUD integration.
    RechargeShields(); // SCARLET - shields integration.

    // tell client some game settings
    gametracker_scarlet = 1;
    player.stat_deaths_on = 1;
    player.stat_streaks_on = 1;
    StatsMarkers(player);
    player.stat_assists_on = (cv_scarlet_assist_window > 0);
    gametracker_teamplay = teamplay;
    gametracker_grenades = cv_scarlet_grenades;
    player.stat_teamplay = teamplay;
    player.stat_grenades = gametracker_grenades;

    // if using time mechanism of restocking
    if (cv_scarlet_grenades_restock)
        if (player.grenades_time <= time) player.ammo_grenades = cv_scarlet_grenades_max;

    // if pulsing melee attack
    if (self.attack_counter_melee > 0)
    {
        if (self.attack_counter_melee < cv_scarlet_melee_spam)
            AxeAttack(0); // flag false for no lunge
        else
            self.attack_counter_melee = 0;
    }

    // if in melee/grenade swing, reset weapon state
    if (self.is_swing)
        FixWeaponState();

    if (time >= self.update_time)
    {
        // the roster is shared by all players and bots, so only re-sort it once per second
        // no matter how many of them run this block
        if (time >= scorekeeper_time)
        {
            scorekeeper_time = time + 1;
            AlphaKeeper(); // re-alphabetize list of players
            ScoreKeeper(); // re-rank players and teams
            StatsShare(); // sync everybody's deaths and assists to every client's HUD stats
        }

        // I never could figure out why the ScoreKeeperAddPlayer() being sent
        // from StatsDeath() didn't work right.  It was always off for
        // some reason.

        // team score integration
        ScoreKeeperAddPlayer(self, FALSE);
        ScoreKeeperEndgame();

        self.update_time = time + 1;
    }
}