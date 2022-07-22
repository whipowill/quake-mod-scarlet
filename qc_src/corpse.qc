void () corpse_touch = 
{ 
        self.velocity = '0 0 0';

        if ((!other.flags & FL_ONGROUND) && (other.health) && (other.flags & FL_CLIENT))
                other.flags = other.flags + FL_ONGROUND;
};

.string headmdl;
void () corpse_die =

{
        sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NORM); //gib sound
        if (self.headmdl) //do we have a head? if not you must have forgotten that.
                ThrowHead (self.headmdl, self.health);
        ThrowGib ("progs/gib1.mdl", self.health);
        ThrowGib ("progs/gib2.mdl", self.health);
        ThrowGib ("progs/gib3.mdl", self.health);

        if (!self.headmdl) //if no head then this is needed!
                remove (self);
};

void () BecomeCorpse =

{
        self.health = 30;

        self.takedamage = DAMAGE_AIM;
        self.solid = SOLID_SLIDEBOX;
        self.movetype = MOVETYPE_STEP;
        self.flags = self.flags & (!FL_MONSTER);

        //make shamblers bigger
        if (self.classname == "monster_shambler")
                setsize (self, '-32 -32 -24', '32 32 -14');
        else
                setsize (self, '-32 -32 -24', '32 32 -19');

        self.classname = "monster_corpse";

        self.origin_z = self.origin_z + 3; //less likely to fall into ground

//target stuff: if a monsters death sets off a trigger then dont let the corpses
//death do the same
        self.use = SUB_Null;
        self.target = string_null;
        self.killtarget = string_null;
        self.targetname = string_null;

        self.th_die = corpse_die;
        self.th_stand = SUB_Null;
        self.th_walk = SUB_Null;
        self.th_run = SUB_Null;
        self.th_missile = SUB_Null;
        self.th_melee = SUB_Null;
        self.th_pain = SUB_Null;
        self.touch = corpse_touch;
};