/*  Copyright (C) 1996-1997  Id Software, Inc.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

    See file, 'COPYING', for details.
*/
/*
*/
void (entity targ, entity inflictor, entity attacker, float damage) T_Damage;
void () player_run;
void(entity bomb, entity attacker, float rad, entity ignore) T_RadiusDamage;
void(vector org, vector vel, float damage) SpawnBlood;
void() SuperDamageSound;


// called by worldspawn
void() W_Precache =
{
	precache_sound ("weapons/r_exp3.wav");	// new rocket explosion
	precache_sound ("weapons/rocket1i.wav");	// spike gun
	precache_sound ("weapons/sgun1.wav");
	precache_sound ("weapons/guncock.wav");	// player shotgun
	precache_sound ("weapons/ric1.wav");	// ricochet (used in c code)
	precache_sound ("weapons/ric2.wav");	// ricochet (used in c code)
	precache_sound ("weapons/ric3.wav");	// ricochet (used in c code)
	precache_sound ("weapons/spike2.wav");	// super spikes
	precache_sound ("weapons/tink1.wav");	// spikes tink (used in c code)
	precache_sound ("weapons/grenade.wav");	// grenade launcher
	precache_sound ("weapons/bounce.wav");		// grenade bounce
	precache_sound ("weapons/shotgn2.wav");	// super shotgun

	S_Precache(); // SCARLET - gore integration.
};

float() crandom =
{
	return 2*(random() - 0.5);
};

/*
================
W_FireAxe
================
*/
void() W_FireAxe =
{
	local	vector	source;
	local	vector	org;

	source = self.origin + '0 0 16';
	traceline (source, source + v_forward*64, FALSE, self);
	if (trace_fraction == 1.0)
		return;
	
	org = trace_endpos - v_forward*4;

	if (trace_ent.takedamage)
	{
		trace_ent.axhitme = 1;
		SpawnBlood (org, '0 0 0', cv_scarlet_dmg_axe); // was 20, SCARLET - custom dmg integration.
		T_Damage (trace_ent, self, self, cv_scarlet_dmg_axe); // was 20, SCARLET - custom dmg integration.
		ThrowBloodSplat(org, trace_endpos, trace_ent, cv_scarlet_dmg_axe, 5); // SCARLET - gore integration.
	}
	else
	{	// hit wall
		sound (self, CHAN_WEAPON, "player/axhit2.wav", 1, ATTN_NORM);
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_GUNSHOT);
		WriteCoord (MSG_BROADCAST, org_x);
		WriteCoord (MSG_BROADCAST, org_y);
		WriteCoord (MSG_BROADCAST, org_z);
	}
};


//============================================================================


vector() wall_velocity =
{
	local vector	vel;
	
	vel = normalize (self.velocity);
	vel = normalize(vel + v_up*(random()- 0.5) + v_right*(random()- 0.5));
	vel = vel + 2*trace_plane_normal;
	vel = vel * 200;
	
	return vel;
};


/*
================
SpawnMeatSpray
================
*/
void(vector org, vector vel) SpawnMeatSpray =
{
	local	entity missile, mpuff;
	local	vector	org;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_NOT;

	makevectors (self.angles);

	missile.velocity = vel;
	missile.velocity_z = missile.velocity_z + 250 + 50*random();

	missile.avelocity = '3000 1000 2000';
	
// set missile duration
	missile.nextthink = time + 1;
	missile.think = SUB_Remove;

	setmodel (missile, "progs/zom_gib.mdl");
	setsize (missile, '0 0 0', '0 0 0');		
	setorigin (missile, org);
};

/*
================
SpawnBlood
================
*/
void(vector org, vector vel, float damage) SpawnBlood =
{
	particle (org, vel*0.1, 73, damage*2);

	// SCARLET - gore integration.
	if (cv_scarlet_gore > 1)
	{
		local float i;
		for (i=1; i<cv_scarlet_gore; i++)
		{
			vel = normalize(vel) * -1;
			vel = normalize(vel + v_up*(random()- 0.5) + v_right*(random()- 0.5));
			particle (org, vel*i*random(), 64+(random()*12), damage*random());
		}
	}
	// SCARLET - end.
};

/*
================
spawn_touchblood
================
*/
void(float damage) spawn_touchblood =
{
	local vector	vel;

	vel = wall_velocity () * 0.2;
	SpawnBlood (self.origin + vel*0.01, vel, damage);
};


/*
================
SpawnChunk
================
*/
void(vector org, vector vel) SpawnChunk =
{
	particle (org, vel*0.02, 0, 10);
};

/*
==============================================================================

MULTI-DAMAGE

Collects multiple small damages into a single damage

==============================================================================
*/

entity	multi_ent;
float	multi_damage;

void() ClearMultiDamage =
{
	multi_ent = world;
	multi_damage = 0;
};

void() ApplyMultiDamage =
{
	if (!multi_ent)
		return;
	T_Damage (multi_ent, self, self, multi_damage);
};

