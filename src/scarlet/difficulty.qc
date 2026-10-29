// -------------------------------------------------
// Single player and coop difficulty settings: how many monsters there are, how hard they hit
// and how fast they chase, per skill.  1 is the map and the game as id built them.
// by whipowill
// -------------------------------------------------

float() sp_or_coop = { return (coop || !deathmatch); }

// how much faster monsters react and chase once they have seen a player
float() ai_chase_mult =
{
	local float m;

	if (!sp_or_coop())
		return 1;
	if (cvar("skill") < 0.5) m = cv_scarlet_singleplayer_monsters_speed_easy;
	else if (cvar("skill") < 1.5) m = cv_scarlet_singleplayer_monsters_speed_normal;
	else if (cvar("skill") < 2.5) m = cv_scarlet_singleplayer_monsters_speed_hard;
	else m = cv_scarlet_singleplayer_monsters_speed_nightmare;
	if (m > 1)
		return m;
	return 1;
}

// how much harder monsters hit players
float() monster_damage_mult =
{
	local float m;

	if (!sp_or_coop())
		return 1;
	if (cvar("skill") < 0.5) m = cv_scarlet_singleplayer_monsters_damage_easy;
	else if (cvar("skill") < 1.5) m = cv_scarlet_singleplayer_monsters_damage_normal;
	else if (cvar("skill") < 2.5) m = cv_scarlet_singleplayer_monsters_damage_hard;
	else m = cv_scarlet_singleplayer_monsters_damage_nightmare;
	if (m > 0)
		return m;
	return 1;
}

// how many monsters there are.  below 1 removes some as they spawn, above 1 adds extra
// ones next to the mapper's, as they spawn
float() monster_density_mult =
{
	local float m;

	if (!sp_or_coop())
		return 1;
	if (cvar("skill") < 0.5) m = cv_scarlet_singleplayer_monsters_density_easy;
	else if (cvar("skill") < 1.5) m = cv_scarlet_singleplayer_monsters_density_normal;
	else if (cvar("skill") < 2.5) m = cv_scarlet_singleplayer_monsters_density_hard;
	else m = cv_scarlet_singleplayer_monsters_density_nightmare;
	if (m > 0)
		return m;
	return 1;
}

// monsters the density setting must leave alone: anything that triggers something when it
// dies, or is triggered itself
float(entity m) monster_density_protected =
{
	if (m.targetname != string_null)
		return TRUE;
	if (m.target != string_null || m.killtarget != string_null)
		return TRUE;
	return FALSE;
}

float density_cloning;
float density_clones;

// call the spawn function of a monster by its classname
void(string cn) monster_density_spawn =
{
	if (cn == "monster_army") monster_army();
	else if (cn == "monster_dog") monster_dog();
	else if (cn == "monster_ogre") monster_ogre();
	else if (cn == "monster_knight") monster_knight();
	else if (cn == "monster_hell_knight") monster_hell_knight();
	else if (cn == "monster_zombie") monster_zombie();
	else if (cn == "monster_wizard") monster_wizard();
	else if (cn == "monster_demon1") monster_demon1();
	else if (cn == "monster_shambler") monster_shambler();
	else if (cn == "monster_tarbaby") monster_tarbaby();
	else if (cn == "monster_enforcer") monster_enforcer();
	else if (cn == "monster_shalrath") monster_shalrath();
}

float(string cn) monster_density_clonable =
{
	return (cn != "monster_fish" && cn != "monster_boss" && cn != "monster_oldone");
}

// a clear spot a few steps from the monster, or '0 0 0'
vector(entity mon) monster_density_spot =
{
	local float tries, ok, dist;
	local vector spot, ang;

	tries = 0;
	while (tries < 8)
	{
		tries = tries + 1;
		ang = '0 0 0';
		ang_y = random() * 360;
		makevectors(ang);
		dist = 80 + random() * 60;
		spot = mon.origin + v_forward * dist;
		traceline(mon.origin, spot, TRUE, mon);
		if (trace_fraction < 1 || pointcontents(spot) != CONTENT_EMPTY)
			continue;
		ok = TRUE;
		// walkers need floor under the spot
		if (mon.classname != "monster_wizard")
		{
			traceline(spot, spot - '0 0 80', TRUE, mon);
			if (trace_fraction == 1)
				ok = FALSE;
		}
		// and some room around it
		if (ok)
		{
			traceline(spot, spot + v_forward * 24, TRUE, mon);
			if (trace_fraction < 1) ok = FALSE;
			traceline(spot, spot - v_forward * 24, TRUE, mon);
			if (trace_fraction < 1) ok = FALSE;
			traceline(spot, spot + v_right * 24, TRUE, mon);
			if (trace_fraction < 1) ok = FALSE;
			traceline(spot, spot - v_right * 24, TRUE, mon);
			if (trace_fraction < 1) ok = FALSE;
		}
		if (ok)
			return spot;
	}
	return '0 0 0';
}

// called by every monster spawn function (self is the monster).  returns TRUE if the monster
// was removed to thin the monsters out.  otherwise adds the extra monsters, if there are any.
// precaching is only allowed while the map loads, so this has to happen as they spawn.
float() MonsterDensity =
{
	local float m, extra, i;
	local entity oself, tmpl;
	local vector spot;

	if (density_cloning)
		return FALSE;

	m = monster_density_mult();
	if (m < 1 && !monster_density_protected(self))
	{
		if (random() >= m)
		{
			remove(self);
			return TRUE;
		}
	}
	if (m <= 1 || monster_density_protected(self) || !monster_density_clonable(self.classname))
		return FALSE;

	extra = floor(m - 1);
	if (random() < (m - 1) - extra)
		extra = extra + 1;

	oself = self;
	density_cloning = TRUE;
	i = 0;
	while (i < extra && density_clones < 250)
	{
		spot = monster_density_spot(oself);
		if (spot != '0 0 0')
		{
			tmpl = spawn();
			setorigin(tmpl, spot);
			tmpl.angles = oself.angles;
			tmpl.classname = oself.classname;
			tmpl.spawnflags = oself.spawnflags;
			self = tmpl;
			monster_density_spawn(oself.classname);
			self = oself;
			density_clones = density_clones + 1;
		}
		i = i + 1;
	}
	density_cloning = FALSE;
	return FALSE;
}
