@tool
extends McpTestSuite

var _labels : Array[Label] = []


func suite_name() -> String:
	return "banner_queue"


func teardown() -> void:
	for label : Label in _labels:
		label.queue_free()
	_labels.clear()


func _presenter() -> BannerPresenter:
	var label := Label.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(label)
	_labels.append(label)
	return BannerPresenter.new(label, 0.1, 1.0, 0.1)


func test_first_banner_shows_at_once() -> void:
	var queue := BannerQueue.new()
	queue.show(_presenter(), "Eka")
	assert_true(queue.is_showing())
	assert_eq(queue.pending_count(), 0)


func test_second_banner_waits_its_turn() -> void:
	var queue := BannerQueue.new()
	var shown : Array[String] = []
	queue.show(_presenter(), "Eka", func() -> void: shown.append("Eka"))
	queue.show(_presenter(), "Toka", func() -> void: shown.append("Toka"))
	assert_eq(queue.pending_count(), 1)
	assert_eq(shown, ["Eka"] as Array[String])


func test_finished_banner_hands_over_to_the_next() -> void:
	var queue := BannerQueue.new()
	var first : BannerPresenter = _presenter()
	var shown : Array[String] = []
	queue.show(first, "Eka")
	queue.show(_presenter(), "Toka", func() -> void: shown.append("Toka"))
	first.finished.emit()
	assert_eq(queue.pending_count(), 0)
	assert_eq(shown, ["Toka"] as Array[String])


func test_spot_frees_when_the_last_banner_finishes() -> void:
	var queue := BannerQueue.new()
	var only : BannerPresenter = _presenter()
	queue.show(only, "Eka")
	only.finished.emit()
	assert_false(queue.is_showing())
