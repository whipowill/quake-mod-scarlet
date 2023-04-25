// -------------------------------------------------
// Enable Halo-style nametags when aiming at players.
// #
// https://gist.github.com/BenVanCitters/a157f58e906bf00adc39a484cbcee12f
// original code by BenVanCitters, modified by whipowill
// -------------------------------------------------

.float      wait_after_show_time; // during gameplay this is set to the time to start showing a player's name under the crosshair - .2 seconds after he is under it
.float      wait_before_show_time; // during gameplay this is set to the time to stop showing a player's name no longer under the crosshair
.float      cleared_name; //to avaoid spamming only send centerprint once every .5 seconds

// print the name of the player under the crosshair in the middle of the screen
// meant to be called every frame (ie in PlayerPreThink)
void() NameTag=
{
    if (!cvar("scarlet_nametags")) return;

    local vector source;
    local float has_invis;
    local float is_player;

    //assign 'v up forward left
    makevectors (self.v_angle);
    //push out a little, hopefully a little out of self's bounding box
    source = self.origin + '0 0 16';
    //trace(raycast) a line way, way out ahead of us
    traceline (source, source + v_forward*2048, FALSE, self);
    //only print name if it's a player that isn't us
    is_player = ((self != trace_ent) && (trace_ent.classname == "player"));

    //only print if the player isn't invisible
    has_invis = ((trace_ent.items & IT_INVISIBILITY)==IT_INVISIBILITY);

    //if our trace didn't go all the way out
    if((trace_fraction < 1.0) && is_player && !has_invis)
    {
        //only print if done waiting
        if(self.wait_before_show_time < time)
        {
            centerprint (self, trace_ent.netname);
            self.cleared_name = FALSE;
        }
        self.wait_after_show_time = time + .2;
    }
    else
    {
        self.wait_before_show_time = time + .2;
    }

    //hide if done waiting - and don't spam!
    if((time > self.wait_after_show_time) && (self.cleared_name == FALSE))
    {
        //clear
        centerprint (self, " ");
        self.cleared_name = TRUE;
    }
}