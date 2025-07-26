// -------------------------------------------------
// Manage sending custom stats to client.
// by whipowill
// -------------------------------------------------

// functions needed
void(float index, float type, .float field) clientstat = #232;
//void(float num, float type, string name) globalstat = #233;

// globalstat was used for tracking players deaths and other info,
// like if the game is teamplay, etc for sending to the client
// to display on the HUD.  But this only worked in QSS-M and
// not vkQuake, so I had to turn it off.  Bc OpenGL got nerfed
// on Linux machines and vkQuake is now the best way to play.

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
.float old_weapon;
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
    //globalstat (GAME_SCARLET, 2, "gametracker_scarlet");
    //globalstat (GAME_TEAMPLAY, 2, "gametracker_teamplay");
    //globalstat (GAME_GRENADES, 2, "gametracker_grenades");

    string str, num;
    for (float i = 1; i<=32; i++)
    {
        num = (i < 10) ? strcat("0", ftos(i)) : ftos(i);

        str = strcat("score_player", num);
        str = strcat(str, "_deaths");
        //globalstat (SCORE_DEATHS+i-1, 2, str);
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

    // if using alternate death notices...
    if (cvar("scarlet_chat_deaths") == 2)
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
            AxeAttack(0); // flag false for no lunge
        else
            self.attack_counter_melee = 0;
    }

    // if in melee/grenade swing, reset weapon state
    if (self.is_swing)
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