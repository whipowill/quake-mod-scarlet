// -------------------------------------------------
// Enable Halo-style killstreak announcements.
// by whipowill
// -------------------------------------------------

.float killstreak;

void(entity player) KillstreakReset =
{
    if (cvar("scarlet_killstreaks") && player.killstreak >= 5)
    {
        bprint(player.netname);
        bprint("'s kill streak has ended (");
        bprint(ftos(player.killstreak));
        bprint(").\n");
    }

    player.killstreak = 0;
}

void(entity player) KillstreakAdd =
{
    if (player.classname != "player") return;

    player.killstreak = player.killstreak + 1;

    if (cvar("scarlet_killstreaks"))
    {
        if (player.killstreak == 5)
        {
            player.wait_before_show_time = time + 1;
            centerprint(player, "Killing Spree!\n");

            bprint(player.netname);
            bprint(" is on a Killing Spree!\n");
        }
        else if (player.killstreak == 10)
        {
            centerprint(player, "Killing Frenzy!\n");

            bprint(player.netname);
            bprint(" is on a Killing Frenzy!\n");
        }
        else if (player.killstreak == 15)
        {
            centerprint(player, "Running Riot!\n");

            bprint(player.netname);
            bprint(" is on a Running Riot!\n");
        }
        else if (player.killstreak == 20)
        {
            centerprint(player, "Rampage!\n");

            bprint(player.netname);
            bprint(" is on a Rampage!\n");
        }
        else if (player.killstreak == 25)
        {
            centerprint(player, "Nightmare!\n");

            bprint(player.netname);
            bprint(" is a Nightmare!\n");
        }
        else if (player.killstreak == 30)
        {
            centerprint(player, "Boogeyman!\n");

            bprint(player.netname);
            bprint(" is a Boogeyman!\n");
        }
        else if (player.killstreak == 35)
        {
            centerprint(player, "Grim Reaper!\n");

            bprint(player.netname);
            bprint(" is a Grim Reaper!\n");
        }
        else if (player.killstreak == 40)
        {
            centerprint(player, "Demon!\n");

            bprint(player.netname);
            bprint(" is a Demon!\n");
        }
        /*
        else if (player.killstreak == 6)
        {
            bprint(player.netname);
            bprint("'s kill streak is ");
            bprint(ftos(player.killstreak));
            bprint("!\n");
        }
        */
    }
}