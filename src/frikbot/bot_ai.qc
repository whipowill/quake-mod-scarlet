/***********************************************
*                                              *
*            FrikBot General AI                *
*     "The I'd rather be playing Quake AI"     *
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

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

target_onstack

checks to see if an entity is on the bot's stack

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

float(entity scot) target_onstack =
{
	if (scot == world)
		return FALSE;
	else if (self.target1_ent == scot)
		return 1;
	else if (self.target2_ent == scot)
		return 2;
	else if (self.target3_ent == scot)
		return 3;
	else if (self.target4_ent == scot)
		return 4;
	else
		return FALSE;
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

target_ent_add

adds a new entity to the stack, since it's a
LIFO stack, this will be the bot's new target1_ent

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

// how long a bot gets to reach its target: the usual couple of seconds, plus the time to walk there
// at a modest speed.  a flat two seconds is only about 600 units of running, so a long straight link
// could never be finished before the bot gave up on it just short of the end and went back
void() bot_set_search_time =
{
	self.search_time = time + searchtime_giveup;
	if (self.target1_ent && self.target1_ent.classname == "waypoint")
		self.search_time = self.search_time + vlen(self.target1_ent.origin - self.origin) / 200;
};

void(entity ent) target_ent_add =
{
	if (ent == world)
		return;
	if (target_onstack(ent))
		return;
	self.target4_ent = self.target3_ent;
	self.target3_ent = self.target2_ent;
	self.target2_ent = self.target1_ent;
	self.target1_ent = ent;
	bot_set_search_time();
};


/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

target_ent_drop

Removes an entity from the bot's target stack.
The stack will empty everything up to the object
So if you have target2_ent item_health, target1_ent
waypoint, and you drop the health, the waypoint
is gone too.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

void(entity ent) target_ent_drop =
{
	local float tg;
	
	tg = target_onstack(ent);
	if (tg == 1)
	{
		self.target1_ent = self.target2_ent;
		self.target2_ent = self.target3_ent;
		self.target3_ent = self.target4_ent;
		self.target4_ent = world;
	}
	else if (tg == 2)
	{
		self.target1_ent = self.target3_ent;
		self.target2_ent = self.target4_ent;
		self.target3_ent = self.target4_ent = world;
	}
	else if (tg == 3)
	{
		self.target1_ent = self.target4_ent;
		self.target2_ent = self.target3_ent = self.target4_ent = world;
	}
	else if (tg == 4)
		self.target1_ent = self.target2_ent = self.target3_ent = self.target4_ent = world;
	bot_set_search_time();
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

bot_lost

Bot has lost its target.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

// dev: one line per bot per second with where it is and what it is after, and a line each
// time it reaches or gives up on a goal.  scarlet_dev_botlog turns it on
.float dev_logtime;

void(entity targ, float success) bot_lost =
{
	if (!targ)
		return;

	if (cv_scarlet_dev_botlog)
	{
		dprint("BOTLOST ");
		dprint(ftos(time));
		dprint(" ");
		dprint(self.netname);
		dprint(success ? " ok " : " fail ");
		dprint(targ.classname);
		dprint(" ");
		dprint(vtos(targ.origin));
		dprint("\n");
	}

	target_ent_drop(targ);
	if (targ.classname == "waypoint")
		targ.b_sound = targ.b_sound - (targ.b_sound & ClientBitFlag(self.b_clientno));

	// find a new route
	if (!success)
	{
		self.target1_ent = self.target2_ent = self.target3_ent = self.target4_ent = world;
		self.last_way = FindWayPoint(self.current_way);
		ClearMyRoute();
		self.b_aiflags = 0;
	}
        else
        {
		// bots used to announce important pickups (pent, quad, armor, etc) to their team here,
		// that chat was removed

                if (targ.flags & FL_ITEM)
                {
                        if (targ.model == string_null)
                                targ._last = world;
                        else
                                targ._last = self;
                }
        }


	if (targ.classname != "player")
	{
		targ.search_time = time + 5;
		// SCARLET - an item the bots keep failing to reach (no route, a wall in the way) is left alone for longer each time
		if (targ.flags & FL_ITEM)
		{
			if (success)
				targ.lost_count = 0;
			else
			{
				targ.lost_count = targ.lost_count + 1;
				targ.search_time = time + min(5 * targ.lost_count * targ.lost_count, 90);
			}
		}
	}
	else if (!success)
	{
		// a player has no give-up timer of its own to set (search_time is its own), so the bot
		// remembers: without this it picks the same unreachable player every scan, fails, and
		// stands there instead of going for anything else
		self.avoid_ent = targ;
		self.avoid_until = time + 4;
	}
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

bot_check_lost

decide if my most immediate target should be
removed.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
// how close a following bot gets to its player.  scarlet_singleplayer_bots_follow_distance is for
// single player and co-op only, teamplay deathmatch keeps the original 128
float() bot_follow_distance =
{
	if (coop || !deathmatch)
		return cv_scarlet_singleplayer_bots_follow_distance;
	return 128;
};

void(entity targ) bot_check_lost =
{
	local vector dist;

	if (targ == world)
		return;

	// waypoints and items are lost if you get close enough to them

	else if (targ.flags & FL_ITEM)
	{
		if (vlen(targ.origin - self.origin) < 32)
			bot_lost(targ, TRUE);
		else if (targ.model == string_null)
			bot_lost(targ, TRUE);
	}
	else if (targ.classname == "waypoint")
	{
		if (!(self.b_aiflags & (AI_SNIPER | AI_AMBUSH)))
		{
			if (self.b_aiflags & AI_RIDE_TRAIN)
			{
				if (vlen(targ.origin - self.origin) < 48)
					bot_lost(targ, TRUE);
			}
			else if (self.b_aiflags & AI_PRECISION)
			{
				if (vlen(targ.origin - self.origin) < 24)
					bot_lost(targ, TRUE);
			}
			else if (vlen(targ.origin - self.origin) < 32)
				bot_lost(targ, TRUE);
		}
	}
	else if (targ.classname == "temp_waypoint")
	{
		if (vlen(targ.origin - self.origin) < 32)
			bot_lost(targ, TRUE);
	}
	else if (targ.classname == "player")
	{
		if (targ.health <= 0)
			bot_lost(targ, TRUE);
		else if ((coop || !deathmatch) || (teamplay && targ.team == self.team))
		{
			if (targ.target1_ent.classname == "player")
			{
				if (!targ.target1_ent.ishuman)
					bot_lost(targ, TRUE);
			}
			else if (targ.teleport_time > time)
			{
				// try not to telefrag teammates
				self.keys = self.keys & 960;
			}
			else if (vlen(targ.origin - self.origin) < bot_follow_distance())
			{
				if (vlen(targ.origin - self.origin) < bot_follow_distance() * 0.375)
					frik_walkmove(self.origin - targ.origin);
				else
				{
					self.keys = self.keys & 960;
					bot_start_topic(7);
				}
				self.search_time = time + searchtime_giveup; // never time out
			}
			else if (!fisible(targ))
				bot_lost(targ, FALSE);	
		}
		else if (waypoint_mode > WM_LOADED)
		{
			if (vlen(targ.origin - self.origin) < 128)
			{
				bot_lost(targ, TRUE);	
			}
		}
	}

	// buttons are lost of their frame changes
	else if (targ.classname == "func_button")
	{
		if (targ.frame)
		{
			bot_lost(targ, TRUE);
			if (self.enemy == targ)
				self.enemy = world;
			//if (self.target1_ent)
			//	bot_get_path(self.target1_ent, TRUE);
				
		}
	}
	// trigger_multiple style triggers are lost if their thinktime changes
	else if ((targ.movetype == MOVETYPE_NONE) && (targ.solid == SOLID_TRIGGER))
	{
		if (targ.nextthink >= time)
		{
			bot_lost(targ, TRUE);
			//if (self.target1_ent)
			//	bot_get_path(self.target1_ent, TRUE);
		}
	}
	// lose any target way above the bot's head
	// FIXME: if the bot can fly in your mod..
	if ((targ.origin_z - self.origin_z) > 32) // make this shorter? does it have any effect? (original value was 64) -whipowill
	{
		dist = targ.origin - self.origin;
		dist_z = 0;
		if (vlen(dist) < 32)
			if (self.flags & FL_ONGROUND)
				if(!frik_recognize_plat(FALSE))
					bot_lost(targ, FALSE);
	}
	else if (targ.classname == "train")
	{
		if (frik_recognize_plat(FALSE))
			bot_lost(targ, TRUE);
	}
	else if (targ.classname == "trigger_teleport") // this is huge, was missing from original frikbot, no more spammy teleporting bots! -whipowill
	{
		// teleport detection is handled in BotAI()
	}

	// targets are lost if the bot's search time has expired
	if (time > self.search_time)
	{
		if (cv_scarlet_dev_botlog)
		{
			dprint("BOTTIMEOUT ");
			dprint(self.netname);
			dprint(" ");
			dprint(targ.classname);
			dprint("\n");
		}
		bot_lost(targ, FALSE);
	}
};


/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

bot_handle_ai

This is a 0.10 addition. Handles any action
based b_aiflags.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

void() bot_handle_ai =
{
	local entity newt;
	local vector v;

	// handle ai flags -- note, not all aiflags are handled
	// here, just those that perform some sort of action

	// wait is used by the ai to stop the bot until his search time expires / or route changes

	if (self.b_aiflags & AI_WAIT)
		self.keys = self.keys & 960;

	if (self.b_aiflags & AI_DOORFLAG) // was on a door when spawned
	{
		b_temp3 = self;
		self = self.last_way;
		if (!frik_recognize_plat(FALSE)) // if there is nothing there now
		{
			newt = FindThing("door"); // this is likely the door responsible (crossfingers)
			self = b_temp3;

			if (self.b_aiflags & AI_DOOR_NO_OPEN)
			{
				if (newt.nextthink)
				{
					self.keys = self.keys & 960; // wait until it closes
				}
				else
				{
					bot_lost(self.last_way, FALSE);
				}
			}
			else
			{
				if (newt.targetname)
				{
					newt = find(world, target, newt.targetname);
					if (newt.health > 0) 
					{
						self.enemy = newt;
						bot_weapon_switch(1);
					}
					else
					{
					//	target_ent_drop(self.last_way);
						target_ent_add(newt);
					//	bot_get_path(newt, TRUE);
					}
				}
				self.b_aiflags = self.b_aiflags - AI_DOORFLAG;
			}
		}
		else
			self = b_temp3;
	}

	if (self.b_aiflags & AI_JUMP)
	{
		if (self.flags & FL_ONGROUND)
		{
			bot_jump();
			self.b_aiflags = self.b_aiflags - AI_JUMP;
		}
	}
	else if (self.b_aiflags & AI_SUPER_JUMP)
	{
		if (self.weapon != 32)
			self.impulse = 7;
		else if (self.flags & FL_ONGROUND)
		{
			self.b_aiflags = self.b_aiflags - AI_SUPER_JUMP;
			if (bot_can_rj(self))
			{
				bot_jump();
				self.v_angle_x = self.b_angle_x = 80;
				self.button0 = TRUE;
			}
			else
				bot_lost(self.target1_ent, FALSE);
			
		}
	}
	if (self.b_aiflags & AI_SURFACE)
	{
		if (self.waterlevel > 2)
  		{
			self.keys = KEY_MOVEUP;
			self.button2 = TRUE; // swim!
    		}
		else
			self.b_aiflags = self.b_aiflags - AI_SURFACE;
	}
	if (self.b_aiflags & AI_RIDE_TRAIN)
	{
		// simple, but effective
		// this can probably be used for a lot of different
		// things, not just trains (door elevators come to mind)
		b_temp3 = self;
		self = self.last_way;
	
		if (!frik_recognize_plat(FALSE)) // if there is nothing there now
		{
			self = b_temp3;
			self.keys = self.keys & 960;
		}
		else
		{
			self = b_temp3;
			if (frik_recognize_plat(FALSE))
			{
				v = realorigin(trace_ent) + trace_ent.origin - self.origin;
				v_z = 0;
				if (vlen(v) < 24)
					self.keys = self.keys & 960;
				else
				{
					self.b_aiflags = self.b_aiflags | AI_PRECISION;
					self.keys = frik_KeysForDir(v);
				}
			}
		}
	}
	if (self.b_aiflags & AI_PLAT_BOTTOM)
	{
		newt = FindThing("plat");
		if (newt.state != 1)
		{
			v =  self.origin - realorigin(newt);
			v_z = 0;
			if (vlen(v) > 96)
				self.keys = self.keys & 960;
			else
				frik_walkmove(v);
		}
		else
		{
			self.b_aiflags = self.b_aiflags - AI_PLAT_BOTTOM;
		}
	}
	if (self.b_aiflags & AI_DIRECTIONAL)
	{
		if ((normalize(self.last_way.origin - self.origin) * self.b_dir) > 0.4)
		{
			self.b_aiflags = self.b_aiflags - AI_DIRECTIONAL;
			bot_lost(self.target1_ent, TRUE);
		}
	}
	if (self.b_aiflags & AI_SNIPER)
	{
		self.b_aiflags = (self.b_aiflags | AI_WAIT | AI_PRECISION) - AI_SNIPER;
		// FIXME: Add a switch to wep command
		// FIXME: increase delay?
	}
	if (self.b_aiflags & AI_AMBUSH)
	{
		self.b_aiflags = (self.b_aiflags | AI_WAIT) - AI_AMBUSH;
		// FIXME: Add a switch to wep command
		// FIXME: increase delay?
	}

};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

bot_path

Bot will follow a route generated by the
begin_route set of functions in bot_way.qc.
This code, while it works pretty well, can get
confused

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

void() bot_path =
{
	local entity jj, tele;

	bot_check_lost(self.target1_ent);
	if (!self.target1_ent)
	{
		self.keys=0;
		return;
	}
	if (target_onstack(self.last_way))
		return; // old waypoint still being hunted

	jj = FindRoute(self.last_way);
	if (!jj)
	{
		// this is an ugly hack
		if (self.target1_ent.current_way != self.last_way)
		{
			if (self.target1_ent.classname != "temp_waypoint")
				if (self.target1_ent.classname != "player")
					bot_lost(self.target1_ent, FALSE);
		}

		return;
	}

	// update the bot's special ai features

	// Readahed types are AI conditions to perform while heading to a waypoint
	// point types are AI flags that should be executed once reaching a waypoint

	self.b_aiflags = (jj.b_aiflags & AI_READAHEAD_TYPES) | (self.last_way.b_aiflags & AI_POINT_TYPES);
	target_ent_add(jj);
	if (self.last_way)
	{
		if (CheckLinked(self.last_way, jj) == 2) // waypoints are telelinked
		{
			tele = FindThing("trigger_teleport"); // this is probbly the teleport responsible
			target_ent_add(tele);
		}

		traceline(self.last_way.origin, jj.origin, FALSE, self); // check for blockage
   		if (trace_fraction != 1)
		{
			if (trace_ent.classname == "door" && !(self.b_aiflags & AI_DOOR_NO_OPEN)) // a door blocks the way
			{
				// linked doors fix
				if (trace_ent.owner)
					trace_ent = trace_ent.owner;
				if ((trace_ent.health > 0) && (self.enemy == world))
				{
					self.enemy = trace_ent;
					bot_weapon_switch(1);
					self.b_aiflags = self.b_aiflags | AI_BLIND; // nick knack paddy hack
				}
				else if (trace_ent.targetname)
				{
					tele = find(world, target, trace_ent.targetname);
					if (tele.health > 0) 
					{
						self.enemy = tele;
						bot_weapon_switch(1);
					}
					else
					{
					//	target_ent_drop(jj);
						target_ent_add(tele);
					//	bot_get_path(tele, TRUE);
						self.b_aiflags = self.b_aiflags | AI_BLIND; // give a bot a bone	
						return;
					}					
				}		
			}
			else if (trace_ent.classname == "func_wall")
			{
				// give up
				bot_lost(self.target1_ent, FALSE);
				return;
			}
		}
	}
	// this is used for AI_DRIECTIONAL
	self.b_dir = normalize(jj.origin - self.last_way.origin);

	self.last_way = jj;
};


/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Bot Priority Look. What a stupid name. This is where
the bot finds things it wants to kill/grab.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
// priority scale
// 0 - 10 virtually ignore
// 10 - 30 normal item range
// 30 - 50 bot will consider this a target worth changing course for
// 50 - 90 bot will hunt these as vital items

// *!* Make sure you add code to bot_check_lost to remove the target *!*


float(entity thing) priority_for_thing =
{
	local float thisp;
	thisp = 0;
	// This is the most executed function in the bot. Careful what you do here.

	if ((thing.flags & FL_ITEM) && thing.model != string_null && thing.search_time < time)
	{
		// ugly hack
                if (thing._last != self)
                        thisp = 20;

		//~ ai fix start -- ryan commented this out? - whipowill
		/* 					 
		if (thing.classname == "item_artifact_super_damage")
			thisp = 65;
		else if (thing.classname == "item_artifact_invulnerability")
			thisp = 65;
		else if (thing.classname == "item_health")
		{
			if (thing.spawnflags & 2)
				thisp = 55;
			if (self.health < 40)
				thisp = thisp + 50;
		}
		else if (thing.model == "progs/armor.mdl")
		{
			if (self.armorvalue < 200)
			{		
				if (thing.skin == 2)
					thisp = 60;
				else if (self.armorvalue < 100)			
					thisp = thisp + 25;
			}
		}
		else if (thing.classname == "weapon_supershotgun")
		{
			if (!(self.items & 2)) // IT_SUPER_SHOTGUN  
				thisp = 25;
		}
		else if (thing.classname == "weapon_nailgun")
		{
			if (!(self.items & 4)) // IT_NAILGUN 
				thisp = 30;
		}
		else if (thing.classname == "weapon_supernailgun")
		{
			if (!(self.items & 8)) // IT_SUPER_NAILGUN
				thisp = 35;
		}
		else if (thing.classname == "weapon_grenadelauncher")
		{
			if (!(self.items & 16)) // IT_GRENADE_LAUNCHER
				thisp = 45;
		}
		else if (thing.classname == "weapon_rocketlauncher")
		{
			if (!(self.items & 32)) // IT_ROCKET_LAUNCHER
				thisp = 60;
		}
		else if (thing.classname == "weapon_lightning")
		{
			if (!(self.items & 64)) // IT_LIGHTNING
				thisp = 50;
		}
		*/

		// these don't work so i repeat these further down...?? maybe these aren't "ITEMS"?
		if (thing.classname == "item_artifact_super_damage")
			thisp = cv_scarlet_bot_priority_quad; // was 55 -whipowill
		else if (thing.classname == "item_artifact_invulnerability")
			thisp = cv_scarlet_bot_priority_pent; // was 55 -whipowill
		else if (thing.classname == "item_artifact_invisibility")
			thisp = cv_scarlet_bot_priority_ring; // was 55 -whipowill
		else if (thing.model == "maps/b_bh100.bsp" || thing.model == "progs/items/quoth/cross.mdl")
			thisp = cv_scarlet_bot_priority_mega; // megahealth wasn't even in here as being special -whipowill


		else if (thing.classname == "item_health")
		{
			if (thing.spawnflags & 2)
				thisp = 10*(random()) + 50;
			if (self.health <= 50)
				thisp = 70;
		}
		else if (thing.classname == "weapon_rocketlauncher")
		{
			if (!(self.items & 32)) // IT_ROCKET_LAUNCHER
				thisp = 60;
		}
		else if (thing.classname == "weapon_lightning")
		{
			if (!(self.items & 64)) // IT_LIGHTNING
				thisp = 50;
		}
		else if (thing.classname == "weapon_grenadelauncher")
		{
			if (!(self.items & 16)) // IT_GRENADE_LAUNCHER
				thisp = 45;
		}
		else if (thing.classname == "weapon_supernailgun")
		{
			if (!(self.items & 8)) // IT_SUPER_NAILGUN
				thisp = 35;
		}
		else if (thing.classname == "weapon_nailgun")
		{
			if (!(self.items & 4)) // IT_NAILGUN 
				thisp = 30;
		}
		else if (thing.classname == "weapon_supershotgun")
		{
			if (!(self.items & 2)) // IT_SUPER_SHOTGUN  
				thisp = 25;
		}
		else if (thing.model == "progs/armor.mdl")
		{
			if (self.armorvalue < 200)
			{
				if (self.armorvalue <= 50)
					thisp = 60;
				else if (self.armorvalue <= 100 && thing.classname != "item_armor1")
					thisp = 55;
				else if (self.armorvalue <= 150 && thing.classname == "item_armorInv")
					thisp = 50;
			}
		}
		else if (thing.model == "progs/backpack.mdl")
			thisp = 45;
		else if (thing.classname == "item_artifact_envirosuit")
			thisp = 30;

		// an item that would do nothing for this bot is no goal, or the bot walks up and stands on
		// it until it gives up (health at full health, ammo at the cap)
		if (thisp)
		{
			if (thing.classname == "item_health")
			{
				if (!(thing.spawnflags & 2) && self.health >= 100)
					thisp = 0;
			}
			else if (bot_armor_worth(thing))
			{
				// armor that is no better than what the bot wears can't be taken
				if (self.armortype * self.armorvalue >= bot_armor_worth(thing))
					thisp = 0;
			}
			else if (thing.classname == "item_shells")
			{
				if (self.ammo_shells >= cv_scarlet_ammo_max_shells)
					thisp = 0;
			}
			else if (thing.classname == "item_spikes")
			{
				if (self.ammo_nails >= cv_scarlet_ammo_max_nails)
					thisp = 0;
			}
			else if (thing.classname == "item_rockets")
			{
				if (self.ammo_rockets >= cv_scarlet_ammo_max_rockets)
					thisp = 0;
			}
			else if (thing.classname == "item_cells")
			{
				if (self.ammo_cells >= cv_scarlet_ammo_max_cells)
					thisp = 0;
			}
		}
	}
	//~ ai fix end
	else if ((thing.flags & FL_MONSTER) && thing.health > 0)
		thisp = 45;
	else if (thing.classname == "player")
	{ 
		if (thing.health > 0)
		{
			if (thing == self)
				return 0;
			else if (thing == self.avoid_ent && self.avoid_until > time)
				return 0;
			else
			{
				if (thing.items & IT_INVISIBILITY) //FIXME
					thisp = 2;
				else if (coop || !deathmatch)
				{
					// follow real players only, never other bots
					if (!thing.ishuman)
						return 0;
					thisp = 200;
					if (thing.target1_ent.classname == "player")
						if (!thing.target1_ent.ishuman)
							return 0;
				}
				else if (teamplay && thing.team == self.team)
				{
					//thisp = 100; don't follow teammates on teamplay! -whipowill
					if (thing.target1_ent.classname == "player")
						return 0;
				}
				else thisp = 30;
			}
		}
	}
	else if (thing.classname == "waypoint")
	{
		if (thing.b_aiflags & AI_SNIPER)
			thisp = 45; //~ ai fix
		else if (thing.b_aiflags & AI_AMBUSH)
			thisp = 30;
	}
	// most entities (gibs, splats, projectiles, waypoints) score nothing, so bail out
	// before the pointcontents() engine call. this runs for every entity per scan.
	if (!thisp)
		return 0;
	// single player and coop: only care about things near a player, otherwise bots run
	// across the map for a far away megahealth over and over
	if (thing.trail_skip)
		return 0;
	if ((coop || !deathmatch) && thing.classname != "player")
		if (!bot_near_human(thing.origin))
			return 0;
	if (pointcontents(thing.origin) < -3)
		return 0;
	if (thisp)
	{
		if (thing.current_way)
		{
			// check to see if it's unreachable
			if (thing.current_way.items == -1)
				return 0;
			else
				thisp = thisp + (13000 - thing.current_way.items) * 0.05; 
		}
	} 		
	return thisp;
};

