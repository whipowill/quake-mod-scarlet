
/*
======================================
FrikBot X (Version 0.10.2)
======================================

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

======================================
These installation instructions only apply to Normal Quake (as does this
entire file). For QuakeWorld, please refer to bot_qw.qc

--------------------------------------
To install on a new mod, do all this:
--------------------------------------
Place all included bot*.qc files in the subdirectory "frikbot"
in your source folder, then...

* Add the following lines to progs.src right after the defs.qc line
frikbot/bot.qc
frikbot/bot_way.qc
frikbot/bot_fight.qc 
frikbot/bot_ai.qc
frikbot/bot_misc.qc
frikbot/bot_phys.qc
frikbot/bot_move.qc
frikbot/bot_ed.qc

--------------------------------------
* Comment out the following functions in defs.qc
sound, stuffcmd, sprint, aim, centerprint, setspawnparms
WriteByte, WriteChar, WriteShort, WriteLong, WriteCoord
WriteAngle, WriteString, WriteEntity
--------------------------------------
* Add this to worldspawn() in world.qc, right at the very top, before InitBodyQue();
BotInit();  // FrikBot
--------------------------------------
* Add this line to StartFrame() in world.qc, at the very top
BotFrame(); // FrikBot
--------------------------------------
* Add these two lines to PlayerPreThink in client.qc at the very top
if (BotPreFrame()) // FrikBot
	return;
--------------------------------------
* Add this line to PlayerPostThink in client.qc at the very top
if (BotPostFrame()) // FrikBot
	return;
--------------------------------------
* Add the following line to the very top of Client Connect in client.qc
ClientInRankings(); // FrikBot
--------------------------------------
* Add these lines to the very top of ClientDisconnect in client.qc
ClientDisconnected(); // FrikBot
--------------------------------------

To install the waypoints:

add

waypoints/map_dm1.qc
waypoints/map_dm2.qc
waypoints/map_dm3.qc
waypoints/map_dm4.qc
waypoints/map_dm5.qc
waypoints/map_dm6.qc

To progs.src, immediately after defs.qc

To remove these waypoints:

Delete the code in bot_map_load, located below.
*/

