package main

import (
	"flag"
	"fmt"
	"math"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

const usage = `trailgen - builds bot trail files (.ent) for Quake maps

usage:
  trailgen                                  build every map under the current folder
  trailgen [-force] [-keep] [-v] [-mod name] [-o dir] [folder or map.bsp ...]
  trailgen dump <map.bsp>

With nothing to say, trailgen builds a trail for every map under the folder you run it
in, loose or inside a pak.  "gen" in front of the options does the same thing.

First it deletes the .ent files trailgen made earlier in the folders it is going to write to,
so maps you tried once and dropped don't leave files behind.  A .ent written by hand is never
deleted.  With -keep it leaves them and skips the maps whose .ent is already up to date.

gen writes <map>.ent into the mod folder's maps folder (scarlet/maps, or the folder named with -mod),
whatever folder or pak the map is in, or into -o dir.  trailgen stops with an error if there is no
mod folder.  A folder is searched
for .bsp files and .pak files all the way down, so pointing it at the Quake folder
builds every map there, including the ones inside paks (dm1-6, the single player levels).
A map you give as a loose file beats the same map in a pak, like it does in the game.  With -keep, an up to date .ent is skipped unless -force is given.
`

func main() {
	args := os.Args[1:]
	if len(args) > 0 {
		switch args[0] {
		case "help", "-h", "-help", "--help":
			fmt.Fprint(os.Stderr, usage)
			return
		case "dump":
			if len(args) != 2 {
				fmt.Fprint(os.Stderr, usage)
				os.Exit(2)
			}
			fail(dump(args[1]))
			return
		case "gen":
			args = args[1:]
		}
	}
	// anything else is for gen, and with no folder it builds the one it is run in
	fail(genCmd(args))
}

func fail(err error) {
	if err != nil {
		fmt.Fprintln(os.Stderr, "trailgen:", err)
		os.Exit(1)
	}
}

var verbose *bool

func genCmd(args []string) error {
	fs := flag.NewFlagSet("gen", flag.ExitOnError)
	step := fs.Float64("step", 256, "distance between waypoints, in units")
	outDir := fs.String("o", "", "write the .ent files here instead of into the mod folder")
	mod := fs.String("mod", "scarlet", "name of the mod folder the .ent files go into (maps/ inside it)")
	lift := fs.Float64("lift", 12, "how far above the player's origin waypoints sit (the old editor used 22)")
	force := fs.Bool("force", false, "rebuild even if the .ent is up to date")
	keep := fs.Bool("keep", false, "keep the .ent files trailgen made earlier and skip the maps they are up to date for (by default they are deleted first)")
	verbose = fs.Bool("v", false, "list what could not be reached")
	fs.Parse(args)
	paths := fs.Args()
	if len(paths) == 0 {
		paths = []string{"."}
	}

	// every trail goes into the mod folder, whatever folder or pak its map came from: the game looks
	// there first, and no engine's own entity files can override it.  Without the folder there is nowhere
	// safe to put them, so stop before anything is touched.  -o picks another place.
	if *outDir == "" {
		dir, err := findModFolder(*mod, paths)
		if err != nil {
			return err
		}
		*outDir = filepath.Join(dir, "maps")
		fmt.Printf("trails go into %s\n", *outDir)
	}

	// loose maps beat the same map in a pak, and a later pak beats an earlier one, like the game
	found := map[string]mapSrc{}
	add := func(m mapSrc) {
		key := filepath.Join(m.dir, m.name)
		if old, ok := found[key]; ok && old.loose && !m.loose {
			return
		}
		found[key] = m
	}
	addPak := func(path string) error {
		ms, err := pakSrcs(path)
		if err != nil {
			return err
		}
		for _, m := range ms {
			add(m)
		}
		return nil
	}
	for _, a := range paths {
		st, err := os.Stat(a)
		if err != nil {
			return err
		}
		if !st.IsDir() {
			if strings.EqualFold(filepath.Ext(a), ".pak") {
				if err := addPak(a); err != nil {
					return err
				}
			} else {
				add(looseSrc(a))
			}
			continue
		}
		filepath.WalkDir(a, func(path string, d os.DirEntry, err error) error {
			if err != nil || d.IsDir() {
				return nil
			}
			switch strings.ToLower(filepath.Ext(path)) {
			case ".bsp":
				add(looseSrc(path))
			case ".pak":
				if err := addPak(path); err != nil {
					fmt.Fprintln(os.Stderr, "trailgen:", err)
				}
			}
			return nil
		})
	}
	var maps []mapSrc
	for _, m := range found {
		maps = append(maps, m)
	}
	sort.Slice(maps, func(i, j int) bool {
		if maps[i].dir != maps[j].dir {
			return maps[i].dir < maps[j].dir
		}
		return maps[i].name < maps[j].name
	})
	if len(maps) == 0 {
		return fmt.Errorf("no .bsp files found")
	}

	if !*keep {
		dirs := map[string]bool{}
		for _, m := range maps {
			if *outDir != "" {
				dirs[*outDir] = true
			} else {
				dirs[m.dir] = true
			}
		}
		removed := 0
		for d := range dirs {
			removed += removeGenerated(d, func(string) bool { return true })
		}
		fmt.Printf("removed %d .ent files trailgen made earlier (hand made ones are left alone)\n", removed)
	}

	built, current, failed := 0, 0, 0
	for i, m := range maps {
		progress = fmt.Sprintf("[%d/%d %3d%%] ", i+1, len(maps), (i+1)*100/len(maps))
		did, err := genMap(m, *outDir, float32(*step), float32(*lift), *force)
		switch {
		case err != nil:
			fmt.Fprintf(os.Stderr, "%s%s: %v\n", progress, m.label, err)
			failed++
		case did:
			built++
		default:
			current++
		}
	}
	fmt.Printf("%d maps: %d built, %d already up to date, %d failed\n", len(maps), built, current, failed)
	if failed > 0 {
		return fmt.Errorf("%d of %d maps failed", failed, len(maps))
	}
	return nil
}

// progress is the "[3/57  5%]" shown before each map's line
var progress string

// genMap builds one map's .ent.  built is false when the .ent was already up to date.
func genMap(src mapSrc, outDir string, step, lift float32, force bool) (built bool, err error) {
	name := src.name
	dir := src.dir
	outPath := filepath.Join(dir, name+".ent")
	if outDir != "" {
		outPath = filepath.Join(outDir, name+".ent")
	}

	raw, err := src.read()
	if err != nil {
		return false, err
	}
	hash := hashBytes(raw)
	atPath := checksumEntPath(outPath, name, raw)
	if _, statErr := os.Stat(atPath); !force && statErr == nil && upToDate(outPath, hash, step, lift) {
		fmt.Printf("%s%-16s up to date\n", progress, name)
		return false, nil
	}

	b, err := ParseBSP(src.label, raw)
	if err != nil {
		return false, err
	}
	if len(b.Models) == 0 || len(b.Clipnodes) == 0 {
		return false, fmt.Errorf("no collision data")
	}

	// entities the map already has: a hand made .ent beside the map wins over the BSP's own
	// list.  one of our own outputs never counts, the original is kept as .ent.orig
	baseText := b.Entities
	// an engine that ships a fixed entity list for this map (vkQuake, Quakespasm) gets its fixes kept
	if t, ok := engineEnts[filepath.Base(atPath)]; ok {
		baseText = t
	}
	orig := filepath.Join(filepath.Dir(outPath), name+".ent.orig")
	for _, cand := range []string{orig, filepath.Join(dir, name+".ent")} {
		data, err := os.ReadFile(cand)
		if err != nil {
			continue
		}
		if isGenerated(data) {
			continue
		}
		baseText = string(data)
		if cand != orig && outPath == cand {
			if err := os.WriteFile(orig, data, 0o644); err != nil {
				return false, err
			}
		}
		break
	}
	all, err := ParseEntities(baseText)
	if err != nil {
		return false, err
	}
	var base []*Entity
	for _, e := range all {
		if e.Class() != "waypoint" {
			base = append(base, e)
		}
	}

	// doors that a walk-in trigger opens count as walls until a bot can reach the trigger.  scouting where
	// bots can walk is quick, so do that for as long as it opens another door, then build the trail once
	open := map[int]bool{}
	for pass := 0; pass < 8; pass++ {
		scout := newGen(b, cloneEntities(base), step, open)
		scout.scout()
		if !scout.openDoors(open) {
			break
		}
	}
	g := newGen(b, cloneEntities(base), step, open)
	g.Lift = lift
	g.build()
	s := g.Stats
	stats := fmt.Sprintf("%d waypoints, %d spawns, %d teleporters, %d plats, %d rocket jumps", s.Kept, s.Seeds, s.Teleports, s.Plats, s.RJs)
	if s.ShutDoors > 0 {
		stats += fmt.Sprintf(", %d shut doors treated as walls", s.ShutDoors)
	}
	if s.KillZones > 0 {
		stats += fmt.Sprintf(", %d kill zones avoided", s.KillZones)
	}
	if err := os.MkdirAll(filepath.Dir(outPath), 0o755); err != nil {
		return false, err
	}
	// this map's old files go first, so nothing stale is left under a checksum name the map no longer has
	removeGenerated(filepath.Dir(outPath), func(n string) bool {
		return n == name+".ent" || strings.HasPrefix(n, name+"@")
	})
	if err := writeEnt(outPath, hash, step, lift, g.ents, g.waypointEntities(), stats); err != nil {
		return false, err
	}
	if err := writeEnt(atPath, hash, step, lift, g.ents, g.waypointEntities(), stats); err != nil {
		return false, err
	}
	fmt.Printf("%s%-16s %s\n", progress, name, stats)
	fmt.Printf("%s%-16s items: %d total, %d on foot, %d by jump or rocket jump; dropped %d waypoints as traps and %d from the web; route stretch mean %.2f p90 %.2f\n", strings.Repeat(" ", len(progress)), "", s.ItemsTotal, s.ItemsOnFoot, s.ItemsRJ, s.Dead, s.Thinned, s.StretchMean, s.StretchP90)
	if *verbose {
		for _, n := range g.Notes {
			fmt.Printf("%s%-16s %s\n", strings.Repeat(" ", len(progress)), "", n)
		}
	}
	return true, nil
}

// interesting entities for pathing: how bots get between floors and areas
var pathClasses = map[string]bool{
	"func_plat": true, "func_door": true, "func_door_secret": true, "func_train": true,
	"trigger_teleport": true, "info_teleport_destination": true, "trigger_push": true,
	"func_button": true, "path_corner": true, "misc_teleporttrain": true,
	"info_player_start": true, "info_player_deathmatch": true, "info_player_coop": true,
}

func dump(path string) error {
	b, err := LoadBSP(path)
	if err != nil {
		return err
	}
	ents, err := ParseEntities(b.Entities)
	if err != nil {
		return err
	}

	fmt.Printf("%s\n", path)
	fmt.Printf("  %d entities, %d models, %d faces, %d vertices\n", len(ents), len(b.Models), len(b.Faces), len(b.Vertices))

	floors, area := 0, 0.0
	for _, f := range b.Faces {
		n := b.FaceNormal(f)
		if n[2] >= 0.7 {
			floors++
			area += faceArea(b.FaceVerts(f))
		}
	}
	fmt.Printf("  %d floor faces, %.0f square units\n", floors, area)

	counts := map[string]int{}
	for _, e := range ents {
		counts[e.Class()]++
	}
	var names []string
	for k := range counts {
		if pathClasses[k] {
			names = append(names, k)
		}
	}
	sort.Strings(names)
	fmt.Println("  entities that matter for pathing:")
	for _, k := range names {
		fmt.Printf("    %-28s %d\n", k, counts[k])
	}
	return nil
}

func faceArea(v []Vec3) float64 {
	var sx, sy, sz float64
	for i := range v {
		a, c := v[i], v[(i+1)%len(v)]
		sx += float64(a[1])*float64(c[2]) - float64(a[2])*float64(c[1])
		sy += float64(a[2])*float64(c[0]) - float64(a[0])*float64(c[2])
		sz += float64(a[0])*float64(c[1]) - float64(a[1])*float64(c[0])
	}
	return math.Sqrt(sx*sx+sy*sy+sz*sz) / 2
}

// findModFolder looks for the mod's folder by name inside each folder trailgen was pointed at (the current
// folder when there are none), and in the current folder itself.  It is an error when there is no such folder.
func findModFolder(name string, paths []string) (string, error) {
	var tried []string
	cands := []string{}
	for _, p := range paths {
		if st, err := os.Stat(p); err == nil && st.IsDir() {
			cands = append(cands, filepath.Join(p, name))
		}
	}
	cands = append(cands, name)
	seen := map[string]bool{}
	for _, c := range cands {
		if st, err := os.Stat(c); err == nil && st.IsDir() {
			return c, nil
		}
		if !seen[c] {
			seen[c] = true
			tried = append(tried, c)
		}
	}
	return "", fmt.Errorf("can't find the %q mod folder (looked for %s).  Run trailgen from your Quake folder, the one that holds id1 and %s, or name the folder with -mod, or choose where the files go with -o", name, strings.Join(tried, ", "), name)
}
