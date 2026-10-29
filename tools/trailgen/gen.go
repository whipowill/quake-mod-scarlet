package main

import (
	"container/heap"
	"fmt"
	"math"
	"os"
	"sort"
	"strings"
)

// Waypoint flags understood by the mod (the AI_ constants in src/frikbot/bot.qc).
const (
	minHalfWidth = 10 // least floor either side of a walked link, so bots keep away from edges
	aiTelelink1  = 1  // the first link goes through a teleporter, so it costs nothing
	aiPlatBottom = 1024
	aiJump       = 256  // the bot jumps when it leaves this waypoint
	aiSuperJump  = 4096 // the bot rocket jumps when it leaves this waypoint
)

const (
	maxLinks = 4 // the mod stores four links per waypoint

	stretch = 1.2 // a link is dropped when the graph already has a path this close to straight

	// rocket jump model: upward speed right after the jump and the rocket go off, then gravity
	rjSpeed   = 600
	gravity   = 800
	rjMinRise = -50 // a rocket jump also carries a bot across a gap to a ledge as high as it stands
	rjMaxRise = 240 // higher than the model can reach
	rjMaxSide = 420

	// plain jump: the player leaves the ground at 270 units a second, 45 high at best
	jumpSpeed   = 270
	jumpMaxRise = 40
	jumpMaxSide = 160
)

type Link struct {
	To    int
	Flag  int  // AI_TELELINK bit when the link goes through a teleporter
	Fixed bool // a teleporter, plat or jump link, never swapped out
}

type Node struct {
	Pos    Vec3 // the player's origin when standing here
	Links  []Link
	Flags  int
	Plat   *Floor // extra floor to walk from when this node sits on a plat
	Spawn  bool   // bots start here, so everything must be able to get back to it
	Launch bool   // a spot where the bot jumps off, only ever linked by special links
	Reach  bool   // bots can get here from a spawn
	Home   bool   // bots here can get back to a spawn
	Dead   bool   // a trap: bots can be sent here but could never leave, so it is dropped
	Thin   bool   // taken out of the web by skeleton (also marked Dead)
}

// special links are always kept: teleporters, plats and jumps
type Special struct{ From, To, Flag int }

// Keepout is the shaft under a plat.  a bot standing in it when the plat is up gets hit by it
// coming down, the plat turns back, and the bot never gets on, so the only waypoint allowed
// there is the plat's own.
type Keepout struct {
	Min, Max   [2]float32
	ZMin, ZMax float32
}

type Cand struct {
	From, To int
	Len      float32
}

type Gen struct {
	b        *BSP
	mv       *Mover
	ents     []*Entity
	step     float32
	nodes    []*Node
	cells    map[[3]int32][]int
	queue    []int
	qhead    int
	specials []Special
	falls    []Cand // drops found while spreading, they only go one way
	items    []int  // the waypoint at each item
	itemName []string
	hover    []*Entity // items too far above any floor to touch
	itemEnt  []*Entity
	tele     []int // the waypoint in each teleporter
	keepout  []Keepout
	Notes    []string
	Stats    Stats
	Lift     float32 // how far above the player's origin a waypoint sits
}

type Stats struct {
	Seeds, Teleports, Plats, RJs     int
	Built, Kept, Falls, Links        int
	Dead, KillZones, Thinned         int
	ItemsTotal, ItemsOnFoot, ItemsRJ int
	StretchMean, StretchP90          float64
}

const cellSize = 64

func newGen(b *BSP, ents []*Entity, step float32) *Gen {
	g := &Gen{b: b, mv: &Mover{b: b, head: b.Models[0].Head[1]}, ents: ents, step: step, cells: map[[3]int32][]int{}}
	g.collectDeadly()
	return g
}

// collectDeadly finds the kill zones: a hurt trigger that does 50 or more damage, and the
// void triggers and walls that kill whatever touches them.  their bounding boxes are used,
// which can be a little bigger than the brush, and a zone that is switched on and off by a
// trigger counts as always on.
func (g *Gen) collectDeadly() {
	for _, e := range g.ents {
		switch e.Class() {
		case "trigger_hurt":
			dmg := float64(5)
			if v := e.Get("dmg"); v != "" {
				fmt.Sscanf(v, "%g", &dmg)
			}
			if dmg < 50 {
				continue
			}
		case "trigger_void", "func_void":
		default:
			continue
		}
		if mins, maxs, ok := g.bounds(e); ok {
			g.mv.deadly = append(g.mv.deadly, Box{mins, maxs})
		}
	}
	g.Stats.KillZones = len(g.mv.deadly)
}

func cellOf(p Vec3) [3]int32 {
	return [3]int32{int32(math.Floor(float64(p[0]) / cellSize)), int32(math.Floor(float64(p[1]) / cellSize)), int32(math.Floor(float64(p[2]) / cellSize))}
}

func hdist(a, b Vec3) float32 {
	return float32(math.Hypot(float64(a[0]-b[0]), float64(a[1]-b[1])))
}

func dist3(a, b Vec3) float32 {
	return float32(math.Sqrt(float64((a[0]-b[0])*(a[0]-b[0]) + (a[1]-b[1])*(a[1]-b[1]) + (a[2]-b[2])*(a[2]-b[2]))))
}

// nearZ lists waypoints within r units sideways of p and within dz of its height, closest first.
func (g *Gen) nearZ(p Vec3, r, dz float32) []int {
	var out []int
	c := cellOf(p)
	n := int32(r/cellSize) + 1
	nz := int32(dz/cellSize) + 1
	for x := c[0] - n; x <= c[0]+n; x++ {
		for y := c[1] - n; y <= c[1]+n; y++ {
			for z := c[2] - nz; z <= c[2]+nz; z++ {
				for _, i := range g.cells[[3]int32{x, y, z}] {
					q := g.nodes[i].Pos
					if hdist(p, q) <= r && math.Abs(float64(p[2]-q[2])) <= float64(dz) {
						out = append(out, i)
					}
				}
			}
		}
	}
	sort.Slice(out, func(a, b int) bool { return hdist(p, g.nodes[out[a]].Pos) < hdist(p, g.nodes[out[b]].Pos) })
	return out
}