float dev_why_items, dev_why_gone, dev_why_blocked, dev_why_unreach, dev_why_zero;

// what a piece of armor is worth: protection times points (green 30, yellow 90, red 160).  the
// game only lets you take armor worth more than what you wear
float(entity thing) bot_armor_worth =
{
	if (thing.classname == "item_armor1")
		return 30;
	if (thing.classname == "item_armor2")
		return 90;
	if (thing.classname == "item_armorInv")
		return 160;
	return 0;
};

// how much this bot would like to get to the spot of an item, whether or not the item is
// there right now (one that is respawning is a place to go and wait for it).  0 is no use.
float(entity thing) bot_spot_value =
{
	local float v;
	v = 0;
	if (thing.trail_skip)
		return 0;
	if (thing.classname == "item_artifact_super_damage")
	{
		if (!(self.items & IT_QUAD)) v = cv_scarlet_bot_priority_quad;
	}
	else if (thing.classname == "item_artifact_invulnerability")
	{
		if (!(self.items & IT_INVULNERABILITY)) v = cv_scarlet_bot_priority_pent;
	}
	else if (thing.classname == "item_artifact_invisibility")
	{
		if (!(self.items & IT_INVISIBILITY)) v = cv_scarlet_bot_priority_ring;
	}
	else if (thing.classname == "item_artifact_envirosuit")
	{
		if (!(self.items & IT_SUIT)) v = 30;
	}
	else if (thing.classname == "item_health")
	{
		if (thing.spawnflags & 2)
			v = cv_scarlet_bot_priority_mega;
		else if (self.health <= 50)
			v = 70;
		else if (self.health < 100)
			v = 40;
	}
	else if (thing.classname == "weapon_rocketlauncher")
	{
		if (!(self.items & 32)) v = 60;
	}
	else if (thing.classname == "weapon_lightning")
	{
		if (!(self.items & 64)) v = 50;
	}
	else if (thing.classname == "weapon_grenadelauncher")
	{
		if (!(self.items & 16)) v = 45;
	}
	else if (thing.classname == "weapon_supernailgun")
	{
		if (!(self.items & 8)) v = 35;
	}
	else if (thing.classname == "weapon_nailgun")
	{
		if (!(self.items & 4)) v = 30;
	}
	else if (thing.classname == "weapon_supershotgun")
	{
		if (!(self.items & 2)) v = 25;
	}
	else if (bot_armor_worth(thing))
	{
		if (self.armortype * self.armorvalue < bot_armor_worth(thing))
		{
			if (self.armorvalue <= 50) v = 60;
			else v = 45;
		}
	}
	else if (thing.classname == "item_shells")
	{
		if (self.ammo_shells < cv_scarlet_ammo_max_shells) v = 30;
	}
	else if (thing.classname == "item_spikes")
	{
		if (self.ammo_nails < cv_scarlet_ammo_max_nails) v = 30;
	}
	else if (thing.classname == "item_rockets")
	{
		if (self.ammo_rockets < cv_scarlet_ammo_max_rockets) v = 35;
	}
	else if (thing.classname == "item_cells")
	{
		if (self.ammo_cells < cv_scarlet_ammo_max_cells) v = 25;
	}
	return v;
};

