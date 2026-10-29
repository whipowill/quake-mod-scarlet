package main

import (
	"container/heap"
	"fmt"
	"math"
	"sort"
)

// The grid fill makes a dense web: hundreds of waypoints and links that run side by side down every
// hall, which gives a bot several near-equal ways to go and has it changing its mind as it walks.
// A person drawing a trail does it differently: a line that touches every item with as few lines as
// possible, with waypoints only at the joints.  skeleton does that to the finished web.
//
//  1. the key points are the waypoints that have a job: items, spawns, teleporters, plats and
//     launch spots;
//  2. each key point is joined only to its direct neighbours, the ones with no other key point on
//     the way, along the shortest path the web has;
//  3. each of those paths is pulled straight: every waypoint a bot could walk past, with a little
//     room to drift off the line, is dropped, so what is left are the corners and the joints.
//
// The web is only scaffolding: it is what proves a path can be walked.  If the skeleton would lose
// track of anything, the web is kept.

const (
	skelNear   = 64 // another key point this close to a path is on the way
	skelMargin = 10 // a straightened run must work this far to either side as well
	skelLoop   = 1.5
)

type skelEdge struct {
	from, to int
	cost     float32
	path     []int
}

// walkClear is true when a bot can walk straight from a to b, and keep walking if it drifts a
// little to either side.
func (g *Gen) walkClear(a, b Vec3) bool {
	d := hdist(a, b)
	if d < 1 {
		return true
	}
	dir := Vec3{(b[0] - a[0]) / d, (b[1] - a[1]) / d, 0}
	ok := func(from, to Vec3) bool {
		end, fell, ok := g.mv.Walk(from, dir, d, nil)
		return ok && !fell && hdist(end, to) <= 24 && math.Abs(float64(end[2]-to[2])) <= 20
	}
	if !ok(a, b) || !g.wideEnough(a, b) {
		return false
	}
	perp := Vec3{-dir[1], dir[0], 0}
	for _, s := range []float32{skelMargin, -skelMargin} {
		sa := Vec3{a[0] + perp[0]*s, a[1] + perp[1]*s, a[2]}
		sb := Vec3{b[0] + perp[0]*s, b[1] + perp[1]*s, b[2]}
		if !g.mv.Empty(sa) || !ok(sa, sb) {
			return false
		}
	}
	return true
}

// denseFrom is the shortest way from a to every waypoint along walked and fallen links.
func (g *Gen) denseFrom(a int) ([]float32, []int) {
	n := len(g.nodes)
	dist := make([]float32, n)
	prev := make([]int, n)
	for i := range dist {
		dist[i] = -1
		prev[i] = -1
	}
	dist[a] = 0
	h := &pq{{a, 0}}
	for h.Len() > 0 {
		it := heap.Pop(h).(pqItem)
		if it.d > dist[it.node] {
			continue
		}
		for _, l := range g.nodes[it.node].Links {
			if l.Flag != 0 || l.Fixed || !g.alive(l.To) {
				continue
			}
			nd := it.d + dist3(g.nodes[it.node].Pos, g.nodes[l.To].Pos)
			if dist[l.To] < 0 || nd < dist[l.To] {
				dist[l.To] = nd
				prev[l.To] = it.node
				heap.Push(h, pqItem{l.To, nd})
			}
		}
	}
	return dist, prev
}

