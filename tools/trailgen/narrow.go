package main

import (
	"fmt"
	"image"
	"image/color"
	"image/png"
	"math"
	"os"
	"sort"
)

// narrowReport (TRAILGEN_NARROW=1) measures how much floor there is either side of every
// walk link, so the narrowest walkways can be looked at.  The hull is 32 wide, so a hull
// moved sideways still touches the floor until its edge passes the walkway's edge:
// half-width = the furthest sideways offset that still touches floor, less 16.
func (g *Gen) narrowReport() {
	type worst struct {
		a, b  int
		hw    float32
		at    Vec3
		aSide string
	}
	var all []worst
	for a, na := range g.nodes {
		for _, l := range na.Links {
			if l.Flag != 0 || l.Fixed || l.To < a {
				continue
			}
			nb := g.nodes[l.To]
			d := hdist(na.Pos, nb.Pos)
			if d < 8 || !g.canWalk(a, l.To) {
				continue
			}
			dir := Vec3{(nb.Pos[0] - na.Pos[0]) / d, (nb.Pos[1] - na.Pos[1]) / d, 0}
			perp := Vec3{-dir[1], dir[0], 0}
			min := float32(99)
			var at Vec3
			for s := float32(0); s <= d; s += 8 {
				t := s / d
				p := Vec3{na.Pos[0] + (nb.Pos[0]-na.Pos[0])*t, na.Pos[1] + (nb.Pos[1]-na.Pos[1])*t, na.Pos[2] + (nb.Pos[2]-na.Pos[2])*t}
				// stairs and ramps aren't straight lines, so stand the sample on the real floor
				f, ok := g.mv.Drop(Vec3{p[0], p[1], p[2] + stepHeight}, stepHeight+40)
				if !ok {
					continue
				}
				p = f
				for _, sg := range []float32{1, -1} {
					h := g.sideHalfWidth(p, perp, sg)
					if h < min {
						min, at = h, p
					}
				}
			}
			all = append(all, worst{a, l.To, min, at, ""})
		}
	}
	sort.Slice(all, func(i, j int) bool { return all[i].hw < all[j].hw })
	bins := []float32{4, 8, 12, 16, 24}
	cnt := make([]int, len(bins)+1)
	for _, w := range all {
		i := 0
		for i < len(bins) && w.hw >= bins[i] {
			i++
		}
		cnt[i]++
	}
	fmt.Printf("walk links by narrowest half-width: <4:%d <8:%d <12:%d <16:%d <24:%d wider:%d (of %d)\n", cnt[0], cnt[1], cnt[2], cnt[3], cnt[4], cnt[5], len(all))
	for i, w := range all {
		if i >= 12 || w.hw >= 16 {
			break
		}
		fmt.Printf("  half-width %2.0f at %.0f %.0f %.0f  (link %d-%d)\n", w.hw, w.at[0], w.at[1], w.at[2], w.a, w.b)
	}
}

// sideHalfWidth walks sideways from p (sign sg) and returns how far the floor reaches
// beyond the centre line; a wall counts as safe.
func (g *Gen) sideHalfWidth(p, perp Vec3, sg float32) float32 {
	for off := float32(0); off <= 48; off += 2 {
		q := Vec3{p[0] + perp[0]*sg*off, p[1] + perp[1]*sg*off, p[2]}
		if !g.mv.Empty(q) {
			return 99 // a wall
		}
		t := g.mv.trace(q, Vec3{q[0], q[1], q[2] - (stepHeight + 2)})
		if t.StartSolid {
			return 99
		}
		if t.Fraction == 1 {
			h := off - 2 - 16
			if h < 0 {
				h = 0
			}
			return float32(math.Max(float64(h), 0))
		}
	}
	return 99
}

// wideEnough is true when there is at least minHalfWidth of floor (or a wall) either side of
// the straight walk from a to b.  The hull is 32 wide, so a hull shifted 16+minHalfWidth sideways
// still touching floor means the floor reaches minHalfWidth past the centre line.  Bots wobble, so
// a link along an edge is one they fall off.
func (g *Gen) wideEnough(a, b Vec3) bool {
	d := hdist(a, b)
	if d < 1 {
		return true
	}
	dir := Vec3{(b[0] - a[0]) / d, (b[1] - a[1]) / d, 0}
	perp := Vec3{-dir[1], dir[0], 0}
	off := 16 + float32(minHalfWidth)
	for s := float32(0); s <= d; s += 8 {
		t := s / d
		p := Vec3{a[0] + (b[0]-a[0])*t, a[1] + (b[1]-a[1])*t, a[2] + (b[2]-a[2])*t}
		f, ok := g.mv.Drop(Vec3{p[0], p[1], p[2] + stepHeight}, stepHeight+40)
		if !ok {
			continue
		}
		for _, sg := range []float32{1, -1} {
			q := Vec3{f[0] + perp[0]*sg*off, f[1] + perp[1]*sg*off, f[2]}
			if !g.mv.Empty(q) {
				continue // a wall
			}
			t := g.mv.trace(q, Vec3{q[0], q[1], q[2] - (stepHeight + 2)})
			if !t.StartSolid && t.Fraction == 1 {
				return false
			}
		}
	}
	return true
}

