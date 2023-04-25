//-------------------------------------------------
// Enable kicking heads and gibs.
// #
// http://www.insideqc.com/qctut/lesson-52.shtml
// original code by Ivana, modified by whipowill
//-------------------------------------------------

void() KickGibs =
{
    if (!cvar("scarlet_football")) return;

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