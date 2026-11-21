class_name Palette
extends RefCounted
## Single source of truth for colours so views stay consistent.

const BG := Color("0e1118")
const FLOOR := Color("1a2130")
const FLOOR_LINE := Color("232c3e")
const WALL := Color("39435a")
const WALL_TOP := Color("4b5772")
const NOISY := Color("2a2f3a")
const NOISY_HATCH := Color("5b6478")
const EXIT_LOCKED := Color("3b4152")
const EXIT_OPEN := Color("2bd47d")
const DOOR := Color("ff9f43")
const TERMINAL := Color("38e1c6")
const OBJECTIVE := Color("ffcc4d")
const HACKED := Color("2bd47d")
const PLAYER := Color("e8f6ff")
const PLAYER_CORE := Color("38e1c6")
const CAMERA := Color("b28dff")
const TEXT := Color("d7deea")
const TEXT_DIM := Color("8a94a8")
const DANGER := Color("ff5470")

const GUARD := [Color("ffd166"), Color("ff9f43"), Color("ff5470")] # by GuardData.State
const CONE := [Color(1.0, 0.82, 0.4, 0.22), Color(1.0, 0.62, 0.26, 0.30), Color(1.0, 0.33, 0.44, 0.38)]
const CAMERA_CONE := Color(0.7, 0.55, 1.0, 0.24)
