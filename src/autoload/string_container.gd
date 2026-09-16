extends Node

const PATH_TO_INGREDIENTS : String = "res://src/resources/ingredients/"
const PATH_TO_BREW_STYLES : String = "res://src/resources/beer_styles/"

const TUNTEMATON : String = "Tuntematon"
const KOTIKALJA : String = "Kotikalja"
const BULKKILAGER : String = "Bulkki Lager"
const TUMMALAGER : String = "Tumma Lager"
const PALEALE : String = "Pale Ale"
const AMBERALE : String = "Amber Ale"
const IPA : String = "IPA"
const HELLES : String = "Helles"
const VIENNALAGER : String = "Vienna Lager"
const MARZEN : String = "Märzen"
const BALTICPORTTERI : String = "Baltic Portteri"
const DOPPELBOCK : String = "Doppelbock"
const HEFEWEIZEN : String = "Hefeweizen"
const WITBIER : String = "Witbier"
const SESSIONALE : String = "Session Ale"
const SAISON : String = "Saison"
const BELGIANDUBBEL : String = "Belgian Dubbel"
const BELGIANSTRONGDARK : String = "Belgian Strong Dark Ale"
const SCOTCHALE : String = "Scotch Ale"
const BARLEYWINE : String = "Barleywine"
const IMPERIALSTOUT : String = "Imperial Stout"
const ALKOHOLITONIPA : String = "Alkoholiton IPA"
const ALKOHOLITONLAGER : String = "Alkoholiton Lager"

const KG : String = "kg"
const G : String = "g"
const KPL : String = "kpl"
const SLASH : String = "/"
const RESOURCE_END : String = ".tres"
const REMAP_END : String = ".remap"

const MALT_STAT_STRING : String = "EBC: %s"
const HOP_STAT_STRING : String = "Alfahapot: %s%% / Beetahapot: %s%%"
const YEAST_STAT_STRING : String = "Käymisaste: %s%%"
const INGREDIENT_LABEL_WITH_STAT_STRING : String = "%s: %s %s (%s)"

const RECIPE_LIBRARY_BUTTON_TEXT : String = "Reseptikirja"
const RECIPE_LIBRARY_TITLE : String = "Reseptikirja"
const RECIPE_LIBRARY_CLOSE_TEXT : String = "Sulje"
## Deliberately still withholds the exact EBC/IBU ranges (that's the "brew
## it to find out" part) but gives more to go on than yeast alone — ABV
## isn't derived from the player's ingredient choices at all (it's a fixed
## style property, see BeerStyle.abv), so revealing it doesn't spoil
## anything about the actual brewing puzzle; the malt-weight minimum is a
## coarse hint (a floor, not the target), not the precise EBC math.
const RECIPE_LIBRARY_LOCKED_STRING : String = "??? (%.1f%% ABV) – vaatii: hiiva %s, vähintään %d kg mallasta"
const RECIPE_LIBRARY_ROW_STRING : String = "%s (%.1f%% ABV) — EBC %s-%s, IBU %s-%s (hiiva: %s)"
const RECIPE_LIBRARY_HOP_HINT_STRING : String = "\nSuosikkihumala: %s"
const RECIPE_LIBRARY_MALT_HINT_STRING : String = "\nVaadittu mallas: %s"
## Coarse, bucketed hints (see BeerStyle.get_color_hint/get_bitterness_hint)
## — locked-row only, deliberately still withholding the exact EBC/IBU
## numbers those buckets are derived from.
const RECIPE_LIBRARY_COLOR_HINT_STRING : String = "\nVäri: %s"
const RECIPE_LIBRARY_BITTERNESS_HINT_STRING : String = "\nKatkeruus: %s"
const RECIPE_LIBRARY_MALT_BLEND_HINT_STRING : String = "\nVaatii mallasseoksen"

const COLOR_HINT_PALE : String = "vaalea"
const COLOR_HINT_GOLDEN : String = "kultainen"
const COLOR_HINT_AMBER : String = "meripihkan"
const COLOR_HINT_BROWN : String = "ruskea"
const COLOR_HINT_BLACK : String = "musta"

const BITTERNESS_HINT_MILD : String = "mieto"
const BITTERNESS_HINT_BALANCED : String = "tasapainoinen"
const BITTERNESS_HINT_BITTER : String = "karvas"
const BITTERNESS_HINT_VERY_BITTER : String = "erittäin karvas"