// skeleton thins the finished web down to the joints.  it reports whether it did.
func (g *Gen) skeleton() bool {
	key := map[int]bool{}
	for _, m := range g.items {
		if g.alive(m) {
			key[m] = true
		}
	}
	for _, t := range g.tele {
		if g.alive(t) {
			key[t] = true
		}
	}
	for _, sp := range g.specials {
		for _, n := range []int{sp.From, sp.To} {
			if g.alive(n) {
				key[n] = true
			}
		}
	}
	for i, nd := range g.nodes {
		if g.alive(i) && (nd.Spawn || nd.Launch || nd.Plat != nil || nd.Flags != 0) {
			key[i] = true
		}
	}
	var keys []int
	for k := range key {
		keys = append(keys, k)
	}
	sort.Ints(keys)
	if len(keys) < 3 {
		return g.skelFail("fewer than three key points")
	}

	// which key points are near each waypoint
	near := make([][]int, len(g.nodes))
	for i, nd := range g.nodes {
		if !g.alive(i) {
			continue
		}
		for _, k := range keys {
			if hdist(nd.Pos, g.nodes[k].Pos) <= skelNear && math.Abs(float64(nd.Pos[2]-g.nodes[k].Pos[2])) < 48 {
				near[i] = append(near[i], k)
			}
		}
	}

	// direct neighbours: no other key point on the way
	var cands []skelEdge
	for _, u := range keys {
		dist, prev := g.denseFrom(u)
		for _, v := range keys {
			if v == u || dist[v] < 0 {
				continue
			}
			var path []int
			direct := true
			for n := v; n != -1; n = prev[n] {
				path = append(path, n)
				if n == u || n == v {
					continue
				}
				for _, k := range near[n] {
					if k == u || k == v {
						continue
					}
					// a key point right beside either end (two items side by side) isn't in the way
					if hdist(g.nodes[k].Pos, g.nodes[u].Pos) <= skelNear || hdist(g.nodes[k].Pos, g.nodes[v].Pos) <= skelNear {
						continue
					}
					direct = false
				}
			}
			if !direct {
				continue
			}
			for i, j := 0, len(path)-1; i < j; i, j = i+1, j-1 {
				path[i], path[j] = path[j], path[i]
			}
			cands = append(cands, skelEdge{u, v, dist[v], path})
		}
	}
	sort.SliceStable(cands, func(i, j int) bool { return cands[i].cost < cands[j].cost })

	// pick the lines: first enough to join everything, then the ones that make a useful loop
	parent := map[int]int{}
	var find func(int) int
	find = func(x int) int {
		if p, ok := parent[x]; ok && p != x {
			parent[x] = find(p)
			return parent[x]
		}
		parent[x] = x
		return x
	}
	chosen := map[[2]int]bool{}
	deg := map[int]int{}
	add := func(e skelEdge) {
		for _, d := range [][2]int{{e.from, e.to}, {e.to, e.from}} {
			if !chosen[d] && g.hasCand(cands, d[0], d[1]) {
				chosen[d] = true
				deg[d[0]]++
			}
		}
	}
	for _, e := range cands {
		if find(e.from) != find(e.to) {
			parent[find(e.from)] = find(e.to)
			add(e)
		}
	}
	adj := map[int][]skelEdge{}
	for d := range chosen {
		for _, e := range cands {
			if e.from == d[0] && e.to == d[1] {
				adj[d[0]] = append(adj[d[0]], e)
				break
			}
		}
	}
	for _, e := range cands {
		if chosen[[2]int{e.from, e.to}] || deg[e.from] >= 4 || deg[e.to] >= 4 {
			continue
		}
		if skelPath(adj, e.from, e.to) <= e.cost*skelLoop {
			continue
		}
		add(e)
		for _, d := range [][2]int{{e.from, e.to}, {e.to, e.from}} {
			if chosen[d] {
				for _, c := range cands {
					if c.from == d[0] && c.to == d[1] {
						adj[d[0]] = append(adj[d[0]], c)
						break
					}
				}
			}
		}
	}

	// straighten every chosen path and collect the waypoints that remain
	keep := map[int]bool{}
	for k := range key {
		keep[k] = true
	}
	links := map[int]map[int]bool{}
	addLink := func(a, b int) {
		if a == b {
			return
		}
		if links[a] == nil {
			links[a] = map[int]bool{}
		}
		links[a][b] = true
	}
	for _, es := range adj {
		for _, e := range es {
			p := e.path
			i := 0
			for i < len(p)-1 {
				// the furthest waypoint along the path that can be walked to straight, and no
				// further than the next fall
				limit := len(p) - 1
				for k := i; k < len(p)-1; k++ {
					if !g.canWalk(p[k], p[k+1]) {
						limit = k + 1
						break
					}
				}
				j := i + 1
				for t := limit; t > i+1; t-- {
					if g.walkClear(g.nodes[p[i]].Pos, g.nodes[p[t]].Pos) && !g.badSegment(p[i], p[t]) {
						j = t
						break
					}
				}
				keep[p[i]], keep[p[j]] = true, true
				addLink(p[i], p[j])
				i = j
			}
		}
	}

	// the special links stay as they were
	for i, nd := range g.nodes {
		if !keep[i] {
			continue
		}
		for _, l := range nd.Links {
			if (l.Flag != 0 || l.Fixed) && keep[l.To] {
				addLink(i, l.To)
			}
		}
	}

	// waypoints on top of each other become one: two paths that bend at the same corner each pick
	// their own web waypoint there, and a pile of them at one spot gives a bot dead ends to start from.
	// a key point is never merged into another key point
	merged := map[int]int{}
	var ks []int
	for k := range keep {
		ks = append(ks, k)
	}
	sort.Ints(ks)
	for i, a := range ks {
		if _, gone := merged[a]; gone {
			continue
		}
		for _, b := range ks[i+1:] {
			if _, gone := merged[b]; gone {
				continue
			}
			if hdist(g.nodes[a].Pos, g.nodes[b].Pos) > 24 || math.Abs(float64(g.nodes[a].Pos[2]-g.nodes[b].Pos[2])) > 20 {
				continue
			}
			switch {
			case key[a] && key[b]:
			case key[b]:
				merged[a] = b
			default:
				merged[b] = a
			}
			if _, gone := merged[a]; gone {
				break
			}
		}
	}
	if len(merged) > 0 {
		rep := func(x int) int {
			for {
				r, ok := merged[x]
				if !ok {
					return x
				}
				x = r
			}
		}
		fixed := map[int]map[int]bool{}
		for a, bs := range links {
			for b := range bs {
				ra, rb := rep(a), rep(b)
				if ra == rb {
					continue
				}
				if fixed[ra] == nil {
					fixed[ra] = map[int]bool{}
				}
				fixed[ra][rb] = true
			}
		}
		links = fixed
		for b := range merged {
			delete(keep, b)
		}
	}

	// no more than four links from a waypoint (that is all the mod stores).  a junction with more
	// gives up its longest line: that line's far end is joined to the nearest other waypoint that
	// can be walked to instead, if there is one, or the line simply goes if the others replace it
	for a := range links {
		for len(links[a]) > 4 {
			var worst, wd = -1, float32(0)
			for b := range links[a] {
				l := g.linkFor(a, b)
				if l.Flag != 0 || l.Fixed {
					continue
				}
				if d := dist3(g.nodes[a].Pos, g.nodes[b].Pos); d > wd {
					worst, wd = b, d
				}
			}
			if worst < 0 {
				return g.skelFail(fmt.Sprintf("waypoint at %.0f %.0f %.0f needs more than four special links", g.nodes[a].Pos[0], g.nodes[a].Pos[1], g.nodes[a].Pos[2]))
			}
			delete(links[a], worst)
			if skelReach(links, a, worst) {
				continue
			}
			// nothing else gets from here to there: give the far end another neighbour
			var best, bd = -1, float32(700)
			for c := range keep {
				if c == a || c == worst || len(links[c]) >= 4 || len(links[worst]) >= 4 {
					continue
				}
				d := dist3(g.nodes[worst].Pos, g.nodes[c].Pos)
				if d < bd && g.walkClear(g.nodes[worst].Pos, g.nodes[c].Pos) && g.walkClear(g.nodes[c].Pos, g.nodes[worst].Pos) {
					best, bd = c, d
				}
			}
			if best < 0 {
				links[a][worst] = true
				return g.skelFail(fmt.Sprintf("waypoint at %.0f %.0f %.0f has more than four lines and one can't be moved", g.nodes[a].Pos[0], g.nodes[a].Pos[1], g.nodes[a].Pos[2]))
			}
			addLink(worst, best)
			addLink(best, worst)
			delete(links[worst], a)
			// the line back the other way is now redundant too, if the new neighbour is reached from here
			if !skelReach(links, a, best) {
				addLink(a, best)
				if len(links[a]) > 4 {
					return g.skelFail("moving a line made another junction too busy")
				}
			}
		}
	}

	// every key point must still be reachable from a spawn and lead back to one
	if !g.skelSound(keep, links) {
		return false // skelSound says why
	}

	// replace the web
	old := make([][]Link, len(g.nodes))
	for i, nd := range g.nodes {
		old[i] = nd.Links
		nd.Links = nil
	}
	for a, bs := range links {
		var targets []int
		for b := range bs {
			targets = append(targets, b)
		}
		sort.Ints(targets)
		for _, b := range targets {
			l := Link{To: b}
			for _, o := range old[a] {
				if o.To == b && (o.Flag != 0 || o.Fixed) {
					l = o
				}
			}
			g.nodes[a].Links = append(g.nodes[a].Links, l)
		}
	}
	thinned := 0
	for i, nd := range g.nodes {
		if !keep[i] && !nd.Dead {
			nd.Dead = true
			nd.Thin = true
			thinned++
		}
	}
	g.Stats.Thinned = thinned
	g.Notes = append(g.Notes, fmt.Sprintf("skeleton: %d key points, %d waypoints kept, %d thinned out of the web", len(keys), len(keep), thinned))
	return true
}

