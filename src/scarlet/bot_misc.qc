/***********************************************
*                                              *
*              FrikBot Misc Code               *
*   "Because you can't name it anything else"  *
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

BotName

Sets bot's name and colors

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
string(float r) BotName =
{
	self.b_num = r;

	// set random params
	self.b_shirt = floor(random() * 14);
	self.b_pants = floor(random() * 14);

	return bot_names[floor(random() * bot_names.length)];
};
string () PickARandomName =
{
	if (bot_count > 16)
		return "player";

	local float y, test;
	local string h;
	local entity t;
	y = TRUE;
	while(y)
	{
		test = floor(random() * 16);
		h = BotName(test);
		t = find(world, netname, h);
		if (t == world)
			y = FALSE;
	}
	return h;
};

// I didn't like the old code so this is very stripped down

entity b_originator;
float b_topic;
float b_chattime_system;

// 1 - connect
// 2 - welcome
// 3 - victory
// 4 - deathsdoor
// 5 - death
// 6 - powerup
// 7 - team
// 8 - suicide
// 9 - ridicule
// 10 - intermission

void(float topic) bot_start_topic =
{
	if (!cvar("scarlet_dialogue")) return;

	local float odds;
	odds = 0.3;

	if (topic == 1) odds = 0.6; // connect
	if (topic == 2) odds = 0.6; // welcome
	if (topic == 8) odds = 0.6; // suicide
	if (topic == 9) odds = 0.6; // ridicule

	if (random() < odds)
	{
		b_topic = topic;
		b_originator = self;

		// trigger immediately, no need to wait
		bot_chat();
	}
	else
		b_topic = 0;
};

void() bot_chat =
{
	// if no chat allowed
	if (b_options & OPT_NOCHAT)
		return;

	if (b_chattime_system > time || self.b_chattime > time || b_topic < 1)
		return;
	if (self.b_chattime_alt > time && (b_topic == 4 || b_topic == 7)) // alt topics are spammy topics, deathsdoor and team
		return;

	// for random nums
	local float r;

	// the quote we will use
	local string quote;

	// if the quote is for teams only
	local float quote_is_to_team;

	// for setting the next topic
	local float next_topic = 0;

	// determine if bot is winning or losing
	local float is_winning = AmIWinning(self); // pass num of clients, needed for player rank

	// for testing easily
	local float is_testing = cvar("scarlet_testing");

	if (b_topic == 1) // connect
	{
		if (b_originator == self)
		{
			r = floor(random() * quotes_connect.length);
			quote = quotes_connect[r];
			if (is_testing) quote = "connect";
			next_topic = 2;
		}
	}
	else if (b_topic == 2) // welcome
	{
		if (b_originator != self)
		{
			r = floor(random() * quotes_welcome.length);
			quote = quotes_welcome[r];
			if (is_testing) quote = "welcome";
		}
	}
	else if (b_topic == 3) // victory
	{
		if (b_originator == self)
		{
			if (is_winning || is_testing)
			{
				r = floor(random() * quotes_victory.length);
				quote = quotes_victory[r];
				if (is_testing) quote = "victory";
			}
			else
			{
				// if losing don't gloat on victory
			}
		}
	}
	else if (b_topic == 4) // deaths door
	{
		if (b_originator == self)
		{
			quote_is_to_team = 1;
			if (!is_winning || is_testing)
			{
				r = floor(random() * quotes_deathsdoor.length);
				quote = quotes_deathsdoor[r];
				if (is_testing) quote = "deathsdoor";
			}
			else
			{
				// if winning do not comment on deathsdoor
			}
		}
	}
	else if (b_topic == 5) // death
	{
		if (b_originator == self)
		{
			if (!is_winning || is_testing)
			{
				r = floor(random() * quotes_death.length);
				quote = quotes_death[r];
				if (is_testing) quote = "death";
			}
			else
			{
				// if winning, do not comment on death
			}
		}
	}
	else if (b_topic == 6) // powerup
	{
		if (b_originator == self)
		{
			// this is handled individually in bot_ai.qc - whpowill
		}
	}
	else if (b_topic == 7) // team chatter
	{
		if (b_originator == self)
		{
			quote_is_to_team = 1;
			if (!is_winning || is_testing)
			{
				r = floor(random() * quotes_team.length);
				quote = quotes_team[r];
				if (is_testing) quote = "team";

			}
			else
			{
				// if winning, don't speak to team.
			}
		}
	}
	else if (b_topic == 8) // suicide
	{
		if (b_originator == self)
		{
			r = floor(random() * quotes_suicide.length);
			quote = quotes_suicide[r];
			if (is_testing) quote = "suicide";
			next_topic = 9;
		}
	}
	else if (b_topic == 9) // ridicule
	{
		if (b_originator != self)
		{
			r = floor(random() * quotes_ridicule.length);
			quote = quotes_ridicule[r];
			if (is_testing) quote = "ridicule";
			next_topic = 9;
		}
	}
	else if (b_topic == 9.5) // ridicule via telefrag
	{
		if (1) // let anyone make fun of it
		{
			r = floor(random() * quotes_ridicule.length);
			quote = quotes_ridicule[r];
			if (is_testing) quote = "ridicule";
			next_topic = 9;
		}
	}
	else if (b_topic == 10) // intermission
	{
		if (is_winning)
		{
			r = floor(random() * quotes_intermission_positive.length);
			quote = quotes_intermission_positive[r];
			if (is_testing) quote = "intermission_positive";
		}
		else
		{
			r = floor(random() * quotes_intermission_negative.length);
			quote = quotes_intermission_negative[r];
			if (is_testing) quote = "intermission_negative";
		}
		next_topic = 10;
	}

	// say the quote
	if (quote && quote != "")
	{
		quote = strcat(": ", quote);
		quote = strcat(quote, "\n");
		if (quote_is_to_team)
		{
			if (teamplay > 0)
				BotSayTeam(quote);
		}
		else
		{
			BotSay(quote);
		}

		// reset the chattime
		self.b_chattime = time + 2; // player cannot speak

		if (b_topic == 4 || b_topic == 7)
			self.b_chattime_alt = time + 60 + (random() * 60); // player cannot speak re: alternative topics (spammy topics)

		if (b_topic == 10)
			b_chattime_system = time + 2; // nobody can speak
		else
			b_chattime_system = time + 1; // nobody can speak
	}

	// set the next chat topic
	bot_start_topic(next_topic);
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Kick A Bot. 

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

void() KickABot =
{
	local entity ty;
	ty = find(world, classname, "player");
	while (ty != world)
	{
		if (!(ty.ishuman))
		{
			
			BotDisconnect(ty);
			ty.ishuman = TRUE;
			ty = world;
		}
		else
			ty = find(ty, classname, "player");
	}

};


/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Simplified origin checking. 

God, I wish I had inline

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

vector(entity ent) realorigin =
{
// even more simplified...
	return (ent.absmin + ent.absmax) * 0.5;
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

fisible

a version of visible that checks for corners
of the bounding boxes

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

float (entity targ) fisible =
{
	local vector	spot1, org;
	local float thruwater, pc1, pc2;
	
	org = realorigin(targ);
	spot1 = self.origin + self.view_ofs;
	
	if (targ.solid == SOLID_BSP)
	{
		traceline (spot1, org, TRUE, self);
		if (trace_ent == targ)
			return TRUE;
		else if (trace_fraction == 1)
			return TRUE;
		return FALSE;
	}
	else
	{
		pc1 = pointcontents(org);
		pc2 = pointcontents(spot1);
		if (targ.classname == "player")
			thruwater = FALSE;
		else if (pc1 == CONTENT_LAVA)
			return FALSE;
		else	
			thruwater = TRUE;
	}
	
	if (pc1 < -1) // targ's origin is in water or other liquid
	{
		if (pc2 != pc1)
		{
			// look for their head
			traceline (spot1, org + targ.mins, TRUE, self);
			// cross the water check
			if (trace_inopen)
				if (trace_inwater)
					if (!thruwater)
						return FALSE;
			if (trace_ent == targ)
				return TRUE;
			else if (trace_fraction == 1)
				return TRUE;
			return FALSE;
		}
	}
	else
	{
		if (pc2 != pc1)
		{
			traceline (spot1, org + targ.maxs, TRUE, self);
			if (trace_inopen)
				if (trace_inwater)
					if (!thruwater)
						return FALSE;
			if (trace_ent == targ)
				return TRUE;
			else if (trace_fraction == 1)
				return TRUE;
			return FALSE;
		}
	}
	traceline (spot1, org, TRUE, self);
	if (trace_ent == targ)
		return TRUE;
	else if (trace_fraction == 1)
		return TRUE;
	traceline (spot1, org + targ.maxs, TRUE, self);
	if (trace_ent == targ)
		return TRUE;
	else if (trace_fraction == 1)
		return TRUE;
	traceline (spot1, org + targ.mins, TRUE, self);
	if (trace_ent == targ)
		return TRUE;
	else if (trace_fraction == 1)
		return TRUE;
	return FALSE;
};


/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Wisible 

goes through movable brushes/entities, used
for waypoints

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

// this is used for waypoint stuff....
float (entity targ1, entity targ2) wisible =
{
	local vector	spot1, spot2;
	local entity ignore;

	spot1 = targ1.origin;
	spot2 = realorigin(targ2);
	
	ignore = self;
	do
	{
		traceline (spot1, spot2, TRUE, ignore);
		spot1 = realorigin(trace_ent);
                ignore = trace_ent;
	} while ((trace_ent != world) && (trace_fraction != 1));
	if (trace_endpos == spot2)
		return TRUE;
	else 
		return FALSE;
};


/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

sisible

Now this is getting ridiculous. Simple visible,
used when we need just a simple traceline nothing else

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

float (entity targ) sisible =
{
	traceline (self.origin, targ.origin, TRUE, self);
	if (trace_ent == targ)
		return TRUE;
	else if (trace_fraction == 1)
		return TRUE;
	else
		return FALSE;
};
/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

angcomp

subtracts one angle from another

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

float (float y1, float y2) angcomp = 
{
	y1 = frik_anglemod(y1);
	y2 = frik_anglemod(y2);

	local float answer;
	answer = y1 - y2;
	if (answer > 180)
		answer = answer - 360;
	else if (answer < -180)
		answer = answer + 360;
	return answer;
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

fov

is the entity in the bot's field of view

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
float (entity targ) fov =
{
	local vector yawn;
	local float g;
	yawn = realorigin(targ);
	yawn = (yawn + targ.view_ofs) - (self.origin + self.view_ofs);
	yawn = normalize(yawn);
	yawn = vectoangles(yawn);
	g = angcomp(self.v_angle_x, yawn_x);
	if (fabs(g) > 45)
		return FALSE;
	g = angcomp(self.v_angle_y, yawn_y);
	if (fabs(g) > 60)
		return FALSE;
 
	return TRUE;
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

frik_anglemod

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
float(float v) frik_anglemod =
{
	return v - floor(v/360) * 360;
};