//-------------------------------------------------
// Enable footsteps walking sounds.
// #
// https://www.quakewiki.net/quake-1/mods/footsteps-pack/
// original code by Seven
//-------------------------------------------------

string(entity e, float s) getsurfacetexture = #437;
float(entity e, vector p) getsurfacenearpoint = #438;

void(entity e) WalkSound =
{
    if (!cvar("scarlet_footsteps")) return;

    local float surfnum, r;
    local string s;

    makevectors(e.v_angle);

    surfnum = getsurfacenearpoint(world, e.origin - '0 0 24');
    if (vlen(self.velocity) < 100)
        return;

    if (surfnum >= 0)
    {
        s = getsurfacetexture(world, surfnum);
        if (s == "wizmet1_2")
        {
            r = rint(random() * 3);         
            if (r == 0)
                sound (e, CHAN_AUTO, "walk/metal1.wav", 0.5, ATTN_NORM);
            else if (r == 1)
                sound (e, CHAN_AUTO, "walk/metal2.wav", 0.5, ATTN_NORM);
            else if (r == 2)
                sound (e, CHAN_AUTO, "walk/metal3.wav", 0.5, ATTN_NORM);
            else
                sound (e, CHAN_AUTO, "walk/metal4.wav", 0.5, ATTN_NORM);
        }
        else
        {
            r = rint(random() * 4);         
            if (r == 0)
                sound (e, CHAN_AUTO, "walk/generic1.wav", 0.5, ATTN_NORM);
            else if (r == 1)
                sound (e, CHAN_AUTO, "walk/generic2.wav", 0.5, ATTN_NORM);
            else if (r == 2)
                sound (e, CHAN_AUTO, "walk/generic3.wav", 0.5, ATTN_NORM);
            else if (r == 3)
                sound (e, CHAN_AUTO, "walk/generic4.wav", 0.5, ATTN_NORM);
            else
                sound (e, CHAN_AUTO, "walk/generic5.wav", 0.5, ATTN_NORM);
        }
    }
};