/*
===============

BULLETS

sg:		6 * 4 = 24		/ 48 / 72 / 96 / 120
ssg:	14 * 4 = 56		/ 112 / 168 / 224 / 280

sg:		5 * 5 = 25		/ 50 / 75 / 100 / 125
ssg:	11 * 5 = 55		/ 110 / 165 / 220 / 275
ssg:	12 * 5 = 60		/ 120 / 180 / 240 / 300

===============
*/

vector(vector dir, vector spread) SpreadVector = 
{
	return dir + crandom()*spread_x*v_right + crandom()*spread_y*v_up;
}

/*
================
BulletImpact
Go to the trouble of combining multiple pellets into a single damage call.
================
*/
vector(float damage, vector dir, float is_nail_converted_to_hitscan = 0) BulletImpact =
{
	vector vel, org;
	
	vel = normalize(dir + v_up*crandom() + v_right*crandom());
	vel = vel + 2*trace_plane_normal;

	org = trace_endpos - dir*4;

	if (trace_ent.takedamage)
	{
		SpawnBlood (org, vel*40, damage);
		AddMultiDamage (trace_ent, damage);

		ThrowBloodSplat(dir, trace_endpos, trace_ent, damage, is_nail_converted_to_hitscan ? 2 : 1); // SCARLET - gore integration.
	}
	else gunshot(org);

	return org;
}

float(entity t) HasBeenShotToDeath =
{
	if (t.multi_dmg < t.health) return FALSE;
	if (DamageCanKill(t,t.multi_dmg)) return TRUE;
	return FALSE;
}

/*
================
FireBullets

Used by shotgun, super shotgun, and enemy soldier firing
================
*/
void(float shotcount, float dmg, vector dir, vector spread, float is_nail_converted_to_hitscan = 0) FireBullets =
{
	vector src, direction;
	entity ig;
	float s, lim;
	
	if (shotcount <= 0) return;
	
	makevectors(self.v_angle);

	if (trace_debug) dprint3("*** firing ", ftos(shotcount), " bullets *\n\n");
	for (s = 0; s < shotcount; s++)
	{
		src = self.origin + v_forward*10;
		src_z = self.absmin_z + self.size_z * 0.7;
		direction = SpreadVector(dir, spread);
		
		if (trace_debug) dprint("* firing a bullet *\n");
		
		lim = 0;
		// check for trace-through cases
		for (ig = self; ig != world; lim++)	// ig == world if we hit a wall or hit nothing
		{
			traceline2(src, src + direction*2048, ig, 0);
			
			// if we've already pelted a monster enough to kill it, let additional bullets add 
			// up for possible gibs (ala quake), but trace them again through the target for 
			// better crowd control feels (ala doom).
			// this is only noticeable with big hordes of weak guys, but it makes big hordes of
			// weak guys not feel like solid ammo-sponge walls.
			if (trace_ent.takedamage && 
				(trace_ent.flags & FL_MONSTER || trace_ent.classname == "player" ) && 
				// some id shootables are actually trigger_multiples with health and SOLID_BBOX, so this doesn't work (see e1m6):
				//( trace_ent.solid == SOLID_BBOX || trace_ent.solid == SOLID_SLIDEBOX ) &&	
				HasBeenShotToDeath(trace_ent) )
			{
				BulletImpact (dmg, direction, is_nail_converted_to_hitscan); // was 2+2*random(), SCARLET - custom dmg integration.

				// start 0.1 unit forward, or else when shooting an adjacent enemy we'll
				// just hit ourselves again
				src = trace_endpos + direction * 0.1;
				ig = trace_ent;
				if (trace_debug) dprint3("bullet hit ", ig.classname, ", continuing thru\n");
			}
			else
			{
				if (trace_debug) dprint("bullet reached world\n");
				ig = world;
			}
			if (lim > 8)
			{
				dprint("bullet pen limit exceeded\n");
				break;
			}
		}
		
		if (trace_fraction != 1.0)
		{
			BulletImpact (dmg, direction, is_nail_converted_to_hitscan); // was 4, SCARLET - custom dmg integration.
		}
		
		if (trace_debug) dprint("bullet is over\n\n");
	}
}

/*
================
W_FireShotgun
================
*/
void() W_FireShotgun =
{
	local vector dir;
	
	// for ai_nav:
	/*if (nav_w_nodeLink())
	{
		self.attack_finished = time + cvar("scarlet_rof_sg");
		return;
	}*/
	
	sound (self, CHAN_WEAPON, "weapons/guncock.wav", 1, ATTN_NORM);	

	self.punchangle_x = -1 * cvar("scarlet_kick_sg");
	makevectors(self.v_angle);
	
	self.currentammo = self.ammo_shells = self.ammo_shells - cvar("scarlet_dec_shells"); // was 1, SCARLET - custom ammo integration.
	dir = aim (self, AUTOAIM_DIST);

	ClearMultiDamage ();
	FireBullets (cvar("scarlet_bullets_in_shell_sg"), cvar("scarlet_dmg_bullets"), dir, Vector(cvar("scarlet_spr_sg")/100, cvar("scarlet_spr_sg")/100/2, 0)); // was 6, SCARLET - custom ammo integration.
	self.attack_finished = time + cvar("scarlet_rof_sg");
	
	ApplyMultiDamage ();
}


/*
================
W_FireSuperShotgun
================
*/
void() W_FireSuperShotgun =
{
	local vector dir;
	
	// for ai_nav:
	/*if (nav_w_nodeLinkSpecial())
	{
		self.attack_finished = time + cvar("scarlet_rof_ssg");
		return;
	}*/

	if (self.currentammo == 1)
	{
		if (self.items & IT_SHOTGUN)
			W_FireShotgun ();
		return;
	}
		
	sound (self, CHAN_WEAPON, "weapons/shotgn2.wav", 1, ATTN_NORM);

	self.punchangle_x = -1 * cvar("scarlet_kick_ssg");
	
	self.currentammo = self.ammo_shells = self.ammo_shells - (cvar("scarlet_dec_shells") * 2); // was 2, SCARLET - custom ammo integration.
	dir = aim (self, AUTOAIM_DIST);

	ClearMultiDamage ();

	FireBullets (cvar("scarlet_bullets_in_shell_ssg"), cvar("scarlet_dmg_bullets"), dir, Vector(cvar("scarlet_spr_ssg")/100, cvar("scarlet_spr_ssg")/100/2, 0)); // was 14, SCARLET - custom ammo integration.
	self.attack_finished = time + cvar("scarlet_rof_ssg");
	
	ApplyMultiDamage ();

}
