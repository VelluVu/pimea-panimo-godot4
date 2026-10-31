extends Node

@warning_ignore("unused_signal")
signal brewery_state_changed(brewery: Brewery)
@warning_ignore("unused_signal")
## `typed`: the bubble writes the line out; false for a bubble restored from a save.
signal dialogue_pushed(text: String, is_special: bool, slot_index: int, character_global_pos: Vector2, display_time: float, fade_time: float, typed: bool)
@warning_ignore("unused_signal")
signal style_discovered(style: int)
@warning_ignore("unused_signal")
signal lvv_raid_triggered(confiscated_bottles: int, fine_amount: float, reputation_lost: int)
## lvv_raid_triggered's payload once the raid squad has left, so LvvRaidWindow's recap
## comes after the player has watched the raid.
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
## The brewing table already holds BrewMixture.MAX_HOP_VARIETIES hops and refused another.
@warning_ignore("unused_signal")
signal hop_variety_limit_reached(limit: int)
@warning_ignore("unused_signal")
signal beer_brewed(style: int)
## Right after beer_brewed, for stats that need the batch (AchievementWiring).
@warning_ignore("unused_signal")
signal batch_brewed(batch: BrewBatch)
## A matched brew's spices changed its quality: positive for suitable ones, negative for
## a broken Reinheitsgebot.
@warning_ignore("unused_signal")
signal brew_spiced(style_name: String, spice_bonus: float)
## A sale went badly for the customer: refused on quality, wrong style or nothing in stock.
@warning_ignore("unused_signal")
signal customer_unhappy()
## Whether an accepted special event was fulfilled; `event_data` tells which one.
@warning_ignore("unused_signal")
signal special_event_resolved(succeeded: bool, event_data: SpecialEventData)
@warning_ignore("unused_signal")
signal group_visit_announced(banner_text: String)
@warning_ignore("unused_signal")
signal batch_bottled(bottles_lost: int, label_cost: float, style_name: String)
## A brew started fermenting (the run's first brew skips it).
@warning_ignore("unused_signal")
signal fermentation_started(style_name: String)
## After every fermentation tick, for the warehouse's time left.
@warning_ignore("unused_signal")
signal fermentation_ticked()
## A batch fermented into its keg; `batch.infected` tells whether the keg soured it.
@warning_ignore("unused_signal")
signal batch_fermented(batch: BrewBatch)
## A fermented batch's servings are in storage; the warehouse door floats it up.
@warning_ignore("unused_signal")
signal batch_stored(style_name: String, bottles: int)
@warning_ignore("unused_signal")
signal daily_bills_paid(electricity: int, water: int, total: int)
## Once per run from Brewery.trigger_ending(): "busted", "bankrupt", "survived" or
## "season_over".
@warning_ignore("unused_signal")
signal game_ended(ending_type: String)
## Once per level gained; LevelUpWindow rolls its perk choices.
@warning_ignore("unused_signal")
signal level_up_reached(new_level: int)
## The exact XP a brew granted (run_xp wraps on a level-up, so it cannot be diffed).
@warning_ignore("unused_signal")
signal brew_xp_gained(amount: int)
## The reputation a brew changed: a season's first of a style, or a failed brew.
@warning_ignore("unused_signal")
signal brew_reputation_gained(amount: int)
## The season's first batch of a style, a novelty (FirstBrewRules).
@warning_ignore("unused_signal")
signal season_first_brew(style: int, style_name: String)
## A sale's exact XP, without a position: the customer captures it around its sale and
## emits xp_popup_requested with one.
@warning_ignore("unused_signal")
signal sale_xp_gained(amount: int)
## A captured sale_xp_gained paired with a position; DialogView shows it.
@warning_ignore("unused_signal")
signal xp_popup_requested(amount: int, position: Vector2, tier: PopupTierRules.Tier)
## A sale's net reputation change, bar fight included. Captured like sale_xp_gained.
@warning_ignore("unused_signal")
signal sale_reputation_gained(amount: int)
## Every non-zero reputation change applied, by ReputationRules.Source, for DayRecapWindow.
@warning_ignore("unused_signal")
signal reputation_changed(amount: int, source: ReputationRules.Source)
## Reputation crossed into another ReputationTier, up (`rose`) or down.
@warning_ignore("unused_signal")
signal reputation_tier_changed(tier: ReputationTier, rose: bool)
## Emitted by TimeManager at a day change with the reputation that `tier`'s daily decay took.
@warning_ignore("unused_signal")
signal reputation_decayed(amount: int, tier: ReputationTier)
## Emitted by TimeManager at a day change with the LVV risk the night took (DayRules).
@warning_ignore("unused_signal")
signal risk_decayed(amount: int)
## LVV risk first reached LVV_HINT_RISK this season; the GUI explains the risk.
@warning_ignore("unused_signal")
signal lvv_hint_reached()
## The player kept the stray cat; ImmersionEventSpawner sends it strolling.
@warning_ignore("unused_signal")
signal cellar_cat_adopted()
## LVV risk is at LVV_INSPECTOR_VISIT_RISK or more and the inspector has not come yet.
@warning_ignore("unused_signal")
signal lvv_inspector_visit_due(brewery: Brewery)
## A delighted customer recommends the cellar; a friend of the same kind follows.
@warning_ignore("unused_signal")
signal friend_recommended(data: CustomerData)
## An unhappy customer spreads a bad review; the next walk-in comes later.
@warning_ignore("unused_signal")
signal bad_review_spread()
## A customer type became a regular or stopped being one (RegularRules).
@warning_ignore("unused_signal")
signal regular_status_changed(customer_title: String, is_regular: bool)
## A sale's tip income, captured like sale_reputation_gained.
@warning_ignore("unused_signal")
signal sale_tip_gained(amount: float)
## Like xp_popup_requested, for reputation; shown just below the XP popup.
@warning_ignore("unused_signal")
signal reputation_popup_requested(amount: int, position: Vector2, tier: PopupTierRules.Tier)
## Like xp_popup_requested, for the income and the tip; the tip shows once the income
## popup has faded.
@warning_ignore("unused_signal")
signal money_popup_requested(income: float, tip: float, position: Vector2, tip_tier: PopupTierRules.Tier)
## How loud the tip popup is, and the quality sold, which sets how loud the XP and
## reputation popups are.
@warning_ignore("unused_signal")
signal sale_popup_tiers_rated(tip_tier: PopupTierRules.Tier, beer_quality: float)
## A sale's word of mouth or regular status change, shown over the customer.
@warning_ignore("unused_signal")
signal customer_note_popup_requested(note: SaleOutcomeCapture.Note, position: Vector2)
## Emitted by DialogWiring when a critical popup appears, once per frame, at the customer.
@warning_ignore("unused_signal")
signal critical_gain_shown(position: Vector2)
## The exact amount a purchase cost, for the shop's popup.
@warning_ignore("unused_signal")
signal ingredient_purchased(cost: float)
## Reputation locks the ingredient. The shop already disables it, so this is rare.
@warning_ignore("unused_signal")
signal ingredient_purchase_locked(ingredient_name: String, required_reputation: int)
## The player cannot afford it; the shop allows the click, so this explains it.
@warning_ignore("unused_signal")
signal ingredient_purchase_underfunded(ingredient_name: String, price: float, money: float)
## Not enough stock to withdraw (all or nothing); DevConsole reports why.
@warning_ignore("unused_signal")
signal ingredient_sale_failed(ingredient_name: String, requested: int, in_stock: int)
## Closing the day early cost money and reputation and relieved some LVV risk.
@warning_ignore("unused_signal")
signal early_day_close_applied(money_cost: float, reputation_cost: int, risk_relief: int, close_count: int)
## A customer thrown out at a forced day close. Carries dialogue_slot, since group members
## share a counter slot but not a bubble.
@warning_ignore("unused_signal")
signal customer_evicted(dialogue_slot: int)
## Emitted by Inventory when batches leave the cellar: `count` empty kegs came back dirty.
@warning_ignore("unused_signal")
signal kegs_emptied(count: int)
## Emitted by KegWasher when a dirty keg was washed to `cleanliness` (0 to 1).
@warning_ignore("unused_signal")
signal keg_washed(cleanliness: float)
## A batch shipped to a BarContact: not a customer sale (no reputation, XP, tip or
## receipt), and shipping raises risk.
@warning_ignore("unused_signal")
signal keg_shipped_to_bar(style_name: String, bar_name: String, bottles: int, payout: float, risk_added: int)
## The day event rolled at a day change (never day 1), for the banner. A forecast: its
## customer bias starts later.
@warning_ignore("unused_signal")
signal day_event_announced(event: DayEventData)
## A sale turned into a bar fight; `message` is the customer's own line, shown as a toast.
@warning_ignore("unused_signal")
signal bar_fight_triggered(message: String)
## Next to bar_fight_triggered, so the customer throws one glass per broken bottle.
@warning_ignore("unused_signal")
signal bar_fight_started(broken_bottles: int)
## A customer's outburst (Persuasiakas fired at the ceiling) scattered the counter, for the
## shake; `message` is CustomerData.dialogue_outburst, shown as a toast.
@warning_ignore("unused_signal")
signal customer_outburst(message: String)
## A customer's own narration after a sale (Presidentti's visit), shown as a toast.
@warning_ignore("unused_signal")
signal customer_sale_narrated(message: String)
## A glass thrown in a bar fight hit the floor, for the shatter sound.
@warning_ignore("unused_signal")
signal glass_shattered()
## The day event's direct effect landed; `message` names the loss, shown as a toast.
@warning_ignore("unused_signal")
signal day_event_effect_triggered(message: String)
## The refund perk returned ingredients.
@warning_ignore("unused_signal")
signal ingredients_refunded()
## Emitted by CellarUpgradeShop after a cellar upgrade is bought; `level` is its new level.
@warning_ignore("unused_signal")
signal cellar_upgrade_purchased(upgrade: CellarUpgradeData, level: int)
## Emitted by CellarUpgradeShop when the player switches an owned machine on or off.
@warning_ignore("unused_signal")
signal machine_switched(upgrade_id: String, enabled: bool)
## A customer type bought something, so the Asiakaskirja marks it as met.
@warning_ignore("unused_signal")
signal customer_served(data: CustomerData)
## A walking customer put a foot down, for the footstep sound.
@warning_ignore("unused_signal")
signal customer_stepped(position: Vector2)
## A customer or group spoke, for the babble sound at `voice_pitch`.
@warning_ignore("unused_signal")
signal customer_spoke(position: Vector2, voice_pitch: float)
## The bartender started pouring; `speed_scale` is the pour animation's speed.
@warning_ignore("unused_signal")
signal beer_poured(position: Vector2, speed_scale: float)
## The console forced a season (SeasonRules.force()), so the decorations switch at once.
@warning_ignore("unused_signal")
signal season_forced(season: SeasonRules.Season)
