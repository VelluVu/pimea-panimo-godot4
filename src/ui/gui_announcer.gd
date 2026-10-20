class_name GuiAnnouncer
extends Node

## Turns game events into toasts (ToastStack), flash/hold/fade banners (BannerPresenter) and
## unlock cards (PopupCardStack).
## GUI owns the labels and calls start().

const DISCOVERY_TOAST_FORMAT: String = "Uusi oluttyyli löydetty: %s!"
const ACHIEVEMENT_CARD_HEADING: String = "Saavutus avattu!"
const CUSTOMER_CARD_HEADING: String = "Uusi asiakas!"
const MORE_ACHIEVEMENTS_FORMAT: String = "+%d muuta saavutusta"
const MORE_CUSTOMERS_FORMAT: String = "+%d muuta asiakasta"
## A burst past this many of one kind shows the first ones and a "+N muuta" card.
const MAX_UNLOCK_CARDS_PER_KIND: int = 4
const CUSTOMER_PORTRAIT_ANIMATION: StringName = &"idle"
const FALLBACK_CUSTOMER_ICON: Texture2D = preload("res://assets/textures/achievement_icons/customer.png")
const UNLOCK_CARD_WIDTH: float = 190.0
const UNLOCK_CARD_FONT_SIZE: int = 14
const REPUTATION_TIER_ROSE_TOAST_FORMAT: String = "Maineesi nousi: %s!"
const REPUTATION_TIER_FELL_TOAST_FORMAT: String = "Maineesi laski: %s."
const KEG_TO_WASH_TOAST_TEXT: String = "Uusi likainen tynnyri pestäväksi"
const FERMENTING_TOAST_FORMAT: String = "Uusi %s-erä käymässä"
const FERMENTED_TOAST_FORMAT: String = "%s valmis tynnyriin"
const HOP_VARIETY_LIMIT_TOAST_FORMAT: String = "Enintään %d humalalajiketta samaan olueen."
const LIGHTLY_SOURED_TOAST_FORMAT: String = "%s happani vähän likaisessa tynnyrissä."
const SOURED_TOAST_FORMAT: String = "%s happani likaisessa tynnyrissä!"
const BADLY_SOURED_TOAST_FORMAT: String = "%s happani pahasti likaisessa tynnyrissä!"
const NOVELTY_TOAST_FORMAT: String = "Uutuus: kauden ensimmäinen %s! Erä myy tiskillä +%d %% hintaan."
const DISCOVERY_TOAST_FLASH_SECONDS: float = 0.15
const DISCOVERY_TOAST_HOLD_SECONDS: float = 2.0
## Long toasts (a daily goal's reward line) stay up long enough to read.
const TOAST_HOLD_PER_CHARACTER_SECONDS: float = 0.05
const TOAST_MIN_HOLD_SECONDS: float = 3.0
const TOAST_MAX_HOLD_SECONDS: float = 7.0
## A burst at once would otherwise stack down the screen.
const TOAST_MAX_VISIBLE: int = 2
const DISCOVERY_TOAST_FADE_SECONDS: float = 0.6

const GROUP_VISIT_BANNER_FLASH_SECONDS: float = 0.2
const GROUP_VISIT_BANNER_HOLD_SECONDS: float = 4.0
const GROUP_VISIT_BANNER_FADE_SECONDS: float = 0.8

## Shorter than the first-brew hint: it repeats on every day a named event lands.
const DAY_EVENT_BANNER_FLASH_SECONDS: float = 0.25
const DAY_EVENT_BANNER_HOLD_SECONDS: float = 6.0
const DAY_EVENT_BANNER_FADE_SECONDS: float = 1.0

## The group banner's style, held long: a paragraph read once at run start.
const FIRST_BREW_HINT_TEXT: String = "Ovet ovat vielä hetken kiinni. Osta raaka-aineet ja pane ensimmäinen olut rauhassa."
const FIRST_BREW_HINT_FLASH_SECONDS: float = 0.25
const FIRST_BREW_HINT_HOLD_SECONDS: float = 12.0
const FIRST_BREW_HINT_FADE_SECONDS: float = 1.2
## A toast once a season, when LVV risk first reaches Brewery.LVV_HINT_RISK; the
## Panimokirja's guide explains the rest.
const LVV_HINT_TEXT: String = "LVV-riski nousee. Panimokirjan ohjeet kertovat, miten sen pitää kurissa."

var _toasts: ToastStack
var _group_visit_banner: BannerPresenter
var _day_event_banner: BannerPresenter
## The group visit and day event banners share the bottom strip, so they take turns.
var _bottom_banners: BannerQueue = BannerQueue.new()
var _first_brew_hint: BannerPresenter
var _unlock_cards: PopupCardStack
var _day_recap_window: DayRecapWindow

## Bumped per announcement, so a banner still waiting out the recap is dropped for a newer
## day's.
var _day_event_announce_serial: int = 0
## Unlocks that land in the same frame, flushed as one burst at the frame's end. Each is
## [icon, text].
var _pending_achievements: Array[Array] = []
var _pending_customers: Array[Array] = []