void(entity hit, float damage) AddMultiDamage =
{
	if (!hit)
		return;
	
	if (hit != multi_ent)
	{
		ApplyMultiDamage ();
		multi_damage = damage;
		multi_ent = hit;
	}
	else
		multi_damage = multi_damage + damage;
};

/*
==============================================================================

BULLETS

==============================================================================
*/

/*
================
TraceAttack
================
*/
void(float damage, vector dir, float is_nail_converted_to_hitscan = 0) TraceAttack =
{
	local	vector	vel, org;
	
	vel = normalize(dir + v_up*crandom() + v_right*crandom());
	vel = vel + 2*trace_plane_normal;
	vel = vel * 200;

	org = trace_endpos - dir*4;

	if (trace_ent.takedamage)
	{
		SpawnBlood (org, vel*0.2, damage);
		AddMultiDamage (trace_ent, damage);

		ThrowBloodSplat(dir, trace_endpos, trace_ent, damage, is_nail_converted_to_hitscan ? 2 : 1); // SCARLET - gore integration.
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_GUNSHOT);
		WriteCoord (MSG_BROADCAST, org_x);
		WriteCoord (MSG_BROADCAST, org_y);
		WriteCoord (MSG_BROADCAST, org_z);
	}
};

/*
================
FireBullets

Used by shotgun, super shotgun, and enemy soldier firing
Go to the trouble of combining multiple pellets into a single damage call.
================
*/
void(float shotcount, vector dir, vector spread, float dmg = 4, float is_nail_converted_to_hitscan = 0) FireBullets =
{
	local	vector direction;
	local	vector	src;
	
	makevectors(self.v_angle);

	src = self.origin + v_forward*10;
	src_z = self.absmin_z + self.size_z * 0.7;

	ClearMultiDamage ();
	while (shotcount > 0)
	{
		direction = dir + crandom()*spread_x*v_right + crandom()*spread_y*v_up;

		traceline (src, src + direction*2048, FALSE, self);
		if (trace_fraction != 1.0)
			TraceAttack (dmg, direction, is_nail_converted_to_hitscan); // was 4, SCARLET - custom dmg integration.

		shotcount = shotcount - 1;
	}
	ApplyMultiDamage ();
};

/*
================
W_FireShotgun
================
*/
void() W_FireShotgun =
{
	local vector dir;

	sound (self, CHAN_WEAPON, "weapons/guncock.wav", 1, ATTN_NORM);	

	self.punchangle_x = -1 * cv_scarlet_kick_sg;
	
	self.currentammo = self.ammo_shells = self.ammo_shells - cv_scarlet_dec_shells; // was 1, SCARLET - custom ammo integration.
	dir = aim (self, 100000);
	FireBullets (cv_scarlet_bullets_in_shell_sg, dir, Vector(cv_scarlet_spr_sg/100, cv_scarlet_spr_sg/100/2, 0), cv_scarlet_dmg_bullets); // was 6, SCARLET - custom ammo integration.
};


/*
================
W_FireSuperShotgun
================
*/
void() W_FireSuperShotgun =
{
	local vector dir;

	if (self.currentammo == 1)
	{
		W_FireShotgun ();
		return;
	}
		
	sound (self ,CHAN_WEAPON, "weapons/shotgn2.wav", 1, ATTN_NORM);	

	self.punchangle_x = -1 * cv_scarlet_kick_ssg;
	
	self.currentammo = self.ammo_shells = self.ammo_shells - (cv_scarlet_dec_shells * 2); // was 2, SCARLET - custom ammo integration.
	dir = aim (self, 100000);
	FireBullets (cv_scarlet_bullets_in_shell_ssg, dir, Vector(cv_scarlet_spr_ssg/100, cv_scarlet_spr_ssg/100/2, 0), cv_scarlet_dmg_bullets); // was 14, SCARLET - custom ammo integration.
};


/*
==============================================================================

ROCKETS

==============================================================================
*/

void()	s_explode1	=	[0,		s_explode2] {};
void()	s_explode2	=	[1,		s_explode3] {};
void()	s_explode3	=	[2,		s_explode4] {};
void()	s_explode4	=	[3,		s_explode5] {};
void()	s_explode5	=	[4,		s_explode6] {};
void()	s_explode6	=	[5,		SUB_Remove] {};

void() BecomeExplosion =
{
	self.movetype = MOVETYPE_NONE;
	self.velocity = '0 0 0';
	self.touch = SUB_Null;
	setmodel (self, "progs/s_explod.spr");
	self.solid = SOLID_NOT;
	s_explode1 ();
};