func (g *Gen) near(p Vec3, r float32) []int { return g.nearZ(p, r, 40) }

const keepMargin = 20 // a bot this far outside the plat's edge is clear of it

// badSegment is a link a bot may not use: it crosses a plat shaft and neither end is on the plat.
func (g *Gen) badSegment(a, b int) bool {
	if g.nodes[a].Plat != nil || g.nodes[b].Plat != nil {
		return false
	}
	return g.crossesKeepout(g.nodes[a].Pos, g.nodes[b].Pos)
}

func (g *Gen) inKeepout(p Vec3) bool {
	for _, k := range g.keepout {
		if p[0] >= k.Min[0]-keepMargin && p[0] <= k.Max[0]+keepMargin && p[1] >= k.Min[1]-keepMargin && p[1] <= k.Max[1]+keepMargin &&
			p[2] >= k.ZMin && p[2] <= k.ZMax {
			return true
		}
	}
	return false
}

// crossesKeepout reports whether the straight line from a to b goes through a plat shaft.
func (g *Gen) crossesKeepout(a, b Vec3) bool {
	if len(g.keepout) == 0 {
		return false
	}
	d := dist3(a, b)
	for t := float32(0); t <= d; t += 12 {
		f := t / d
		if g.inKeepout(Vec3{a[0] + (b[0]-a[0])*f, a[1] + (b[1]-a[1])*f, a[2] + (b[2]-a[2])*f}) {
			return true
		}
	}
	return g.inKeepout(b)
}

// addNode makes a waypoint and queues it to be spread from.
func (g *Gen) addNode(p Vec3) int {
	g.nodes = append(g.nodes, &Node{Pos: p})
	i := len(g.nodes) - 1
	c := cellOf(p)
	g.cells[c] = append(g.cells[c], i)
	g.queue = append(g.queue, i)
	return i
}

// canWalk is true when a bot standing at a can walk to b without falling.
func (g *Gen) canWalk(a, b int) bool {
	na, nb := g.nodes[a], g.nodes[b]
	d := hdist(na.Pos, nb.Pos)
	if d < 1 {
		return true
	}
	dir := Vec3{(nb.Pos[0] - na.Pos[0]) / d, (nb.Pos[1] - na.Pos[1]) / d, 0}
	vf := na.Plat
	if vf == nil {
		vf = nb.Plat
	}
	end, fell, ok := g.mv.Walk(na.Pos, dir, d, vf)
	if !ok || fell || hdist(end, nb.Pos) > 24 || math.Abs(float64(end[2]-nb.Pos[2])) > 20 {
		return false
	}
	return true
}

// canWalkSafe is canWalk for a link that is going to be made: a link along an edge is one bots fall
// off, so it needs floor either side (a plat has no floor of its own to measure).
func (g *Gen) canWalkSafe(a, b int) bool {
	if !g.canWalk(a, b) {
		return false
	}
	if g.nodes[a].Plat != nil || g.nodes[b].Plat != nil {
		return true
	}
	return g.wideEnough(g.nodes[a].Pos, g.nodes[b].Pos)
}

// spreadDirs are the compass points the waypoints grow in.
var spreadDirs = func() []Vec3 {
	var out []Vec3
	for i := 0; i < 16; i++ {
		a := float64(i) * math.Pi / 8
		out = append(out, Vec3{float32(math.Cos(a)), float32(math.Sin(a)), 0})
	}
	return out
}()

// expand grows one new waypoint from n in direction dir, if there is room for one.
func (g *Gen) expand(n int, dir Vec3) {
	from := g.nodes[n]
	sep := g.step * 0.75
	for _, dist := range []float32{g.step, g.step * 0.6, g.step * 0.35} {
		end, fell, ok := g.mv.Walk(from.Pos, dir, dist, from.Plat)
		if !ok {
			continue
		}
		for _, c := range g.near(end, sep*dist/g.step) {
			if c == n {
				continue
			}
			if fell {
				g.falls = append(g.falls, Cand{n, c, dist3(from.Pos, g.nodes[c].Pos)})
				return
			}
			if g.canWalk(n, c) {
				return // that spot is already covered
			}
		}
		if g.inKeepout(end) {
			return
		}
		i := g.addNode(end)
		if fell {
			g.falls = append(g.falls, Cand{n, i, dist3(from.Pos, end)})
		}
		return
	}
}

// fill spreads waypoints from everything in the queue until there is nowhere left to go.
func (g *Gen) fill() {
	for ; g.qhead < len(g.queue); g.qhead++ {
		for _, d := range spreadDirs {
			g.expand(g.queue[g.qhead], d)
		}
	}
}

// seedAt adds a waypoint at the floor under p (or reuses one that is already there).
func (g *Gen) seedAt(p Vec3, up float32) (int, bool) {
	land, ok := g.mv.Drop(Vec3{p[0], p[1], p[2] + up}, 256)
	if !ok || g.mv.Deadly(land) {
		return 0, false
	}
	if c := g.near(land, 24); len(c) > 0 {
		return c[0], true
	}
	return g.addNode(land), true
}

func (g *Gen) seedSpawns() {
	for _, e := range g.ents {
		switch e.Class() {
		case "info_player_start", "info_player_deathmatch", "info_player_coop":
			o, ok := e.Origin()
			if !ok {
				continue
			}
			if i, ok := g.seedAt(o, 8); ok {
				g.nodes[i].Spawn = true
				g.Stats.Seeds++
			}
		}
	}
}