// probeMap (TRAILGEN_PROBE="x,y,z") prints which spots around a point a hull can stand on.
func (g *Gen) probeMap(x, y, z float32) {
	for dy := float32(64); dy >= -64; dy -= 8 {
		line := ""
		for dx := float32(-96); dx <= 96; dx += 4 {
			q := Vec3{x + dx, y + dy, z}
			switch {
			case !g.mv.Empty(q):
				line += "#"
			default:
				t := g.mv.trace(q, Vec3{q[0], q[1], q[2] - (stepHeight + 2)})
				if !t.StartSolid && t.Fraction < 1 {
					line += "."
				} else {
					line += " "
				}
			}
		}
		fmt.Printf("%5.0f %s\n", y+dy, line)
	}
}

// nodeEdge is how far from the centre of the waypoint the floor runs out, the nearest direction.
func (g *Gen) nodeEdge(p Vec3) float32 {
	min := float32(99)
	for _, d := range spreadDirs {
		if h := g.sideHalfWidth(p, d, 1); h < min {
			min = h
		}
	}
	return min
}

func (g *Gen) nodeEdgeReport() {
	bins := []float32{1, 4, 8, 12, 16}
	cnt := make([]int, len(bins)+1)
	for _, n := range g.nodes {
		h := g.nodeEdge(n.Pos)
		i := 0
		for i < len(bins) && h >= bins[i] {
			i++
		}
		cnt[i]++
	}
	fmt.Printf("waypoints by floor beyond them in the nearest direction: <1:%d <4:%d <8:%d <12:%d <16:%d more:%d (of %d)\n", cnt[0], cnt[1], cnt[2], cnt[3], cnt[4], cnt[5], len(g.nodes))
}

// whyUnreachable (TRAILGEN_WHY="x,y,z") lists the usable waypoints near a spot and whether a
// jump from each could land on it.
func (g *Gen) whyUnreachable(f Vec3) {
	land, ok := g.mv.Drop(Vec3{f[0], f[1], f[2] + 8}, 64)
	fmt.Printf("target %.0f %.0f %.0f standing spot found: %v (%.0f %.0f %.0f)\n", f[0], f[1], f[2], ok, land[0], land[1], land[2])
	if ok {
		f = land
	}
	n := 0
	for u, nu := range g.nodes {
		if !(nu.Reach && nu.Home) || nu.Launch {
			continue
		}
		d := hdist(nu.Pos, f)
		rise := f[2] - nu.Pos[2]
		if d > 450 || rise < 0 || rise > 400 {
			continue
		}
		fmt.Printf("  wp %3d at %5.0f %5.0f %5.0f  side %3.0f rise %3.0f  vz600:%v vz700:%v vz800:%v\n", u, nu.Pos[0], nu.Pos[1], nu.Pos[2], d, rise,
			g.rocketJump(nu.Pos, f, 600), g.rocketJump(nu.Pos, f, 700), g.rocketJump(nu.Pos, f, 800))
		n++
	}
	fmt.Println(n, "candidate waypoints")
}

// sliceMap (TRAILGEN_SLICE="x,y,z") prints a side view along y at a fixed x: '.' is where the
// player's box fits, '#' is where it doesn't.  height is up the page, y runs left to right.
func (g *Gen) sliceMap(x, y, z float32) {
	for dz := float32(160); dz >= -64; dz -= 8 {
		line := ""
		for dy := float32(-160); dy <= 240; dy += 4 {
			if g.mv.Empty(Vec3{x, y + dy, z + dz}) {
				line += "."
			} else {
				line += "#"
			}
		}
		fmt.Printf("%5.0f %s\n", z+dz, line)
	}
	fmt.Printf("      y from %.0f to %.0f, 4 units a column\n", y-160, y+240)
}

