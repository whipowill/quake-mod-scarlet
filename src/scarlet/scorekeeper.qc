// -------------------------------------------------
// Make combined team score trigger deathmatch fraglimit.
// #
// by whipowill
// -------------------------------------------------

// functions needed
float(string s1, string s2) strcasecmp = #229;

.float ranking;
.float alphapos; // the rank by alphabetical order of name

typedef struct
{
        string name;
        float frags;
        float team;
        entity player;
} playerkeep;
playerkeep score_player_roster[16]; // index of player names and scores
float score_player_rank[16]; // player ranks where key is rank and value is roster index key (only tracking up to 8 players)
float score_player_alpha[16]; // player names in alphabetical order (for tracking stats and sending to client)

typedef struct
{
        float frags;
        float team;
} teamkeep;
teamkeep score_team_roster[16]; // index of teams and scores
float score_team_rank[4]; // team ranks where key is the rank and value is the team num (only tracking up to 4 teams)

float(string name1, string name2) StringCompare =
{
        return strcasecmp(name1, name2);
}

string(string name) NameFilter =
{
        return (!name || name == "") ? "ZZZZZZZ" : name;
}

string(float id) GetPlayerNameFromAlphaIndex =
{
        if (id <= 0) return NameFilter("");

        return NameFilter(score_player_roster[id].name);
}

void(float id, float rank) AssignAlpha =
{
        if (!score_player_roster[id].name || score_player_roster[id].name == "") return;

        entity player = score_player_roster[id].player;

        player.alphapos = rank;
}

void(float id, float rank) AssignRank =
{
        if (!score_player_roster[id].name || score_player_roster[id].name == "") return;

        score_player_roster[id].player.ranking = rank;
}

void() ScoreKeeperEndgame =
{
        // don't do it if you already did it
        if (intermission_running) return;

        // update stats on player and capture max score
        local float maxscore = teamplay ? ScoreKeeperFragsForRank(0, "score_team_rank") : ScoreKeeperFragsForRank(0, "score_player_rank");

        // capture fraglimit
        local float fraglimit = cvar("fraglimit");

        // if conditions
        if (cvar("scarlet_teamscores") && coop < 1 && deathmatch > 0 && teamplay > 0 && fraglimit > 0 && maxscore >= fraglimit)
                 execute_changelevel();
};

void(entity player) ScoreKeeperAddPlayer =
{
        if (player.classname != "player") return;

        local float i;
        local float playerkey;

        for (i=0; i<16; i++)
        {
                if (score_player_roster[i].name == player.netname)
                        playerkey = i;
                else if (score_player_roster[i].name == "")
                        playerkey = i;
        }
        if (playerkey)
        {
                score_player_roster[playerkey].name = player.netname;
                score_player_roster[playerkey].frags = player.frags;
                score_player_roster[playerkey].team = player.team;
                score_player_roster[playerkey].player = player; // should be store by reference
        }

        ScoreKeeper();
};

void(entity player) ScoreKeeperRemovePlayer =
{
        local float i;
        for (i=0; i<16; i++)
        {
                if (score_player_roster[i].name == player.netname)
                {
                        score_player_roster[i].name = "",
                        score_player_roster[i].frags = 0;
                        score_player_roster[i].team = -1;
                        score_player_roster[i].player = world;
                }
        }

        ScoreKeeper();
};

float(float rankkey, string roster_type) ScoreKeeperFragsForRank =
{
        if (roster_type == "score_player_rank")
        {
                local float playerkey = score_player_rank[rankkey];
                if (playerkey < 0) return 0;
                return score_player_roster[playerkey].frags;
        }
        else if (roster_type == "score_team_rank")
        {
                local float teamkey = score_team_rank[rankkey];
                if (teamkey < 0) return 0;
                return score_team_roster[teamkey].frags;
        }

        return 0;
};

