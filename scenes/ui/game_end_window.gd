class_name GameEndWindow
extends Panel

## Modal end-of-run screen for all three endings — see
## Brewery.trigger_ending() and BrewerySignals.game_ended. Unlike
## LvvRaidWindow/DayRecapWindow (which just show/hide while the game keeps
## running underneath), this pauses the whole SceneTree so nothing else
## (customers, timers, spawners) keeps going behind it — the run is over.
## Needs PROCESS_MODE_ALWAYS on this root node so its buttons still
## receive input while paused; its children inherit that by default.
##
## The "survived" ending alone offers a continue option — see
## _on_continue_button_pressed() and Brewery.has_continued_past_survival.

const GAME_SCENE_PATH : String = "res://scenes/main.tscn"

const TITLE_BUSTED : String = "BUSTED!"
const TITLE_BANKRUPT : String = "KONKURSSI!"
const TITLE_SURVIVED : String = "LEGENDA!"

const MESSAGE_BUSTED : String = "Kolmas ratsia oli viimeinen. LVV takavarikoi kaiken ja sulki panimosi pysyvästi."
const MESSAGE_BANKRUPT : String = "Rahat loppuivat ja varasto oli tyhjä. Panimosi ajautui konkurssiin."
const MESSAGE_SURVIVED : String = "Selvisit ratsioista ja konkurssin partaalta läpi koko uran. Kellarisi kaljasta tuli kaupunginosan legenda."

const STATS_FORMAT : String = "\n\nPäiviä selvitty: %d\nMainetta lopussa: %d\nAnnoksia myyty yhteensä: %d"
const RANK_FORMAT : String = "\n\nSijoitus ennätyslistalla: #%d"
const NEW_RECORD_TEXT : String = "\nUUSI ENNÄTYS!"

const RESTART_BUTTON_TEXT : String = "Uusi yritys"
## Deliberately not phrased like a "keep your streak going" hook — this is
## an off-the-record epilogue, not a second attempt at the same goal.
const CONTINUE_BUTTON_TEXT : String = "Jatka pelaamista (ei tilastoihin)"

@onready var title_label : Label = $MarginContainer/MainVBox/TitleLabel
@onready var message_label : Label = $MarginContainer/MainVBox/MessageLabel
@onready var restart_button : Button = $MarginContainer/MainVBox/RestartButton
@onready var continue_button : Button = $MarginContainer/MainVBox/ContinueButton
@onready var modifier_select_window : ModifierSelectWindow = $"../ModifierSelectWindow"


func _ready() -> void:
	restart_button.text = RESTART_BUTTON_TEXT
	restart_button.pressed.connect(_on_restart_button_pressed)
	continue_button.text = CONTINUE_BUTTON_TEXT
	continue_button.pressed.connect(_on_continue_button_pressed)
	modifier_select_window.modifier_chosen.connect(_on_modifier_chosen)
	BrewerySignals.game_ended.connect(_on_game_ended)
	hide()


func _on_game_ended(ending_type : String) -> void:
	var brewery := BrewEngine.current_brewery
	if brewery == null:
		return

	match ending_type:
		"busted":
			title_label.text = TITLE_BUSTED
			message_label.text = MESSAGE_BUSTED
		"bankrupt":
			title_label.text = TITLE_BANKRUPT
			message_label.text = MESSAGE_BANKRUPT
		"survived":
			title_label.text = TITLE_SURVIVED
			message_label.text = MESSAGE_SURVIVED
		_:
			title_label.text = ending_type
			message_label.text = ""

	message_label.text += STATS_FORMAT % [brewery.current_day, brewery.reputation, brewery.lifetime_bottles_sold]

	# LeaderboardManager records this same ending off the identical
	# game_ended signal (see its own has_continued_past_survival guard) —
	# mirror that guard here so the rank shown always matches an entry
	# that actually made it onto the list.
	if not brewery.has_continued_past_survival:
		var rank := LeaderboardManager.get_rank_for_stats(brewery.current_day, brewery.reputation, brewery.lifetime_bottles_sold, brewery.run_modifier)
		message_label.text += RANK_FORMAT % rank
		if rank == 1:
			message_label.text += NEW_RECORD_TEXT

	# Only the "survived" ending is a real stopping point you'd want to
	# keep going past — busted/bankrupt are dead ends with nothing left to
	# play with (no stock, no cash, or both).
	continue_button.visible = ending_type == "survived"

	get_tree().paused = true
	show()


## Stays paused (unlike the old direct-restart flow) while
## ModifierSelectWindow is up — the run is still "over" until the player
## has actually picked what comes next; see that window's own
## PROCESS_MODE_ALWAYS for why its buttons still work while paused.
func _on_restart_button_pressed() -> void:
	hide()
	modifier_select_window.open()


func _on_modifier_chosen(modifier : RunModifier) -> void:
	get_tree().paused = false
	BrewEngine.start_new_game(modifier)
	TimeManager.resume_time()
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


## Resumes the same run exactly as it was — no reward, no re-roll, just an
## off-the-record epilogue. Clears game_has_ended so busted/bankrupt can
## still end things later, but latches has_continued_past_survival so the
## survived ending itself can never fire again this run (see
## TimeManager._check_survival_ending()).
func _on_continue_button_pressed() -> void:
	var brewery := BrewEngine.current_brewery
	if brewery == null:
		return

	hide()
	brewery.game_has_ended = false
	brewery.has_continued_past_survival = true
	get_tree().paused = false