func (g *Gen) bounds(e *Entity) (Vec3, Vec3, bool) {
	m := e.ModelIndex()
	if m < 1 || m >= len(g.b.Models) {
		return Vec3{}, Vec3{}, false
	}
	return g.b.Models[m].Mins, g.b.Models[m].Maxs, true
}

// seedTeleports puts a waypoint inside every teleporter, linked straight to where it leads.
func (g *Gen) seedTeleports() {
	dests := map[string][]*Entity{}
	for _, e := range g.ents {
		if e.Class() == "info_teleport_destination" {
			dests[e.Get("targetname")] = append(dests[e.Get("targetname")], e)
		}
	}
	for _, e := range g.ents {
		if e.Class() != "trigger_teleport" {
			continue
		}
		mins, maxs, ok := g.bounds(e)
		ds := dests[e.Get("target")]
		if !ok || len(ds) == 0 {
			continue
		}
		o, ok := ds[0].Origin()
		if !ok {
			continue
		}
		in, ok := g.seedAt(Vec3{(mins[0] + maxs[0]) / 2, (mins[1] + maxs[1]) / 2, mins[2]}, 40)
		// a teleporter set into a narrow niche has no room for the player's box at its middle,
		// but touching its edge is enough
		for r := float32(8); !ok && r <= 40; r += 8 {
			for _, d := range [][2]float32{{-1, 0}, {1, 0}, {0, -1}, {0, 1}, {-1, -1}, {-1, 1}, {1, -1}, {1, 1}} {
				cx, cy := (mins[0]+maxs[0])/2+d[0]*r, (mins[1]+maxs[1])/2+d[1]*r
				if cx < mins[0]-16 || cx > maxs[0]+16 || cy < mins[1]-16 || cy > maxs[1]+16 {
					continue
				}
				if in, ok = g.seedAt(Vec3{cx, cy, mins[2]}, 40); ok {
					break
				}
			}
		}
		if !ok {
			continue
		}
		out, ok := g.seedAt(o, 27)
		if !ok {
			// a destination hanging in the air: the player leaves it at 300 along its angle
			// and lands wherever that carries him
			var ang float32
			fmt.Sscanf(ds[0].Get("angle"), "%f", &ang)
			land, fl := g.teleFlight(o, ang)
			if !fl {
				continue
			}
			out, ok = g.seedAt(land, 8)
			if !ok {
				continue
			}
		}
		g.specials = append(g.specials, Special{in, out, aiTelelink1})
		g.Stats.Teleports++
		g.tele = append(g.tele, in)
	}
}

// seedPlats puts a waypoint on each plat at the bottom and at the top and links them.
func (g *Gen) seedPlats() {
	for _, e := range g.ents {
		if e.Class() != "func_plat" {
			continue
		}
		mins, maxs, ok := g.bounds(e)
		if !ok {
			continue
		}
		cx, cy := (mins[0]+maxs[0])/2, (mins[1]+maxs[1])/2
		// the brush is modelled at the top.  it rides down to 8 above its own bottom
		topZ := maxs[2] + 24
		botZ := mins[2] + 8 + 24
		const inset = 8
		top := &Floor{Min: [2]float32{mins[0] + inset, mins[1] + inset}, Max: [2]float32{maxs[0] - inset, maxs[1] - inset}, Z: topZ}
		bot := &Floor{Min: top.Min, Max: top.Max, Z: botZ}
		b := g.addNode(Vec3{cx, cy, botZ})
		t := g.addNode(Vec3{cx, cy, topZ})
		g.keepout = append(g.keepout, Keepout{Min: [2]float32{mins[0], mins[1]}, Max: [2]float32{maxs[0], maxs[1]}, ZMin: mins[2] - 8, ZMax: maxs[2]})
		g.nodes[b].Plat, g.nodes[b].Flags = bot, aiPlatBottom
		g.nodes[t].Plat = top
		g.specials = append(g.specials, Special{b, t, 0}, Special{t, b, 0})
		g.Stats.Plats++
	}
}

func (g *Gen) degree(n int) int { return len(g.nodes[n].Links) }

func (g *Gen) link(a, b, flag int, fixed bool) bool {
	if a == b {
		return false
	}
	n := g.nodes[a]
	for _, l := range n.Links {
		if l.To == b {
			return true
		}
	}
	if len(n.Links) >= maxLinks {
		return false
	}
	n.Links = append(n.Links, Link{To: b, Flag: flag, Fixed: fixed})
	return true
}

type pqItem struct {
	node int
	d    float32
}
type pq []pqItem

func (p pq) Len() int            { return len(p) }
func (p pq) Less(i, j int) bool  { return p[i].d < p[j].d }
func (p pq) Swap(i, j int)       { p[i], p[j] = p[j], p[i] }
func (p *pq) Push(x interface{}) { *p = append(*p, x.(pqItem)) }
func (p *pq) Pop() interface{} {
	o := *p
	x := o[len(o)-1]
	*p = o[:len(o)-1]
	return x
}

// pathWithin reports whether the links made so far already get from a to b in limit units or less.
func (g *Gen) pathWithin(a, b int, limit float32) bool {
	best := map[int]float32{a: 0}
	h := &pq{{a, 0}}
	for h.Len() > 0 {
		it := heap.Pop(h).(pqItem)
		if it.node == b {
			return true
		}
		if it.d > best[it.node] {
			continue
		}
		for _, l := range g.nodes[it.node].Links {
			nd := it.d + dist3(g.nodes[it.node].Pos, g.nodes[l.To].Pos)
			if nd > limit {
				continue
			}
			if d, ok := best[l.To]; !ok || nd < d {
				best[l.To] = nd
				heap.Push(h, pqItem{l.To, nd})
			}
		}
	}
	return false
}