void() T_MissileTouch =
{
	local float	damg;

	if (other == self.owner)
		return;		// don't explode on owner

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}

	// damg = 100 + random()*20; // OG Quake: 100-120 on a direct hit
	// damg = cv_scarlet_dmg_rockets - ((cv_scarlet_dmg_rockets/5) + random()*(cv_scarlet_dmg_rockets/5)); // SCARLET - a possible way to do it: 72-96 at 120
	damg = cv_scarlet_dmg_rockets; // SCARLET - custom dmg integration: the exact value, no randomness
	
	if (other.health)
	{
		if (other.classname == "monster_shambler")
			damg = damg * 0.5;	// mostly immune
		T_Damage (other, self, self.owner, damg );
	}

	// don't do radius damage to the other, because all the damage
	// was done in the impact
	T_RadiusDamage (self, self.owner, cv_scarlet_dmg_rockets, other); // was 120, SCARLET - custom dmg integration.

	ThrowBloodSplatByExplosion(self, cv_scarlet_dmg_rockets); // SCARLET - gore integration.

//	sound (self, CHAN_WEAPON, "weapons/r_exp3.wav", 1, ATTN_NORM);
	self.origin = self.origin - 8*normalize(self.velocity);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	BecomeExplosion ();
};



/*
================
W_FireRocket
================
*/
void() W_FireRocket =
{
	local	entity missile, mpuff;
	
	self.currentammo = self.ammo_rockets = self.ammo_rockets - cv_scarlet_dec_rockets; // was 1, SCARLET - custom ammo integration.
	
	sound (self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);

	self.punchangle_x = -1 * cv_scarlet_kick_rl;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_FLYMISSILE;
	missile.solid = SOLID_BBOX;
		
// set missile speed	

	makevectors (self.v_angle);
	missile.velocity = aim(self, 1000);
	missile.velocity = missile.velocity * 1000;
	missile.angles = vectoangles(missile.velocity);
	
	missile.touch = T_MissileTouch;
	
// set missile duration
	missile.nextthink = time + 5;
	missile.think = SUB_Remove;

	setmodel (missile, "progs/missile.mdl");
	setsize (missile, '0 0 0', '0 0 0');		
	setorigin (missile, self.origin + v_forward*8 + '0 0 16');
};

/*
===============================================================================

LIGHTNING

===============================================================================
*/

/*
=================
LightningDamage
=================
*/
void(vector p1, vector p2, entity from, float damage) LightningDamage =
{
	local entity		e1, e2;
	local vector		f;
	
	f = p2 - p1;
	normalize (f);
	f_x = 0 - f_y;
	f_y = f_x;
	f_z = 0;
	f = f*16;

	e1 = e2 = world;

	traceline (p1, p2, FALSE, self);
	if (trace_ent.takedamage)
	{
		//particle (trace_endpos, '0 0 100', 225, damage*4);
		T_Damage (trace_ent, from, from, damage);
		ThrowBloodSplatByLightning(p1, trace_endpos, trace_ent, damage); // SCARLET - gore integration.
		if (self.classname == "player")
		{
			if (other.classname == "player")
				trace_ent.velocity_z = trace_ent.velocity_z + 400;
		}
	}
	e1 = trace_ent;

	traceline (p1 + f, p2 + f, FALSE, self);
	if (trace_ent != e1 && trace_ent.takedamage)
	{
		//particle (trace_endpos, '0 0 100', 225, damage*4);
		T_Damage (trace_ent, from, from, damage);
		ThrowBloodSplatByLightning(p1, trace_endpos, trace_ent, damage); // SCARLET - gore integration.
	}
	e2 = trace_ent;

	traceline (p1 - f, p2 - f, FALSE, self);
	if (trace_ent != e1 && trace_ent != e2 && trace_ent.takedamage)
	{
		//particle (trace_endpos, '0 0 100', 225, damage*4);
		T_Damage (trace_ent, from, from, damage);
		ThrowBloodSplatByLightning(p1, trace_endpos, trace_ent, damage); // SCARLET - gore integration.
	}
};


void() W_FireLightning =
{
	local	vector		org;

	if (self.ammo_cells < 1)
	{
		self.weapon = W_BestWeapon ();
		W_SetCurrentAmmo ();
		return;
	}

// explode if under water
	if (self.waterlevel > 1)
	{
		T_RadiusDamage (self, self, 35*self.ammo_cells, world);
		self.ammo_cells = 0;
		W_SetCurrentAmmo ();
		return;
	}

	if (self.t_width < time)
	{
		sound (self, CHAN_WEAPON, "weapons/lhit.wav", 1, ATTN_NORM);
		self.t_width = time + 0.6;
	}
	self.punchangle_x = -1 * cv_scarlet_kick_tb;

	self.currentammo = self.ammo_cells = self.ammo_cells - cv_scarlet_dec_cells; // was 1, SCARLET - custom ammo integration.

	org = self.origin + '0 0 16';
	
	traceline (org, org + v_forward*600, TRUE, self);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_LIGHTNING2);
	WriteEntity (MSG_BROADCAST, self);
	WriteCoord (MSG_BROADCAST, org_x);
	WriteCoord (MSG_BROADCAST, org_y);
	WriteCoord (MSG_BROADCAST, org_z);
	WriteCoord (MSG_BROADCAST, trace_endpos_x);
	WriteCoord (MSG_BROADCAST, trace_endpos_y);
	WriteCoord (MSG_BROADCAST, trace_endpos_z);

	LightningDamage (self.origin, trace_endpos + v_forward*4, self, cv_scarlet_dmg_cells); // was 30, SCARLET - custom dmg integration.

	if (cv_scarlet_rof_tb) // SCARLET - the thunderbolt can have a rate of fire of its own
		self.attack_finished = time + cv_scarlet_rof_tb;
};


