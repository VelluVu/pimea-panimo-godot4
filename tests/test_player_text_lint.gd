@tool
extends McpTestSuite

## Lint for hand-written, player-facing Finnish descriptions in the data
## .tres files (perks, run modifiers, meta unlocks, bars, achievements).
## Reads the raw `description = "..."` lines with FileAccess instead of
## loading the resources, so it doesn't depend on the editor's script
## cache for RunPerk/MetaUnlockData subclasses (see feedback on the stale
## editor cache). Enforces the two rules that keep slipping in by hand:
## no em dash (project text rule) and every description ends like a sentence
## (a missing full stop is how run-on text like "... ratsiakynnys nousee"
## went unnoticed).

const DESCRIPTION_DIRS : Array[String] = [
	"res://src/resources/perks",
	"res://src/resources/run_modifiers",
	"res://src/resources/meta_unlocks",
	"res://src/resources/bars",
	"res://src/resources/achievements",
]
const DESCRIPTION_PREFIX : String = "description = \""
const EM_DASH : String = "—"
const SENTENCE_ENDINGS : Array[String] = [".", "!", "?"]


func suite_name() -> String:
	return "player_text_lint"


## Returns "" when fine, otherwise a short reason. Pure, so it's testable
## without touching the filesystem.
static func lint_description(text : String) -> String:
	if text.contains(EM_DASH):
		return "contains an em dash"
	if text.strip_edges() != text:
		return "has leading/trailing whitespace"
	if text.contains("  "):
		return "has a double space"
	for ending : String in SENTENCE_ENDINGS:
		if text.ends_with(ending):
			return ""
	return "does not end with . ! or ?"


func test_lint_accepts_a_clean_sentence() -> void:
	assert_eq(lint_description("Pidät matalaa profiilia, joten ratsiakynnys nousee."), "")


func test_lint_rejects_em_dash() -> void:
	assert_ne(lint_description("Hyvä asia %s ja toinen." % EM_DASH), "")


func test_lint_rejects_missing_full_stop() -> void:
	assert_ne(lint_description("Ei pistettä lopussa"), "")


func test_lint_rejects_double_space() -> void:
	assert_ne(lint_description("Kaksi  välilyöntiä."), "")


func test_every_shipped_description_passes_lint() -> void:
	var checked : int = 0
	for dir_path : String in DESCRIPTION_DIRS:
		for file_name : String in DirAccess.get_files_at(dir_path):
			if not file_name.ends_with(".tres"):
				continue
			var path : String = "%s/%s" % [dir_path, file_name]
			var file : FileAccess = FileAccess.open(path, FileAccess.READ)
			if file == null:
				continue
			for raw_line : String in file.get_as_text().split("\n"):
				# Some hand-edited .tres files are saved with CRLF endings.
				var line : String = raw_line.trim_suffix("\r")
				if not line.begins_with(DESCRIPTION_PREFIX):
					continue
				# Line looks like: description = "text"
				var text : String = line.substr(DESCRIPTION_PREFIX.length()).trim_suffix("\"")
				var problem : String = lint_description(text)
				assert_eq(problem, "", "%s: %s" % [path, problem])
				checked += 1
	assert_gt(checked, 0, "lint found no descriptions to check, directories moved?")
