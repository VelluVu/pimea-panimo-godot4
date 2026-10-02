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
## Informative only: a new run or the main menu are picked from GameMenuWindow, so
## the player cannot leave a run by accident. The season endings ("survived",
## "season_over") continue the run: it is already scored, so playing on only earns
## reduced renown (Brewery.has_continued_past_survival). Busted and bankrupt open
## the game menu instead, as there is nothing left to play.

const TITLE_BUSTED : String = "BUSTED!"
const TITLE_BANKRUPT : String = "KONKURSSI!"
const TITLE_SURVIVED : String = "LEGENDA!"
const TITLE_SEASON_OVER : String = "KAUSI PÄÄTTYI!"

const MESSAGE_BUSTED : String = "Kolmas ratsia oli viimeinen. LVV takavarikoi kaiken ja sulki panimosi pysyvästi."
const MESSAGE_BANKRUPT : String = "Rahat loppuivat ja varasto oli tyhjä. Panimosi ajautui konkurssiin."
const MESSAGE_SURVIVED : String = "Selvisit kauden loppuun, ja kellarisi kaljasta tuli kaupunginosan legenda."
const MESSAGE_SEASON_OVER : String = "Selvisit kauden loppuun, mutta legendaksi tarvitaan %d mainetta."

const RANK_FORMAT : String = "Sijoitus: #%d"
const NEW_RECORD_TEXT : String = "UUSI ENNÄTYS!"
const RENOWN_FORMAT : String = "Olutopin mainetta +%d"
const CONTINUE_NOTE : String = "Voit jatkaa pelaamista, mutta ennätyslistan pisteet eivät enää muutu. Olutopin mainetta saat jatkossa vähemmän, ja uudet reseptit ja saavutukset avautuvat yhä. Uuden yrityksen voit aloittaa valikosta."

const CONTINUE_BUTTON_TEXT : String = "Jatka pelaamista"
const MENU_BUTTON_TEXT : String = "Valikkoon"

@onready var title_label : Label = %TitleLabel
@onready var message_label : Label = %MessageLabel
@onready var breakdown_label : Label = %BreakdownLabel
@onready var result_label : Label = %ResultLabel
@onready var note_label : Label = %NoteLabel
@onready var close_button : Button = %CloseButton

## Set per ending: the close button continues the run or opens the game menu.
var _is_season_end : bool = false


func _ready() -> void:
	close_button.pressed.connect(_on_close_button_pressed)
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
		"season_over":
			title_label.text = TITLE_SEASON_OVER
			message_label.text = MESSAGE_SEASON_OVER % Brewery.SURVIVAL_MIN_REPUTATION
		_:
			title_label.text = ending_type
			message_label.text = ""

	_is_season_end = ending_type in [DayRules.ENDING_SURVIVED, DayRules.ENDING_SEASON_OVER]
	_show_score(brewery, ending_type)
	note_label.visible = _is_season_end
	note_label.text = CONTINUE_NOTE
	close_button.text = CONTINUE_BUTTON_TEXT if _is_season_end else MENU_BUTTON_TEXT

	get_tree().paused = true
	show()


## Off the record after continuing: LeaderboardManager and MetaProgressManager skip
## those endings too, so no score, rank or renown is shown for them.
func _show_score(brewery : Brewery, ending_type : String) -> void:
	var on_record : bool = not brewery.has_continued_past_survival
	breakdown_label.visible = on_record
	result_label.visible = on_record
	if not on_record:
		return

	var entry : Dictionary = RunScore.entry_for(brewery, ending_type)
	breakdown_label.text = LeaderboardText.breakdown(entry)
	var rank : int = LeaderboardManager.get_rank(entry["score"])
	var lines : PackedStringArray = [tr(RANK_FORMAT) % rank]
	if rank == 1:
		lines.append(NEW_RECORD_TEXT)
	lines.append(tr(RENOWN_FORMAT) % RunScore.renown(entry["score"]))
	result_label.text = "\n".join(lines)


func _on_close_button_pressed() -> void:
	hide()
	if _is_season_end:
		_continue_run()
	else:
		GUISignals.game_menu_requested.emit()


## Resumes the same run exactly as it was, already scored: only reduced nightly
## renown from here on (MetaProgressManager). Clears game_has_ended so busted/bankrupt can
## still end things later, but latches has_continued_past_survival so the
## survived ending itself can never fire again this run (see
## DayRules.season_ending()).
func _continue_run() -> void:
	var brewery := BrewEngine.current_brewery
	if brewery == null:
		return
	brewery.game_has_ended = false
	brewery.has_continued_past_survival = true
	get_tree().paused = false
