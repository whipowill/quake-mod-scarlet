// -------------------------------------------------
// Developer aids for watching bots (scarlet_dev_botgoal 1, scarlet_dev_botlog 1).
// by whipowill
//
// The engine can't write text in the world, so a bot's goal floats over its head as a model:
//   the item's own model     going for that item
//   lavaball                 going for a waypoint (or something that isn't an item)
//   head                     going for a player
//   rocket                   fighting an enemy
//   gib                      running from a player with the pentagram
//   spike                    no goal
// and looking straight at a bot prints its name and goal in the middle of the screen.
// -------------------------------------------------

.string     mark_model;

// the entity a bot is really after: the item sits behind the waypoint it is heading for
entity(entity bot) BotGoalEnt =
{
    if (bot.target4_ent.flags & FL_ITEM)
        return bot.target4_ent;
    if (bot.target3_ent.flags & FL_ITEM)
        return bot.target3_ent;
    if (bot.target2_ent.flags & FL_ITEM)
        return bot.target2_ent;
    return bot.target1_ent;
};

string(entity bot) BotGoalState =
{
    if (bot.flee_ent)
        return "runs from pent";
    if (bot.enemy)
        return "fights";
    return "goes for";
};

void() BotGoalMarkThink =
{
    local entity bot = self.owner;
    local entity goal;
    local string mdl;

    if (!cv_scarlet_dev_botgoal || bot.classname != "player")
    {
        remove(self);
        return;
    }

    goal = BotGoalEnt(bot);
    if (bot.health <= 0)
        mdl = string_null;
    else if (bot.flee_ent)
        mdl = "progs/gib1.mdl";
    else if (bot.enemy)
        mdl = "progs/missile.mdl";
    else if ((goal.flags & FL_ITEM) && goal.model != string_null)
        mdl = goal.model;
    else if (goal.classname == "player")
        mdl = "progs/h_player.mdl";
    else if (goal)
        mdl = "progs/lavaball.mdl";
    else
        mdl = "progs/spike.mdl";

    if (mdl != self.mark_model)
    {
        self.mark_model = mdl;
        if (mdl)
            setmodel(self, mdl);
        else
        {
            self.modelindex = 0;
            self.model = string_null;
        }
        setsize(self, '0 0 0', '0 0 0');
    }

    // the three armors share one model and differ only by skin
    if ((goal.flags & FL_ITEM) && mdl == goal.model)
        self.skin = goal.skin;
    else
        self.skin = 0;

    setorigin(self, bot.origin + '0 0 1' * (60 + 3 * sin(time * 3)));
    self.nextthink = time;
};

// meant to be called every frame for a bot (see BotFrame)
void(entity bot) BotGoalMark =
{
    local entity m;

    if (!cv_scarlet_dev_botgoal)
        return;
    if (bot.goal_mark.classname == "goal_mark" && bot.goal_mark.owner == bot)
        return;

    m = spawn();
    m.classname = "goal_mark";
    m.owner = bot;
    m.movetype = MOVETYPE_NOCLIP; // so avelocity spins it
    m.solid = SOLID_NOT;
    m.avelocity = '0 120 0';
    m.scale = 0.7;
    m.think = BotGoalMarkThink;
    m.nextthink = time;
    bot.goal_mark = m;
};

// a human who looks straight at a bot gets its name and goal printed
void() BotGoalLook =
{
    local entity p, b, goal;
    local float n;

    if (!cv_scarlet_dev_botgoal)
        return;

    p = nextent(world);
    n = 0;
    while (n < max_clients)
    {
        if (p.ishuman && p.classname == "player" && p.health > 0 && time > p.look_time)
        {
            p.look_time = time + 0.3;
            makevectors(p.v_angle);
            traceline(p.origin + p.view_ofs, p.origin + p.view_ofs + v_forward * 2048, FALSE, p);
            b = trace_ent;
            if (b.classname == "player" && !b.ishuman)
            {
                goal = BotGoalEnt(b);
                if (b.enemy)
                    goal = b.enemy;
                if (b.flee_ent)
                    goal = b.flee_ent;
                centerprint5(p, b.netname, "\n", BotGoalState(b), "\n", goal.classname);
            }
        }
        p = nextent(p);
        n = n + 1;
    }
};

// dev: log when a bot lands from a drop, so tests can see where bots fall off things
void() bot_fall_log =
{
    local vector r;

    if (!cv_scarlet_dev_botlog)
        return;

    // how much a bot that is just walking (no enemy) changes direction: degrees a second, so a
    // smooth route and a jittery one can be told apart
    if (self.health > 0 && !self.enemy && (self.flags & FL_ONGROUND))
    {
        local vector v;
        local float yaw, dy;

        v = self.velocity;
        v_z = 0;
        if (vlen(v) > 150)
        {
            yaw = vectoyaw(v);
            dy = yaw - self.turn_yaw;
            while (dy > 180)
                dy = dy - 360;
            while (dy < -180)
                dy = dy + 360;
            if (self.turn_yaw)
            {
                if (dy < 0)
                    dy = 0 - dy;
                self.turn_sum = self.turn_sum + dy;
                self.turn_time = self.turn_time + frametime;
            }
            self.turn_yaw = yaw;
        }
        else
            self.turn_yaw = 0;
    }
    if (time > self.turn_next)
    {
        self.turn_next = time + 30;
        if (self.turn_time > 5)
        {
            dprint("BOTTURN ");
            dprint(self.netname);
            dprint(" ");
            dprint(ftos(self.turn_sum / self.turn_time));
            dprint(" over ");
            dprint(ftos(self.turn_time));
            dprint("\n");
        }
    }

    // every death, and where
    if (self.health <= 0)
    {
        if (!self.dead_logged)
        {
            self.dead_logged = TRUE;
            dprint("BOTDEAD ");
            dprint(ftos(time));
            dprint(" ");
            dprint(self.netname);
            dprint(" at ");
            dprint(vtos(self.origin));
            dprint(" by ");
            dprint(self.enemy.classname);
            dprint("\n");
        }
    }
    else
        self.dead_logged = FALSE;

    if (self.flags & FL_ONGROUND)
    {
        if (self.fall_z && self.fall_z - self.origin_z > 80 && self.teleport_time < time - 1)
        {
            dprint("BOTFALL ");
            dprint(ftos(time));
            dprint(" ");
            dprint(self.netname);
            dprint(" from ");
            dprint(vtos(self.fall_org));
            dprint(" to ");
            dprint(vtos(self.origin));
            dprint(" hp ");
            dprint(ftos(self.health));
            dprint(" tdz ");
            dprint(ftos(self.fall_tdz));
            dprint(" enemy ");
            dprint(self.enemy.classname);
            dprint(" avoid ");
            dprint(self.avoid.classname);
            dprint(" goal ");
            dprint(BotGoalEnt(self).classname);
            dprint("\n");
        }
        self.fall_z = 0;
    }
    else
    {
        if (!self.fall_z)
        {
            self.fall_z = self.origin_z;
            self.fall_org = self.origin;
            if (self.target1_ent)
            {
                r = realorigin(self.target1_ent);
                self.fall_tdz = r_z - self.origin_z;
            }
            else
                self.fall_tdz = 999;
        }
        else if (self.origin_z > self.fall_z)
        {
            self.fall_z = self.origin_z;
            self.fall_org = self.origin;
        }
    }
};
