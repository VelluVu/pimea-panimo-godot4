class_name OnlineLeaderboard
extends Node

## A shared leaderboard on a Supabase (PostgREST) backend: sends a score through a
## server function, which checks it, and reads the top of the table. The key is the
## project's public one: the server allows only that function and reading, so it is
## safe to ship. Works while the tree is paused when this node's process_mode allows it.

signal submitted(result: Dictionary)
signal top_received(rows: Array)
signal request_failed(action: StringName, message: String)

const ACTION_SUBMIT: StringName = &"submit"
const ACTION_FETCH: StringName = &"fetch"
const LOG_HTTP_ERROR: String = "OnlineLeaderboard: %s failed (result %d, HTTP %d): %s"

## The project URL, like "https://abcd.supabase.co".
var base_url: String = ""
## The publishable (anon) key.
var api_key: String = ""
var table: String = ""
## The columns read by fetch_top(), comma separated.
var columns: String = "*"
## The order of the list, as PostgREST writes it: "score.desc,id.asc".
var order: String = ""
## The server function that checks and stores a score.
var submit_function: String = ""
var timeout_seconds: float = 10.0


func is_configured() -> bool:
	return not base_url.is_empty() and not api_key.is_empty()


## The server's reply (for example the new row's rank) comes in `submitted`.
func submit(payload: Dictionary) -> void:
	var url: String = "%s/rest/v1/rpc/%s" % [base_url, submit_function]
	_send(ACTION_SUBMIT, url, HTTPClient.METHOD_POST, JSON.stringify(payload))


func fetch_top(limit: int) -> void:
	var url: String = "%s/rest/v1/%s?select=%s&order=%s&limit=%d" % [base_url, table, columns, order, limit]
	_send(ACTION_FETCH, url, HTTPClient.METHOD_GET, "")


func _send(action: StringName, url: String, method: HTTPClient.Method, body: String) -> void:
	if not is_configured():
		request_failed.emit(action, "not configured")
		return
	var http := HTTPRequest.new()
	http.timeout = timeout_seconds
	# In a browser the fetch API has already unpacked a gzipped reply, and Godot's own
	# unpacking then fails (RESULT_BODY_DECOMPRESS_FAILED) as soon as the reply is big
	# enough for the server to compress.
	http.accept_gzip = not OS.has_feature("web")
	add_child(http)
	http.request_completed.connect(func(result: int, code: int, _headers: PackedStringArray, data: PackedByteArray) -> void:
		http.queue_free()
		_on_completed(action, result, code, data.get_string_from_utf8()))
	var error: Error = http.request(url, _headers(), method, body)
	if error != OK:
		http.queue_free()
		request_failed.emit(action, error_string(error))


func _headers() -> PackedStringArray:
	return ["apikey: %s" % api_key, "Content-Type: application/json", "Accept: application/json"]


func _on_completed(action: StringName, result: int, code: int, text: String) -> void:
	var parsed: Variant = JSON.parse_string(text) if not text.is_empty() else null
	if result != HTTPRequest.RESULT_SUCCESS or code < 200 or code >= 300:
		push_warning(LOG_HTTP_ERROR % [action, result, code, text.left(200)])
		request_failed.emit(action, _server_message(parsed))
		return
	if action == ACTION_SUBMIT:
		submitted.emit(parsed if parsed is Dictionary else {})
	else:
		top_received.emit(parsed if parsed is Array else [])


## PostgREST puts a raised exception's text in "message".
func _server_message(parsed: Variant) -> String:
	if parsed is Dictionary:
		return str(parsed.get("message", ""))
	return ""
