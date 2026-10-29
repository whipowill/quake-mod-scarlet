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
  trailgen [-force] [-v] [-o dir] [folder or map.bsp ...]
  trailgen dump <map.bsp>

With nothing to say, trailgen builds a trail for every map under the folder you run it
in, loose or inside a pak, and skips the ones that are already up to date.  "gen" in front
of the options does the same thing.

gen writes <map>.ent next to each map (or into -o dir).  A folder is searched
for .bsp files and .pak files all the way down, so pointing it at the Quake folder
builds every map there, including the ones inside paks (dm1-6, the single player
levels): those go in a maps folder next to the pak, where the game looks for them.
A map you give as a loose file beats the same map in a pak, like it does in the game.  An up to date .ent is skipped unless -force is given.
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
	outDir := fs.String("o", "", "write the .ent files here instead of next to each map")
	lift := fs.Float64("lift", 12, "how far above the player's origin waypoints sit (the old editor used 22)")
	force := fs.Bool("force", false, "rebuild even if the .ent is up to date")
	verbose = fs.Bool("v", false, "list what could not be reached")
	fs.Parse(args)
	paths := fs.Args()
	if len(paths) == 0 {
		paths = []string{"."}
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
	if !force && upToDate(outPath, hash, step, lift) {
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

	g := newGen(b, base, step)
	g.Lift = lift
	g.build()
	s := g.Stats
	stats := fmt.Sprintf("%d waypoints, %d spawns, %d teleporters, %d plats, %d rocket jumps", s.Kept, s.Seeds, s.Teleports, s.Plats, s.RJs)
	if s.KillZones > 0 {
		stats += fmt.Sprintf(", %d kill zones avoided", s.KillZones)
	}
	if err := os.MkdirAll(filepath.Dir(outPath), 0o755); err != nil {
		return false, err
	}
	if err := writeEnt(outPath, hash, step, lift, base, g.waypointEntities(), stats); err != nil {
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
