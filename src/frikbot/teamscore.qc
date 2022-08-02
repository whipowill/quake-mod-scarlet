// -------------------------------------------------
// Make combined team score trigger deathmatch fraglimit.
// #
// by whipowill
// -------------------------------------------------

float teamscore[14];

float(entity victim) TeamScoreEndgame =
{
        // if no cvar then bail
        if (!cvar("frikbot_teamscores"))
                return FALSE;

        float fraglimit = cvar("fraglimit");

        // if wrong game type then bail
        if (coop > 0 || deathmatch < 1 || teamplay < 1 || fraglimit < 1) return FALSE;

        entity killer = victim.enemy;

        // get team nums
        float victim_team_num = victim.team;
        float killer_team_num = killer.team;

        if (victim == killer)
        {
                teamscore[victim_team_num] -= 1;
        }
        else if (killer.classname == "teledeath")
        {
                killer_team_num = killer.owner.team;

                //teamscore[victim_team_num] -= 1; // telefrag doesn't subtrack from the victim
                teamscore[killer_team_num] += 1;
        }
        else
        {
                teamscore[killer_team_num] += 1;
        }

        // if team is over fraglimit
        if (teamscore[killer_team_num] >= fraglimit)
                return TRUE;

        return FALSE;
};