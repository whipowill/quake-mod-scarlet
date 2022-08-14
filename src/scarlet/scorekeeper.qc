// -------------------------------------------------
// Make combined team score trigger deathmatch fraglimit.
// #
// by whipowill
// -------------------------------------------------

typedef struct
{
        string name;
        float frags;
        float team;
} playerkeep;
playerkeep score_player_roster[16]; // index of player names and scores
float score_player_rank[8]; // player ranks where key is rank and value is roster index key (only tracking up to 8 players)

typedef struct
{
        float frags;
        float team;
} teamkeep;
teamkeep score_team_roster[16]; // index of teams and scores
float score_team_rank[4]; // team ranks where key is the rank and value is the team num (only tracking up to 4 teams)

float() ScoreKeeperEndgame =
{
        if (self.enemy.classname == "player")
                if (self != self.enemy && !self.ishuman)
                        bot_start_topic(5); // death chat
        if (self.enemy.classname == "teledeath")
                if (!self.ishuman)
                        bot_start_topic(9.5); // ridicule chat

        // update stats on attacker
        ScoreKeeper(self.enemy);

        // update stats on self and capture max score
        local float maxscore = ScoreKeeper(self);

        // capture fraglimit
        local float fraglimit = cvar("fraglimit");

        // if conditions
        if (cvar("scarlet_teamscores") && coop < 1 && deathmatch > 0 && teamplay > 0 && fraglimit > 0 && maxscore >= fraglimit)
                return TRUE;

        // return
        return FALSE;
};

void(string name) ScoreKeeperRemovePlayer =
{
        local float i;
        for (i=0; i<16; i++)
        {
                if (score_player_roster[i].name == name)
                {
                        score_player_roster[i].name = "",
                        score_player_roster[i].frags = 0;
                        score_player_roster[i].team = -1;
                }
        }
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

float(entity player) ScoreKeeper =
{
        if (self.enemy.classname != "player") return 0;

        // We're always going to track team ranks and player ranks
        // bc the server may swap settings on midgame and we don't
        // want to lose the stats.

        // for loops
        local float i;

        // update player info in roster sheet -- what breaks this is if the player changes his name mid-game but I don't know what else to do
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
        }

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

                // return highest team score
                return ScoreKeeperFragsForRank(0, "score_team_rank");
        }

        // return highest player score
        return ScoreKeeperFragsForRank(0, "score_player_rank");
};

float(entity player) AmIWinning =
{
        // This is used for dialogue between the bots,
        // I want them to get depressed if they're losing
        // and prideful if they're winning.

        local float i;
        local float is_winning = FALSE;

        local float is_testing = cvar("scarlet_testing");

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

                // for testing
                if (cvar("scarlet_testing"))
                {
                        bprint("TESTING -- ");
                        bprint(player.netname);
                        bprint(" team (#");
                        bprint(ftos(player.team));
                        bprint(") is rank ");
                        bprint(ftos(team_rank+1));
                        bprint("/");
                        bprint(ftos(num_of_teams));
                        bprint(" (");
                        bprint(ftos(is_winning));
                        bprint(")");
                        bprint("\n");
                }

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

        // for testing
        if (cvar("scarlet_testing"))
        {
                bprint("TESTING -- ");
                bprint(player.netname);
                bprint(" is rank ");
                bprint(ftos(player_rank+1));
                bprint("/");
                bprint(ftos(num_of_players));
                bprint(" (");
                bprint(ftos(is_winning));
                bprint(")");
                bprint("\n");
        }

        // return
        return is_winning;
};