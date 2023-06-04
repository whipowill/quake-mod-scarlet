// -------------------------------------------------
// Enable blood splatter when getting shot.
// #
// https://www.insideqc.com/qctut/qctut-47.shtml
// original code by Maniac, modified by whipowill
// -------------------------------------------------

float() crandom;

void() SplatThink =
{
        if ((self.attack_finished <= time))
        {
                remove(self);
                return;
        }

        if (self.type != "drop")
        {
                remove(self);
                return;
        }

        if (self.flags & FL_ONGROUND)
        {
                remove(self);
                return;

                // trying to get blood stains on the ground NONE OF THIS LOOKED GOOD :(
                //particle (self.origin, '0 0 0', 64+(random()*3), random()*44);
                //particle (self.origin, '0 0 0', 64+(random()*6), random()*22);
                //particle (self.origin, '0 0 0', 64+(random()*9), random()*11);
                //self.nextthink = time + 1 + (3*random());
        }

        // splat slowly slides down walls, changing speed
        self.angles = vectoangles(self.velocity); // point in direction of movement
        self.velocity_z = random()*-10;
        self.nextthink = time + 0.2;
};

void() SplatTouch =
{
        if (CheckProjectilePassthru()) return;

        if ((other != world) || (pointcontents(self.origin) <= -3))
        {
                remove(self);
                return;
        }

        if (other == world)
        {
                self.velocity = self.avelocity = '0 0 0';
                self.movetype = MOVETYPE_FLY;
        }

        self.touch = SUB_Null; // don't call this (touch) function again
        self.attack_finished = time + 5 + (5*random()); // set random "time limit"

        self.think = SplatThink;
        self.nextthink = time + 0.2;
};

void(vector dir, vector org, entity own, float damage, float weap = 1) ThrowBloodSplat =
{
        // weap is a made up var, 1=bullet,2=nail,3=rock,4=cell,5=axe

        if (!cvar("scarlet_gore")) return;

        local entity splat;

        if ( !((own.flags & FL_MONSTER) || (own.classname == "player")) )
                return; // only monsters and players should create splats!

        local float c = 1; // chances that a shot will splatter
        local float m = 1; // multiplier

        if (weap == 1)
        {
                c = cvar("scarlet_gore_chance_bullets");
                m = cvar("scarlet_gore_multiplier_bullets");
        }
        else if (weap == 2)
        {
                c = cvar("scarlet_gore_chance_nails");
                m = cvar("scarlet_gore_multiplier_nails");
        }
        else if (weap == 3)
        {
                c = cvar("scarlet_gore_chance_rockets");
                m = cvar("scarlet_gore_multiplier_rockets");
        }
        else if (weap == 4)
        {
                c = cvar("scarlet_gore_chance_cells");
                m = cvar("scarlet_gore_multiplier_cells");
        }

        local float pass = 1;
        if (cvar("scarlet_gore_limit_shot"))
        {
                if (random() > c) pass = 0;
        }

        if (pass)
        {
                // loop
                local float i;
                local float j = cvar("scarlet_gore"); // number of times to loop
                for (i=1; i<=j*m; i++)
                {
                        pass = 1;
                        if (cvar("scarlet_gore_limit_drop"))
                        {
                                if (random() > c) pass = 0;
                        }

                        if (pass) // reroll chance for each loop
                        {
                                splat = spawn();
                                splat.owner = own; // move through hit monster/player
                                splat.movetype = MOVETYPE_BOUNCE; //MOVETYPE_TOSS;
                                splat.solid = SOLID_BBOX; // does not move through other entities (besides owner)

                                dir = normalize(dir); //make sure "dir" has length 1
                                splat.velocity = dir * ((450 - (damage*2)) + (50*random())); // less velocity the more damage is dealt
                                splat.velocity_x = splat.velocity_x + (crandom()*180); // 90 degree arc of splash
                                splat.velocity_y = splat.velocity_y + (crandom()*180); // 90 degree arc of splash
                                splat.velocity_z = splat.velocity_z + (crandom()*180); // random arc of spatter
                                //splat.avelocity = '3000 1000 2000'; //spin fast!
                                splat.avelocity = Vector(random(),random(),random()) * 600;
                                splat.touch = SplatTouch;

                                splat.nextthink = time + 0.2;
                                splat.think = SUB_Null;

                                // the damage is sent to this method so you could do different
                                // gibs based on how much damage was dealt, but it didn't look right to me.

                                local float rand = crandom();
                                if (rand >= .95)
                                {
                                        setmodel (splat, "progs/gib2.mdl"); // lungs
                                        splat.type = "lung";
                                }
                                if (rand >= .90 && rand < .95)
                                {
                                        setmodel (splat, "progs/gib3.mdl"); // chunk
                                        splat.type = "chunk";
                                }
                                else if (rand >= .8 && rand < .90)
                                {
                                        setmodel (splat, "progs/gib1.mdl"); // arm?
                                        splat.type = "arm";
                                }
                                else
                                {
                                        setmodel (splat, "progs/zom_gib.mdl");
                                        splat.type = "drop";
                                }
                                setsize (splat, '0 0 0', '0 0 0');
                                setorigin (splat, org); //start splat at point of damage
                        }
                }
        }

        // testing
        //SpawnShards(org, own);
};

void(entity explosive, float damage) ThrowBloodSplatByExplosion =
{
        local entity head;

        explosive.angles_x = (explosive.angles_x + 180)*-1; // grenades and rockets explode in front of you, reverse direction
        makevectors(explosive.angles); //find direction rocket is facing

        head = findradius(explosive.origin, damage+40);
        while (head)
        {
                ThrowBloodSplat(v_forward, head.origin, head, damage, 3);

                head = head.chain;
        }
};

void(vector dir, vector org, entity own, float damage) ThrowBloodSplatByLightning =
{
        local vector vel;

        vel = normalize(dir) * -1;
        vel = normalize(vel + v_up*(random()- 0.5) + v_right*(random()- 0.5));

        SpawnBlood (org + vel, vel*40, damage/4);
        ThrowBloodSplat(dir, org, own, damage, 4);
};