void() AlphaKeeper =
{
        // reset player ranks
        score_player_alpha[7] = -1;
        score_player_alpha[6] = -1;
        score_player_alpha[5] = -1;
        score_player_alpha[4] = -1;
        score_player_alpha[3] = -1;
        score_player_alpha[2] = -1;
        score_player_alpha[1] = -1;
        score_player_alpha[0] = -1;

        // alphabetize the players (for use in stats.qc)

        float i;
        string name;

        for (i=0; i<16; i++)
        {
                name = NameFilter(score_player_roster[i].name);

                if (StringCompare(name, GetPlayerNameFromAlphaIndex(score_player_alpha[0])) < 0)
                {
                        score_player_alpha[7] = score_player_alpha[6];
                        score_player_alpha[6] = score_player_alpha[5];
                        score_player_alpha[5] = score_player_alpha[4];
                        score_player_alpha[4] = score_player_alpha[3];
                        score_player_alpha[3] = score_player_alpha[2];
                        score_player_alpha[2] = score_player_alpha[1];
                        score_player_alpha[1] = score_player_alpha[0];
                        score_player_alpha[0] = i;
                }
                else if (StringCompare(name, GetPlayerNameFromAlphaIndex(score_player_alpha[1])) < 0)
                {
                        score_player_alpha[7] = score_player_alpha[6];
                        score_player_alpha[6] = score_player_alpha[5];
                        score_player_alpha[5] = score_player_alpha[4];
                        score_player_alpha[4] = score_player_alpha[3];
                        score_player_alpha[3] = score_player_alpha[2];
                        score_player_alpha[2] = score_player_alpha[1];
                        score_player_alpha[1] = i;
                }
                else if (StringCompare(name, GetPlayerNameFromAlphaIndex(score_player_alpha[2])) < 0)
                {
                        score_player_alpha[7] = score_player_alpha[6];
                        score_player_alpha[6] = score_player_alpha[5];
                        score_player_alpha[5] = score_player_alpha[4];
                        score_player_alpha[4] = score_player_alpha[3];
                        score_player_alpha[3] = score_player_alpha[2];
                        score_player_alpha[2] = i;
                }
                else if (StringCompare(name, GetPlayerNameFromAlphaIndex(score_player_alpha[3])) < 0)
                {
                        score_player_alpha[7] = score_player_alpha[6];
                        score_player_alpha[6] = score_player_alpha[5];
                        score_player_alpha[5] = score_player_alpha[4];
                        score_player_alpha[4] = score_player_alpha[3];
                        score_player_alpha[3] = i;
                }
                else if (StringCompare(name, GetPlayerNameFromAlphaIndex(score_player_alpha[4])) < 0)
                {
                        score_player_alpha[7] = score_player_alpha[6];
                        score_player_alpha[6] = score_player_alpha[5];
                        score_player_alpha[5] = score_player_alpha[4];
                        score_player_alpha[4] = i;
                }
                else if (StringCompare(name, GetPlayerNameFromAlphaIndex(score_player_alpha[5])) < 0)
                {
                        score_player_alpha[7] = score_player_alpha[6];
                        score_player_alpha[6] = score_player_alpha[5];
                        score_player_alpha[5] = i;
                }
                else if (StringCompare(name, GetPlayerNameFromAlphaIndex(score_player_alpha[6])) < 0)
                {
                        score_player_alpha[7] = score_player_alpha[6];
                        score_player_alpha[6] = i;
                }
                else if (StringCompare(name, GetPlayerNameFromAlphaIndex(score_player_alpha[7])) < 0)
                {
                        score_player_alpha[7] = i;
                }
        }

        for (i=0; i<8; i++)
                if (score_player_alpha[i] >= 0) // if a real player
                        AssignAlpha(score_player_alpha[i], i+1);
}