//=============================================================================


void() GrenadeExplode =
{
	T_RadiusDamage (self, self.owner, cv_scarlet_dmg_rockets, world); // was 120, SCARLET - custom dmg integration.

	ThrowBloodSplatByExplosion(self, cv_scarlet_dmg_rockets); // SCARLET - gore integration.

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

	BecomeExplosion ();
};

void() GrenadeTouch =
{
	if (other == self.owner)
		return;		// don't explode on owner
	if (other.takedamage == DAMAGE_AIM)
	{
		GrenadeExplode();
		return;
	}
	sound (self, CHAN_WEAPON, "weapons/bounce.wav", 1, ATTN_NORM);	// bounce sound
	if (self.velocity == '0 0 0')
		self.avelocity = '0 0 0';
};

/*
================
W_FireGrenade
================
*/
void() W_FireGrenade =
{
	local	entity missile, mpuff;
	
	self.currentammo = self.ammo_rockets = self.ammo_rockets - cv_scarlet_dec_rockets; // was 1, SCARLET - custom ammo integration.
	
	sound (self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);

	self.punchangle_x = -1 * cv_scarlet_kick_gl;

	missile = spawn ();
	missile.owner = self;
	missile.movetype = MOVETYPE_BOUNCE;
	missile.solid = SOLID_BBOX;
	missile.classname = "grenade";
		
// set missile speed	

	makevectors (self.v_angle);

	if (self.v_angle_x)
		missile.velocity = v_forward*600 + v_up * 200 + crandom()*v_right*10 + crandom()*v_up*10;
	else
	{
		missile.velocity = aim(self, 10000);
		missile.velocity = missile.velocity * 600;
		missile.velocity_z = 200;
	}

	missile.avelocity = '300 300 300';

	missile.angles = vectoangles(missile.velocity);
	
	missile.touch = GrenadeTouch;
	
// set missile duration
	missile.nextthink = time + 2.5;
	missile.think = GrenadeExplode;

	setmodel (missile, "progs/grenade.mdl");
	setsize (missile, '0 0 0', '0 0 0');		
	setorigin (missile, self.origin);
};


//=============================================================================

void() spike_touch;
void() superspike_touch;


/*
===============
launch_spike

Used for both the player and the ogre
===============
*/
void(vector org, vector dir) launch_spike =
{
	newmis = spawn ();
	newmis.owner = self;
	newmis.movetype = MOVETYPE_FLYMISSILE;
	newmis.solid = SOLID_BBOX;

	newmis.angles = vectoangles(dir);
	
	newmis.touch = spike_touch;
	newmis.classname = "spike";
	newmis.think = SUB_Remove;
	newmis.nextthink = time + 6;
	setmodel (newmis, "progs/spike.mdl");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);		
	setorigin (newmis, org);

	newmis.velocity = dir * 1000;
};

// SCARLET - nailguns.  the nailgun fires one nail at a time (or two quick hitscan bullets), the
// super nailgun two nails at once, both with their own speed, spread and rate of fire.  a speed of
// 2000 or more is too fast for a missile to carry, so the nail becomes a bullet instead.

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

// a nail with a speed of its own, that does cv_scarlet_dmg_nails
entity(vector org, vector vel) launch_nail =
{
	launch_spike (org, normalize(vel));
	newmis.velocity = vel;
	newmis.scarlet_nail = TRUE;
	newmis.dmg = cv_scarlet_dmg_nails; // was 9, SCARLET - custom dmg integration.
	return newmis;
}

void() spike_unfatten = { self.movetype = MOVETYPE_FLY; }

