// -------------------------------------------------
// Make players respawn in a random location (avoid telegrags).
// #
// by FrikaC, adapted by whipowill
// -------------------------------------------------

entity() RandomSpawnLocation =
{
        local entity spot;
        local entity thing;
        local float pcount;

        local float freespots, totalspots;
        local entity lastfreespot;

        totalspots = 0;

        // loop through all spots to find widely free spots (radius 84)
        freespots = 0;
        lastfreespot = world;

        spot = find(world, classname, "info_player_deathmatch");
        while (spot)
        {
                totalspots = totalspots + 1;

                if (spot != lastspawn)
                {
                        pcount = 0;
                        thing = findradius(spot.origin, 84); // search for players
                        while ( (thing!=world) && (pcount == 0) )
                        {
                                if ((thing.classname == "player") && (thing.health > 0)) // player found
                                        pcount = 1;
                                thing = thing.chain;
                        }
                        if (!pcount) // this is a free spot
                        {
                                spot.goalentity = lastfreespot; // create reverse free spot list
                                lastfreespot = spot; // begin of reverse free spot list
                                freespots = freespots + 1;
                        }
                }

                // Get the next spot in the chain
                spot = find(spot, classname, "info_player_deathmatch");
        }

        if (totalspots)
        {
                if (freespots)
                {
                        // We now have the number of frre spots available on the map
                        // Generate a random number between 0 and (freespots - 1)
                        freespots = freespots - 0.01;   // random() result varies between 0.0 and (n-1).99
                        freespots = floor(random() * freespots);

                        spot = lastfreespot;
                        while (freespots)
                        {
                                spot = spot.goalentity;
                                freespots = freespots - 1;
                        }

                        lastspawn = spot;
                        return spot;
                }

                // ack, they are all guarded
                // loop through all spots to find free spots (radius 32)
                freespots = 0;
                lastfreespot = world;

                spot = find(world, classname, "info_player_deathmatch");
                while (spot)
                {
                        if (spot != lastspawn)
                        {
                                pcount = 0;
                                thing = findradius(spot.origin, 32); // search for players
                                while ( (thing!=world) && (pcount == 0) )
                                {
                                        if ((thing.classname == "player") && (thing.health > 0)) // player found
                                                pcount = 1;
                                        thing = thing.chain;
                                }
                                if (!pcount) // this is a free spot
                                {
                                        spot.goalentity = lastfreespot; // create reverse free spot list
                                        lastfreespot = spot; // begin of reverse free spot list
                                        freespots = freespots + 1;
                                }
                        }

                        // Get the next spot in the chain
                        spot = find(spot, classname, "info_player_deathmatch");
                }

                if (freespots)
                {
                        // We now have the number of free spots available on the map
                        // Generate a random number between 0 and (freespots - 1)
                        freespots = freespots - 0.01;   // random() result varies between 0.0 and (n-1).99
                        freespots = floor(random() * freespots);

                        spot = lastfreespot;
                        while (freespots)
                        {
                                spot = spot.goalentity;
                                freespots = freespots - 1;
                        }

                        lastspawn = spot;
                        return spot;
                }

                // ack, they are all full, just pick one at random
                // Generate a random number between 0 and (totalspots - 1)
                totalspots = totalspots - 0.01; // random() result varies between 0.0 and (n-1).99
                totalspots = floor(random() * totalspots);

                spot = find(world, classname, "info_player_deathmatch");
                while (totalspots)
                {
                        totalspots = totalspots - 1;
                        spot = find(spot, classname, "info_player_deathmatch");
                }

                lastspawn = spot;
                return spot;
        }
        /*
        spot = lastspawn;
        while (1)
        {
                spot = find(spot, classname, "info_player_deathmatch");
                if (spot != world)
                {
                        if (spot == lastspawn)
                                return lastspawn;
                        pcount = 0;
                        thing = findradius(spot.origin, 32);
                        while(thing)
                        {
                                if (thing.classname == "player")
                                        pcount = pcount + 1;
                                thing = thing.chain;
                        }
                        if (pcount == 0)
                        {
                                lastspawn = spot;
                                return spot;
                        }
                }
        }
        */
};

float tele_tome_timer; // for limiting how often this can be used
void() TeleBotsToMe =
{
        if (!coop) return;

        if (tele_tome_timer > time) return;

        centerprint(self, "Bringing old friends back together...");

        local float i;
        local entity player;

        for (i=0; i<16; i++)
        {
                if (score_player_roster[i].name && score_player_roster[i].name != "")
                {
                        player = score_player_roster[i].player;
                        teleport(player, self, 1, 0);
                }
        }

        tele_tome_timer = time + 60;
};