func (g *Gen) hasCand(cands []skelEdge, a, b int) bool {
	for _, c := range cands {
		if c.from == a && c.to == b {
			return true
		}
	}
	return false
}

// linkFor is the link from a to b in the web (the zero link if there is none).
func (g *Gen) linkFor(a, b int) Link {
	for _, l := range g.nodes[a].Links {
		if l.To == b {
			return l
		}
	}
	return Link{To: b}
}

// skelPath is the length of the shortest way from a to b along the lines chosen so far.
func skelPath(adj map[int][]skelEdge, a, b int) float32 {
	best := map[int]float32{a: 0}
	h := &pq{{a, 0}}
	for h.Len() > 0 {
		it := heap.Pop(h).(pqItem)
		if it.node == b {
			return it.d
		}
		if it.d > best[it.node] {
			continue
		}
		for _, e := range adj[it.node] {
			nd := it.d + e.cost
			if d, ok := best[e.to]; !ok || nd < d {
				best[e.to] = nd
				heap.Push(h, pqItem{e.to, nd})
			}
		}
	}
	return float32(math.Inf(1))
}

// skelReach reports whether b can still be reached from a along links.
func skelReach(links map[int]map[int]bool, a, b int) bool {
	seen := map[int]bool{a: true}
	stack := []int{a}
	for len(stack) > 0 {
		n := stack[len(stack)-1]
		stack = stack[:len(stack)-1]
		if n == b {
			return true
		}
		for t := range links[n] {
			if !seen[t] {
				seen[t] = true
				stack = append(stack, t)
			}
		}
	}
	return false
}

