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
## Same payload as lvv_raid_triggered, delayed until the raid squad (LvvRaidSpawner) has
## finished walking in, seizing kegs and leaving. LvvRaidWindow listens to this, so the
## recap lands after the player has watched the raid.
@warning_ignore("unused_signal")
signal lvv_raid_recap_ready(confiscated_bottles: int, fine_amount: float, reputation_lost: int)
@warning_ignore("unused_signal")
signal recipe_saved(recipe_name: String)
@warning_ignore("unused_signal")
signal bottles_sold(amount: int)
@warning_ignore("unused_signal")
signal beer_sale_breakdown(entry: SaleReceiptEntry)
## reason is a RecipeSaveRules.Rejection; same_recipe_name is set for DUPLICATE.
@warning_ignore("unused_signal")
signal recipe_save_rejected(reason: int, same_recipe_name: String)
@warning_ignore("unused_signal")
signal beer_brewed(style: int)
## Emitted by Brewer for a matched brew whose spices changed its quality: positive for
## suitable spices, negative for a broken Reinheitsgebot.
@warning_ignore("unused_signal")
signal brew_spiced(style_name: String, spice_bonus: float)
## Emitted by SaleProcessor when a sale goes badly for the customer: rejected on quality,
## wrong style, or nothing in stock. DailyGoalManager reads it for UNHAPPY_CUSTOMERS_MAX.
@warning_ignore("unused_signal")
signal customer_unhappy()
## Emitted by SpecialEventManager.process_accept() with whether the event was
## fulfilled. `event_data` says which event resolved, so AchievementManager can tell a
## RiskBribeEventData success from other special events. A connected method may take
## fewer parameters than the signal emits.
@warning_ignore("unused_signal")
signal special_event_resolved(succeeded: bool, event_data: SpecialEventData)
@warning_ignore("unused_signal")
signal group_visit_announced(banner_text: String)
@warning_ignore("unused_signal")
signal batch_bottled(bottles_lost: int, label_cost: float, style_name: String)
## Emitted by Brewer once a brewed batch's bottles are in storage. The warehouse door
## floats it up.
@warning_ignore("unused_signal")
signal batch_stored(style_name: String, bottles: int)
@warning_ignore("unused_signal")
signal daily_bills_paid(electricity: int, water: int, total: int)
## Emitted once per run by Brewery.trigger_ending(). `ending_type` is "busted", "bankrupt"
## "survived" or "season_over" (the last two on the season's last day). See GameEndWindow.
@warning_ignore("unused_signal")
signal game_ended(ending_type: String)
## Emitted once per level gained by Brewery.add_xp(). LevelUpWindow rolls its own perk
## choices when it hears this.
@warning_ignore("unused_signal")
signal level_up_reached(new_level: int)
## Emitted by Brewer.start_brew() with the exact XP the brew granted (run_xp wraps on a
## level-up, so it cannot be diffed). BrewPreparationPanel shows a "+X XP" popup at the
## brew button.
@warning_ignore("unused_signal")
signal brew_xp_gained(amount: int)
## Emitted by Brewer.start_brew() with the reputation a first brew of a style (or a
## failed brew) changed. BrewPreparationPanel shows it beside the XP popup.
@warning_ignore("unused_signal")
signal brew_reputation_gained(amount: int)
## Emitted by SaleProcessor with the exact XP a sale granted. It carries no position:
## callers that know their customer (Customer, GroupVisitDirector) capture it around their
## own process_auto_sale() call, then emit xp_popup_requested with a position.
@warning_ignore("unused_signal")
signal sale_xp_gained(amount: int)
## Emitted by whoever knows where to show an XP popup, once they have paired a captured
## sale_xp_gained amount with a position. DialogView places it.
@warning_ignore("unused_signal")
signal xp_popup_requested(amount: int, position: Vector2, tier: PopupTierRules.Tier)
## Emitted by SaleProcessor with a sale's net reputation change, after any bar-fight
## penalty. Same capture-and-pair pattern as sale_xp_gained.
@warning_ignore("unused_signal")
signal sale_reputation_gained(amount: int)
## Emitted by Brewery.change_reputation() with every non-zero change actually applied,
## tagged with where it came from (ReputationRules.Source). DayRecapWindow sums them.
@warning_ignore("unused_signal")
signal reputation_changed(amount: int, source: ReputationRules.Source)
## Emitted by Brewery.change_reputation() when reputation crosses into another
## ReputationTier, up (`rose`) or down.
@warning_ignore("unused_signal")
signal reputation_tier_changed(tier: ReputationTier, rose: bool)
## Emitted by TimeManager at a day change with the reputation that `tier`'s daily decay took.
@warning_ignore("unused_signal")
signal reputation_decayed(amount: int, tier: ReputationTier)
## Emitted by TimeManager at a day change with the LVV risk the night took (DayRules).
@warning_ignore("unused_signal")
signal risk_decayed(amount: int)
## Emitted by Brewery the first time in a season LVV risk reaches LVV_HINT_RISK; the
## GUI explains the risk and how to keep it down.
@warning_ignore("unused_signal")
signal lvv_hint_reached()
## Emitted by Brewery the first time in a season LVV risk reaches LVV_INSPECTOR_VISIT_RISK;
## CustomerSpawner sends the inspector in to look around.
@warning_ignore("unused_signal")
signal lvv_inspector_visit_due()
## Emitted by SaleProcessor when a delighted customer recommends the cellar; the
## spawner sends in a friend of the same kind (WordOfMouthRules).
@warning_ignore("unused_signal")
signal friend_recommended(data: CustomerData)
## Emitted by SaleProcessor when an unhappy customer spreads a bad review; the
## spawner delays the next walk-in.
@warning_ignore("unused_signal")
signal bad_review_spread()
## Emitted by SaleProcessor when a customer type becomes a regular or stops being
## one (RegularRules).
@warning_ignore("unused_signal")
signal regular_status_changed(customer_title: String, is_regular: bool)
## Emitted by SaleProcessor with a sale's tip income. Same pattern as sale_reputation_gained.
@warning_ignore("unused_signal")
signal sale_tip_gained(amount: float)
## Emitted like xp_popup_requested, for reputation. DialogView shows it just below the
## XP popup.
@warning_ignore("unused_signal")
signal reputation_popup_requested(amount: int, position: Vector2, tier: PopupTierRules.Tier)
## Emitted like xp_popup_requested, for what the bottles cost and the tip on top.
## DialogView shows the tip once the income popup has faded.
@warning_ignore("unused_signal")
signal money_popup_requested(income: float, tip: float, position: Vector2, tip_tier: PopupTierRules.Tier)
## Emitted by SaleProcessor after sale_tip_gained with how loud the tip popup is and the
## quality of the beer sold, which sets how loud the XP and reputation popups are.
@warning_ignore("unused_signal")
signal sale_popup_tiers_rated(tip_tier: PopupTierRules.Tier, beer_quality: float)
## Emitted by SaleOutcomeCapture with a sale's word of mouth or regular status change,
## shown over the customer instead of a toast.
@warning_ignore("unused_signal")
signal customer_note_popup_requested(note: SaleOutcomeCapture.Note, position: Vector2)
## Emitted by DialogWiring when a critical popup appears, once per frame, at the customer.
@warning_ignore("unused_signal")
signal critical_gain_shown(position: Vector2)
## Emitted by IngredientTrader with the exact amount charged. ShopView shows a "-X €"
## popup at the buy button.
@warning_ignore("unused_signal")
signal ingredient_purchased(cost: float)
## Emitted by IngredientTrader when reputation locks the ingredient. The shop dropdown
## already disables locked entries, so players rarely reach this; it replaces a
## silent print().
@warning_ignore("unused_signal")
signal ingredient_purchase_locked(ingredient_name: String, required_reputation: int)
## Emitted by IngredientTrader when the player cannot afford the price. Unlike the
## lock, the shop does not prevent this, so it explains the failed click.
@warning_ignore("unused_signal")
signal ingredient_purchase_underfunded(ingredient_name: String, price: int, money: float)
## Emitted by IngredientTrader when the requested amount cannot be withdrawn (stock is
## all-or-nothing). Lets listeners, today only DevConsole, report why nothing sold.
@warning_ignore("unused_signal")
signal ingredient_sale_failed(ingredient_name: String, requested: int, in_stock: int)
## Emitted by InspectionService.apply_early_close_cost() when the player closes the day
## early: it costs money and reputation but relieves some LVV risk.
@warning_ignore("unused_signal")
signal early_day_close_applied(money_cost: float, reputation_cost: int, risk_relief: int, close_count: int)
## Emitted by CustomerManager.evict_active_customers() for each customer thrown out when the
## day is force-closed. Carries dialogue_slot, not the counter slot: a group shares one
## counter slot but each member keeps its own dialogue_slot. DialogView clears that bubble
## at once.
@warning_ignore("unused_signal")
signal customer_evicted(dialogue_slot: int)
## Emitted by BatchDistributor when a batch is dumped for warehouse-clearing cash. Separate
## from bottles_sold on purpose: it is not a customer sale (no reputation, XP, tip, goal
## progress or receipt). BeerPatchPanel shows a payout popup.
@warning_ignore("unused_signal")
signal batch_bulk_sold(style_name: String, bottles: int, payout: float)
## Emitted by BatchDistributor when a batch is shipped to a BarContact. Like
## batch_bulk_sold it is not a real sale, but it carries risk_added because shipping does
## raise risk. BeerPatchPanel shows a payout and risk popup.
@warning_ignore("unused_signal")
signal keg_shipped_to_bar(style_name: String, bar_name: String, bottles: int, payout: float, risk_added: int)
## Emitted by DayEventManager on each real day change (never day 1) with the DayEventData
## it rolled in secret. GUI shows its announcement as a banner. It is a forecast: the
## spawn-bias window opens later, per the event's own timing.
@warning_ignore("unused_signal")
signal day_event_announced(event: DayEventData)
## Emitted by SaleProcessor when a sale becomes a bar fight. `message` is the
## customer's own bar-fight line with the broken-bottle count filled in. SaleFlashStack
## shows it as its own toast, not in the customer's speech bubble.
@warning_ignore("unused_signal")
signal bar_fight_triggered(message: String)
## Emitted by SaleProcessor next to bar_fight_triggered, so the customer who started it can
## play the rampage with one thrown glass per broken bottle.
@warning_ignore("unused_signal")
signal bar_fight_started(broken_bottles: int)
## A glass thrown in a bar fight hit the floor, for the shatter sound.
@warning_ignore("unused_signal")
signal glass_shattered()
## Emitted by DayEventManager when the day's event has a direct effect that actually
## landed. `message` is its effect_toast_format with the lost amount filled in,
## shown as its own toast.
@warning_ignore("unused_signal")
signal day_event_effect_triggered(message: String)
## Emitted by Brewer when the refund perk's roll succeeds and something was refunded. No
## payload; shown as a good-news toast.
@warning_ignore("unused_signal")
signal ingredients_refunded()
## Emitted by CellarUpgradeShop after a cellar upgrade is bought; `level` is its new level.
@warning_ignore("unused_signal")
signal cellar_upgrade_purchased(upgrade: CellarUpgradeData, level: int)
## Emitted by SaleProcessor after a customer bought something, and by
## GroupVisitDirector for the other types in a mixed group; the Asiakaskirja
## remembers the customer type as met (CustomerUnlockTracker).
@warning_ignore("unused_signal")
signal customer_served(data: CustomerData)
## A walking customer put a foot down, for the footstep sound.
@warning_ignore("unused_signal")
signal customer_stepped(position: Vector2)
## A customer or a group said something out loud, for the babble sound. `voice_pitch`
## is the speaker's CustomerData.voice_pitch.
@warning_ignore("unused_signal")
signal customer_spoke(position: Vector2, voice_pitch: float)
## The bartender started pouring; `speed_scale` is the pour animation's speed.
@warning_ignore("unused_signal")
signal beer_poured(position: Vector2, speed_scale: float)
