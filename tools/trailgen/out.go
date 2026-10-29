package main

import (
	"bytes"
	"crypto/sha256"
	"encoding/binary"
	"encoding/hex"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

// genVersion is bumped whenever the generator's output would change for the same map.
// A .ent made by another version is rebuilt.
const genVersion = 23

const headerPrefix = "// trailgen "

func fmtNum(f float32) string { return strconv.FormatFloat(float64(f), 'f', -1, 32) }

func hashBytes(b []byte) string {
	s := sha256.Sum256(b)
	return hex.EncodeToString(s[:])
}

// the header says what the file was made from, so a change to the map, to the generator
// or to the settings (spacing, lift) all count as stale
func header(hash string, step, lift float32) string {
	return fmt.Sprintf("%sv%d bsp=%s step=%s lift=%s\n", headerPrefix, genVersion, hash, fmtNum(step), fmtNum(lift))
}

// upToDate reports whether the .ent at path was made by this generator version from a
// BSP with this hash.
func upToDate(path, hash string, step, lift float32) bool {
	data, err := os.ReadFile(path)
	if err != nil {
		return false
	}
	first, _, _ := strings.Cut(string(data), "\n")
	return strings.TrimSpace(first) == strings.TrimSpace(header(hash, step, lift))
}

func isGenerated(data []byte) bool { return strings.HasPrefix(string(data), headerPrefix) }

func writeEnt(path, hash string, step, lift float32, base, ways []*Entity, stats string) error {
	var sb strings.Builder
	sb.WriteString(header(hash, step, lift))
	sb.WriteString("// " + stats + "\n")
	for _, group := range [][]*Entity{base, ways} {
		for _, e := range group {
			sb.WriteString("{\n")
			for i, k := range e.Keys {
				sb.WriteString("\"" + k + "\" \"" + e.Vals[i] + "\"\n")
			}
			sb.WriteString("}\n")
		}
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	return os.WriteFile(path, []byte(sb.String()), 0o644)
}

// crc16 is the checksum Quake engines (vkQuake, Quakespasm) put in an entity file's name: CRC-16/CCITT-FALSE.
func crc16(b []byte) uint16 {
	crc := uint16(0xffff)
	for _, c := range b {
		crc ^= uint16(c) << 8
		for i := 0; i < 8; i++ {
			if crc&0x8000 != 0 {
				crc = crc<<1 ^ 0x1021
			} else {
				crc <<= 1
			}
		}
	}
	return crc
}

// entityText is the entity lump of a BSP file, up to its first NUL.
func entityText(bsp []byte) []byte {
	if len(bsp) < 12 {
		return nil
	}
	ofs := int(binary.LittleEndian.Uint32(bsp[4:8]))
	n := int(binary.LittleEndian.Uint32(bsp[8:12]))
	if ofs < 0 || n < 0 || ofs+n > len(bsp) {
		return nil
	}
	t := bsp[ofs : ofs+n]
	if i := bytes.IndexByte(t, 0); i >= 0 {
		t = t[:i]
	}
	return t
}

// checksumEntPath is the second name a map's .ent is saved under, <map>@<crc>.ent, where the checksum is that of
// the map's own entity text.  vkQuake and Quakespasm look for that one first, and ship their own fixed entity lists
// under it for some stock maps (e1m1, e1m2, e1m4, e2m2, e2m3, e2m7), which would be used instead of ours if only
// <map>.ent existed.
func checksumEntPath(entPath, name string, bsp []byte) string {
	return filepath.Join(filepath.Dir(entPath), fmt.Sprintf("%s@%04x.ent", name, crc16(entityText(bsp))))
}

// removeGenerated deletes the .ent files in dir that trailgen made (they start with its header).  A hand made
// .ent has no such header and is never touched.  match picks which names to look at.
func removeGenerated(dir string, match func(name string) bool) int {
	files, _ := os.ReadDir(dir)
	removed := 0
	for _, f := range files {
		name := f.Name()
		if f.IsDir() || !strings.HasSuffix(name, ".ent") || !match(name) {
			continue
		}
		data, err := os.ReadFile(filepath.Join(dir, name))
		if err != nil || !isGenerated(data) {
			continue
		}
		if os.Remove(filepath.Join(dir, name)) == nil {
			removed++
		}
	}
	return removed
}
