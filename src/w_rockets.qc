/*
===============

ROCKETS

===============
*/


void(vector org, float rad) T_GibDownedZombies =
{
	if (rad < 72) return;	// not a big enough blast
	entity head;
	head = findradiusplus(org + '0 0 16', rad, type, "zombie");
	// look a little too high since we'll assume zombies are lower than their 
	// actual origin, which is 24u off the ground
	
	while(head)
	{
		if ( head.customflags & CFL_KNOCKEDDOWN &&	// on ground
			 head.solid == SOLID_NOT && // can't be hurt otherwise
			CanDamage(head, org) &&	// in sight
			rad - vlen(head.origin - org) > 0.5 * head.health	// close enough to hurt
			)
		{
			T_Damage (head, self, self, head.health + 10);
		}
		head = head.chain;
	}
}


// =======================================================

void() T_ExplosiveTouch =
{
	if (other.classname == "monster_shambler")
		BecomeWeakExplosion();
	else
		BecomeExplosion();
}

void() T_MissileExplode =
{
	local float	damg;
	damg = cvar("scarlet_dmg_rockets") - ((cvar("scarlet_dmg_rockets")/5) + random()*(cvar("scarlet_dmg_rockets")/5)); // was 100, SCARLET - custom dmg integration.
	
	if (other.health)
	{
		if (other.classname == "monster_shambler")
			damg = damg * 0.5;
		if (other.type == "zombie")
			damg = max(damg, other.health + 25);	// so ogre rockets kill zombies despite being too weak
		T_Damage (other, self, self.trueowner, damg );
	}

	// don't do radius damage to other, because all damage will be done in the impact
	T_RadiusDamage (self, self.trueowner, cvar("scarlet_dmg_rockets"), other); // was 120, SCARLET - custom dmg integration.

	ThrowBloodSplatByExplosion(self, cvar("scarlet_dmg_rockets")); // SCARLET - gore integration.
}

void() T_MissileTouch =
{
	if (other == self.owner) return;		// don't explode on owner
	if (CheckProjectilePassthru()) return;

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

	T_MissileExplode();

	self.origin = self.origin - 8*normalize(self.velocity);
	T_ExplosiveTouch();
}

/*
================
W_FireRocket
player rocket launch inherited from generic launch_rocket
================
*/
void() W_FireRocket =
{
	local entity missile;
	local vector loc;
	
	self.currentammo = self.ammo_rockets = self.ammo_rockets - cvar("scarlet_dec_rockets"); // was 1, SCARLET - custom ammo integration.
	
	sound (self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);

	self.punchangle_x = -1 * cvar("scarlet_kick_rl");
	
	makevectors (self.v_angle);
	loc = self.origin + v_forward * 8 + '0 0 16';
	
		missile = launch_rocket( loc, v_forward * 1000 );
		self.attack_finished = time + cvar("scarlet_rof_rl");
}

//=============================================================================

/*
===============

GERNADES

===============
*/

void() GrenadeExplode =
{
	T_RadiusDamage (self, self.trueowner, cvar("scarlet_dmg_rockets"), world); // was 120, SCARLET - custom dmg integration.
	//T_GibDownedZombies (self, cvar("scarlet_dmg_rockets"));

	ThrowBloodSplatByExplosion(self, cvar("scarlet_dmg_rockets")); // SCARLET - gore integration.
	
	BecomeExplosion ();
}

void() GrenadeTouch =
{
	if (other == self.owner ) return;		// don't explode on owner
	if (CheckProjectilePassthru()) return;
	if (other.takedamage == DAMAGE_AIM)
	{
		self.velocity = '0 0 0';
		T_MissileExplode();
		T_ExplosiveTouch();
		return;
	}
	sound (self, CHAN_WEAPON, "weapons/bounce.wav", 1, ATTN_NORM);	// bounce sound
	if (self.velocity == '0 0 0')
		self.avelocity = '0 0 0';
}

/*
================
W_FireGrenade
================
*/
void() W_FireGrenade =
{
	entity g;
	float base;
	vector gvel;
	
	self.currentammo = self.ammo_rockets = self.ammo_rockets - cvar("scarlet_dec_rockets"); // was 1, SCARLET - custom ammo integration.
	sound (self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);
	self.punchangle_x = -1 * cvar("scarlet_kick_gl");

	// set grenade speed	
	makevectors (self.v_angle);
	base = 200;
	if (self.v_angle_x)
		gvel = v_forward * base * 3 + v_up * base + crandom() * v_right * 10 + crandom() * v_up * 10;
	else
	{
		gvel = aim(self, AUTOAIM_DIST);
		gvel = gvel * base * 3;
		gvel_z = base;
	}
	
	g = launch_grenade(self.origin, gvel);
	self.attack_finished = time + cvar("scarlet_rof_gl");
	g.touch = GrenadeTouch;
	g.th_die = GrenadeExplode;
}
