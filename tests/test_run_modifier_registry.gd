@tool
extends McpTestSuite

## Unit tests for RunModifierRegistry.get_random_modifiers() — the pool
## itself is a shared static var (see that file's own _static_init()
## docstring for why), so unlike a hypothetical "empty pool fallback"
## test, these only ever READ pool through a fresh instance, never mutate
## it — safe to run alongside a live game session in the same process.

const RunModifierRegistryScript := preload("res://src/autoload/run_modifier_registry.gd")


func suite_name() -> String:
	return "run_modifier_registry"


## _static_init() populates the shared `pool` the moment the live game
## loads this script (autoload boot), but this @tool test-runner loads
## its own copy of the script independently of that — whether pool
## already got populated here depends on editor/test-runner load order,
## not on anything this suite controls. Guarded, idempotent top-up (only
## appends when still empty) so these tests are self-sufficient either
## way instead of silently passing vacuously against an empty pool.
func _ensure_pool_populated() -> void:
	if RunModifierRegistryScript.pool.is_empty():
		RunModifierRegistryScript._static_init()


func test_get_random_modifiers_returns_requested_count() -> void:
	_ensure_pool_populated()
	var registry := RunModifierRegistryScript.new()
	# The real resource pool has 6 modifiers (see src/resources/run_modifiers/) —
	# asking for 3 should never come up short.
	assert_eq(registry.get_random_modifiers(3).size(), 3)


func test_get_random_modifiers_returns_distinct_modifiers() -> void:
	_ensure_pool_populated()
	var registry := RunModifierRegistryScript.new()
	var picked : Array[RunModifier] = registry.get_random_modifiers(RunModifierRegistryScript.pool.size())
	var seen_names : Dictionary = {}
	for modifier : RunModifier in picked:
		assert_false(seen_names.has(modifier.modifier_name), "duplicate modifier offered: %s" % modifier.modifier_name)
		seen_names[modifier.modifier_name] = true


func test_get_random_modifiers_clamps_to_pool_size_instead_of_padding() -> void:
	_ensure_pool_populated()
	var registry := RunModifierRegistryScript.new()
	var pool_size : int = RunModifierRegistryScript.pool.size()
	assert_eq(registry.get_random_modifiers(pool_size + 10).size(), pool_size)


func test_get_random_modifiers_every_result_comes_from_the_pool() -> void:
	_ensure_pool_populated()
	var registry := RunModifierRegistryScript.new()
	var picked : Array[RunModifier] = registry.get_random_modifiers(3)
	for modifier : RunModifier in picked:
		assert_true(RunModifierRegistryScript.pool.has(modifier), "offered modifier not found in pool: %s" % modifier.modifier_name)
