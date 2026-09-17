#class_name BrewerySignals (Autoload)
extends Node

@warning_ignore("unused_signal")
signal brewery_state_changed(brewery: Brewery)
@warning_ignore("unused_signal")
signal dialogue_pushed(text: String, is_special: bool, slot_index: int, character_global_pos: Vector2, display_time: float, fade_time: float)
@warning_ignore("unused_signal")
signal style_discovered(style: int)
@warning_ignore("unused_signal")
signal lvv_raid_triggered(confiscated_bottles: int, fine_amount: float, reputation_lost: int)
## Fired once the raid squad (LvvRaidSpawner) has finished walking in,
## seizing kegs, and walking back out — same payload as lvv_raid_triggered,
## just delayed until the visual sequence is done. LvvRaidWindow listens to
## THIS instead of the raw trigger, so the recap popup lands after the
## player has watched the raid happen instead of covering it immediately.
@warning_ignore("unused_signal")
signal lvv_raid_recap_ready(confiscated_bottles: int, fine_amount: float, reputation_lost: int)
@warning_ignore("unused_signal")
signal recipe_saved(recipe_name: String)
@warning_ignore("unused_signal")
signal bottles_sold(amount: int)
@warning_ignore("unused_signal")
signal beer_sale_breakdown(entry: SaleReceiptEntry)
@warning_ignore("unused_signal")
signal recipe_save_rejected()
@warning_ignore("unused_signal")
signal beer_brewed(style: int)
## Fired by CustomerManager.process_auto_sale() whenever a sale resolves to
## a negative outcome for the customer — rejected on quality, wrong style,
## or nothing in stock to offer at all (see its own emit site for the exact
## conditions). Read by DailyGoalManager for the UNHAPPY_CUSTOMERS_MAX goal
## type; no counter of this existed anywhere before that goal needed one.
@warning_ignore("unused_signal")
signal customer_unhappy()
## Fired by SpecialEventManager.process_accept() with try_fulfill()'s own
## result — previously discarded once it had picked a dialogue string.
## Read by DailyGoalManager for the SPECIAL_EVENT goal type.
@warning_ignore("unused_signal")
signal special_event_resolved(succeeded: bool)
@warning_ignore("unused_signal")
signal group_visit_announced(banner_text: String)
@warning_ignore("unused_signal")
signal batch_bottled(bottles_lost: int, label_cost: float, style_name: String)
@warning_ignore("unused_signal")
signal daily_bills_paid(electricity: int, water: int, total: int)
## Fired exactly once per run by Brewery.trigger_ending() — ending_type is
## one of "busted" (BUSTED_RAID_COUNT reached), "bankrupt"
## (check_bankruptcy()), or "survived" (TimeManager reaching the day
## target with the run not on the ropes). See GameEndWindow.
@warning_ignore("unused_signal")
signal game_ended(ending_type: String)
## Fired once per level gained by Brewery.add_xp() — see LevelUpWindow,
## which rolls its own perk choices via PerkRegistry when it hears this
## rather than the signal carrying pre-rolled choices itself.
@warning_ignore("unused_signal")
signal level_up_reached(new_level: int)
## Fired by Brewery.start_brew() with the exact XP that brew just granted
## (see Brewery.add_xp() — run_xp itself isn't safe to diff, it wraps
## around on a level-up). BrewPreparationPanel shows a "+X XP" popup at
## the "Pane" (start brew) button for this.
@warning_ignore("unused_signal")
signal brew_xp_gained(amount: int)
## Fired by CustomerManager.process_auto_sale() with the exact XP that
## sale just granted — same "don't diff run_xp" reasoning as
## brew_xp_gained. Carries no position: it's a synchronous bookkeeping
## signal callers who know their own customer position (Customer,
## CustomerSpawner's group-order path) capture around their own
## process_auto_sale() call, mirroring dev_console.gd's "sell" command
## capturing beer_sale_breakdown the same way — then those callers emit
## xp_popup_requested themselves with the position attached.
@warning_ignore("unused_signal")
signal sale_xp_gained(amount: int)
## Emitted by whoever actually knows where to show an XP popup (Customer,
## CustomerSpawner) once they've paired a captured sale_xp_gained amount
## with their own known position. DialogView listens for this since it
## already owns "how to place something at a customer's position".
@warning_ignore("unused_signal")
signal xp_popup_requested(amount: int, position: Vector2)
## Fired by CustomerManager.process_auto_sale() with this sale's net
## reputation change (post any bar-fight penalty) — same "synchronous
## bookkeeping signal, caller pairs it with a known position" pattern as
## sale_xp_gained/xp_popup_requested.
@warning_ignore("unused_signal")
signal sale_reputation_gained(amount: int)
## Fired by CustomerManager.process_auto_sale() with this sale's tip
## income — same pattern as sale_reputation_gained.
@warning_ignore("unused_signal")
signal sale_tip_gained(amount: float)
## Emitted by whoever knows where to show a reputation popup (Customer,
## CustomerSpawner) once they've paired a captured sale_reputation_gained
## amount with their own known position. DialogView shows it just below
## the "+X XP" popup at that same position.
@warning_ignore("unused_signal")
signal reputation_popup_requested(amount: int, position: Vector2)
## Emitted the same way as reputation_popup_requested, for a sale's tip
## income — shown next to the customer alongside the XP/reputation popups.
@warning_ignore("unused_signal")
signal tip_popup_requested(amount: float, position: Vector2)
## Fired by Brewery._on_buy_ingredient() with the exact amount charged —
## ShopView shows a "-X €" popup at the "Osta" (buy) button for this,
## mirroring BrewPreparationPanel's brew_xp_gained popup at "Pane".
@warning_ignore("unused_signal")
signal ingredient_purchased(cost: float)
## Fired by Brewery._on_buy_ingredient() when reputation locks out the
## ingredient at its current price. Real players can't normally reach this
## today — ingredient_option_button.gd already disables locked entries in
## the shop dropdown (see playtest_notes_7.txt) — but this used to be a
## silent print()-only failure, so the signal exists as the same cheap
## insurance the CustomerManager active_spawner guard is, in case that UI
## guard ever changes.
@warning_ignore("unused_signal")
signal ingredient_purchase_locked(ingredient_name: String, required_reputation: int)
## Fired by Brewery._on_buy_ingredient() when the player can't afford
## buy_price. Unlike the reputation lock above, the shop UI does not
## disable this case — clicking "Osta" with an empty wallet is a real,
## reachable path that previously only print()'d StringContainer.
## RESOURCE_ERROR to console with no on-screen explanation.
@warning_ignore("unused_signal")
signal ingredient_purchase_underfunded(ingredient_name: String, price: int, money: float)
## Fired by Brewery.apply_early_close_cost() whenever the player manually
## closes the day before the timer runs out — see that method's docstring
## for why this costs money/reputation but relieves some LVV risk, and
## TimeManager.force_advance_day() for where earliness is measured.
@warning_ignore("unused_signal")
signal early_day_close_applied(money_cost: float, reputation_cost: int, risk_relief: int, close_count: int)
## Fired by CustomerManager.evict_active_customers() for every customer
## thrown out when the day is force-closed while they were still on the
## counter — carries dialogue_slot (not assigned_slot: a group visit puts
## several customers on one assigned_slot but each keeps a distinct
## dialogue_slot) so DialogView can immediately clear that customer's
## speech bubble instead of leaving it to finish its normal display/fade
## timing for a customer who is already gone.
@warning_ignore("unused_signal")
signal customer_evicted(dialogue_slot: int)
## Fired by Brewery._on_bulk_sell_batch_requested() once a batch is dumped
## for cheap warehouse-clearing cash — deliberately separate from
## bottles_sold/beer_sale_breakdown since this isn't a real customer sale
## (no reputation/XP/tip, doesn't count toward DailyGoalManager's sales
## goals or the sale receipt log). BeerPatchPanel listens for this to show
## a payout popup at the sold row.
@warning_ignore("unused_signal")
signal batch_bulk_sold(style_name: String, bottles: int, payout: float)
## Fired by Brewery._on_ship_batch_to_bar_requested() once a batch is
## handed off to a BarContact — same "not a real sale" reasoning as
## batch_bulk_sold (no bottles_sold/reputation/XP/tip), but this one also
## carries risk_added since, unlike a bulk sale, shipping to a bar does
## raise Brewery.risk. BeerPatchPanel listens for this to show a payout/
## risk popup at the shipped row.
@warning_ignore("unused_signal")
signal keg_shipped_to_bar(style_name: String, bar_name: String, bottles: int, payout: float, risk_added: int)
## Fired by DayEventManager once per genuine day change (never on day 1 —
## see its own docstring) with whichever DayEventData it just rolled in
## secret. GUI shows event.announcement_text as a held banner; the actual
## spawn-bias window opens separately and later, per that event's own
## timing fields — this signal is purely "here's the forecast", not "the
## bias is active now".
@warning_ignore("unused_signal")
signal day_event_announced(event: DayEventData)