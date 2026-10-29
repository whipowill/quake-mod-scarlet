// -------------------------------------------------
// Enable Halo-style nametags when aiming at players.
// #
// https://gist.github.com/BenVanCitters/a157f58e906bf00adc39a484cbcee12f
// original code by BenVanCitters, modified by whipowill
// -------------------------------------------------

.float      wait_after_show_time; // during gameplay this is set to the time to start showing a player's name under the crosshair - .2 seconds after he is under it
.float      wait_before_show_time; // during gameplay this is set to the time to stop showing a player's name no longer under the crosshair

// tell the HUD mod which player is under the crosshair so it can print the name there
// meant to be called every frame (ie in PlayerPreThink)
void() NameTag=
{
    if (!cv_scarlet_nametags) return;

    local vector source;
    local float has_invis;
    local float is_player;

    //assign 'v up forward left
    makevectors (self.v_angle);
    //push out a little, hopefully a little out of self's bounding box
    source = self.origin + '0 0 16';
    //trace(raycast) a line way, way out ahead of us
    traceline (source, source + v_forward*2048, FALSE, self);
    //only show name if it's a player that isn't us
    is_player = ((self != trace_ent) && (trace_ent.classname == "player"));

    //only show if the player isn't invisible
    has_invis = ((trace_ent.items & IT_INVISIBILITY)==IT_INVISIBILITY);

    //if our trace didn't go all the way out
    if((trace_fraction < 1.0) && is_player && !has_invis)
    {
        //only show if done waiting
        if(self.wait_before_show_time < time)
            self.stat_nametag = StatsSlot(trace_ent) + 1; // the HUD mod draws the name
        self.wait_after_show_time = time + .2;
    }
    else
    {
        self.wait_before_show_time = time + .2;
    }

    //hide if done waiting
    if(time > self.wait_after_show_time)
        self.stat_nametag = 0;
}
