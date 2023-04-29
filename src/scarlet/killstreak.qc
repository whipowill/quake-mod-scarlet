// -------------------------------------------------
// Enable Halo-style killstreak announcements.
// by whipowill
// -------------------------------------------------

.float killstreak;

void(entity player) KillstreakReset =
{
    if (cvar("scarlet_killstreaks") && player.killstreak >= 6)
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
    player.killstreak = player.killstreak + 1;

    if (cvar("scarlet_killstreaks"))
    {
        if (player.killstreak > 0 && player.killstreak <= 6)
            player.wait_before_show_time = time + 1; // prevent nametags from erasing

        if (player.killstreak == 2)
        {
            centerprint(player, "Double Kill!\n");
        }
        else if (player.killstreak == 3)
        {
            centerprint(player, "Triple Kill!\n");
        }
        else if (player.killstreak == 4)
        {
            centerprint(player, "Killtacular!\n");
        }
        else if (player.killstreak == 5)
        {
            centerprint(player, "Killing Spree!\n");
        }
        else if (player.killstreak == 6)
        {
            centerprint(player, "Running Riot!\n");
        }
        else
        {
            //sprint(player, "Your killstreak is ");
            //sprint(player, ftos(player.killstreak));
            //sprint(player, ".\n");
        }
    }
}