// when no item is there to be taken, a bot goes round the places the things it needs appear,
// the way a player does, instead of standing still.  only when it needs nothing at all does it
// pick a waypoint at random
void() bot_patrol =
{
	local entity foe, t, spot, pick;
	local float score, best, n, d, bestd, tries;

	// the best spot to be at
	pick = world;
	best = 0;
	foe = findradius(self.origin, 13000);
	while (foe)
	{
		if (foe.flags & FL_ITEM)
		{
			score = bot_spot_value(foe);
			if (score)
			{
				// closer is better, a little luck keeps bots from all taking the same loop
				score = score - vlen(foe.origin - self.origin) * 0.025 + random() * 10;
				if (score > best)
				{
					// and its waypoint (the nearest), skipping a spot the bot is already standing at
					spot = world;
					bestd = 100000;
					t = way_head;
					while (t)
					{
						if (!(t.b_aiflags & AI_IGNORE_TYPES))
						{
							d = vlen(t.origin - foe.origin);
							if (d < bestd)
							{
								bestd = d;
								spot = t;
							}
						}
						t = t._next;
					}
					if (spot && bestd < 200 && vlen(spot.origin - self.origin) > 100)
					{
						best = score;
						pick = spot;
					}
				}
			}
		}
		foe = foe.chain;
	}

	// it needs nothing from the map: any far off waypoint
	if (pick == world)
	{
		bestd = 0;
		tries = 0;
		while (tries < 8 && waypoints > 0)
		{
			tries = tries + 1;
			t = way_head;
			n = floor(random() * waypoints);
			while (n > 0 && t._next)
			{
				t = t._next;
				n = n - 1;
			}
			if (t.b_aiflags & AI_IGNORE_TYPES)
				continue;
			if (t.search_time >= time)
				continue;	// SCARLET - a waypoint goal that just got a bot stuck is banned for a while
			d = vlen(t.origin - self.origin);
			if (d > bestd)
			{
				bestd = d;
				pick = t;
			}
		}
	}

	if (pick == world)
	{
		// nowhere to go, so at least let the other bots have the route table
		route_table = world;
		return;
	}
	target_ent_add(pick);
	bot_get_path(pick, FALSE);
	self.b_aiflags = self.b_aiflags | AI_WAIT;
};

