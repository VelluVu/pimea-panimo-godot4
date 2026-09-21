@tool
extends McpTestSuite

## Unit tests for ConsoleCommandRegistry: dispatch, the developer-mode gate and the help lists.

const RegistryScript := preload("res://systems/console/console_command_registry.gd")


func suite_name() -> String:
	return "console_command_registry"


func _make(lines : Array) -> RegistryScript:
	return RegistryScript.new(func(text : String) -> void: lines.append(text))


func test_execute_runs_the_handler_with_the_arguments_and_ignores_case() -> void:
	var lines : Array = []
	var received : Array = []
	var registry := _make(lines)
	registry.register("osta", func(args : PackedStringArray) -> void: received.append(args))

	registry.execute("OSTA mallas 3")

	assert_eq(received.size(), 1)
	assert_eq(received[0], PackedStringArray(["mallas", "3"]))


func test_an_unknown_command_is_reported_with_its_name() -> void:
	var lines : Array = []
	_make(lines).execute("nope now")
	assert_eq(lines.size(), 1)
	assert_true(String(lines[0]).contains("nope"))


func test_dev_only_commands_need_developer_mode() -> void:
	var lines : Array = []
	var ran : Array = []
	var registry := _make(lines)
	registry.register("cheat", func(_args : PackedStringArray) -> void: ran.append(true), "", "", true)

	registry.developer_mode_check = func() -> bool: return false
	registry.execute("cheat")
	assert_eq(ran.size(), 0, "blocked while developer mode is off")
	assert_eq(lines, [registry.dev_mode_off_message])

	registry.developer_mode_check = func() -> bool: return true
	registry.execute("cheat")
	assert_eq(ran.size(), 1, "allowed once developer mode is on")


func test_help_lists_listed_commands_and_hides_unlisted_ones() -> void:
	var lines : Array = []
	var registry := _make(lines)
	registry.developer_mode_check = func() -> bool: return false
	registry.register("visible", func(_a : PackedStringArray) -> void: pass, "visible <x>", "note")
	registry.register("secret", func(_a : PackedStringArray) -> void: pass, "", "", false, false)

	registry.print_help()

	assert_eq(lines.size(), 1, "no developer section while developer mode is off")
	assert_true(String(lines[0]).contains("visible <x> (note)"))
	assert_false(String(lines[0]).contains("secret"))


func test_typing_help_runs_through_execute_like_the_console_registers_it() -> void:
	var lines : Array = []
	var registry := _make(lines)
	registry.developer_mode_check = func() -> bool: return false
	registry.register("player", func(_a : PackedStringArray) -> void: pass)
	registry.register("help", registry.print_help, "", "", false, false)

	registry.execute("help")

	assert_eq(lines.size(), 1, "help must print without an argument-count error")
	assert_true(String(lines[0]).contains("player"))


func test_help_adds_a_developer_section_in_developer_mode() -> void:
	var lines : Array = []
	var registry := _make(lines)
	registry.developer_mode_check = func() -> bool: return true
	registry.register("player", func(_a : PackedStringArray) -> void: pass)
	registry.register("cheat", func(_a : PackedStringArray) -> void: pass, "", "", true)

	registry.print_help()

	assert_eq(lines.size(), 2)
	assert_true(String(lines[0]).contains("player") and not String(lines[0]).contains("cheat"))
	assert_true(String(lines[1]).contains("cheat"))


func test_help_skips_the_developer_section_when_there_are_no_developer_commands() -> void:
	var lines : Array = []
	var registry := _make(lines)
	registry.developer_mode_check = func() -> bool: return true
	registry.register("player", func(_a : PackedStringArray) -> void: pass)

	registry.print_help()

	assert_eq(lines.size(), 1)


func test_the_wording_can_be_replaced() -> void:
	var lines : Array = []
	var registry := _make(lines)
	registry.unknown_command_format = "??? %s"
	registry.execute("zzz")
	assert_eq(lines, ["??? zzz"])
