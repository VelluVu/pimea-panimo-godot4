@tool
extends McpTestSuite

## Unit tests for PerkRegistry.get_random_perks() — mirrors
## test_run_modifier_registry.gd's approach and its reasoning almost
## exactly, but PerkRegistry is a plain class_name utility (not an
## autoload), and its methods are real static calls (no instance needed),
## since nothing needs the perk pool ready before another autoload's
## _init() the way RunModifierRegistry's pool does.


func suite_name() -> String:
	return "perk_registry"


## Same rationale as test_run_modifier_registry.gd's _ensure_pool_populated:
## this @tool test-runner loads its own copy of the script independently
## of the live game's autoload boot, so whether _static_init() already
## ran here isn't something this suite controls. Guarded top-up keeps
## these tests self-sufficient either way.
func _ensure_pool_populated() -> void:
	if PerkRegistry.pool.is_empty():
		PerkRegistry._static_init()


func test_get_random_perks_returns_requested_count() -> void:
	_ensure_pool_populated()
	# The real resource pool has 3 perks (see src/resources/perks/) —
	# asking for 2 should never come up short.
	assert_eq(PerkRegistry.get_random_perks(2).size(), 2)


func test_get_random_perks_returns_distinct_perks_within_one_offer() -> void:
	_ensure_pool_populated()
	var picked : Array[RunPerk] = PerkRegistry.get_random_perks(PerkRegistry.pool.size())
	var seen_names : Dictionary = {}
	for perk : RunPerk in picked:
		assert_false(seen_names.has(perk.perk_name), "duplicate perk offered: %s" % perk.perk_name)
		seen_names[perk.perk_name] = true


func test_get_random_perks_clamps_to_pool_size_instead_of_padding() -> void:
	_ensure_pool_populated()
	var pool_size : int = PerkRegistry.pool.size()
	assert_eq(PerkRegistry.get_random_perks(pool_size + 10).size(), pool_size)


func test_get_random_perks_every_result_comes_from_the_pool() -> void:
	_ensure_pool_populated()
	var picked : Array[RunPerk] = PerkRegistry.get_random_perks(2)
	for perk : RunPerk in picked:
		assert_true(PerkRegistry.pool.has(perk), "offered perk not found in pool: %s" % perk.perk_name)
