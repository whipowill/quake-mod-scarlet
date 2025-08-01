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
	self.search_time = time + searchtime_giveup;
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
	self.search_time = time + searchtime_giveup;
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

bot_lost

Bot has lost its target.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

void(entity targ, float success) bot_lost =
{
	if (!targ)
		return;

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
		if (targ.classname == "item_artifact_invisibility")
			if (self.items & IT_INVISIBILITY)
				BotSayTeam(": friendly eyes\n");
		if (targ.classname == "item_armor1")
			if (self.items & IT_ARMOR1)
				//BotSayTeam(": @ green armor\n");
		if (targ.classname == "item_armor2")
			if (self.items & IT_ARMOR2)
				BotSayTeam(": @ yellow armor\n");
		if (targ.classname == "item_armorInv")
			if (self.items & IT_ARMOR3)
				BotSayTeam(": @ red armor\n");
		if (targ.classname == "item_artifact_invulnerability")
			if (self.items & IT_INVULNERABILITY)
				BotSayTeam(": @ pent\n");
		if (targ.classname == "item_artifact_super_damage")
			if (self.items & IT_QUAD)
				BotSayTeam(": @ quad\n");
		if (targ.classname == "item_artifact_envirosuit")
			if (self.items & IT_SUIT)
				BotSayTeam(": @ suit\n");
		if (targ.classname == "item_health")
			if (self.health == 200)
				//BotSayTeam(": @ megahealth\n"); // too unreliable to detect
		if (targ.classname == "weapon_rocketlauncher")
			if (self.items & IT_ROCKET_LAUNCHER)
				//BotSayTeam(": @ rocket\n");

                if (targ.flags & FL_ITEM)
                {
                        if (targ.model == string_null)
                                targ._last = world;
                        else
                                targ._last = self;
                }
        }


	if (targ.classname != "player")
		targ.search_time = time + 5;
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

bot_check_lost

decide if my most immediate target should be
removed.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
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
		else if ((coop) || (teamplay && targ.team == self.team))
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
			else if (vlen(targ.origin - self.origin) < 128)
			{
				if (vlen(targ.origin - self.origin) < 48)
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
		bot_lost(targ, FALSE);
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
			thisp = cvar("scarlet_priority_quad"); // was 55 -whipowill
		else if (thing.classname == "item_artifact_invulnerability")
			thisp = cvar("scarlet_priority_pent"); // was 55 -whipowill
		else if (thing.classname == "item_artifact_invisibility")
			thisp = cvar("scarlet_priority_ring"); // was 55 -whipowill
		else if (thing.model == "progs/m_h100.mdl" || thing.model == "progs/items/quoth/cross.mdl")
			thisp = cvar("scarlet_priority_mega"); // megahealth wasn't even in here as being special -whipowill


		else if (thing.classname == "item_health")
		{
			if (thing.spawnflags & 2)
				thisp = 10*(random()) + 50;
			if (self.health <= 50)
				thisp = 70;
		}
		else if (thing.model == "progs/items/mervup_75.mdl") // adding shards/stims/pots -whipowill
		{
			thisp = cvar("scarlet_priority_pots");
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
			else
			{
				if (thing.items & IT_INVISIBILITY) //FIXME
					thisp = 2;
				else if (coop)
				{
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

void(float scope) bot_look_for_crap =
{
	local entity foe, best;
	local float thatp, bestp, dist;

	if (scope == 1)
		foe = findradius(self.origin, 13000);
	else
		foe = findradius(self.origin, 500);

	bestp = 1;
	while(foe)
	{
		thatp = priority_for_thing(foe);
		if (thatp)
			if (!scope)
				if (!sisible(foe))
					thatp = 0;
		if (thatp > bestp)
		{
			bestp = thatp;
			best = foe;
			dist = vlen(self.origin - foe.origin);
		}
		foe = foe.chain;
	}
	if (best == world)
		return;
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
	local float h;
	local vector view;
	
	if (self.enemy)
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
			
			levels = 3;
			
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
	}
	else if (self.target1_ent)
	{
		view = realorigin(self.target1_ent);
		if (self.target1_ent.flags & FL_ITEM)
				view = view + '0 0 48';
		view = view - (self.origin + self.view_ofs);
		view = vectoangles(view);
		view_x = view_x * -1;
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

void() BotAI =
{
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
		ClearMyRoute();
		self.target1_ent = self.target2_ent = self.target3_ent = self.target4_ent = self.enemy = world;
		self.last_way = world;

		return;
	}

	// alive again, reset respawn timer
	self.respawn_time = 0;

	// part of teleport logic bug solution -whipowill
	if (self.target1_ent.classname == "trigger_teleport")
		if (self.teleport_time > time)
			bot_lost(self.target1_ent, TRUE);

	// description of the problem:  as the bot cycles thru pulses, it ends every pulse
	// with a target (self.target1_ent) and a waypoint (self.last_way).  target is the immediate
	// place it's heading and waypoint is the ultimate place it's heading.

	// when the bot determines it needs to use a teleporter it adds it as a target but not a
	// waypoint.  what happens is when the bot goes thru the teleporter, it still has the teleporter
	// as the target and so it wants to go back thru it to get to it.

	// the issue is how to remove the teleporter as a target after the bot has gone thru.
	// normally this would be done in the function bot_check_lost(), which in the case of waypoints
	// and items removes the target when the bots gets really close to it.

	// but for some reason proximity calculation doesn't work w/ teleporters, i don't know why.
	// moreover, bot_check_lost() is run AFTER movetotarget(), so target removal there is too late.
	// my solution is to bypass bot_check_lost() and run this detection immediately upon teleportation.

	// end. -whipowill
		
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

	// shut the bot's buttons off, various functions will turn them on by AI end

	self.button2 = 0;
	self.button0 = 0;
	
	// target1_ent is like goalentity in normal Quake monster AI.
	// it's the bot's most immediate target
	if (route_table == self)
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
		frik_movetogoal();
		bot_path();
	}
	else
	{
		if (waypoint_mode < WM_EDITOR)
                {
                	if(self.route_failed)
                	{
                		if (waypoint_mode == WM_DYNAMIC)
                	        	frik_bot_roam();
                	        else
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
