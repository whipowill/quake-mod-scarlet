float() crandom; //function prototype for crandom

//SplatThink: Controls behavior of splats after they have hit the wall
void() SplatThink =
{
        //if ( (self.attack_finished <= time) || (self.flags & FL_ONGROUND) )
        if ( (self.attack_finished <= time) )
        {
                remove(self); //remove if: time "runs out" or on ground
                return;
        }
        self.velocity_z = random()*-10; //splat slowly slides down walls, changing speed
        self.angles = vectoangles(self.velocity); //point in direction of movement
        self.nextthink = time + 0.2;
};

//SplatTouch: Called(by the engine) when splats touch the world or an entity
//after being spawned
void() SplatTouch =
{
        //if ( (other != world) || (pointcontents(self.origin) <= -3) || (self.flags & FL_ONGROUND) )
        if ( (other != world) || (pointcontents(self.origin) <= -3) )
        {
                remove(self); //remove if: didn't hit wall, in liquid, or on ground
                return;
        }

        self.velocity = self.avelocity = '0 0 0'; //stop moving and spinning
        self.movetype = MOVETYPE_TOSS; //MOVETYPE_FLY; //changed to remove effect of gravity
        self.touch = SUB_Null; //don't call this (touch) function again
        self.attack_finished = time + 4 + (2*random()); //set random "time limit"

        self.think = SplatThink;
        self.nextthink = time + 0.2;
};

//ThrowBloodSplat: This will create a blood splat at "org", moving in
//direction "dir", and owned by "own"
void(vector dir, vector org, entity own) ThrowBloodSplat =
{
        local entity splat;

        if ( !((own.flags & FL_MONSTER) || (own.classname == "player")) )
                return; //only monsters and players should create splats!

        splat = spawn();
        splat.owner = own; //move through hit monster/player
        splat.movetype = MOVETYPE_TOSS; //MOVETYPE_TOSS; //gravity with no bouncing
        splat.solid = SOLID_BBOX; //does not move through other entities (besides owner)

        dir = normalize(dir); //make sure "dir" has length 1
        splat.velocity = dir * (450 + 50*random()); //random velocity in direction of shot
        splat.velocity_x = splat.velocity_x + crandom()*40; //randomize x velocity (+/- 40)
        splat.velocity_y = splat.velocity_y + crandom()*40; //randomize y velocity (+/- 40)
        splat.velocity_z = splat.velocity_z + 120 + 50*random(); //randomize z velocity (+ 120-170)
        splat.avelocity = '3000 1000 2000'; //spin fast!
        splat.touch = SplatTouch;
    
        splat.nextthink = time + 2;
        splat.think = SUB_Remove;

        setmodel (splat, "progs/zom_gib.mdl");
        setsize (splat, '0 0 0', '0 0 0');     
        setorigin (splat, org); //start splat at point of damage
};

// special blood spat function for rockets and grenades based on radius. -whipowill
void(entity inflictor, entity attacker, float damage, entity ignore) ThrowBloodSplatRadius =
{
        local   float   points;
        local   entity  head;
        local   vector  org;

        head = findradius(self.origin, damage+40);

        while (head)
        {
                //if (head != ignore)
                //{
                        org = head.origin + (head.mins + head.maxs)*0.5;
                        points = 0.5*vlen (inflictor.origin - org);
                        if (points < 0)
                                points = 0;
                        points = damage - points;
                        if (head == self.owner)
                                points = points * 0.5;
                        if (points > 0)
                        {
                                if (CanDamage (head, self))
                                {
                                        if (random() < 0.8) //only 4 in 5 times to prevent overflows
                                        {
                                                inflictor.angles_x = inflictor.angles_x*-1; //account for error in makevectors with non-player entities
                                                makevectors(inflictor.angles); //find direction nail is facing
                                                ThrowBloodSplat(v_forward, inflictor.origin, other); //throw blood splat in direction nail is facing
                                        }
                                }
                        }
                //}

                head = head.chain;
        }
};