// connect picks the links.  Special links go in first, then every walkable link between
// nearby waypoints, shortest first, skipping any the graph already covers in nearly a straight line.
func (g *Gen) connect() {
	for _, n := range g.nodes {
		n.Links = nil
	}
	for _, s := range g.specials {
		g.link(s.From, s.To, s.Flag, true)
	}

	var cands []Cand
	for a, na := range g.nodes {
		if na.Launch {
			continue
		}
		for _, b := range g.nearZ(na.Pos, g.step*2, 80) {
			if b == a || g.nodes[b].Launch || !g.canWalkSafe(a, b) || g.badSegment(a, b) {
				continue
			}
			cands = append(cands, Cand{a, b, dist3(na.Pos, g.nodes[b].Pos)})
		}
	}
	cands = append(cands, g.falls...)
	sort.SliceStable(cands, func(i, j int) bool { return cands[i].Len < cands[j].Len })

	for _, c := range cands {
		if g.degree(c.From) >= maxLinks || g.nodes[c.From].Launch || g.nodes[c.To].Launch {
			continue
		}
		if g.pathWithin(c.From, c.To, c.Len*stretch) {
			continue
		}
		g.link(c.From, c.To, 0, false)
	}
	g.express()
}

// withinHops reports whether b can be reached from a in limit links or fewer.  the link
// skipFrom -> skipTo is treated as if it were not there.
func (g *Gen) withinHops(a, b, limit, skipFrom, skipTo int) bool {
	if a == b {
		return true
	}
	seen := map[int]bool{a: true}
	frontier := []int{a}
	for depth := 0; depth < limit; depth++ {
		var next []int
		for _, u := range frontier {
			for _, l := range g.nodes[u].Links {
				if u == skipFrom && l.To == skipTo {
					continue
				}
				if l.To == b {
					return true
				}
				if !seen[l.To] {
					seen[l.To] = true
					next = append(next, l.To)
				}
			}
		}
		frontier = next
	}
	return false
}

// express adds long straight links where they save at least four hops, which keeps routes
// shallow.  the mod works routes out a hop at a time, one bot at a time, so a deep graph
// leaves bots standing around waiting for a route.  a node that has no free link gives up
// one the graph can do without (its target stays within three hops).
func (g *Gen) express() {
	reach := g.step * 2
	if reach < 900 {
		reach = 900
	}
	var cands []Cand
	for a, na := range g.nodes {
		if na.Launch {
			continue
		}
		for _, b := range g.nearZ(na.Pos, reach, 120) {
			d := dist3(na.Pos, g.nodes[b].Pos)
			if b == a || g.nodes[b].Launch || d < g.step*1.2 || !g.canWalkSafe(a, b) || g.badSegment(a, b) {
				continue
			}
			cands = append(cands, Cand{a, b, d})
		}
	}
	sort.SliceStable(cands, func(i, j int) bool { return cands[i].Len > cands[j].Len })

	for _, c := range cands {
		if g.withinHops(c.From, c.To, 3, -1, -1) {
			continue
		}
		a := g.nodes[c.From]
		if len(a.Links) < maxLinks {
			g.link(c.From, c.To, 0, false)
			continue
		}
		swap, shortest := -1, float32(1e9)
		for i, l := range a.Links {
			if l.Fixed {
				continue
			}
			if d := dist3(a.Pos, g.nodes[l.To].Pos); d < shortest && g.withinHops(c.From, l.To, 3, c.From, l.To) {
				swap, shortest = i, d
			}
		}
		if swap >= 0 {
			a.Links[swap] = Link{To: c.To}
		}
	}
}

// prune marks every waypoint dead that a bot could not reach from where bots start, or
// could not get back out of again (pits it can fall into).
func (g *Gen) prune() {
	n := len(g.nodes)
	reach := make([]bool, n)
	home := make([]bool, n)
	back := make([][]int, n)
	for i, nd := range g.nodes {
		for _, l := range nd.Links {
			back[l.To] = append(back[l.To], i)
		}
	}
	var stack []int
	for i, nd := range g.nodes {
		if nd.Spawn {
			reach[i], home[i] = true, true
			stack = append(stack, i)
		}
	}
	spawns := append([]int(nil), stack...)
	for len(stack) > 0 {
		i := stack[len(stack)-1]
		stack = stack[:len(stack)-1]
		for _, l := range g.nodes[i].Links {
			if !reach[l.To] {
				reach[l.To] = true
				stack = append(stack, l.To)
			}
		}
	}
	stack = spawns
	for len(stack) > 0 {
		i := stack[len(stack)-1]
		stack = stack[:len(stack)-1]
		for _, p := range back[i] {
			if !home[p] {
				home[p] = true
				stack = append(stack, p)
			}
		}
	}
	for i, nd := range g.nodes {
		nd.Reach, nd.Home = reach[i], home[i]
		// only a trap is dropped.  a pocket bots can't be routed into stays: one that gets
		// there anyway (a teleport, a knock, a fall) still needs waypoints to find its way out
		nd.Dead = reach[i] && !home[i]
	}
}

// alive reports whether bots can get to waypoint n from a spawn and back again.
func (g *Gen) alive(n int) bool { return g.nodes[n].Reach && g.nodes[n].Home }

