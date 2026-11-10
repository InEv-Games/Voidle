@tool
class_name ExcavationSiteDef
extends Resource

## One excavation of a world (ExcavationWorldDef): a mark on the map and a story
## in two parts. Its "start" entry opens it: narrative, then the player pays `cost`
## and the crews dig for `duration_sec` of play time. Its "return" entry plays when
## they're done: the choices, whose exits add to `reward` (StoryGrant) and decide
## who joins (StoryJoinCompanion, on the last excavation of a ruin) and what later
## stories remember (StorySetFlag). Nothing an exit of the "start" part collects
## counts: put it in the "return" part.

enum Terrain { RUINS, CRATER, ANY }

## Saved in excavations_done: don't rename one that shipped.
@export var site_id: String = ""
## Excavations with the same id are dug at one place: one mark on the map, with
## a notched bar of how many are done. Empty: a place of its own.
@export var ruin_id: String = ""
@export var display_name: String = ""
## One line under the name, before the player pays.
@export_multiline var teaser: String = ""
## { resource id: amount } paid to start digging: credits only (playtest 07.11),
## a quarter less inside a City's reach (Excavations.cost_of).
@export var cost: Dictionary = {}
## How long the crews dig, in seconds of play time (they stop while the game is closed).
@export var duration_sec: float = 300.0
## { resource id: amount } it always pays when it ends, on top of what the story
## adds: Science and the site's material, never credits: a dig turns credits
## into what money can't easily buy (playtest 07.11).
@export var reward: Dictionary = {}
## Where its mark goes; the next kinds are tried if the world has none of it.
@export var terrain: Terrain = Terrain.RUINS
@export var story: VSMData

const ENTRY_OPENING := "start"
const ENTRY_RETURN := "return"

## What its place is saved under (GameState.excavation_sites).
func place_key() -> String:
	return ruin_id if ruin_id != "" else site_id