## Builds the presenters. `goals_panel` is pointed at when the first-brew hint ends.
func setup(toast_label: Label, group_visit_label: Label, day_event_label: Label, first_brew_hint_label: Label, goals_panel: DailyGoalsPanel, day_recap_window: DayRecapWindow, unlock_cards: PopupCardStack) -> void:
	_day_recap_window = day_recap_window
	_unlock_cards = unlock_cards
	_unlock_cards.card_width = UNLOCK_CARD_WIDTH
	_unlock_cards.heading_font_size = UNLOCK_CARD_FONT_SIZE
	_unlock_cards.text_font_size = UNLOCK_CARD_FONT_SIZE
	# A long toast (several unlocks at once) wraps instead of running off the screen.
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toasts = ToastStack.new(toast_label, DISCOVERY_TOAST_FLASH_SECONDS, DISCOVERY_TOAST_HOLD_SECONDS, DISCOVERY_TOAST_FADE_SECONDS)
	_toasts.hold_per_character = TOAST_HOLD_PER_CHARACTER_SECONDS
	_toasts.min_hold_seconds = TOAST_MIN_HOLD_SECONDS
	_toasts.max_hold_seconds = TOAST_MAX_HOLD_SECONDS
	_toasts.max_visible = TOAST_MAX_VISIBLE
	BannerPresenter.add_backing(group_visit_label)
	BannerPresenter.add_backing(day_event_label)
	_group_visit_banner = BannerPresenter.new(group_visit_label, GROUP_VISIT_BANNER_FLASH_SECONDS, GROUP_VISIT_BANNER_HOLD_SECONDS, GROUP_VISIT_BANNER_FADE_SECONDS)
	# A plain fade-in, not the flash: it is a forecast, not an arrival.
	_day_event_banner = BannerPresenter.new(day_event_label, DAY_EVENT_BANNER_FLASH_SECONDS, DAY_EVENT_BANNER_HOLD_SECONDS, DAY_EVENT_BANNER_FADE_SECONDS, false)
	# Natural end and early dismissal both hide it and hand off to the goals panel.
	_first_brew_hint = BannerPresenter.new(first_brew_hint_label, FIRST_BREW_HINT_FLASH_SECONDS, FIRST_BREW_HINT_HOLD_SECONDS, FIRST_BREW_HINT_FADE_SECONDS, true, true, true, goals_panel.draw_attention)


## Connects every event source and shows the first-brew hint on a fresh run.
func start() -> void:
	BrewerySignals.style_discovered.connect(_on_style_discovered)
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
	CustomerRegistry.customer_unlocked.connect(_on_customer_unlocked)
	DailyGoalManager.daily_goal_resolved.connect(_on_daily_goal_resolved)
	BrewerySignals.early_day_close_applied.connect(_on_early_day_close_applied)
	BrewerySignals.reputation_tier_changed.connect(_on_reputation_tier_changed)
	BrewerySignals.group_visit_announced.connect(_on_group_visit_announced)
	BrewerySignals.brew_spiced.connect(_on_brew_spiced)
	BrewerySignals.season_first_brew.connect(_on_season_first_brew)
	BrewerySignals.day_event_announced.connect(_on_day_event_announced)
	BrewerySignals.lvv_hint_reached.connect(_on_lvv_hint_reached)
	BrewerySignals.kegs_emptied.connect(_on_kegs_emptied)
	BrewerySignals.hop_variety_limit_reached.connect(func(limit: int) -> void: _show_toast(tr(HOP_VARIETY_LIMIT_TOAST_FORMAT) % limit))
	BrewerySignals.fermentation_started.connect(_on_fermentation_started)
	BrewerySignals.batch_fermented.connect(_on_batch_fermented)

	# Shown while the clock is stopped, so the missing customers do not read as a bug.
	if TimeManager.day_timer.is_stopped():
		BrewerySignals.brewery_state_changed.connect(_on_first_brew_hint_state_changed)
		_first_brew_hint.present(FIRST_BREW_HINT_TEXT)


func _on_season_first_brew(_style: int, style_name: String) -> void:
	_show_toast(tr(NOVELTY_TOAST_FORMAT) % [UiText.of(style_name), roundi(FirstBrewRules.NOVELTY_PRICE_BONUS * 100.0)])


func _on_brew_spiced(style_name: String, spice_bonus: float) -> void:
	_show_toast(ToastText.spiced_brew(style_name, spice_bonus))


func _on_style_discovered(style: int) -> void:
	_show_toast(tr(DISCOVERY_TOAST_FORMAT) % BeerStyle.get_style_string_from_style(style))


func _on_achievement_unlocked(achievement_id: String, title: String) -> void:
	var achievement: AchievementData = AchievementManager.get_achievement(achievement_id)
	_queue_unlock(_pending_achievements, achievement.icon if achievement != null else null, title)