void(float scope) bot_look_for_crap =
{
	local entity foe, best;
	local float thatp, bestp, dist;

	// the local (nearby) scan runs every tick for idle bots, so don't do it that often
	if (!scope)
	{
		if (self.look_time > time)
			return;
		self.look_time = time + 0.25;
	}

	if (scope == 1)
		foe = findradius(self.origin, 13000);
	else
		foe = findradius(self.origin, 500);

	bestp = 1;
	dev_why_items = dev_why_gone = dev_why_blocked = dev_why_unreach = dev_why_zero = 0;
	while(foe)
	{
		thatp = priority_for_thing(foe);
		if (scope && (foe.flags & FL_ITEM))
		{
			dev_why_items = dev_why_items + 1;
			if (foe.model == string_null) dev_why_gone = dev_why_gone + 1;
			else if (foe.search_time >= time) dev_why_blocked = dev_why_blocked + 1;
			else if (!thatp)
			{
				if (foe.current_way.items == -1 && foe.current_way) dev_why_unreach = dev_why_unreach + 1;
				else dev_why_zero = dev_why_zero + 1;
			}
		}
		if (thatp)
			if (!scope)
				if (!sisible(foe))
					thatp = 0;
		// an item across the map is worth less than one close by.  a powerup (100 and up) is
		// worth the trip from anywhere
		if (thatp > 0 && thatp < 100 && cv_scarlet_bot_goal_distance > 0)
			thatp = thatp / (1 + vlen(self.origin - foe.origin) / cv_scarlet_bot_goal_distance);
		if (thatp > bestp)
		{
			bestp = thatp;
			best = foe;
			dist = vlen(self.origin - foe.origin);
		}
		foe = foe.chain;
	}
	if (cv_scarlet_dev_botlog && scope)
	{
		dprint("BOTSCAN ");
		dprint(ftos(time));
		dprint(" ");
		dprint(self.netname);
		dprint(" best ");
		dprint(best.classname);
		dprint(" ");
		dprint(ftos(bestp));
		dprint(" model ");
		dprint(best.model);
		dprint(" at ");
		dprint(vtos(best.origin));
		dprint(" name ");
		dprint(best.netname);
		dprint(" onstack ");
		dprint(ftos(target_onstack(best)));
		dprint(" holding ");
		dprint(ftos(route_table == self));
		dprint(" hp ");
		dprint(ftos(self.health));
		dprint(" armor ");
		dprint(ftos(self.armorvalue));
		dprint(" ammo ");
		dprint(ftos(self.ammo_shells));
		dprint("/");
		dprint(ftos(self.ammo_nails));
		dprint("/");
		dprint(ftos(self.ammo_rockets));
		dprint("/");
		dprint(ftos(self.ammo_cells));
		dprint(" items ");
		dprint(ftos(self.items));
		dprint(" why: items ");
		dprint(ftos(dev_why_items));
		dprint(" gone ");
		dprint(ftos(dev_why_gone));
		dprint(" blocked ");
		dprint(ftos(dev_why_blocked));
		dprint(" unreachable ");
		dprint(ftos(dev_why_unreach));
		dprint(" scores0 ");
		dprint(ftos(dev_why_zero));
		dprint("\n");
	}
	if (best == world)
	{
		// nothing to want.  without this the bot keeps the route table and rescans every
		// tick, and no other bot can get a route, so a match of friendly bots freezes
		if (scope == 1)
			bot_patrol();
		return;
	}
	if (!target_onstack(best))
	{	
		target_ent_add(best);
		if (scope)
		{
			bot_get_path(best, FALSE);
			self.b_aiflags = self.b_aiflags | AI_WAIT;
		}
	}
};


