class_name ReceiptText
extends RefCounted

## A sale's receipt as the log shows it: who bought what, how the list price became the
## charged price, the totals and a parting line. Adds up line by line.

const NUMBER_FORMAT : String = "KUITTI #%d"
const STYLE_QUALITY_FORMAT : String = "%s, laatu %d %%"
const CUSTOMER_FORMAT : String = "Asiakas: %s"
const SEPARATOR : String = "- - - - - - - - - -"
const COST_FORMAT : String = "Raaka-aineet (arvio): %.2f €"
const PROFIT_FORMAT : String = "Kate: %.2f €"
const LIST_PRICE_FORMAT : String = "Listahinta: %.2f €"
const BONUS_FORMAT : String = "%s: %+d %%"
const REPUTATION_BONUS : String = "Maine"
const PERK_BONUS : String = "Edut"
const AGED_BONUS : String = "Kypsytetty"
const NOVELTY_BONUS : String = "Uutuus"
const PRICE_FORMAT : String = "= Hinta/annos: %.2f €"
const SALE_FORMAT : String = "%d × %.2f € = %.1f €"
const TIP_FORMAT : String = "Tippi: +%.1f €"
const DOUBLED_TIP_FORMAT : String = "Tippi: +%.1f € (tuplana!)"
const NO_TIP : String = "Tippi: ei tällä kertaa"
const TOTAL_FORMAT : String = "TILILLE: +%.1f €"
const FOOTERS : Array[String] = [
	"Kiitos käynnistä. Unohda tämä osoite.",
	"Palautusoikeus: ei ole.",
	"Hinta sisältää pimeyden. Valot maksetaan erikseen.",
	"Kuitti ei kelpaa verottajalle. Eikä sitä ole olemassa.",
	"LVV, jos luet tätä: kyseessä on mehua.",
	"Juo vastuullisesti. Tai ainakin hiljaa.",
	"Seuraava kierros on aina parempi.",
	"Säilytä pimeässä. Kuten meidätkin.",
]


static func text(entry : SaleReceiptEntry) -> String:
	var lines : PackedStringArray = []
	if entry.receipt_number > 0:
		lines.append(UiText.of(NUMBER_FORMAT) % entry.receipt_number)
	var style : String = UiText.of(entry.breakdown.style_name)
	lines.append(UiText.of(STYLE_QUALITY_FORMAT) % [style, roundi(entry.quality * 100.0)] if entry.quality >= 0.0 else style)
	if not entry.customer_title.is_empty():
		lines.append(UiText.of(CUSTOMER_FORMAT) % UiText.of(entry.customer_title))
	lines.append(SEPARATOR)
	lines.append(UiText.of(COST_FORMAT) % entry.breakdown.raw_cost_per_bottle)
	lines.append(UiText.of(PROFIT_FORMAT) % (price_per_serving(entry) - entry.breakdown.raw_cost_per_bottle))
	lines.append(UiText.of(LIST_PRICE_FORMAT) % entry.breakdown.price_per_bottle)
	lines.append_array(bonus_lines(entry))
	lines.append(UiText.of(PRICE_FORMAT) % price_per_serving(entry))
	lines.append(SEPARATOR)
	lines.append(UiText.of(SALE_FORMAT) % [entry.bottles_sold, price_per_serving(entry), entry.gross_income])
	lines.append(tip_line(entry))
	lines.append(UiText.of(TOTAL_FORMAT) % entry.net_income)
	var footer : String = footer_for(entry.footer_index)
	if not footer.is_empty():
		lines.append(SEPARATOR)
		lines.append(footer)
	return "\n".join(lines)


## The charged price; receipts saved before it was kept fall back to the list price.
static func price_per_serving(entry : SaleReceiptEntry) -> float:
	return entry.charged_price if entry.charged_price >= 0.0 else entry.breakdown.price_per_bottle


## One line per counter bonus that changed the price, in the order they apply.
static func bonus_lines(entry : SaleReceiptEntry) -> PackedStringArray:
	var lines : PackedStringArray = []
	var bonuses : Array = [
		[REPUTATION_BONUS, entry.reputation_bonus],
		[PERK_BONUS, entry.perk_multiplier - 1.0],
		[AGED_BONUS, entry.aged_price_multiplier - 1.0],
		[NOVELTY_BONUS, FirstBrewRules.NOVELTY_PRICE_BONUS if entry.novelty else 0.0],
	]
	for bonus : Array in bonuses:
		var percent : int = roundi(bonus[1] * 100.0)
		if percent != 0:
			lines.append(UiText.of(BONUS_FORMAT) % [UiText.of(bonus[0]), percent])
	return lines


static func tip_line(entry : SaleReceiptEntry) -> String:
	if entry.tip_income <= 0.0:
		return UiText.of(NO_TIP)
	return UiText.of(DOUBLED_TIP_FORMAT if entry.tip_doubled else TIP_FORMAT) % entry.tip_income


## A negative index (older receipts) has no footer.
static func footer_for(index : int) -> String:
	if index < 0 or FOOTERS.is_empty():
		return ""
	return UiText.of(FOOTERS[index % FOOTERS.size()])
