@tool
extends EditorPlugin

## Puts the commit being exported into the pack as res://build_commit.txt
## (BuildInfo.COMMIT_FILE): an exported game has no .git to read.

var _export: EditorExportPlugin

func _enter_tree() -> void:
	_export = CommitExport.new()
	add_export_plugin(_export)

func _exit_tree() -> void:
	remove_export_plugin(_export)
	_export = null

class CommitExport extends EditorExportPlugin:
	func _get_name() -> String:
		return "BuildInfo"

	func _export_begin(_features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
		var id := BuildInfo.git_head()
		if id != "":
			add_file(BuildInfo.COMMIT_FILE, id.to_utf8_buffer(), false)
