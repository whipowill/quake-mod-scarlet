/***********************************************
*                                              *
*             FrikBot Fight Code               *
*      "Because I ain't no Ghandi code"        *
*                                              *
***********************************************/

/*

This program is in the Public Domain. My crack legal
team would like to add:

RYAN "FRIKAC" SMITH IS PROVIDING THIS SOFTWARE "AS IS"
AND MAKES NO WARRANTY, EXPRESS OR IMPLIED, AS TO THE
ACCURACY, CAPABILITY, EFFICIENCY, MERCHANTABILITY, OR
FUNCTIONING OF THIS SOFTWARE AND/OR DOCUMENTATION. IN
NO EVENT WILL RYAN "FRIKAC" SMITH BE LIABLE FOR ANY
GENERAL, CONSEQUENTIAL, INDIRECT, INCIDENTAL,
EXEMPLARY, OR SPECIAL DAMAGES, EVEN IF RYAN "FRIKAC"
SMITH HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES, IRRESPECTIVE OF THE CAUSE OF SUCH DAMAGES. 

You accept this software on the condition that you
indemnify and hold harmless Ryan "FrikaC" Smith from
any and all liability or damages to third parties,
including attorney fees, court costs, and other
related costs and expenses, arising out of your use
of this software irrespective of the cause of said
liability. 

The export from the United States or the subsequent
reexport of this software is subject to compliance
with United States export control and munitions
control restrictions. You agree that in the event you
seek to export this software, you assume full
responsibility for obtaining all necessary export
licenses and approvals and for assuring compliance
with applicable reexport restrictions. 

Any reproduction of this software must contain
this notice in its entirety. 

*/

.entity avoid;
.float dodge_next, monster_next;	// SCARLET - when this bot next looks for shots and for monsters
.float last_melee_attempt, last_grenade_attempt;

