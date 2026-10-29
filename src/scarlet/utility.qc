// -------------------------------------------------
// Small helpers the bot and Scarlet code share.
// by whipowill
// -------------------------------------------------

float(float a, float b) min = { if (a <= b) return a; return b; }
float(float a, float b) max = { if (a >= b) return a; return b; }

// a without the bits that b has set
float(float a, float b) not = { return a - (a & b); }

// wrap the self/oself shuffle for code cleanliness elsewhere
void(void() fun, entity newself) SUB_CallAsSelf =
{
	local entity oself;

	oself = self;
	self = newself;
	fun();
	self = oself;
}

// the sound and sparkle of a teleport, at self
void() teleport_flash =
{
	local	float v;
	local	string snd;

	v = random() * 5;
	if (v < 1)
		snd = "misc/r_tele1.wav";
	else if (v < 2)
		snd = "misc/r_tele2.wav";
	else if (v < 3)
		snd = "misc/r_tele3.wav";
	else if (v < 4)
		snd = "misc/r_tele4.wav";
	else
		snd = "misc/r_tele5.wav";

	sound (self, CHAN_VOICE, snd, 1, ATTN_NORM);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_TELEPORT);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);
}

// ---- helpers that Copper had and the mod still uses

vector(float x, float y, float z) Vector =
{
	local vector v;
	v_x = x;
	v_y = y;
	v_z = z;
	return v;
}

float(float a, float b) mod =
{
	return a - (floor(a / b) * b);
}

// count up and wrap back to 0 at the limit
float(float a, float limit) cycle =
{
	a = a + 1;
	if (a >= limit) return 0;
	return a;
}

float(entity who) has_quad = { return (who.items & IT_QUAD || who.super_damage_finished > time); }

// a live player that is really there, for touch functions
float() CheckValidTouch =
{
	if (other.classname != "player")
		return FALSE;
	if (other.health <= 0)
		return FALSE;
	if (other.movetype == MOVETYPE_NOCLIP)
		return FALSE;
	return TRUE;
}

// move traveler to dst (a teleporter, or a player), with the flashes if tfog
void(entity traveler, entity dst, float tfog, float nofwd) teleport =
{
	local vector vdir;

	if (dst.classname == "player")
		vdir = dst.angles;
	else
		vdir = dst.mangle;

	if (tfog)
	{
		SUB_CallAsSelf(teleport_flash, traveler);
		spawn_tfog(dst.origin);
	}
	spawn_tdeath(dst.origin, traveler);

	setorigin(traveler, dst.origin);
	traveler.angles = vdir;
	if (traveler.flags & FL_MONSTER)
		traveler.ideal_yaw = traveler.angles_y;

	if (traveler.classname == "player")
	{
		traveler.fixangle = 1;
		traveler.velocity = '0 0 0';
		if (!nofwd)
		{
			makevectors(traveler.angles);
			traveler.velocity = v_forward * 300;
		}
	}
	traveler.flags = traveler.flags - (traveler.flags & FL_ONGROUND);
}

// the armor tiers: how much of a hit each one absorbs (scarlet_absorb_green, _yellow, _red)
// which tier is an armortype closest to?  0 for none, 1 green, 2 yellow, 3 red
float(float t) armor_tier =
{
	if (t <= 0)
		return 0;
	if (t < (cv_scarlet_absorb_green + cv_scarlet_absorb_yellow) / 2)
		return 1;
	if (t < (cv_scarlet_absorb_yellow + cv_scarlet_absorb_red) / 2)
		return 2;
	return 3;
}

// give armor: replace takes the new type and amount (unless it is a downgrade), otherwise the amount is added
float(entity e, float amt, float absorb, float replace) armor_give =
{
	if (!amt)
		return FALSE;
	if (replace)
	{
		if (absorb * amt <= e.armortype * e.armorvalue)
			return FALSE;	// id's test: the old armor is worth as much or more
		e.armortype = absorb;
		e.armorvalue = amt;
	}
	else
	{
		if (e.armortype == 0)
			e.armortype = cv_scarlet_absorb_green;
		e.armorvalue = e.armorvalue + amt;
	}

	e.items = e.items - (e.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3));
	if (!e.armorvalue)
		e.armortype = 0;
	else if (armor_tier(e.armortype) == 1)
		e.items = e.items | IT_ARMOR1;
	else if (armor_tier(e.armortype) == 2)
		e.items = e.items | IT_ARMOR2;
	else
		e.items = e.items | IT_ARMOR3;
	return TRUE;
}

void(entity h, float t) powerup_invulnerability =
{
	sprint (h, "An unholy ward surrounds you ...\n");
	h.items = h.items | IT_INVULNERABILITY;
	h.invincible_time = 1;
	h.invincible_finished = time + t;
}

void(entity h, float t) powerup_super_damage =
{
	sprint (h, "You begin to channel unstoppable power ...\n");
	h.items = h.items | IT_QUAD;
	h.super_damage_finished = time + t;
	h.super_time = 1;
}
