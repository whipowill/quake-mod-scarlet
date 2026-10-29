package main

// Collision against the BSP clip hulls, ported from the Quake engine's
// SV_RecursiveHullCheck.  Hull 1 is already expanded by the standing player's box,
// so tracing a point through it is the same as moving the whole player.

const (
	contentsEmpty = -1
	contentsSolid = -2
	contentsWater = -3
	contentsSlime = -4
	contentsLava  = -5

	distEpsilon = 0.03125
)

type Trace struct {
	AllSolid   bool
	StartSolid bool
	Fraction   float32
	End        Vec3
	Normal     Vec3 // surface hit, zero when nothing was hit
}

func dot(a, b Vec3) float32 { return a[0]*b[0] + a[1]*b[1] + a[2]*b[2] }

func (b *BSP) planeDist(plane int32, p Vec3) float32 {
	pl := b.Planes[plane]
	return dot(pl.Normal, p) - pl.Dist
}

// HullContents is the contents value of the point p in the hull rooted at head.
func (b *BSP) HullContents(head int, p Vec3) int {
	num := head
	for num >= 0 {
		cn := b.Clipnodes[num]
		if b.planeDist(cn.Plane, p) < 0 {
			num = int(cn.Children[1])
		} else {
			num = int(cn.Children[0])
		}
	}
	return num
}

// HullTrace moves a point from start to end through the hull rooted at head.
func (b *BSP) HullTrace(head int, start, end Vec3) Trace {
	t := Trace{AllSolid: true, Fraction: 1, End: end}
	b.hullCheck(head, head, 0, 1, start, end, &t)
	if t.Fraction == 1 {
		t.End = end
	}
	return t
}

func (b *BSP) hullCheck(root, num int, p1f, p2f float32, p1, p2 Vec3, t *Trace) bool {
	if num < 0 {
		if num != contentsSolid {
			t.AllSolid = false
		} else {
			t.StartSolid = true
		}
		return true
	}

	cn := b.Clipnodes[num]
	t1 := b.planeDist(cn.Plane, p1)
	t2 := b.planeDist(cn.Plane, p2)
	if t1 >= 0 && t2 >= 0 {
		return b.hullCheck(root, int(cn.Children[0]), p1f, p2f, p1, p2, t)
	}
	if t1 < 0 && t2 < 0 {
		return b.hullCheck(root, int(cn.Children[1]), p1f, p2f, p1, p2, t)
	}

	// put the crosspoint distEpsilon units on the near side
	var frac float32
	if t1 < 0 {
		frac = (t1 + distEpsilon) / (t1 - t2)
	} else {
		frac = (t1 - distEpsilon) / (t1 - t2)
	}
	frac = clamp01(frac)
	midf := p1f + (p2f-p1f)*frac
	mid := lerp(p1, p2, frac)

	side := 0
	if t1 < 0 {
		side = 1
	}
	if !b.hullCheck(root, int(cn.Children[side]), p1f, midf, p1, mid, t) {
		return false
	}
	if b.HullContents(int(cn.Children[side^1]), mid) != contentsSolid {
		// the other side is open, keep going through it
		return b.hullCheck(root, int(cn.Children[side^1]), midf, p2f, mid, p2, t)
	}
	if t.AllSolid {
		return false // never got out of the solid area
	}

	// the other side of the node is solid, this is the impact point
	pl := b.Planes[cn.Plane]
	if side == 0 {
		t.Normal = pl.Normal
	} else {
		t.Normal = Vec3{-pl.Normal[0], -pl.Normal[1], -pl.Normal[2]}
	}
	for b.HullContents(root, mid) == contentsSolid {
		// shouldn't really happen, but does occasionally
		frac -= 0.1
		if frac < 0 {
			t.Fraction = midf
			t.End = mid
			return false
		}
		midf = p1f + (p2f-p1f)*frac
		mid = lerp(p1, p2, frac)
	}
	t.Fraction = midf
	t.End = mid
	return false
}

func clamp01(f float32) float32 {
	if f < 0 {
		return 0
	}
	if f > 1 {
		return 1
	}
	return f
}

func lerp(a, b Vec3, f float32) Vec3 {
	return Vec3{a[0] + (b[0]-a[0])*f, a[1] + (b[1]-a[1])*f, a[2] + (b[2]-a[2])*f}
}