float(entity e) bot_size_player =
{
	local float sz;

	sz = e.health + e.armorvalue * e.armortype;
	if (e.weapon == 32)
		sz = sz + 60;
	else if (e.weapon == 64)
		sz = sz + 60;
	else if (e.weapon == 16)
		sz = sz + 50;
	else if (e.weapon == 8)
		sz = sz + 50;
	else if (e.weapon == 4)
		sz = sz + 40;
	else if (e.weapon == 2)
		sz = sz + 40;
	else if (e.weapon == 1)
		sz = sz + 10;
	else if (e.weapon == 4096)
		sz = sz - 50;
	if (e.items & 4194304) // Quad
		sz = sz + 200;
	if (e.items & 1048576) // Invul
		sz = sz + 300;
	if (e.items & 524288) // Invis
		sz = sz + 250;
	return sz;
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Skill handicaps

What makes a bot below skill 3 weaker.  Skill 3 is
never held back.  scarlet_bot_handicap scales all of
it: 1 is the full amount, 0 makes every bot like skill 3.

                       skill 0   1     2     3
  reaction to new foe   0.6 s   0.4   0.2   0
  turn speed            60%      75%   90%   100% (skill 3 turns instantly)
  aim wobble            6 deg    4     2     0
  shots led (of 3)      0        1     2     3
  rockets dodged        25%      50%   75%   100%

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

float() bot_reaction_time =
{
	if (self.b_skill >= 3)
		return 0;
	return (0.6 - 0.2 * self.b_skill) * cv_scarlet_bot_handicap;
};

float() bot_dodge_chance =
{
	local float c;
	c = 0.25 + 0.25 * self.b_skill;
	if (c > 1)
		c = 1;
	return 1 - (1 - c) * cv_scarlet_bot_handicap;
};

float() bot_turn_scale =
{
	local float c;
	c = 0.6 + 0.15 * self.b_skill;
	if (c > 1)
		c = 1;
	return 1 - (1 - c) * cv_scarlet_bot_handicap;
};

float() bot_wobble =
{
	if (self.b_skill >= 3)
		return 0;
	return (6 - 2 * self.b_skill) * cv_scarlet_bot_handicap;
};

float() bot_lead_levels =
{
	local float h;
	h = cv_scarlet_bot_handicap;
	if (h > 1)
		h = 1;
	return 3 - floor((3 - self.b_skill) * h);
};

void() bot_dodge_stuff =
{
	local entity foe;
	local float avdist, foesz, flen, tsz;
	local vector v;

	if (waypoint_mode > WM_LOADED)
		return;

	if (self.enemy)
	{
		v = self.origin - realorigin(self.enemy);

		foesz = bot_size_player(self.enemy);
		foesz = foesz + vlen(v) * 0.5;
	}
	else 
		foesz = 9999999;
	avdist = 256;

	// SCARLET - looking for shots walks the whole entity list three times, so a bot does it ten
	// times a second, not every frame.  in between it keeps the shot it saw (or drops it if it is gone)
	if (time < self.dodge_next)
	{
		if (self.avoid && self.avoid.classname == "")
			self.avoid = world;
	}
	else
	{
	self.dodge_next = time + 0.1;
	self.avoid = world;
	foe = find(world, classname, "grenade");
	while(foe)
	{
		flen = vlen(foe.origin - self.origin);
		if (flen < avdist)
		{
			avdist = flen;
			self.avoid = foe;
		}
		foe = find(foe, classname, "grenade");
	}
	if (!self.avoid)
	{
		foe = find(world, classname, "missile");
		while(foe)
		{
			if (foe.owner != self)
			{
				flen = vlen(foe.origin - self.origin);
				if (flen < avdist)
				{
					avdist = flen;
					self.avoid = foe;
				}
			}
			foe = find(foe, classname, "missile");
		}
		if (!self.avoid)
		{
			foe = find(world, classname, "spike");
			while(foe)
			{
				if (foe.owner != self)
				{
					flen = vlen(foe.origin - self.origin);
					if (flen < avdist)
					{
						avdist = flen;
						self.avoid = foe;
					}
				}
				foe = find(foe, classname, "spike");
			}
		}
	}
	// a weaker bot doesn't always see the shot coming: it decides once for each projectile
	if (self.avoid)
	{
		if (self.avoid != self.dodge_seen)
		{
			self.dodge_seen = self.avoid;
			self.dodge_skip = (random() > bot_dodge_chance());
		}
		if (self.dodge_skip)
			self.avoid = world;
	}
	}

	if (coop || !deathmatch)
	{
		// SCARLET - and monsters are looked for four times a second
		if (!self.enemy && time >= self.monster_next)
		{
			self.monster_next = time + 0.25;
			foe = findradius(self.origin, 9999);
			while(foe)
			{
				if(foe.flags & FL_MONSTER)
				{
					if(foe.health > 0)
					{
						tsz = bot_size_player(foe) + vlen(foe.origin - self.origin) * 0.5;
						if (tsz < foesz)
						{
							if (bot_near_human(foe.origin) && fisible(foe))
							{
								self.enemy = foe;
								foesz = tsz;
							}
						}
					}
				}
				foe = foe.chain;
			}
		}		
	}
	else
	{
		foe = player_head;
		while(foe)
		{
			if(foe != self)
			{
				if (foe.modelindex != 0)
				{
					if (foe.health > 0)
					{
						if (foe.items & IT_INVULNERABILITY)
						{
							// nothing hurts them, so don't pick them as a target.  run away instead
							if (!(teamplay && self.team == foe.team) && !(self.items & IT_INVULNERABILITY))
								if (vlen(foe.origin - self.origin) < 700 && fisible(foe))
								{
									self.flee_ent = foe;
									self.flee_until = time + 1.5;
								}
						}
						else if (!(teamplay && self.team == foe.team))
						{
							tsz = bot_size_player(foe) + vlen(foe.origin - self.origin) * 0.5;
							if (tsz < foesz)
							{
								if (fov(foe) || foe.b_sound > time || self.b_skill == 3)
								{
									if (fisible(foe))
									{
										self.enemy = foe;
										foesz = tsz;
									}
								}
							}
						}
					}
				}
			}
			foe = foe._next;
		}
	}
};




/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

weapon_range

_x "sweet spot range" - try to maintain this range if possible
_y minimum range bot can be to be effective (rl/gl) (move away)
_z maximum range bot can be to be effective (lg/axe) (move in)
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

vector(float wep) weapon_range =
{
	if (wep == 4096) // IT_AXE
		return '48 0 64';
	else if (wep == 1) // IT_SHOTGUN
		return '128 8 3000';
	else if (wep == 2) // IT_SUPER_SHOTGUN
		return '128 0 3000';
	else if (wep == 4) // IT_NAILGUN
		return '180 0 3000';
	else if (wep == 8) // IT_SUPER_NAILGUN
		return '180 0 3000';
	else if (wep == 16) // IT_GRENADE_LAUNCHER
		return '180 48 3000';
	else if (wep == 32) // IT_ROCKET_LAUNCHER
		return '180 48 3000';
	else if (wep == 64) // IT_LIGHTNING
		//return '350 0 512';
		return '350 0 3000';
	else
		return '180 0 3000';
};
/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

bot_weapon_switch

Pick a weapon based on range / ammo

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

void(float brange) bot_weapon_switch =
{
	local	float	it, flag, pulse;
	local vector v;

	it = self.items & 127;

	while(it)
	{
		if ((self.ammo_rockets >= 1) && (it & 32))
		{
			flag = 32;
			pulse = 7;
		}
		else if (self.waterlevel <= 1 && self.ammo_cells >= 1 && (it & 64))
		{
			flag = 64;
			pulse = 8;
		}
		else if(self.ammo_nails >= 2 && (it & 8))
		{
			flag = 8;
			pulse = 5;
		}
		else if ((self.ammo_rockets >= 1) && (it & 16))
		{
			flag = 16;
			pulse = 6;
		}
		else if(self.ammo_shells >= 2 && (it & 2))
		{
			flag = 2;
			pulse = 3;
		}
		else if(self.ammo_nails >= 1 && (it & 4))
		{
			flag = 4;
			pulse = 4;
		}
		else if(self.ammo_shells >= 1 && (it & 1))
		{
			flag = 1;
			pulse = 2;
		}
		else
		{
			if (pulse)
				self.impulse = pulse;
			return;
		}

		if (brange == -1)
		{
			if (pulse)
				self.impulse = pulse;
			return;
		}
		v = weapon_range(flag);
		if (brange < v_y || brange > v_z)
			it = it - flag;
		else
		{
			if (pulse)
				self.impulse = pulse;
			return;
		}
	}
};

void() bot_shoot = 
{
	// quick little function to stop making him shoot the wrong way ! Argh
	local float g;
	g = angcomp(self.v_angle_x, self.b_angle_x);
	if (fabs(g) > 30)
	{
		return; // argh, too far away
	}
	g = angcomp(self.v_angle_y, self.b_angle_y);
	if (fabs(g) > 30)
	{
		return; // not again!
	}
	self.button0 = TRUE;
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Bot_fight_style

This is the core of the bot's thinking when
attacking an enemy. 

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

// How much farther than the axe's normal reach a bot will start a swing, because the
// lunge carries it the rest of the way.
float() bot_lunge_reach =
{
	if (cv_scarlet_melee && cv_scarlet_melee_lunge && cv_scarlet_melee_lunge_speed > 0 && self.attack_lunged_melee <= time)
		return cv_scarlet_melee_lunge_range;
	return 0;
};

// can the bot shoot at what's in its sights? players always, and in coop and single
// player monsters too (they are the bots' enemies there)
float(entity e) bot_fight_target =
{
	if (e.classname == "player")
		return TRUE;
	if ((coop || !deathmatch) && (e.flags & FL_MONSTER) && e.health > 0)
		return TRUE;
	return FALSE;
};

void() bot_fight_style =
{
	local vector a, g, v, v1, v2, org;
	local float foedist, mysz, foesz;

	if (self.enemy.health <= 0)
	{
		self.enemy = world;
		return;
	}
	else if (self.enemy.items & IT_INVULNERABILITY)
	{
		// don't waste ammo on someone who can't be hurt
		self.enemy = world;
		return;
	}
	else if (!self.enemy.takedamage)
	{
		self.enemy = world;
		return;
	}
	else if (!fisible(self.enemy))
	{
		self.enemy = world;
		return;
	}

	// a weaker bot takes a moment to react to a new enemy
	if (time < self.react_until)
		return;

	org = realorigin(self.enemy);
	makevectors(self.v_angle);

	// decide if I should shoot

	foedist = vlen(org - self.origin);
	v = weapon_range(self.weapon);

	// if possible, perform axe attack first! -whipowill
	a = weapon_range(IT_AXE);
	if (foedist > a_y && foedist < (a_z + bot_lunge_reach())) // add space for lunge
	{
		traceline(self.origin + self.view_ofs, self.origin + self.view_ofs + v_forward * v_z, FALSE, self);
		if (vlen(trace_endpos - (self.origin + self.view_ofs)) >= v_y)
		{
			if (bot_fight_target(trace_ent))
			{
				if ((trace_ent.classname == "player") && ((trace_ent.team == self.team && teamplay) || (coop || !deathmatch))) return;

				if (self.last_melee_attempt <= time)
				{
					if (random() <= cv_scarlet_grenades_chance) AxeAttack();
					self.last_melee_attempt = time + (cv_scarlet_grenades_cooldown * random());
				}
			}
		}
	}

	// if possible, perform grenade attack first! -whipowill
	g = weapon_range(IT_GRENADE_LAUNCHER); // finding the perfect range to use a grenade
	if (foedist > g_y && foedist < g_z)
	{
		traceline(self.origin + self.view_ofs, self.origin + self.view_ofs + v_forward * v_z, FALSE, self);
		if (vlen(trace_endpos - (self.origin + self.view_ofs)) >= v_y)
		{
			if (bot_fight_target(trace_ent))
			{
				if ((trace_ent.classname == "player") && ((trace_ent.team == self.team && teamplay) || (coop || !deathmatch))) return;

				if (self.last_grenade_attempt <= time)
				{
					if (random() <= cv_scarlet_grenades_chance) GrenadeAttack();
					self.last_grenade_attempt = time + (cv_scarlet_grenades_cooldown * random());
				}
			}
		}
	}

	if (foedist > v_y && foedist < v_z)
	{
		traceline(self.origin + self.view_ofs, self.origin + self.view_ofs + v_forward * v_z, FALSE, self);
		if (vlen(trace_endpos - (self.origin + self.view_ofs)) >= v_y)
		{
			if (bot_fight_target(trace_ent))
			{
				// try to avoid shooting teammates
				if ((trace_ent.classname == "player") && ((trace_ent.team == self.team && teamplay) || (coop || !deathmatch)))
					return;

				bot_shoot();
			}
		}
	}
	else
	{
		bot_weapon_switch(foedist);
	}

	if (!(self.b_aiflags & (AI_PRECISION | AI_BLIND | AI_OBSTRUCTED)))
	{
		foesz = bot_size_player(self.enemy);
		mysz = bot_size_player(self) + 5;

		if (foesz > mysz)
		{
			if (teamplay)
			{
				bot_start_topic(7); // team chatter
			}
			
			return;
		}
		else if (mysz < 140)
			return;
		else if (self.avoid)
		{
			if (self.avoid.velocity)
				v = self.avoid.velocity;
			else
				v = normalize(self.avoid.origin - self.origin);
			v1_x = v_y * -1;
			v1_y = v_x;
			v2_x = v_y;
			v2_y = v_x * -1;
			foedist = vlen(self.avoid.origin - (self.origin + v1));
			if (foedist < vlen(self.avoid.origin - (self.origin + v2)))
				frik_walkmove(v2);
			else
				frik_walkmove(v1);
		}
		else if (!self.enemy.flags && FL_MONSTER)
		{
			if (foedist + 32 <  v_x)
			frik_walkmove(self.origin - org);
			else if (foedist - 32 >  v_x)
				frik_walkmove(org - self.origin);
			else if (self.wallhug)
				frik_walkmove(v_right);
			else
				frik_walkmove(v_right * -1);
		}
	}
	else
	{
		foesz = bot_size_player(self.enemy);
		mysz = bot_size_player(self) + 5;

		if (foesz > mysz)
			return;
		else if (mysz < 140)
			return;
		self.keys = self.keys & 960;
	}
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

bot_flee

A player holding the pentagram can't be hurt, so a
bot that sees one (bot_dodge_stuff picks which) turns
and runs the other way, keeping the goal it had.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

void() bot_flee =
{
	local vector away, ang;

	if (!self.flee_ent)
		return;
	if (time > self.flee_until || self.flee_ent.health <= 0 || !(self.flee_ent.items & IT_INVULNERABILITY))
	{
		self.flee_ent = world;
		return;
	}
	away = self.origin - self.flee_ent.origin;
	away_z = 0;
	if (vlen(away) < 1)
		return;

	self.enemy = world;
	ang = vectoangles(away);
	ang_x = 0;
	self.b_angle = ang;
	frik_walkmove(away);
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

bot_unblock

Players block each other, so two bots that meet in
a hallway (or one that comes up behind another) just
push on each other forever.  A bot that finds someone
right in its way steps sideways: to its right when
they are dead ahead (so two bots meeting head on pass
each other, like traffic), otherwise away from them.
If that doesn't free it for a moment the bot with the
lower number backs up as well.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

void() bot_unblock =
{
	local entity foe, hit;
	local vector dir, rel, side, step;
	local float lateral, ahead;

	if (!(self.flags & FL_ONGROUND) || self.waterlevel > 1 || (self.b_aiflags & (AI_PRECISION | AI_BLIND)))
	{
		self.bump_since = 0;
		return;
	}

	// which way am I trying to go?
	dir = self.velocity;
	if (vlen(dir) < 60 && self.target1_ent)
		dir = realorigin(self.target1_ent) - self.origin;
	dir_z = 0;
	if (vlen(dir) < 1)
	{
		self.bump_since = 0;
		return;
	}
	dir = normalize(dir);

	// someone right in front of me?
	hit = world;
	foe = player_head;
	while (foe)
	{
		if (foe != self && foe.health > 0 && foe.modelindex != 0)
		{
			rel = foe.origin - self.origin;
			if (fabs(rel_z) < 48)
			{
				rel_z = 0;
				if (vlen(rel) < 56)
				{
					ahead = normalize(rel) * dir;
					if (ahead > 0.5)
						hit = foe;
				}
			}
		}
		foe = foe._next;
	}
	if (!hit)
	{
		self.bump_since = 0;
		return;
	}
	if (!self.bump_since)
		self.bump_since = time;

	rel = hit.origin - self.origin;
	rel_z = 0;
	side_x = dir_y;
	side_y = 0 - dir_x;
	lateral = rel * side; // positive: they are to my right
	if (fabs(lateral) < 12)
		step = side;
	else if (lateral > 0)
		step = '0 0 0' - side;
	else
		step = side;

	if (time - self.bump_since > 1 && self.b_clientno < hit.b_clientno)
		frik_walkmove(step * 1.5 - dir);
	else
		frik_walkmove(step * 1.5 + dir * 0.5);
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

bot_squeeze

A bot heads straight for its next waypoint, so one that
is a little off to the side of a doorway runs into the
wall beside it and keeps pushing: it has no idea it only
has to move over.  When a bot is pushing forward but not
getting anywhere it looks for the smallest sideways step
that leaves room for its whole body to go toward the
target, and takes it.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

void() bot_squeeze =
{
	local vector dir, perp, p, a, b, ahead, target, flat;
	local float dist, off, side, tries, found;

	// only a bot on the ground that wants to go forward and isn't
	if (!(self.flags & FL_ONGROUND) || !self.target1_ent || self.waterlevel > 1
		|| (self.b_aiflags & (AI_PRECISION | AI_BLIND | AI_WAIT)) || !(self.keys & KEY_MOVEFORWARD))
	{
		self.wall_since = 0;
		self.wall_logged = FALSE;
		return;
	}
	flat = self.velocity;
	flat_z = 0;
	if (vlen(flat) > 40)
	{
		self.wall_sq = 0;
		self.wall_since = 0;
		self.wall_logged = FALSE;
		return;
	}
	if (!self.wall_since)
		self.wall_since = time;
	if (time - self.wall_since < 0.3)
		return;

	target = realorigin(self.target1_ent);
	dir = target - self.origin;
	// a doorway is on the level the bot is on.  a target far above or below is a plat, a lift or a
	// ledge the bot is waiting at, which sideways steps won't help
	if (fabs(dir_z) > 64)
		return;
	dir_z = 0;
	dist = vlen(dir);
	if (dist < 40)
		return;
	dir = dir * (1 / dist);
	perp_x = 0 - dir_y;
	perp_y = dir_x;
	perp_z = 0;
	ahead = dir * min(dist, 80);

	// a wall has to be in the way of the body: if both edges have a clear run toward the target
	// the bot is waiting for something (a plat, a door, a teleporter), not jammed
	a = self.origin + perp * 14;
	b = self.origin - perp * 14;
	traceline(a, a + ahead, TRUE, self);
	if (trace_fraction == 1)
	{
		traceline(b, b + ahead, TRUE, self);
		if (trace_fraction == 1)
			return;
	}

	// the smallest shift wins; the side it stepped last time goes first so it doesn't dither
	found = FALSE;
	off = 16;
	while (off <= 48 && !found)
	{
		tries = 0;
		while (tries < 2 && !found)
		{
			side = self.wall_side;
			if (!side)
				side = 1;
			if (tries)
				side = 0 - side;
			p = self.origin + perp * (off * side);
			traceline(self.origin, p, TRUE, self);
			if (trace_fraction == 1)
			{
				// room for both edges of the body, and the middle, all the way ahead
				a = p + perp * 14;
				b = p - perp * 14;
				traceline(a, a + ahead, TRUE, self);
				if (trace_fraction == 1)
				{
					traceline(b, b + ahead, TRUE, self);
					if (trace_fraction == 1)
					{
						traceline(p, p + ahead, TRUE, self);
						if (trace_fraction == 1)
							found = TRUE;
					}
				}
			}
			if (!found)
				tries = tries + 1;
		}
		if (!found)
			off = off + 16;
	}

	if (cv_scarlet_dev_botlog && !self.wall_logged && time - self.wall_since >= 1)
	{
		self.wall_logged = TRUE;
		dprint("BOTWALL ");
		dprint(ftos(time));
		dprint(" ");
		dprint(self.netname);
		dprint(found ? " can step over " : " no way round ");
		dprint(self.target1_ent.classname);
		dprint(" at ");
		dprint(vtos(self.origin));
		dprint(" to ");
		dprint(vtos(target));
		dprint("\n");
	}

	if (found)
	{
		self.wall_side = side;
		if (!self.wall_sq)
		{
			self.wall_sq = time;
			if (cv_scarlet_dev_botlog)
			{
				dprint("BOTSQUEEZE ");
				dprint(self.netname);
				dprint(" at ");
				dprint(vtos(self.origin));
				dprint(" to ");
				dprint(vtos(target));
				dprint(" ");
				dprint(self.target1_ent.classname);
				dprint(" side ");
				dprint(ftos(side));
				dprint(" off ");
				dprint(ftos(off));
				dprint("\n");
			}
		}
		frik_walkmove(perp * side);
	}
};
