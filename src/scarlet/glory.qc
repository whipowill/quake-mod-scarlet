//-------------------------------------------------
// Enable glory kill rewards.
// by whipowill
//-------------------------------------------------

void() RewardThink =
{
    if ((self.attack_finished <= time))
    {
        remove(self);
        return;
    }

    // sleep until expiry instead of polling
    self.nextthink = self.attack_finished;
};

void() RewardTouch =
{
    // if NOT touched by player...
    if (!CheckValidTouch()) return;

    // if touched by owner...
    //if (other == self.owner) return;

    if (self.type == "reward_mega")
    {
        sound(other, CHAN_ITEM, self.noise, 1, ATTN_NORM);
        T_Heal(other, 100, TRUE);
    }
    else if (self.type == "reward_quad")
    {
        sound(other, CHAN_ITEM, self.noise, 1, ATTN_NORM);
        powerup_super_damage(other, 30);
    }
    else if (self.type == "reward_pent")
    {
        sound(other, CHAN_ITEM, self.noise, 1, ATTN_NORM);
        powerup_invulnerability(other, 30);
    }
    else if (self.type == "reward_weapon" || self.type == "item")
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

// drops one powerup (Megahealth, Quad or Pent, equally likely) at org
void(vector org) SpawnPowerup =
{
    local entity reward;
    local float pick;

    // the three powerups are equally likely
    pick = random();

    reward = spawn();
    //reward.owner = own;
    reward.movetype = MOVETYPE_TOSS;
    reward.solid = SOLID_TRIGGER;
    reward.flags = FL_ITEM; // so AI will know it's an item worth picking up

    reward.velocity = Vector(random(), random(), random()) * 500;
    reward.touch = RewardTouch;
    reward.think = RewardThink;

    reward.attack_finished = time + (cv_scarlet_rewards_expire/2) + ((cv_scarlet_rewards_expire/2)*random());
    reward.nextthink = reward.attack_finished;

    if (pick < 0.333)
    {
        setmodel (reward, "progs/items/quoth/cross.mdl");
        reward.type = "reward_mega";
        reward.classname = "item_health";
        reward.noise = "items/r_item2.wav";
    }
    else if (pick < 0.667)
    {
        setmodel (reward, "progs/quaddama.mdl");
        reward.type = "reward_quad";
        reward.classname = "item_artifact_super_damage";
        reward.noise = "items/damage.wav";
    }
    else
    {
        setmodel (reward, "progs/invulner.mdl");
        reward.type = "reward_pent";
        reward.classname = "item_artifact_invulnerability";
        reward.noise = "items/protect.wav";
    }
    setsize (reward, '-16 -16 -24', '16 16 32');

    setorigin (reward, org); //start reward at point of damage
}

void(vector org, entity own) SpawnRewards =
{
    if (!cv_scarlet_rewards || !deathmatch) return;

    local float chance;

    // chance of a powerup on this kill: a base chance plus a bonus for every kill in the
    // streak of the player who died.  Axe kills are 4x as likely.
    chance = cv_scarlet_rewards_drop_chance + (cv_scarlet_rewards_drop_streak * own.killstreak);
    if (own.enemy.weaponmodel == "progs/v_axe.mdl") chance = chance * 4;

    if (random() >= chance) return;

    SpawnPowerup(org);
}

// single player and coop: a monster killed by a player can drop a powerup
void(vector org) SpawnMonsterReward =
{
    if (!(coop || !deathmatch)) return;
    if (random() >= cv_scarlet_singleplayer_monsters_drop_chance) return;

    SpawnPowerup(org);
}

void(entity item) SpawnWeapons =
{
    if (cvar("weapons")) return;
    if (cv_scarlet_remove_weaker_weapons && item.netname == "Super Shotgun") return;
    //if (cv_scarlet_remove_weaker_weapons && item.netname == "Perforator") return;

    local entity weap;

    weap = spawn();
    weap.movetype = MOVETYPE_TOSS;
    weap.solid = SOLID_TRIGGER;

    weap.velocity = Vector(random(), random(), random()) * (50 + 150);
    weap.touch = RewardTouch;
    weap.think = RewardThink;
    weap.nextthink = time + (random()/2);

    weap.attack_finished = time + cv_scarlet_rewards_expire;

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

    weap.type = "reward_weapon";
    weap.noise = "weapons/pkup.wav";

    setsize (weap, '-16 -16 0', '16 16 56');
    setorigin (weap, item.origin); //start reward at point of damage
}