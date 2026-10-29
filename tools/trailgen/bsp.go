package main

import (
	"encoding/binary"
	"fmt"
	"math"
	"os"
)

// Quake BSP reader: version 29, and BSP2 (the same layout with 32 bit indexes, for big maps).
// Only the lumps trailgen needs are decoded.

const (
	lumpEntities = iota
	lumpPlanes
	lumpTextures
	lumpVertices
	lumpVisibility
	lumpNodes
	lumpTexinfo
	lumpFaces
	lumpLighting
	lumpClipnodes
	lumpLeafs
	lumpMarksurfaces
	lumpEdges
	lumpSurfedges
	lumpModels
	numLumps
)

type Vec3 [3]float32

type Plane struct {
	Normal Vec3
	Dist   float32
}

type Face struct {
	Plane     int
	Side      bool // true when the face is on the back of its plane
	FirstEdge int
	NumEdges  int
	Texinfo   int
}

type Clipnode struct {
	Plane    int32
	Children [2]int32 // >= 0 is another clipnode, < 0 is a contents value
}

type Model struct {
	Mins, Maxs Vec3
	Head       [4]int // root clipnode of each hull, [1] is the standing player hull
	FirstFace  int
	NumFaces   int
}

type BSP struct {
	Entities  string
	Planes    []Plane
	Vertices  []Vec3
	Faces     []Face
	Clipnodes []Clipnode
	Edges     [][2]uint32
	Surfedges []int32
	Models    []Model
}

func LoadBSP(path string) (*BSP, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	return ParseBSP(path, data)
}