const INGREDIENT_LOCKED_LABEL : String = "??? – vaatii mainetta: %d"
const INGREDIENT_LOCKED_ERROR : String = "Ainesosa ERROR: %s vaatii vähintään %d mainetta"
const INGREDIENT_UNLOCKED_TOAST_FORMAT : String = "Uusi humala saatavilla: %s!"

const LEADERBOARD_BUTTON_TEXT : String = "Ennätykset"
const LEADERBOARD_TITLE : String = "Ennätykset"
const LEADERBOARD_CLOSE_TEXT : String = "Sulje"
const LEADERBOARD_EMPTY_STRING : String = "Ei vielä ennätyksiä — pelaa ensimmäinen erä!"
const LEADERBOARD_ROW_FORMAT : String = "#%d  %s — %d pv, %d mainetta, %d annosta (%s)\n%s — pisteet: %d"
const LEADERBOARD_ENDING_BUSTED : String = "Jäi kiinni"
const LEADERBOARD_ENDING_BANKRUPT : String = "Konkurssi"
const LEADERBOARD_ENDING_SURVIVED : String = "Selvisi"

const NEW_RECORD_STRING : String = "\n\nUUSI ENNÄTYS!"
const RANK_STRING : String = "\n\nSijoitus: #%d / %d"

const HOP_FLAVOR_STRING : String = "Maku: %s"
const HOP_FLAVOR_CITRUS : String = "Sitruksinen"
const HOP_FLAVOR_TROPICAL : String = "Trooppinen"
const HOP_FLAVOR_PINE : String = "Mäntyinen"
const HOP_FLAVOR_NOBLE : String = "Jalo"
const HOP_FLAVOR_EARTHY : String = "Maanläheinen"

const QUALITY_TIER_POOR : String = "Heikko"
const QUALITY_TIER_MEDIOCRE : String = "Tyydyttävä"
const QUALITY_TIER_GOOD : String = "Hyvä"
const QUALITY_TIER_EXCELLENT : String = "Erinomainen"
const QUALITY_TIER_MASTERFUL : String = "Mestarillinen"

const BREW_QUALITY_BREAKDOWN_TOOLTIP : String = "Osumatarkkuus: %s%%\nHumalalajeja käytetty: %s\nHumalatasapaino-bonus: %s%%\nMakuosuma: %s"
const YES_STRING : String = "Kyllä"
const NO_STRING : String = "Ei"

const DATABASE_STRING : String = "Database"
const LIST_STRING : String = "List"
const INVENTORY_STRING : String = "Inventory"
const MONEY_STRING : String = "Money"

const INVALID_ID_ERROR : String = "%s ERROR: item with ID: %s does not exist in %s"
const WITHDRAW_NO_STOCK_ERROR : String = "%s ERROR: withdraw failed. Not enough stock for: %s"
const WITHDRAW_INVALID_AMOUNT_ERROR : String = "%s ERROR: withdraw failed. Invalid withdraw amount: %s"
const RESOURCE_ERROR : String = "Resource ERROR: currently have %s, and need %s %s"
const TABLE_EMPTY_ERROR : String = "Start Brewing ERROR: table has no ingredients"
const NOT_ENOUGH_INGREDIENTS_ERROR : String = "Brew resolver ERROR: not enough ingredients"
const DATABASE_DUBLICATE_KEY_ERROR : String = "ERROR: ID %s is already in use! Dublicate key: %s"
const INVALID_EXPORT_SCRIPT_ERROR : String = "%s ERROR: Export script is null"
const TYPE_ERROR : String = "ERROR: ID %s is correct type, but file is not correct inherited class!"
const INVALID_ADD_AMOUNT_ERROR : String = "%s ERROR: Trying to add %s amount of ingredient with ID: %s"

const NO_CUSTOMERS_IN_RESOURCES_WARNING : String = "CustomerManager: The customer pool is empty! Check that .tres resources exists."
const SERVING_NULL_CUSTOMER_WARNING : String = "CustomerManager: Tried to serve beer, but there are no customer."
const NOT_ENOUGH_BOTTLES_IN_BATCH_WARNING : String = "CustomerManager: Not enough bottles in batch!"

