class_name OnlineLeaderboardWiring
extends OnlineLeaderboard

## This game's shared leaderboards: the Supabase project, this build's board, RunScore
## entries to and from the server columns, and the wording. The demo and the full game
## have their own tables (dev/tools/leaderboard/*.sql). A window showing the list adds one.

## The online parts stay hidden while either is empty.
const PROJECT_URL: String = "https://dagwyjxvspehgoailvju.supabase.co"
const PUBLISHABLE_KEY: String = "sb_publishable_wS34tYQE-8pI74DiX6dvlQ_AqfUh2YI"

## The full game's board stays hidden until the game is out; the demo's is always on.
const SEASON_BOARD_LIVE: bool = false
const DEMO_TABLE: String = "demo_scores"
const DEMO_SUBMIT_FUNCTION: String = "submit_demo_score"
const SEASON_TABLE: String = "season_scores"
const SEASON_SUBMIT_FUNCTION: String = "submit_season_score"

const OPTION_NICKNAME: String = "online_nickname"
## The player's latest row on each board, to highlight it in the list.
const OPTION_LAST_ROW_ID_PREFIX: String = "online_last_row_id_"

const SUBMIT_FAILED_TEXT: String = "Lähetys epäonnistui. Tarkista verkkoyhteys ja yritä uudelleen."
const BUSY_TEXT: String = "Palvelimella on ruuhkaa. Yritä hetken päästä uudelleen."
const REJECTED_TEXT: String = "Palvelin ei hyväksynyt tulosta."
const FETCH_FAILED_TEXT: String = "Listaa ei saatu ladattua. Tarkista verkkoyhteys."
## An exception text of the submit functions in the .sql files.
const SERVER_BUSY: String = "busy"


func _init() -> void:
	base_url = PROJECT_URL
	api_key = PUBLISHABLE_KEY
	var demo: bool = DemoRules.is_demo()
	table = DEMO_TABLE if demo else SEASON_TABLE
	submit_function = DEMO_SUBMIT_FUNCTION if demo else SEASON_SUBMIT_FUNCTION
	columns = "id,nickname,score,ending_type,days_survived,reputation,bottles,worth,styles_brewed,created_at"
	order = "score.desc,id.asc"
	# Older rows stay in the table but leave the list: their scores used other rules.
	filter = "score_version=eq.%d" % LeaderboardManager.SCORE_VERSION


## Test runs in developer mode stay off the lists.
func is_enabled() -> bool:
	return is_configured() and (DemoRules.is_demo() or SEASON_BOARD_LIVE) and not BrewEngine.is_developer_mode()


func submit_entry(nickname: String, entry: Dictionary) -> void:
	submit({
		"p_nickname": NicknameRules.clean(nickname),
		"p_ending_type": entry.get("ending_type", ""),
		"p_days_survived": entry.get("days_survived", 0),
		"p_reputation": entry.get("reputation", 0),
		"p_bottles": entry.get("lifetime_bottles_sold", 0),
		"p_worth": entry.get("worth", 0.0),
		"p_styles": entry.get("styles_brewed", 0),
		"p_score": entry.get("score", 0),
		"p_score_version": LeaderboardManager.SCORE_VERSION,
	})


## A server row as a leaderboard entry, with the name and row id added.
static func entry_from_row(row: Dictionary) -> Dictionary:
	return {
		"id": int(row.get("id", 0)),
		"nickname": str(row.get("nickname", "")),
		"ending_type": str(row.get("ending_type", "")),
		"days_survived": int(row.get("days_survived", 0)),
		"reputation": int(row.get("reputation", 0)),
		"lifetime_bottles_sold": int(row.get("bottles", 0)),
		"worth": float(row.get("worth", 0.0)),
		"styles_brewed": int(row.get("styles_brewed", 0)),
		"bonus": 0,
		"score": int(row.get("score", 0)),
		"date": str(row.get("created_at", "")).left(19),
	}


static func failure_text(action: StringName, message: String) -> String:
	if action == ACTION_FETCH:
		return FETCH_FAILED_TEXT
	if message == SERVER_BUSY:
		return BUSY_TEXT
	return REJECTED_TEXT if not message.is_empty() else SUBMIT_FAILED_TEXT


func saved_nickname() -> String:
	return str(SettingsManager.get_option(OPTION_NICKNAME, ""))


func save_nickname(nickname: String) -> void:
	SettingsManager.set_option(OPTION_NICKNAME, NicknameRules.clean(nickname))


func last_row_id() -> int:
	return int(SettingsManager.get_option(OPTION_LAST_ROW_ID_PREFIX + table, 0))


func save_last_row_id(row_id: int) -> void:
	SettingsManager.set_option(OPTION_LAST_ROW_ID_PREFIX + table, row_id)
