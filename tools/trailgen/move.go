package main

// Player style movement on the static world, used to decide which waypoints can be
// linked.  All positions are the player's origin (24 above the floor when standing).

const (
	stepHeight = 18  // tallest step the player walks up without jumping
	maxFall    = 160 // longest drop a bot is sent over
	walkSub    = 16  // movement is checked in pieces this long
	floorSlope = 0.7 // steepest floor (as a normal's z) that can be stood on
)

// Floor is a surface that is not part of the static world, like the top of a plat.
type Floor struct {
	Min, Max [2]float32
	Z        float32 // player origin height when standing on it
}

// Box is a volume in the map.
type Box struct{ Min, Max Vec3 }

type Mover struct {
	b      *BSP
	head   int
	fall   float32 // longest drop for now; 0 means maxFall
	deadly []Box   // kill zones: hurt triggers and voids, which a bot must not touch
}

// deadlyMargin keeps waypoints and links this far clear of a kill zone, since the player's box
// only has to brush one to be hit.
const deadlyMargin = 8

// Deadly reports whether a standing player at p would touch a kill zone.
func (m *Mover) Deadly(p Vec3) bool {
	for _, b := range m.deadly {
		if p[0]+16+deadlyMargin > b.Min[0] && p[0]-16-deadlyMargin < b.Max[0] &&
			p[1]+16+deadlyMargin > b.Min[1] && p[1]-16-deadlyMargin < b.Max[1] &&
			p[2]+32 > b.Min[2] && p[2]-24 < b.Max[2] {
			return true
		}
	}
	return false
}

func (m *Mover) limit() float32 {
	if m.fall > 0 {
		return m.fall
	}
	return maxFall
}

func (m *Mover) trace(a, b Vec3) Trace { return m.b.HullTrace(m.head, a, b) }

func (m *Mover) Empty(p Vec3) bool { return m.b.HullContents(m.head, p) == contentsEmpty }

// Drop finds the floor below p, up to maxDown away.
func (m *Mover) Drop(p Vec3, maxDown float32) (Vec3, bool) {
	if !m.Empty(p) {
		return p, false
	}
	t := m.trace(p, Vec3{p[0], p[1], p[2] - maxDown})
	if t.StartSolid || t.Fraction == 1 || t.Normal[2] < floorSlope {
		return p, false
	}
	return t.End, true
}

// Standing reports whether p is an empty spot with floor right under it.
func (m *Mover) Standing(p Vec3) bool {
	if !m.Empty(p) {
		return false
	}
	t := m.trace(p, Vec3{p[0], p[1], p[2] - 2})
	return !t.StartSolid && t.Fraction < 1 && t.Normal[2] >= floorSlope
}

func (m *Mover) floorBelow(p Vec3, maxDown float32, vf *Floor) (Vec3, bool) {
	best, ok := m.Drop(p, maxDown)
	if vf != nil && p[0] >= vf.Min[0] && p[0] <= vf.Max[0] && p[1] >= vf.Min[1] && p[1] <= vf.Max[1] &&
		vf.Z <= p[2]+0.01 && vf.Z >= p[2]-maxDown {
		if !ok || vf.Z > best[2] {
			best = Vec3{p[0], p[1], vf.Z}
			ok = true
		}
	}
	return best, ok
}

// Walk moves from the standing spot from, along the horizontal direction dir, for dist
// units.  fell is true if the walk went off a ledge, in which case end is where the
// player lands just past the edge.  ok is false if something blocked the way, or there
// is no floor within maxFall below.  vf is an extra floor to treat as solid ground.
func (m *Mover) Walk(from, dir Vec3, dist float32, vf *Floor) (end Vec3, fell, ok bool) {
	pos := from
	for done := float32(0); done < dist-0.01; {
		d := dist - done
		if d > walkSub {
			d = walkSub
		}
		// walk straight on first.  stepping up before stepping forward fails under a low ceiling,
		// like a ramp up into a window recess, where a player simply walks on
		if flat := (Vec3{pos[0] + dir[0]*d, pos[1] + dir[1]*d, pos[2]}); true {
			if ft := m.trace(pos, flat); !ft.StartSolid && ft.Fraction == 1 {
				land, found := m.floorBelow(flat, m.limit(), vf)
				if found && m.Empty(land) && !m.Deadly(land) {
					if pos[2]-land[2] > stepHeight {
						return land, true, true
					}
					pos = land
					done += d
					continue
				}
			}
		}

		up := Vec3{pos[0], pos[1], pos[2] + stepHeight}
		ut := m.trace(pos, up)
		if ut.StartSolid {
			return pos, false, false
		}
		up = ut.End
		to := Vec3{up[0] + dir[0]*d, up[1] + dir[1]*d, up[2]}
		t := m.trace(up, to)
		if t.StartSolid || t.Fraction < 1 {
			return pos, false, false
		}
		land, found := m.floorBelow(to, stepHeight+m.limit()+(up[2]-pos[2]-stepHeight), vf)
		if !found || !m.Empty(land) || m.Deadly(land) {
			return pos, false, false
		}
		if pos[2]-land[2] > stepHeight {
			return land, true, true
		}
		pos = land
		done += d
	}
	return pos, false, true
}
