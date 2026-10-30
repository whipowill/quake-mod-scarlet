package main

import (
	"fmt"
	"strconv"
	"strings"
)

// Entity is one {...} block of the entity lump.  Keys keep their file order so the
// output can be written back without shuffling the map's own entities.
type Entity struct {
	Keys []string
	Vals []string
}

func (e *Entity) Get(key string) string {
	for i, k := range e.Keys {
		if k == key {
			return e.Vals[i]
		}
	}
	return ""
}

func (e *Entity) Set(key, val string) {
	for i, k := range e.Keys {
		if k == key {
			e.Vals[i] = val
			return
		}
	}
	e.Keys = append(e.Keys, key)
	e.Vals = append(e.Vals, val)
}

func (e *Entity) Class() string { return e.Get("classname") }

// Origin parses the "origin" key.
func (e *Entity) Origin() (Vec3, bool) {
	f := strings.Fields(e.Get("origin"))
	if len(f) != 3 {
		return Vec3{}, false
	}
	var v Vec3
	for i := range v {
		x, err := strconv.ParseFloat(f[i], 32)
		if err != nil {
			return Vec3{}, false
		}
		v[i] = float32(x)
	}
	return v, true
}

// ModelIndex returns N for a brush entity whose "model" is "*N", or -1.
func (e *Entity) ModelIndex() int {
	m := e.Get("model")
	if !strings.HasPrefix(m, "*") {
		return -1
	}
	n, err := strconv.Atoi(m[1:])
	if err != nil {
		return -1
	}
	return n
}

// cloneEntities copies a list of entities, so one build's changes (items it marks, waypoints it adds)
// don't leak into the next.
func cloneEntities(in []*Entity) []*Entity {
	out := make([]*Entity, len(in))
	for i, e := range in {
		out[i] = &Entity{Keys: append([]string(nil), e.Keys...), Vals: append([]string(nil), e.Vals...)}
	}
	return out
}

// ParseEntities reads the text of an entity lump (or a .ent file).
func ParseEntities(text string) ([]*Entity, error) {
	var out []*Entity
	var cur *Entity
	// like the engine, stop at the first NUL (map editors leave one at the end of the file)
	if i := strings.IndexByte(text, 0); i >= 0 {
		text = text[:i]
	}
	s := text
	for {
		s = strings.TrimLeft(s, " \t\r\n")
		if s == "" {
			break
		}
		switch s[0] {
		case '{':
			if cur != nil {
				return nil, fmt.Errorf("entity %d: unexpected '{'", len(out))
			}
			cur = &Entity{}
			s = s[1:]
		case '}':
			if cur == nil {
				return nil, fmt.Errorf("entity %d: unexpected '}'", len(out))
			}
			out = append(out, cur)
			cur = nil
			s = s[1:]
		case '"':
			if cur == nil {
				return nil, fmt.Errorf("entity %d: key outside of braces", len(out))
			}
			key, rest, ok := readQuoted(s)
			if !ok {
				return nil, fmt.Errorf("entity %d: unterminated string", len(out))
			}
			rest = strings.TrimLeft(rest, " \t\r\n")
			val, rest, ok := readQuoted(rest)
			if !ok {
				return nil, fmt.Errorf("entity %d: key %q has no value", len(out), key)
			}
			cur.Keys = append(cur.Keys, key)
			cur.Vals = append(cur.Vals, val)
			s = rest
		case '/':
			// some hand edited .ent files carry // comments
			if i := strings.IndexByte(s, '\n'); i >= 0 {
				s = s[i:]
			} else {
				s = ""
			}
		default:
			return nil, fmt.Errorf("entity %d: unexpected %q", len(out), s[:1])
		}
	}
	if cur != nil {
		return nil, fmt.Errorf("entity lump ends inside an entity")
	}
	return out, nil
}

func readQuoted(s string) (string, string, bool) {
	if s == "" || s[0] != '"' {
		return "", s, false
	}
	i := strings.IndexByte(s[1:], '"')
	if i < 0 {
		return "", s, false
	}
	return s[1 : 1+i], s[2+i:], true
}
