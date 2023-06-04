//-------------------------------------------------
// Messing w/ health/shield recharge abilities.
// by whipowill
//-------------------------------------------------

.float last_damaged_time; // keep track of the last time we got damaged
.float next_recharge_time;

void() RechargeShields =
{
    // if disabled
    if (!cvar("scarlet_recharge") || !deathmatch) return;

    // if not enough time has passed since last damaged
    if (time < (self.last_damaged_time + cvar("scarlet_recharge_cooldown")))
    {
        // reset
        self.next_recharge_time = 0;

        // end
        return;
    }

    // if not enough time has passed since last recharge
    if (time < self.next_recharge_time && self.next_recharge_time > 0) return;

    local float type = cvar("scarlet_recharge");
    local float rate_health = cvar("scarlet_recharge_health");
    local float rate_armor = cvar("scarlet_recharge_armor");

    local float pass_health;
    local float pass_armor, armor_max;

    if (rate_health > 0)
    {
        if (self.health < 100)
            pass_health = 1;
    }
    if (rate_armor > 0)
    {
        if (self.armortype == ARMORTYPE_GREEN && self.armorvalue < 100)
        {
            pass_armor = 1;
            armor_max = 100;
        }
        else if (self.armortype == ARMORTYPE_YELLOW && self.armorvalue < 150)
        {
            pass_armor = 1;
            armor_max = 150;
        }
        else if (self.armortype == ARMORTYPE_RED && self.armorvalue < 200)
        {
            pass_armor = 1;
            armor_max = 200;
        }
    }

    if (pass_health)
    {
        T_Heal(self, rate_health, FALSE); // flag false to not allow overheal
    }
    if (pass_armor)
    {
        rate_armor = ((armor_max - self.armorvalue) < rate_armor) ? armor_max - self.armorvalue : rate_armor;
        armor_give(self, rate_armor, self.armortype, FALSE); // flag false to allow increment instead of replace
    }

    // if we did anything...
    if (pass_health || pass_armor)
    {
        // if this was the first time
        //if (self.next_recharge_time == 0)
            //sound(self, CHAN_AUTO, "items/protect3.wav", 1, ATTN_NORM);

        // It doesn't seem to be an option to have a sound only play for the player.

        // set next tick
        self.next_recharge_time = time + 1;

        // end
        return;
    }

    // reset
    self.next_recharge_time = 0;
};