void() W_FireNailgun =
{
	local vector offset, v, org, dir;

	dir = aim (self, 1000);
	v = vectoangles (dir);
	v_x = v_x * -1;	// pitch comes back inverted from vectoangles
	makevectors (v);

	sound (self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
	self.currentammo = self.ammo_nails = self.ammo_nails - cv_scarlet_dec_nails; // was 1, SCARLET - custom ammo integration.
	offset = VEC_ORIGIN;
	if (mod (self.cnt, 2))
		offset_x = -2.5;
	else
		offset_x = 2.5;

	org = W_SpikeOrigin (offset);
	dir = W_SpikeDir (v_forward, cv_scarlet_spr_ng);

	// default sv_maxvelocity is 2000, any higher leads to weird
	// angular offsets caused by clamping the velocity
	if (cv_scarlet_spd_ng >= 1999)
	{
		ClearMultiDamage ();
		FireBullets (2, aim (self, 1000), Vector(cv_scarlet_spr_ng/100, cv_scarlet_spr_ng/100/2, 0), cv_scarlet_dmg_nails/2, 1); // flag true so it knows this was a nail not a bullet -whipowill
		ApplyMultiDamage ();
	}
	else
	{
		launch_nail (org, dir * cv_scarlet_spd_ng);
	}
	self.attack_finished = time + cv_scarlet_rof_ng;
}

void() W_FirePerforator =
{
	local vector offset;

	sound (self, CHAN_WEAPON, "weapons/spike2.wav", 1, ATTN_NORM);
	self.currentammo = self.ammo_nails = self.ammo_nails - (cv_scarlet_dec_nails * 2); // was 2, SCARLET - custom ammo integration.

	if (mod (self.cnt, 4) == 0) offset = '0 0 1.25';
	else if (mod (self.cnt, 4) == 1) offset = '1 0 1';
	else if (mod (self.cnt, 4) == 2) offset = '1.25 0 0';
	else offset = '1 0 -1';

	if (cv_scarlet_spd_sng >= 1999)
	{
		ClearMultiDamage ();
		FireBullets (4, aim (self, 1000), Vector(cv_scarlet_spr_sng/100, cv_scarlet_spr_sng/100/2, 0), cv_scarlet_dmg_nails/2, 1); // flag true so it knows this was a nail not a bullet -whipowill
		ApplyMultiDamage ();
	}
	else
	{
		local entity spike1, spike2;

		spike1 = launch_nail (W_SpikeOrigin(offset), W_SpikeDir(v_forward, cv_scarlet_spr_sng) * cv_scarlet_spd_sng);
		spike2 = launch_nail (W_SpikeOrigin('0 0 0' - offset), W_SpikeDir(v_forward, cv_scarlet_spr_sng) * cv_scarlet_spd_sng);

		// weaken the SNG at long distance while keeping the spread under control
		spike1.think = spike_unfatten;
		spike2.think = spike_unfatten;
		spike1.nextthink = time + 0.25;
		spike2.nextthink = time + 0.3;

		if (self.super_damage_finished > time)
		{
			// two nails do 9 each, 36 each with quad, and the second wouldn't always hit.  the
			// nails share their damage instead, so the quad super nailgun still gibs
			spike2.dmg = cv_scarlet_dmg_nails*2; // SCARLET - custom dmg integration.
			spike1.dmg = cv_scarlet_dmg_nails*2; // SCARLET - custom dmg integration.
			spike2.buddy = spike1;
			spike1.buddy = spike2;
			// first one to hit does its damage and then nerfs its 'buddy'
		}
	}

	self.attack_finished = time + cv_scarlet_rof_sng;
}

void(float ox) W_FireSpikes =
{
	if (self.ammo_nails < 1 || (self.ammo_nails < 2 && self.weapon == IT_SUPER_NAILGUN))
	{
		self.weapon = W_BestWeapon ();
		W_SetCurrentAmmo ();
		return;
	}

	makevectors (self.v_angle);

	if (self.ammo_nails >= 2 && self.weapon == IT_SUPER_NAILGUN)
	{
		W_FirePerforator ();
		self.punchangle_x = -1 * cv_scarlet_kick_sng;
	}
	else
	{
		W_FireNailgun ();
		self.punchangle_x = -1 * cv_scarlet_kick_ng;
	}
	self.cnt = cycle (self.cnt, 8);
}



.float hit_z;
void() spike_touch =
{
local float rand, d;
	if (other == self.owner)
		return;

	if (other.solid == SOLID_TRIGGER)
		return;	// trigger field, do nothing

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}
	
// hit something that bleeds
	d = 9;
	if (self.scarlet_nail)
		d = self.dmg;	// SCARLET - a nail from the nailguns knows its own damage (0 once its buddy has hit)
	if (!d)
	{
		// nothing to do: the quad super nailgun's other nail did all the damage
	}
	else if (other.takedamage)
	{
		spawn_touchblood (d);
		T_Damage (other, self, self.owner, d);

		// SCARLET - gore integration.
		self.angles_x = self.angles_x*-1;
		makevectors(self.angles);
		ThrowBloodSplat(v_forward, self.origin, other, d, 2);
		// SCARLET - end.
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		
		if (self.classname == "wizspike")
			WriteByte (MSG_BROADCAST, TE_WIZSPIKE);
		else if (self.classname == "knightspike")
			WriteByte (MSG_BROADCAST, TE_KNIGHTSPIKE);
		else
			WriteByte (MSG_BROADCAST, TE_SPIKE);
		WriteCoord (MSG_BROADCAST, self.origin_x);
		WriteCoord (MSG_BROADCAST, self.origin_y);
		WriteCoord (MSG_BROADCAST, self.origin_z);
	}

	// nonsense for combining quad SNG spike damage
	if (self.buddy)
		self.buddy.dmg = 0;

	remove(self);

};

void() superspike_touch =
{
local float rand;
	if (other == self.owner)
		return;

	if (other.solid == SOLID_TRIGGER)
		return;	// trigger field, do nothing

	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}
	