func _on_customer_unlocked(title: String) -> void:
	_queue_unlock(_pending_customers, _customer_portrait(CustomerRegistry.get_customer(title)), title)


func _queue_unlock(pending: Array[Array], icon: Texture2D, title: String) -> void:
	if _pending_achievements.is_empty() and _pending_customers.is_empty():
		_flush_unlocks.call_deferred()
	pending.append([icon, title])


func _customer_portrait(customer: CustomerData) -> Texture2D:
	if customer == null or customer.sprite_frames == null or not customer.sprite_frames.has_animation(CUSTOMER_PORTRAIT_ANIMATION):
		return FALLBACK_CUSTOMER_ICON
	return CharacterBust.of(customer.sprite_frames.get_frame_texture(CUSTOMER_PORTRAIT_ANIMATION, 0))


func _flush_unlocks() -> void:
	_show_unlock_cards(_pending_achievements, ACHIEVEMENT_CARD_HEADING, MORE_ACHIEVEMENTS_FORMAT)
	_show_unlock_cards(_pending_customers, CUSTOMER_CARD_HEADING, MORE_CUSTOMERS_FORMAT)
	_pending_achievements.clear()
	_pending_customers.clear()


func _show_unlock_cards(unlocks: Array[Array], heading: String, more_format: String) -> void:
	var shown: int = unlocks.size() if unlocks.size() <= MAX_UNLOCK_CARDS_PER_KIND else MAX_UNLOCK_CARDS_PER_KIND - 1
	for index: int in shown:
		_unlock_cards.show_card(unlocks[index][0], tr(heading), tr(unlocks[index][1]))
	if shown < unlocks.size():
		_unlock_cards.show_card(unlocks[shown][0], tr(heading), tr(more_format) % (unlocks.size() - shown))


func _on_daily_goal_resolved(goal_name: String, succeeded: bool, money: int, reputation: int, xp: int, risk: int) -> void:
	_show_toast(ToastText.goal_resolved(goal_name, succeeded, money, reputation, xp, risk))


## Explains the money/reputation shift of a forced close.
func _on_early_day_close_applied(money_cost: float, reputation_cost: int, risk_relief: int, _close_count: int) -> void:
	_show_toast(ToastText.early_close(money_cost, reputation_cost, risk_relief))


func _on_reputation_tier_changed(tier: ReputationTier, rose: bool) -> void:
	_show_toast(tr(REPUTATION_TIER_ROSE_TOAST_FORMAT if rose else REPUTATION_TIER_FELL_TOAST_FORMAT) % tr(tier.tier_name))


func _on_group_visit_announced(banner_text: String) -> void:
	_bottom_banners.show(_group_visit_banner, tr(banner_text))


## The day's forecast banner waits for the recap window, which reacts to the same
## day_changed.
func _on_day_event_announced(event: DayEventData) -> void:
	_day_event_announce_serial += 1
	var serial: int = _day_event_announce_serial

	await get_tree().process_frame
	if _day_recap_window.visible:
		await _day_recap_window.hidden
	if serial != _day_event_announce_serial:
		return

	_bottom_banners.show(_day_event_banner, tr(event.announcement_text), GUISignals.day_event_banner_shown.emit.bind(event))


## Dismisses the hint once the clock starts, handing off to DailyGoalsPanel.
func _on_first_brew_hint_state_changed(_brewery: Brewery) -> void:
	if TimeManager.day_timer.is_stopped():
		return

	BrewerySignals.brewery_state_changed.disconnect(_on_first_brew_hint_state_changed)
	_first_brew_hint.dismiss_early()


func _on_kegs_emptied(_count: int) -> void:
	var brewery : Brewery = BrewEngine.current_brewery
	if brewery != null and brewery.machine_active(CellarMachines.KEG_WASHER):
		return
	_show_toast(tr(KEG_TO_WASH_TOAST_TEXT))


func _on_fermentation_started(style_name: String) -> void:
	_show_toast(tr(FERMENTING_TOAST_FORMAT) % UiText.of(style_name))


func _on_batch_fermented(batch: BrewBatch) -> void:
	var format : String = FERMENTED_TOAST_FORMAT
	match batch.get_sour_level():
		FermentationRules.SourLevel.LIGHT:
			format = LIGHTLY_SOURED_TOAST_FORMAT
		FermentationRules.SourLevel.CLEAR:
			format = SOURED_TOAST_FORMAT
		FermentationRules.SourLevel.STRONG:
			format = BADLY_SOURED_TOAST_FORMAT
	_show_toast(tr(format) % UiText.of(batch.beer_style.style_name))


func _on_lvv_hint_reached() -> void:
	_show_toast(tr(LVV_HINT_TEXT))


## ToastText returns an empty string for "no toast".
func _show_toast(text: String) -> void:
	if not text.is_empty():
		_toasts.show_toast(text)
		GUISignals.toast_shown.emit()
