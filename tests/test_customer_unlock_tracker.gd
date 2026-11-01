@tool
extends McpTestSuite

## CustomerUnlockTracker's saved state on a throwaway file, never the real
## user://customer_unlocks.cfg: met titles and the queue that unlocks Ämpärihamstraaja.

const TEST_SAVE_PATH : String = "user://test_customer_unlock_tracker.cfg"


func suite_name() -> String:
	return "customer_unlock_tracker"


func teardown() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)


func test_no_queue_is_seen_at_first() -> void:
	assert_false(CustomerUnlockTracker.new(TEST_SAVE_PATH).has_seen_queue())


func test_a_seen_queue_is_saved_for_later_runs() -> void:
	CustomerUnlockTracker.new(TEST_SAVE_PATH).mark_queue_seen()
	assert_true(CustomerUnlockTracker.new(TEST_SAVE_PATH).has_seen_queue(), "a new tracker reads it from the file")


func test_reset_forgets_the_queue_and_met_titles() -> void:
	var tracker := CustomerUnlockTracker.new(TEST_SAVE_PATH)
	tracker.mark_queue_seen()
	tracker.mark_met("Snobi")
	tracker.reset()
	assert_false(tracker.has_seen_queue())
	assert_false(tracker.is_met("Snobi"))