// hit something that bleeds
	if (other.takedamage)
	{
		spawn_touchblood (18);
		T_Damage (other, self, self.owner, 18);
	}
	else
	{
		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_SUPERSPIKE);
		WriteCoord (MSG_BROADCAST, self.origin_x);
		WriteCoord (MSG_BROADCAST, self.origin_y);
		WriteCoord (MSG_BROADCAST, self.origin_z);
	}

	remove(self);

};


/*
===============================================================================

PLAYER WEAPON USE

===============================================================================
*/

void() W_SetCurrentAmmo =
{
	player_run ();		// get out of any weapon firing states

	self.items = self.items - ( self.items & (IT_SHELLS | IT_NAILS | IT_ROCKETS | IT_CELLS) );
	
	if (self.weapon == IT_AXE)
	{
		self.currentammo = 0;
		self.weaponmodel = "progs/v_axe.mdl";
		self.weaponframe = 0;
	}
	else if (self.weapon == IT_SHOTGUN)
	{
		self.currentammo = self.ammo_shells;
		self.weaponmodel = "progs/v_shot.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_SHELLS;
	}
	else if (self.weapon == IT_SUPER_SHOTGUN)
	{
		self.currentammo = self.ammo_shells;
		self.weaponmodel = "progs/v_shot2.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_SHELLS;
	}
	else if (self.weapon == IT_NAILGUN)
	{
		self.currentammo = self.ammo_nails;
		self.weaponmodel = "progs/v_nail.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_NAILS;
	}
	else if (self.weapon == IT_SUPER_NAILGUN)
	{
		self.currentammo = self.ammo_nails;
		self.weaponmodel = "progs/v_nail2.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_NAILS;
	}
	else if (self.weapon == IT_GRENADE_LAUNCHER)
	{
		self.currentammo = self.ammo_rockets;
		self.weaponmodel = "progs/v_rock.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_ROCKETS;
	}
	else if (self.weapon == IT_ROCKET_LAUNCHER)
	{
		self.currentammo = self.ammo_rockets;
		self.weaponmodel = "progs/v_rock2.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_ROCKETS;
	}
	else if (self.weapon == IT_LIGHTNING)
	{
		self.currentammo = self.ammo_cells;
		self.weaponmodel = "progs/v_light.mdl";
		self.weaponframe = 0;
		self.items = self.items | IT_CELLS;
	}
	else
	{
		self.currentammo = 0;
		self.weaponmodel = "";
		self.weaponframe = 0;
	}
};

float() W_BestWeapon =
{
	local	float	it;
	
	it = self.items;

	if(self.ammo_cells >= 1 && (it & IT_LIGHTNING) )
		return IT_LIGHTNING;
	else if(self.ammo_nails >= 2 && (it & IT_SUPER_NAILGUN) )
		return IT_SUPER_NAILGUN;
	else if(self.ammo_shells >= 2 && (it & IT_SUPER_SHOTGUN) )
		return IT_SUPER_SHOTGUN;
	else if(self.ammo_nails >= 1 && (it & IT_NAILGUN) )
		return IT_NAILGUN;
	else if(self.ammo_shells >= 1 && (it & IT_SHOTGUN) )
		return IT_SHOTGUN;
		
/*
	if(self.ammo_rockets >= 1 && (it & IT_ROCKET_LAUNCHER) )
		return IT_ROCKET_LAUNCHER;
	else if(self.ammo_rockets >= 1 && (it & IT_GRENADE_LAUNCHER) )
		return IT_GRENADE_LAUNCHER;

*/

	return IT_AXE;
};

float() W_CheckNoAmmo =
{
	if (self.currentammo > 0)
		return TRUE;

	if (self.weapon == IT_AXE)
		return TRUE;
	
	self.weapon = W_BestWeapon ();

	W_SetCurrentAmmo ();
	
// drop the weapon down
	return FALSE;
};

/*
============
W_Attack

An attack impulse can be triggered now
============
*/
void()	player_axe1;
void()	player_axeb1;
void()	player_axec1;
void()	player_axed1;
void()	player_shot1;
void()	player_nail1;
void()	player_light1;
void()	player_rocket1;

// SCARLET - a swing of the axe, also used by the melee impulse
void() W_AxeSwing =
{
	local float r;

	sound (self, CHAN_WEAPON, "weapons/ax1.wav", 1, ATTN_NORM);
	r = random();
	if (r < 0.25)
		player_axe1 ();
	else if (r<0.5)
		player_axeb1 ();
	else if (r<0.75)
		player_axec1 ();
	else
		player_axed1 ();
}

