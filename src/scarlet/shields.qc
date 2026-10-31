//-------------------------------------------------
// Messing w/ health/shield recharge abilities.
// by whipowill
//-------------------------------------------------

.float last_damaged_time; // keep track of the last time we got damaged
.float regen_second; // the whole second of game time this player last had its beat, the one the streak healing and the recharge both go by

void() RechargeShields =
{
    // one beat a second, on the turn of each whole second of game time, and everything that heals goes by it, so
    // the streak healing, the health recharge and the armor recharge below always land on the same frame, and that
    // frame is the same for every player (a timer counted from each player's own last beat would drift apart)
    local float beat = (floor(time) != self.regen_second);
    if (beat)
        self.regen_second = floor(time);

    // killstreak healing: every skull earned heals scarlet_killstreak_heal health on each beat, and unlike
    // the recharge below it does not wait for a break in the fighting
    if (beat && cv_scarlet_killstreak_heal > 0)
    {
        local float skulls = KillstreakTier(self);
        if (skulls > cv_scarlet_killstreak_vfx_skulls_max) skulls = cv_scarlet_killstreak_vfx_skulls_max;
        if (skulls >= 1)
            T_Heal(self, skulls * cv_scarlet_killstreak_heal, FALSE); // flag false to not allow overheal
    }

    // if disabled
    if (!cv_scarlet_recharge) return;

    // if not enough time has passed since last damaged
    if (time < (self.last_damaged_time + cv_scarlet_recharge_cooldown))
    {
        // end
        return;
    }

    // not on the beat
    if (!beat) return;

    local float type = cv_scarlet_recharge;
    local float rate_health = cv_scarlet_recharge_health;
    local float rate_armor = cv_scarlet_recharge_armor;

    local float pass_health;
    local float pass_armor, armor_max;

    if (rate_health > 0)
    {
        if (self.health < 100)
            pass_health = 1;
    }
    if (rate_armor > 0)
    {
        if (armor_tier(self.armortype) == 1 && self.armorvalue < 100)
        {
            pass_armor = 1;
            armor_max = 100;
        }
        else if (armor_tier(self.armortype) == 2 && self.armorvalue < 150)
        {
            pass_armor = 1;
            armor_max = 150;
        }
        else if (armor_tier(self.armortype) == 3 && self.armorvalue < 200)
        {
            pass_armor = 1;
            armor_max = 200;
        }
    }

    local float log_health = self.health;
    local float log_armor = self.armorvalue;

    if (pass_health)
    {
        T_Heal(self, rate_health, FALSE); // flag false to not allow overheal
    }
    if (pass_armor)
    {
        rate_armor = ((armor_max - self.armorvalue) < rate_armor) ? armor_max - self.armorvalue : rate_armor;
        armor_give(self, rate_armor, self.armortype, FALSE); // flag false to allow increment instead of replace
    }

    // dev: say what the recharge did, and when, in the player's own console
    if (cv_scarlet_dev_rechargelog && (pass_health || pass_armor))
    {
        sprint(self, "RECHARGE time ");
        sprint(self, ftos(time));
        sprint(self, " health ");
        sprint(self, ftos(log_health));
        sprint(self, "->");
        sprint(self, ftos(self.health));
        sprint(self, " armor ");
        sprint(self, ftos(log_armor));
        sprint(self, "->");
        sprint(self, ftos(self.armorvalue));
        sprint(self, "\n");
    }

};
