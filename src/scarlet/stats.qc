// -------------------------------------------------
// Manage sending custom stats to client.
// by whipowill
// -------------------------------------------------

void(float index, float type, .float field) addstatf = #232;

// for game vars I'm using 33-63
const float VAR_TEAMPLAY = 33;
const float VAR_GRENADES = 34;

// for player stats I'm using 128-255
const float IT_GRENADES = 128;

.float teamplaytracker;
.float grenadestracker;

void() StatsInit =
{
    // for AddStat 2nd argument
    // 1: string (4 stats carrying a total of 16 charactures)
    // 2: float (one stat, float converted to an integer for transportation)
    // 8: integer (one stat, not converted to an int, so this can be used to transport floats as floats - what a unique idea!)

    addstatf (VAR_TEAMPLAY, 2, teamplaytracker);
    addstatf (VAR_GRENADES, 2, grenadestracker);
    addstatf (IT_GRENADES, 2, ammo_grenades);
}

void() StatsReset =
{
    self.ammo_grenades = cvar("scarlet_grenades_min");
}

void() StatsUpdate =
{
    // HACK: the only way to pass these vars to CSQC is as player stat!

    // tell client this is a team game
    self.teamplaytracker = teamplay;

    // tell client this is grenades game
    self.grenadestracker = cvar("scarlet_grenades");

    // if using time mechanism of restocking
    if (cvar("scarlet_grenades_restock"))
        if (self.grenades_time <= time) self.ammo_grenades = cvar("scarlet_grenades_max");
}