class_name OnlineScorePanel
extends VBoxContainer

## The end screen's form for the demo's shared leaderboard. Nothing is sent unless the
## player presses send; the name is remembered.

const CAPTION_TEXT : String = "Maailmanlaajuinen tulostaulukko"
const NAME_PLACEHOLDER : String = "Nimesi"
const SEND_BUTTON_TEXT : String = "Lähetä tulos"
const SENDING_TEXT : String = "Lähetetään..."
const NO_NAME_TOOLTIP : String = "Kirjoita ensin nimimerkki."
const RANK_FORMAT : String = "Sijoitus kaikista pelaajista: #%d / %d"

@onready var caption_label : Label = %CaptionLabel
@onready var name_edit : LineEdit = %NameEdit
@onready var send_button : Button = %SendButton
@onready var status_label : Label = %StatusLabel

var _leaderboard : OnlineLeaderboardWiring
var _entry : Dictionary = {}
var _sending_or_sent : bool = false


func _ready() -> void:
	_leaderboard = OnlineLeaderboardWiring.new()
	add_child(_leaderboard)
	_leaderboard.submitted.connect(_on_submitted)
	_leaderboard.request_failed.connect(_on_request_failed)
	caption_label.text = CAPTION_TEXT
	name_edit.placeholder_text = NAME_PLACEHOLDER
	name_edit.max_length = NicknameRules.MAX_LENGTH
	send_button.text = SEND_BUTTON_TEXT
	name_edit.text_changed.connect(func(_text : String) -> void: _update_send_button())
	name_edit.text_submitted.connect(func(_text : String) -> void: _on_send_pressed())
	send_button.pressed.connect(_on_send_pressed)
	hide()


## Shows a fresh form for a run that is on the record, else hides it.
func show_for(entry : Dictionary, on_record : bool) -> void:
	visible = on_record and _leaderboard.is_enabled()
	if not visible:
		return
	_entry = entry
	_sending_or_sent = false
	name_edit.text = _leaderboard.saved_nickname()
	name_edit.editable = true
	status_label.text = ""
	_update_send_button()


func _update_send_button() -> void:
	var has_name : bool = NicknameRules.is_valid(name_edit.text)
	send_button.disabled = _sending_or_sent or not has_name
	# The grey button says why; once sent, the status line does.
	send_button.tooltip_text = "" if has_name or _sending_or_sent else NO_NAME_TOOLTIP


func _on_send_pressed() -> void:
	if send_button.disabled:
		return
	_sending_or_sent = true
	_update_send_button()
	name_edit.editable = false
	name_edit.release_focus()
	status_label.text = SENDING_TEXT
	_leaderboard.save_nickname(name_edit.text)
	_leaderboard.submit_entry(name_edit.text, _entry)


func _on_submitted(result : Dictionary) -> void:
	_leaderboard.save_last_row_id(int(result.get("id", 0)))
	status_label.text = tr(RANK_FORMAT) % [int(result.get("rank", 0)), int(result.get("total", 0))]


## Lets the player try again.
func _on_request_failed(action : StringName, message : String) -> void:
	status_label.text = OnlineLeaderboardWiring.failure_text(action, message)
	_sending_or_sent = false
	name_edit.editable = true
	_update_send_button()