// SCARLET - back to a clean weapon: no animation, the model for the weapon in hand
void() W_ResetWeaponState =
{
	player_run ();

	self.weaponframe = 0;

	if (self.weapon == IT_AXE)
		self.weaponmodel = "progs/v_axe.mdl";
	else if (self.weapon == IT_SHOTGUN)
		self.weaponmodel = "progs/v_shot.mdl";
	else if (self.weapon == IT_SUPER_SHOTGUN)
		self.weaponmodel = "progs/v_shot2.mdl";
	else if (self.weapon == IT_NAILGUN)
		self.weaponmodel = "progs/v_nail.mdl";
	else if (self.weapon == IT_SUPER_NAILGUN)
		self.weaponmodel = "progs/v_nail2.mdl";
	else if (self.weapon == IT_GRENADE_LAUNCHER)
		self.weaponmodel = "progs/v_rock.mdl";
	else if (self.weapon == IT_ROCKET_LAUNCHER)
		self.weaponmodel = "progs/v_rock2.mdl";
	else if (self.weapon == IT_LIGHTNING)
		self.weaponmodel = "progs/v_light.mdl";
	else
		self.weaponmodel = string_null;
	W_SetCurrentAmmo ();
}

void() W_Attack =
{
	local	float	r;

	if (!W_CheckNoAmmo ())
		return;

	makevectors	(self.v_angle);			// calculate forward angle for velocity
	self.show_hostile = time + 1;	// wake monsters up

	if (self.weapon == IT_AXE)
	{
		W_AxeSwing ();
		self.attack_finished = time + cv_scarlet_rof_axe; // was 0.5, SCARLET - custom rof integration.
	}
	else if (self.weapon == IT_SHOTGUN)
	{
		player_shot1 ();
		W_FireShotgun ();
		self.attack_finished = time + cv_scarlet_rof_sg; // was 0.5, SCARLET - custom rof integration.
	}
	else if (self.weapon == IT_SUPER_SHOTGUN)
	{
		player_shot1 ();
		W_FireSuperShotgun ();
		self.attack_finished = time + cv_scarlet_rof_ssg; // was 0.7, SCARLET - custom rof integration.
	}
	else if (self.weapon == IT_NAILGUN || self.weapon == IT_SUPER_NAILGUN)
	{
		// SCARLET - the nailguns set their own rof when they fire
		player_nail1 ();
		W_FireSpikes (0);
	}
	else if (self.weapon == IT_GRENADE_LAUNCHER)
	{
		player_rocket1();
		W_FireGrenade();
		self.attack_finished = time + cv_scarlet_rof_gl; // was 0.6, SCARLET - custom rof integration.
	}
	else if (self.weapon == IT_ROCKET_LAUNCHER)
	{
		player_rocket1();
		W_FireRocket();
		self.attack_finished = time + cv_scarlet_rof_rl; // was 0.8, SCARLET - custom rof integration.
	}
	else if (self.weapon == IT_LIGHTNING)
	{
		player_light1();
		self.attack_finished = time + 0.1;
		sound (self, CHAN_AUTO, "weapons/lstart.wav", 1, ATTN_NORM);
	}

	if (!W_CheckNoAmmo ())	// SCARLET - switch away at once when the shot used the last ammo
		return;
};

/*
============
W_ChangeWeapon

============
*/
void() W_ChangeWeapon =
{
	local	float	it, am, fl;
	
	it = self.items;
	am = 0;
	
	if (self.impulse == 1)
	{
		fl = IT_AXE;
	}
	else if (self.impulse == 2)
	{
		fl = IT_SHOTGUN;
		if (self.ammo_shells < 1)
			am = 1;
	}
	else if (self.impulse == 3)
	{
		fl = IT_SUPER_SHOTGUN;
		if (self.ammo_shells < 2)
			am = 1;
	}		
	else if (self.impulse == 4)
	{
		fl = IT_NAILGUN;
		if (self.ammo_nails < 1)
			am = 1;
	}
	else if (self.impulse == 5)
	{
		fl = IT_SUPER_NAILGUN;
		if (self.ammo_nails < 2)
			am = 1;
	}
	else if (self.impulse == 6)
	{
		fl = IT_GRENADE_LAUNCHER;
		if (self.ammo_rockets < 1)
			am = 1;
	}
	else if (self.impulse == 7)
	{
		fl = IT_ROCKET_LAUNCHER;
		if (self.ammo_rockets < 1)
			am = 1;
	}
	else if (self.impulse == 8)
	{
		fl = IT_LIGHTNING;
		if (self.ammo_cells < 1)
			am = 1;
	}

	self.impulse = 0;
	
	if (!(self.items & fl))
	{	// don't have the weapon or the ammo
		sprint (self, "no weapon.\n");
		return;
	}
	
	if (am)
	{	// don't have the ammo
		sprint (self, "not enough ammo.\n");
		return;
	}

//
// set weapon, set ammo
//
	self.weapon = fl;		
	W_SetCurrentAmmo ();
};