/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

bot_angle_set

Sets the bots look keys & b_angle to point at
the target - used for fighting and just
generally making the bot look good.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

void() bot_angle_set =
{
	local float h, w;
	local vector view;

	// a new enemy gets noticed after a reaction time that depends on skill
	if (self.enemy != self.react_enemy)
	{
		self.react_enemy = self.enemy;
		if (self.enemy)
			self.react_until = time + bot_reaction_time();
	}

	if (self.enemy && time >= self.react_until)
	{
		if (self.enemy.items & 524288)
			if (random() > 0.01)
				return;
		if (self.missile_speed == 0)
			self.missile_speed = 10000;
		if (self.enemy.solid == SOLID_BSP)
		{
			view = (((self.enemy.absmin + self.enemy.absmax) * 0.5) - self.origin);
		}
		else
		{
		
			local float levels;
			
			levels = bot_lead_levels();
			
			view = self.enemy.origin;
			
			while (levels)
			{
				h = vlen(view - self.origin) / self.missile_speed;
				if (self.enemy.flags & FL_ONGROUND)
					view = self.enemy.velocity * h + '0 0 -20';
				else
					view = (self.enemy.velocity - (sv_gravity * '0 0 1') * h) * h;
				view = self.enemy.origin + view; 
				traceline(self.enemy.origin, view, FALSE, self);
				view = trace_endpos;
				levels = levels - 1;
			}
			view = normalize(view - self.origin);
		}
		view = vectoangles(view);
		view_x = view_x * -1;
		self.b_angle = view;

		// a weaker bot's aim wobbles: a new offset every half second or so
		w = bot_wobble();
		if (w > 0)
		{
			if (time > self.aim_jtime)
			{
				self.aim_jtime = time + 0.4 + random() * 0.4;
				self.aim_jit_x = crandom() * w;
				self.aim_jit_y = crandom() * w;
			}
			self.b_angle_x = self.b_angle_x + self.aim_jit_x;
			self.b_angle_y = self.b_angle_y + self.aim_jit_y;
		}
	}
	else if (self.target1_ent)
	{
		view = realorigin(self.target1_ent);
		if (self.target1_ent.flags & FL_ITEM)
				view = view + '0 0 48';
		view = view - (self.origin + self.view_ofs);
		view = vectoangles(view);
		view_x = view_x * -1;
		// don't stare at the floor/ceiling while heading for a goal. fov() only notices
		// enemies within 45 degrees of the bot's pitch, so a bot circling a nearby goal
		// with its head pitched down never spots anyone until it's hit.
		while (view_x > 180)
			view_x = view_x - 360;
		while (view_x < -180)
			view_x = view_x + 360;
		if (view_x > 25)
			view_x = 25;
		else if (view_x < -25)
			view_x = -25;
		self.b_angle = view;
	}
	else
		self.b_angle_x = 0;
	// HACK HACK HACK HACK
	// The bot falls off ledges a lot because of "turning around"
	// so let the bot use instant turn around when not hunting a player
	if ((self.enemy == world || self.enemy.movetype == MOVETYPE_PUSH) && self.target1_ent.classname != "player")
	{
		self.keys = self.keys & 63;
		self.v_angle = self.b_angle;
		while (self.v_angle_x < -180)
			self.v_angle_x = self.v_angle_x + 360;
		while (self.v_angle_x > 180)
			self.v_angle_x = self.v_angle_x - 360;
	}
	else if (self.b_skill == 3) // FrikaC allowed instant reflexes for skill 3. -whipowill
	{
		self.keys = self.keys & 63;
		self.v_angle = self.b_angle;
		while (self.v_angle_x < -180)
			self.v_angle_x = self.v_angle_x + 360;
		while (self.v_angle_x > 180)
			self.v_angle_x = self.v_angle_x - 360;

	}
	else // use mouse emulation! -whipowill
	{
		// bot "accuracy" code
		local float accuracy;
		if (self.b_skill == 3) accuracy = .90;
		if (self.b_skill == 2) accuracy = .75;
		if (self.b_skill == 1) accuracy = .50;
		if (self.b_skill == 0) accuracy = .25;

		local float precision;
		precision = 15 * (1 - accuracy); // 15 degrees is what I chose as the max amount the bots can be off their aim

		if (self.b_angle_x > 180)
			self.b_angle_x = self.b_angle_x - 360;
		self.keys = self.keys & 63;

		if (angcomp(self.b_angle_y, self.v_angle_y) > precision)
			self.keys = self.keys | KEY_LOOKLEFT;
		else if (angcomp(self.b_angle_y, self.v_angle_y) < (precision * -1))
			self.keys = self.keys | KEY_LOOKRIGHT;
		if (angcomp(self.b_angle_x, self.v_angle_x) < (precision * -1))
			self.keys = self.keys | KEY_LOOKUP;
		else if (angcomp(self.b_angle_x, self.v_angle_x) > precision)
			self.keys = self.keys | KEY_LOOKDOWN;
	}
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

BotAI

This is the main ai loop. Though called every
frame, the ai_time limits it's actual updating

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
float stagger_think;

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

bot_grab_vital

The global scan only runs when a bot has no goal, so a bot en route to
something ordinary used to run right past a quad or pent in plain view.
While it has a goal, glance around for vital items (priority 100+) and
push one on top of the target stack. The old goal resumes afterwards.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
void() bot_grab_vital =
{
	local entity foe, best;
	local float thatp, bestp, goalp;

	if (self.look_time > time)
		return;
	self.look_time = time + 0.25;

	if (self.enemy)
		return;

	bestp = 99;
	foe = findradius(self.origin, 700);
	while (foe)
	{
		if (foe.flags & FL_ITEM)
		{
			thatp = priority_for_thing(foe);
			if (thatp > bestp)
				if (!target_onstack(foe))
					if (sisible(foe))
					{
						bestp = thatp;
						best = foe;
					}
		}
		foe = foe.chain;
	}
	// nothing vital in sight.  an ordinary item right beside the bot is still worth a detour when
	// it is worth more than the goal the bot is on its way to: a bot with green armor shouldn't walk
	// past yellow armor to get to a box of nails
	if (!best)
	{
		goalp = 0;
		if (self.target4_ent.flags & FL_ITEM)
			goalp = priority_for_thing(self.target4_ent);
		else if (self.target3_ent.flags & FL_ITEM)
			goalp = priority_for_thing(self.target3_ent);
		else if (self.target2_ent.flags & FL_ITEM)
			goalp = priority_for_thing(self.target2_ent);
		else if (self.target1_ent.flags & FL_ITEM)
			goalp = priority_for_thing(self.target1_ent);

		bestp = 49;
		if (goalp + 10 > bestp)
			bestp = goalp + 10;
		foe = findradius(self.origin, 200);
		while (foe)
		{
			if (foe.flags & FL_ITEM)
			{
				thatp = priority_for_thing(foe);
				if (thatp > bestp)
					if (!target_onstack(foe))
						if (sisible(foe))
						{
							bestp = thatp;
							best = foe;
						}
			}
			foe = foe.chain;
		}
		if (best && cv_scarlet_dev_botlog)
		{
			dprint("BOTGRAB ");
			dprint(self.netname);
			dprint(" ");
			dprint(best.classname);
			dprint(" worth ");
			dprint(ftos(bestp));
			dprint(" over ");
			dprint(ftos(goalp));
			dprint("\n");
		}
	}
	if (best)
		target_ent_add(best);
};

.float regroup_time;

// is this spot within the fight range of a human player?  in coop and single player the
// bots only pick fights near you, so they don't wander off after monsters across the map
float(vector org) bot_near_human =
{
	local entity head;
	local float n;

	if (cv_scarlet_singleplayer_bots_range <= 0)
		return TRUE;
	// SCARLET - walk the client slots, not the whole entity list with find()
	head = nextent(world);
	n = 0;
	while (n < max_clients)
	{
		if (head.ishuman && head.classname == "player" && head.health > 0)
			if (vlen(head.origin - org) < cv_scarlet_singleplayer_bots_range)
				return TRUE;
		head = nextent(head);
		n = n + 1;
	}
	return FALSE;
};

// teleports a bot next to a player, never onto them, so nobody gets telefragged or
// shoved. tries a ring of spots around the player and uses the first one with room.
// returns FALSE if none fit.
float(entity bot, entity to) bot_teleport_near =
{
	local entity oself;
	local vector org, spot, ang;
	local float i, dist, ok;

	oself = self;
	self = bot;
	org = bot.origin;
	i = 0;
	while (i < 16)
	{
		// two rings, near then far
		dist = 80;
		if (i >= 8)
			dist = 140;
		ang_y = i * 45 + random() * 20;
		ang_x = 0;
		ang_z = 0;
		makevectors(ang);
		spot = to.origin + v_forward * dist;
		traceline(to.origin, spot, TRUE, to);
		if (trace_fraction == 1 && pointcontents(spot) == CONTENT_EMPTY)
		{
			setorigin(bot, spot + '0 0 4');
			if (droptofloor(0, 0))
			{
				SUB_CallAsSelf(teleport_flash, bot);
				bot.velocity = VEC_ORIGIN;
				bot.flags = not(bot.flags, FL_ONGROUND);
				ok = TRUE;
				i = 99;
			}
		}
		i = i + 1;
	}
	if (!ok)
		setorigin(bot, org);
	self = oself;
	return ok;
};

// in coop and single player games a bot that has fallen far behind every human
// teleports to the nearest one, like the players' impulse 113 does for everyone
void() bot_regroup =
{
	local entity head, best;
	local float d, bestd;

	if (cv_scarlet_singleplayer_bots_regroup_distance <= 0 || time < self.regroup_time)
		return;
	self.regroup_time = time + 5;

	bestd = 99999;
	head = find(world, classname, "player");
	while (head)
	{
		if (head.ishuman && head.health > 0)
		{
			d = vlen(head.origin - self.origin);
			if (d < bestd)
			{
				bestd = d;
				best = head;
			}
		}
		head = find(head, classname, "player");
	}
	if (!best || bestd < cv_scarlet_singleplayer_bots_regroup_distance)
		return;
	if (fisible(best))
		return;
	SUB_CallAsSelf(teleport_flash, self);
	if (!bot_teleport_near(self, best))
		return;
	ClearMyRoute();
	self.target1_ent = self.target2_ent = self.target3_ent = self.target4_ent = world;
	self.last_way = world;
};

void() bot_devlog =
{
	local entity plat;
	if (!cv_scarlet_dev_botlog || self.dev_logtime > time)
		return;
	self.dev_logtime = time + 1;
	dprint("BOTLOG ");
	dprint(ftos(time));
	dprint(" ");
	dprint(self.netname);
	dprint(" ");
	dprint(vtos(self.origin));
	dprint(" goal ");
	dprint(self.target1_ent.classname);
	dprint(" ");
	dprint(vtos(self.target1_ent.origin));
	dprint(" health ");
	dprint(ftos(self.health));
	dprint(" cw ");
	dprint(ftos(self.current_way.count));
	dprint(" lw ");
	dprint(ftos(self.last_way.count));
	dprint(" aif ");
	dprint(ftos(self.b_aiflags));
	dprint(" rt ");
	dprint(ftos(route_table == self));
	dprint(" busy ");
	dprint(ftos(busy_waypoints));
	dprint(" fail ");
	dprint(ftos(self.route_failed));
	dprint(" enemy ");
	dprint(self.enemy.classname);
	dprint(" ground ");
	dprint(ftos((self.flags & FL_ONGROUND) != 0));
	dprint(" keys ");
	dprint(ftos(self.keys));
	dprint(" tgt1 ");
	dprint(self.target1_ent.classname);
	dprint(" ");
	dprint(vtos(self.target1_ent.origin));
	plat = FindThing("plat");
	if (plat && vlen((plat.absmin + plat.absmax) * 0.5 - self.origin) < 400)
	{
		dprint(" plat ");
		dprint(vtos((plat.absmin + plat.absmax) * 0.5));
		dprint(" top ");
		dprint(ftos(plat.absmax_z));
		dprint(" state ");
		dprint(ftos(plat.state));
	}
	dprint("\n");
};

void() BotAI =
{
	local entity stuck_goal;
	// am I dead? Fire randomly until I respawn
	// health < 1 is used because fractional healths show up as 0 on normal player
	// status bars, and the mod probably already compensated for that

	if (self.health < 1 && !intermission_running)
	{
		self.ai_time = time + 0.05;

		self.button0 = floor(random() * 2);
		self.button2 = 0;
		self.keys = 0;
		self.b_aiflags = 0;

		// only clear the route once. this runs every tick while the bot is dead (the
		// respawn delay can be long), and ClearMyRoute walks every waypoint on the map.
		if (self.last_way || self.target1_ent)
			ClearMyRoute();
		self.target1_ent = self.target2_ent = self.target3_ent = self.target4_ent = self.enemy = world;
		self.last_way = world;

		return;
	}

	// alive again, reset respawn timer
	self.respawn_time = 0;

	bot_devlog();

	// the item a bot is after sits behind the waypoint it is heading for.  if someone takes it
	// on the way, give the route up now instead of running all the way to an empty spot
	if ((self.target2_ent.flags & FL_ITEM) && self.target2_ent.model == string_null)
		bot_lost(self.target2_ent, FALSE);
	else if ((self.target3_ent.flags & FL_ITEM) && self.target3_ent.model == string_null)
		bot_lost(self.target3_ent, FALSE);
	else if ((self.target4_ent.flags & FL_ITEM) && self.target4_ent.model == string_null)
		bot_lost(self.target4_ent, FALSE);

	if (coop || !deathmatch)
		bot_regroup();

	// teleport logic bug solution -whipowill
	// a bot heading for a teleporter has the trigger or the waypoint inside it as its target.
	// bot_check_lost() only drops a target when the bot gets close, and a bot that just came out of
	// the other end is far away, so it would walk back through the portal to "reach" it (and then
	// do it again, or change its mind twice).  the moment a teleport happens the whole plan is
	// stale, so drop it and plan again from where the bot now stands.  the waypoint it used is
	// blacklisted for a few seconds by bot_lost().
	if (self.teleport_time > time && self.teleport_time != self.tele_seen)
	{
		self.tele_seen = self.teleport_time;
		if (cv_scarlet_dev_botlog)
		{
			dprint("BOTTELE ");
			dprint(ftos(time));
			dprint(" ");
			dprint(self.netname);
			dprint("\n");
		}
		if (self.target1_ent && self.target1_ent.classname != "player")
			bot_lost(self.target1_ent, FALSE);
	}
		
	// stagger the bot's AI out so they all don't think at the same time, causing game
	// 'spikes'
	if (self.target1_ent.classname != "player")
	{
		if (self.ai_time > time)
			return;

		self.ai_time = time + 0.05;
		if (bot_count > 0)
		{
			if ((time - stagger_think) < (0.1 / bot_count))
				self.ai_time = self.ai_time + 0.1 / (2 * bot_count);
		}
		else
			return;
	}

	stagger_think = time;

	// failsafe: if the bot is chasing a goal but hasn't gone anywhere in 2 seconds,
	// give up on it and pick a new one.  SCARLET - the goal itself (the last thing on its plan, the item
	// or the far waypoint, not just the next step) is banned for a minute for every bot, so nobody walks
	// into the same door again as soon as the short ban on a single waypoint runs out.
	if (self.target1_ent && self.target1_ent.classname != "player" && !(self.b_aiflags & AI_WAIT) && !intermission_running)
	{
		if (vlen(self.origin - self.stuck_org) > 16 || self.stuck_time == 0)
		{
			self.stuck_org = self.origin;
			self.stuck_time = time;
		}
		else if (time - self.stuck_time > 2)
		{
			if (cv_scarlet_dev_botlog)
			{
				dprint("BOTSTUCK ");
				dprint(self.netname);
				dprint(" ");
				dprint(self.target1_ent.classname);
				dprint(" goal ");
				dprint(self.target4_ent.classname);
				dprint(self.target3_ent.classname);
				dprint(self.target2_ent.classname);
				dprint("\n");
			}
			stuck_goal = self.target4_ent;
			if (!stuck_goal)
				stuck_goal = self.target3_ent;
			if (!stuck_goal)
				stuck_goal = self.target2_ent;
			if (!stuck_goal)
				stuck_goal = self.target1_ent;
			bot_lost(self.target1_ent, FALSE);
			// following a human in single player and co-op is not a goal to be banned: the bot gets pulled back
			// to its player when it falls behind
			if (stuck_goal != self.target1_ent && !(stuck_goal.classname == "player" && (coop || !deathmatch)))
			{
				bot_lost(stuck_goal, FALSE);
				ClearMyRoute();
				self.target1_ent = self.target2_ent = self.target3_ent = self.target4_ent = world;
				self.last_way = world;
			}
			if (stuck_goal.classname == "player")
			{
				if (!(coop || !deathmatch))
				{
					self.avoid_ent = stuck_goal;
					self.avoid_until = time + 60;
				}
			}
			else if (stuck_goal.search_time < time + 60)
				stuck_goal.search_time = time + 60;
			self.stuck_time = 0;
		}
	}
	else
		self.stuck_time = 0;

	// shut the bot's buttons off, various functions will turn them on by AI end

	self.button2 = 0;
	self.button0 = 0;
	
	// target1_ent is like goalentity in normal Quake monster AI.
	// it's the bot's most immediate target
	if (waypoint_mode == WM_UNINIT && max_clients > 1)
	{
		// no trail for this map, so the bot has no way to get around and no goals
		self.target1_ent = self.target2_ent = self.target3_ent = self.target4_ent = world;
		self.keys = 0;
	}
	else if (route_table == self)
	{
		if (busy_waypoints <= 0)
		{
			if (waypoint_mode < WM_EDITOR)
				bot_look_for_crap(TRUE);
		}
		self.b_aiflags = 0;
		self.keys = 0;
	}
	else if (self.target1_ent)
	{
		if (waypoint_mode < WM_EDITOR)
			bot_grab_vital();
		frik_movetogoal();
		bot_path();
	}
	else
	{
		if (waypoint_mode < WM_EDITOR)
                {
                	if(self.route_failed)
                	{
                		self.keys = 0;
                		self.route_failed = 0;
                	}
                        else if(!begin_route())
                        {	
                                bot_look_for_crap(FALSE);
                                self.keys = 0;
                        }
			
                }
		else
		{
			self.b_aiflags = AI_WAIT;
			self.keys = 0;
		}
	}

	// bot_angle_set points the bot at it's goal (self.enemy or target1_ent)

	bot_angle_set();

	// run from anyone holding the pentagram, step around anyone blocking the way
	bot_flee();
	if (!self.flee_ent)
	{
		bot_unblock();
		bot_squeeze();
	}

	// fight my enemy. Enemy is probably a field QC coders will most likely use a lot
	// for their own needs, since it's unused on a normal player
	// FIXME
	if (self.enemy)
		bot_fight_style();
	else if (random() < 0.2)
		if (random() < 0.2)
			bot_weapon_switch(-1);
	bot_dodge_stuff();

	// checks to see if bot needs to start going up for air
	if (self.waterlevel > 2)
  	{
		if (time > (self.air_finished - 2))
		{
			traceline (self.origin, self.origin + '0 0 6800', TRUE, self);
			if (trace_inopen)	
			{
				self.keys = KEY_MOVEUP;
				self.button2 = TRUE; // swim!
				return; // skip ai flags for now - this is life or death
			}
		}
    	}

	bot_handle_ai();

	// no trail for this map: whatever the fight or the dodging wanted, the bot stays where it is
	if (waypoint_mode == WM_UNINIT && max_clients > 1)
	{
		self.keys = self.keys & 960;
		self.button2 = 0;
	}

	// if deaths door
	if (self.health < 20 && self.target1_ent.classname != "player")
		bot_start_topic(4);

	// if victory
	if (self.b_frags != self.frags) // moved from bot.qc bc did not trigger reliably
	{
		if (self.b_frags > self.frags)
			bot_start_topic(8);
		else
			bot_start_topic(3);
		self.b_frags = self.frags;
		/*
		if (!self.ishuman) // if moving to bot_qw.qc then uncomment this
		{
			WriteByte(2, 14);
			WriteByte(2, self.b_clientno);
			WriteShort(2, self.frags);
		}
		*/
	}

	// if intermission
	if (self.view_ofs == '0 0 0')
		bot_start_topic(10);

	bot_chat();
};