// linkCheck (TRAILGEN_CHECK=1) tests every link against the map: how long it is, and whether the
// straight line between its ends is blocked for the player's box.  a walked link may bend with the
// floor, so a blocked line is only a hint; a long one that is blocked is the kind that cuts corners.
func (g *Gen) linkCheck() {
	type bad struct {
		a, b   int
		length float32
		frac   float32
	}
	var blocked []bad
	var small []string
	shaft := 0
	var lens []float32
	total, special, fall := 0, 0, 0
	for a, na := range g.nodes {
		for _, l := range na.Links {
			total++
			nb := g.nodes[l.To]
			if l.Flag != 0 || l.Fixed || na.Launch || nb.Launch {
				special++
				continue
			}
			if g.badSegment(a, l.To) {
				shaft++
			}
			d := dist3(na.Pos, nb.Pos)
			lens = append(lens, d)
			if !g.canWalk(a, l.To) {
				fall++
				if drop := na.Pos[2] - nb.Pos[2]; drop > 0 && drop <= 40 {
					small = append(small, fmt.Sprintf("  a drop of only %.0f: (%.0f %.0f %.0f) to (%.0f %.0f %.0f)", drop, na.Pos[0], na.Pos[1], na.Pos[2], nb.Pos[0], nb.Pos[1], nb.Pos[2]))
				}
				continue
			}
			// walk along the link and look for floor under every point, at about the right height
			hd := hdist(na.Pos, nb.Pos)
			off := false
			for t := float32(0); t <= hd; t += 8 {
				f := t / hd
				if hd < 1 {
					f = 0
				}
				p := Vec3{na.Pos[0] + (nb.Pos[0]-na.Pos[0])*f, na.Pos[1] + (nb.Pos[1]-na.Pos[1])*f, na.Pos[2] + (nb.Pos[2]-na.Pos[2])*f}
				fl, ok := g.mv.Drop(Vec3{p[0], p[1], p[2] + stepHeight + 24}, 24+stepHeight+60)
				if !ok || math.Abs(float64(fl[2]-p[2])) > 40 {
					off = true
					break
				}
			}
			if off {
				blocked = append(blocked, bad{a, l.To, d, 0})
			}
		}
	}
	for i, nd := range g.nodes {
		if nd.Plat == nil {
			continue
		}
		in := 0
		for _, o := range g.nodes {
			for _, l := range o.Links {
				if l.To == i {
					in++
				}
			}
		}
		fmt.Printf("  plat waypoint %d at (%.0f %.0f %.0f): %d links in, %d out:", i, nd.Pos[0], nd.Pos[1], nd.Pos[2], in, len(nd.Links))
		for _, l := range nd.Links {
			fmt.Printf(" %d(%.0f,%.0f,%.0f%s)", l.To, g.nodes[l.To].Pos[0], g.nodes[l.To].Pos[1], g.nodes[l.To].Pos[2], map[bool]string{true: ",plat link", false: ""}[l.Fixed])
		}
		fmt.Println()
	}
	fmt.Printf("links that cross a plat shaft without starting or ending on the plat: %d\n", shaft)
	fmt.Printf("fall links with a drop of 40 or less (a bot only steps off a ledge on purpose for more than 32): %d\n", len(small))
	for i, m := range small {
		if i >= 12 {
			break
		}
		fmt.Println(m)
	}
	sort.Slice(lens, func(i, j int) bool { return lens[i] < lens[j] })
	med, p90, max := float32(0), float32(0), float32(0)
	if len(lens) > 0 {
		med, p90, max = lens[len(lens)/2], lens[len(lens)*9/10], lens[len(lens)-1]
	}
	fmt.Printf("links: %d total, %d special (teleport, jump, plat), %d falls, %d walked; length median %.0f p90 %.0f max %.0f\n", total, special, fall, len(lens)-fall, med, p90, max)
	fmt.Printf("walked links with no floor under part of them: %d of %d\n", len(blocked), len(lens)-fall)
	sort.Slice(blocked, func(i, j int) bool { return blocked[i].length > blocked[j].length })
	for i, b := range blocked {
		if i >= 8 {
			break
		}
		pa, pb := g.nodes[b.a].Pos, g.nodes[b.b].Pos
		fmt.Printf("  %4.0f long: (%.0f %.0f %.0f) to (%.0f %.0f %.0f)\n", b.length, pa[0], pa[1], pa[2], pb[0], pb[1], pb[2])
	}
}