/*
============
CheatCommand
============
*/
void() CheatCommand =
{
	if (deathmatch || coop)
		return;

	self.ammo_rockets = 100;
	self.ammo_nails = 200;
	self.ammo_shells = 100;
	self.items = self.items | 
		IT_AXE |
		IT_SHOTGUN |
		IT_SUPER_SHOTGUN |
		IT_NAILGUN |
		IT_SUPER_NAILGUN |
		IT_GRENADE_LAUNCHER |
		IT_ROCKET_LAUNCHER |
		IT_KEY1 | IT_KEY2;

	self.ammo_cells = 200;
	self.items = self.items | IT_LIGHTNING;

	self.weapon = IT_ROCKET_LAUNCHER;
	self.impulse = 0;
	W_SetCurrentAmmo ();
};

/*
============
CycleWeaponCommand

Go to the next weapon with ammo
============
*/
void() CycleWeaponCommand =
{
	local	float	it, am;
	
	it = self.items;
	self.impulse = 0;
	
	while (1)
	{
		am = 0;

		if (self.weapon == IT_LIGHTNING)
		{
			self.weapon = IT_AXE;
		}
		else if (self.weapon == IT_AXE)
		{
			self.weapon = IT_SHOTGUN;
			if (self.ammo_shells < 1)
				am = 1;
		}
		else if (self.weapon == IT_SHOTGUN)
		{
			self.weapon = IT_SUPER_SHOTGUN;
			if (self.ammo_shells < 2)
				am = 1;
		}		
		else if (self.weapon == IT_SUPER_SHOTGUN)
		{
			self.weapon = IT_NAILGUN;
			if (self.ammo_nails < 1)
				am = 1;
		}
		else if (self.weapon == IT_NAILGUN)
		{
			self.weapon = IT_SUPER_NAILGUN;
			if (self.ammo_nails < 2)
				am = 1;
		}
		else if (self.weapon == IT_SUPER_NAILGUN)
		{
			self.weapon = IT_GRENADE_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
		else if (self.weapon == IT_GRENADE_LAUNCHER)
		{
			self.weapon = IT_ROCKET_LAUNCHER;
			if (self.ammo_rockets < 1)
				am = 1;
		}
		else if (self.weapon == IT_ROCKET_LAUNCHER)
		{
			self.weapon = IT_LIGHTNING;
			if (self.ammo_cells < 1)
				am = 1;
		}
	
		if ( (self.items & self.weapon) && am == 0)
		{
			W_SetCurrentAmmo ();
			return;
		}
	}

};

/*
============
ServerflagsCommand

Just for development
============
*/
void() ServerflagsCommand =
{
	serverflags = serverflags * 2 + 1;
};

void() QuadCheat =
{
	if (deathmatch || coop)
		return;
	self.super_time = 1;
	self.super_damage_finished = time + 30;
	self.items = self.items | IT_QUAD;
	dprint ("quad cheat\n");
};

/*
============
ImpulseCommands

============
*/
void() ImpulseCommands =
{
	if (self.impulse >= 1 && self.impulse <= 8)
		W_ChangeWeapon ();

	// SCARLET - best-of weapon keys: the stronger of the pair if it is owned and has ammo, else the other
	if (self.impulse == 160) // rocket launcher, else grenade launcher
	{
		if ((self.items & IT_ROCKET_LAUNCHER) && self.ammo_rockets >= 1)
			self.impulse = 7;
		else if ((self.items & IT_GRENADE_LAUNCHER) && self.ammo_rockets >= 1)
			self.impulse = 6;
		else
			self.impulse = 7;
		W_ChangeWeapon ();
	}
	if (self.impulse == 161) // super nailgun, else nailgun
	{
		if ((self.items & IT_SUPER_NAILGUN) && self.ammo_nails >= 2)
			self.impulse = 5;
		else if ((self.items & IT_NAILGUN) && self.ammo_nails >= 1)
			self.impulse = 4;
		else
			self.impulse = 5;
		W_ChangeWeapon ();
	}
	if (self.impulse == 162) // super shotgun, else shotgun
	{
		if ((self.items & IT_SUPER_SHOTGUN) && self.ammo_shells >= 2)
			self.impulse = 3;
		else if ((self.items & IT_SHOTGUN) && self.ammo_shells >= 1)
			self.impulse = 2;
		else
			self.impulse = 3;
		W_ChangeWeapon ();
	}

	if (self.impulse == 9)
		CheatCommand ();
	if (self.impulse == 10)
		CycleWeaponCommand ();
	if (self.impulse == 11)
		ServerflagsCommand ();

	if (self.impulse == 255)
		QuadCheat ();
		
	self.impulse = 0;
};

/*
============
W_WeaponFrame

Called every frame so impulse events can be handled as well as possible
============
*/
void() W_WeaponFrame =
{
	if (time < self.attack_finished)
		return;

	ImpulseCommands ();
	
// check for attack
	if (self.button0)
	{
		SuperDamageSound ();
		W_Attack ();
	}
};

/*
========
SuperDamageSound

Plays sound if needed
========
*/
void() SuperDamageSound =
{
	if (self.super_damage_finished > time)
	{
		if (self.super_sound < time)
		{
			self.super_sound = time + 1;
			sound (self, CHAN_BODY, "items/damage3.wav", 1, ATTN_NORM);
		}
	}
	return;
};


