class_name Customer
extends Node2D


var customer_data: CustomerData
var assigned_slot: int = -1
var generated_name: String = "Asiakas"


func get_customer_name() -> String:
	return generated_name


func walk_complex_route(stairs_pos: Vector2, center_pos: Vector2, target_pos: Vector2) -> void:
	var tween = create_tween()
	var start_pos = global_position
	var stair_steps = 15
	
	for i in range(1, stair_steps + 1):
		var step_pos = start_pos.lerp(stairs_pos, float(i) / stair_steps)
		tween.tween_property(self, "global_position", step_pos, customer_data.stair_step_duration).set_trans(Tween.TRANS_LINEAR)
		tween.tween_interval(0.05)
		
	var dist_to_center = stairs_pos.distance_to(center_pos)
	var duration_to_center = dist_to_center / customer_data.floor_walk_speed
	tween.tween_property(self, "global_position", center_pos, duration_to_center).set_trans(Tween.TRANS_LINEAR)
	
	tween.tween_interval(0.8)
	
	var dist_to_target = center_pos.distance_to(target_pos)
	var duration_to_target = dist_to_target / customer_data.floor_walk_speed
	tween.tween_property(self, "global_position", target_pos, duration_to_target).set_trans(Tween.TRANS_LINEAR)
	
	tween.tween_callback(_on_reached_counter)


func _on_reached_counter() -> void:
	var intro_text = generated_name + ": " + customer_data.dialogue_intro
	BrewerySignals.dialogue_pushed.emit(intro_text, false, assigned_slot, global_position)
	var sale_timer = get_tree().create_timer(2.0)
	sale_timer.timeout.connect(_on_sale_timeout)


func _on_sale_timeout() -> void:
	var response_text = CustomerManager.process_auto_sale(customer_data)
	var final_text = generated_name + ": " + response_text
	BrewerySignals.dialogue_pushed.emit(final_text, false, assigned_slot, global_position)
	
	var leave_timer = get_tree().create_timer(3.5)
	leave_timer.timeout.connect(leave_counter)


func leave_counter() -> void:
	var exit_pos = global_position + Vector2(0.0, 150.0)
	var duration = 150.0 / customer_data.floor_walk_speed
	
	var tween = create_tween()
	tween.tween_property(self, "global_position", exit_pos, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)

	CustomerManager.free_slot_index(assigned_slot)