// itemSpots lists where bots would want to stand to pick up each item.
func (g *Gen) itemSpots() []Vec3 {
	var out []Vec3
	g.itemName = nil
	g.itemEnt = nil
	g.hover = nil
	for _, e := range g.ents {
		c := e.Class()
		if !strings.HasPrefix(c, "item_") && !strings.HasPrefix(c, "weapon_") {
			continue
		}
		if strings.HasPrefix(c, "item_key") || c == "item_sigil" || strings.HasPrefix(c, "item_rune") {
			continue
		}
		o, ok := e.Origin()
		if !ok {
			continue
		}
		if land, ok := g.mv.Drop(Vec3{o[0], o[1], o[2] + 36}, 200); ok {
			// a player standing on that floor reaches about 45 up on tiptoe and a jump adds
			// another 45, so an item hanging higher than that can't be picked up from there
			if o[2]-land[2] > maxItemHover {
				g.hover = append(g.hover, e)
				g.Notes = append(g.Notes, fmt.Sprintf("%s at %.0f %.0f %.0f hangs %.0f above the floor under it, so it can't be picked up", c, o[0], o[1], o[2], o[2]-land[2]))
				e.Set("trail_skip", "1")
				continue
			}
			out = append(out, land)
			g.itemName = append(g.itemName, c)
			g.itemEnt = append(g.itemEnt, e)
		} else if tr := g.mv.trace(Vec3{o[0], o[1], o[2] + 8}, Vec3{o[0], o[1], o[2] - 1000}); !tr.StartSolid && (tr.Fraction == 1 || o[2]-tr.End[2] > maxItemHover) {
			// nothing to stand on within reach below it
			g.hover = append(g.hover, e)
			g.Notes = append(g.Notes, fmt.Sprintf("%s at %.0f %.0f %.0f has no floor within reach under it, so it can't be picked up", c, o[0], o[1], o[2]))
			e.Set("trail_skip", "1")
		}
	}
	return out
}

// rocketJump simulates a bot that leaves the ground at from with upward speed vz (a jump,
// or a jump plus a rocket under its feet) and steers for to.  it reports whether the bot
// lands on to.
func (g *Gen) rocketJump(from, to Vec3, vz float32) bool {
	const dt = 1.0 / 60
	pos := from
	var vel Vec3
	vel[2] = vz
	for t := 0; t < 240; t++ {
		d := hdist(pos, to)
		var want float32 = 320
		if d*8 < want {
			want = d * 8
		}
		if d > 1 {
			vel[0] = (to[0] - pos[0]) / d * want
			vel[1] = (to[1] - pos[1]) / d * want
		}
		vel[2] -= gravity * dt

		// move like the engine does: go as far as possible, slide along what was hit, repeat
		left := float32(dt)
		for bump := 0; bump < 4 && left > 0; bump++ {
			end := Vec3{pos[0] + vel[0]*left, pos[1] + vel[1]*left, pos[2] + vel[2]*left}
			tr := g.mv.trace(pos, end)
			if tr.StartSolid || g.mv.Deadly(tr.End) {
				return false
			}
			pos = tr.End
			if tr.Fraction == 1 {
				break
			}
			if tr.Normal[2] >= floorSlope && vel[2] < 0 {
				return hdist(pos, to) <= 40 && math.Abs(float64(pos[2]-to[2])) <= 24
			}
			left -= left * tr.Fraction
			dn := dot(vel, tr.Normal)
			vel = Vec3{vel[0] - tr.Normal[0]*dn, vel[1] - tr.Normal[1]*dn, vel[2] - tr.Normal[2]*dn}
		}
	}
	return false
}

// findLaunch looks for the closest reachable waypoint a bot can jump to f from, by an
// ordinary jump if that is enough and by rocket jump if not.  it returns the waypoint
// and the flag the launch spot needs, or -1.
func (g *Gen) findLaunch(f Vec3) (int, int) {
	return g.findLaunchFrom(f, nil)
}

// findLaunchFrom is findLaunch, but only from the waypoints in allow (all of them if it is nil).
func (g *Gen) findLaunchFrom(f Vec3, allow map[int]bool) (int, int) {
	for _, mode := range []struct {
		flag             int
		vz, minRise, max float32
		side             float32
		margin           float32
	}{
		{aiJump, jumpSpeed, stepHeight, jumpMaxRise, jumpMaxSide, 20},
		{aiSuperJump, rjSpeed, rjMinRise, rjMaxRise, rjMaxSide, 60},
	} {
		best := -1
		var bestD float32
		for u, nu := range g.nodes {
			rise := f[2] - nu.Pos[2]
			if allow != nil && !allow[u] {
				continue
			}
			if !(nu.Reach && nu.Home) || nu.Launch || nu.Plat != nil || rise < mode.minRise || rise > mode.max {
				continue
			}
			d := hdist(nu.Pos, f)
			if d > mode.side || (best >= 0 && d >= bestD) {
				continue
			}
			// must work with some margin either way, the real jump varies
			if g.rocketJump(nu.Pos, f, mode.vz) && g.rocketJump(nu.Pos, f, mode.vz-mode.margin) {
				best, bestD = u, d
			}
		}
		if best >= 0 {
			return best, mode.flag
		}
	}
	return -1, 0
}

// seedItems puts a waypoint at every item, so bots can walk right up to it.
func (g *Gen) seedItems() {
	for _, f := range g.itemSpots() {
		if c := g.near(f, 24); len(c) > 0 {
			g.items = append(g.items, c[0])
		} else {
			g.items = append(g.items, g.addNode(f))
		}
	}
	g.Stats.ItemsTotal = len(g.items)
	// a teleporter is as good as an item to get to
	for _, t := range g.tele {
		g.items = append(g.items, t)
		g.itemName = append(g.itemName, "teleporter")
	}
}

