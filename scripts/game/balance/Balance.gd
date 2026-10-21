## Balance — autoload. Holds the active balance profile (`cfg`, a BalanceConfig)
## and the shared curve math every price and level formula uses, so UI, buying,
## previews and production can never disagree.
##
## Pick the profile with the `voidle/balance/profile` project setting (a name:
## "current" loads res://resources/balance/profile_current.tres) or with the dev
## console: `balance <name>`. Saves record which profile they were played with.
extends Node

signal profile_changed(profile_name: String)

const PROFILE_DIR := "res://resources/balance/"
const DEFAULT_PROFILE := "current"

var cfg: BalanceConfig = null
var profile_name: String = ""

func _init() -> void:
	# loaded before any other autoload's _ready can ask for numbers
	if not load_profile(String(ProjectSettings.get_setting("voidle/balance/profile", DEFAULT_PROFILE))):
		load_profile(DEFAULT_PROFILE)
	if cfg == null:
		cfg = BalanceConfig.new()   # built-in defaults = the current game
		profile_name = cfg.profile_name

func profile_path(p_name: String) -> String:
	return PROFILE_DIR + "profile_%s.tres" % p_name

## Names of the profiles found in PROFILE_DIR.
func available_profiles() -> PackedStringArray:
	var out := PackedStringArray()
	for f in DirAccess.get_files_at(PROFILE_DIR):
		var file := f.trim_suffix(".remap")
		if file.begins_with("profile_") and file.ends_with(".tres"):
			out.append(file.trim_prefix("profile_").trim_suffix(".tres"))
	return out

## Switches the active profile; false (and no change) if it can't be loaded.
func load_profile(p_name: String) -> bool:
	var path := profile_path(p_name)
	if not ResourceLoader.exists(path):
		return false
	var res := load(path) as BalanceConfig
	if res == null:
		return false
	cfg = res
	profile_name = p_name
	profile_changed.emit(p_name)
	return true

# ── Curve math ───────────────────────────────────────────────────────────────

## base × growth^n
func geometric(base: float, growth: float, n: float) -> float:
	return base * pow(growth, n)

## Price of buying `count` more when `owned` are already bought, each costing
## base × growth^(index): base·g^owned · (g^count − 1)/(g − 1).
func geometric_sum(base: float, growth: float, owned: int, count: int) -> float:
	if count <= 0:
		return 0.0
	if is_equal_approx(growth, 1.0):
		return base * count
	return base * pow(growth, owned) * (pow(growth, count) - 1.0) / (growth - 1.0)

## How many more can be bought with `money` when `owned` are already bought.
func max_affordable(base: float, growth: float, owned: int, money: float) -> int:
	if base <= 0.0 or money <= 0.0:
		return 0
	if is_equal_approx(growth, 1.0):
		return int(floor(money / base))
	var n: float = floorf(log(money * (growth - 1.0) / (base * pow(growth, owned)) + 1.0) / log(growth))
	return maxi(int(n), 0)