void() bot_map_load =
{
	// place your qc loaded waypoints here

	if (mapname == "dm1")
		map_dm1();
	else if (mapname == "dm2")
		map_dm2();
	else if (mapname == "dm3")
		map_dm3();
	else if (mapname == "dm4")
		map_dm4();
	else if (mapname == "dm5")
		map_dm5();
	//else if (mapname == "dm6")
		//map_dm6(); // use wayfile instead
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Variables and shtuff

bot.qc has become pretty much a header file
for all variables in the bot...

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

// ----- entity fields ---
.float wallhug, keys, oldkeys, ishuman;
.float b_frags, b_clientno, b_shirt, b_pants;
.float priority, ai_time, b_sound, missile_speed;
.float portal_time, b_skill, switch_wallhug;
.float b_aiflags, b_num, b_chattime, b_chattime_alt;
.float b_menu, b_menu_time, b_menu_value;
.float route_failed, dyn_flags, dyn_time;
.float dyn_plat;
.entity temp_way, last_way, phys_obj;
.entity target1_ent, target2_ent, target3_ent, target4_ent;
.entity _next, _last;
.entity current_way;
.vector b_angle, b_dest, mouse_emu, obs_dir;
.vector movevect, b_dir;
.vector dyn_dest;

// --------defines-----
float SVC_UPDATENAME = 13;
float SVC_UPDATEFRAGS = 14;
float SVC_UPDATECOLORS = 17;

// used for the physics & movement AI
float KEY_MOVEUP = 1;
float KEY_MOVEDOWN = 2;
float KEY_MOVELEFT = 4;
float KEY_MOVERIGHT = 8;
float KEY_MOVEFORWARD = 16;
float KEY_MOVEBACK = 32;
float KEY_LOOKUP = 64;
float KEY_LOOKDOWN = 128;
float KEY_LOOKLEFT = 256;
float KEY_LOOKRIGHT = 512;

// these are aiflags for waypoints
// some overlap to the bot
float AI_TELELINK_1 = 1; // link type
float AI_TELELINK_2 = 2; // link type
float AI_TELELINK_3 = 4; // link type
float AI_TELELINK_4 = 8; // link type
float AI_DOORFLAG = 16; // read ahead
float AI_PRECISION = 32; // read ahead + point
float AI_SURFACE = 64; // point
float AI_BLIND = 128; // read ahead + point
float AI_JUMP = 256; // point + ignore
float AI_DIRECTIONAL = 512; // read ahead + ignore
float AI_PLAT_BOTTOM = 1024; // read ahead
float AI_RIDE_TRAIN = 2048; // read ahead
float AI_SUPER_JUMP = 4096; // point + ignore + route test
float AI_SNIPER = 8192; // point type
float AI_AMBUSH = 16384; // point type
float AI_DOOR_NO_OPEN = 32768; // read ahead
float AI_DIFFICULT = 65536; // route test
float AI_TRACE_TEST = 131072; // route test

// these are flags for bots/players (dynamic/editor flags)
float AI_OBSTRUCTED	= 1;
float AI_HOLD_SELECT = 2;
float AI_ROUTE_FAILED = 2;
float AI_WAIT = 4;
float AI_DANGER = 8;


// addition masks
float AI_POINT_TYPES = 29152;
float AI_READAHEAD_TYPES = 36528;
float AI_IGNORE_TYPES = 4864;

float WM_UNINIT = 0;
float WM_DYNAMIC = 1;
float WM_LOADING = 2;
float WM_LOADED = 3;
float WM_EDITOR = 4;
float WM_EDITOR_DYNAMIC	= 5;
float WM_EDITOR_DYNLINK	= 6;


float OPT_SAVEBOTS = 1;
float OPT_NOCHAT = 2;

// -------globals-----
float active_clients;
float max_clients, real_frametime;
float bot_count, b_options, bot_team0_count, bot_team1_count;
float waypoint_mode, dump_mode;
float waypoints, direct_route;
float sv_friction, sv_gravity;
float sv_accelerate, sv_maxspeed, sv_stopspeed;
entity fixer;
entity route_table;
entity b_temp1, b_temp2, b_temp3;
entity player_head, phys_head, way_head;
float busy_waypoints;
float saved_bots, saved_skills1, saved_skills2, current_bots;
float searchtime_giveup = 2; // for tweaking how long it takes to give up -whipowill

// -------ProtoTypes------
// external
void() ClientConnect;
void() ClientDisconnect;
void() SetNewParms;

// rankings
float(float clientno) ClientBitFlag;
float() ClientNextAvailable;
void(float whichteam, float whatbot, float whatskill) BotConnect;
void(entity bot) BotDisconnect;
void(float clientno) BotInvalidClientNo;
void(entity who) UpdateClient;

// waypointing
void() DynamicWaypoint;
entity(vector org) make_waypoint;
void() ClearAllWays;
void() FixWaypoints;
float() begin_route;
void(entity this, float direct) bot_get_path;
void() WaypointThink;
entity(entity start) FindWayPoint;

// physics & movement
float(entity e) bot_can_rj;
void() bot_jump;
void() frik_bot_roam;
float(vector weird) frik_walkmove;
void() frik_movetogoal;
void() frik_obstacles;
float(float flag) frik_recognize_plat;
float(vector sdir) frik_KeysForDir;
void(vector whichway, float danger) frik_obstructed;
void() SV_Physics_Client;
void() SV_ClientThink;
void() CL_KeyMove;

// ai & misc
string() PickARandomName;
float(entity targ) fov;
float(float y1, float y2) angcomp;
float(entity targ1, entity targ2) wisible;
float(entity targ) sisible;
float(entity targ) fisible;
vector(entity ent) realorigin;
void(entity ent) target_ent_drop;
void(entity ent) target_ent_add;
void() KickABot;
void() BotImpulses;
void(entity targ, float success) bot_lost;
string(float r) BotName;
float(float v) frik_anglemod;
void() bot_chat;
void(float topic) bot_start_topic;

// editor stuffs

void()				bot_way_edit;
void()				bot_menu_display;


// ----------Commands---------
void(entity e, float chan, string samp, float vol, float atten) frik_sound = #8;
void(entity client, string s)	frik_stuffcmd = #21;
void(entity client, string s)	frik_sprint = #24;
vector(entity e, float sped)	frik_aim = #44;	
void(entity client, string s)	frik_centerprint = #73;
void(entity e)			frik_setspawnparms = #78;
void(float to, float f)		frik_WriteByte = #52;
void(float to, float f)		frik_WriteChar = #53;
void(float to, float f)		frik_WriteShort = #54;
void(float to, float f)		frik_WriteLong = #55;
void(float to, float f)		frik_WriteCoord = #56;
void(float to, float f)		frik_WriteAngle = #57;
void(float to, string s)	frik_WriteString	= #58;
void(float to, entity s)	frik_WriteEntity	= #59;

void(entity client, string s1, string s2, string s3, string s4, string s5, string s6, string s7)
frik_big_centerprint = #73;

//----------------------------------------------------------------------------

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Function redclarations. These allow function 
designed to work for clients (sprint, so forth)
to mainly not complain when working with a bot

Although these shouldn't be needed anymore,
as the bots truly are clients now, if you don't
stop the SZ_ buffer from filling up by disabling
direct messages to the bots, it crashes quake :-(

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

void(entity	client, string s) stuffcmd =
{
	if (client.ishuman == 1)
		frik_stuffcmd(client, s);
	b_temp1 = player_head;

	while(b_temp1)
	{
		if (b_temp1.classname == "botcam")
		{
			if ((b_temp1.enemy == client) && b_temp1.ishuman)
				frik_stuffcmd(b_temp1, s);
		}
		b_temp1 = b_temp1._next;
	}
};

void(entity	e) setspawnparms =
{
	if (e.ishuman == 1)
		frik_setspawnparms(e);
	else
	{
		b_temp1 = player_head;
		while(b_temp1)
		{
			if (b_temp1.ishuman)
			{
				frik_setspawnparms(b_temp1);
				return;
			}
			b_temp1 = b_temp1._next;
		}
		SetNewParms();
	}
};

void(entity	client, string s) sprint =
{
	if (client.ishuman == 1)
		frik_sprint(client, s);
	b_temp1 = player_head;

	while(b_temp1)
	{
		if (b_temp1.classname == "botcam")
		{
			if ((b_temp1.enemy == client) && b_temp1.ishuman)
				frik_sprint(b_temp1, s);
		}
		b_temp1 = b_temp1._next;
	}
};

void(entity	client, string s) centerprint =
{
	if (client.ishuman == 1)
		frik_centerprint(client, s);
	b_temp1 = player_head;

	while(b_temp1)
	{
		if (b_temp1.classname == "botcam")
		{
			if ((b_temp1.enemy == client) && b_temp1.ishuman)
				frik_centerprint(b_temp1, s);
		}
		b_temp1 = b_temp1._next;
	}
};

vector(entity e, float sped) aim =
{
	e.missile_speed = sped;
	return frik_aim(e, sped);
};

void(entity e, float chan, string samp, float vol, float atten) sound = 
{
	frik_sound(e, chan, samp, vol, atten);
	if (samp == "items/inv3.wav")
		return;
	else if (e.classname == "player")
		e.b_sound = time + 1;
	else if (other.classname == "player")
		other.b_sound = time + 1;
};

void(float to, float f) WriteByte =
{
	if ((to == MSG_ONE) && (msg_entity.ishuman != TRUE))
		return;
	frik_WriteByte(to, f);
};

void(float to, float f) WriteChar =		
{
	if ((to == MSG_ONE) && (msg_entity.ishuman != TRUE))
		return;
	frik_WriteChar(to, f);
};

void(float to, float f) WriteShort =	
{
	if ((to == MSG_ONE) && (msg_entity.ishuman != TRUE))
		return;
	frik_WriteShort(to, f);
};

void(float to, float f) WriteLong = 
{
	if ((to == MSG_ONE) && (msg_entity.ishuman != TRUE))
		return;
	frik_WriteLong(to, f);
};

void(float to, float f) WriteCoord = 
{
	if ((to == MSG_ONE) && (msg_entity.ishuman != TRUE))
		return;
	frik_WriteCoord(to, f);
};

void(float to, float f) WriteAngle = 
{
	if ((to == MSG_ONE) && (msg_entity.ishuman != TRUE))
		return;
	frik_WriteAngle(to, f);
};

void(float to, string s) WriteString = 
{
	if ((to == MSG_ONE) && (msg_entity.ishuman != TRUE))
		return;
	frik_WriteString(to, s);
};

void(float to, entity s) WriteEntity = 
{
	if ((to == MSG_ONE) && (msg_entity.ishuman != TRUE))
		return;
	frik_WriteEntity(to, s);
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Bot Cam, see what the bot sees (or any other player)

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

float() botcam =
{
	if (self.classname != "botcam")
		return FALSE;
	setorigin(self, self.enemy.origin);
	self.items = self.enemy.items;
	self.weapon = self.enemy.weapon;
	self.weaponmodel = self.enemy.weaponmodel;
	self.currentammo = self.enemy.currentammo;
	self.weaponframe = self.enemy.weaponframe;
	self.ammo_shells = self.enemy.ammo_shells;
	self.ammo_nails = self.enemy.ammo_nails;
	self.ammo_rockets= self.enemy.ammo_rockets;
	self.ammo_cells = self.enemy.ammo_cells;
	self.view_ofs = self.enemy.view_ofs;
	self.health = self.enemy.health;
	self.armorvalue = self.enemy.armorvalue;
	self.dmg_take = self.enemy.dmg_take;
	self.dmg_save = self.enemy.dmg_save;
	self.dmg_inflictor = self.enemy.dmg_inflictor;
	self.punchangle = self.enemy.punchangle;
	self.deadflag = self.enemy.deadflag;
	msg_entity = self;
	WriteByte (MSG_ONE,5);
	WriteEntity (MSG_ONE, self.enemy); 
	WriteByte (MSG_ONE, 10);
     	WriteAngle (MSG_ONE,self.enemy.v_angle_x);
     	WriteAngle (MSG_ONE,self.enemy.v_angle_y);
     	WriteAngle (MSG_ONE,self.enemy.v_angle_z);
	self.modelindex = 0;
	
	self.impulse = 0;	
	return TRUE;	
};

void() botcam_u = 
{
	// sloppy cycling code
	if (self.classname != "botcam")
	{
		self.enemy = player_head;
	}
	else
	{
		do
			self.enemy = self.enemy._next;
		while (self.enemy.classname == "botcam");
	}
	if (self.enemy == self)
	{
		do
			self.enemy = self.enemy._next;
		while (self.enemy.classname == "botcam");
	}
	self.classname = "botcam";
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.takedamage = DAMAGE_NO;

	if (!self.enemy)
	{
		sprint(self, "No one left to track!\n");
		msg_entity = self;
		WriteByte (MSG_ONE,5);
		WriteEntity (MSG_ONE, self);
		PutClientInServer();
		return;
	}
	if (!self.enemy.ishuman)
	{
		self.enemy.dmg_take = 0;
		self.enemy.dmg_save = 0;
	}
	sprint(self, "Now tracking ");
	sprint(self, self.enemy.netname);
	sprint(self, "\n");
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Stuff mentioned up top
it just links the bot into the mod

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

void() ClientFixRankings =
{
	local float cno;

	if (self.switch_wallhug > time)
		return;
	self.switch_wallhug = 0;

	b_temp2 = nextent(world);
	cno = 0;

	while (cno < max_clients)
	{
		if ((!b_temp2.ishuman) && (active_clients & ClientBitFlag(cno)))
			UpdateClient(b_temp2);
		cno = cno + 1;
		b_temp2 = nextent(b_temp2);
	}
};

void() ClientInRankings =
{
	local float cno;

   	cno = self.colormap - 1;
	BotInvalidClientNo (cno);

	if (player_head)
		player_head._last = self;

	self._next = player_head;
	self._last = world;
	player_head = self;

	if (!self.phys_obj)
	{
		b_temp2 = phys_head;
		while (b_temp2 != world && b_temp2.owner != self)
			b_temp2 = b_temp2._next;
		self.phys_obj = b_temp2;
	}

	if (self.ishuman == 2)
	{
		self.ishuman = FALSE;
		return;
	}
	active_clients = active_clients | ClientBitFlag(cno);

	self.b_clientno = cno;
	self.ishuman = TRUE;
	self.switch_wallhug = time + 1;
};

void() ClientDisconnected =
{
	// remove from scorekeeper
	ScoreKeeperRemovePlayer(self); // whipowill

	if (player_head == self)
		player_head = self._next;
	if (self._next)
		self._next._last = self._last;
	if (self._last)
		self._last._next = self._next;

	active_clients = active_clients - active_clients & ClientBitFlag(self.b_clientno);
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

BotPreFrame & BotPostFrame, used to make the
bot easier to install

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

float () BotPreFrame =
{
	if (self.b_clientno == -1)
		return TRUE;
	if (self.ishuman)
	{
		if (self.switch_wallhug)
			ClientFixRankings();
		if (self.classname == "botcam")
			return TRUE;
	}
	DynamicWaypoint();
	return FALSE;
};

float () BotPostFrame =
{
	if (self.b_clientno == -1)
		return TRUE;
	if (self.ishuman)
	{
		if (waypoint_mode > WM_LOADED)
			bot_menu_display();

		BotImpulses();

		if (botcam())
			return TRUE;
	}
	return FALSE;
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Bot Chat code

The rest of this code is in bot_misc.qc

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

void(string h) BotSay = // simulate talking by composing a 'chat' message
{
	WriteByte(MSG_ALL, 8);
	WriteByte(MSG_ALL, 1);
	WriteString(MSG_ALL, self.netname);
	WriteByte(MSG_ALL, 8);
	WriteByte(MSG_ALL, 2);
	WriteString(MSG_ALL, h);
};

void() BotSayInit =
{
	WriteByte(MSG_ALL, 8);
	WriteByte(MSG_ALL, 1);
	WriteString(MSG_ALL, self.netname);
};

void(string h) BotSay2 =
{
	WriteByte(MSG_ALL, 8);
	WriteByte(MSG_ALL, 2);
	WriteString(MSG_ALL, h);
};

void(string h) BotSayTeam = 
{
	local entity t;
	if (!teamplay)
		return;
	t = player_head;
	while(t)
	{
		if (t.team == self.team)
		{
			msg_entity = t;
			WriteByte(MSG_ONE, 8);
			WriteByte(MSG_ONE, 1);
			WriteByte(MSG_ONE, 40);
			WriteString(MSG_ONE, self.netname);
			WriteByte(MSG_ONE, 8);
			WriteByte(MSG_ONE, 2);
			WriteByte(MSG_ONE, 41);
			WriteString(MSG_ONE, h);
		}
		t = t._next;
	}
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

BotInit

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

void() BotInit =
{
	local entity ent, fisent;
	local float numents;
	
	// spawn entities for the physics
	ent = nextent(world);
	max_clients = 0;

	while(ent != world)
	{
		max_clients = max_clients + 1;
		ent = nextent(ent);
	}
	if (max_clients > 16)
		max_clients = 16;

	ent = nextent(world);
	fisent = world;
	while (numents < max_clients)
	{

		phys_head = spawn();
		if (fisent)
			fisent._next = phys_head;
		phys_head._last = fisent;
		fisent = phys_head;
		ent.phys_obj = phys_head;
		phys_head.classname = "phys_obj";
		phys_head.owner = ent;
		numents = numents + 1;
		ent = nextent(ent);
	}
	precache_model("progs/s_light.spr");
	precache_model("progs/s_bubble.spr");
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Rankings 'utilities'. Written by Alan Kivlin,
this code just fools clients by sending precisely
the same network messages as when a real player
signs on to the server.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

void(entity who) UpdateClient =
{
	WriteByte (MSG_ALL, SVC_UPDATENAME);
	WriteByte (MSG_ALL, who.b_clientno);
	WriteString (MSG_ALL, who.netname);
	WriteByte (MSG_ALL, SVC_UPDATECOLORS);
	WriteByte (MSG_ALL, who.b_clientno);
	WriteByte (MSG_ALL, who.b_shirt * 16 + who.b_pants);
	WriteByte (MSG_ALL, SVC_UPDATEFRAGS);
	WriteByte (MSG_ALL, who.b_clientno);
	WriteShort (MSG_ALL, who.frags);
};

float(float clientno) ClientBitFlag =
{
	// bigger, but faster
	if (clientno == 0)
		return 1;
	else if (clientno == 1)
		return 2;
	else if (clientno == 2)
		return 4;
	else if (clientno == 3)
		return 8;
	else if (clientno == 4)
		return 16;
	else if (clientno == 5)
		return 32;
	else if (clientno == 6)
		return 64;
	else if (clientno == 7)
		return 128;
	else if (clientno == 8)
		return 256;
	else if (clientno == 9)
		return 512;
	else if (clientno == 10)
		return 1024;
	else if (clientno == 11)
		return 2048;
	else if (clientno == 12)
		return 4096;
	else if (clientno == 13)
		return 8192;
	else if (clientno == 14)
		return 16384;
	else if (clientno == 15)
		return 32768;
	return 0;
};

float() ClientNextAvailable =
{
	local float clientno;

	clientno = max_clients;
	while(clientno > 0)
	{
		clientno = clientno - 1;

		if(!(active_clients & ClientBitFlag(clientno)))
			return clientno;
	}

	return -1;
};


void(entity e1, entity e2, float flag) DeveloperLightning =
{
	// used to show waypoint links for debugging
	WriteByte (MSG_BROADCAST, 23);
	if (flag)
		WriteByte (MSG_BROADCAST, 6);
	else
		WriteByte (MSG_BROADCAST, 13);
	WriteEntity (MSG_BROADCAST, e2);
	WriteCoord (MSG_BROADCAST, e1.origin_x);
	WriteCoord (MSG_BROADCAST, e1.origin_y);
	WriteCoord (MSG_BROADCAST, e1.origin_z);
	WriteCoord (MSG_BROADCAST, e2.origin_x);
	WriteCoord (MSG_BROADCAST, e2.origin_y);
	WriteCoord (MSG_BROADCAST, e2.origin_z); 
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Find Another Color

Team finding code

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

float(float tcolor) FindAnotherColor =
{
	local float bestbet, scolor, pcount, bestp;
	bestbet = -1;
	bestp = 16;
	while(scolor < 14)
	{
		if (scolor != tcolor)
		{
			b_temp2 = player_head;
			pcount = 0;
			while(b_temp2 != world)
			{
				if (b_temp2.team == scolor + 1)
					pcount = pcount + 1;
				b_temp2 = b_temp2._next;
			}
			if ((pcount < bestp) && pcount)
			{
				bestbet = scolor;
				bestp = pcount;
			}
		}
		scolor = scolor + 1;
	}
	if (bestbet < 0)
	{
		bestbet = tcolor;
		while (bestbet == tcolor)
		{
			bestbet = floor(random() * 14);
		}
	}
	return bestbet;
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

BotConnect and related functions.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/				
entity(float num) GetClientEntity =
{
	local entity upsy;
	upsy = world;
	num = num + 1;
	while (num > 0)
	{
		num = num - 1;
		upsy = nextent(upsy);
	} 
	return upsy;
};

void(float whichteam, float whatbot, float whatskill) BotConnect =
{
	local float f;
	local string h;
	local entity uself;
	
	f = ClientNextAvailable();
	uself = self;
	if(f == -1)
	{
		bprint("Unable to connect a bot, server is full.\n");
		return;
	}
	
	// chat thing

	bot_count = bot_count + 1;
	if (whichteam == 0) bot_team0_count = bot_team0_count + 1;
	if (whichteam == 1) bot_team1_count = bot_team1_count + 1;

	self = GetClientEntity(f);
	self.b_clientno = f;
	self.colormap = f + 1;
	if (whatbot)
		self.netname = BotName(whatbot);
	else
		self.netname = PickARandomName();

	// players can set skill all weird, so leave these checks in
	whatskill = rint(whatskill);
	if (whatskill > 3)
		whatskill = 3;
	else if (whatskill < 0)
		whatskill = 0;
	self.b_skill = whatskill;

	// for debugging -whipowill
	dprint("Adding bot of skill ");
	dprint(ftos(self.b_skill));
	dprint(" to the game.\n");

	bot_start_topic(1); // welcome msg
	self.b_chattime_alt = time + 30 + (random() * 30); // for making sure they don't spam team msgs right away. -whipowill

	if (teamplay) // choose same team on coop! -whipowill
	{
		if (whichteam)
			self.b_pants = FindAnotherColor(uself.team - 1);
		else
			self.b_pants = uself.team - 1;

		// default team shirt to match pants
		self.b_shirt = self.b_pants;

		// if let bots pick unique tops...
		if (!cvar("scarlet_bots_team_jersey"))
		{
			// 0 = Titanium White - neutral
			// 1 = Van Dyke Brown - neutral
			// 2 = Mountain Mixture - pastel
			// 3 = Sap Green - neutral
			// 4 = Alizarin Crimson - red
			// 5 = Yellow Ochre - neutral
			// 6 = Cadmium Orange - pastel
			// 7 = Flower Pink - pastel
			// 8 = Magenta Mauve - pastel
			// 9 = Dusty Rose - pastel
			// 10 = Dark Sienna - neutral
			// 11 = Phthalo Green - blue
			// 12 = Indian Yellow - red
			// 13 = Prussian Blue - blue

			// code for unique top color on teams

			float is_pastel, is_neutral, is_other;

			float top_color;

			// determine category for pants
		    if (self.b_pants == 2
		    	|| self.b_pants == 6
		    	|| self.b_pants == 7
		    	|| self.b_pants == 8
		    	|| self.b_pants == 9
		    )
		    {
		    	is_pastel = 1;
		    }

		    if (self.b_pants == 0
		    	|| self.b_pants == 1
		    	|| self.b_pants == 3
		    	|| self.b_pants == 5
		    	|| self.b_pants == 10
		    )
		    {
		    	is_neutral = 1;
		    }

		    if (!is_pastel && !is_neutral) is_other = 1;

	    	while (!top_color)
	    	{
	    		for (float i = 0; i < 14; i++)
	    		{
	    			// if pants are bright and top is also pastel
	    			if (is_pastel && ((i == 0
				    	|| i == 2
				    	|| i == 6
				    	|| i == 7
				    	|| i == 8
				    	|| i == 9
				    )))
				    {
				    	if (!top_color && random() <= .05) top_color = i;
				    }

				    // if pants are neutral and top is neutral or other
	    			if (is_neutral && ((i == 0
	    				// neutral
				    	|| i == 1
				    	|| i == 3
				    	|| i == 5
				    	|| i == 10
				    	// other
				    	|| i == 4
				    	|| i == 11
				    	|| i == 12
				    	|| i == 13
				    )))
				    {
				    	if (!top_color && random() <= .05) top_color = i;
				    }

				    // if pants are other and top is neutral
	    			if (is_other && ((i == 0
	    				// neutral
				    	|| i == 1
				    	|| i == 3
				    	|| i == 5
				    	|| i == 10
				    )))
				    {
				    	if (!top_color && random() <= .05) top_color = i;
				    }

	    		}
	    	}

	    	self.b_shirt = top_color;
	    }
	}

	self.team = self.b_pants + 1;
	UpdateClient(self);
	SetNewParms();
	self.ishuman = 2;
	ClientConnect();
	PutClientInServer();

	active_clients = active_clients | ClientBitFlag(f);

	// this is risky... could corrupt .way files if done wrong
	// If you're not the gambling type, comment this out

	f = ClientBitFlag(self.b_num - 1);
	current_bots = current_bots | f;

	if (self.b_num <= 8)
		saved_skills1 = (saved_skills1 & (65536 - (3 * f)) | (self.b_skill * f));
	else
	{
		f = ClientBitFlag(self.b_num - 9);
		saved_skills2 = (saved_skills2 & (65536 - (3 * f)) | (self.b_skill * f));
	}

	h = ftos(current_bots);
	cvar_set("scratch1", h);
	h = ftos(saved_skills1);
	cvar_set("scratch2", h);
	h = ftos(saved_skills2);
	cvar_set("scratch3", h);
	self = uself;
};

void(entity bot) BotDisconnect =
{
	local string h;
	local entity uself;
	uself = self;
	self = bot;

	bot_count = bot_count - 1;
	current_bots = current_bots - (current_bots & ClientBitFlag(self.b_num - 1));
	h = ftos(current_bots);
	cvar_set("scratch1", h);


	ClientDisconnect();

	if (self.b_clientno != -1)
	{
      	// the bot's client number is not in use by a real player so we
		// must remove it's entry in the rankings
		// Quake engine sets all fields to 0, can only do the most important here
		self.b_frags = self.frags = 0;
		self.netname = "";
		self.classname = "";
		self.health = 0;
		self.items = 0;
		self.armorvalue = 0;
		self.weaponmodel = "";
		self.b_pants = 0;
		self.b_shirt = 0;
		self.ammo_shells = self.ammo_nails = self.ammo_rockets = self.ammo_cells = 0;
		UpdateClient(self);
		active_clients = active_clients - (active_clients & ClientBitFlag(self.b_clientno));
	      self.b_clientno = -1;
   	}
	self = uself;
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

BotInvalidClientNo
kicks a bot if a player connects and takes the bot's space

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

void(float clientno) BotInvalidClientNo =
{
	local entity bot;

	bot = GetClientEntity(clientno);
	if(bot.b_clientno > 0)
	{
		if (active_clients & ClientBitFlag(self.b_clientno))
		{
			bot.b_clientno = -1;
			BotDisconnect(bot);
			active_clients = active_clients | ClientBitFlag(self.b_clientno);
			BotConnect(0, bot.b_num, bot.b_skill); 
			return;
		}
	}
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Waypoint Loading from file

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
void() LoadWaypoint = 
{
	local vector org;
	local entity tep;
	local float r;
	org_x = cvar("saved1");
	org_y = cvar("saved2");
	org_z = cvar("saved3");
	
	tep = make_waypoint(org);

	r = cvar("saved4");

	tep.b_aiflags = floor(r / 4);
	tep.b_pants = cvar("scratch1");
	tep.b_skill = cvar("scratch2");
	tep.b_shirt = cvar("scratch3");
	tep.b_frags = cvar("scratch4");
};

void() bot_return =
{
	if (time > 2)
	{
		if ((waypoint_mode == WM_DYNAMIC) || (waypoint_mode == WM_LOADED))
		{
			// minor precaution

			if (saved_bots & 1) BotConnect(0, 1, saved_skills1 & 3);
			if (saved_bots & 2) BotConnect(0, 2, (saved_skills1 & 12) / 4);
			if (saved_bots & 4) BotConnect(0, 3, (saved_skills1 & 48) / 16);
			if (saved_bots & 8) BotConnect(0, 4, (saved_skills1 & 192) / 64);
			if (saved_bots & 16) BotConnect(0, 5, (saved_skills1 & 768) / 256);
			if (saved_bots & 32) BotConnect(0, 6, (saved_skills1 & 3072) / 1024);
			if (saved_bots & 64) BotConnect(0, 7, (saved_skills1 & 12288) / 4096);
			if (saved_bots & 128) BotConnect(0, 8, (saved_skills1 & 49152) / 16384);
			if (saved_bots & 256) BotConnect(0, 9, saved_skills2 & 3);
			if (saved_bots & 512) BotConnect(0, 10, (saved_skills2 & 12) / 4);
			if (saved_bots & 1024) BotConnect(0, 11, (saved_skills2& 48) / 16);
			if (saved_bots & 2048) BotConnect(0, 12, (saved_skills2 & 192) / 64);
			if (saved_bots & 4096) BotConnect(0, 13, (saved_skills2 & 768) / 256);
			if (saved_bots & 8192) BotConnect(0, 14, (saved_skills2 & 3072) / 1024);
			if (saved_bots & 16384) BotConnect(0, 15, (saved_skills2 & 12288) / 4096);
			if (saved_bots & 32768) BotConnect(0, 16, (saved_skills2 & 49152) / 16384);
			saved_bots = 0;
		}
	}
};


void() WaypointWatch =
{
	// Waypoint Baywatch
	local float bigboobs;
	local string h;
	if (framecount < 4)
		return;
	if (max_clients < 2)
		return;
	if (waypoint_mode != WM_UNINIT)
	{
		bigboobs = cvar("saved4");
		if (bigboobs != 0)
		{
			if ((bigboobs & 3) == 1)
				ClearAllWays();
			else if ((bigboobs & 3) == 3)
			{
				FixWaypoints();
				h = ftos(b_options);
				cvar_set("saved1", h);
				cvar_set("saved4", "0");
				cvar_set("scratch1", "0");
				waypoint_mode = WM_LOADED;
				return;
			}
			LoadWaypoint();
			waypoint_mode = WM_LOADING;
			cvar_set("saved4", "0");
		}
	}
	else
	{
		// the bots return!
		b_options = cvar("saved1");
		//if (coop || (b_options & OPT_SAVEBOTS))
		if ((b_options & OPT_SAVEBOTS)) // remove coop condition for bots sticking around -whipowill
		{
			saved_bots = cvar("scratch1");
			saved_skills1 = cvar("scratch2");
			saved_skills2 = cvar("scratch3");
		}
		cvar_set ("saved4", "0");
		if (max_clients > 1)
		{
			localcmd("exec maps/");
			localcmd(mapname);
			localcmd(".way\n");
			waypoint_mode = WM_DYNAMIC;
			bot_map_load();
		}
		else
			waypoint_mode = WM_LOADED;
	}
};
void() BotFrame =
{
	local float num;

	// for the sake of speed
	sv_maxspeed = cvar("sv_maxspeed");
	sv_gravity = cvar("sv_gravity");
	sv_friction = cvar("sv_friction");
	sv_accelerate = cvar("sv_accelerate");
	sv_stopspeed = cvar("sv_stopspeed");
	real_frametime = frametime; // in NQ this is alright
	
	self = nextent(world);
	num = 0;
	while (num < max_clients)
	{
		if (self.ishuman == FALSE)
		{
			if (active_clients & ClientBitFlag(num))
			{
				frik_obstacles();
				CL_KeyMove();
				SV_ClientThink();
				SV_Physics_Client();
			}
		}
		self = nextent(self);
		num = num + 1;
	}
	WaypointWatch();

	if (saved_bots)
		bot_return();
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Bot Impulses. Allows the player to perform bot
related functions.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

void() BotImpulses =
{
	local float f;

	if (self.impulse == 100)
	{
		f = cvar("skill");
		BotConnect(0, 0, f);
	}
	else if (self.impulse == 101)
	{
		f = cvar("skill");
		BotConnect(1, 0, f);
	}
	else if (self.impulse == 102)
		KickABot();
	else if (self.impulse == 103)
		botcam_u();
	else if (self.impulse == 104)
		bot_way_edit();
	if (self.impulse == 110) // random team bot -whipowill
	{
		f = cvar("skill") - 1 + rint(random());
		BotConnect(0, 0, f);
	}
	else if (self.impulse == 111) // random enemy bot -whipowill
	{
		f = cvar("skill") - 1 + rint(random());
		BotConnect(1, 0, f);
	}
	else if (self.impulse == 113) // tele bots to player in coop -whipowill
	{
		TeleBotsToMe();
	}
	else if (self.impulse == 120) // do a melee attack -whipowill
	{
		AxeAttack();
	}
	else if (self.impulse == 121) // do a grenade attack -whipowill
	{
		GrenadeAttack();
	}
	else if (self.impulse == 130) // testing scorekeeper -whipowill
	{
		ScoreKeeperList();
	}
	else
		return;

	self.impulse = 0;
};