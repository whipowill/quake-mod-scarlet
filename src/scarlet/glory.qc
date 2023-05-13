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

    self.touch = ShardTouch;
    self.nextthink = time + .5;
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
    else if (self.type == "shard_weapon" || self.type == "item")
    {
        sound(other, CHAN_WEAPON, self.noise, 1, ATTN_NORM);

        other.items |= self.items;

        local entity oself = self;
        self = other;
        // change to the weapon
        W_BetterWeapon(oself.items);
        self = oself;
    }

    remove(self);
}

void(vector org, entity own) SpawnShards =
{
    if (!cvar("scarlet_shards") || !deathmatch) return;

    local entity shard;
    local float rand, is_rune;

    local float rune_chance = cvar("scarlet_shards_powerups") ? cvar("scarlet_shards_powerups_chance") : 0;
    local float rune_nochance = 1 - (rune_chance * 3);

    // loop
    local float i;
    local float m = cvar("scarlet_shards_multiplier") * (own.killstreak + 1);

    if (own.enemy.weaponmodel == "progs/v_axe2.mdl") m = m*4;

    local float pass;
    for (i=1; i<=m; i++)
    {
        if (random() <= cvar("scarlet_shards_chance"))
        {
            rand = random();

            pass = 1;
            if (cvar("scarlet_shards_powerups") == 2 && rand < rune_nochance)
            {
                pass = 0;

                // if this is a glory kill
                if (own.enemy.weaponmodel == "progs/v_axe2.mdl") pass = 1;

                // if this is a killstreak kill
                if (own.enemy.killstreak/5 == floor(own.enemy.killstreak/5)) pass = 1;
            }

            if (pass)
            {
                shard = spawn();
                shard.owner = own;
                shard.movetype = MOVETYPE_TOSS;
                shard.solid = SOLID_TRIGGER;

                shard.velocity = Vector(random(), random(), random()) * (50 + 300);
                if (own.enemy.weaponmodel != "progs/v_axe2.mdl")
                    shard.touch = ShardTouch; // if not glory kill, allow immediate absorb of shards
                shard.think = ShardThink;
                shard.nextthink = time + 1;

                shard.attack_finished = time + (cvar("scarlet_shards_expire")/2) + ((cvar("scarlet_shards_expire")/2)*random());

                if (rand >= 0 && rand < rune_nochance)
                {
                    shard.angles = '0 180 0'; // for stimpack
                    setmodel (shard, "progs/items/rogue/mervup_edited.mdl");
                    shard.type = "shard_health";
                    shard.noise = "items/r_item1.wav";
                    setsize (shard, '-24 -24 -16', '24 24 16');
                }
                if (!is_rune && cvar("scarlet_shards_powerups"))
                {
                    if (rand >= rune_nochance && rand < (rune_nochance + (rune_chance*1)))
                    {
                        is_rune = 1;

                        setmodel (shard, "progs/items/quoth/cross.mdl");
                        shard.type = "shard_mega";
                        shard.noise = "items/r_item2.wav";
                        setsize (self, '-16 -16 -24', '16 16 32');
                    }
                    else if (rand >= (rune_nochance + (rune_chance*1)) && rand < (rune_nochance + (rune_chance*2)))
                    {
                        is_rune = 1;

                        setmodel (shard, "progs/quaddama.mdl");
                        shard.type = "shard_quad";
                        shard.noise = "items/damage.wav";
                        setsize (shard, '-16 -16 -24', '16 16 32');
                    }
                    else if (rand >= (rune_nochance + (rune_chance*2)))
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
}

void(entity item) SpawnWeapons =
{
    if (cvar("weapons")) return;
    if (cvar("scarlet_limited") && item.netname == "Super Shotgun") return;
    //if (cvar("scarlet_limited") && item.netname == "Perforator") return;

    local entity weap;

    weap = spawn();
    weap.movetype = MOVETYPE_TOSS;
    weap.solid = SOLID_TRIGGER;

    weap.velocity = Vector(random(), random(), random()) * (50 + 150);
    weap.touch = ShardTouch;
    weap.think = ShardThink;
    weap.nextthink = time + (random()/2);

    weap.attack_finished = time + cvar("scarlet_shards_expire");

    weap.flags = FL_ITEM;

    if (item.netname == "Shotgun")
    {
        return;

        //setmodel (weap, "progs/g_shotgn.mdl");
        //weap.items = IT_SHOTGUN;
        //weap.netname = "Shotgun";
    }
    else if (item.netname == "Super Shotgun")
    {
        setmodel (weap, "progs/g_shot.mdl");
        weap.items = IT_SUPER_SHOTGUN;
        weap.netname = "Super Shotgun";
    }
    else if (item.netname == "Nailgun")
    {
        setmodel (weap, "progs/g_nail.mdl");
        weap.items = IT_NAILGUN;
        weap.netname = "Nailgun";
    }
    else if (item.netname == "Perforator")
    {
        setmodel (weap, "progs/g_nail2.mdl");
        weap.items = IT_SUPER_NAILGUN;
        weap.netname = "Perforator";
    }
    else if (item.netname == "Grenade Launcher")
    {
        setmodel (weap, "progs/g_rock.mdl");
        weap.items = IT_GRENADE_LAUNCHER;
        weap.netname = "Grenade Launcher";
    }
    else if (item.netname == "Rocket Launcher")
    {
        setmodel (weap, "progs/g_rock2.mdl");
        weap.items = IT_ROCKET_LAUNCHER;
        weap.netname = "Rocket Launcher";
    }
    else if (item.netname == "Thunderbolt")
    {
        setmodel (weap, "progs/g_light.mdl");
        weap.items = IT_LIGHTNING;
        weap.netname = "Thunderbolt";
    }

    weap.type = "shard_weapon";
    weap.noise = "weapons/pkup.wav";

    setsize (weap, '-16 -16 0', '16 16 56');
    setorigin (weap, item.origin); //start shard at point of damage
}