// reachItems finds items bots can't get to on foot and sets up a rocket jump for each one
// that has a launch spot.  it reports whether it added anything.
func (g *Gen) reachItems() bool {
	added := false
	for _, m := range g.items {
		if g.alive(m) {
			continue
		}
		f := g.nodes[m].Pos

		best, flag := g.findLaunch(f)
		if best < 0 {
			continue
		}

		g.nodes = append(g.nodes, &Node{Pos: g.nodes[best].Pos, Launch: true, Flags: flag})
		l := len(g.nodes) - 1
		g.specials = append(g.specials, Special{best, l, 0}, Special{l, m, 0})
		added = true
	}
	return added
}

// build runs the whole thing and leaves the finished graph in g.nodes.
func (g *Gen) build() {
	g.seedSpawns()
	g.seedTeleports()
	g.seedPlats()
	g.seedItems()
	g.fill()
	g.centerNodes()
	g.connect()
	g.prune()
	if g.rescueSpawns() {
		g.connect()
		g.prune()
		// and a way back up to whatever is on it
		if g.reachPerches() {
			g.connect()
			g.prune()
		}
	}

	for _, m := range g.items {
		if g.alive(m) {
			g.Stats.ItemsOnFoot++
		}
	}
	if g.reachItems() {
		g.connect()
		g.prune()
	}
	// a ledge bots can jump or teleport up to still needs a way back down
	if g.rescuePerches() {
		g.connect()
		g.prune()
	}
	// count the jumps that paid off: a ledge with no way back down is no use
	for _, s := range g.specials {
		if g.nodes[s.From].Launch && g.alive(s.To) && g.alive(s.From) {
			g.Stats.ItemsRJ++
			if g.nodes[s.From].Flags&aiSuperJump != 0 {
				g.Stats.RJs++
			}
		}
	}
	for i, m := range g.items {
		if !g.alive(m) {
			p := g.nodes[m].Pos
			g.Notes = append(g.Notes, fmt.Sprintf("can't reach %s at %.0f %.0f %.0f%s", g.itemName[i], p[0], p[1], p[2], g.nearestAlive(m)))
			// an item whose waypoint was dropped as a trap has nothing to route to, so tell
			// the bots to leave it alone (teleporters have no entity to mark)
			if i < len(g.itemEnt) {
				g.itemEnt[i].Set("trail_skip", "1")
			}
		}
	}
	if os.Getenv("TRAILGEN_DENSE") == "" {
		g.skeleton()
	}
	g.compact()
	g.measure()
	if w := os.Getenv("TRAILGEN_WHY"); w != "" {
		var x, y, z float32
		fmt.Sscanf(w, "%f,%f,%f", &x, &y, &z)
		g.whyUnreachable(Vec3{x, y, z})
	}
	if sl := os.Getenv("TRAILGEN_SLICE"); sl != "" {
		var x, y, z float32
		fmt.Sscanf(sl, "%f,%f,%f", &x, &y, &z)
		g.sliceMap(x, y, z)
	}
	if pr := os.Getenv("TRAILGEN_PROBE"); pr != "" {
		var x, y, z float32
		fmt.Sscanf(pr, "%f,%f,%f", &x, &y, &z)
		g.probeMap(x, y, z)
	}
	if im := os.Getenv("TRAILGEN_IMAGE"); im != "" {
		g.drawGraph(im)
	}
	if sp := os.Getenv("TRAILGEN_SEE"); sp != "" {
		var x, y, z float32
		fmt.Sscanf(sp, "%f,%f,%f", &x, &y, &z)
		g.seeMap(Vec3{x, y, z})
	}
	if os.Getenv("TRAILGEN_CHECK") != "" {
		g.clearanceReport()
		g.linkCheck()
	}
	if os.Getenv("TRAILGEN_NARROW") != "" {
		g.narrowReport()
		g.nodeEdgeReport()
	}
}

// compact drops the dead waypoints and renumbers what is left.
func (g *Gen) compact() {
	g.Stats.Built = len(g.nodes)
	remap := make([]int, len(g.nodes))
	var kept []*Node
	for i, nd := range g.nodes {
		if nd.Dead {
			remap[i] = -1
			if nd.Thin {
				continue
			}
			g.Stats.Dead++
			continue
		}
		remap[i] = len(kept)
		kept = append(kept, nd)
	}
	for _, nd := range kept {
		var ls []Link
		for _, l := range nd.Links {
			if remap[l.To] >= 0 {
				l.To = remap[l.To]
				ls = append(ls, l)
			}
		}
		nd.Links = ls
		// telelink flags belong to the slot a link sits in
		nd.Flags &^= 15
		for s, l := range ls {
			if l.Flag != 0 {
				nd.Flags |= aiTelelink1 << s
			}
		}
		g.Stats.Links += len(ls)
	}
	g.nodes = kept
	g.Stats.Kept = len(kept)
	g.Stats.Falls = 0
	for _, f := range g.falls {
		_ = f
	}
}

// measure reports how winding the routes are: the length of the best route between two
// waypoints divided by the straight line between them.  1.0 is perfectly straight.
func (g *Gen) measure() {
	var ratios []float64
	for a := range g.nodes {
		dist := map[int]float32{a: 0}
		h := &pq{{a, 0}}
		for h.Len() > 0 {
			it := heap.Pop(h).(pqItem)
			if it.d > dist[it.node] {
				continue
			}
			for _, l := range g.nodes[it.node].Links {
				if g.nodes[it.node].Flags&15 != 0 && l.Flag != 0 {
					continue // teleports aren't walked
				}
				nd := it.d + dist3(g.nodes[it.node].Pos, g.nodes[l.To].Pos)
				if d, ok := dist[l.To]; !ok || nd < d {
					dist[l.To] = nd
					heap.Push(h, pqItem{l.To, nd})
				}
			}
		}
		for b, d := range dist {
			e := hdist(g.nodes[a].Pos, g.nodes[b].Pos)
			if b != a && e >= 300 && e <= 1200 && math.Abs(float64(g.nodes[a].Pos[2]-g.nodes[b].Pos[2])) < 64 {
				ratios = append(ratios, float64(d)/float64(e))
			}
		}
	}
	if len(ratios) == 0 {
		return
	}
	sort.Float64s(ratios)
	var sum float64
	for _, r := range ratios {
		sum += r
	}
	g.Stats.StretchMean = sum / float64(len(ratios))
	g.Stats.StretchP90 = ratios[len(ratios)*9/10]
}

