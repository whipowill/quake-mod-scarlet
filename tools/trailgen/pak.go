package main

import (
	"encoding/binary"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// A map to build: a loose .bsp file, or one inside a pak.
type mapSrc struct {
	name  string                 // the map's name, without maps/ or .bsp
	label string                 // what to call it in an error
	dir   string                 // the folder its .ent goes in: beside a loose map, the maps folder next to a pak
	loose bool                   // a loose file beats the same map in a pak, like it does in the game
	read  func() ([]byte, error) // the .bsp bytes
}

func looseSrc(path string) mapSrc {
	return mapSrc{
		name:  strings.TrimSuffix(filepath.Base(path), filepath.Ext(path)),
		label: path,
		dir:   filepath.Dir(path),
		loose: true,
		read:  func() ([]byte, error) { return os.ReadFile(path) },
	}
}

// pakSrcs lists the maps in a pak (the PACK format: a header, then a directory of 64 byte
// entries pointing at each file).  the brush models for items (maps/b_*.bsp) aren't maps.
func pakSrcs(path string) ([]mapSrc, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	if len(data) < 12 || string(data[0:4]) != "PACK" {
		return nil, fmt.Errorf("%s: not a pak file", path)
	}
	le := binary.LittleEndian
	off, n := int(le.Uint32(data[4:])), int(le.Uint32(data[8:]))
	if off < 12 || n < 0 || off+n > len(data) {
		return nil, fmt.Errorf("%s: bad pak directory", path)
	}
	var out []mapSrc
	for i := off; i+64 <= off+n; i += 64 {
		name := string(data[i : i+56])
		if z := strings.IndexByte(name, 0); z >= 0 {
			name = name[:z]
		}
		pos, size := int(le.Uint32(data[i+56:])), int(le.Uint32(data[i+60:]))
		low := strings.ToLower(name)
		base := filepath.Base(low)
		if !strings.HasPrefix(low, "maps/") || !strings.HasSuffix(low, ".bsp") || strings.HasPrefix(base, "b_") {
			continue
		}
		if pos < 0 || size < 0 || pos+size > len(data) {
			return nil, fmt.Errorf("%s: %s is outside the pak", path, name)
		}
		file := data[pos : pos+size]
		out = append(out, mapSrc{
			name:  strings.TrimSuffix(filepath.Base(name), filepath.Ext(name)),
			label: filepath.Base(path) + ":" + name,
			dir:   filepath.Join(filepath.Dir(path), "maps"),
			read:  func() ([]byte, error) { return file, nil },
		})
	}
	return out, nil
}
