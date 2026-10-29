package main

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

// genVersion is bumped whenever the generator's output would change for the same map.
// A .ent made by another version is rebuilt.
const genVersion = 22

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