// waypointEntities turns the graph into entities the mod's waypoint() spawn function reads.
func (g *Gen) waypointEntities() []*Entity {
	out := make([]*Entity, 0, len(g.nodes))
	linkKey := [maxLinks]string{"b_pants", "b_skill", "b_shirt", "b_frags"}
	for _, nd := range g.nodes {
		e := &Entity{}
		e.Set("classname", "waypoint")
		e.Set("origin", strings.Join([]string{fmtNum(nd.Pos[0]), fmtNum(nd.Pos[1]), fmtNum(nd.Pos[2] + g.Lift)}, " "))
		for s, l := range nd.Links {
			e.Set(linkKey[s], fmtNum(float32(l.To+1)))
		}
		if nd.Flags != 0 {
			e.Set("b_aiflags", fmtNum(float32(nd.Flags)))
		}
		out = append(out, e)
	}
	return out
}

// rescueFall is how far a bot stuck on a perch is allowed to drop.
const rescueFall = 768

// maxItemHover is the most an item's origin can be above the standing spot under it and still be picked up
const maxItemHover = 80

// reachFrom lists the waypoints a bot can get to from n.
func (g *Gen) reachFrom(n int) []int {
	seen := map[int]bool{n: true}
	stack := []int{n}
	for len(stack) > 0 {
		i := stack[len(stack)-1]
		stack = stack[:len(stack)-1]
		for _, l := range g.nodes[i].Links {
			if !seen[l.To] {
				seen[l.To] = true
				stack = append(stack, l.To)
			}
		}
	}
	out := make([]int, 0, len(seen))
	for i := range seen {
		out = append(out, i)
	}
	sort.Ints(out)
	return out
}

// longDrops lets bots leave a pocket by dropping further than maxFall.  a drop that long is never
// sent over normally, but a pocket with no other way out (a spawn on a perch, a ledge reached by
// rocket jump) needs one, or the bots in it are stuck.  it reports whether it added anything.
func (g *Gen) longDrops(pocket []int, what string, at Vec3) bool {
	g.mv.fall = rescueFall
	nodes, falls := len(g.nodes), len(g.falls)
	for _, p := range pocket {
		for _, d := range spreadDirs {
			g.expand(p, d)
		}
	}
	g.mv.fall = 0
	long := false
	for _, c := range g.falls[falls:] {
		if g.nodes[c.From].Pos[2]-g.nodes[c.To].Pos[2] > maxFall {
			long = true
		}
	}
	if !long && len(g.nodes) == nodes {
		return false
	}
	g.Notes = append(g.Notes, fmt.Sprintf("%s at %.0f %.0f %.0f was on a perch with no way down, so drops of up to %d are allowed from it", what, at[0], at[1], at[2], rescueFall))
	return true
}

// rescueSpawns frees bots that spawn on a perch with no way down: a pocket that holds a spawn
// but leads to no other.
func (g *Gen) rescueSpawns() bool {
	added := false
	done := map[int]bool{}
	for s, nd := range g.nodes {
		if !nd.Spawn || done[s] {
			continue
		}
		pocket := g.reachFrom(s)
		for _, p := range pocket {
			done[p] = true
		}
		// a pocket that leads to another spawn leads into the map
		others := false
		for _, p := range pocket {
			if p != s && g.nodes[p].Spawn {
				others = true
			}
		}
		if !others && g.longDrops(pocket, "spawn", nd.Pos) {
			added = true
		}
	}
	if added {
		g.fill()
	}
	return added
}

// rescuePerches does the same for an item bots can get to (by rocket jump) but not back from.
func (g *Gen) rescuePerches() bool {
	added := false
	done := map[int]bool{}
	for i, m := range g.items {
		if done[m] || !g.nodes[m].Dead {
			continue
		}
		pocket := g.reachFrom(m)
		for _, p := range pocket {
			done[p] = true
		}
		if g.longDrops(pocket, g.itemName[i], g.nodes[m].Pos) {
			added = true
		}
	}
	if added {
		g.fill()
	}
	return added
}

// nearestAlive describes the closest waypoint bots can use to n, for the notes.
func (g *Gen) nearestAlive(n int) string {
	best, bd := -1, float32(1e9)
	for i, nd := range g.nodes {
		if i == n || !g.alive(i) {
			continue
		}
		if d := dist3(g.nodes[n].Pos, nd.Pos); d < bd {
			best, bd = i, d
		}
	}
	if best < 0 {
		return ""
	}
	dz := g.nodes[best].Pos[2] - g.nodes[n].Pos[2]
	return fmt.Sprintf("  (nearest usable waypoint %.0f away, %.0f above)", bd, dz)
}

