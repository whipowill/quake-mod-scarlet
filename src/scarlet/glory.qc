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

    self.nextthink = time + .2;
};

void() ShardTouch =
{
    if (CheckProjectilePassthru()) return;

    // if NOT touched by player...
    if (!CheckValidTouch()) return;

    // if touched by owner...
    //if (other == self.owner) return;

    if (self.type == "shard_health")
    {
        sound(other, CHAN_ITEM, self.noise, 1, ATTN_NORM);
        T_Heal(other, cvar("scarlet_shards_health"), TRUE);
        armor_give(other, cvar("scarlet_shards_armor"), other.armortype, FALSE);
    }
    else if (self.type == "shard_armor") // not in use atm
    {
        sound(other, CHAN_ITEM, self.noise, 1, ATTN_NORM);
        armor_give(other, cvar("scarlet_shards_armor"), other.armortype, FALSE);
    }
    else if (self.type == "shard_mega")
    {
        sound(other, CHAN_POWERUP, self.noise, 1, ATTN_NORM);
        T_Heal(other, 100, TRUE);
    }
    else if (self.type == "shard_quad")
    {
        sound(other, CHAN_POWERUP, self.noise, 1, ATTN_NORM);
        powerup_super_damage(other, 30);
    }
    else if (self.type == "shard_pent")
    {
        sound(other, CHAN_POWERUP, self.noise, 1, ATTN_NORM);
        powerup_invulnerability(other, 30);
    }

    remove(self);
}

void(vector org, entity own) SpawnShards =
{
    if (!cvar("scarlet_shards") || !deathmatch) return;

    local entity shard;
    local float rand, is_rune;

    // loop
    local float i;
    local float m = cvar("scarlet_shards_multiplier") * (own.killstreak + 1);

    for (i=1; i<=m; i++)
    {
        if (random() <= cvar("scarlet_shards_chance"))
        {
            shard = spawn();
            shard.owner = own;
            shard.movetype = MOVETYPE_TOSS;
            shard.solid = SOLID_TRIGGER;

            shard.velocity = Vector(random(), random(), random()) * 240;

            shard.touch = ShardTouch;
            shard.think = ShardThink;
            shard.nextthink = time + (random()/2);

            shard.attack_finished = time + (cvar("scarlet_shards_expire")/2) + ((cvar("scarlet_shards_expire")/2)*random());

            rand = random();
            if (rand >= 0 && rand < .985)
            {
                shard.angles = '0 180 0'; // for stimpack
                setmodel (shard, "progs/items/rogue/mervup.mdl");
                shard.type = "shard_health";
                shard.noise = "items/r_item1.wav";
                setsize (shard, '-24 -24 -12', '24 24 12');
            }
            /*
            if (rand >= .50 && rand < .985)
            {
                shard.angles = '-90 180 -90';
                setmodel (shard, "progs/items/quoth/glass.mdl");
                shard.type = "shard_armor";
                shard.noise = "items/empathy2.wav";
                setsize (shard, '-24 -24 -12', '24 24 12');
            }
            */
            if (!is_rune && cvar("scarlet_shards_powerups"))
            {
                if (rand >= .985 && rand < .990)
                {
                    is_rune = 1;

                    setmodel (shard, "progs/items/quoth/cross.mdl");
                    shard.type = "shard_mega";
                    shard.noise = "items/r_item2.wav";
                    setsize (self, '-16 -16 -24', '16 16 32');
                }
                else if (rand >= .990 && rand < .995)
                {
                    is_rune = 1;

                    setmodel (shard, "progs/quaddama.mdl");
                    shard.type = "shard_quad";
                    shard.noise = "items/damage.wav";
                    setsize (shard, '-16 -16 -24', '16 16 32');
                }
                else if (rand >= .995)
                {
                    is_rune = 1;

                    setmodel (shard, "progs/invul.mdl");
                    shard.type = "shard_pent";
                    shard.noise = "items/protect.wav";
                    setsize (shard, '-16 -16 -24', '16 16 32');
                }
            }


            setorigin (shard, org); //start shard at point of damage
        }
    }
}