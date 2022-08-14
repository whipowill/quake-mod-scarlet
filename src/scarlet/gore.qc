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
                remove(self); // remove if: time "runs out"
                return;
        }

        self.angles = vectoangles(self.velocity); // point in direction of movement
        if (self.flags & FL_ONGROUND)
        {
                // trying to get blood stains on the ground
                particle (self.origin, self.velocity*0.2, 64+(random()*15), 100 * random());
                particle (self.origin, self.velocity*0.4, 64+(random()*15), 100 * random());
                particle (self.origin, self.velocity*0.6, 64+(random()*15), 100 * random());
                self.nextthink = time + random();
        }
        else
        {
                // splat slowly slides down walls, changing speed
                self.velocity_z = random()*-10;
                self.nextthink = time + 0.2;
        }

};

void() SplatTouch =
{
        if ((other != world) || (pointcontents(self.origin) <= -3))
        {
                remove(self); // remove if: didn't hit wall, in liquid
                return;
        }

        self.velocity = self.avelocity = '0 0 0'; // stop moving and spinning
        self.movetype = MOVETYPE_FLY; // changed to remove effect of gravity
        self.touch = SUB_Null; // don't call this (touch) function again
        self.attack_finished = time + 4 + (2*random()); // set random "time limit"

        self.think = SplatThink;
        self.nextthink = time + 0.2;
};

void(vector dir, vector org, entity own, float damage) ThrowBloodSplat =
{
        if (!cvar("scarlet_gore")) return;

        local entity splat;

        if ( !((own.flags & FL_MONSTER) || (own.classname == "player")) )
                return; // only monsters and players should create splats!

        splat = spawn();
        splat.owner = own; // move through hit monster/player
        splat.movetype = MOVETYPE_TOSS;
        splat.solid = SOLID_BBOX; // does not move through other entities (besides owner)

        dir = normalize(dir); //make sure "dir" has length 1
        splat.velocity = dir * ((450 - (damage*2)) + (50*random())); // less velocity the more damage is dealt
        splat.velocity_x = splat.velocity_x + (crandom()*90); // 90 degree arc of splash
        splat.velocity_y = splat.velocity_y + (crandom()*90); // 90 degree arc of splash
        splat.velocity_z = splat.velocity_z + 90 + (100*random()); // random arc of spatter
        splat.avelocity = '3000 1000 2000'; //spin fast!
        splat.touch = SplatTouch;
    
        splat.nextthink = time + 2;
        splat.think = SUB_Remove;

        // the damage is sent to this method so you could do different
        // gibs based on how much damage was dealt, but it didn't look right to me.

        setmodel (splat, "progs/zom_gib.mdl");
        setsize (splat, '0 0 0', '0 0 0');
        setorigin (splat, org); //start splat at point of damage
};

void(entity explosive, float damage) ThrowBloodSplatByExplosion =
{
        local entity head;
        local float count;

        explosive.angles_x = (explosive.angles_x + 180)*-1; // grenades and rockets explode in front of you, reverse direction
        makevectors(explosive.angles); //find direction rocket is facing

        head = findradius(explosive.origin, damage+40);
        while (head)
        {
                count = 0;

                while (count < 3)
                {
                        if (random() < 0.8)
                        {
                                ThrowBloodSplat(v_forward, head.origin, head, damage);
                                ThrowBloodSplat(v_forward, head.origin, head, damage);
                                ThrowBloodSplat(v_forward, head.origin, head, damage);
                        }
                        count++;
                }

                head = head.chain;
        }
};

void(vector dir, vector org, entity own, float damage) ThrowBloodSplatByLightning =
{
        local float count;
        count = 0;

        while (count < 3)
        {
                if (random() < 0.6)
                {
                        ThrowBloodSplat(dir, org, own, damage);
                        ThrowBloodSplat(dir, org, own, damage);
                }
                count++;
        }
};