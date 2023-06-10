// -------------------------------------------------
// Manage sending custom stats to client.
// by whipowill
// -------------------------------------------------

// functions needed
void(float index, float type, .float field) clientstat = #232;
void(float num, float type, string name) globalstat = #233;

// my client vars (33-63) -whipowill
const float IT_GRENADES = 33;

// my global vars (128-255) -whipowill
const float GAME_SCARLET = 128;
const float GAME_TEAMPLAY = 129;
const float GAME_GRENADES = 130;
const float SCORE_DEATHS = 131; // 32 slots

float gametracker_scarlet, gametracker_teamplay, gametracker_grenades;

float score_player01_deaths;
float score_player02_deaths;
float score_player03_deaths;
float score_player04_deaths;
float score_player05_deaths;
float score_player06_deaths;
float score_player07_deaths;
float score_player08_deaths;

.float deaths;

.float update_time;

// this runs when client loads
void() StatsInit =
{
    // 1: string (4 stats carrying a total of 16 charactures)
    // 2: float (one stat, float converted to an integer for transportation)
    // 8: integer (one stat, not converted to an int, so this can be used to transport floats as floats - what a unique idea!)

    // client vars
    clientstat (IT_GRENADES, 2, ammo_grenades);

    // global vars
    globalstat (GAME_SCARLET, 2, "gametracker_scarlet");
    globalstat (GAME_TEAMPLAY, 2, "gametracker_teamplay");
    globalstat (GAME_GRENADES, 2, "gametracker_grenades");

    string str, num;
    for (float i = 1; i<=32; i++)
    {
        num = (i < 10) ? strcat("0", ftos(i)) : ftos(i);

        str = strcat("score_player", num);
        str = strcat(str, "_deaths");
        globalstat (SCORE_DEATHS+i-1, 2, str);
    }
}

// this runs when player gets hurt
void(entity player, entity attacker) StatsDamage =
{
    if (player.classname != "player") return;

    // flag player as having been attacked (for shield recharge)
    player.last_damaged_time = time;
}

// this runs when player dies
void(entity player, entity attacker) StatsDeath =
{
    // Don't put any player or attacker classname checks in
    // here bc it gets too complicated.  All these functions will
    // check it on their own as needed.

    // add to player deaths
    player.deaths = player.deaths + 1;

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
}

// this runs when player respawns
void(entity player) StatsRespawn =
{
    if (player.classname != "player") return;

    // reset stats
    player.ammo_grenades = cvar("scarlet_grenades_min");

    // make sure player is in scorekeeper index
    ScoreKeeperAddPlayer(player);
}

// this runs every frame
void(entity player) StatsUpdate =
{
    if (player.classname != "player") return;

    NameTag(); // SCARLET - nametags integration.
    RechargeShields(); // SCARLET - shields integration.

    // tell client some game settings
    gametracker_scarlet = 1;
    gametracker_teamplay = teamplay;
    gametracker_grenades = cvar("scarlet_grenades");

    // if using time mechanism of restocking
    if (cvar("scarlet_grenades_restock"))
        if (player.grenades_time <= time) player.ammo_grenades = cvar("scarlet_grenades_max");

    // if pulsing melee attack
    if (self.attack_counter_melee > 0)
    {
        if (self.attack_counter_melee < cvar("scarlet_melee_spam"))
            AxeAttack();
        else
            self.attack_counter_melee = 0;
    }

    // reset weapon state
    if (!self.attack_counter_melee)
        FixWeaponState();

    if (time >= self.update_time)
    {
        // assign stats
        AlphaKeeper(); // re-alphabetize list of players
        if (player.alphapos == 1)
        {
                score_player01_deaths = player.deaths;
        }
        else if (player.alphapos == 2)
        {
                score_player02_deaths = player.deaths;
        }
        else if (player.alphapos == 3)
        {
                score_player03_deaths = player.deaths;
        }
        else if (player.alphapos == 4)
        {
                score_player04_deaths = player.deaths;
        }
        else if (player.alphapos == 5)
        {
                score_player05_deaths = player.deaths;
        }
        else if (player.alphapos == 6)
        {
                score_player06_deaths = player.deaths;
        }
        else if (player.alphapos == 7)
        {
                score_player07_deaths = player.deaths;
        }
        else if (player.alphapos == 8)
        {
                score_player08_deaths = player.deaths;
        }

        // I never could figure out why the ScoreKeeperAddPlayer() being sent
        // from StatsDeath() didn't work right.  It was always off for
        // some reason.

        // team score integration
        ScoreKeeperAddPlayer(self);
        ScoreKeeperEndgame();

        self.update_time = time + 1;
    }
}