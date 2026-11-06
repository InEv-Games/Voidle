class_name BuildInfo
extends RefCounted

## "Voidle v0.1 680a54d": the game, its version (Project Settings →
## application/config/version) and the commit it was built from.
## An exported game reads the commit from COMMIT_FILE, which the build_info
## export plugin (addons/build_info) writes into the pack; a run from the editor
## reads it from the repository's .git.

const COMMIT_FILE := "res://build_commit.txt"
const SHORT := 7

static func label() -> String:
	var parts: Array[String] = [String(ProjectSettings.get_setting("application/config/name", "Voidle"))]
	var v := String(ProjectSettings.get_setting("application/config/version", ""))
	if v != "":
		parts.append("v" + v)
	var c := commit()
	if c != "":
		parts.append(c)
	return " ".join(parts)

## The short commit id, or "" when it can't be found.
static func commit() -> String:
	if FileAccess.file_exists(COMMIT_FILE):
		return FileAccess.get_file_as_string(COMMIT_FILE).strip_edges().left(SHORT)
	return git_head().left(SHORT)

## The full id of the repository's HEAD (res://.git), or "".
static func git_head() -> String:
	var git := ProjectSettings.globalize_path("res://.git")
	var head := FileAccess.get_file_as_string(git.path_join("HEAD")).strip_edges()
	if not head.begins_with("ref: "):
		return head   # detached: the id itself (or "" when there is no .git)
	var ref := head.substr(5)
	var loose := FileAccess.get_file_as_string(git.path_join(ref)).strip_edges()
	if loose != "":
		return loose
	# a packed ref: "<id> <ref>" lines in packed-refs
	for line in FileAccess.get_file_as_string(git.path_join("packed-refs")).split("\n"):
		if line.ends_with(" " + ref):
			return line.get_slice(" ", 0)
	return ""