// reachPerches gives a way up to a perch with an item on it.  once a spawn perch has a way down
// (rescueSpawns), its items count as reachable, because bots spawn there, but nothing in the
// rest of the map leads up to it.  a perch is a spawn that no other spawn can get to.  for the
// first item on it, look for a jump or rocket jump from somewhere the rest of the map reaches.
func (g *Gen) reachPerches() bool {
	var spawns []int
	for i, nd := range g.nodes {
		if nd.Spawn {
			spawns = append(spawns, i)
		}
	}
	added := false
	for _, s := range spawns {
		// what the other spawns can get to, and what is only this spawn's
		outside := map[int]bool{}
		for _, o := range spawns {
			if o == s {
				continue
			}
			for _, n := range g.reachFrom(o) {
				outside[n] = true
			}
		}
		if outside[s] {
			continue // not a perch
		}
		local := map[int]bool{}
		for _, n := range g.reachFrom(s) {
			if !outside[n] {
				local[n] = true
			}
		}
		for i, m := range g.items {
			if !local[m] || g.nodes[m].Launch {
				continue
			}
			best, flag := g.findLaunchFrom(g.nodes[m].Pos, outside)
			if best < 0 {
				continue
			}
			g.nodes = append(g.nodes, &Node{Pos: g.nodes[best].Pos, Launch: true, Flags: flag})
			l := len(g.nodes) - 1
			g.specials = append(g.specials, Special{best, l, 0}, Special{l, m, 0})
			g.Notes = append(g.Notes, fmt.Sprintf("%s on the spawn perch at %.0f %.0f %.0f can be reached by jumping from %.0f %.0f %.0f", g.itemName[i],
				g.nodes[m].Pos[0], g.nodes[m].Pos[1], g.nodes[m].Pos[2], g.nodes[best].Pos[0], g.nodes[best].Pos[1], g.nodes[best].Pos[2]))
			added = true
			break // one way up is enough
		}
	}
	return added
}

// centerNodes moves each ordinary waypoint toward the middle of the open space around it.  the
// fill puts waypoints wherever a walk ends, which in a hallway is often against a wall, and a
// bot following waypoints that alternate between the walls zigzags down the hall.  waypoints with
// a job to do (items, spawns, teleporters, plats, launch spots) stay put.
func (g *Gen) centerNodes() {
	fixed := map[int]bool{}
	for _, m := range g.items {
		fixed[m] = true
	}
	for _, t := range g.tele {
		fixed[t] = true
	}
	for _, sp := range g.specials {
		fixed[sp.From] = true
		fixed[sp.To] = true
	}
	for i, nd := range g.nodes {
		if nd.Spawn || nd.Launch || nd.Plat != nil {
			fixed[i] = true
		}
	}
	for pass := 0; pass < 3; pass++ {
		for i, nd := range g.nodes {
			if fixed[i] {
				continue
			}
			p := nd.Pos
			var free [8]float32
			for k := 0; k < 8; k++ {
				a := float64(k) * math.Pi / 4
				tr := g.mv.trace(p, Vec3{p[0] + float32(math.Cos(a))*64, p[1] + float32(math.Sin(a))*64, p[2]})
				if tr.StartSolid {
					free[k] = 0
				} else {
					free[k] = tr.Fraction * 64
				}
			}
			var shift [2]float32
			for k := 0; k < 4; k++ {
				diff := (free[k] - free[k+4]) / 2 // more room one way than the other
				a := float64(k) * math.Pi / 4
				shift[0] += float32(math.Cos(a)) * diff
				shift[1] += float32(math.Sin(a)) * diff
			}
			shift[0] *= 0.5
			shift[1] *= 0.5
			if l := float32(math.Hypot(float64(shift[0]), float64(shift[1]))); l > 24 {
				shift[0] *= 24 / l
				shift[1] *= 24 / l
			} else if l < 2 {
				continue
			}
			np := Vec3{p[0] + shift[0], p[1] + shift[1], p[2]}
			fl, ok := g.mv.Drop(Vec3{np[0], np[1], p[2] + stepHeight}, 2*stepHeight)
			if !ok || math.Abs(float64(fl[2]-p[2])) > stepHeight || !g.mv.Standing(fl) || g.mv.Deadly(fl) || g.inKeepout(fl) {
				continue
			}
			if tr := g.mv.trace(p, fl); tr.StartSolid || tr.Fraction < 1 {
				continue
			}
			if float64(g.nodeEdge(fl)) < math.Min(float64(g.nodeEdge(p)), 12) {
				continue // not toward a ledge
			}
			nd.Pos = fl
		}
	}
	g.cells = map[[3]int32][]int{}
	for i, nd := range g.nodes {
		c := cellOf(nd.Pos)
		g.cells[c] = append(g.cells[c], i)
	}
}

// teleFlight follows a player who leaves a teleporter destination in mid-air: 27 above the
// origin, at 300 along its angle, falling.  It reports where he lands, if it is a safe place.
func (g *Gen) teleFlight(o Vec3, angle float32) (Vec3, bool) {
	const dt = 1.0 / 60
	rad := float64(angle) * math.Pi / 180
	pos := Vec3{o[0], o[1], o[2] + 27}
	vel := Vec3{float32(math.Cos(rad)) * 300, float32(math.Sin(rad)) * 300, 0}
	if !g.mv.Empty(pos) {
		return pos, false
	}
	for t := 0; t < 240; t++ {
		vel[2] -= gravity * dt
		left := float32(dt)
		for bump := 0; bump < 4 && left > 0; bump++ {
			end := Vec3{pos[0] + vel[0]*left, pos[1] + vel[1]*left, pos[2] + vel[2]*left}
			tr := g.mv.trace(pos, end)
			if tr.StartSolid || g.mv.Deadly(tr.End) {
				return pos, false
			}
			pos = tr.End
			if tr.Fraction == 1 {
				break
			}
			if tr.Normal[2] >= floorSlope && vel[2] < 0 {
				return pos, true
			}
			left -= left * tr.Fraction
			dn := dot(vel, tr.Normal)
			vel = Vec3{vel[0] - tr.Normal[0]*dn, vel[1] - tr.Normal[1]*dn, vel[2] - tr.Normal[2]*dn}
		}
	}
	return pos, false
}
