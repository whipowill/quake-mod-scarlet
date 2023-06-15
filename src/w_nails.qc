/*
================
spawn_touchblood

only used by nailguns so now it's here
================
*/
void(float damage) spawn_touchblood =
{
	local vector	vel;

	vel = normalize(self.velocity) * -1;
	vel = normalize(vel + v_up*(random()- 0.5) + v_right*(random()- 0.5));
	
	//vel = vel + 2*trace_plane_normal;
	// nailguns don't do traces so there is no valid trace plane normal
	// (which explains why nailgun blood spurts always seemed to be caught in some strange wind)
	
	SpawnBlood (self.origin + vel, vel * 40, damage);
}



// --------------------------------

vector(vector muzzle) W_SpikeOrigin =
{
	return (self.origin + '0 0 16' + 
			11 * v_forward +
			muzzle_x * v_right +
			muzzle_z * v_up);
}

vector(vector fwd, float spread) W_SpikeDir =
{
	return normalize(fwd + (2 * v_right * crandom() + v_up * crandom()) * spread / 100);
}

void() W_FireNailgun =
{
	vector offset, v, org, dir;
	// remember sv_aim
	dir = aim( self, AUTOAIM_DIST );
	v = vectoangles( dir );
	v_x *= -1;	// pitch comes back inverted from vectoangles :|
	makevectors( v );

	sound (self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
	self.currentammo = self.ammo_nails = self.ammo_nails - cvar("scarlet_dec_nails"); // was 1, SCARLET - custom ammo integration.
	offset = VEC_ORIGIN;
	if ( mod( self.cnt, 2 ) ) offset_x = -2.5;
	else offset_x = 2.5;	

	org = W_SpikeOrigin(offset);
	dir = W_SpikeDir(v_forward, cvar("scarlet_spr_ng")); // Lunaran removed this in 1.20? SCARLET spread

	// default sv_maxvelocity is 2000, any higher leads to weird 
	// angular offsets caused by clamping the velocity
	if (cvar("scarlet_spd_ng") >= 1999)
	{
		ClearMultiDamage();
		FireBullets(2, cvar("scarlet_dmg_nails")/2, aim(self, AUTOAIM_DIST), Vector(cvar("scarlet_spr_ng")/100, cvar("scarlet_spr_ng")/100/2, 0));
		ApplyMultiDamage();
	}
	else
	{
		launch_nail(org, dir * cvar("scarlet_spd_ng"));
	}
	self.attack_finished = time + cvar("scarlet_rof_ng");
}

void() spike_unfatten = { self.movetype = MOVETYPE_FLY; }

void() W_FirePerforator =
{
	vector offset;
	sound (self, CHAN_WEAPON, "weapons/spike2.wav", 1, ATTN_NORM);
	self.currentammo = self.ammo_nails = self.ammo_nails - (cvar("scarlet_dec_nails") * 2); // was 2, SCARLET - custom ammo integration.
	
	if (mod(self.cnt, 4) == 0) offset = '0 0 1.25';
	else if (mod(self.cnt, 4) == 1) offset = '1 0 1';
	else if (mod(self.cnt, 4) == 2) offset = '1.25 0 0';
	else if (mod(self.cnt, 4) == 3) offset = '1 0 -1';
	
	if (cvar("scarlet_spd_sng") >= 1999)
	{
		ClearMultiDamage();
		FireBullets(4, cvar("scarlet_dmg_nails")/2, aim(self, AUTOAIM_DIST), Vector(cvar("scarlet_spr_sng")/100, cvar("scarlet_spr_sng")/100/2, 0));
		ApplyMultiDamage();
	}
	else
	{
		entity spike1, spike2;
		spike1 = launch_nail(W_SpikeOrigin(offset), W_SpikeDir(v_forward, cvar("scarlet_spr_sng")) * cvar("scarlet_spd_sng"));
		spike2 = launch_nail(W_SpikeOrigin(-offset), W_SpikeDir(v_forward, cvar("scarlet_spr_sng")) * cvar("scarlet_spd_sng"));

		// weaken the SNG at long distance while keeping the spread under control
		spike1.think = spike_unfatten;
		spike2.think = spike_unfatten;
		spike1.nextthink = time + 0.25;
		spike2.nextthink = time + 0.3;

		if (has_quad(self))
		{
			// here's a silly thing:
			// one vanilla SNG nail does 18 dmg, 72 with quad, enough to gib zombies and grunts.
			// two copper nails do 9 each, 36 each with quad, for the same total damage, but that
			//   only kills grunts and knocks zombies down because the second nail doesn't hit.

			// the dumb solution is to make one nail do 0 dmg and the other do 18 in quad mode
			//   so the math works out like the old math and the quad SNG still feels right
			spike2.dmg = cvar("scarlet_dmg_nails")*2; // SCARLET - custom dmg integration.
			spike1.dmg = cvar("scarlet_dmg_nails")*2; // SCARLET - custom dmg integration.
			spike2.buddy = spike1;
			spike1.buddy = spike2;
			// first one to hit does its damage and then nerfs its 'buddy'
		}
	}

	self.attack_finished = time + cvar("scarlet_rof_sng");
}

void() W_FireSpikes =
{
	if (self.ammo_nails < 1 || (self.ammo_nails < 2 && !(self.items & IT_NAILGUN)))
	{
		W_SelectBestWeapon();
		return;
	}
	if (self.ammo_nails >= 2 && self.weapon == IT_SUPER_NAILGUN)
	{
		W_FirePerforator();
		self.punchangle_x = -1 * cvar("scarlet_kick_sng");
	}
	else
	{
		W_FireNailgun();
		self.punchangle_x = -1 * cvar("scarlet_kick_ng");
	}
	
	self.cnt = cycle(self.cnt,8);
}

float() CheckValidSpikeTouch =
{
	if (other == self.owner) return FALSE;
	if (other.solid == SOLID_TRIGGER) return FALSE;
	if (CheckProjectilePassthru()) return FALSE;

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return FALSE;
	}
	
	return TRUE;
}


void() spike_touch =
{
	if (!CheckValidSpikeTouch()) return;
	
	if (self.dmg)
	{
		if (other.takedamage)
		{
			spawn_touchblood (self.dmg);
			T_Damage (other, self, self.trueowner, self.dmg);

			// SCARLET - gore integration.
			self.angles_x = self.angles_x*-1;
			makevectors(self.angles);
			ThrowBloodSplat(v_forward, self.origin, other, self.dmg, 2);
			// SCARLET - end.
		}
		else
		{
			WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
			
			switch(self.classname)
			{
			case "wizspike":
				WriteByte (MSG_BROADCAST, TE_WIZSPIKE); break;
			case "knightspike":
				WriteByte (MSG_BROADCAST, TE_KNIGHTSPIKE); break;
			case "laser":
				WriteByte(MSG_BROADCAST, TE_GUNSHOT); break;
			default:
				WriteByte (MSG_BROADCAST, TE_SPIKE);
			}
			WriteCoord (MSG_BROADCAST, self.origin_x);
			WriteCoord (MSG_BROADCAST, self.origin_y);
			WriteCoord (MSG_BROADCAST, self.origin_z);
		}
		
		if (self.classname == "laser")
		{
			sound (self, CHAN_WEAPON, "enforcer/enfstop.wav", 1, ATTN_STATIC);
			particle (self.origin, self.velocity*-0.01, 235, 15);
		}
	}
	// nonsense for combining quad SNG spike damage
	if (self.buddy)
		self.buddy.dmg = 0;
	remove(self);
}