const SELL_MESSAGE : String = "Sold %s amount of stuff, and you get %s€ back"
const SUCCESFULL_BREW_MESSAGE : String = "Successful brew batch: "
const NEW_GAME_MESSAGE : String = "New game started! Brewery established."
const FOLDER_SCAN_MESSAGE : String = "[IngredientDatabase] Start recursive folder scan..."
const FOLDER_SCAN_COMPLETE_MESSAGE : String = "[IngredientDatabase] Database fully sorted! Total registered items: "
const DATABASE_FOUND_DATA_MESSAGE : String = "[IngredientDatabase] found from subfolder: %s (ID: %s)"
const CREATED_MISSING_BEER_STYLES_FOLDER : String = "Created missing beer_styles folder: "
const LOADED_BEER_STYLES_MESSAGE : String = "Ladattu yhteensä %s oluttyyliä datasta:"
const BEER_BATCH_STARTED_SPOILING_MESSAGE : String = "HUOMIO: Erä %s (Ikä: %s päivää) alkaa etikkoitua kellarissa!"
const DAY_CHANGED_MESSAGE : String = "--- DAY CHANGED: Day %s starts ---"

const WRONG_STYLE_DIALOGUE_STRING : String = "Ei tää sitä ollu mitä hain, mut jotaki kuitenki."

const LVV_RAID_TITLE : String = "LVV-TARKASTUS!"
const LVV_RAID_MESSAGE : String = "Alkoholitarkastajat ryntäsivät kellariin ja takavarikoivat %s annosta valmista olutta! Lisäksi kirjoittivat sakon: %.1f €, ja maineesi laski %s pistettä."
const LVV_RAID_CLOSE_TEXT : String = "Selvä..."

## RunPerk.get_stat_summary() lines — only the non-neutral fields are ever
## shown (see that function), so every perk's numbers are always positive.
const PERK_QUALITY_STAT_STRING : String = "Laatu: +%d %%"
const PERK_REPUTATION_STAT_STRING : String = "Maineen kertymä: +%d %%"
const PERK_TIP_STAT_STRING : String = "Tipit: +%d %%"
const PERK_DISTRIBUTION_STAT_STRING : String = "Jakelutulot: %+d %%"
## Appended to a perk's stat summary when RunPerk.stacks_additively is
## true — the default (false, no hint shown) compounds with repeat
## picks, so this only needs to call out the exception.
const PERK_ADDITIVE_STACKING_HINT : String = "(tasainen kasvu, ei kerry)"

## RunPerk.get_tier_label() — shown on LevelUpWindow's cards (color-coded
## via RunPerk.get_tier_color()) so a level-up's rarity is actually visible
## instead of every perk offer looking the same.
const PERK_TIER_COMMON : String = "Tavallinen"
const PERK_TIER_RARE : String = "Harvinainen"
const PERK_TIER_LEGENDARY : String = "Legendaarinen"

## RunModifier.get_stat_summary() lines — signed (%+d) since a modifier can
## push either direction (see e.g. Kireä LVV's lower raid threshold).
const MODIFIER_RAID_THRESHOLD_STAT_STRING : String = "Ratsiakynnys: %+d %%"
const MODIFIER_INGREDIENT_PRICE_STAT_STRING : String = "Ainehinnat: %+d %%"

const RUN_EFFECTS_BUTTON_TOOLTIP : String = "Kierroksen tilastot"
const RUN_EFFECTS_TITLE : String = "Kierroksen tilastot"
const RUN_EFFECTS_CLOSE_TEXT : String = "Sulje"
const RUN_EFFECTS_MODIFIER_HEADER : String = "Olosuhteet: %s"
const RUN_EFFECTS_RAID_THRESHOLD_STRING : String = "Ratsiakynnys tällä kierroksella: %d riskiä"
const RUN_EFFECTS_NO_MODIFIER_STRING : String = "Ei aktiivista kierrosta."
const RUN_EFFECTS_PERKS_HEADER : String = "Aktiiviset perkit (%d):"
const RUN_EFFECTS_NO_PERKS_STRING : String = "Ei vielä perkkejä — nouse tasolle 2 saadaksesi ensimmäisen."
const RUN_EFFECTS_PERK_ROW_FORMAT : String = "%s %s%s"
const RUN_EFFECTS_PERK_ROW_COUNT_SUFFIX : String = " ×%d"
const RUN_EFFECTS_TOTALS_HEADER : String = "Yhteisvaikutus:"
const RUN_EFFECTS_TOTALS_QUALITY : String = "Laatubonus jokaiseen erään: +%d %%"
const RUN_EFFECTS_TOTALS_REPUTATION : String = "Maineen kertymä: +%d %%"
const RUN_EFFECTS_TOTALS_TIP : String = "Tipit: +%d %%"
