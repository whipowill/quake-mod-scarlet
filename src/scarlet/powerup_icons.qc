// -------------------------------------------------
// Show a miniature spinning quad or pentagram above the head of anyone carrying one.
// by whipowill
//
// scale is an engine field (QSS, FTE, DarkPlaces, and vkQuake/QuakeSpasm with the RMQ
// protocol).  On an engine that ignores it the icons just show up full size, in which
// case turn this off with scarlet_powerup_icons 0.
// -------------------------------------------------

.float      scale;
.float      icon_kind;  // 1 = pentagram, 2 = quad
.entity     pent_icon, quad_icon;

void() PowerupIconThink =
{
    local entity plr = self.owner;
    local float held, height;

    if (self.icon_kind == 1)
        held = plr.items & IT_INVULNERABILITY;
    else
        held = plr.items & IT_QUAD;

    // an invisible player shouldn't give themselves away
    if (plr.health <= 0 || !held || (plr.items & IT_INVISIBILITY) || !cv_scarlet_powerup_icons)
    {
        remove(self);
        return;
    }

    // stack them if the player has both
    height = cv_scarlet_powerup_icon_height;
    if (self.icon_kind == 1 && (plr.items & IT_QUAD))
        height = height + 12;

    setorigin(self, plr.origin + '0 0 1' * (height + 3 * sin(time * 3)));
    self.nextthink = time;
};

entity(entity plr, float kind) PowerupIconSpawn =
{
    local entity icon = spawn();

    icon.classname = "powerup_icon";
    icon.owner = plr;
    icon.icon_kind = kind;
    icon.movetype = MOVETYPE_NOCLIP; // so avelocity spins it
    icon.solid = SOLID_NOT;
    icon.avelocity = '0 120 0';
    icon.scale = cv_scarlet_powerup_icon_scale;

    if (kind == 1)
        setmodel(icon, "progs/invulner.mdl");
    else
        setmodel(icon, "progs/quaddama.mdl");
    setsize(icon, '0 0 0', '0 0 0');
    setorigin(icon, plr.origin + '0 0 1' * cv_scarlet_powerup_icon_height);

    icon.think = PowerupIconThink;
    icon.nextthink = time;

    return icon;
};

// meant to be called every frame for a player (see CheckPowerups)
void() PowerupIcons =
{
    if (!cv_scarlet_powerup_icons) return;
    if (self.items & IT_INVISIBILITY) return;

    // the icon removes itself when the powerup ends, so a stale pointer means make a new one
    if (self.items & IT_INVULNERABILITY)
        if (self.pent_icon.classname != "powerup_icon" || self.pent_icon.owner != self)
            self.pent_icon = PowerupIconSpawn(self, 1);

    if (self.items & IT_QUAD)
        if (self.quad_icon.classname != "powerup_icon" || self.quad_icon.owner != self)
            self.quad_icon = PowerupIconSpawn(self, 2);
};
