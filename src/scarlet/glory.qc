//-------------------------------------------------
// Enable glory kill shards.
// by whipowill
//-------------------------------------------------

void() ShardThink =
{
    if ((self.attack_finished <= time))
    {
        remove(self);
        return;
    }

    /*
    if (self.alpha > .9)
        self.alpha = 0.8;
    else if (self.alpha == 0.8)
        self.alpha = 0.6;
    else if (self.alpha == 0.6)
        self.alpha = 0.5;
    else if (self.alpha == 0.5)
        self.alpha = 0.7;
    else if (self.alpha == 0.7)
        self.alpha = 0.9;
    else if (self.alpha < .1)
        self.alpha = 1;
    */

    self.nextthink = time + .2;
};

void() ShardTouch =
{
    if (CheckProjectilePassthru()) return;

    // if NOT touched by player...
    if (!CheckValidTouch()) return;

    // if touched by owner...
    //if (other == self.owner) return;

    if (self.type == "shard1")
    {
        T_Heal(other, cvar("scarlet_shards_health"), TRUE);
        armor_give(other, cvar("scarlet_shards_armor"), other.armortype, FALSE);
    }

    sound(other, CHAN_ITEM, self.noise, 1, ATTN_NORM);

    remove(self);
}

void(vector org, entity own) SpawnShards =
{
    if (!cvar("scarlet_shards")) return;

    local entity shard;

    // loop
    local float i;
    local float j = cvar("scarlet_shards_count"); // number of times to loop

    if (!deathmatch) j = ceil(j / 3);

    for (i=1; i<=j; i++)
    {
        if (random() <= cvar("scarlet_shards_chance"))
        {
            shard = spawn();
            shard.owner = own;
            shard.movetype = MOVETYPE_TOSS;
            shard.solid = SOLID_TRIGGER;

            shard.angles = '0 180 0';
            //shard.avelocity = Vector(random(),random(),random()) * 100;
            shard.velocity = Vector(random(), random(), random()) * 240;

            shard.touch = ShardTouch;
            shard.think = ShardThink;
            shard.nextthink = time + (random()/2);

            shard.attack_finished = time + (cvar("scarlet_shards_expire")/2) + ((cvar("scarlet_shards_expire")/2)*random());

            setmodel (shard, "progs/items/mervup.mdl");
            shard.type = "shard1";
            shard.noise = "items/r_item1.wav";
            setsize (shard, '-24 -24 -12', '24 24 12');
            setorigin (shard, org); //start shard at point of damage

            shard.alpha = 1;
        }
    }
}