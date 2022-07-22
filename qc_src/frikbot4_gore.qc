// -------------------------------------------------
// Enable blood splatter when getting shot.
// -------------------------------------------------

float() crandom; // function prototype for crandom

// SplatThink: Controls behavior of splats after they have hit the wall
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
                particle (self.origin, self.velocity*0.1, 79, 666 * random());
                self.nextthink = time + random();
        }
        else
        {
                // splat slowly slides down walls, changing speed
                self.velocity_z = random()*-10;
                self.nextthink = time + 0.2;
        }

};

// SplatTouch: Called(by the engine) when splats touch the world or an entity after being spawned
void() SplatTouch =
{
        if ((other != world) || (pointcontents(self.origin) <= -3))
        {
                //remove(self); // remove if: didn't hit wall, in liquid
                //return;
        }

        self.velocity = self.avelocity = '0 0 0'; // stop moving and spinning
        self.movetype = MOVETYPE_FLY; // changed to remove effect of gravity
        self.touch = SUB_Null; // don't call this (touch) function again
        self.attack_finished = time + 4 + (2*random()); // set random "time limit"

        self.think = SplatThink;
        self.nextthink = time + 0.2;
};

//ThrowBloodSplat: This will create a blood splat at "org", moving in direction "dir", and owned by "own"
void(vector dir, vector org, entity own, float damage) ThrowBloodSplat =
{
        if (!cvar("frikbot4_gore")) return;

        local entity splat;

        if ( !((own.flags & FL_MONSTER) || (own.classname == "player")) )
                return; //only monsters and players should create splats!

        splat = spawn();
        splat.owner = own; //move through hit monster/player
        splat.movetype = MOVETYPE_TOSS;
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

        // the damage is sent to this method so you could do different
        // gibs based on how much damage was dealt, but it didn't look right to me.

        setmodel (splat, "progs/zom_gib.mdl");
        setsize (splat, '0 0 0', '0 0 0');
        setorigin (splat, org); //start splat at point of damage
};

// special blood spat function for rockets and grenades based on radius. -whipowill
void(entity rocket, entity attacker, float damage, entity ignore) ThrowBloodSplatRadius =
{
        local   entity  head;

        rocket.angles_x = rocket.angles_x*-1; //account for error in makevectors with non-player entities
        makevectors(rocket.angles); //find direction rocket is facing

        head = findradius(rocket.origin, damage+40);
        while (head)
        {
                if (random() < 0.8) //only 4 in 5 times to prevent overflows
                {
                        ThrowBloodSplat(rocket.velocity, rocket.origin, other, damage); //throw blood splat in direction nail is facing
                }

                head = head.chain;
        }
};

//**********************************************
// Enable kicking heads and gibs.
//**********************************************

void() KickGibs;

void() KickGibs =
{
    if (!cvar("frikbot4_gore")) return;

    local vector v;

    // only a player can kick it
    if (other.classname != "player")
        return;

    //randomize sound
    /*
    if (random()< 0.8)
        sound(other, CHAN_ITEM, "zombie/z_hit.wav", 1, ATTN_NORM);
    else
        sound(other, CHAN_ITEM, "zombie/z_miss.wav", 1, ATTN_NORM);
    */

    //define velocity
    //you can play with these formulas to adjust
    //trajectory
    v_x = (other.velocity_x*2+50*random());
    v_y = (other.velocity_y*2+50*random());
    v_z =250 + 160 * random()+(other.velocity_y+other.velocity_x)*0.30;

    self.flags = self.flags - ( self.flags & FL_ONGROUND );
    self.velocity = v;
};