// drawGraph (TRAILGEN_IMAGE=file.png) draws the map from above: the floors a player can stand on
// in grey, the links in colour (short blue, medium green, long orange, teleporters red) and the
// waypoints as white dots.
func (g *Gen) drawGraph(path string) {
	m0 := g.b.Models[0]
	const cell, scale = 8, 4 // a floor sample every 8 units, 4 units to a pixel
	w := int((m0.Maxs[0]-m0.Mins[0])/scale) + 1
	h := int((m0.Maxs[1]-m0.Mins[1])/scale) + 1
	img := image.NewRGBA(image.Rect(0, 0, w, h))
	for i := range img.Pix {
		img.Pix[i] = 0
	}
	for y := 0; y < h; y++ {
		for x := 0; x < w; x++ {
			img.Set(x, y, color.RGBA{20, 20, 24, 255})
		}
	}
	px := func(p Vec3) (int, int) {
		return int((p[0] - m0.Mins[0]) / scale), h - 1 - int((p[1]-m0.Mins[1])/scale)
	}
	for wy := m0.Mins[1]; wy < m0.Maxs[1]; wy += cell {
		for wx := m0.Mins[0]; wx < m0.Maxs[0]; wx += cell {
			for z := m0.Mins[2]; z < m0.Maxs[2]; z += 24 {
				if g.mv.Standing(Vec3{wx, wy, z}) {
					x, y := px(Vec3{wx, wy, z})
					img.Set(x, y, color.RGBA{70, 70, 78, 255})
					break
				}
			}
		}
	}
	line := func(a, b Vec3, c color.RGBA) {
		x0, y0 := px(a)
		x1, y1 := px(b)
		n := int(math.Max(math.Abs(float64(x1-x0)), math.Abs(float64(y1-y0)))) + 1
		for i := 0; i <= n; i++ {
			t := float64(i) / float64(n)
			img.Set(x0+int(float64(x1-x0)*t), y0+int(float64(y1-y0)*t), c)
		}
	}
	for _, na := range g.nodes {
		for _, l := range na.Links {
			nb := g.nodes[l.To]
			d := hdist(na.Pos, nb.Pos)
			c := color.RGBA{60, 120, 255, 255}
			switch {
			case l.Flag != 0:
				c = color.RGBA{255, 40, 40, 255}
			case d > 500:
				c = color.RGBA{255, 160, 40, 255}
			case d > 200:
				c = color.RGBA{60, 220, 90, 255}
			}
			line(na.Pos, nb.Pos, c)
		}
	}
	for _, n := range g.nodes {
		x, y := px(n.Pos)
		for dy := -1; dy <= 1; dy++ {
			for dx := -1; dx <= 1; dx++ {
				img.Set(x+dx, y+dy, color.RGBA{255, 255, 255, 255})
			}
		}
	}
	f, err := os.Create(path)
	if err != nil {
		fmt.Println(err)
		return
	}
	defer f.Close()
	png.Encode(f, img)
	fmt.Printf("drew %dx%d picture to %s\n", w, h, path)
}

// wallClearance is how far a standing player at p can move in the nearest direction before the
// box touches a wall (of 8 directions, looking up to 64 units).
func (g *Gen) wallClearance(p Vec3) float32 {
	min := float32(64)
	for i := 0; i < 8; i++ {
		a := float64(i) * math.Pi / 4
		d := Vec3{float32(math.Cos(a)) * 64, float32(math.Sin(a)) * 64, 0}
		tr := g.mv.trace(p, Vec3{p[0] + d[0], p[1] + d[1], p[2]})
		if tr.StartSolid {
			return 0
		}
		if f := tr.Fraction * 64; f < min {
			min = f
		}
	}
	return min
}

func (g *Gen) clearanceReport() {
	bins := []float32{4, 12, 24, 48}
	cnt := make([]int, len(bins)+1)
	for _, n := range g.nodes {
		c := g.wallClearance(n.Pos)
		i := 0
		for i < len(bins) && c >= bins[i] {
			i++
		}
		cnt[i]++
	}
	fmt.Printf("waypoints by room to move before touching a wall: <4:%d <12:%d <24:%d <48:%d more:%d (of %d)\n", cnt[0], cnt[1], cnt[2], cnt[3], cnt[4], len(g.nodes))
}

// seeMap (TRAILGEN_SEE="x,y,z") lists the nearest waypoints to a spot and whether the player's box
// can see each one, since a bot finds its place in the trail by the nearest waypoint it can see.
func (g *Gen) seeMap(p Vec3) {
	type item struct {
		n int
		d float32
	}
	var near []item
	for i, nd := range g.nodes {
		near = append(near, item{i, dist3(p, nd.Pos)})
	}
	sort.Slice(near, func(i, j int) bool { return near[i].d < near[j].d })
	seen := 0
	for k, it := range near {
		nd := g.nodes[it.n]
		tr := g.mv.trace(p, nd.Pos)
		vis := !tr.StartSolid && tr.Fraction == 1
		if vis {
			seen++
		}
		if k < 8 {
			fmt.Printf("  waypoint %3d at (%5.0f %5.0f %5.0f) %4.0f away, seen: %v\n", it.n, nd.Pos[0], nd.Pos[1], nd.Pos[2], it.d, vis)
		}
	}
	fmt.Printf("%d of %d waypoints can be seen from there\n", seen, len(g.nodes))
}