// ParseBSP reads a map from its bytes; path is only for the error messages.
func ParseBSP(path string, data []byte) (*BSP, error) {
	var err error
	if len(data) < 4+numLumps*8 {
		return nil, fmt.Errorf("%s: too small to be a BSP", path)
	}
	le := binary.LittleEndian
	version := le.Uint32(data[0:4])
	bsp2 := string(data[0:4]) == "BSP2"
	if version != 29 && !bsp2 {
		return nil, fmt.Errorf("%s: unsupported BSP version %d (only 29 and BSP2)", path, version)
	}
	lump := func(i int) ([]byte, error) {
		off := int(le.Uint32(data[4+i*8:]))
		n := int(le.Uint32(data[8+i*8:]))
		if off < 0 || n < 0 || off+n > len(data) {
			return nil, fmt.Errorf("%s: lump %d out of range", path, i)
		}
		return data[off : off+n], nil
	}
	f32 := func(b []byte) float32 { return math.Float32frombits(le.Uint32(b)) }

	b := &BSP{}
	var raw []byte

	if raw, err = lump(lumpEntities); err != nil {
		return nil, err
	}
	// the lump is NUL terminated, and the engine stops reading at the first NUL (some maps carry
	// leftovers after it)
	for i, c := range raw {
		if c == 0 {
			raw = raw[:i]
			break
		}
	}
	b.Entities = string(raw)

	if raw, err = lump(lumpPlanes); err != nil {
		return nil, err
	}
	for i := 0; i+20 <= len(raw); i += 20 {
		b.Planes = append(b.Planes, Plane{Vec3{f32(raw[i:]), f32(raw[i+4:]), f32(raw[i+8:])}, f32(raw[i+12:])})
	}

	if raw, err = lump(lumpVertices); err != nil {
		return nil, err
	}
	for i := 0; i+12 <= len(raw); i += 12 {
		b.Vertices = append(b.Vertices, Vec3{f32(raw[i:]), f32(raw[i+4:]), f32(raw[i+8:])})
	}

	if raw, err = lump(lumpFaces); err != nil {
		return nil, err
	}
	if bsp2 {
		for i := 0; i+28 <= len(raw); i += 28 {
			b.Faces = append(b.Faces, Face{
				Plane:     int(le.Uint32(raw[i:])),
				Side:      le.Uint32(raw[i+4:]) != 0,
				FirstEdge: int(le.Uint32(raw[i+8:])),
				NumEdges:  int(le.Uint32(raw[i+12:])),
				Texinfo:   int(le.Uint32(raw[i+16:])),
			})
		}
	} else {
		for i := 0; i+20 <= len(raw); i += 20 {
			b.Faces = append(b.Faces, Face{
				Plane:     int(le.Uint16(raw[i:])),
				Side:      le.Uint16(raw[i+2:]) != 0,
				FirstEdge: int(le.Uint32(raw[i+4:])),
				NumEdges:  int(le.Uint16(raw[i+8:])),
				Texinfo:   int(le.Uint16(raw[i+10:])),
			})
		}
	}

	if raw, err = lump(lumpClipnodes); err != nil {
		return nil, err
	}
	if bsp2 {
		for i := 0; i+12 <= len(raw); i += 12 {
			b.Clipnodes = append(b.Clipnodes, Clipnode{
				Plane:    int32(le.Uint32(raw[i:])),
				Children: [2]int32{int32(le.Uint32(raw[i+4:])), int32(le.Uint32(raw[i+8:]))},
			})
		}
	} else {
		for i := 0; i+8 <= len(raw); i += 8 {
			b.Clipnodes = append(b.Clipnodes, Clipnode{
				Plane:    int32(le.Uint32(raw[i:])),
				Children: [2]int32{int32(int16(le.Uint16(raw[i+4:]))), int32(int16(le.Uint16(raw[i+6:])))},
			})
		}
	}

	if raw, err = lump(lumpEdges); err != nil {
		return nil, err
	}
	if bsp2 {
		for i := 0; i+8 <= len(raw); i += 8 {
			b.Edges = append(b.Edges, [2]uint32{le.Uint32(raw[i:]), le.Uint32(raw[i+4:])})
		}
	} else {
		for i := 0; i+4 <= len(raw); i += 4 {
			b.Edges = append(b.Edges, [2]uint32{uint32(le.Uint16(raw[i:])), uint32(le.Uint16(raw[i+2:]))})
		}
	}

	if raw, err = lump(lumpSurfedges); err != nil {
		return nil, err
	}
	for i := 0; i+4 <= len(raw); i += 4 {
		b.Surfedges = append(b.Surfedges, int32(le.Uint32(raw[i:])))
	}

	if raw, err = lump(lumpModels); err != nil {
		return nil, err
	}
	for i := 0; i+64 <= len(raw); i += 64 {
		b.Models = append(b.Models, Model{
			Mins: Vec3{f32(raw[i:]), f32(raw[i+4:]), f32(raw[i+8:])},
			Maxs: Vec3{f32(raw[i+12:]), f32(raw[i+16:]), f32(raw[i+20:])},
			Head: [4]int{int(int32(le.Uint32(raw[i+36:]))), int(int32(le.Uint32(raw[i+40:]))),
				int(int32(le.Uint32(raw[i+44:]))), int(int32(le.Uint32(raw[i+48:])))},
			FirstFace: int(le.Uint32(raw[i+56:])),
			NumFaces:  int(le.Uint32(raw[i+60:])),
		})
	}
	return b, nil
}

// FaceVerts returns a face's polygon corners in order.
func (b *BSP) FaceVerts(f Face) []Vec3 {
	out := make([]Vec3, 0, f.NumEdges)
	for i := 0; i < f.NumEdges; i++ {
		se := b.Surfedges[f.FirstEdge+i]
		var v uint32
		if se >= 0 {
			v = b.Edges[se][0]
		} else {
			v = b.Edges[-se][1]
		}
		out = append(out, b.Vertices[v])
	}
	return out
}

// FaceNormal is the direction the face points out of the solid.
func (b *BSP) FaceNormal(f Face) Vec3 {
	n := b.Planes[f.Plane].Normal
	if f.Side {
		n = Vec3{-n[0], -n[1], -n[2]}
	}
	return n
}