// skelSound checks the thinned graph the way prune checks the web: everything kept must be
// reachable from a spawn and able to get back to one.
func (g *Gen) skelSound(keep map[int]bool, links map[int]map[int]bool) bool {
	back := map[int][]int{}
	for a, bs := range links {
		for b := range bs {
			back[b] = append(back[b], a)
		}
	}
	var spawns []int
	for i, nd := range g.nodes {
		if nd.Spawn && keep[i] {
			spawns = append(spawns, i)
		}
	}
	if len(spawns) == 0 {
		return g.skelFail("no spawn left")
	}
	flood := func(next func(int) []int) map[int]bool {
		seen := map[int]bool{}
		stack := append([]int(nil), spawns...)
		for _, s := range spawns {
			seen[s] = true
		}
		for len(stack) > 0 {
			n := stack[len(stack)-1]
			stack = stack[:len(stack)-1]
			for _, t := range next(n) {
				if !seen[t] {
					seen[t] = true
					stack = append(stack, t)
				}
			}
		}
		return seen
	}
	fwd := flood(func(n int) []int {
		var o []int
		for t := range links[n] {
			o = append(o, t)
		}
		return o
	})
	bwd := flood(func(n int) []int { return back[n] })
	for i := range g.nodes {
		if !keep[i] || !g.alive(i) {
			continue
		}
		if !fwd[i] || !bwd[i] {
			what := "can't be reached from a spawn"
			if fwd[i] && !bwd[i] {
				what = "can't get back to a spawn"
			} else if !fwd[i] && !bwd[i] {
				what = "has no way in or out"
			}
			return g.skelFail(fmt.Sprintf("the waypoint at %.0f %.0f %.0f %s", g.nodes[i].Pos[0], g.nodes[i].Pos[1], g.nodes[i].Pos[2], what))
		}
	}
	return true
}

// skelFail records why the web was kept.
func (g *Gen) skelFail(why string) bool {
	g.Notes = append(g.Notes, "skeleton: kept the full web because "+why)
	return false
}