void() ScoreKeeper =
{
        // We're always going to track team ranks and player ranks
        // bc the server may swap settings on midgame and we don't
        // want to lose the stats.

        // for loops
        local float i;

        // reset player ranks
        score_player_rank[7] = -1;
        score_player_rank[6] = -1;
        score_player_rank[5] = -1;
        score_player_rank[4] = -1;
        score_player_rank[3] = -1;
        score_player_rank[2] = -1;
        score_player_rank[1] = -1;
        score_player_rank[0] = -1;

        // update the player ranks
        for (i=0; i<16; i++)
        {
                if (score_player_roster[i].frags >= ScoreKeeperFragsForRank(0, "score_player_rank"))
                {
                        score_player_rank[7] = score_player_rank[6];
                        score_player_rank[6] = score_player_rank[5];
                        score_player_rank[5] = score_player_rank[4];
                        score_player_rank[4] = score_player_rank[3];
                        score_player_rank[3] = score_player_rank[2];
                        score_player_rank[2] = score_player_rank[1];
                        score_player_rank[1] = score_player_rank[0];
                        score_player_rank[0] = i;
                }
                else if (score_player_roster[i].frags >= ScoreKeeperFragsForRank(1, "score_player_rank"))
                {
                        score_player_rank[7] = score_player_rank[6];
                        score_player_rank[6] = score_player_rank[5];
                        score_player_rank[5] = score_player_rank[4];
                        score_player_rank[4] = score_player_rank[3];
                        score_player_rank[3] = score_player_rank[2];
                        score_player_rank[2] = score_player_rank[1];
                        score_player_rank[1] = i;
                }
                else if (score_player_roster[i].frags >= ScoreKeeperFragsForRank(2, "score_player_rank"))
                {
                        score_player_rank[7] = score_player_rank[6];
                        score_player_rank[6] = score_player_rank[5];
                        score_player_rank[5] = score_player_rank[4];
                        score_player_rank[4] = score_player_rank[3];
                        score_player_rank[3] = score_player_rank[2];
                        score_player_rank[2] = i;
                }
                else if (score_player_roster[i].frags >= ScoreKeeperFragsForRank(3, "score_player_rank"))
                {
                        score_player_rank[7] = score_player_rank[6];
                        score_player_rank[6] = score_player_rank[5];
                        score_player_rank[5] = score_player_rank[4];
                        score_player_rank[4] = score_player_rank[3];
                        score_player_rank[3] = i;
                }
                else if (score_player_roster[i].frags >= ScoreKeeperFragsForRank(4, "score_player_rank"))
                {
                        score_player_rank[7] = score_player_rank[6];
                        score_player_rank[6] = score_player_rank[5];
                        score_player_rank[5] = score_player_rank[4];
                        score_player_rank[4] = i;
                }
                else if (score_player_roster[i].frags >= ScoreKeeperFragsForRank(5, "score_player_rank"))
                {
                        score_player_rank[7] = score_player_rank[6];
                        score_player_rank[6] = score_player_rank[5];
                        score_player_rank[5] = i;
                }
                else if (score_player_roster[i].frags >= ScoreKeeperFragsForRank(6, "score_player_rank"))
                {
                        score_player_rank[7] = score_player_rank[6];
                        score_player_rank[6] = i;
                }
                else if (score_player_roster[i].frags >= ScoreKeeperFragsForRank(7, "score_player_rank"))
                {
                        score_player_rank[7] = i;
                }
        }

        for (i=0; i<8; i++)
                if (score_player_rank[i] >= 0) // if a real player
                        AssignRank(score_player_rank[i], i+1);

        // if tracking teams
        if (teamplay > 0)
        {
                // reset team roster
                for (i=0; i<16; i++) // i thought team nums would be 0-13 but i'm not entirely sure
                {
                        score_team_roster[i].frags = 0;
                        score_team_roster[i].team = -1;
                }
                for (i=0; i<16; i++) // foreach player
                {
                        // if a real player on a real team
                        if (score_player_roster[i].team >= 0)
                        {
                                // add the frags to that team
                                score_team_roster[score_player_roster[i].team].frags += score_player_roster[i].frags;
                                score_team_roster[score_player_roster[i].team].team = score_player_roster[i].team;
                        }
                }

                // reset team ranks
                score_team_rank[3] = -1;
                score_team_rank[2] = -1;
                score_team_rank[1] = -1;
                score_team_rank[0] = -1;

                for (i=0; i<16; i++) // foreach team in roster
                {
                        if (score_team_roster[i].team >= 0) // if team has a number
                        {
                                if (score_team_roster[i].frags >= ScoreKeeperFragsForRank(0, "score_team_rank"))
                                {
                                        score_team_rank[3] = score_team_rank[2];
                                        score_team_rank[2] = score_team_rank[1];
                                        score_team_rank[1] = score_team_rank[0];
                                        score_team_rank[0] = i;
                                }
                                else if (score_team_roster[i].frags >= ScoreKeeperFragsForRank(1, "score_team_rank"))
                                {
                                        score_team_rank[3] = score_team_rank[2];
                                        score_team_rank[2] = score_team_rank[1];
                                        score_team_rank[1] = i;
                                }
                                else if (score_team_roster[i].frags >= ScoreKeeperFragsForRank(2, "score_team_rank"))
                                {
                                        score_team_rank[3] = score_team_rank[2];
                                        score_team_rank[2] = i;
                                }
                                else if (score_team_roster[i].frags >= ScoreKeeperFragsForRank(3, "score_team_rank"))
                                {
                                        score_team_rank[3] = i;
                                }
                        }
                }
        }
};

float(entity player) AmIWinning =
{
        // This is used for dialogue between the bots,
        // I want them to get depressed if they're losing
        // and prideful if they're winning.

        local float i;
        local float is_winning = FALSE;

        // if teams
        if (teamplay > 0)
        {
                local float num_of_teams = 4;

                local float team_rank = 666;
                if (score_team_rank[0] == player.team) team_rank = 0;
                else if (score_team_rank[1] == player.team) team_rank = 1;
                else if (score_team_rank[2] == player.team) team_rank = 2;
                else if (score_team_rank[3] == player.team) team_rank = 3;

                if ((team_rank+1) <= (num_of_teams/4))
                        is_winning = TRUE;

                // are you in the top half?
                return is_winning;
        }

        // find your rank
        local float player_key = -1;
        local float player_rank = 666;
        for (i=0; i<16; i++)
        {
                if (score_player_roster[i].name == player.netname)
                {
                        player_key = i;
                        break;
                }
        }

        for (i=0; i<8; i++)
        {
                if (score_player_rank[i] == player_key)
                {
                        player_rank = i;
                        break;
                }
        }

        // calc num of players
        local float num_of_players = 0;
        for (i=0; i<16; i++)
                if (score_player_roster[i].name != "")
                        num_of_players++;

        if ((player_rank+1) <= (num_of_players/2))
                is_winning = TRUE;

        // return
        return is_winning;
};

void() ScoreKeeperList =
{
        // this is for testing and debugging
        bprint("Scorekeeper list of tracked players.\n");

        local float i;
        for (i=0; i<16; i++)
        {
                if (score_player_roster[i].name && score_player_roster[i].name != "")
                {
                        bprint("SCOREKEEPER -- ");
                        bprint(score_player_roster[i].name);
                        bprint(" - ");
                        bprint(ftos(score_player_roster[i].frags));
                        bprint("\n");
                }
        }
};