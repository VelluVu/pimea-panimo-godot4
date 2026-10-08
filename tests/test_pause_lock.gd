@tool
extends McpTestSuite

## Unit tests for PauseLock's holder bookkeeping: the tree stays paused until
## the last holder lets go, and freed holders never keep it paused.

const PauseLockScript := preload("res://src/ui/pause_lock.gd")


func suite_name() -> String:
	return "pause_lock"


func setup() -> void:
	PauseLockScript.clear()


func teardown() -> void:
	PauseLockScript.clear()


func test_last_holder_releasing_unpauses() -> void:
	var holder := RefCounted.new()
	PauseLockScript.add_holder(holder.get_instance_id())
	assert_false(PauseLockScript.remove_holder(holder.get_instance_id()))


func test_another_holder_keeps_the_pause() -> void:
	var menu := RefCounted.new()
	var cards := RefCounted.new()
	PauseLockScript.add_holder(menu.get_instance_id())
	PauseLockScript.add_holder(cards.get_instance_id())
	assert_true(PauseLockScript.remove_holder(menu.get_instance_id()))
	assert_false(PauseLockScript.remove_holder(cards.get_instance_id()))


func test_holding_twice_needs_one_release() -> void:
	var holder := RefCounted.new()
	PauseLockScript.add_holder(holder.get_instance_id())
	PauseLockScript.add_holder(holder.get_instance_id())
	assert_false(PauseLockScript.remove_holder(holder.get_instance_id()))


func test_freed_holder_does_not_keep_the_pause() -> void:
	var gone := Node.new()
	var other := RefCounted.new()
	PauseLockScript.add_holder(gone.get_instance_id())
	PauseLockScript.add_holder(other.get_instance_id())
	gone.free()
	assert_false(PauseLockScript.remove_holder(other.get_instance_id()))
